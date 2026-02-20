#!/bin/bash
# Deterministic structural validation for cogworks skills
# Usage: deterministic-checks.sh <skill-directory> [--json]
#
# Thresholds (authoritative values — no external config file):
#   SKILL.md max lines:          500 (critical failure if exceeded)
#   SKILL.md warning threshold:  450 (warning if exceeded)
#   Minimum citations:           3   (warning if fewer, critical if zero)
#   Required frontmatter fields: name, description
#   Supporting file min entries: 3   (warning if fewer ## headings)
#   Description min words:       10  (warning if shorter)
#   Forbidden patterns:          TODO, FIXME, XXX, HACK, OpenAI key, AWS key
#   Name format:                 lowercase + numbers + hyphens, max 64 chars
#   Name reserved words:         anthropic, claude
#   Section substantiveness:     <20 words = thin; >50% thin = warning
#   Citation line plausibility:  >10000 = implausible
#
# Exit codes:
#   0 = all checks passed, no warnings
#   1 = critical failure(s) detected
#   2 = passed with warnings

set -euo pipefail

SKILL_DIR="$1"
JSON_OUTPUT="${2:-}"
SKILL_FILE="${SKILL_DIR}/SKILL.md"

# Citation patterns (strict):
#   [Source N]
#   (source:line) or (source-file:line)
CITATION_REGEX='\[Source [0-9]+\]|\((source|source-[a-zA-Z0-9_-]+|[a-zA-Z0-9_/-]+\.[a-zA-Z0-9]+):[0-9]+\)'

# Results tracking
CRITICAL_FAILURES=()
WARNINGS=()
CHECKS_PASSED=()
JQ_AVAILABLE=true
PYTHON_AVAILABLE=true

# Output functions
log_pass() { CHECKS_PASSED+=("$1"); }
log_warning() { WARNINGS+=("$1"); }
log_critical() { CRITICAL_FAILURES+=("$1"); }

# Check 0: Dependencies
check_dependencies() {
    if ! command -v python3 >/dev/null 2>&1; then
        PYTHON_AVAILABLE=false
        log_critical "Missing dependency: python3"
        return 1
    fi

    # PyYAML required for frontmatter validation
    if ! python3 -c "import yaml" >/dev/null 2>&1; then
        log_critical "Missing dependency: PyYAML for python3 (pip install pyyaml)"
        return 1
    fi

    # jq required only for JSON output
    if [[ "$JSON_OUTPUT" == "--json" ]]; then
        if ! command -v jq >/dev/null 2>&1; then
            JQ_AVAILABLE=false
            log_critical "Missing dependency: jq (required for --json output)"
            return 1
        fi
    fi

    log_pass "Dependencies available"
}

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

    # Extract frontmatter (only the first --- delimited block)
    local frontmatter=$(awk 'NR==1 && /^---$/{found=1; next} found && /^---$/{exit} found{print}' "$SKILL_FILE")

    # Validate YAML (using python)
    if ! echo "$frontmatter" | python3 -c "import sys, yaml; yaml.safe_load(sys.stdin)" 2>/dev/null; then
        log_critical "Invalid YAML in frontmatter"
        return 1
    fi

    log_pass "Frontmatter is valid YAML"
}

# Check 3: Required frontmatter fields present
check_required_frontmatter_fields() {
    local frontmatter=$(awk 'NR==1 && /^---$/{found=1; next} found && /^---$/{exit} found{print}' "$SKILL_FILE")

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

# Check 5: Source citations present (strict patterns, prefer supporting files)
check_citations_present() {
    local supporting_files=()
    local supporting_count=0
    local skill_citations=0
    local supporting_citations=0

    for support_file in "${SKILL_DIR}/reference.md" "${SKILL_DIR}/patterns.md" "${SKILL_DIR}/examples.md"; do
        if [[ -f "$support_file" ]]; then
            supporting_files+=("$support_file")
        fi
    done

    supporting_count=${#supporting_files[@]}

    if (( supporting_count > 0 )); then
        for support_file in "${supporting_files[@]}"; do
            local count
            count=$(grep -oE "$CITATION_REGEX" "$support_file" | wc -l)
            supporting_citations=$((supporting_citations + count))
        done

        if (( supporting_citations == 0 )); then
            log_critical "No source citations found in supporting files"
            return 1
        elif (( supporting_citations < 3 )); then
            log_warning "Very few citations found in supporting files (${supporting_citations})"
        fi

        log_pass "Citations present in supporting files (${supporting_citations} found)"
        return 0
    fi

    # Fallback: no supporting files exist, check SKILL.md
    skill_citations=$(grep -oE "$CITATION_REGEX" "$SKILL_FILE" | wc -l)

    if (( skill_citations == 0 )); then
        log_critical "No source citations found"
        return 1
    elif (( skill_citations < 3 )); then
        log_warning "Very few citations found (${skill_citations})"
    fi

    log_pass "Citations present (${skill_citations} found)"
}

# Check 6: Forbidden patterns (reports all matches, not just first)
check_forbidden_patterns() {
    local forbidden=(
        "TODO"
        "FIXME"
        "XXX"
        "HACK"
        "sk-[a-zA-Z0-9]{32}"  # OpenAI API key pattern
        "AKIA[0-9A-Z]{16}"     # AWS access key pattern
    )

    local found_any=false
    for pattern in "${forbidden[@]}"; do
        if grep -qE "$pattern" "$SKILL_FILE"; then
            log_critical "Forbidden pattern found: $pattern"
            found_any=true
        fi
    done

    if $found_any; then
        return 1
    fi

    log_pass "No forbidden patterns"
}

# Check 7: Supporting files follow 3+ entry rule
check_supporting_files() {
    for support_file in "${SKILL_DIR}/patterns.md" "${SKILL_DIR}/examples.md" "${SKILL_DIR}/reference.md"; do
        if [[ -f "$support_file" ]]; then
            local filename=$(basename "$support_file")
            # Count entries (lines starting with ## or ###)
            local entry_count=$(grep -cE '^##{1,2} ' "$support_file" || true)

            if (( entry_count > 0 && entry_count < 3 )); then
                log_warning "${filename} has <3 entries (${entry_count}) - should fold into reference.md"
            fi
        fi
    done

    log_pass "Supporting files follow 3+ entry rule"
}

# Check 8: Description has keywords
check_description_keywords() {
    local frontmatter=$(awk 'NR==1 && /^---$/{found=1; next} found && /^---$/{exit} found{print}' "$SKILL_FILE")
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

# Check 11: Cross-file heading duplication
check_cross_file_heading_duplication() {
    local all_headings=""
    local files_checked=0

    for file in "${SKILL_DIR}/reference.md" "${SKILL_DIR}/patterns.md" "${SKILL_DIR}/examples.md"; do
        if [[ -f "$file" ]]; then
            local filename=$(basename "$file")
            # Extract ## headings outside code fences using awk
            local headings=$(awk '
                /^```/ { in_fence = !in_fence; next }
                !in_fence && /^## / { print }
            ' "$file" 2>/dev/null || true)
            if [[ -n "$headings" ]]; then
                while IFS= read -r heading; do
                    all_headings+="${heading}|${filename}"$'\n'
                done <<< "$headings"
            fi
            files_checked=$((files_checked + 1))
        fi
    done

    # Need at least 2 files to check for cross-file duplication
    if (( files_checked < 2 )); then
        log_pass "Cross-file heading duplication (fewer than 2 supporting files)"
        return 0
    fi

    # Check for identical headings across different files
    local duplicates_found=false
    local seen_headings=()
    local seen_files=()

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local heading="${line%%|*}"
        local file="${line##*|}"

        for i in "${!seen_headings[@]}"; do
            if [[ "${seen_headings[$i]}" == "$heading" && "${seen_files[$i]}" != "$file" ]]; then
                log_warning "Duplicate heading '${heading}' found in ${seen_files[$i]} and ${file}"
                duplicates_found=true
                break
            fi
        done

        seen_headings+=("$heading")
        seen_files+=("$file")
    done <<< "$all_headings"

    if ! $duplicates_found; then
        log_pass "No cross-file heading duplication"
    fi
}

# Check 12: Frontmatter name format
check_name_format() {
    local frontmatter=$(awk 'NR==1 && /^---$/{found=1; next} found && /^---$/{exit} found{print}' "$SKILL_FILE")
    local name_value=$(echo "$frontmatter" | grep "^name:" | head -1 | sed 's/^name:[[:space:]]*//' | tr -d '"' | tr -d "'")

    if [[ -z "$name_value" ]]; then
        # Missing name is caught by check 3; skip here
        return 0
    fi

    # Check format: lowercase + numbers + hyphens only
    if [[ ! "$name_value" =~ ^[a-z0-9-]+$ ]]; then
        log_warning "Frontmatter name '${name_value}' contains invalid characters (allowed: lowercase, numbers, hyphens)"
    fi

    # Check max length
    if (( ${#name_value} > 64 )); then
        log_warning "Frontmatter name '${name_value}' exceeds 64 characters (${#name_value} chars)"
    fi

    # Check reserved words
    if [[ "$name_value" == *"anthropic"* || "$name_value" == *"claude"* ]]; then
        log_warning "Frontmatter name '${name_value}' contains reserved word ('anthropic' or 'claude')"
    fi

    log_pass "Frontmatter name format valid"
}

# Check 13: Supporting file substantiveness
check_supporting_file_substantiveness() {
    local thin_files_found=false

    for support_file in "${SKILL_DIR}/patterns.md" "${SKILL_DIR}/examples.md"; do
        if [[ -f "$support_file" ]]; then
            local filename=$(basename "$support_file")
            local total_sections=0
            local thin_sections=0

            # Extract sections between ## headings and count words in each
            local in_section=false
            local section_words=0

            while IFS= read -r line; do
                if [[ "$line" =~ ^##\  || "$line" =~ ^###\  ]]; then
                    # Process previous section
                    if $in_section; then
                        total_sections=$((total_sections + 1))
                        if (( section_words < 20 )); then
                            thin_sections=$((thin_sections + 1))
                        fi
                    fi
                    in_section=true
                    section_words=0
                elif $in_section; then
                    local words=$(echo "$line" | wc -w)
                    section_words=$((section_words + words))
                fi
            done < "$support_file"

            # Process last section
            if $in_section; then
                total_sections=$((total_sections + 1))
                if (( section_words < 20 )); then
                    thin_sections=$((thin_sections + 1))
                fi
            fi

            # Flag if >50% of sections have <20 words
            if (( total_sections > 0 )); then
                local thin_pct=$((thin_sections * 100 / total_sections))
                if (( thin_pct > 50 )); then
                    log_warning "${filename} has thin content (${thin_sections}/${total_sections} sections have <20 words)"
                    thin_files_found=true
                fi
            fi
        fi
    done

    if ! $thin_files_found; then
        log_pass "Supporting files have substantive content"
    fi
}

# Check 14: Citation format consistency
check_citation_format() {
    # Look for file-path citations matching pattern (filename.ext:line)
    local citations=$(grep -oE '\([a-zA-Z0-9_/-]+\.[a-z]+:[0-9]+\)' "$SKILL_FILE" 2>/dev/null || true)

    if [[ -z "$citations" ]]; then
        # No file-path citations — nothing to validate (general citations checked in check 5)
        log_pass "Citation format consistency (no file-path citations to validate)"
        return 0
    fi

    local implausible=false
    while IFS= read -r citation; do
        # Extract line number
        local line_num=$(echo "$citation" | grep -oE '[0-9]+\)$' | tr -d ')')

        # Flag implausible line numbers (>10000)
        if (( line_num > 10000 )); then
            log_warning "Implausible citation ${citation} — line number >10000"
            implausible=true
        fi
    done <<< "$citations"

    if ! $implausible; then
        log_pass "Citation format consistency"
    fi
}

# Check 15: Snapshot date present in generated skills
check_snapshot_date_present() {
    # This check only applies to generated skills (with reference.md)
    if [[ ! -f "${SKILL_DIR}/reference.md" ]]; then
        log_pass "Snapshot date (not applicable - no reference.md)"
        return 0
    fi

    local skill_has_snapshot=false
    local ref_has_snapshot=false

    # Check SKILL.md for snapshot date
    if grep -q "^> \*\*Knowledge snapshot from:\*\*" "$SKILL_FILE"; then
        skill_has_snapshot=true
    fi

    # Check reference.md for snapshot date in Sources section
    if grep -q "^> \*\*Knowledge snapshot date:\*\*" "${SKILL_DIR}/reference.md"; then
        ref_has_snapshot=true
    fi

    if $skill_has_snapshot && $ref_has_snapshot; then
        log_pass "Snapshot date present in both SKILL.md and reference.md"
    elif $skill_has_snapshot || $ref_has_snapshot; then
        log_warning "Snapshot date missing in one location"
    else
        log_warning "Snapshot date missing (generated skills should include snapshot date)"
    fi
}

# Check 16: Model routing contract in cogworks-generated skills
check_model_routing_contract() {
    # Apply only to skills explicitly marked as cogworks-generated.
    if ! grep -q "^> \*\*Generated by:\*\* cogworks" "$SKILL_FILE"; then
        log_pass "Model routing contract (not applicable - not marked as cogworks-generated)"
        return 0
    fi

    local missing=()

    if ! grep -q "^## Model Routing Contract" "$SKILL_FILE"; then
        missing+=("section heading")
    fi
    if ! grep -q "primary-capability-class:" "$SKILL_FILE"; then
        missing+=("primary-capability-class")
    fi
    if ! grep -q "fallback-capability-class:" "$SKILL_FILE"; then
        missing+=("fallback-capability-class")
    fi
    if ! grep -q "task-to-capability mapping:" "$SKILL_FILE"; then
        missing+=("task-to-capability mapping")
    fi
    if ! grep -q "quality gates tied to capability:" "$SKILL_FILE"; then
        missing+=("quality gates tied to capability")
    fi
    if ! grep -q "resolved-primary-model:" "$SKILL_FILE"; then
        missing+=("resolved-primary-model")
    fi
    if ! grep -q "resolved-fallback-model:" "$SKILL_FILE"; then
        missing+=("resolved-fallback-model")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_warning "Model routing contract incomplete for cogworks-generated skill (missing: $(IFS=', '; echo "${missing[*]}"))"
        return 0
    fi

    log_pass "Model routing contract present for cogworks-generated skill"
}

# Check 17: Claude-target generated skills must pin frontmatter model
check_model_frontmatter_for_claude_target() {
    # Scope to cogworks-generated skills only.
    if ! grep -q "^> \*\*Generated by:\*\* cogworks" "$SKILL_FILE"; then
        log_pass "Model frontmatter for Claude target (not applicable - not marked as cogworks-generated)"
        return 0
    fi

    # Apply only when the destination path indicates Claude skill target.
    if [[ ! "$SKILL_DIR" =~ (^|/)\.claude/skills/ ]]; then
        log_pass "Model frontmatter for Claude target (not applicable - non-Claude target path)"
        return 0
    fi

    local frontmatter
    frontmatter=$(awk 'NR==1 && /^---$/{found=1; next} found && /^---$/{exit} found{print}' "$SKILL_FILE")
    local model_value
    model_value=$(echo "$frontmatter" | grep "^model:" | head -1 | sed 's/^model:[[:space:]]*//' | tr -d '"' | tr -d "'" || true)

    if [[ -z "$model_value" ]]; then
        log_critical "Missing required frontmatter field for Claude target: model"
        return 1
    fi

    # Accept common Claude aliases, optional [1m] suffix, or explicit claude-* model names.
    if [[ "$model_value" =~ ^(default|opus|sonnet|haiku|opusplan)(\[1m\])?$ || "$model_value" =~ ^claude-[a-z0-9-]+(\[1m\])?$ ]]; then
        log_pass "Claude-target model frontmatter present (${model_value})"
        return 0
    fi

    log_critical "Invalid Claude-target model frontmatter value: ${model_value}"
    return 1
}

# Run all checks
run_all_checks() {
    check_dependencies || true
    # If dependencies missing, skip remaining checks (they'd all fail)
    if [[ ${#CRITICAL_FAILURES[@]} -gt 0 ]]; then
        return 0
    fi

    check_skill_file_exists || true
    # If SKILL.md is missing, skip remaining checks (they'd all fail)
    if [[ ${#CRITICAL_FAILURES[@]} -gt 0 ]]; then
        return 0
    fi

    check_frontmatter_valid || true
    check_required_frontmatter_fields || true
    check_line_count || true
    check_citations_present || true
    check_forbidden_patterns || true
    check_supporting_files || true
    check_description_keywords || true
    check_no_duplicate_headers || true
    check_markdown_syntax || true
    check_cross_file_heading_duplication || true
    check_name_format || true
    check_supporting_file_substantiveness || true
    check_citation_format || true
    check_snapshot_date_present || true
    check_model_routing_contract || true
    check_model_frontmatter_for_claude_target || true
}

# Generate output
generate_output() {
    if [[ "$JSON_OUTPUT" == "--json" ]]; then
        local status="pass"
        [[ ${#CRITICAL_FAILURES[@]} -gt 0 ]] && status="fail"

        if $JQ_AVAILABLE; then
            # JSON output for machine consumption (using jq for safe escaping)
            local cf_json="[]"
            if [[ ${#CRITICAL_FAILURES[@]} -gt 0 ]]; then
                cf_json=$(printf '%s\n' "${CRITICAL_FAILURES[@]}" | jq -R . | jq -s .)
            fi

            local w_json="[]"
            if [[ ${#WARNINGS[@]} -gt 0 ]]; then
                w_json=$(printf '%s\n' "${WARNINGS[@]}" | jq -R . | jq -s .)
            fi

            local cp_json="[]"
            if [[ ${#CHECKS_PASSED[@]} -gt 0 ]]; then
                cp_json=$(printf '%s\n' "${CHECKS_PASSED[@]}" | jq -R . | jq -s .)
            fi

            jq -n \
                --argjson critical_failures "$cf_json" \
                --argjson warnings "$w_json" \
                --argjson checks_passed "$cp_json" \
                --arg status "$status" \
                '{
                    critical_failures: $critical_failures,
                    warnings: $warnings,
                    checks_passed: $checks_passed,
                    status: $status
                }'
        elif $PYTHON_AVAILABLE; then
            python3 - <<'PY'
import json
import os

status = os.environ.get("CW_STATUS", "fail")
critical = os.environ.get("CW_CRITICAL", "").split("\n") if os.environ.get("CW_CRITICAL") else []
warnings = os.environ.get("CW_WARNINGS", "").split("\n") if os.environ.get("CW_WARNINGS") else []
passed = os.environ.get("CW_PASSED", "").split("\n") if os.environ.get("CW_PASSED") else []

print(json.dumps({
    "critical_failures": [c for c in critical if c],
    "warnings": [w for w in warnings if w],
    "checks_passed": [p for p in passed if p],
    "status": status
}))
PY
        else
            echo "{\"critical_failures\":[],\"warnings\":[],\"checks_passed\":[],\"status\":\"${status}\"}"
        fi
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

    if [[ "$JSON_OUTPUT" == "--json" && ! $JQ_AVAILABLE ]]; then
        local status="pass"
        [[ ${#CRITICAL_FAILURES[@]} -gt 0 ]] && status="fail"
        export CW_STATUS="$status"
        export CW_CRITICAL="$(printf '%s\n' "${CRITICAL_FAILURES[@]}")"
        export CW_WARNINGS="$(printf '%s\n' "${WARNINGS[@]}")"
        export CW_PASSED="$(printf '%s\n' "${CHECKS_PASSED[@]}")"
    fi

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
