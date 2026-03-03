#!/usr/bin/env bash
# Pre-release CI quality gate
# Runs deterministic checks, behavioral tests, and verifies test coverage
# Exit 0 on pass, exit 1 on fail

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "=== Pre-release CI Gate Check ==="
echo ""

EXIT_CODE=0

# Step 1: Run quality gates (deterministic checks)
echo "Step 1/3: Running quality gates (deterministic checks)..."
if bash scripts/validate-quality-gates.sh; then
    echo "✓ Quality gates passed"
else
    echo "✗ Quality gates failed"
    EXIT_CODE=1
fi
echo ""

# Step 2: Check for behavioral traces
echo "Step 2/3: Checking for behavioral test coverage..."
TRACE_COUNT=$(find tests/behavioral/cogworks-encode/traces -name "*.json" 2>/dev/null | wc -l || echo "0")
if [ "$TRACE_COUNT" -gt 0 ]; then
    echo "✓ Found $TRACE_COUNT behavioral trace(s)"
else
    echo "⚠ Warning: No behavioral traces found in tests/behavioral/cogworks-encode/"
    echo "  Run behavioral trace capture before release for full validation"
fi
echo ""

# Step 3: Run behavioral evaluation if traces exist
echo "Step 3/3: Running behavioral evaluation..."
if [ "$TRACE_COUNT" -gt 0 ]; then
    if python3 tests/framework/scripts/cogworks-eval.py behavioral run --skill-prefix cogworks-; then
        echo "✓ Behavioral evaluation passed"
    else
        echo "✗ Behavioral evaluation failed"
        EXIT_CODE=1
    fi
else
    echo "⊘ Skipping behavioral eval (no traces available)"
fi
echo ""

# Final result
if [ "$EXIT_CODE" -eq 0 ]; then
    echo "=== ✓ Pre-release CI gate: PASS ==="
else
    echo "=== ✗ Pre-release CI gate: FAIL ==="
fi

exit "$EXIT_CODE"
