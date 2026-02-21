#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXTRACTOR="$ROOT_DIR/tests/framework/scripts/extract_behavioral_raw_trace.py"

usage() {
  cat <<'EOF' >&2
Usage: scripts/run-behavioral-case-codex.sh <skill_slug> <case_id> <case_json_path> <raw_trace_path>
EOF
}

read_case_field() {
  local case_json_path="$1"
  local field_name="$2"
  local default_value="${3:-}"
  python3 - "$case_json_path" "$field_name" "$default_value" <<'PY'
import json
import sys
from pathlib import Path

payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
field_name = sys.argv[2]
default_value = sys.argv[3]
value = payload.get(field_name, default_value)
if value is None:
    value = default_value
if isinstance(value, str):
    print(value)
else:
    print(str(value))
PY
}

build_prompt_from_case() {
  local case_json_path="$1"
  python3 - "$case_json_path" <<'PY'
import json
import sys
from pathlib import Path

payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
mode = str(payload.get("harness_mode", "activation_only")).strip().lower()
request = payload.get("user_request")
turns = payload.get("conversation_turns")

conversation_turns = []
if isinstance(turns, list):
    conversation_turns = [t.strip() for t in turns if isinstance(t, str) and t.strip()]
if (not isinstance(request, str) or not request.strip()) and conversation_turns:
    request = conversation_turns[-1]
if not isinstance(request, str) or not request.strip():
    raise SystemExit("case json missing non-empty user_request or conversation_turns")

request = request.strip()
if conversation_turns:
    prior_turns = conversation_turns[:-1]
    latest_turn = conversation_turns[-1]
else:
    prior_turns = []
    latest_turn = request

if mode == "realistic":
    lines = [
        "You are running a behavioral activation test harness.",
        "",
        "Treat this as a realistic conversation and respond naturally.",
    ]
    if prior_turns:
        lines.extend(["", "Conversation so far:"])
        lines.extend([f"- User: {turn}" for turn in prior_turns])
    lines.extend(["", "Latest user message:", latest_turn])
    print("\n".join(lines))
    raise SystemExit(0)

lines = [
    "You are running a behavioral activation test harness.",
    "",
    "Hard constraints:",
    "- Do not run shell commands.",
    "- Do not modify or create files.",
    "- Do not invoke editing tools.",
    "- Return a concise plain-text answer only.",
    "",
    "User request:",
    request,
]
print("\n".join(lines))
PY
}

setup_isolated_home() {
  local case_json_path="$1"
  local isolation_mode
  isolation_mode="$(read_case_field "$case_json_path" "isolation_mode" "default")"
  if [[ "$isolation_mode" != "isolated_home" ]]; then
    return 0
  fi
  ISOLATED_HOME="$(mktemp -d)"
  export HOME="$ISOLATED_HOME"
  trap 'rm -rf "$ISOLATED_HOME"' EXIT
}

validate_events_health() {
  local events_path="$1"
  python3 - "$events_path" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
if not path.exists():
    raise SystemExit("events file missing")

has_terminal = False
for raw in path.read_text(encoding="utf-8").splitlines():
    line = raw.strip()
    if not line:
        continue
    try:
        item = json.loads(line)
    except Exception:
        continue
    if not isinstance(item, dict):
        continue

    item_type = str(item.get("type", ""))
    if item_type in {"turn.completed", "task_complete"}:
        has_terminal = True
    if item_type in {"turn.failed", "error"}:
        message = item.get("message") or item.get("error", "")
        raise SystemExit(f"codex stream reported {item_type}: {message}")

if not has_terminal:
    raise SystemExit("codex stream missing successful terminal event")
PY
}

if [[ $# -ne 4 ]]; then
  usage
  exit 2
fi

skill_slug="$1"
case_id="$2"
case_json_path="$3"
raw_trace_path="$4"

events_root="${COGWORKS_BEHAVIORAL_EVENTS_ROOT:-/tmp/cogworks-behavioral-raw}"
timeout_sec="${COGWORKS_BEHAVIORAL_CODEX_TIMEOUT_SEC:-900}"
events_dir="$events_root/$skill_slug"
events_path="$events_dir/${case_id}.codex.events.jsonl"
mkdir -p "$events_dir"

setup_isolated_home "$case_json_path"
prompt="$(build_prompt_from_case "$case_json_path")"

set +e
timeout "$timeout_sec" codex exec --json --sandbox workspace-write "$prompt" > "$events_path"
status=$?
set -e
if [[ $status -ne 0 ]]; then
  echo "codex behavioral capture command failed (exit $status): $case_id" >&2
  echo "events: $events_path" >&2
  exit "$status"
fi

validate_events_health "$events_path"

python3 "$EXTRACTOR" \
  --pipeline codex \
  --skill-slug "$skill_slug" \
  --case-id "$case_id" \
  --case-json-path "$case_json_path" \
  --events-jsonl "$events_path" \
  --out "$raw_trace_path"
