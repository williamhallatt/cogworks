#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_HOOK="$REPO_ROOT/.githooks/commit-msg"
TARGET_HOOK="$REPO_ROOT/.git/hooks/commit-msg"

if [ ! -d "$REPO_ROOT/.git" ]; then
  echo "ERROR: .git directory not found. Run this from a cloned repository."
  exit 1
fi

if [ ! -f "$SOURCE_HOOK" ]; then
  echo "ERROR: Source hook not found: $SOURCE_HOOK"
  exit 1
fi

chmod +x "$SOURCE_HOOK"
mkdir -p "$(dirname "$TARGET_HOOK")"
cp "$SOURCE_HOOK" "$TARGET_HOOK"
chmod +x "$TARGET_HOOK"

echo "Installed git hook: $TARGET_HOOK"
echo "Validation command: scripts/validate-docs-attestation.sh --commit HEAD"
