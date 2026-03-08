# Skill-vs-Skill Benchmark Specification

This surface defines the maintained contract for comparing two skills under the
same fixed conditions.

## Fixed conditions

Keep all of the following identical across both candidates:

- model
- agent surface
- tool inventory
- sandbox and filesystem policy
- task case
- grader configuration

The intended difference is the skill under test.

## Primary outputs

- `benchmark-summary.json`
- `benchmark-report.md`
- `benchmark-results.json`

## Canonical interfaces

- [`case.schema.json`](/home/will/code/cogworks/evals/skill-benchmark/case.schema.json)
- [`observation.schema.json`](/home/will/code/cogworks/evals/skill-benchmark/observation.schema.json)
- [`judge-output.schema.json`](/home/will/code/cogworks/evals/skill-benchmark/judge-output.schema.json)
- [`benchmark-summary.schema.json`](/home/will/code/cogworks/evals/skill-benchmark/benchmark-summary.schema.json)
- [`runbook.md`](/home/will/code/cogworks/evals/skill-benchmark/runbook.md)
- [`examples/case-example.json`](/home/will/code/cogworks/evals/skill-benchmark/examples/case-example.json)
- [`examples/benchmark-summary.example.json`](/home/will/code/cogworks/evals/skill-benchmark/examples/benchmark-summary.example.json)

## Integrity rules

- `judge_only` checks require an explicit `--judge-model`
- judge and generator model families must differ
- invalid trials are rerun instead of scored
- replay evidence is valid for smoke coverage but not decision-grade ranking
- publish ranked conclusions only when `decision_eligible = true`

## Decision-Grade Policy

Use this surface for publishable benchmark claims only when all of the
following are true:

- both candidates ran under the same model, agent surface, tool inventory, and
  sandbox policy
- deterministic or state-based checks carry the primary grading load
- `judge_only` checks are limited to residual qualities that deterministic
  grading cannot resolve
- the judge model family differs from the generator model family
- `decision_eligible = true`
- `replay_evidence_present = false`
- the summary includes a 95% confidence interval and preserved artifacts

Do not treat single-run anecdotes, replay-only runs, or same-family
generator/judge pairings as decision-grade evidence.
