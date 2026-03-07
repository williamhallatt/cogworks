#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR=""
RUN_ID="engine-compare-$(date +%Y%m%d-%H%M%S)"

LEGACY_SKILL_PATH=""
AGENTIC_SKILL_PATH=""
LEGACY_LOG=""
AGENTIC_LOG=""
LEGACY_RUN_ROOT=""
AGENTIC_RUN_ROOT=""

usage() {
  cat <<'USAGE'
Usage: scripts/run-engine-performance-compare.sh \
  --legacy-skill-path <path> \
  --legacy-log <path> \
  --agentic-skill-path <path> \
  --agentic-log <path> \
  [--legacy-run-root <path>] \
  [--agentic-run-root <path>] \
  [--out-dir <path>]

Writes benchmark-summary.json and benchmark-report.md under tests/results/engine-comparison/<run-id>/ by default.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --legacy-skill-path)
      LEGACY_SKILL_PATH="$2"
      shift 2
      ;;
    --legacy-log)
      LEGACY_LOG="$2"
      shift 2
      ;;
    --agentic-skill-path)
      AGENTIC_SKILL_PATH="$2"
      shift 2
      ;;
    --agentic-log)
      AGENTIC_LOG="$2"
      shift 2
      ;;
    --legacy-run-root)
      LEGACY_RUN_ROOT="$2"
      shift 2
      ;;
    --agentic-run-root)
      AGENTIC_RUN_ROOT="$2"
      shift 2
      ;;
    --out-dir)
      OUT_DIR="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$LEGACY_SKILL_PATH" || -z "$LEGACY_LOG" || -z "$AGENTIC_SKILL_PATH" || -z "$AGENTIC_LOG" ]]; then
  usage >&2
  exit 2
fi

if [[ -z "$OUT_DIR" ]]; then
  OUT_DIR="$ROOT_DIR/tests/results/engine-comparison/$RUN_ID"
fi

mkdir -p "$OUT_DIR"

ARGS=(
  --legacy-skill-path "$LEGACY_SKILL_PATH"
  --legacy-log "$LEGACY_LOG"
  --agentic-skill-path "$AGENTIC_SKILL_PATH"
  --agentic-log "$AGENTIC_LOG"
  --out-dir "$OUT_DIR"
)

if [[ -n "$LEGACY_RUN_ROOT" ]]; then
  ARGS+=(--legacy-run-root "$LEGACY_RUN_ROOT")
fi

if [[ -n "$AGENTIC_RUN_ROOT" ]]; then
  ARGS+=(--agentic-run-root "$AGENTIC_RUN_ROOT")
fi

python3 "$ROOT_DIR/scripts/compare-engine-performance.py" "${ARGS[@]}"

echo "Comparison artifacts written to: $OUT_DIR"
