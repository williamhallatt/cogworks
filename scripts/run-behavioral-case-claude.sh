#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXTRACTOR="$ROOT_DIR/tests/framework/scripts/extract_behavioral_raw_trace.py"

usage() {
  cat <<'EOF' >&2
Usage: scripts/run-behavioral-case-claude.sh <skill_slug> <case_id> <case_json_path> <raw_trace_path>
EOF
}

read_user_request() {
  local case_json_path="$1"
  python3 - "$case_json_path" <<'PY'
import json
import sys
from pathlib import Path

payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
request = payload.get("user_request")
if not isinstance(request, str) or not request.strip():
    raise SystemExit("case json missing non-empty user_request")
print(request)
PY
}

build_prompt() {
  local user_request="$1"
  cat <<EOF
You are running a behavioral activation test harness.

Hard constraints:
- Do not run shell commands.
- Do not modify or create files.
- Do not invoke editing tools.
- Return a concise plain-text answer only.

User request:
$user_request
EOF
}

validate_events_health() {
  local events_path="$1"
  local stderr_path="$2"
  python3 - "$events_path" "$stderr_path" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
stderr_path = Path(sys.argv[2])
if not path.exists():
    raise SystemExit("events file missing")

has_result = False
assistant_texts = []
interrupted = False
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
    if item.get("type") == "assistant":
        message = item.get("message")
        if isinstance(message, dict):
            for block in message.get("content", []) or []:
                if isinstance(block, dict) and isinstance(block.get("text"), str):
                    assistant_texts.append(block["text"])
    if item.get("type") == "user":
        message = item.get("message")
        if isinstance(message, dict):
            for block in message.get("content", []) or []:
                if isinstance(block, dict) and block.get("text") == "[Request interrupted by user]":
                    interrupted = True
    if item.get("type") == "result":
        has_result = True
        if item.get("subtype") == "error_during_execution":
            details = []
            if interrupted:
                details.append(
                    "request interrupted before execution (often environment/session policy interruption)"
                )
            if assistant_texts:
                details.append(assistant_texts[-1].strip())
            if stderr_path.exists():
                stderr_text = stderr_path.read_text(encoding="utf-8").strip()
                if stderr_text:
                    details.append(f"stderr: {stderr_text}")
            suffix = f": {' | '.join(details)}" if details else ""
            raise SystemExit(f"claude stream reported error_during_execution{suffix}")
        if bool(item.get("is_error", False)):
            details = []
            if assistant_texts:
                details.append(assistant_texts[-1].strip())
            if stderr_path.exists():
                stderr_text = stderr_path.read_text(encoding="utf-8").strip()
                if stderr_text:
                    details.append(f"stderr: {stderr_text}")
            suffix = f": {' | '.join(details)}" if details else ""
            raise SystemExit(f"claude stream reported result.is_error=true{suffix}")
    if item.get("type") == "error":
        message = item.get("message", "unknown")
        raise SystemExit(f"claude stream error event: {message}")

if not has_result:
    extra = ""
    if stderr_path.exists():
        stderr_text = stderr_path.read_text(encoding="utf-8").strip()
        if stderr_text:
            extra = f" | stderr: {stderr_text}"
    raise SystemExit(f"claude stream missing result event{extra}")
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
timeout_sec="${COGWORKS_BEHAVIORAL_CLAUDE_TIMEOUT_SEC:-900}"
permission_mode="${COGWORKS_BEHAVIORAL_CLAUDE_PERMISSION_MODE:-default}"
events_dir="$events_root/$skill_slug"
events_path="$events_dir/${case_id}.claude.events.jsonl"
stderr_path="$events_dir/${case_id}.claude.stderr.log"
mkdir -p "$events_dir"

user_request="$(read_user_request "$case_json_path")"
prompt="$(build_prompt "$user_request")"

set +e
timeout "$timeout_sec" claude -p --verbose --output-format stream-json --permission-mode "$permission_mode" "$prompt" > "$events_path" 2> "$stderr_path"
status=$?
set -e
if [[ $status -ne 0 ]]; then
  echo "claude behavioral capture command failed (exit $status): $case_id" >&2
  echo "events: $events_path" >&2
  [[ -s "$stderr_path" ]] && echo "stderr: $stderr_path" >&2
  exit "$status"
fi

validate_events_health "$events_path" "$stderr_path"

python3 "$EXTRACTOR" \
  --pipeline claude \
  --skill-slug "$skill_slug" \
  --case-id "$case_id" \
  --case-json-path "$case_json_path" \
  --events-jsonl "$events_path" \
  --out "$raw_trace_path"
