# Skill-vs-Skill Benchmark Runbook

## 1. Pin the environment

Before any run, record:

- model id
- agent surface and version
- tool inventory
- sandbox mode
- benchmark dataset version
- grader config version

Do not compare results across runs that changed any of the above.

## 2. Author cases

For each case, fill [`case.schema.json`](case.schema.json) with:

- task prompt
- category
- expected activation behavior
- observable checks
- forbidden actions
- optional rubric dimensions

Prefer executable or state-based checks over free-text expectations.

## 3. Prepare the pair

Create two run configurations:

- `candidate_a` with `skill_a`
- `candidate_b` with `skill_b`

Everything else must remain fixed.

## 4. Execute repeated trials

For each case:

1. Run `candidate_a` for `N` trials.
2. Run `candidate_b` for the same `N` trials.
3. Capture raw traces for every trial.
4. Normalize traces into the observation schema.

For the pilot harness, candidate commands are responsible for writing the normalized observation JSON to `COGWORKS_BENCHMARK_OBSERVATION_PATH`. If the case contains `judge_only` checks, they must also write judge output to `COGWORKS_BENCHMARK_JUDGE_OUTPUT_PATH`.

Codex candidate commands can use [`scripts/skill-benchmark-codex-adapter.py`](../../../scripts/skill-benchmark-codex-adapter.py) as the bridge layer. In live mode it runs `codex exec --json`; in replay mode it converts a saved Codex event stream into the normalized observation contract for offline smoke tests.

If a run crashes or the environment is invalid, mark the trial invalid and rerun until both candidates have the same valid trial count.
Do not convert invalid trials into scored fallback observations.

## 5. Score deterministic evidence first

For each observation, score:

- outcome correctness
- required artifact presence
- forbidden action violations
- trace-sequence expectations
- safety or policy violations
- efficiency counters

Deterministic failures should be reflected directly in the case score. Do not ask an LLM judge to reinterpret a hard failure.

## 6. Judge residual qualities

Use an LLM judge only for qualities that cannot be deterministically checked, such as:

- whether the synthesized plan captured all required distinctions
- whether a summary preserved critical contradictions
- whether the chosen strategy satisfied a domain rubric with no executable oracle

Judge rules:

- different model family from the generator
- structured output only
- criterion-based or pairwise prompt
- calibrated on a human-labeled sample before decision-grade use

## 7. Aggregate paired results

Per case:

- compute the average case score for `candidate_a`
- compute the average case score for `candidate_b`
- compute the paired delta
- assign a case winner or tie

Overall:

- mean paired delta
- win rate
- 95% confidence interval
- breakdown by case family
- activation diagnostics
- safety and efficiency deltas

## 8. Produce benchmark artifacts

Write:

- one machine-readable summary matching [`benchmark-summary.schema.json`](benchmark-summary.schema.json)
- one human-readable `benchmark-report.md`
- one detailed `benchmark-results.json` containing per-case and per-trial evidence

The report should include:

- fixed conditions
- candidate identifiers
- aggregate result
- category breakdown
- notable regressions
- limitations

## 9. Decision policy

Use these result labels:

- `candidate_a`
- `candidate_b`
- `no_clear_winner`
- `insufficient_evidence`

Do not publish a ranked conclusion when the confidence interval overlaps zero or ranking eligibility is false.
Do not publish a ranked conclusion when `decision_eligible = false`.

## 10. Post-run review

Review failed and boundary cases manually for:

- grader blind spots
- reward hacking
- data leakage
- environment drift
- activation/efficacy attribution mistakes

Add high-value failures back into the benchmark set for the next version.

## Pilot command

```bash
python3 scripts/run-skill-benchmark.py \
  --benchmark-id skill-benchmark-pilot \
  --cases-file tests/test-data/skill-benchmark-pilot/cases.jsonl \
  --candidate-a skill-a \
  --candidate-a-command "python3 tests/test-data/skill-benchmark-pilot/fake-runner.py" \
  --candidate-b skill-b \
  --candidate-b-command "python3 tests/test-data/skill-benchmark-pilot/fake-runner.py" \
  --model gpt-5-codex \
  --judge-model claude-3-7-sonnet \
  --agent-surface codex-cli \
  --trials 3
```

Codex replay smoke:

```bash
python3 scripts/run-skill-benchmark.py \
  --benchmark-id skill-benchmark-codex-replay \
  --cases-file tests/test-data/skill-benchmark-codex-adapter/cases.jsonl \
  --candidate-a codex-skill \
  --candidate-a-command "python3 scripts/skill-benchmark-codex-adapter.py --replay-events tests/test-data/skill-benchmark-codex-adapter/candidate-a-events.jsonl" \
  --candidate-b codex-baseline \
  --candidate-b-command "python3 scripts/skill-benchmark-codex-adapter.py --replay-events tests/test-data/skill-benchmark-codex-adapter/candidate-b-events.jsonl" \
  --model gpt-5-codex \
  --agent-surface codex-cli \
  --trials 1
```

Deterministic integrity smoke:

```bash
bash tests/run-skill-benchmark-smoke.sh
```
