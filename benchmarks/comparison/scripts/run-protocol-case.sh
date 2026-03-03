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

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
mkdir -p "$OUT_DIR"

# Resolve pipeline config from protocol.
readarray -t CFG < <(python3 - "$PROTOCOL" "$PIPELINE" "$OUT_DIR" <<'PY'
import json,sys
p=sys.argv[1]
pipeline=sys.argv[2]
out_dir=sys.argv[3]
cfg=json.load(open(p,encoding='utf-8'))
pl=cfg.get('pipelines',{}).get(pipeline,{})
cmd=str(pl.get('generation_command_template','')).strip()
sk_t=str(pl.get('skill_path_template','{out_dir}/generated-skill')).strip()
skill_root=sk_t.replace('{out_dir}', out_dir)
b=cfg.get('budget',{})
print(cmd)
print(skill_root)
print(str(cfg.get('model_family','')))
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

mkdir -p "$OUT_DIR/logs" "$SKILL_ROOT"

start_ts="$(date +%s.%N)"

if [[ "$MODE" == "offline" ]]; then
  cat > "$SKILL_ROOT/SKILL.md" <<EOF
---
name: ${PIPELINE}-${TASK_ID}
description: Offline protocol smoke artifact for ${PIPELINE} on ${TASK_ID}.
---

# ${PIPELINE} ${TASK_ID}

## Decision Rules
- When ingesting sources for ${TASK_ID}, produce a concise task skill and include boundaries.

## Anti-Patterns
- Do not omit constraints.

## Sources
- [Source 1] Offline fixture
EOF
else
  if [[ -z "$GEN_CMD" ]]; then
    cat > "$OUT_DIR/generation-artifact.json" <<EOF
{
  "pipeline": "$PIPELINE",
  "task_id": "$TASK_ID",
  "skill_root": "$SKILL_ROOT",
  "generation_failed": true,
  "failure_reason": "generation_command_template is empty in protocol manifest for pipeline"
}
EOF
    # Emit minimal failed metrics so runner can continue.
    cat > "$OUT_DIR/metrics.json" <<EOF
{
  "pipeline": "$PIPELINE",
  "task_id": "$TASK_ID",
  "layer1_pass": false,
  "quality_score": 0.0,
  "activation_f1": 0.0,
  "false_positive_rate": 1.0,
  "negative_control_ratio": 0.0,
  "perturbation_success": false,
  "runtime_sec": 0.0,
  "usage": {"total_tokens": 0, "context_tokens": 0},
  "failed": true,
  "failure_reason": "missing generation command"
}
EOF
    exit 1
  fi

  expanded="$GEN_CMD"
  expanded="${expanded//\{task_id\}/$TASK_ID}"
  expanded="${expanded//\{sources_path\}/$SOURCES_PATH}"
  expanded="${expanded//\{out_dir\}/$OUT_DIR}"
  expanded="${expanded//\{skill_out_dir\}/$SKILL_ROOT}"

  set +e
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
  fi
fi

end_ts="$(date +%s.%N)"
GEN_RUNTIME="$(python3 - "$start_ts" "$end_ts" <<'PY'
import sys
s=float(sys.argv[1]); e=float(sys.argv[2])
print(f"{max(0.0, e-s):.4f}")
PY
)"

python3 "$ROOT_DIR/benchmarks/comparison/scripts/score-generated-skill.py" \
  --pipeline "$PIPELINE" \
  --task-id "$TASK_ID" \
  --sources-path "$SOURCES_PATH" \
  --skill-root "$SKILL_ROOT" \
  --out-dir "$OUT_DIR" \
  --model-family "$MODEL_FAMILY" \
  --generation-runtime-sec "$GEN_RUNTIME" \
  --max-total-tokens "$MAX_TOTAL_TOKENS" \
  --max-context-tokens "$MAX_CONTEXT_TOKENS" \
  --max-runtime-sec "$MAX_RUNTIME_SEC"

if [[ ! -f "$OUT_DIR/generation-artifact.json" ]]; then
  cat > "$OUT_DIR/generation-artifact.json" <<EOF
{
  "pipeline": "$PIPELINE",
  "task_id": "$TASK_ID",
  "skill_root": "$SKILL_ROOT",
  "files": [
    "SKILL.md",
    "reference.md",
    "patterns.md",
    "examples.md"
  ],
  "generation_trace_path": "$OUT_DIR/logs/generation.stdout.log",
  "model_family": "$MODEL_FAMILY",
  "budget_applied": {
    "max_total_tokens": $MAX_TOTAL_TOKENS,
    "max_context_tokens": $MAX_CONTEXT_TOKENS,
    "max_runtime_sec": $MAX_RUNTIME_SEC
  },
  "generation_failed": false
}
EOF
fi
