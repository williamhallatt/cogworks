#!/bin/bash
# Thin wrapper — puts the Layer 3 static contract test in the tests/ runner namespace.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== Agentic Contract Smoke ==="
bash "$ROOT_DIR/scripts/test-agentic-contract.sh"
