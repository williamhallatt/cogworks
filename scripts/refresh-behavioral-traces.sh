#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EVAL_CLI="$ROOT_DIR/tests/framework/scripts/cogworks-eval.py"
NORMALIZER="$ROOT_DIR/tests/framework/scripts/capture_behavioral_trace.py"

TESTS_ROOT="$ROOT_DIR/tests/behavioral"
RAW_ROOT="/tmp/cogworks-behavioral-raw"
MODE="all" # capture|validate|all
SKILLS=()

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --skill <slug>         Skill slug to process (repeatable). Default: cogworks-learn + cogworks-encode
  --tests-root <path>    Behavioral tests root (default: tests/behavioral)
  --raw-root <path>      Raw trace workspace (default: /tmp/cogworks-behavioral-raw)
  --mode <mode>          capture | validate | all (default: all)
  -h, --help             Show this help

Required env for capture mode:
  COGWORKS_BEHAVIORAL_CLAUDE_CAPTURE_CMD
  COGWORKS_BEHAVIORAL_CODEX_CAPTURE_CMD

Capture command placeholders:
  {skill_slug} {case_id} {case_json_path} {raw_trace_path}
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skill)
      SKILLS+=("$2")
      shift 2
      ;;
    --tests-root)
      TESTS_ROOT="$2"
      shift 2
      ;;
    --raw-root)
      RAW_ROOT="$2"
      shift 2
      ;;
    --mode)
      MODE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ "$MODE" != "capture" && "$MODE" != "validate" && "$MODE" != "all" ]]; then
  echo "--mode must be capture, validate, or all." >&2
  exit 2
fi

if [[ ${#SKILLS[@]} -eq 0 ]]; then
  SKILLS=("cogworks-learn" "cogworks-encode")
fi

if [[ "$MODE" == "capture" || "$MODE" == "all" ]]; then
  if [[ -z "${COGWORKS_BEHAVIORAL_CLAUDE_CAPTURE_CMD:-}" ]]; then
    echo "Missing COGWORKS_BEHAVIORAL_CLAUDE_CAPTURE_CMD for capture mode." >&2
    exit 2
  fi
  if [[ -z "${COGWORKS_BEHAVIORAL_CODEX_CAPTURE_CMD:-}" ]]; then
    echo "Missing COGWORKS_BEHAVIORAL_CODEX_CAPTURE_CMD for capture mode." >&2
    exit 2
  fi
fi

mkdir -p "$RAW_ROOT"

run_capture_cmd() {
  local template="$1"
  local skill_slug="$2"
  local case_id="$3"
  local case_json_path="$4"
  local raw_trace_path="$5"

  local cmd="$template"
  cmd="${cmd//\{skill_slug\}/$skill_slug}"
  cmd="${cmd//\{case_id\}/$case_id}"
  cmd="${cmd//\{case_json_path\}/$case_json_path}"
  cmd="${cmd//\{raw_trace_path\}/$raw_trace_path}"

  # Prevent capture commands from consuming the case iterator stdin.
  bash -lc "$cmd" </dev/null
}

extract_case_lines() {
  local cases_path="$1"
  python3 - "$cases_path" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
for raw in path.read_text(encoding="utf-8").splitlines():
    line = raw.strip()
    if not line:
        continue
    item = json.loads(line)
    print(json.dumps(item, separators=(",", ":")))
PY
}

compare_normalized_behavior() {
  local case_json_path="$1"
  local left="$2"
  local right="$3"
  python3 - "$case_json_path" "$left" "$right" <<'PY'
import json
import sys
from pathlib import Path

case = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
left = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
right = json.loads(Path(sys.argv[3]).read_text(encoding="utf-8"))

keys = [
    "skill_slug",
    "case_id",
    "activated",
    "tools_used",
    "commands",
    "files_modified",
    "files_created",
    "task_completed",
    "quality_score",
    "baseline_run",
]

diffs = []
for key in keys:
    if left.get(key) != right.get(key):
        diffs.append(key)

if not diffs:
    print("claude")
    raise SystemExit(0)

category = str(case.get("category", "")).strip().lower()
evidence = str(case.get("activation_evidence", "allow_fallback")).strip().lower()

if diffs == ["activated"] and category in {"implicit", "contextual"} and evidence == "allow_fallback":
    should_activate = bool(case.get("should_activate"))
    left_activated = bool(left.get("activated"))
    right_activated = bool(right.get("activated"))

    if should_activate:
        if left_activated and not right_activated:
            print("claude")
            raise SystemExit(0)
        if right_activated and not left_activated:
            print("codex")
            raise SystemExit(0)
    else:
        if not left_activated and right_activated:
            print("claude")
            raise SystemExit(0)
        if not right_activated and left_activated:
            print("codex")
            raise SystemExit(0)

print(f"mismatch:{','.join(diffs)}", file=sys.stderr)
raise SystemExit(1)
PY
}

capture_skill_cases() {
  local skill_slug="$1"
  local cases_path="$TESTS_ROOT/$skill_slug/test-cases.jsonl"
  local traces_dir="$TESTS_ROOT/$skill_slug/traces"

  if [[ ! -f "$cases_path" ]]; then
    echo "Missing test cases: $cases_path" >&2
    return 1
  fi

  mkdir -p "$traces_dir"
  local skill_raw_root="$RAW_ROOT/$skill_slug"
  mkdir -p "$skill_raw_root"

  while IFS= read -r case_json; do
    [[ -z "$case_json" ]] && continue
    local case_id
    case_id="$(python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["id"])' <<< "$case_json")"

    local case_json_path="$skill_raw_root/${case_id}.case.json"
    local raw_claude="$skill_raw_root/${case_id}.claude.raw.json"
    local raw_codex="$skill_raw_root/${case_id}.codex.raw.json"
    local norm_claude="$skill_raw_root/${case_id}.claude.norm.json"
    local norm_codex="$skill_raw_root/${case_id}.codex.norm.json"
    local final_trace="$traces_dir/${case_id}.json"

    printf '%s\n' "$case_json" > "$case_json_path"

    echo "Capturing $skill_slug/$case_id (claude)..."
    run_capture_cmd "$COGWORKS_BEHAVIORAL_CLAUDE_CAPTURE_CMD" \
      "$skill_slug" "$case_id" "$case_json_path" "$raw_claude"

    echo "Capturing $skill_slug/$case_id (codex)..."
    run_capture_cmd "$COGWORKS_BEHAVIORAL_CODEX_CAPTURE_CMD" \
      "$skill_slug" "$case_id" "$case_json_path" "$raw_codex"

    python3 "$NORMALIZER" \
      --pipeline claude \
      --skill-slug "$skill_slug" \
      --case-id "$case_id" \
      --raw-trace "$raw_claude" \
      --out "$norm_claude" \
      --harness "${COGWORKS_BEHAVIORAL_CLAUDE_HARNESS:-claude-code}" \
      --model "${COGWORKS_BEHAVIORAL_CLAUDE_MODEL:-claude-opus-4-6}" \
      --trace-source captured \
      --notes "Captured from claude pipeline"

    python3 "$NORMALIZER" \
      --pipeline codex \
      --skill-slug "$skill_slug" \
      --case-id "$case_id" \
      --raw-trace "$raw_codex" \
      --out "$norm_codex" \
      --harness "${COGWORKS_BEHAVIORAL_CODEX_HARNESS:-codex-cli}" \
      --model "${COGWORKS_BEHAVIORAL_CODEX_MODEL:-gpt-5-codex}" \
      --trace-source captured \
      --notes "Captured from codex pipeline"

    local shared_source
    if ! shared_source="$(compare_normalized_behavior "$case_json_path" "$norm_claude" "$norm_codex")"; then
      echo "Behavior mismatch between pipelines for $skill_slug/$case_id." >&2
      echo "Claude trace: $norm_claude" >&2
      echo "Codex trace:  $norm_codex" >&2
      echo "Resolve mismatch before writing shared trace." >&2
      return 1
    fi

    local shared_raw="$raw_claude"
    if [[ "$shared_source" == "codex" ]]; then
      shared_raw="$raw_codex"
      echo "Using codex raw trace as shared baseline for $skill_slug/$case_id due to tolerated activation mismatch."
    fi

    python3 "$NORMALIZER" \
      --pipeline shared \
      --skill-slug "$skill_slug" \
      --case-id "$case_id" \
      --raw-trace "$shared_raw" \
      --out "$final_trace" \
      --harness "shared-harness" \
      --model "shared-model" \
      --trace-source captured \
      --notes "Captured and parity-checked across claude+codex pipelines"

    echo "Wrote shared trace: $final_trace"
  done < <(extract_case_lines "$cases_path")
}

validate_strict() {
  local skills_args=()
  local skill
  for skill in "${SKILLS[@]}"; do
    skills_args+=(--skill "$skill")
  done

  echo "Running strict behavioral validation for Claude..."
  python3 "$EVAL_CLI" behavioral run \
    --skills-root "$ROOT_DIR/.claude/skills" \
    --tests-root "$TESTS_ROOT" \
    --strict-provenance \
    "${skills_args[@]}"

  echo "Running strict behavioral validation for Codex..."
  python3 "$EVAL_CLI" behavioral run \
    --skills-root "$ROOT_DIR/.agents/skills" \
    --tests-root "$TESTS_ROOT" \
    --strict-provenance \
    "${skills_args[@]}"
}

if [[ "$MODE" == "capture" || "$MODE" == "all" ]]; then
  for skill in "${SKILLS[@]}"; do
    capture_skill_cases "$skill"
  done
fi

if [[ "$MODE" == "validate" || "$MODE" == "all" ]]; then
  validate_strict
fi

echo "Behavioral trace refresh complete."
