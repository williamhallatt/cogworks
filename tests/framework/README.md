# Cogworks Test Framework

Unified testing framework for both Claude and Codex pipelines.

Canonical recursive round runbook: `tests/datasets/recursive-round/README.md`

## Scope

This framework supports two test tracks:

- Layer 1 deterministic checks for generated skills
- headless smoke coverage for trigger parsing, benchmark integrity, and schema
  validation

## Primary Commands

Headless offline bar:

```bash
bash tests/run-all.sh
```

Generated skill tests:

```bash
bash scripts/test-generated-skill.sh --skill-path .claude/skills/my-skill
```

Skill benchmark pilot:

```bash
python3 scripts/run-skill-benchmark.py \
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

Codex replay adapter smoke:

```bash
python3 scripts/run-skill-benchmark.py \
  --cases-file tests/test-data/skill-benchmark-codex-adapter/cases.jsonl \
  --candidate-a codex-skill \
  --candidate-a-command "python3 scripts/skill-benchmark-codex-adapter.py --replay-events tests/test-data/skill-benchmark-codex-adapter/candidate-a-events.jsonl" \
  --candidate-b codex-baseline \
  --candidate-b-command "python3 scripts/skill-benchmark-codex-adapter.py --replay-events tests/test-data/skill-benchmark-codex-adapter/candidate-b-events.jsonl" \
  --model gpt-5-codex \
  --agent-surface codex-cli \
  --trials 1
```

Benchmark runner integrity smoke:

```bash
bash tests/run-skill-benchmark-smoke.sh
```

Recursive TDD round:

```bash
cp tests/datasets/recursive-round/round-manifest.example.json \
  /tmp/round-manifest.local.json

bash scripts/pin-test-bundle-hash.sh /tmp/round-manifest.local.json

source scripts/recursive-env.example.sh
bash scripts/run-recursive-round.sh \
  --round-manifest /tmp/round-manifest.local.json \
  --mode fast \
  --run-id rr-20260220-fast1
```

## Advanced CLI

```bash
python3 tests/framework/scripts/cogworks-eval.py behavioral scaffold --skill cogworks-newskill
bash scripts/run-trigger-smoke-tests.sh claude
bash scripts/run-trigger-smoke-tests.sh codex
bash tests/run-trigger-smoke-parser-smoke.sh
```

> **Layer 5b judge evaluation** requires a captured agent trace and a cross-model
> judge. Use `cogworks-eval.py behavioral judge-prepare` to construct the prompt
> and `judge-validate` to validate the output. See `evals/SUCCESS-CRITERIA.md`
> for pass thresholds.

The canonical benchmark contract, decision-grade policy, schemas, and examples
live under `evals/skill-benchmark/`.

## Framework Layout

```text
tests/framework/
├── graders/
│   └── deterministic-checks.sh
├── scripts/
│   ├── behavioral_deterministic.py
│   ├── behavioral_lib.py
│   └── cogworks-eval.py
└── templates/
    └── behavioral-test-case-template.jsonl
```
