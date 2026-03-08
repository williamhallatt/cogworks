#!/bin/bash
# Unified test runner — executes all headless suites in sequence.
# Exit 0 = all passed, exit 1 = any failed.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SUITES=(
  "Layer 1 — Black-box tests|run-black-box-tests.sh"
  "Layer 2 — Trigger smoke parser|run-trigger-smoke-parser-smoke.sh"
  "Layer 3 — Agentic contract smoke|run-agentic-contract-smoke.sh"
  "Layer 4 — Skill benchmark smoke|run-skill-benchmark-smoke.sh"
  "Schema validation|run-schema-validation-smoke.sh"
)

PASSED=0
FAILED=0
FAILED_NAMES=()

for entry in "${SUITES[@]}"; do
  label="${entry%%|*}"
  script="${entry##*|}"

  echo ""
  echo "================================================================"
  echo "  $label"
  echo "================================================================"

  if bash "$SCRIPT_DIR/$script"; then
    PASSED=$((PASSED + 1))
  else
    FAILED=$((FAILED + 1))
    FAILED_NAMES+=("$label")
  fi
done

echo ""
echo "================================================================"
echo "  SUMMARY: $PASSED passed, $FAILED failed"
echo "================================================================"

if [[ $FAILED -gt 0 ]]; then
  for name in "${FAILED_NAMES[@]}"; do
    echo "  FAILED: $name"
  done
  exit 1
fi

echo "  All suites passed."
exit 0
