# Objective Skill Evaluation

Canonical benchmark specification surface for comparing one skill against
another without changing the model, agent surface, tools, or environment.

## Contents

- `skill-benchmark/README.md` — benchmark contract
- `skill-benchmark/runbook.md` — concrete run procedure
- `skill-benchmark/*.schema.json` — machine-readable interfaces used by
  `scripts/run-skill-benchmark.py`
- `skill-benchmark/examples/` — canonical example inputs and summaries used by
  schema validation smoke

## Status

The maintained runnable harness is
[`scripts/run-skill-benchmark.py`](/home/will/code/cogworks/scripts/run-skill-benchmark.py).
Its smoke coverage lives in
[`tests/run-skill-benchmark-smoke.sh`](/home/will/code/cogworks/tests/run-skill-benchmark-smoke.sh).

Decision-grade benchmark claims must remain on the canonical `evals/` surface.
Research drafts under `_sources/evals/` may inform the benchmark design, but
they are not part of the maintained executable contract.

## Behavioral Evaluation

- `SUCCESS-CRITERIA.md` — per-layer pass/fail criteria including Layer 5 verdict rules
- `behavioral/` — per-skill judge output schemas:
  - `cogworks.judge-output.schema.json`
  - `cogworks-encode.judge-output.schema.json`
  - `cogworks-learn.judge-output.schema.json`

Layer 5a (deterministic structural validation) runs in `tests/run-all.sh`.
Layer 5b (LLM-judged quality) uses `cogworks-eval.py behavioral judge-prepare`
and `judge-validate`. See `SUCCESS-CRITERIA.md` for pass thresholds.
