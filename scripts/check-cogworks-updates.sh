#!/usr/bin/env bash
set -euo pipefail

readonly REPO="williamhallatt/cogworks"
readonly RELEASES_API="https://api.github.com/repos/${REPO}/releases/latest"

QUIET=false

print_usage() {
  cat <<'EOF'
Usage: bash scripts/check-cogworks-updates.sh [--quiet] [--help]

Checks whether your packaged/local cogworks version is behind the latest GitHub release.

Exit codes:
  0  Up to date (or local version is newer)
  1  Update available
  2  Error while checking (dependencies/network/parsing)
EOF
}

print_info() {
  if [[ "$QUIET" == false ]]; then
    echo "$1"
  fi
}

error_exit() {
  echo "Error: $1" >&2
  exit 2
}

normalize_version() {
  local raw="$1"
  raw="${raw#v}"
  echo "$raw"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --quiet)
        QUIET=true
        shift
        ;;
      --help|-h)
        print_usage
        exit 0
        ;;
      *)
        echo "Unknown option: $1" >&2
        print_usage >&2
        exit 2
        ;;
    esac
  done
}

read_local_version() {
  local script_dir root install_file local_ver
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  root="$(cd "${script_dir}/.." && pwd)"
  install_file="${root}/install.sh"

  [[ -f "$install_file" ]] || error_exit "install.sh not found at ${install_file}"

  local_ver="$(sed -nE 's/^readonly VERSION="([^"]+)"/\1/p' "$install_file" | head -1)"
  [[ -n "$local_ver" ]] || error_exit "could not parse VERSION from install.sh"

  local_ver="$(normalize_version "$local_ver")"
  [[ "$local_ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || error_exit "invalid local version format: ${local_ver}"
  echo "$local_ver"
}

fetch_latest_release() {
  command -v curl >/dev/null 2>&1 || error_exit "curl is required"
  curl -fsSL --connect-timeout 10 --max-time 20 "$RELEASES_API"
}

parse_field_from_json() {
  local json="$1"
  local field="$2"

  if command -v jq >/dev/null 2>&1; then
    echo "$json" | jq -r "$field // empty"
    return 0
  fi

  case "$field" in
    .tag_name)
      echo "$json" | sed -nE 's/.*"tag_name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' | head -1
      ;;
    .html_url)
      echo "$json" | sed -nE 's/.*"html_url"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' | head -1
      ;;
    *)
      echo ""
      ;;
  esac
}

version_compare() {
  local a="$1" b="$2"
  local a_major a_minor a_patch b_major b_minor b_patch

  IFS='.' read -r a_major a_minor a_patch <<< "$a"
  IFS='.' read -r b_major b_minor b_patch <<< "$b"

  if (( a_major < b_major )); then return 1; fi
  if (( a_major > b_major )); then return 0; fi
  if (( a_minor < b_minor )); then return 1; fi
  if (( a_minor > b_minor )); then return 0; fi
  if (( a_patch < b_patch )); then return 1; fi
  return 0
}

main() {
  parse_args "$@"

  print_info "Checking cogworks updates..."

  local local_version response latest_tag latest_version latest_url
  local_version="$(read_local_version)"
  response="$(fetch_latest_release)" || error_exit "failed to fetch latest release metadata"

  latest_tag="$(parse_field_from_json "$response" ".tag_name")"
  latest_url="$(parse_field_from_json "$response" ".html_url")"
  [[ -n "$latest_tag" ]] || error_exit "could not parse latest release tag_name"

  latest_version="$(normalize_version "$latest_tag")"
  [[ "$latest_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || error_exit "invalid latest release version: ${latest_tag}"

  print_info "Current version: v${local_version}"
  print_info "Latest release:  v${latest_version}"

  if version_compare "$local_version" "$latest_version"; then
    if [[ "$local_version" == "$latest_version" ]]; then
      echo "Status: up to date."
    else
      echo "Status: local version is newer than latest GitHub release."
    fi
    exit 0
  fi

  echo "Status: update available."
  if [[ -n "$latest_url" ]]; then
    echo "Download: ${latest_url}"
  else
    echo "Download: https://github.com/${REPO}/releases/latest"
  fi
  echo "Upgrade: download the latest release archive and run ./install.sh"
  exit 1
}

main "$@"
