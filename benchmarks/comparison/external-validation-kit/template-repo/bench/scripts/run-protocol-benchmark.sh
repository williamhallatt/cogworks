#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CLI="$ROOT_DIR/bench/scripts/benchmark_cli.py"

RUN_ID="protocol-$(date +%Y%m%d-%H%M%S)"
PROTOCOL="$ROOT_DIR/bench/protocols/protocol-pilot.json"
RESULTS_ROOT="$ROOT_DIR/bench/results/pipeline-benchmark"
MODE="real"
FORCE=0
DRY_RUN=0
REPEATS=3
VARIANTS=("clean")

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --run-id <id>
  --protocol <path>
  --results-root <path>
  --mode <real|offline>
  --repeats <n>
  --variant <label>
  --force
  --dry-run
  -h, --help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-id) RUN_ID="$2"; shift 2 ;;
    --protocol) PROTOCOL="$2"; shift 2 ;;
    --results-root) RESULTS_ROOT="$2"; shift 2 ;;
    --mode) MODE="$2"; shift 2 ;;
    --repeats) REPEATS="$2"; shift 2 ;;
    --variant)
      if [[ ${#VARIANTS[@]} -eq 1 && "${VARIANTS[0]}" == "clean" ]]; then VARIANTS=(); fi
      VARIANTS+=("$2")
      shift 2
      ;;
    --force) FORCE=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ "$MODE" != "real" && "$MODE" != "offline" ]]; then
  echo "--mode must be real or offline" >&2
  exit 2
fi

if [[ ! -f "$PROTOCOL" ]]; then
  echo "Protocol file not found: $PROTOCOL" >&2
  exit 2
fi

python3 - "$PROTOCOL" <<'PY'
import json,sys
cfg=json.load(open(sys.argv[1],encoding='utf-8'))
required=['name','source_manifest','tasks','pipelines','execution','reproducibility']
missing=[k for k in required if k not in cfg]
if missing:
    raise SystemExit(f"protocol missing keys: {', '.join(missing)}")
for name,pl in cfg.get('pipelines',{}).items():
    mode=pl.get('execution_mode','protocol_prompt')
    if mode not in {'skill_installed','protocol_prompt'}:
        raise SystemExit(f"pipeline {name} has invalid execution_mode: {mode}")
    if mode=='skill_installed':
        if 'skill_install' not in pl or 'skill_invocation' not in pl:
            raise SystemExit(f"pipeline {name} missing skill_install/skill_invocation for skill_installed mode")
PY

TMP_MANIFEST="$(mktemp)"
trap 'rm -f "$TMP_MANIFEST"' EXIT

python3 - "$PROTOCOL" "$TMP_MANIFEST" <<'PY'
import json,sys
from pathlib import Path
protocol=Path(sys.argv[1]).resolve()
out=Path(sys.argv[2])
cfg=json.loads(protocol.read_text(encoding='utf-8'))
root=protocol.parents[2]
manifest=Path(cfg.get('source_manifest','bench/datasets/pipeline-benchmark/manifest.jsonl'))
if not manifest.is_absolute():
    manifest=(root/manifest).resolve()
selected=set(cfg.get('tasks',[]))
rows=[]
for line in manifest.read_text(encoding='utf-8').splitlines():
    if not line.strip():
        continue
    obj=json.loads(line)
    if obj.get('task_id') in selected:
        rows.append(obj)
if not rows:
    raise SystemExit('No tasks selected')
out.write_text('\n'.join(json.dumps(r) for r in rows)+'\n', encoding='utf-8')
print(manifest)
print(','.join(r['task_id'] for r in rows))
PY

mapfile -t PIPELINES < <(python3 - "$PROTOCOL" <<'PY'
import json,sys
cfg=json.load(open(sys.argv[1],encoding='utf-8'))
for p in cfg.get('pipelines',{}).keys():
    print(p)
PY
)

VARIANT_ARGS=()
for v in "${VARIANTS[@]}"; do VARIANT_ARGS+=(--variant "$v"); done

PIPELINE_ARGS=()
for p in "${PIPELINES[@]}"; do PIPELINE_ARGS+=(--pipeline "$p"); done

COMMAND_ARGS=()
for p in "${PIPELINES[@]}"; do
  COMMAND_ARGS+=(--command-template "$p::bash bench/scripts/run-protocol-case.sh --protocol '$PROTOCOL' --pipeline '$p' --task-id '{task_id}' --sources-path '{sources_path}' --out-dir '{out_dir}' --mode '$MODE'")
done

COMMON_ARGS=(
  --manifest "$TMP_MANIFEST"
  --results-root "$RESULTS_ROOT"
  --run-id "$RUN_ID"
  --repeats "$REPEATS"
)

FORCE_ARGS=()
if [[ "$FORCE" -eq 1 ]]; then FORCE_ARGS+=(--force); fi

python3 "$CLI" scaffold "${COMMON_ARGS[@]}" "${PIPELINE_ARGS[@]}" "${VARIANT_ARGS[@]}" "${FORCE_ARGS[@]}"

RUN_ARGS=()
if [[ "$DRY_RUN" -eq 1 ]]; then RUN_ARGS+=(--dry-run); fi

python3 "$CLI" run "${COMMON_ARGS[@]}" "${PIPELINE_ARGS[@]}" "${VARIANT_ARGS[@]}" "${FORCE_ARGS[@]}" --cwd "$ROOT_DIR" "${RUN_ARGS[@]}" "${COMMAND_ARGS[@]}"

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "Dry run complete: $RESULTS_ROOT/$RUN_ID"
  exit 0
fi

python3 "$CLI" summarize --manifest "$TMP_MANIFEST" --results-root "$RESULTS_ROOT" --run-id "$RUN_ID" "${PIPELINE_ARGS[@]}" || true

python3 "$ROOT_DIR/bench/scripts/summarize-protocol-benchmark.py" \
  --run-id "$RUN_ID" \
  --results-root "$RESULTS_ROOT" \
  --protocol "$PROTOCOL"

python3 "$ROOT_DIR/bench/scripts/scan_contamination.py" --run-root "$RESULTS_ROOT/$RUN_ID" --out "$RESULTS_ROOT/$RUN_ID/contamination-report.json"
python3 "$ROOT_DIR/bench/scripts/verify_reproducibility.py" --run-root "$RESULTS_ROOT/$RUN_ID" --protocol "$PROTOCOL" --out "$RESULTS_ROOT/$RUN_ID/reproducibility-report.json"
python3 "$ROOT_DIR/bench/scripts/generate_trust_report.py" --run-root "$RESULTS_ROOT/$RUN_ID" --protocol "$PROTOCOL" --out-json "$RESULTS_ROOT/$RUN_ID/trust-report.json" --out-md "$RESULTS_ROOT/$RUN_ID/trust-report.md"

echo "Run ID: $RUN_ID"
echo "Protocol summary: $RESULTS_ROOT/$RUN_ID/pilot-summary.json"
echo "Trust report:    $RESULTS_ROOT/$RUN_ID/trust-report.md"
