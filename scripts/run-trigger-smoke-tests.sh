#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROMPTS_DIR="$ROOT_DIR/tests/trigger-smoke/prompts"
RUNNER="${1:-claude}"
TIMEOUT_SEC="${TRIGGER_SMOKE_TIMEOUT_SEC:-300}"
OUT_ROOT="${TRIGGER_SMOKE_OUT_ROOT:-/tmp/cogworks-trigger-smoke}"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT_DIR="$OUT_ROOT/$STAMP/$RUNNER"

usage() {
  cat <<'EOF'
Usage: scripts/run-trigger-smoke-tests.sh [claude|codex]

Environment:
  TRIGGER_SMOKE_TIMEOUT_SEC   per-case timeout (default: 300)
  TRIGGER_SMOKE_OUT_ROOT      output directory root (default: /tmp/cogworks-trigger-smoke)
EOF
}

if [[ "$RUNNER" != "claude" && "$RUNNER" != "codex" ]]; then
  usage >&2
  exit 2
fi

if ! command -v "$RUNNER" >/dev/null 2>&1; then
  echo "Runner not installed: $RUNNER" >&2
  exit 2
fi

mkdir -p "$OUT_DIR"

cases=(
  "cogworks-learn|$PROMPTS_DIR/cogworks-learn-explicit.txt"
  "cogworks-learn|$PROMPTS_DIR/cogworks-learn-mid-conversation.txt"
  "cogworks-encode|$PROMPTS_DIR/cogworks-encode-explicit.txt"
  "cogworks-encode|$PROMPTS_DIR/cogworks-encode-mid-conversation.txt"
)

run_case() {
  local skill="$1"
  local prompt_file="$2"
  local name
  name="$(basename "$prompt_file" .txt)"
  local log="$OUT_DIR/$name.jsonl"
  local prompt
  prompt="$(cat "$prompt_file")"

  if [[ "$RUNNER" == "claude" ]]; then
    timeout "$TIMEOUT_SEC" claude -p --output-format stream-json --permission-mode default "$prompt" > "$log" 2>&1 || true
  else
    timeout "$TIMEOUT_SEC" codex exec --json --sandbox workspace-write "$prompt" > "$log" 2>&1 || true
  fi

  local pattern
  pattern='"skill":"([^"]*:)?'"$skill"'"'
  if grep -q '"name":"Skill"' "$log" && grep -Eq "$pattern" "$log"; then
    echo "PASS  $name ($skill)"
    return 0
  fi

  echo "FAIL  $name ($skill)"
  echo "  log: $log"
  return 1
}

passed=0
failed=0
for entry in "${cases[@]}"; do
  skill="${entry%%|*}"
  prompt_file="${entry##*|}"
  if run_case "$skill" "$prompt_file"; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi
done

echo ""
echo "Runner: $RUNNER"
echo "Passed: $passed"
echo "Failed: $failed"
echo "Logs:   $OUT_DIR"

if [[ $failed -gt 0 ]]; then
  exit 1
fi

