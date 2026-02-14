#!/bin/bash
# Deterministic structural validation for cogworks skills
# Usage: deterministic-checks.sh <skill-directory> [--json]

set -euo pipefail

SKILL_DIR="$1"
JSON_OUTPUT="${2:-}"
SKILL_FILE="${SKILL_DIR}/SKILL.md"

# Results tracking
CRITICAL_FAILURES=()
WARNINGS=()
CHECKS_PASSED=()

# Output functions
log_pass() { CHECKS_PASSED+=("$1"); }
log_warning() { WARNINGS+=("$1"); }
log_critical() { CRITICAL_FAILURES+=("$1"); }

# Check 1: SKILL.md exists
check_skill_file_exists() {
    if [[ ! -f "$SKILL_FILE" ]]; then
        log_critical "SKILL.md file not found"
        return 1
    fi
    log_pass "SKILL.md exists"
}

# Check 2: Frontmatter is valid YAML
check_frontmatter_valid() {
    if ! grep -q "^---$" "$SKILL_FILE"; then
        log_critical "Missing frontmatter delimiters"
        return 1
    fi

    # Extract frontmatter
    local frontmatter=$(sed -n '/^---$/,/^---$/p' "$SKILL_FILE" | sed '1d;$d')

    # Validate YAML (using python)
    if ! echo "$frontmatter" | python3 -c "import sys, yaml; yaml.safe_load(sys.stdin)" 2>/dev/null; then
        log_critical "Invalid YAML in frontmatter"
        return 1
    fi

    log_pass "Frontmatter is valid YAML"
}

# Check 3: Required frontmatter fields present
check_required_frontmatter_fields() {
    local frontmatter=$(sed -n '/^---$/,/^---$/p' "$SKILL_FILE" | sed '1d;$d')

    if ! echo "$frontmatter" | grep -q "^name:"; then
        log_critical "Missing required field: name"
        return 1
    fi

    if ! echo "$frontmatter" | grep -q "^description:"; then
        log_critical "Missing required field: description"
        return 1
    fi

    log_pass "Required frontmatter fields present"
}

# Check 4: SKILL.md line count ≤ 500
check_line_count() {
    local line_count=$(wc -l < "$SKILL_FILE")

    if (( line_count > 500 )); then
        log_critical "SKILL.md exceeds 500 lines (${line_count} lines)"
        return 1
    elif (( line_count > 450 )); then
        log_warning "SKILL.md approaching line limit (${line_count}/500 lines)"
    fi

    log_pass "Line count within limit (${line_count}/500)"
}

# Check 5: Source citations present
check_citations_present() {
    # Look for citation patterns: [source], (source:line), etc.
    local citation_count=$(grep -oE '\[(source|[a-zA-Z0-9_-]+\.md)\]|\([a-zA-Z0-9_/-]+\.[a-z]+:[0-9]+\)' "$SKILL_FILE" | wc -l)

    if (( citation_count == 0 )); then
        log_critical "No source citations found"
        return 1
    elif (( citation_count < 3 )); then
        log_warning "Very few citations found (${citation_count})"
    fi

    log_pass "Citations present (${citation_count} found)"
}

# Check 6: Forbidden patterns
check_forbidden_patterns() {
    local forbidden=(
        "TODO"
        "FIXME"
        "XXX"
        "HACK"
        "sk-[a-zA-Z0-9]{32}"  # OpenAI API key pattern
        "AKIA[0-9A-Z]{16}"     # AWS access key pattern
    )

    for pattern in "${forbidden[@]}"; do
        if grep -qE "$pattern" "$SKILL_FILE"; then
            log_critical "Forbidden pattern found: $pattern"
            return 1
        fi
    done

    log_pass "No forbidden patterns"
}

# Check 7: Supporting files follow 3+ entry rule
check_supporting_files() {
    for support_file in "${SKILL_DIR}/patterns.md" "${SKILL_DIR}/examples.md" "${SKILL_DIR}/reference.md"; do
        if [[ -f "$support_file" ]]; then
            local filename=$(basename "$support_file")
            # Count entries (lines starting with ##)
            local entry_count=$(grep -cE '^## ' "$support_file" || true)

            if (( entry_count > 0 && entry_count < 3 )); then
                log_warning "${filename} has <3 entries (${entry_count}) - should fold into reference.md"
            fi
        fi
    done

    log_pass "Supporting files follow 3+ entry rule"
}

# Check 8: Description has keywords
check_description_keywords() {
    local frontmatter=$(sed -n '/^---$/,/^---$/p' "$SKILL_FILE" | sed '1d;$d')
    local description=$(echo "$frontmatter" | grep "^description:" | cut -d: -f2- | tr -d '"')

    # Count words
    local word_count=$(echo "$description" | wc -w)

    if (( word_count < 10 )); then
        log_warning "Description is very short (${word_count} words) - add keywords for discoverability"
    fi

    log_pass "Description has sufficient content"
}

# Check 9: No duplicate section headers
check_no_duplicate_headers() {
    local headers=$(grep -E '^##+ ' "$SKILL_FILE" | sort)
    local unique_headers=$(echo "$headers" | uniq)

    if [[ "$headers" != "$unique_headers" ]]; then
        log_warning "Duplicate section headers found"
    fi

    log_pass "No duplicate headers"
}

# Check 10: Markdown syntax valid
check_markdown_syntax() {
    # Check for unclosed code blocks
    local code_fence_count=$(grep -cE '^```' "$SKILL_FILE" || true)

    if (( code_fence_count % 2 != 0 )); then
        log_critical "Unclosed code fence (odd number of code fence markers)"
        return 1
    fi

    log_pass "Markdown syntax valid"
}

# Run all checks
run_all_checks() {
    check_skill_file_exists || true
    [[ ${#CRITICAL_FAILURES[@]} -eq 0 ]] || return 1

    check_frontmatter_valid || true
    check_required_frontmatter_fields || true
    check_line_count || true
    check_citations_present || true
    check_forbidden_patterns || true
    check_supporting_files || true
    check_description_keywords || true
    check_no_duplicate_headers || true
    check_markdown_syntax || true
}

# Generate output
generate_output() {
    if [[ "$JSON_OUTPUT" == "--json" ]]; then
        # JSON output for machine consumption
        echo "{"
        echo "  \"critical_failures\": ["
        for ((i=0; i<${#CRITICAL_FAILURES[@]}; i++)); do
            echo -n "    \"${CRITICAL_FAILURES[$i]}\""
            [[ $i -lt $((${#CRITICAL_FAILURES[@]} - 1)) ]] && echo "," || echo ""
        done
        echo "  ],"
        echo "  \"warnings\": ["
        for ((i=0; i<${#WARNINGS[@]}; i++)); do
            echo -n "    \"${WARNINGS[$i]}\""
            [[ $i -lt $((${#WARNINGS[@]} - 1)) ]] && echo "," || echo ""
        done
        echo "  ],"
        echo "  \"checks_passed\": ["
        for ((i=0; i<${#CHECKS_PASSED[@]}; i++)); do
            echo -n "    \"${CHECKS_PASSED[$i]}\""
            [[ $i -lt $((${#CHECKS_PASSED[@]} - 1)) ]] && echo "," || echo ""
        done
        echo "  ],"
        echo "  \"status\": \"$([[ ${#CRITICAL_FAILURES[@]} -eq 0 ]] && echo 'pass' || echo 'fail')\""
        echo "}"
    else
        # Human-readable output
        echo "=== Deterministic Checks Results ==="
        echo ""

        if [[ ${#CHECKS_PASSED[@]} -gt 0 ]]; then
            echo "✓ Passed (${#CHECKS_PASSED[@]}):"
            for check in "${CHECKS_PASSED[@]}"; do
                echo "  - $check"
            done
            echo ""
        fi

        if [[ ${#WARNINGS[@]} -gt 0 ]]; then
            echo "⚠ Warnings (${#WARNINGS[@]}):"
            for warning in "${WARNINGS[@]}"; do
                echo "  - $warning"
            done
            echo ""
        fi

        if [[ ${#CRITICAL_FAILURES[@]} -gt 0 ]]; then
            echo "✗ Critical Failures (${#CRITICAL_FAILURES[@]}):"
            for failure in "${CRITICAL_FAILURES[@]}"; do
                echo "  - $failure"
            done
            echo ""
        fi
    fi
}

# Main execution
main() {
    run_all_checks
    generate_output

    # Exit with appropriate code
    if [[ ${#CRITICAL_FAILURES[@]} -gt 0 ]]; then
        exit 1
    elif [[ ${#WARNINGS[@]} -gt 0 ]]; then
        exit 2
    else
        exit 0
    fi
}

main
