#!/bin/bash
# Portable synthesis output validation for cogworks-encode
# Usage: validate-synthesis.sh <output-file-or-directory> [--json]
#
# Validates synthesis output against structural and citation requirements.
# Ships with cogworks-encode so standalone users have mechanical enforcement.
#
# Exit codes:
#   0 = all checks passed
#   1 = critical failure(s)
#   2 = passed with warnings

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: validate-synthesis.sh <output-file-or-directory> [--json]"
    exit 1
fi

TARGET="$1"
JSON_OUTPUT="${2:-}"

# Collect all markdown files to check
FILES=()
if [[ -d "$TARGET" ]]; then
    while IFS= read -r -d '' f; do
        FILES+=("$f")
    done < <(find "$TARGET" -name "*.md" -print0)
elif [[ -f "$TARGET" ]]; then
    FILES=("$TARGET")
else
    echo "Error: $TARGET is not a file or directory"
    exit 1
fi

if [[ ${#FILES[@]} -eq 0 ]]; then
    echo "Error: no markdown files found in $TARGET"
    exit 1
fi

CRITICAL=()
WARNINGS=()
PASSED=()

log_pass()     { PASSED+=("$1"); }
log_warning()  { WARNINGS+=("$1"); }
log_critical() { CRITICAL+=("$1"); }

# Concatenate all file contents for aggregate checks
ALL_CONTENT=""
for f in "${FILES[@]}"; do
    ALL_CONTENT+="$(cat "$f")"$'\n'
done

# Check 1: Required section headings
REQUIRED_SECTIONS=("TL;DR" "Decision Rules" "Anti-Patterns" "Quick Reference" "Sources")
missing=()
for section in "${REQUIRED_SECTIONS[@]}"; do
    if ! echo "$ALL_CONTENT" | grep -qi "^#\{1,4\} .*${section}"; then
        missing+=("$section")
    fi
done
if [[ ${#missing[@]} -gt 0 ]]; then
    log_critical "Missing required sections: $(IFS=', '; echo "${missing[*]}")"
else
    log_pass "All required sections present"
fi

# Check 2: Source citations (min 3 [Source N] references)
CITATION_COUNT=$({ echo "$ALL_CONTENT" | grep -oE '\[Source [0-9]+\]' || true; } | wc -l)
if (( CITATION_COUNT == 0 )); then
    log_critical "No [Source N] citations found"
elif (( CITATION_COUNT < 3 )); then
    log_warning "Only ${CITATION_COUNT} citations found (minimum 3 recommended)"
else
    log_pass "Citations present (${CITATION_COUNT} found)"
fi

# Check 3: Balanced markdown code fences
for f in "${FILES[@]}"; do
    fence_count=$(grep -cE '^```' "$f" || true)
    if (( fence_count % 2 != 0 )); then
        log_critical "Unclosed code fence in $(basename "$f") (${fence_count} fence markers)"
    fi
done
if [[ ! " ${CRITICAL[*]:-} " =~ "Unclosed code fence" ]]; then
    log_pass "Code fences balanced"
fi

# Check 4: Forbidden patterns
FORBIDDEN=("TODO" "FIXME" "XXX" "HACK")
found_forbidden=false
for pattern in "${FORBIDDEN[@]}"; do
    if echo "$ALL_CONTENT" | grep -q "$pattern"; then
        log_warning "Forbidden pattern found: $pattern"
        found_forbidden=true
    fi
done
if ! $found_forbidden; then
    log_pass "No forbidden patterns"
fi

# Check 5: Sources section has at least one numbered entry
if echo "$ALL_CONTENT" | grep -qE '^\s*[0-9]+\.\s'; then
    log_pass "Sources section contains numbered entries"
else
    log_warning "No numbered entries found in Sources section"
fi

# Output results
if [[ "$JSON_OUTPUT" == "--json" ]]; then
    # Build JSON manually (no jq dependency)
    printf '{"critical_failures":['
    for i in "${!CRITICAL[@]}"; do
        (( i > 0 )) && printf ','
        printf '"%s"' "${CRITICAL[$i]//\"/\\\"}"
    done
    printf '],"warnings":['
    for i in "${!WARNINGS[@]}"; do
        (( i > 0 )) && printf ','
        printf '"%s"' "${WARNINGS[$i]//\"/\\\"}"
    done
    printf '],"checks_passed":['
    for i in "${!PASSED[@]}"; do
        (( i > 0 )) && printf ','
        printf '"%s"' "${PASSED[$i]//\"/\\\"}"
    done
    printf '],"status":"%s"}\n' "$( [[ ${#CRITICAL[@]} -gt 0 ]] && echo fail || echo pass )"
else
    echo "=== Synthesis Validation ==="
    echo ""
    if [[ ${#PASSED[@]} -gt 0 ]]; then
        echo "Passed (${#PASSED[@]}):"
        for p in "${PASSED[@]}"; do echo "  - $p"; done
        echo ""
    fi
    if [[ ${#WARNINGS[@]} -gt 0 ]]; then
        echo "Warnings (${#WARNINGS[@]}):"
        for w in "${WARNINGS[@]}"; do echo "  - $w"; done
        echo ""
    fi
    if [[ ${#CRITICAL[@]} -gt 0 ]]; then
        echo "Critical (${#CRITICAL[@]}):"
        for c in "${CRITICAL[@]}"; do echo "  - $c"; done
        echo ""
    fi
fi

if [[ ${#CRITICAL[@]} -gt 0 ]]; then
    exit 1
elif [[ ${#WARNINGS[@]} -gt 0 ]]; then
    exit 2
else
    exit 0
fi
