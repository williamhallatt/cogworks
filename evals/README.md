# Objective Skill Evaluation

Canonical benchmark specification surface for comparing one skill against
another without changing the model, agent surface, tools, or environment.

## Contents

- `skill-benchmark/README.md` — benchmark contract
- `skill-benchmark/runbook.md` — concrete run procedure
- `skill-benchmark/*.schema.json` — machine-readable interfaces used by
  `scripts/run-skill-benchmark.py`

## Status

The maintained runnable harness is
[`scripts/run-skill-benchmark.py`](/home/will/code/cogworks/scripts/run-skill-benchmark.py).
Its smoke coverage lives in
[`tests/run-skill-benchmark-smoke.sh`](/home/will/code/cogworks/tests/run-skill-benchmark-smoke.sh).
