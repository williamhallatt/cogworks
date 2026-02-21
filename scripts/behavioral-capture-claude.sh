#!/bin/bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
Usage: scripts/behavioral-capture-claude.sh <skill_slug> <case_id> <case_json_path> <raw_trace_path>

Required environment:
  COGWORKS_BEHAVIORAL_CLAUDE_REAL_CMD

Template placeholders supported in COGWORKS_BEHAVIORAL_CLAUDE_REAL_CMD:
  {skill_slug} {case_id} {case_json_path} {raw_trace_path}
EOF
}

validate_raw_trace() {
  local raw_trace_path="$1"
  python3 - "$raw_trace_path" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
if not path.exists():
    print(f"missing raw trace output: {path}", file=sys.stderr)
    sys.exit(1)

try:
    payload = json.loads(path.read_text(encoding="utf-8"))
except Exception as exc:
    print(f"invalid raw trace JSON ({path}): {exc}", file=sys.stderr)
    sys.exit(1)

if not isinstance(payload, dict):
    print(f"raw trace must be a JSON object: {path}", file=sys.stderr)
    sys.exit(1)

required = {
    "activated": bool,
    "tools_used": list,
    "commands": list,
    "files_modified": list,
    "files_created": list,
}

for key, expected_type in required.items():
    if key not in payload:
        print(f"raw trace missing required key '{key}': {path}", file=sys.stderr)
        sys.exit(1)
    if not isinstance(payload[key], expected_type):
        print(
            f"raw trace key '{key}' must be {expected_type.__name__}: {path}",
            file=sys.stderr,
        )
        sys.exit(1)
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

template="${COGWORKS_BEHAVIORAL_CLAUDE_REAL_CMD:-}"
if [[ -z "$template" ]]; then
  echo "COGWORKS_BEHAVIORAL_CLAUDE_REAL_CMD is required." >&2
  echo "Example: export COGWORKS_BEHAVIORAL_CLAUDE_REAL_CMD=\"my-claude-capture --skill '{skill_slug}' --case '{case_id}' --case-json '{case_json_path}' --out '{raw_trace_path}'\"" >&2
  exit 2
fi

cmd="${template//\{skill_slug\}/$skill_slug}"
cmd="${cmd//\{case_id\}/$case_id}"
cmd="${cmd//\{case_json_path\}/$case_json_path}"
cmd="${cmd//\{raw_trace_path\}/$raw_trace_path}"

bash -lc "$cmd"
validate_raw_trace "$raw_trace_path"
