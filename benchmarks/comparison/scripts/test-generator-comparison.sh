#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
export PYTHONPATH="$ROOT_DIR/benchmarks/comparison/scripts:${PYTHONPATH:-}"
CLI="$ROOT_DIR/tests/framework/scripts/cogworks-eval.py"
RANKING_SCRIPT="$ROOT_DIR/benchmarks/comparison/scripts/render-quality-first-ranking.py"

RUN_ID="comp-$(date +%Y%m%d-%H%M%S)"
MANIFEST="$ROOT_DIR/benchmarks/comparison/datasets/pipeline-benchmark/manifest.jsonl"
COMPARATORS="$ROOT_DIR/benchmarks/comparison/datasets/pipeline-benchmark/comparators.local.json"
RESULTS_ROOT="$ROOT_DIR/benchmarks/comparison/results/pipeline-benchmark"
REPEATS=3
MODE="real"
FORCE=0
DRY_RUN=0
VARIANTS=("clean" "source-order-shuffled")

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --run-id <id>             Run identifier (default: timestamped)
  --manifest <path>         Benchmark manifest path
  --comparators <path>      Comparator config JSON path
  --results-root <path>     Output root
  --repeats <n>             Repeat count (default: 3)
  --variant <label>         Variant label (repeatable; default: clean + source-order-shuffled)
  --mode <real|offline>     Run mode (default: real)
  --force                   Overwrite existing run-metadata files
  --dry-run                 Write placeholder metadata only; skip summarize/ranking
  -h, --help                Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-id)
      RUN_ID="$2"
      shift 2
      ;;
    --manifest)
      MANIFEST="$2"
      shift 2
      ;;
    --comparators)
      COMPARATORS="$2"
      shift 2
      ;;
    --results-root)
      RESULTS_ROOT="$2"
      shift 2
      ;;
    --repeats)
      REPEATS="$2"
      shift 2
      ;;
    --variant)
      if [[ ${#VARIANTS[@]} -eq 2 && "${VARIANTS[0]}" == "clean" && "${VARIANTS[1]}" == "source-order-shuffled" ]]; then
        VARIANTS=()
      fi
      VARIANTS+=("$2")
      shift 2
      ;;
    --mode)
      MODE="$2"
      shift 2
      ;;
    --force)
      FORCE=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ "$MODE" != "real" && "$MODE" != "offline" ]]; then
  echo "--mode must be real or offline" >&2
  exit 2
fi

if [[ ! -f "$CLI" ]]; then
  echo "Benchmark CLI not found: $CLI" >&2
  exit 2
fi

if [[ ! -f "$COMPARATORS" ]]; then
  echo "Comparator config not found: $COMPARATORS" >&2
  exit 2
fi

mapfile -t PIPELINES < <(python3 - "$COMPARATORS" <<'PY'
import json,sys
cfg=json.load(open(sys.argv[1], encoding="utf-8"))
for name in cfg.get("pipelines", {}).keys():
    print(name)
PY
)

if [[ ${#PIPELINES[@]} -eq 0 ]]; then
  echo "Comparator config has no pipelines." >&2
  exit 2
fi

if [[ "$MODE" == "offline" ]]; then
  export COGWORKS_BENCH_OFFLINE=1
  export COGWORKS_COMPARATOR_OFFLINE=1
else
  unset COGWORKS_BENCH_OFFLINE || true
  unset COGWORKS_COMPARATOR_OFFLINE || true
fi

eval "$(
python3 - "$COMPARATORS" <<'PY'
import json,sys
cfg=json.load(open(sys.argv[1], encoding="utf-8"))
budget=cfg.get("budget", {})
model=cfg.get("model_family", "")
if model:
    print(f"export COGWORKS_BENCH_MODEL_FAMILY='{model}'")
if "max_total_tokens" in budget:
    print(f"export COGWORKS_BENCH_MAX_TOTAL_TOKENS='{budget['max_total_tokens']}'")
if "max_context_tokens" in budget:
    print(f"export COGWORKS_BENCH_MAX_CONTEXT_TOKENS='{budget['max_context_tokens']}'")
if "max_runtime_sec" in budget:
    print(f"export COGWORKS_BENCH_MAX_RUNTIME_SEC='{budget['max_runtime_sec']}'")
PY
)"

VARIANT_ARGS=()
for v in "${VARIANTS[@]}"; do
  VARIANT_ARGS+=(--variant "$v")
done

PIPELINE_ARGS=()
for p in "${PIPELINES[@]}"; do
  PIPELINE_ARGS+=(--pipeline "$p")
done

COMMAND_ARGS=()
while IFS=$'\t' read -r name template; do
  [[ -z "$name" ]] && continue
  COMMAND_ARGS+=(--command-template "$name::$template")
done < <(python3 - "$COMPARATORS" <<'PY'
import json,sys
cfg=json.load(open(sys.argv[1], encoding="utf-8"))
for name, payload in cfg.get("pipelines", {}).items():
    template=str(payload.get("command_template", "")).strip()
    if not template:
        continue
    # Keep templates repo-relative for deterministic execution.
    if template.startswith("./"):
        template = template[2:]
    print(f"{name}\t{template}")
PY
)

if [[ ${#COMMAND_ARGS[@]} -eq 0 ]]; then
  echo "Comparator config must contain at least one command_template." >&2
  exit 2
fi

COMMON_ARGS=(
  --manifest "$MANIFEST"
  --results-root "$RESULTS_ROOT"
  --run-id "$RUN_ID"
  --repeats "$REPEATS"
)

FORCE_ARGS=()
if [[ "$FORCE" -eq 1 ]]; then
  FORCE_ARGS+=(--force)
fi

python3 "$CLI" pipeline-benchmark scaffold \
  "${COMMON_ARGS[@]}" \
  "${VARIANT_ARGS[@]}" \
  "${PIPELINE_ARGS[@]}" \
  "${FORCE_ARGS[@]}"

RUN_ARGS=()
if [[ "$DRY_RUN" -eq 1 ]]; then
  RUN_ARGS+=(--dry-run)
fi

python3 "$CLI" pipeline-benchmark run \
  "${COMMON_ARGS[@]}" \
  "${VARIANT_ARGS[@]}" \
  "${PIPELINE_ARGS[@]}" \
  "${FORCE_ARGS[@]}" \
  --cwd "$ROOT_DIR" \
  "${RUN_ARGS[@]}" \
  "${COMMAND_ARGS[@]}"

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "Dry-run complete. Skipping summarize and ranking."
  echo "Run metadata directory: $RESULTS_ROOT/$RUN_ID"
  exit 0
fi

set +e
python3 "$CLI" pipeline-benchmark summarize \
  --manifest "$MANIFEST" \
  --results-root "$RESULTS_ROOT" \
  --run-id "$RUN_ID" \
  "${PIPELINE_ARGS[@]}"
SUMMARY_EXIT=$?
set -e

SUMMARY="$RESULTS_ROOT/$RUN_ID/benchmark-summary.json"
RANKING="$RESULTS_ROOT/$RUN_ID/quality-first-ranking.md"
python3 "$RANKING_SCRIPT" \
  --summary "$SUMMARY" \
  --manifest "$MANIFEST" \
  --run-root "$RESULTS_ROOT/$RUN_ID" \
  --out "$RANKING"

echo "Run ID: $RUN_ID"
echo "Summary: $SUMMARY"
echo "Report:  $RESULTS_ROOT/$RUN_ID/benchmark-report.md"
echo "Quality: $RANKING"

if [[ "$SUMMARY_EXIT" -ne 0 ]]; then
  exit "$SUMMARY_EXIT"
fi
