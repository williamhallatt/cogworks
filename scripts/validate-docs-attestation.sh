#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Validate docs attestation trailers in commit messages.

Usage:
  scripts/validate-docs-attestation.sh --commit <sha>
  scripts/validate-docs-attestation.sh --range <base>..<head>
  scripts/validate-docs-attestation.sh --message-file <path>
EOF
}

print_example() {
  cat <<'EOF'
Expected trailer format:
  Docs-Impact: updated|none|required-followup
  Docs-Updated: <csv-paths>|none
  Docs-Why-None: <required when impact=none or required-followup>

Examples:
  Docs-Impact: updated
  Docs-Updated: README.md, TESTING.md

  Docs-Impact: none
  Docs-Updated: none
  Docs-Why-None: Internal refactor only; no user-facing behavior changed.

  Docs-Impact: required-followup
  Docs-Updated: none
  Docs-Why-None: Follow up by 2026-02-27 owner @williamh after benchmark results.
EOF
}

fail_message() {
  local subject="$1"
  local reason="$2"
  echo "ERROR: docs attestation validation failed for: $subject"
  echo "Reason: $reason"
  echo
  print_example
}

extract_single_value() {
  local key="$1"
  local message="$2"

  local count
  count="$(printf '%s\n' "$message" | grep -E -c "^${key}:[[:space:]]*.*$" || true)"
  if [ "$count" -eq 0 ]; then
    echo "__MISSING__"
    return 0
  fi

  if [ "$count" -gt 1 ]; then
    echo "__DUPLICATE__"
    return 0
  fi

  printf '%s\n' "$message" | sed -n "s/^${key}:[[:space:]]*//p"
}

validate_csv_paths() {
  local value="$1"
  local token
  local has_token=0

  IFS=',' read -r -a tokens <<< "$value"
  for token in "${tokens[@]}"; do
    token="$(echo "$token" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    if [ -z "$token" ]; then
      continue
    fi
    has_token=1
  done

  if [ "$has_token" -eq 0 ]; then
    return 1
  fi

  return 0
}

validate_message_content() {
  local subject="$1"
  local message="$2"

  local docs_impact docs_updated docs_why_none

  docs_impact="$(extract_single_value "Docs-Impact" "$message")"
  docs_updated="$(extract_single_value "Docs-Updated" "$message")"
  docs_why_none="$(extract_single_value "Docs-Why-None" "$message")"

  if [ "$docs_impact" = "__MISSING__" ]; then
    fail_message "$subject" "Missing required trailer: Docs-Impact"
    return 1
  fi
  if [ "$docs_impact" = "__DUPLICATE__" ]; then
    fail_message "$subject" "Duplicate trailer: Docs-Impact"
    return 1
  fi

  if [ "$docs_updated" = "__MISSING__" ]; then
    fail_message "$subject" "Missing required trailer: Docs-Updated"
    return 1
  fi
  if [ "$docs_updated" = "__DUPLICATE__" ]; then
    fail_message "$subject" "Duplicate trailer: Docs-Updated"
    return 1
  fi

  if [ "$docs_why_none" = "__DUPLICATE__" ]; then
    fail_message "$subject" "Duplicate trailer: Docs-Why-None"
    return 1
  fi

  case "$docs_impact" in
    updated|none|required-followup) ;;
    *)
      fail_message "$subject" "Invalid Docs-Impact value: '$docs_impact'"
      return 1
      ;;
  esac

  case "$docs_impact" in
    updated)
      if [ "$docs_updated" = "none" ]; then
        fail_message "$subject" "Docs-Updated must list files when Docs-Impact is 'updated'"
        return 1
      fi
      if ! validate_csv_paths "$docs_updated"; then
        fail_message "$subject" "Docs-Updated must contain a non-empty comma-separated file list"
        return 1
      fi
      ;;
    none)
      if [ "$docs_updated" != "none" ]; then
        fail_message "$subject" "Docs-Updated must be 'none' when Docs-Impact is 'none'"
        return 1
      fi
      if [ "$docs_why_none" = "__MISSING__" ] || [ -z "$docs_why_none" ]; then
        fail_message "$subject" "Docs-Why-None is required when Docs-Impact is 'none'"
        return 1
      fi
      ;;
    required-followup)
      if [ "$docs_updated" != "none" ]; then
        fail_message "$subject" "Docs-Updated must be 'none' when Docs-Impact is 'required-followup'"
        return 1
      fi
      if [ "$docs_why_none" = "__MISSING__" ] || [ -z "$docs_why_none" ]; then
        fail_message "$subject" "Docs-Why-None is required when Docs-Impact is 'required-followup'"
        return 1
      fi
      if ! echo "$docs_why_none" | grep -Eq '[0-9]{4}-[0-9]{2}-[0-9]{2}'; then
        fail_message "$subject" "Docs-Why-None must include a follow-up date (YYYY-MM-DD)"
        return 1
      fi
      if ! echo "$docs_why_none" | grep -Eq '@[A-Za-z0-9._-]+'; then
        fail_message "$subject" "Docs-Why-None must include an owner handle (for example @williamh)"
        return 1
      fi
      ;;
  esac

  echo "PASS: $subject"
  return 0
}

validate_commit() {
  local commit_sha="$1"
  local subject message

  if ! git cat-file -e "${commit_sha}^{commit}" 2>/dev/null; then
    echo "ERROR: Commit does not exist: $commit_sha"
    return 1
  fi

  subject="$(git log -1 --format=%s "$commit_sha")"
  message="$(git log -1 --format=%B "$commit_sha")"
  validate_message_content "$commit_sha ($subject)" "$message"
}

validate_range() {
  local range="$1"
  local commits
  local failed=0

  commits="$(git rev-list --reverse "$range" 2>/dev/null || true)"
  if [ -z "$commits" ]; then
    echo "ERROR: No commits found in range '$range'"
    return 1
  fi

  while IFS= read -r commit_sha; do
    if ! validate_commit "$commit_sha"; then
      failed=1
    fi
  done <<< "$commits"

  if [ "$failed" -ne 0 ]; then
    return 1
  fi

  return 0
}

validate_message_file() {
  local file_path="$1"
  local message

  if [ ! -f "$file_path" ]; then
    echo "ERROR: Message file not found: $file_path"
    return 1
  fi

  message="$(cat "$file_path")"
  validate_message_content "COMMIT_MSG" "$message"
}

if [ "$#" -ne 2 ]; then
  usage
  exit 1
fi

case "$1" in
  --commit)
    validate_commit "$2"
    ;;
  --range)
    validate_range "$2"
    ;;
  --message-file)
    validate_message_file "$2"
    ;;
  *)
    usage
    exit 1
    ;;
esac
