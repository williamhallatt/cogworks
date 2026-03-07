# Objective Skill Benchmark Framework

## Accepted direction

1. Treat skill evaluation as a paired intervention on a fixed agent system.
2. Compare skill against skill, not full system against full system.
3. Make efficacy the primary score and activation a separate scorecard.
4. Prefer deterministic trace and state evidence over prose judgments.
5. Use cross-model judging only for residual qualitative criteria.
6. Write the resulting research and benchmark doctrine into `evals/`.

## Implemented

- Added `evals/` as the canonical home for skill-evaluation research and benchmark specs.
- Wrote a research memo synthesizing local material with external evaluation sources.
- Defined a reusable skill-vs-skill benchmark specification and execution runbook.
- Added machine-readable schemas for benchmark cases, normalized observations, judge outputs, and benchmark summaries.
- Added starter example artifacts for dataset and harness authors.
- Extracted the core architectural decision into `_plans/DECISIONS.md`.

## Outstanding

- No execution harness has been implemented yet.
- No benchmark dataset has been instantiated yet.
- No CI gate currently validates artifacts in `evals/skill-benchmark/`.

## Outcome

The repo now has a decision-complete specification package for objective skill-vs-skill benchmarking. Future implementation work can build the harness and datasets without reopening the benchmark-policy questions.
