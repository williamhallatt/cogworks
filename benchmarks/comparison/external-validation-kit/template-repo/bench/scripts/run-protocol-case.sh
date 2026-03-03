#!/bin/bash
set -euo pipefail

usage() {
  echo "Usage: $0 --protocol <path> --pipeline <id> --task-id <id> --sources-path <path> --out-dir <path> --mode <real|offline>" >&2
}

PROTOCOL=""
PIPELINE=""
TASK_ID=""
SOURCES_PATH=""
OUT_DIR=""
MODE="real"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --protocol) PROTOCOL="$2"; shift 2 ;;
    --pipeline) PIPELINE="$2"; shift 2 ;;
    --task-id) TASK_ID="$2"; shift 2 ;;
    --sources-path) SOURCES_PATH="$2"; shift 2 ;;
    --out-dir) OUT_DIR="$2"; shift 2 ;;
    --mode) MODE="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ -z "$PROTOCOL" || -z "$PIPELINE" || -z "$TASK_ID" || -z "$SOURCES_PATH" || -z "$OUT_DIR" ]]; then
  usage
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
mkdir -p "$OUT_DIR" "$OUT_DIR/logs"

if [[ "$SOURCES_PATH" = /* ]]; then
  SOURCES_ABS="$SOURCES_PATH"
else
  SOURCES_ABS="$ROOT_DIR/$SOURCES_PATH"
fi

readarray -t CFG < <(python3 - "$PROTOCOL" "$PIPELINE" "$OUT_DIR" <<'PY'
import json,sys
from pathlib import Path
protocol=Path(sys.argv[1]).resolve()
pipeline=sys.argv[2]
out=sys.argv[3]
cfg=json.loads(protocol.read_text(encoding='utf-8'))
pl=cfg.get('pipelines',{}).get(pipeline,{})
cmd=str(pl.get('generation_command_template','')).strip()
sk_t=str(pl.get('skill_path_template','{out_dir}/generated-skill')).strip()
print(cmd)
print(sk_t.replace('{out_dir}', out))
print(str(cfg.get('model_family','')))
b=cfg.get('budget',{})
print(str(b.get('max_total_tokens',0)))
print(str(b.get('max_context_tokens',0)))
print(str(b.get('max_runtime_sec',0)))
PY
)

GEN_CMD="${CFG[0]}"
SKILL_ROOT="${CFG[1]}"
MODEL_FAMILY="${CFG[2]}"
MAX_TOTAL_TOKENS="${CFG[3]}"
MAX_CONTEXT_TOKENS="${CFG[4]}"
MAX_RUNTIME_SEC="${CFG[5]}"

python3 "$ROOT_DIR/bench/scripts/detect_pipeline_capability.py" \
  --protocol "$PROTOCOL" \
  --pipeline "$PIPELINE" \
  --out "$OUT_DIR/execution-mode.json"

EXEC_MODE="$(python3 - "$OUT_DIR/execution-mode.json" <<'PY'
import json,sys
cfg=json.load(open(sys.argv[1],encoding='utf-8'))
print(cfg.get('execution_mode','protocol_prompt'))
PY
)"

if [[ "$SOURCES_ABS" != /* ]]; then
  echo "sources path must resolve to an absolute path" >&2
  exit 2
fi

WORK_TMP="$(mktemp -d "${TMPDIR:-/tmp}/skill-bench-${PIPELINE}-${TASK_ID}-XXXXXX")"
if [[ "${BENCH_KEEP_WORKSPACE:-0}" != "1" ]]; then
  trap 'rm -rf "$WORK_TMP"' EXIT
fi

SANDBOX="$WORK_TMP/workspace"
CODEX_HOME_DIR="$SANDBOX/codex-home"
mkdir -p "$SANDBOX/input/sources" "$SANDBOX/input/protocol" "$SANDBOX/output/generated-skill" "$CODEX_HOME_DIR"
cp -R "$SOURCES_ABS"/. "$SANDBOX/input/sources/"

for proto in "$ROOT_DIR/bench/protocols/$PIPELINE.md" "$ROOT_DIR/bench/protocols/$PIPELINE".md; do
  if [[ -f "$proto" ]]; then
    cp "$proto" "$SANDBOX/input/protocol/pipeline.md"
    break
  fi
done

cp "$ROOT_DIR/TRUST_MODEL.md" "$SANDBOX/input/protocol/" 2>/dev/null || true
cp "$ROOT_DIR/ARCHITECTURE.md" "$SANDBOX/input/protocol/" 2>/dev/null || true

bash "$ROOT_DIR/bench/scripts/install_pipeline_skills.sh" \
  --protocol "$PROTOCOL" \
  --pipeline "$PIPELINE" \
  --workspace-root "$SANDBOX" \
  --codex-home "$CODEX_HOME_DIR" \
  --out "$OUT_DIR/skill-install-report.json" \
  --mode "$MODE"

start_ts="$(date +%s.%N)"

if [[ "$MODE" == "offline" ]]; then
  cat > "$SANDBOX/output/generated-skill/SKILL.md" <<EOF
---
name: ${PIPELINE}-${TASK_ID}
description: Offline protocol artifact for ${PIPELINE} on ${TASK_ID}.
---

# ${PIPELINE} ${TASK_ID}

## Decision Rules
- Produce concise, testable guidance.

## Benchmark Evidence
- skill_used: offline-smoke

## Sources
- Source set for ${TASK_ID}
EOF
  cat > "$SANDBOX/output/generated-skill/reference.md" <<EOF
# Reference

- Generated in offline mode for smoke validation.
EOF
else
  expanded="$GEN_CMD"
  expanded="${expanded//\{task_id\}/$TASK_ID}"
  expanded="${expanded//\{sources_path\}/$SANDBOX/input/sources}"
  expanded="${expanded//\{out_dir\}/$SANDBOX/output}"
  expanded="${expanded//\{skill_out_dir\}/$SANDBOX/output/generated-skill}"

  REQUIRED_SKILL_SLUG="$(python3 - "$PROTOCOL" "$PIPELINE" <<'PY'
import json,sys
cfg=json.load(open(sys.argv[1],encoding='utf-8'))
pl=cfg.get('pipelines',{}).get(sys.argv[2],{})
inv=pl.get('skill_invocation',{}) if isinstance(pl.get('skill_invocation'),dict) else {}
print(inv.get('required_skill_slug',''))
PY
)"

  INSTALL_SOURCE="$(python3 - "$PROTOCOL" "$PIPELINE" <<'PY'
import json,sys
cfg=json.load(open(sys.argv[1],encoding='utf-8'))
pl=cfg.get('pipelines',{}).get(sys.argv[2],{})
ins=pl.get('skill_install',{}) if isinstance(pl.get('skill_install'),dict) else {}
print(ins.get('source',''))
PY
)"

  mkdir -p "$CODEX_HOME_DIR/home"

  set +e
  BENCH_WORKSPACE_ROOT="$SANDBOX" \
  BENCH_EXECUTION_MODE="$EXEC_MODE" \
  BENCH_REQUIRED_SKILL_SLUG="$REQUIRED_SKILL_SLUG" \
  BENCH_SKILL_INSTALL_SOURCE="$INSTALL_SOURCE" \
  CODEX_HOME="$CODEX_HOME_DIR" \
  HOME="$CODEX_HOME_DIR/home" \
  bash -lc "$expanded" >"$OUT_DIR/logs/generation.stdout.log" 2>"$OUT_DIR/logs/generation.stderr.log"
  gen_exit=$?
  set -e

  if [[ $gen_exit -ne 0 ]]; then
    cat > "$OUT_DIR/generation-artifact.json" <<EOF
{
  "pipeline": "$PIPELINE",
  "task_id": "$TASK_ID",
  "skill_root": "$SKILL_ROOT",
  "generation_failed": true,
  "failure_reason": "generation command exited non-zero",
  "generation_exit_code": $gen_exit
}
EOF
    exit "$gen_exit"
  fi
fi

mkdir -p "$SKILL_ROOT"
cp -R "$SANDBOX/output/generated-skill"/. "$SKILL_ROOT/" 2>/dev/null || true

python3 "$ROOT_DIR/bench/scripts/verify_skill_use.py" \
  --protocol "$PROTOCOL" \
  --pipeline "$PIPELINE" \
  --out-dir "$OUT_DIR" \
  --skill-root "$SKILL_ROOT" \
  --mode "$MODE"

end_ts="$(date +%s.%N)"
GEN_RUNTIME="$(python3 - "$start_ts" "$end_ts" <<'PY'
import sys
s=float(sys.argv[1]); e=float(sys.argv[2])
print(f"{max(0.0,e-s):.4f}")
PY
)"

python3 "$ROOT_DIR/bench/scorers/scorer-v1.py" \
  --pipeline "$PIPELINE" \
  --task-id "$TASK_ID" \
  --sources-path "$SOURCES_ABS" \
  --skill-root "$SKILL_ROOT" \
  --out-dir "$OUT_DIR" \
  --model-family "$MODEL_FAMILY" \
  --generation-runtime-sec "$GEN_RUNTIME" \
  --max-total-tokens "$MAX_TOTAL_TOKENS" \
  --max-context-tokens "$MAX_CONTEXT_TOKENS" \
  --max-runtime-sec "$MAX_RUNTIME_SEC"

python3 "$ROOT_DIR/bench/scorers/scorer-v2.py" \
  --pipeline "$PIPELINE" \
  --task-id "$TASK_ID" \
  --sources-path "$SOURCES_ABS" \
  --skill-root "$SKILL_ROOT" \
  --out-dir "$OUT_DIR"

python3 - "$OUT_DIR" "$EXEC_MODE" <<'PY'
import json,sys
from pathlib import Path
out=Path(sys.argv[1]); mode=sys.argv[2]
for name in ["metrics.json","quality-eval.json","quality-eval-v2.json"]:
    p=out/name
    if not p.exists():
        continue
    data=json.loads(p.read_text(encoding='utf-8'))
    if isinstance(data,dict):
        data["execution_mode"]=mode
        p.write_text(json.dumps(data,indent=2),encoding='utf-8')
PY

python3 "$ROOT_DIR/bench/scripts/collect_provenance.py" \
  --run-root "$OUT_DIR" \
  --sources-path "$SOURCES_ABS" \
  --skill-root "$SKILL_ROOT" \
  --sandbox "$SANDBOX"

if [[ ! -f "$OUT_DIR/generation-artifact.json" ]]; then
  cat > "$OUT_DIR/generation-artifact.json" <<EOF
{
  "pipeline": "$PIPELINE",
  "task_id": "$TASK_ID",
  "skill_root": "$SKILL_ROOT",
  "generation_trace_path": "$OUT_DIR/logs/generation.stdout.log",
  "model_family": "$MODEL_FAMILY",
  "generation_failed": false,
  "isolation_workspace": "$SANDBOX",
  "execution_mode": "$EXEC_MODE"
}
EOF
fi
