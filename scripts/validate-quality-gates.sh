#!/bin/bash
# validate-quality-gates.sh — Deterministic structural checks for generated skills.
# No LLM calls. Breaks self-verification circularity (D8).
#
# Usage:
#   scripts/validate-quality-gates.sh <path/to/SKILL.md>
#   scripts/validate-quality-gates.sh          # scans _generated-skills/ by default
set -euo pipefail

PASS=0
FAIL=1
overall_exit=0

print_result() {
  local status="$1"
  local label="$2"
  if [[ "$status" == "PASS" ]]; then
    echo "  [PASS] $label"
  else
    echo "  [FAIL] $label"
    overall_exit=1
  fi
}

check_frontmatter_present() {
  local file="$1"
  local first_line
  first_line=$(head -1 "$file")
  if [[ "$first_line" == "---" ]]; then
    print_result PASS "YAML frontmatter present"
  else
    print_result FAIL "YAML frontmatter present (file must start with ---)"
  fi
}

check_frontmatter_field() {
  local file="$1"
  local field="$2"
  local in_frontmatter=0
  local found=0
  while IFS= read -r line; do
    if [[ "$in_frontmatter" -eq 0 && "$line" == "---" ]]; then
      in_frontmatter=1
      continue
    fi
    if [[ "$in_frontmatter" -eq 1 && "$line" == "---" ]]; then
      break
    fi
    if [[ "$in_frontmatter" -eq 1 && "$line" =~ ^"$field": ]]; then
      found=1
      break
    fi
  done < "$file"
  if [[ "$found" -eq 1 ]]; then
    print_result PASS "frontmatter has '$field:' field"
  else
    print_result FAIL "frontmatter has '$field:' field"
  fi
}

check_section_heading() {
  local file="$1"
  if grep -qE '^## ' "$file"; then
    print_result PASS "at least one '##' section heading exists"
  else
    print_result FAIL "at least one '##' section heading exists"
  fi
}

check_body_word_count() {
  local file="$1"
  local min_words=200
  # Strip frontmatter (between first two --- lines) before counting.
  local word_count
  word_count=$(awk '
    /^---/ { if (fm==0) { fm=1; next } else { fm=2; next } }
    fm==2 { print }
  ' "$file" | wc -w)
  if [[ "$word_count" -ge "$min_words" ]]; then
    print_result PASS "body word count >= $min_words (got $word_count)"
  else
    print_result FAIL "body word count >= $min_words (got $word_count)"
  fi
}

check_no_injection_markers() {
  local file="$1"
  # Flag bare delimiters at line start only — prose/code-span mentions (e.g. `<<UNTRUSTED_SOURCE>>`)
  # are documentation, not injection. Actual delimiters appear unquoted at the start of a line.
  if grep -qE '^<<(UNTRUSTED_SOURCE|END_UNTRUSTED_SOURCE)>>' "$file"; then
    print_result FAIL "no injection markers present"
  else
    print_result PASS "no injection markers present"
  fi
}

check_metadata_version() {
  local file="$1"
  # metadata: block must appear in frontmatter; version: must follow it.
  local in_frontmatter=0
  local in_metadata=0
  local found_version=0
  while IFS= read -r line; do
    if [[ "$in_frontmatter" -eq 0 && "$line" == "---" ]]; then
      in_frontmatter=1
      continue
    fi
    if [[ "$in_frontmatter" -eq 1 && "$line" == "---" ]]; then
      break
    fi
    if [[ "$in_frontmatter" -eq 1 ]]; then
      if [[ "$line" =~ ^metadata: ]]; then
        in_metadata=1
      elif [[ "$in_metadata" -eq 1 && "$line" =~ ^[[:space:]]+version: ]]; then
        found_version=1
        break
      elif [[ "$in_metadata" -eq 1 && ! "$line" =~ ^[[:space:]] ]]; then
        # Left the metadata block without finding version:
        in_metadata=0
      fi
    fi
  done < "$file"
  if [[ "$found_version" -eq 1 ]]; then
    print_result PASS "frontmatter has 'metadata:' block with 'version:'"
  else
    print_result FAIL "frontmatter has 'metadata:' block with 'version:'"
  fi
}

validate_skill_file() {
  local file="$1"
  echo "Validating: $file"
  check_frontmatter_present      "$file"
  check_frontmatter_field        "$file" "name"
  check_frontmatter_field        "$file" "description"
  check_section_heading          "$file"
  check_body_word_count          "$file"
  check_no_injection_markers     "$file"
  check_metadata_version         "$file"
  echo ""
}

# ── Entry point ──────────────────────────────────────────────────────────────

if [[ "${1:-}" != "" ]]; then
  if [[ ! -f "$1" ]]; then
    echo "Error: file not found: $1" >&2
    exit 1
  fi
  validate_skill_file "$1"
else
  ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  GENERATED_DIR="$ROOT_DIR/_generated-skills"
  if [[ ! -d "$GENERATED_DIR" ]]; then
    echo "No _generated-skills/ directory found and no file argument given." >&2
    exit 1
  fi
  found=0
  while IFS= read -r -d '' skill_file; do
    validate_skill_file "$skill_file"
    found=1
  done < <(find "$GENERATED_DIR" -name "SKILL.md" -print0 | sort -z)
  if [[ "$found" -eq 0 ]]; then
    echo "No SKILL.md files found in $GENERATED_DIR" >&2
    exit 1
  fi
fi

if [[ "$overall_exit" -eq 0 ]]; then
  echo "All quality gate checks passed."
else
  echo "One or more quality gate checks failed." >&2
fi
exit "$overall_exit"
