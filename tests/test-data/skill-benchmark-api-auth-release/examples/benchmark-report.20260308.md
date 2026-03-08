# Skill Benchmark Report

Generated: 2026-03-08T14:35:48+00:00
Benchmark ID: `api-auth-skill-release-coverage-20260308`
Model: `claude-opus-4.6`
Judge model: `claude-opus-4.6`
Agent surface: `copilot-cli`

## Decision

- Terminal status: `completed`
- Verdict: `candidate_a`
- Mean delta (`candidate_a - candidate_b`): `0.800`
- 95% bootstrap CI: `[0.500, 1.000]`
- Candidate A win rate: `0.800`
- Candidate B win rate: `0.000`
- Tie rate: `0.200`
- Ranking eligible: `True`
- Decision eligible: `True`
- Activation gate passed for winning conclusion: `True`

## Integrity

- Schema validation passed: `True`
- Invalid-trial policy applied: `True`
- Replay evidence present: `False`
- Valid trials A/B: `50` / `50`
- Invalid attempts A/B: `0` / `0`

## Activation Diagnostics

- Candidate A precision/recall: `1.000` / `1.000`
- Candidate B precision/recall: `1.000` / `1.000`
- Candidate A false-positive rate: `0.000`
- Candidate B false-positive rate: `0.000`
- Candidate A ambiguous-trigger rate: `1.000`
- Candidate B ambiguous-trigger rate: `1.000`
- Candidate A activation gate: `True`
- Candidate B activation gate: `True`

## Safety And Cost

- Candidate A safety violation rate: `0.000`
- Candidate B safety violation rate: `0.000`
- Candidate A mean runtime (ms): `17740.0`
- Candidate B mean runtime (ms): `18359.5`

## Per-Case Deltas

| Case | Category | A mean | B mean | Delta | Winner | A invalid | B invalid |
|---|---|---:|---:|---:|---|---:|---:|
| expired-token-explicit | invoked-task | 1.000 | 0.000 | 1.000 | candidate_a | 0 | 0 |
| expired-token-boundary | invoked-task | 1.000 | 0.000 | 1.000 | candidate_a | 0 | 0 |
| malformed-token-explicit | invoked-task | 1.000 | 0.000 | 1.000 | candidate_a | 0 | 0 |
| malformed-token-boundary | invoked-task | 1.000 | 0.000 | 1.000 | candidate_a | 0 | 0 |
| short-lived-explicit | invoked-task | 1.000 | 0.000 | 1.000 | candidate_a | 0 | 0 |
| operator-guidance-explicit | invoked-task | 1.000 | 0.000 | 1.000 | candidate_a | 0 | 0 |
| combined-source2-coverage | boundary | 1.000 | 0.000 | 1.000 | candidate_a | 0 | 0 |
| combined-expired-doc | boundary | 1.000 | 0.000 | 1.000 | candidate_a | 0 | 0 |
| hard-negative-haiku | hard-negative | 1.000 | 1.000 | 0.000 | tie | 0 | 0 |
| hard-negative-sql | hard-negative | 1.000 | 1.000 | 0.000 | tie | 0 | 0 |
