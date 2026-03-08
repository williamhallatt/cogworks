#!/bin/bash
# Validates JSON schemas parse correctly and example files validate against them.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCHEMA_DIR="$ROOT_DIR/evals/skill-benchmark"
EXAMPLES_DIR="$ROOT_DIR/_sources/evals/skill-benchmark/examples"
PILOT_CASES="$ROOT_DIR/tests/test-data/skill-benchmark-pilot/cases.jsonl"

FAILURES=0

fail() {
  echo "FAIL  $1" >&2
  FAILURES=$((FAILURES + 1))
}

echo "=== Schema Validation Smoke ==="

# 1. All 4 schemas parse as valid JSON Schema (Draft 2020-12)
for schema in "$SCHEMA_DIR"/*.schema.json; do
  name=$(basename "$schema")
  if python3 -c "
from jsonschema import Draft202012Validator
import json, sys
schema = json.load(open(sys.argv[1]))
Draft202012Validator.check_schema(schema)
" "$schema" 2>/dev/null; then
    echo "PASS  $name is valid JSON Schema"
  else
    fail "$name is not valid JSON Schema"
  fi
done

# 2. Example files validate against their schemas
if [[ -f "$EXAMPLES_DIR/case-example.json" ]]; then
  if python3 -c "
from jsonschema import Draft202012Validator
import json, sys
schema = json.load(open(sys.argv[1]))
instance = json.load(open(sys.argv[2]))
Draft202012Validator(schema).validate(instance)
" "$SCHEMA_DIR/case.schema.json" "$EXAMPLES_DIR/case-example.json" 2>/dev/null; then
    echo "PASS  case-example.json validates against case.schema.json"
  else
    fail "case-example.json does not validate against case.schema.json"
  fi
fi

if [[ -f "$EXAMPLES_DIR/benchmark-summary.example.json" ]]; then
  if python3 -c "
from jsonschema import Draft202012Validator
import json, sys
schema = json.load(open(sys.argv[1]))
instance = json.load(open(sys.argv[2]))
Draft202012Validator(schema).validate(instance)
" "$SCHEMA_DIR/benchmark-summary.schema.json" "$EXAMPLES_DIR/benchmark-summary.example.json" 2>/dev/null; then
    echo "PASS  benchmark-summary.example.json validates against benchmark-summary.schema.json"
  else
    fail "benchmark-summary.example.json does not validate against benchmark-summary.schema.json"
  fi
fi

# 3. Pilot test cases validate against case.schema.json
if [[ -f "$PILOT_CASES" ]]; then
  line_num=0
  while IFS= read -r line; do
    line_num=$((line_num + 1))
    if ! python3 -c "
from jsonschema import Draft202012Validator
import json, sys
schema = json.load(open(sys.argv[1]))
instance = json.loads(sys.argv[2])
Draft202012Validator(schema).validate(instance)
" "$SCHEMA_DIR/case.schema.json" "$line" 2>/dev/null; then
      fail "pilot cases.jsonl line $line_num does not validate against case.schema.json"
    fi
  done < "$PILOT_CASES"
  if [[ $FAILURES -eq 0 ]]; then
    echo "PASS  pilot cases.jsonl ($line_num lines) validates against case.schema.json"
  fi
fi

if [[ $FAILURES -gt 0 ]]; then
  echo ""
  echo "Schema validation failed with $FAILURES issue(s)." >&2
  exit 1
fi

echo ""
echo "Schema validation passed."
