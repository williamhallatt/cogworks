#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESULTS_ROOT="$ROOT_DIR/tests/results/pipeline-benchmark"
RUN_ID="smoke-$(date +%Y%m%d-%H%M%S)"
RUNNER="$ROOT_DIR/scripts/test-cogworks-pipeline.sh"
SUMMARY_JSON="$RESULTS_ROOT/$RUN_ID/benchmark-summary.json"
REPORT_MD="$RESULTS_ROOT/$RUN_ID/benchmark-report.md"

for required_script in \
  "$ROOT_DIR/scripts/test-cogworks-pipeline.sh" \
  "$ROOT_DIR/scripts/run-claude-benchmark.sh" \
  "$ROOT_DIR/scripts/run-codex-benchmark.sh"; do
  if [[ ! -x "$required_script" ]]; then
    echo "Missing or non-executable benchmark script: $required_script" >&2
    exit 1
  fi
done

bash "$RUNNER" \
  --mode offline \
  --run-id "$RUN_ID" \
  --repeats 2 \
  --variant clean \
  --variant source-order-shuffled \
  --force

if [[ ! -f "$SUMMARY_JSON" ]]; then
  echo "Missing summary output: $SUMMARY_JSON" >&2
  exit 1
fi

if [[ ! -f "$REPORT_MD" ]]; then
  echo "Missing report output: $REPORT_MD" >&2
  exit 1
fi

python3 - "$SUMMARY_JSON" <<'PY'
import json
import sys
from pathlib import Path

summary = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
pipelines = summary.get("pipelines", {})
winner = summary.get("winner")

for expected in ("claude", "codex"):
    if expected not in pipelines:
        raise SystemExit(f"Missing pipeline in summary: {expected}")

if not winner or winner == "none":
    raise SystemExit("Expected a benchmark winner in smoke test summary.")
PY

echo "Pipeline benchmark smoke test passed."
echo "Run ID: $RUN_ID"
