# Skill-vs-Skill Benchmark Specification

This specification defines how to compare two agent skills for the same task family without confounding the result with model or environment changes.

## Comparison contract

The primary benchmark is a **paired, isolated skill comparison**.

Everything below must be identical across both candidates:

- model
- agent surface
- tool inventory
- sandbox and filesystem policy
- task case
- grader configuration

The only intended difference is the skill under test.

## Primary outputs

The benchmark produces two scorecards.

### 1. Efficacy scorecard

Primary decision surface. Measures whether the skill improves task outcomes once the task is in scope.

Required dimensions:

- task outcome correctness
- deterministic process compliance
- safety and policy violations
- efficiency: latency, steps, tokens, cost
- optional rubric dimensions for residual qualitative criteria

### 2. Activation scorecard

Separate diagnostic or release gate. Measures whether the skill activates when it should and stays out of the way when it should not.

Required dimensions:

- activation precision
- activation recall
- false-positive rate
- false-negative rate
- ambiguous-trigger rate

## Dataset design

Every benchmark set must include all three case families:

- `invoked-task`: the skill is explicitly or strongly relevant
- `hard-negative`: the skill should not activate and should not influence the run
- `boundary`: ambiguous, adversarial, or partially relevant prompts

Recommended starting mix:

- 50-60% `invoked-task`
- 25-30% `hard-negative`
- 15-20% `boundary`

## Evidence hierarchy

Use the cheapest trustworthy signal first.

1. Deterministic checks
2. Structured trace and state checks
3. Cross-model LLM judge
4. Human review for judge calibration and dispute resolution

The benchmark should never use a judge to answer a question that can be resolved from the trace, the filesystem, a structured output, or an executable oracle.

## Trial policy

- Run each case at least 3 times per skill in pilot mode.
- Use at least 5 times per case for decision-grade comparisons.
- Aggregate by paired case delta, not by separate unpaired averages.
- Report mean delta and a 95% confidence interval.
- Invalid trials are retried up to a bounded limit and are excluded from scoring.

## Result interpretation

The summary metric `mean_delta` is always computed as:

`candidate_a_mean_score - candidate_b_mean_score`

`candidate_a` beats `candidate_b` only when all of the following hold:

- efficacy delta is positive
- the 95% confidence interval excludes zero
- safety/compliance metrics do not regress beyond the benchmark threshold
- activation diagnostics do not show disqualifying false-positive behavior

If those conditions do not hold, the result is either `no_clear_winner` or `insufficient_evidence`.

Publication rule:

- Treat `decision_eligible = true` as the minimum gate for publishing a ranked conclusion.

## Canonical interfaces

- [`case.schema.json`](case.schema.json)
- [`observation.schema.json`](observation.schema.json)
- [`judge-output.schema.json`](judge-output.schema.json)
- [`benchmark-summary.schema.json`](benchmark-summary.schema.json)
- [`runbook.md`](runbook.md)

## Pilot harness

The first runnable harness is [`scripts/run-skill-benchmark.py`](../../../scripts/run-skill-benchmark.py).

Candidate commands receive benchmark context through environment variables:

- `COGWORKS_BENCHMARK_ID`
- `COGWORKS_BENCHMARK_CASE_ID`
- `COGWORKS_BENCHMARK_CASE_FILE`
- `COGWORKS_BENCHMARK_CANDIDATE_ID`
- `COGWORKS_BENCHMARK_TRIAL_ID`
- `COGWORKS_BENCHMARK_WORK_DIR`
- `COGWORKS_BENCHMARK_OBSERVATION_PATH`
- `COGWORKS_BENCHMARK_JUDGE_OUTPUT_PATH`
- `COGWORKS_BENCHMARK_MODEL`
- `COGWORKS_BENCHMARK_AGENT_SURFACE`

Each candidate command must write a normalized observation JSON to `COGWORKS_BENCHMARK_OBSERVATION_PATH`. If the case uses `judge_only` checks, the command should also write a judge output JSON to `COGWORKS_BENCHMARK_JUDGE_OUTPUT_PATH`.

When any case uses `judge_only` checks:
- pass `--judge-model <model-id>` to the harness
- the judge model family must differ from the generator model family
- judge output must record `judge_model`

For Codex CLI runs, the default adapter is [`scripts/skill-benchmark-codex-adapter.py`](../../../scripts/skill-benchmark-codex-adapter.py). It can run `codex exec --json` live or normalize a saved JSONL trace in replay mode.

## Defaults

- benchmark id format: `skill-benchmark-<domain>-<date>`
- schema version: `1.0`
- confidence interval method: paired bootstrap unless a stronger task-specific method is justified
- ranking eligibility requires at least 10 cases and 5 trials per case
- replay evidence makes the run non-decision-grade even when the harness otherwise completes
