#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
L1_SCRIPT="$ROOT_DIR/tests/framework/graders/deterministic-checks.sh"
EVAL_CLI="$ROOT_DIR/tests/framework/scripts/cogworks-eval.py"

SKILL_PATH=""
TESTS_ROOT="$ROOT_DIR/tests/behavioral"
RESULTS_ROOT="$ROOT_DIR/tests/results/behavioral"
WITH_BEHAVIORAL=0

usage() {
  cat <<EOF
Usage: $0 --skill-path <path> [options]

Options:
  --skill-path <path>     Skill directory to validate (required)
  --with-behavioral       Also run behavioral validation for this skill slug
  --tests-root <path>     Behavioral tests root (default: tests/behavioral)
  --results-root <path>   Behavioral results root (default: tests/results/behavioral)
  -h, --help              Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skill-path)
      SKILL_PATH="$2"
      shift 2
      ;;
    --with-behavioral)
      WITH_BEHAVIORAL=1
      shift
      ;;
    --tests-root)
      TESTS_ROOT="$2"
      shift 2
      ;;
    --results-root)
      RESULTS_ROOT="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$SKILL_PATH" ]]; then
  echo "--skill-path is required." >&2
  usage
  exit 2
fi

if [[ ! -d "$SKILL_PATH" ]]; then
  echo "Skill path not found: $SKILL_PATH" >&2
  exit 2
fi

if [[ ! -x "$L1_SCRIPT" ]]; then
  echo "Deterministic checks script not found or not executable: $L1_SCRIPT" >&2
  exit 2
fi

echo "Running Layer 1 deterministic checks..."
bash "$L1_SCRIPT" "$SKILL_PATH" --json

if [[ "$WITH_BEHAVIORAL" -eq 0 ]]; then
  exit 0
fi

SKILL_SLUG="$(basename "$SKILL_PATH")"
SKILLS_ROOT="$(dirname "$SKILL_PATH")"

echo "Running behavioral checks for $SKILL_SLUG..."
python3 "$EVAL_CLI" behavioral run \
  --skills-root "$SKILLS_ROOT" \
  --tests-root "$TESTS_ROOT" \
  --results-root "$RESULTS_ROOT" \
  --skill "$SKILL_SLUG"
