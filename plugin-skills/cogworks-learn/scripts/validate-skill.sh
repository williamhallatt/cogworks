#!/bin/bash
# Portable skill validation for cogworks-learn
# Usage: validate-skill.sh <skill-directory> [--json]
#
# Essential structural checks for generated skills. A portable subset of the
# full deterministic-checks.sh that ships with cogworks-learn so standalone
# users have mechanical quality enforcement.
#
# Exit codes:
#   0 = all checks passed
#   1 = critical failure(s)
#   2 = passed with warnings

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: validate-skill.sh <skill-directory> [--json]"
    exit 1
fi

SKILL_DIR="$1"
JSON_OUTPUT="${2:-}"
SKILL_FILE="${SKILL_DIR}/SKILL.md"
REF_FILE="${SKILL_DIR}/reference.md"
META_FILE="${SKILL_DIR}/metadata.json"

CRITICAL=()
WARNINGS=()
PASSED=()

log_pass()     { PASSED+=("$1"); }
log_warning()  { WARNINGS+=("$1"); }
log_critical() { CRITICAL+=("$1"); }

# Check 1: SKILL.md exists
if [[ ! -f "$SKILL_FILE" ]]; then
    log_critical "SKILL.md not found in ${SKILL_DIR}"
    # Cannot continue without SKILL.md
    CRITICAL_ONLY=true
else
    CRITICAL_ONLY=false
    log_pass "SKILL.md exists"
fi

if [[ "${CRITICAL_ONLY:-false}" != "true" ]]; then

# Check 2: Valid YAML frontmatter (opening/closing --- delimiters)
if head -1 "$SKILL_FILE" | grep -q "^---$"; then
    closing=$(awk 'NR>1 && /^---$/{print NR; exit}' "$SKILL_FILE")
    if [[ -n "$closing" ]]; then
        log_pass "Frontmatter delimiters present"
    else
        log_critical "Missing closing frontmatter delimiter (---)"
    fi
else
    log_critical "Missing opening frontmatter delimiter (---)"
fi

# Check 3: Required frontmatter fields (name, description)
frontmatter=$(awk 'NR==1 && /^---$/{found=1; next} found && /^---$/{exit} found{print}' "$SKILL_FILE")
has_name=false
has_desc=false
if echo "$frontmatter" | grep -q "^name:"; then has_name=true; fi
if echo "$frontmatter" | grep -q "^description:"; then has_desc=true; fi

if $has_name && $has_desc; then
    log_pass "Required frontmatter fields present (name, description)"
else
    missing_fields=()
    $has_name || missing_fields+=("name")
    $has_desc || missing_fields+=("description")
    log_critical "Missing required frontmatter fields: $(IFS=', '; echo "${missing_fields[*]}")"
fi

# Check 4: SKILL.md line count <= 500
line_count=$(wc -l < "$SKILL_FILE")
if (( line_count > 500 )); then
    log_critical "SKILL.md exceeds 500 lines (${line_count} lines)"
elif (( line_count > 450 )); then
    log_warning "SKILL.md approaching limit (${line_count}/500 lines)"
else
    log_pass "Line count within limit (${line_count}/500)"
fi

# Check 5: Required section headings in SKILL.md
SKILL_SECTIONS=("When to Use" "Quick Decision|Cheatsheet" "Invocation")
skill_content=$(cat "$SKILL_FILE")
skill_missing=()
for section in "${SKILL_SECTIONS[@]}"; do
    # Support alternatives separated by |
    found=false
    IFS='|' read -ra alts <<< "$section"
    for alt in "${alts[@]}"; do
        if echo "$skill_content" | grep -qi "^#\{1,4\} .*${alt}"; then
            found=true
            break
        fi
    done
    if ! $found; then
        skill_missing+=("$section")
    fi
done
if [[ ${#skill_missing[@]} -gt 0 ]]; then
    log_warning "SKILL.md missing sections: $(IFS=', '; echo "${skill_missing[*]}")"
else
    log_pass "SKILL.md required sections present"
fi

# Check 6: Required section headings in reference.md
if [[ -f "$REF_FILE" ]]; then
    REF_SECTIONS=("TL;DR" "Decision Rules" "Anti-Patterns" "Quick Reference" "Sources")
    ref_content=$(cat "$REF_FILE")
    ref_missing=()
    for section in "${REF_SECTIONS[@]}"; do
        if ! echo "$ref_content" | grep -qi "^#\{1,4\} .*${section}"; then
            ref_missing+=("$section")
        fi
    done
    if [[ ${#ref_missing[@]} -gt 0 ]]; then
        log_warning "reference.md missing sections: $(IFS=', '; echo "${ref_missing[*]}")"
    else
        log_pass "reference.md required sections present"
    fi
else
    log_warning "reference.md not found"
fi

# Check 7: Source citations (min 3 across files)
total_citations=0
for f in "$SKILL_FILE" "$REF_FILE" "${SKILL_DIR}/patterns.md" "${SKILL_DIR}/examples.md"; do
    if [[ -f "$f" ]]; then
        count=$({ grep -oE '\[Source [0-9]+\]' "$f" || true; } | wc -l)
        total_citations=$((total_citations + count))
    fi
done
if (( total_citations == 0 )); then
    log_critical "No [Source N] citations found"
elif (( total_citations < 3 )); then
    log_warning "Only ${total_citations} citations found (minimum 3 recommended)"
else
    log_pass "Citations present (${total_citations} found)"
fi

# Check 8: Forbidden patterns
FORBIDDEN=("TODO" "FIXME" "XXX" "HACK")
found_forbidden=false
for f in "$SKILL_FILE" "$REF_FILE" "${SKILL_DIR}/patterns.md" "${SKILL_DIR}/examples.md"; do
    if [[ -f "$f" ]]; then
        for pattern in "${FORBIDDEN[@]}"; do
            if grep -q "$pattern" "$f"; then
                log_warning "Forbidden pattern '$pattern' in $(basename "$f")"
                found_forbidden=true
            fi
        done
    fi
done
if ! $found_forbidden; then
    log_pass "No forbidden patterns"
fi

# Check 9: Balanced markdown code fences
for f in "$SKILL_FILE" "$REF_FILE" "${SKILL_DIR}/patterns.md" "${SKILL_DIR}/examples.md"; do
    if [[ -f "$f" ]]; then
        fence_count=$(grep -cE '^```' "$f" || true)
        if (( fence_count % 2 != 0 )); then
            log_critical "Unclosed code fence in $(basename "$f") (${fence_count} fence markers)"
        fi
    fi
done
if [[ ! " ${CRITICAL[*]:-} " =~ "Unclosed code fence" ]]; then
    log_pass "Code fences balanced"
fi

# Check 10: metadata.json validation
if [[ -f "$META_FILE" ]]; then
    # Try python3 first, then jq, then basic grep
    if command -v python3 >/dev/null 2>&1; then
        meta_result=$(python3 - "$META_FILE" "$SKILL_DIR" <<'PYEOF'
import json, sys, os
meta_path = sys.argv[1]
skill_dir = sys.argv[2]
dir_name = os.path.basename(os.path.normpath(skill_dir))
try:
    with open(meta_path) as f:
        data = json.load(f)
except (json.JSONDecodeError, IOError) as e:
    print(f"CRITICAL:Invalid JSON: {e}")
    sys.exit(0)
errors = []
for field in ["slug", "version", "snapshot_date", "cogworks_version", "topic", "sources"]:
    if field not in data:
        errors.append(f"missing field: {field}")
if "slug" in data and data["slug"] != dir_name:
    errors.append(f"slug '{data['slug']}' != directory '{dir_name}'")
if "sources" in data:
    if not isinstance(data["sources"], list) or len(data["sources"]) == 0:
        errors.append("sources must be a non-empty array")
for e in errors:
    print(f"WARNING:{e}")
if not errors:
    print("PASS")
PYEOF
        )
        while IFS= read -r line; do
            case "$line" in
                CRITICAL:*) log_critical "metadata.json: ${line#CRITICAL:}" ;;
                WARNING:*)  log_warning "metadata.json: ${line#WARNING:}" ;;
                PASS)       log_pass "metadata.json valid" ;;
            esac
        done <<< "$meta_result"
    elif command -v jq >/dev/null 2>&1; then
        if jq empty "$META_FILE" 2>/dev/null; then
            log_pass "metadata.json is valid JSON"
        else
            log_critical "metadata.json is not valid JSON"
        fi
    else
        log_warning "metadata.json found but no python3/jq to validate"
    fi
fi

# Check 11: Description length >= 10 words
if $has_desc; then
    description=$(echo "$frontmatter" | grep "^description:" | head -1 | sed 's/^description:[[:space:]]*//' | tr -d '"' | tr -d "'")
    word_count=$(echo "$description" | wc -w)
    if (( word_count < 10 )); then
        log_warning "Description is short (${word_count} words) — add keywords for discoverability"
    else
        log_pass "Description length adequate (${word_count} words)"
    fi
fi

fi # end CRITICAL_ONLY guard

# Output results
if [[ "$JSON_OUTPUT" == "--json" ]]; then
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
    echo "=== Skill Validation ==="
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
