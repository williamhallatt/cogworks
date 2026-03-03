#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
export PYTHONPATH="$ROOT_DIR/benchmarks/comparison/scripts:${PYTHONPATH:-}"
CLI="$ROOT_DIR/tests/framework/scripts/cogworks-eval.py"

RUN_ID="protocol-$(date +%Y%m%d-%H%M%S)"
PROTOCOL="$ROOT_DIR/benchmarks/comparison/datasets/pipeline-benchmark/protocol-pilot.json"
RESULTS_ROOT="$ROOT_DIR/benchmarks/comparison/results/pipeline-benchmark"
MODE="real"
FORCE=0
DRY_RUN=0
COMPAT_SUMMARY=0
REPEATS=1
VARIANTS=("clean")

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --run-id <id>          Run identifier
  --protocol <path>      Protocol manifest (default: benchmarks/comparison/datasets/pipeline-benchmark/protocol-pilot.json)
  --results-root <path>  Results root (default: benchmarks/comparison/results/pipeline-benchmark)
  --mode <real|offline>  Execution mode (default: real)
  --repeats <n>          Repeat count (default: 1)
  --variant <label>      Variant label (repeatable; default: clean)
  --compat-summary       Also run legacy comparator summarizer (non-authoritative for protocol runs)
  --force                Overwrite existing run metadata
  --dry-run              Dry-run the benchmark runner
  -h, --help             Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-id) RUN_ID="$2"; shift 2 ;;
    --protocol) PROTOCOL="$2"; shift 2 ;;
    --results-root) RESULTS_ROOT="$2"; shift 2 ;;
    --mode) MODE="$2"; shift 2 ;;
    --repeats) REPEATS="$2"; shift 2 ;;
    --compat-summary) COMPAT_SUMMARY=1; shift ;;
    --variant)
      if [[ ${#VARIANTS[@]} -eq 1 && "${VARIANTS[0]}" == "clean" ]]; then
        VARIANTS=()
      fi
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

if [[ ! -f "$CLI" ]]; then
  echo "Benchmark CLI not found: $CLI" >&2
  exit 2
fi

# Extract protocol config and build a filtered manifest for selected tasks.
TMP_MANIFEST="$(mktemp)"
trap 'rm -f "$TMP_MANIFEST"' EXIT

python3 - "$PROTOCOL" "$TMP_MANIFEST" <<'PY'
import json,sys
from pathlib import Path
cfg=json.load(open(sys.argv[1],encoding='utf-8'))
out=Path(sys.argv[2])
all_manifest=Path(cfg.get('source_manifest','benchmarks/comparison/datasets/pipeline-benchmark/manifest.jsonl'))
if not all_manifest.exists():
    raise SystemExit(f"source_manifest not found: {all_manifest}")
selected=set(cfg.get('tasks',[]))
if not selected:
    raise SystemExit("protocol has no tasks")
rows=[]
for line in all_manifest.read_text(encoding='utf-8').splitlines():
    line=line.strip()
    if not line:
        continue
    obj=json.loads(line)
    if obj.get('task_id') in selected:
        rows.append(obj)
if not rows:
    raise SystemExit("no matching tasks found in source_manifest")
out.write_text("\n".join(json.dumps(r) for r in rows)+"\n", encoding='utf-8')
print(all_manifest)
print(",".join(r['task_id'] for r in rows))
PY

mapfile -t PIPELINES < <(python3 - "$PROTOCOL" <<'PY'
import json,sys
cfg=json.load(open(sys.argv[1],encoding='utf-8'))
for p in cfg.get('pipelines',{}).keys():
    print(p)
PY
)

if [[ ${#PIPELINES[@]} -eq 0 ]]; then
  echo "No pipelines configured in protocol." >&2
  exit 2
fi

PIPELINE_ARGS=()
for p in "${PIPELINES[@]}"; do
  PIPELINE_ARGS+=(--pipeline "$p")
done

VARIANT_ARGS=()
for v in "${VARIANTS[@]}"; do
  VARIANT_ARGS+=(--variant "$v")
done

COMMAND_ARGS=()
for p in "${PIPELINES[@]}"; do
  COMMAND_ARGS+=(--command-template "$p::bash benchmarks/comparison/scripts/run-protocol-case.sh --protocol '$PROTOCOL' --pipeline '$p' --task-id '{task_id}' --sources-path '{sources_path}' --out-dir '{out_dir}' --mode '$MODE'")
done

COMMON_ARGS=(
  --manifest "$TMP_MANIFEST"
  --results-root "$RESULTS_ROOT"
  --run-id "$RUN_ID"
  --repeats "$REPEATS"
)

FORCE_ARGS=()
if [[ "$FORCE" -eq 1 ]]; then
  FORCE_ARGS+=(--force)
fi

if [[ "$MODE" == "offline" ]]; then
  export COGWORKS_COMPARATOR_OFFLINE=1
  export COGWORKS_BENCH_OFFLINE=1
else
  unset COGWORKS_COMPARATOR_OFFLINE || true
  unset COGWORKS_BENCH_OFFLINE || true
fi

python3 "$CLI" pipeline-benchmark scaffold \
  "${COMMON_ARGS[@]}" \
  "${PIPELINE_ARGS[@]}" \
  "${VARIANT_ARGS[@]}" \
  "${FORCE_ARGS[@]}"

RUN_ARGS=()
if [[ "$DRY_RUN" -eq 1 ]]; then
  RUN_ARGS+=(--dry-run)
fi

python3 "$CLI" pipeline-benchmark run \
  "${COMMON_ARGS[@]}" \
  "${PIPELINE_ARGS[@]}" \
  "${VARIANT_ARGS[@]}" \
  "${FORCE_ARGS[@]}" \
  --cwd "$ROOT_DIR" \
  "${RUN_ARGS[@]}" \
  "${COMMAND_ARGS[@]}"

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "Dry run complete: $RESULTS_ROOT/$RUN_ID"
  exit 0
fi

PB_EXIT=0
if [[ "$COMPAT_SUMMARY" -eq 1 ]]; then
  # Legacy comparator summarizer is optional in protocol mode and can produce
  # misleading disqualifications because protocol-run artifacts differ.
  set +e
  python3 "$CLI" pipeline-benchmark summarize \
    --manifest "$TMP_MANIFEST" \
    --results-root "$RESULTS_ROOT" \
    --run-id "$RUN_ID" \
    "${PIPELINE_ARGS[@]}"
  PB_EXIT=$?
  set -e
else
  echo "Skipped legacy compatibility summary. Use --compat-summary to emit benchmark-summary.json."
fi

python3 "$ROOT_DIR/benchmarks/comparison/scripts/summarize-protocol-benchmark.py" \
  --run-id "$RUN_ID" \
  --results-root "$RESULTS_ROOT" \
  --protocol "$PROTOCOL"

echo "Run ID: $RUN_ID"
echo "Protocol Summary: $RESULTS_ROOT/$RUN_ID/pilot-summary.json"
echo "Protocol Report:  $RESULTS_ROOT/$RUN_ID/pilot-report.md"

if [[ "$PB_EXIT" -ne 0 ]]; then
  echo "Legacy compatibility summary exited non-zero (non-fatal for protocol runs)."
fi
