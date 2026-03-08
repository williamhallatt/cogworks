#!/bin/bash
set -euo pipefail

REPORT_PATH=""
SKILL_PATH=""
LABEL="fail-closed run"
EXPECT_PATTERNS=()
FAILURES=0

usage() {
  cat <<'USAGE'
Usage: tests/validate-fail-closed-run.sh --report-path <path> [options]

Options:
  --report-path <path>      Blocking report artifact to validate (required)
  --skill-path <path>       Optional skill output path that must not contain SKILL.md
  --expect-pattern <text>   Text that must appear in the report (repeatable)
  --label <text>            Friendly label for output
USAGE
}

pass() {
  echo "PASS  $1"
}

fail() {
  echo "FAIL  $1" >&2
  FAILURES=$((FAILURES + 1))
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --report-path)
      REPORT_PATH="$2"
      shift 2
      ;;
    --skill-path)
      SKILL_PATH="$2"
      shift 2
      ;;
    --expect-pattern)
      EXPECT_PATTERNS+=("$2")
      shift 2
      ;;
    --label)
      LABEL="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$REPORT_PATH" ]]; then
  usage >&2
  exit 2
fi

if [[ -s "$REPORT_PATH" ]]; then
  pass "$LABEL report exists and is non-empty"
else
  fail "$LABEL report exists and is non-empty"
fi

for pattern in "${EXPECT_PATTERNS[@]}"; do
  if grep -Fq "$pattern" "$REPORT_PATH"; then
    pass "$LABEL report contains '$pattern'"
  else
    fail "$LABEL report contains '$pattern'"
  fi
done

if [[ -n "$SKILL_PATH" ]]; then
  if [[ -f "$SKILL_PATH/SKILL.md" ]]; then
    fail "$LABEL did not produce an installable SKILL.md"
  else
    pass "$LABEL did not produce an installable SKILL.md"
  fi
fi

if [[ $FAILURES -gt 0 ]]; then
  echo ""
  echo "Fail-closed validation failed with $FAILURES issue(s)." >&2
  exit 1
fi

echo ""
echo "Fail-closed validation passed."
