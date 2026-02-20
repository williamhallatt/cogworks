#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

required_files=(
  "$ROOT_DIR/README.md"
  "$ROOT_DIR/TESTING.md"
  "$ROOT_DIR/INSTALL.md"
  "$ROOT_DIR/RELEASES.md"
  "$ROOT_DIR/AGENTS.md"
  "$ROOT_DIR/tests/framework/README.md"
  "$ROOT_DIR/tests/datasets/recursive-round/README.md"
)

for f in "${required_files[@]}"; do
  [[ -f "$f" ]] || { echo "Missing required doc: $f" >&2; exit 1; }
done

# Canonical runbook reference must exist in major docs.
for f in "$ROOT_DIR/README.md" "$ROOT_DIR/TESTING.md" "$ROOT_DIR/INSTALL.md" "$ROOT_DIR/tests/framework/README.md" "$ROOT_DIR/AGENTS.md"; do
  rg -q "tests/datasets/recursive-round/README.md" "$f" || {
    echo "Missing canonical runbook reference in $f" >&2
    exit 1
  }
done

# Core scripts must be referenced in user docs.
for script in run-recursive-round.sh run-recursive-hook.sh hash-test-bundle.sh pin-test-bundle-hash.sh recursive-env.example.sh; do
  rg -q "$script" "$ROOT_DIR/README.md" "$ROOT_DIR/TESTING.md" "$ROOT_DIR/tests/datasets/recursive-round/README.md" || {
    echo "Script not documented: $script" >&2
    exit 1
  }
done

# Decision-grade signal wording should be documented.
for f in "$ROOT_DIR/TESTING.md" "$ROOT_DIR/tests/datasets/recursive-round/README.md"; do
  rg -q "ranking_eligible=true" "$f" || {
    echo "Missing decision-grade signal contract in $f" >&2
    exit 1
  }
done

echo "Recursive docs validation passed."
