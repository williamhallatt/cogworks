# Cogworks Test Framework

Unified testing framework for both Claude and Codex pipelines.

Canonical recursive round runbook: `tests/datasets/recursive-round/README.md`

## Scope

This framework supports two test tracks:

- Layer 1 deterministic checks for generated skills
- Behavioral activation tests (pending reconstruction — see D-022/D-023)

## Primary Commands

Generated skill tests:

```bash
bash scripts/test-generated-skill.sh --skill-path .claude/skills/my-skill
```

Recursive TDD round:

```bash
source scripts/recursive-env.example.sh
bash scripts/run-recursive-round.sh \
  --round-manifest tests/datasets/recursive-round/round-manifest.local.json \
  --mode fast \
  --run-id rr-20260220-fast1
```

## Advanced CLI

```bash
python3 tests/framework/scripts/cogworks-eval.py behavioral scaffold --skill cogworks-newskill
bash scripts/run-trigger-smoke-tests.sh claude
bash scripts/run-trigger-smoke-tests.sh codex
```

> **Note:** `cogworks-eval.py behavioral run` is blocked — traces were deleted (D-022). Capture scripts have been removed (D-023). See Parker's mandate: `.squad/agents/parker/charter.md`.

## Framework Layout

```text
tests/framework/
├── graders/
│   └── deterministic-checks.sh
├── scripts/
│   ├── behavioral_lib.py
│   └── cogworks-eval.py
└── templates/
    ├── behavioral-test-case-template.jsonl
    └── behavioral-trace-template.json
```

