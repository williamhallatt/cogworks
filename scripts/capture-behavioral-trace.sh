#!/bin/bash
set -euo pipefail

# Normalize a raw behavioral trace file into the behavioral trace contract format.
# Use when you already have a raw trace JSON (e.g. from a manual test run) and
# want to normalize it without running a full capture pipeline.
#
# For full end-to-end capture (run agent + normalize), use behavioral-capture.sh instead.

usage() {
  cat <<'EOF' >&2
Usage: scripts/capture-behavioral-trace.sh <claude|codex> <case-id> <skill-slug> <raw-trace.json> <out-trace.json>

Environment (pipeline-specific):
  COGWORKS_BEHAVIORAL_CLAUDE_HARNESS  (default: claude-code)
  COGWORKS_BEHAVIORAL_CLAUDE_MODEL    (default: claude-opus-4-6)
  COGWORKS_BEHAVIORAL_CODEX_HARNESS   (default: codex-cli)
  COGWORKS_BEHAVIORAL_CODEX_MODEL     (default: gpt-5-codex)

Sample data for testing this script:
  tests/test-data/behavioral-capture/case-sample.json
  tests/test-data/behavioral-capture/claude-events-sample.jsonl
  tests/test-data/behavioral-capture/codex-events-sample.jsonl
EOF
}

if [[ $# -ne 5 ]]; then
  usage
  exit 2
fi

pipeline="$1"
case_id="$2"
skill_slug="$3"
raw_trace="$4"
out_trace="$5"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NORMALIZER="$ROOT_DIR/tests/framework/scripts/capture_behavioral_trace.py"

if [[ "$pipeline" == "claude" ]]; then
  harness="${COGWORKS_BEHAVIORAL_CLAUDE_HARNESS:-claude-code}"
  model="${COGWORKS_BEHAVIORAL_CLAUDE_MODEL:-claude-opus-4-6}"
elif [[ "$pipeline" == "codex" ]]; then
  harness="${COGWORKS_BEHAVIORAL_CODEX_HARNESS:-codex-cli}"
  model="${COGWORKS_BEHAVIORAL_CODEX_MODEL:-gpt-5-codex}"
else
  echo "Pipeline must be 'claude' or 'codex', got: $pipeline" >&2
  usage
  exit 2
fi

python3 "$NORMALIZER" \
  --pipeline "$pipeline" \
  --skill-slug "$skill_slug" \
  --case-id "$case_id" \
  --raw-trace "$raw_trace" \
  --out "$out_trace" \
  --harness "$harness" \
  --model "$model" \
  --trace-source captured
