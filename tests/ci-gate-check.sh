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

# Step 2: Check for behavioral traces per skill
echo "Step 2/3: Checking for behavioral test coverage..."
MISSING_TRACES_SKILLS=()
TOTAL_TRACE_COUNT=0

for skill_dir in tests/behavioral/*/; do
    skill_name=$(basename "$skill_dir")
    count=$(find "${skill_dir}traces" -name "*.json" 2>/dev/null | wc -l || echo "0")
    TOTAL_TRACE_COUNT=$((TOTAL_TRACE_COUNT + count))
    if [ "$count" -eq 0 ]; then
        MISSING_TRACES_SKILLS+=("$skill_name")
    fi
done

if [ ${#MISSING_TRACES_SKILLS[@]} -gt 0 ]; then
    echo "✗ No behavioral traces found for skill(s): ${MISSING_TRACES_SKILLS[*]}"
    echo ""
    echo "  Behavioral traces were intentionally removed (D-022)."
    echo "  The prior traces were LLM-generated circular ground truth:"
    echo "    - quality_score: null on all core skill traces"
    echo "    - task_completed: false in baseline runs"
    echo "  These records validated consistency, not correctness."
    echo ""
    echo "  DO NOT regenerate traces with cogworks-eval.py — that recreates the same circular problem."
    echo "  Parker is responsible for defining quality ground truth as first-principles replacement."
    echo "  See .squad/agents/parker/charter.md and _plans/DECISIONS.md [D-022]."
    EXIT_CODE=1
else
    echo "✓ Found $TOTAL_TRACE_COUNT behavioral trace(s) across all skills"
fi
echo ""

# Step 3: Run behavioral evaluation if all skills have traces
echo "Step 3/3: Running behavioral evaluation..."
if [ ${#MISSING_TRACES_SKILLS[@]} -eq 0 ]; then
    if python3 tests/framework/scripts/cogworks-eval.py behavioral run --skill-prefix cogworks-; then
        echo "✓ Behavioral evaluation passed"
    else
        echo "✗ Behavioral evaluation failed"
        EXIT_CODE=1
    fi
else
    echo "⊘ Skipping behavioral eval (traces missing — see Step 2 error above)"
fi
echo ""

# Final result
if [ "$EXIT_CODE" -eq 0 ]; then
    echo "=== ✓ Pre-release CI gate: PASS ==="
else
    echo "=== ✗ Pre-release CI gate: FAIL ==="
fi

exit "$EXIT_CODE"
