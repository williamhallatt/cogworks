#!/bin/bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 --target <absolute-path>
EOF
}

TARGET=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ -z "$TARGET" ]]; then
  usage
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/template-repo"

if [[ ! -d "$SRC" ]]; then
  echo "Template repo missing at $SRC" >&2
  exit 2
fi

mkdir -p "$TARGET"
cp -R "$SRC"/. "$TARGET/"

# Placeholder vendor directories.
mkdir -p "$TARGET/vendors/cogworks" "$TARGET/vendors/generator-a" "$TARGET/vendors/generator-b"

echo "Scaffolded external benchmark repo at: $TARGET"
echo "Next: read $TARGET/RUNBOOK.md"
