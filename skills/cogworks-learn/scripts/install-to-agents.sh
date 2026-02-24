#!/bin/bash
set -euo pipefail

STAGING_DIR="${1:-_generated-skills}"

if ! command -v npx &>/dev/null; then
  echo ""
  echo "ERROR: npx is not available."
  echo ""
  echo "Generated skill files are ready in $STAGING_DIR/"
  echo "but cannot be installed to your agents without the skills CLI."
  echo ""
  echo "To finish installation:"
  echo "  1. Install Node.js 18+: https://nodejs.org/"
  echo "  2. Run: npx skills add $STAGING_DIR"
  echo ""
  exit 1
fi

echo "Installing generated skills from $STAGING_DIR/ to detected agents..."
npx skills add "$STAGING_DIR"
echo "Done. Skills installed to detected agents."
