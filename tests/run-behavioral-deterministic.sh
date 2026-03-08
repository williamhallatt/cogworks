#!/bin/bash
# Layer 5a — Deterministic behavioral test validation.
# Validates test case definitions for structural correctness, activation
# keyword consistency, and category coverage. No API key required.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

python3 "$ROOT_DIR/tests/framework/scripts/behavioral_deterministic.py" \
  --tests-root "$ROOT_DIR/tests/behavioral"
