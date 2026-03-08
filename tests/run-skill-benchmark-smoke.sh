#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d /tmp/cogworks-benchmark-smoke-XXXXXX)"
trap 'rm -rf "$TMP_ROOT"' EXIT

run_python_asserts() {
  local summary_path="$1"
  local python_check="$2"
  python3 - "$summary_path" "$python_check" <<'PY'
import json
import sys

summary_path = sys.argv[1]
python_check = sys.argv[2]
summary = json.load(open(summary_path, encoding="utf-8"))
globals_dict = {"summary": summary}
exec(python_check, globals_dict)
PY
}

cd "$ROOT_DIR"

PILOT_OUT="$TMP_ROOT/pilot-out"
python3 scripts/run-skill-benchmark.py \
  --benchmark-id skill-benchmark-pilot-smoke \
  --cases-file tests/test-data/skill-benchmark-pilot/cases.jsonl \
  --candidate-a skill-a \
  --candidate-a-command "python3 tests/test-data/skill-benchmark-pilot/fake-runner.py" \
  --candidate-b skill-b \
  --candidate-b-command "python3 tests/test-data/skill-benchmark-pilot/fake-runner.py" \
  --model gpt-5-codex \
  --judge-model claude-3-7-sonnet \
  --agent-surface codex-cli \
  --trials 3 \
  --out-dir "$PILOT_OUT" \
  --work-root "$TMP_ROOT/work-pilot"

run_python_asserts "$PILOT_OUT/benchmark-summary.json" $'assert summary["schema_validation_passed"] is True\nassert summary["decision_eligible"] is False\nassert summary["invalid_trials"]["candidate_a"] == 0\nassert summary["invalid_trials"]["candidate_b"] == 0\nassert abs(summary["activation_metrics"]["candidate_a"]["ambiguous_trigger_rate"] - 1.0) < 1e-9'

RERUN_OUT="$TMP_ROOT/rerun-out"
python3 scripts/run-skill-benchmark.py \
  --benchmark-id skill-benchmark-rerun-smoke \
  --cases-file tests/test-data/skill-benchmark-integrity/rerun-cases.jsonl \
  --candidate-a flaky-a \
  --candidate-a-command "python3 tests/test-data/skill-benchmark-integrity/fixture-runner.py --profile flaky" \
  --candidate-b stable-b \
  --candidate-b-command "python3 tests/test-data/skill-benchmark-integrity/fixture-runner.py --profile stable" \
  --model gpt-5-codex \
  --judge-model claude-3-7-sonnet \
  --agent-surface codex-cli \
  --trials 1 \
  --max-invalid-retries 2 \
  --out-dir "$RERUN_OUT" \
  --work-root "$TMP_ROOT/work-rerun"

run_python_asserts "$RERUN_OUT/benchmark-summary.json" $'assert summary["invalid_trial_policy_applied"] is True\nassert summary["valid_trials"]["candidate_a"] == 1\nassert summary["invalid_trials"]["candidate_a"] >= 1\nassert summary["valid_trials"]["candidate_b"] == 1'

ACTIVATION_OUT="$TMP_ROOT/activation-out"
python3 scripts/run-skill-benchmark.py \
  --benchmark-id skill-benchmark-activation-gate-smoke \
  --cases-file tests/test-data/skill-benchmark-integrity/activation-gate-cases.jsonl \
  --candidate-a false-positive-a \
  --candidate-a-command "python3 tests/test-data/skill-benchmark-integrity/fixture-runner.py --profile false-positive" \
  --candidate-b clean-negative-b \
  --candidate-b-command "python3 tests/test-data/skill-benchmark-integrity/fixture-runner.py --profile clean-negative" \
  --model gpt-5-codex \
  --judge-model claude-3-7-sonnet \
  --agent-surface codex-cli \
  --trials 5 \
  --out-dir "$ACTIVATION_OUT" \
  --work-root "$TMP_ROOT/work-activation"

run_python_asserts "$ACTIVATION_OUT/benchmark-summary.json" $'assert summary["mean_delta"] > 0\nassert summary["ranking_eligible"] is True\nassert summary["verdict"] == "no_clear_winner"\nassert summary["activation_gate_passed"]["winner"] is True\nassert summary["activation_gate_passed"]["candidate_a"] is False\nassert summary["activation_metrics"]["candidate_a"]["false_positive_rate"] > summary["activation_metrics"]["candidate_b"]["false_positive_rate"]'

REPLAY_OUT="$TMP_ROOT/replay-out"
python3 scripts/run-skill-benchmark.py \
  --benchmark-id skill-benchmark-codex-replay-smoke \
  --cases-file tests/test-data/skill-benchmark-codex-adapter/cases.jsonl \
  --candidate-a codex-skill \
  --candidate-a-command "python3 scripts/skill-benchmark-codex-adapter.py --replay-events tests/test-data/skill-benchmark-codex-adapter/candidate-a-events.jsonl" \
  --candidate-b codex-baseline \
  --candidate-b-command "python3 scripts/skill-benchmark-codex-adapter.py --replay-events tests/test-data/skill-benchmark-codex-adapter/candidate-b-events.jsonl" \
  --model gpt-5-codex \
  --agent-surface codex-cli \
  --trials 1 \
  --out-dir "$REPLAY_OUT" \
  --work-root "$TMP_ROOT/work-replay"

run_python_asserts "$REPLAY_OUT/benchmark-summary.json" $'assert summary["replay_evidence_present"] is True\nassert summary["decision_eligible"] is False\nassert summary["verdict"] == "insufficient_evidence"'

echo "Benchmark smoke tests passed."
