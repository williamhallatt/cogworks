#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_RUN_ROOT=""
CLAUDE_SKILL_PATH=""
COPILOT_RUN_ROOT=""
COPILOT_SKILL_PATH=""
FAIL_CLOSED_REPORT=""
FAIL_CLOSED_SKILL_PATH=""
BENCHMARK_SUMMARY=""
FAIL_CLOSED_PATTERNS=()

usage() {
  cat <<'USAGE'
Usage: tests/run-release-validation.sh [options]

Required options:
  --claude-run-root <path>
  --claude-skill-path <path>
  --copilot-run-root <path>
  --copilot-skill-path <path>
  --fail-closed-report <path>
  --benchmark-summary <path>

Optional:
  --fail-closed-skill-path <path>
  --fail-closed-pattern <text>   Repeatable required text in the blocking report
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --claude-run-root)
      CLAUDE_RUN_ROOT="$2"
      shift 2
      ;;
    --claude-skill-path)
      CLAUDE_SKILL_PATH="$2"
      shift 2
      ;;
    --copilot-run-root)
      COPILOT_RUN_ROOT="$2"
      shift 2
      ;;
    --copilot-skill-path)
      COPILOT_SKILL_PATH="$2"
      shift 2
      ;;
    --fail-closed-report)
      FAIL_CLOSED_REPORT="$2"
      shift 2
      ;;
    --fail-closed-skill-path)
      FAIL_CLOSED_SKILL_PATH="$2"
      shift 2
      ;;
    --fail-closed-pattern)
      FAIL_CLOSED_PATTERNS+=("$2")
      shift 2
      ;;
    --benchmark-summary)
      BENCHMARK_SUMMARY="$2"
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

for required in \
  CLAUDE_RUN_ROOT \
  CLAUDE_SKILL_PATH \
  COPILOT_RUN_ROOT \
  COPILOT_SKILL_PATH \
  FAIL_CLOSED_REPORT \
  BENCHMARK_SUMMARY; do
  if [[ -z "${!required}" ]]; then
    usage >&2
    exit 2
  fi
done

echo "=== Offline Bar ==="
bash "$ROOT_DIR/tests/run-all.sh"

echo ""
echo "=== Claude Release Evidence ==="
bash "$ROOT_DIR/scripts/validate-agentic-run.sh" \
  --run-root "$CLAUDE_RUN_ROOT" \
  --skill-path "$CLAUDE_SKILL_PATH" \
  --expect-surface claude-cli

echo ""
echo "=== Copilot Release Evidence ==="
bash "$ROOT_DIR/scripts/validate-agentic-run.sh" \
  --run-root "$COPILOT_RUN_ROOT" \
  --skill-path "$COPILOT_SKILL_PATH" \
  --expect-surface copilot-cli

echo ""
echo "=== Fail-Closed Evidence ==="
FAIL_CLOSED_ARGS=(
  --report-path "$FAIL_CLOSED_REPORT"
  --label "release fail-closed evidence"
)
if [[ -n "$FAIL_CLOSED_SKILL_PATH" ]]; then
  FAIL_CLOSED_ARGS+=(--skill-path "$FAIL_CLOSED_SKILL_PATH")
fi
for pattern in "${FAIL_CLOSED_PATTERNS[@]}"; do
  FAIL_CLOSED_ARGS+=(--expect-pattern "$pattern")
done
bash "$ROOT_DIR/tests/validate-fail-closed-run.sh" "${FAIL_CLOSED_ARGS[@]}"

echo ""
echo "=== Benchmark Release Evidence ==="
python3 - "$ROOT_DIR/evals/skill-benchmark/benchmark-summary.schema.json" "$BENCHMARK_SUMMARY" <<'PY'
import json
import sys
from jsonschema import Draft202012Validator

schema = json.load(open(sys.argv[1], encoding="utf-8"))
summary = json.load(open(sys.argv[2], encoding="utf-8"))
Draft202012Validator(schema).validate(summary)

assert summary["schema_validation_passed"] is True
assert summary["decision_eligible"] is True
assert summary["replay_evidence_present"] is False
assert summary["terminal_status"] == "completed"
assert summary["judge_model"] not in (None, "")
assert summary["trial_count"] >= 5
assert summary["confidence_interval_95"][0] > 0
PY

echo "PASS  benchmark summary is decision-grade release evidence"

echo ""
echo "Release validation passed."
