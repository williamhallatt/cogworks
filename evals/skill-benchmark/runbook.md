# Skill-vs-Skill Benchmark Runbook

## Procedure

1. Pin the environment: model, agent surface, tools, sandbox, dataset version.
2. Author cases that satisfy `case.schema.json`.
3. Run both candidates under identical fixed conditions.
4. Normalize outputs into `observation.schema.json`.
5. Use `judge-output.schema.json` only for `judge_only` checks.
6. Aggregate into `benchmark-summary.json` and `benchmark-report.md`.

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

Smoke coverage:

```bash
bash tests/run-skill-benchmark-smoke.sh
```
