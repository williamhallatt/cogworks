#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PYTHONPATH="$ROOT_DIR/scripts:${PYTHONPATH:-}"
CLI="$ROOT_DIR/tests/framework/scripts/cogworks-eval.py"

RUN_ID="ab-$(date +%Y%m%d-%H%M%S)"
MANIFEST="$ROOT_DIR/tests/datasets/pipeline-benchmark/manifest.jsonl"
RESULTS_ROOT="$ROOT_DIR/tests/results/pipeline-benchmark"
REPEATS=3
MODE="offline"
FORCE=0
DRY_RUN=0
VARIANTS=("clean" "source-order-shuffled")

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --run-id <id>           Run identifier (default: timestamped)
  --manifest <path>       Manifest path (default: tests/datasets/pipeline-benchmark/manifest.jsonl)
  --results-root <path>   Results root (default: tests/results/pipeline-benchmark)
  --repeats <n>           Repeat count per task (default: 3)
  --variant <label>       Variant label (repeatable). Defaults to clean + source-order-shuffled.
  --mode <offline|real>   Benchmark mode (default: offline)
  --force                 Overwrite existing run-metadata.json files
  --dry-run               Write placeholder metadata only; skip summarize
  -h, --help              Show this help
EOF
}

ensure_real_mode_env() {
  local missing=()
  [[ -n "${COGWORKS_BENCH_CLAUDE_CMD:-}" ]] || missing+=("COGWORKS_BENCH_CLAUDE_CMD")
  [[ -n "${COGWORKS_BENCH_CODEX_CMD:-}" ]] || missing+=("COGWORKS_BENCH_CODEX_CMD")

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "Missing required environment variable(s) for --mode real: ${missing[*]}" >&2
    echo "Each command must write <out_dir>/metrics.json and may use {sources_path} and {out_dir} placeholders." >&2
    exit 2
  fi
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

if [[ "$MODE" != "offline" && "$MODE" != "real" ]]; then
  echo "--mode must be 'offline' or 'real'." >&2
  exit 2
fi

if [[ ! -f "$CLI" ]]; then
  echo "Benchmark CLI not found: $CLI" >&2
  exit 2
fi

if [[ "$MODE" == "real" ]]; then
  ensure_real_mode_env
else
  export COGWORKS_BENCH_OFFLINE=1
fi

VARIANT_ARGS=()
for v in "${VARIANTS[@]}"; do
  VARIANT_ARGS+=(--variant "$v")
done

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
  "${FORCE_ARGS[@]}"

RUN_ARGS=()
if [[ "$DRY_RUN" -eq 1 ]]; then
  RUN_ARGS+=(--dry-run)
fi

python3 "$CLI" pipeline-benchmark run \
  "${COMMON_ARGS[@]}" \
  "${VARIANT_ARGS[@]}" \
  "${FORCE_ARGS[@]}" \
  "${RUN_ARGS[@]}" \
  --command-template "claude::$ROOT_DIR/scripts/run-claude-benchmark.sh '{sources_path}' '{out_dir}'" \
  --command-template "codex::$ROOT_DIR/scripts/run-codex-benchmark.sh '{sources_path}' '{out_dir}'"

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "Dry-run complete. Skipping summarize by design."
  echo "Run metadata directory: $RESULTS_ROOT/$RUN_ID"
  exit 0
fi

python3 "$CLI" pipeline-benchmark summarize \
  --manifest "$MANIFEST" \
  --results-root "$RESULTS_ROOT" \
  --run-id "$RUN_ID"

echo "Run ID: $RUN_ID"
echo "Summary: $RESULTS_ROOT/$RUN_ID/benchmark-summary.json"
echo "Report:  $RESULTS_ROOT/$RUN_ID/benchmark-report.md"
