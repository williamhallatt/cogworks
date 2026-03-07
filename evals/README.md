# Objective Skill Evaluation

This directory holds the repo's first-principles research and benchmark specification for comparing one agent skill against another.

## Contents

- `research/2026-03-07-objective-skill-evaluation-research.md` — literature-backed findings and design doctrine
- `skill-benchmark/README.md` — canonical benchmark specification
- `skill-benchmark/runbook.md` — concrete execution procedure
- `skill-benchmark/*.schema.json` — machine-readable interfaces for cases, observations, judge outputs, and summaries
- `skill-benchmark/examples/` — starter examples for dataset authors and harness implementers

## Core rules

- Keep the primary benchmark **skill-isolated**: same model, same agent surface, same tools, same environment, different skill only.
- Score **task efficacy after invocation** as the primary result.
- Report **activation accuracy** separately so trigger quality does not blur downstream task quality.
- Prefer **deterministic trace/state checks** over prose judgment whenever possible.
- Use **cross-model judging** only for residual qualities that cannot be checked deterministically.
- Report **variance and uncertainty**, not just a single score.

## Status

This package now includes a pilot harness at [`scripts/run-skill-benchmark.py`](/home/will/code/cogworks/scripts/run-skill-benchmark.py). The runner is intentionally narrow: it expects candidate commands to emit normalized observation artifacts, then it scores, aggregates, and reports the paired comparison.
