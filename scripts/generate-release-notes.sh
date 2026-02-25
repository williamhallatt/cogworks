#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat <<'EOF'
Generate structured release notes from git commit history.

Usage:
  scripts/generate-release-notes.sh --tag <tag> --previous-tag <tag> [--output <file>]

Options:
  --tag <tag>           The release tag (required)
  --previous-tag <tag>  The previous release tag; pass "" for first release (required)
  --output <file>       Write output to file instead of stdout (optional)
EOF
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

TAG=""
PREVIOUS_TAG=""
OUTPUT_FILE=""
PREVIOUS_TAG_SET=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --tag)
      TAG="${2:-}"
      shift 2
      ;;
    --previous-tag)
      PREVIOUS_TAG="${2:-}"
      PREVIOUS_TAG_SET=1
      shift 2
      ;;
    --output)
      OUTPUT_FILE="${2:-}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [ -z "$TAG" ]; then
  echo "ERROR: --tag is required" >&2
  usage >&2
  exit 1
fi

if [ "$PREVIOUS_TAG_SET" -eq 0 ]; then
  echo "ERROR: --previous-tag is required (pass \"\" for first release)" >&2
  usage >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# commit_range
# Returns the git range string for log/rev-list commands
# ---------------------------------------------------------------------------

commit_range() {
  if [ -z "$PREVIOUS_TAG" ]; then
    echo "$TAG"
  else
    echo "${PREVIOUS_TAG}..${TAG}"
  fi
}

# ---------------------------------------------------------------------------
# parse_commit_type <subject>
# Outputs one of: feature | fix | refactor | docs | skip | other
# ---------------------------------------------------------------------------

parse_commit_type() {
  local subject="$1"
  if printf '%s' "$subject" | grep -qE '^add/'; then
    echo "feature"
  elif printf '%s' "$subject" | grep -qE '^fix/'; then
    echo "fix"
  elif printf '%s' "$subject" | grep -qE '^refactor/'; then
    echo "refactor"
  elif printf '%s' "$subject" | grep -qE '^docs/'; then
    echo "docs"
  elif printf '%s' "$subject" | grep -qE '^(chore|release)/'; then
    echo "skip"
  else
    echo "other"
  fi
}

# ---------------------------------------------------------------------------
# strip_type_prefix <subject>
# Removes "word/ " prefix from display text
# ---------------------------------------------------------------------------

strip_type_prefix() {
  printf '%s' "$1" | sed 's|^[a-z-]*/[[:space:]]*||'
}

# ---------------------------------------------------------------------------
# extract_body_lines <body>
# Strips blank lines; returns up to 3 lines
# ---------------------------------------------------------------------------

extract_body_lines() {
  local body="$1"
  local result
  result="$(printf '%s\n' "$body" \
    | grep -v '^[[:space:]]*$' \
    | head -n 3 \
    || true)"
  printf '%s' "$result"
}

# ---------------------------------------------------------------------------
# render_section <title> <items_string>
# Emits "### Title\n\n- item\n\n" only when items_string is non-empty
# ---------------------------------------------------------------------------

render_section() {
  local title="$1"
  local items="$2"
  [ -z "$items" ] && return 0
  printf '### %s\n\n' "$title"
  printf '%s\n' "$items"
  printf '\n'
}

# ---------------------------------------------------------------------------
# render_notes
# Orchestrates: iterate commits → categorize → render sections → skills → footer
# ---------------------------------------------------------------------------

render_notes() {
  local range
  range="$(commit_range)"

  # Accumulate items per category
  local features="" fixes="" refactors="" docs_items="" others=""

  local sha subject body type display body_lines body_quoted entry line
  while IFS= read -r sha; do
    [ -z "$sha" ] && continue

    subject="$(git log -1 --format='%s' "$sha")"
    body="$(git log -1 --format='%b' "$sha")"

    type="$(parse_commit_type "$subject")"
    [ "$type" = "skip" ] && continue

    display="$(strip_type_prefix "$subject")"

    # Build body quote lines (up to 3 non-trailer lines)
    body_lines="$(extract_body_lines "$body")"
    body_quoted=""
    if [ -n "$body_lines" ]; then
      while IFS= read -r line; do
        [ -z "$line" ] && continue
        body_quoted="${body_quoted}  > ${line}"$'\n'
      done <<< "$body_lines"
    fi

    entry="- ${display}"
    if [ -n "$body_quoted" ]; then
      entry="${entry}"$'\n'"${body_quoted%$'\n'}"
    fi

    case "$type" in
      feature)  features="${features}${entry}"$'\n' ;;
      fix)      fixes="${fixes}${entry}"$'\n' ;;
      refactor) refactors="${refactors}${entry}"$'\n' ;;
      docs)     docs_items="${docs_items}${entry}"$'\n' ;;
      other)    others="${others}${entry}"$'\n' ;;
    esac
  done < <(git rev-list --reverse "$range" 2>/dev/null || true)

  # Trim trailing newlines
  features="${features%$'\n'}"
  fixes="${fixes%$'\n'}"
  refactors="${refactors%$'\n'}"
  docs_items="${docs_items%$'\n'}"
  others="${others%$'\n'}"

  printf '## What'\''s Changed\n\n'
  render_section "New Features" "$features"
  render_section "Bug Fixes" "$fixes"
  render_section "Refactors" "$refactors"
  render_section "Documentation" "$docs_items"
  render_section "Other Changes" "$others"

  # Installation block
  printf '## Installation\n\n'
  printf '`npx skills add williamhallatt/cogworks`\n\n'
  printf 'See [INSTALL.md](https://github.com/williamhallatt/cogworks/blob/main/INSTALL.md) for options.\n'

  # Full changelog link
  if [ -n "$PREVIOUS_TAG" ]; then
    printf '\n**Full changelog**: https://github.com/williamhallatt/cogworks/compare/%s...%s\n' \
      "$PREVIOUS_TAG" "$TAG"
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

if [ -n "$OUTPUT_FILE" ]; then
  render_notes > "$OUTPUT_FILE"
else
  render_notes
fi
