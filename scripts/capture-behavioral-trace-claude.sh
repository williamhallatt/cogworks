#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NORMALIZER="$ROOT_DIR/tests/framework/scripts/capture_behavioral_trace.py"

if [[ $# -ne 4 ]]; then
  echo "Usage: $0 <case-id> <skill-slug> <raw-trace.json> <out-trace.json>" >&2
  exit 2
fi

CASE_ID="$1"
SKILL_SLUG="$2"
RAW_TRACE="$3"
OUT_TRACE="$4"

HARNESS="${COGWORKS_BEHAVIORAL_CLAUDE_HARNESS:-claude-code}"
MODEL="${COGWORKS_BEHAVIORAL_CLAUDE_MODEL:-claude-opus-4-6}"

python3 "$NORMALIZER" \
  --pipeline claude \
  --skill-slug "$SKILL_SLUG" \
  --case-id "$CASE_ID" \
  --raw-trace "$RAW_TRACE" \
  --out "$OUT_TRACE" \
  --harness "$HARNESS" \
  --model "$MODEL" \
  --trace-source captured
