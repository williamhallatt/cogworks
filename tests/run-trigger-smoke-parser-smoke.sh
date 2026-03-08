#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PARSER="$ROOT_DIR/scripts/run-trigger-smoke-tests.sh"
FIXTURES="$ROOT_DIR/tests/test-data/trigger-smoke"

bash "$PARSER" --parse-log codex cogworks-learn "$FIXTURES/codex-cogworks-learn-activation.jsonl"
bash "$PARSER" --parse-log codex cogworks-encode "$FIXTURES/codex-cogworks-encode-activation.jsonl"

if bash "$PARSER" --parse-log claude cogworks-learn "$FIXTURES/claude-connection-refused.jsonl"; then
  echo "Expected claude connectivity fixture to skip." >&2
  exit 1
else
  status=$?
  if [[ $status -ne 2 ]]; then
    echo "Expected claude connectivity fixture to return skip (2)." >&2
    exit 1
  fi
fi

if bash "$PARSER" --parse-log codex cogworks "$FIXTURES/codex-transport-blocked.jsonl"; then
  echo "Expected codex transport fixture to skip." >&2
  exit 1
else
  status=$?
  if [[ $status -ne 2 ]]; then
    echo "Expected codex transport fixture to return skip (2)." >&2
    exit 1
  fi
fi

echo "Trigger smoke parser fixtures passed."
