#!/bin/bash
# Black-box test runner for cogworks-test framework
# Tests against documented promises, not implementation details

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_CASES="$SCRIPT_DIR/test-suite/mvp-test-cases.jsonl"
RESULTS_DIR="$SCRIPT_DIR/results/black-box-$(date +%Y%m%d-%H%M%S)"
LAYER1_SCRIPT="$PROJECT_ROOT/.claude/test-framework/graders/deterministic-checks.sh"

# Create results directory
mkdir -p "$RESULTS_DIR"

# Counters
PASSED=0
FAILED=0
SKIPPED=0

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Output functions
log_pass() {
    echo -e "${GREEN}✅ PASS${NC}: $1"
}

log_fail() {
    echo -e "${RED}❌ FAIL${NC}: $1"
}

log_skip() {
    echo -e "${YELLOW}⊘ SKIP${NC}: $1"
}

# Skill path resolution
resolve_skill_path() {
    local skill_name="$1"

    # Check if it's in .claude/skills/ (production skills)
    if [[ -d "$PROJECT_ROOT/.claude/skills/$skill_name" ]]; then
        echo "$PROJECT_ROOT/.claude/skills/$skill_name"
        return 0
    fi

    # Check if it's in tests/test-data/ (test fixtures)
    if [[ -d "$SCRIPT_DIR/test-data/$skill_name" ]]; then
        echo "$SCRIPT_DIR/test-data/$skill_name"
        return 0
    fi

    echo "ERROR: Skill not found: $skill_name" >&2
    return 1
}

# Test execution
run_test() {
    local test_id="$1"
    local test_name="$2"
    local description="$3"
    local input="$4"
    local expected_json="$5"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Running: $test_id - $test_name"
    echo "Description: $description"

    # Resolve skill path
    local skill_path
    if ! skill_path=$(resolve_skill_path "$input"); then
        log_fail "$test_id - Skill not found: $input"
        FAILED=$((FAILED + 1))
        echo "$test_id,FAIL,Skill not found: $input" >> "$RESULTS_DIR/summary.csv"
        return 1
    fi

    # Execute Layer 1 deterministic checks
    local output_file="$RESULTS_DIR/${test_id}-output.json"
    local exit_code=0

    bash "$LAYER1_SCRIPT" "$skill_path" --json > "$output_file" 2>&1 || exit_code=$?

    # Parse expected values
    local expected_status=$(echo "$expected_json" | jq -r '.status // empty')
    local expected_exit_code=$(echo "$expected_json" | jq -r '.exit_code // empty')
    local expected_critical=$(echo "$expected_json" | jq -r '.critical_failures // empty')
    local expected_min_critical=$(echo "$expected_json" | jq -r '.min_critical_failures // empty')
    local expected_warnings=$(echo "$expected_json" | jq -r '.warnings // empty')
    local expected_min_warnings=$(echo "$expected_json" | jq -r '.min_warnings // empty')
    local expected_checks=$(echo "$expected_json" | jq -r '.checks_passed // empty')
    local min_checks=$(echo "$expected_json" | jq -r '.min_checks_passed // empty')
    local failure_contains=$(echo "$expected_json" | jq -r '.failure_contains // empty')
    local warning_contains=$(echo "$expected_json" | jq -r '.warning_contains // empty')

    # Parse actual values
    local actual_status=$(jq -r '.status // "unknown"' "$output_file" 2>/dev/null || echo "parse_error")
    local actual_critical=$(jq -r '.critical_failures | length' "$output_file" 2>/dev/null || echo "0")
    local actual_warnings=$(jq -r '.warnings | length' "$output_file" 2>/dev/null || echo "0")
    local actual_checks=$(jq -r '.checks_passed | length' "$output_file" 2>/dev/null || echo "0")

    # Validation logic
    local pass=true
    local failure_reasons=()

    # Check status
    if [[ -n "$expected_status" && "$actual_status" != "$expected_status" ]]; then
        pass=false
        failure_reasons+=("Status mismatch: expected '$expected_status', got '$actual_status'")
    fi

    # Check exit code
    if [[ -n "$expected_exit_code" && "$exit_code" != "$expected_exit_code" ]]; then
        pass=false
        failure_reasons+=("Exit code mismatch: expected $expected_exit_code, got $exit_code")
    fi

    # Check critical failures count
    if [[ -n "$expected_critical" && "$actual_critical" != "$expected_critical" ]]; then
        pass=false
        failure_reasons+=("Critical failures mismatch: expected $expected_critical, got $actual_critical")
    fi

    # Check minimum critical failures
    if [[ -n "$expected_min_critical" && "$actual_critical" -lt "$expected_min_critical" ]]; then
        pass=false
        failure_reasons+=("Critical failures below minimum: expected >=$expected_min_critical, got $actual_critical")
    fi

    # Check warnings count
    if [[ -n "$expected_warnings" && "$actual_warnings" != "$expected_warnings" ]]; then
        pass=false
        failure_reasons+=("Warnings mismatch: expected $expected_warnings, got $actual_warnings")
    fi

    # Check minimum warnings
    if [[ -n "$expected_min_warnings" && "$actual_warnings" -lt "$expected_min_warnings" ]]; then
        pass=false
        failure_reasons+=("Warnings below minimum: expected >=$expected_min_warnings, got $actual_warnings")
    fi

    # Check checks passed count
    if [[ -n "$expected_checks" && "$actual_checks" != "$expected_checks" ]]; then
        pass=false
        failure_reasons+=("Checks passed mismatch: expected $expected_checks, got $actual_checks")
    fi

    # Check minimum checks passed
    if [[ -n "$min_checks" && "$actual_checks" -lt "$min_checks" ]]; then
        pass=false
        failure_reasons+=("Checks passed below minimum: expected >=$min_checks, got $actual_checks")
    fi

    # Check failure message contains
    if [[ -n "$failure_contains" ]]; then
        if ! jq -e ".critical_failures | any(contains(\"$failure_contains\"))" "$output_file" >/dev/null 2>&1; then
            pass=false
            failure_reasons+=("Critical failure message doesn't contain: '$failure_contains'")
        fi
    fi

    # Check warning message contains
    if [[ -n "$warning_contains" ]]; then
        if ! jq -e ".warnings | any(contains(\"$warning_contains\"))" "$output_file" >/dev/null 2>&1; then
            pass=false
            failure_reasons+=("Warning message doesn't contain: '$warning_contains'")
        fi
    fi

    # Report result
    if $pass; then
        log_pass "$test_id"
        PASSED=$((PASSED + 1))
        echo "$test_id,PASS" >> "$RESULTS_DIR/summary.csv"
    else
        log_fail "$test_id"
        echo "Failure reasons:"
        for reason in "${failure_reasons[@]}"; do
            echo "  - $reason"
        done
        FAILED=$((FAILED + 1))
        echo "$test_id,FAIL,${failure_reasons[0]}" >> "$RESULTS_DIR/summary.csv"
    fi

    # Save detailed results
    {
        echo "Test ID: $test_id"
        echo "Test Name: $test_name"
        echo "Description: $description"
        echo "Input: $input (resolved to: $skill_path)"
        echo "Exit Code: $exit_code"
        echo ""
        echo "Expected:"
        echo "$expected_json" | jq '.'
        echo ""
        echo "Actual:"
        jq '.' "$output_file"
        echo ""
        echo "Result: $(${pass} && echo "PASS" || echo "FAIL")"
        if ! $pass; then
            echo ""
            echo "Failure Reasons:"
            for reason in "${failure_reasons[@]}"; do
                echo "  - $reason"
            done
        fi
    } > "$RESULTS_DIR/${test_id}-report.txt"
}

# Main execution
main() {
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║   Black-Box Test Suite for cogworks-test Framework            ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Test cases: $TEST_CASES"
    echo "Results directory: $RESULTS_DIR"
    echo ""

    # Create summary CSV header
    echo "test_id,result,details" > "$RESULTS_DIR/summary.csv"

    # Read and execute tests
    while IFS= read -r test_case; do
        # Parse test case JSON
        test_id=$(echo "$test_case" | jq -r '.id')
        test_name=$(echo "$test_case" | jq -r '.test')
        description=$(echo "$test_case" | jq -r '.description')
        input=$(echo "$test_case" | jq -r '.input')
        expected=$(echo "$test_case" | jq -c '.expected')

        # Execute test
        run_test "$test_id" "$test_name" "$description" "$input" "$expected"

    done < "$TEST_CASES"

    # Print summary
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                      TEST RESULTS SUMMARY                       ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    local total=$((PASSED + FAILED + SKIPPED))
    local pass_rate=0
    if [[ $total -gt 0 ]]; then
        pass_rate=$((PASSED * 100 / total))
    fi

    echo "Total Tests:  $total"
    echo -e "${GREEN}Passed:       $PASSED${NC}"
    echo -e "${RED}Failed:       $FAILED${NC}"
    echo -e "${YELLOW}Skipped:      $SKIPPED${NC}"
    echo ""
    echo "Pass Rate:    ${pass_rate}%"
    echo ""
    echo "Detailed results saved to: $RESULTS_DIR"
    echo ""

    # Determine overall result (100% threshold — every test matters)
    if [[ $FAILED -eq 0 ]]; then
        echo -e "${GREEN}✅ ALL TESTS PASSED${NC}"
        exit 0
    else
        echo -e "${RED}❌ TESTS FAILED ($FAILED of $total failed)${NC}"
        exit 1
    fi
}

# Run main
main
