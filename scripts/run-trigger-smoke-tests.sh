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
       scripts/run-trigger-smoke-tests.sh --parse-log <claude|codex> <skill> <log>

Environment:
  TRIGGER_SMOKE_TIMEOUT_SEC   per-case timeout (default: 300)
  TRIGGER_SMOKE_OUT_ROOT      output directory root (default: /tmp/cogworks-trigger-smoke)
EOF
}

is_environment_blocked_log() {
  local log="$1"
  if grep -Eq 'ConnectionRefused|Unable to connect to API|failed to connect to websocket|Operation not permitted \(os error 1\)|error sending request for url|Falling back from WebSockets to HTTPS transport' "$log"; then
    return 0
  fi
  if [[ $(wc -l < "$log") -le 2 ]]; then
    return 0
  fi
  return 1
}

log_shows_activation() {
  local runner="$1"
  local skill="$2"
  local log="$3"

  if [[ "$runner" == "claude" ]]; then
    grep -Eq "\"name\":\"Skill\".*${skill}|\"arguments\":\"\\{\\\\\"name\\\\\":\\\\\"${skill}\\\\\"" "$log" || \
      grep -Fq "\"text\":\"Using \`${skill}\`" "$log"
    return
  fi

  grep -Fq "\"text\":\"Using \`${skill}\`" "$log" || grep -Eq "\"name\":\"Skill\".*${skill}" "$log"
}

parse_log_result() {
  local runner="$1"
  local skill="$2"
  local log="$3"

  if is_environment_blocked_log "$log"; then
    return 2
  fi
  if log_shows_activation "$runner" "$skill" "$log"; then
    return 0
  fi
  return 1
}

if [[ "${1:-}" == "--parse-log" ]]; then
  if [[ $# -ne 4 ]]; then
    usage >&2
    exit 2
  fi
  parse_log_result "$2" "$3" "$4"
  exit $?
fi

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
  "cogworks|$PROMPTS_DIR/cogworks-explicit.txt"
  "cogworks|$PROMPTS_DIR/cogworks-mid-conversation.txt"
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
    timeout "$TIMEOUT_SEC" claude -p --output-format stream-json --verbose --permission-mode default "$prompt" > "$log" 2>&1 || true
  else
    timeout "$TIMEOUT_SEC" codex exec --json --sandbox workspace-write "$prompt" > "$log" 2>&1 || true
  fi

  set +e
  parse_log_result "$RUNNER" "$skill" "$log"
  result=$?
  set -e
  if [[ $result -eq 0 ]]; then
    echo "PASS  $name ($skill)"
    return 0
  fi
  if [[ $result -eq 2 ]]; then
    echo "SKIP  $name ($skill)"
    echo "  runner connectivity blocked: $log"
    return 2
  fi

  echo "FAIL  $name ($skill)"
  if grep -q "Error:" "$log" || grep -q '"type":"error"' "$log"; then
    echo "  runner error in log: $log"
  fi
  echo "  log: $log"
  return 1
}

passed=0
failed=0
skipped=0
for entry in "${cases[@]}"; do
  skill="${entry%%|*}"
  prompt_file="${entry##*|}"
  if run_case "$skill" "$prompt_file"; then
    passed=$((passed + 1))
  else
    status=$?
    if [[ $status -eq 2 ]]; then
      skipped=$((skipped + 1))
    else
      failed=$((failed + 1))
    fi
  fi
done

echo ""
echo "Runner: $RUNNER"
echo "Passed: $passed"
echo "Failed: $failed"
echo "Skipped: $skipped"
echo "Logs:   $OUT_DIR"

if [[ $failed -gt 0 ]]; then
  exit 1
fi
