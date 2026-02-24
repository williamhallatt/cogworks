---
name: cogworks-test
description: "Run and manage cogworks test suites - deterministic checks, behavioral tests, black-box framework tests, and pipeline benchmarks. Use when testing generated skills, validating skill quality, running regression tests, or checking test framework health."
---

# Cogworks Test Runner

Provides commands for running the cogworks test infrastructure. Use this skill when validating generated skills or checking framework health.

## Quick Reference

### Deterministic Checks (Layer 1)

Validate a single skill's structure, frontmatter, and content:

```bash
bash tests/framework/graders/deterministic-checks.sh <skill-path> --json
```

### Behavioral Tests

Run behavioral gates for all cogworks-prefixed skills:

```bash
python3 tests/framework/scripts/cogworks-eval.py behavioral run --skill-prefix cogworks-
```

### Black-Box Framework Tests

Validate the test framework itself:

```bash
bash tests/run-black-box-tests.sh
```

### Recursive Round

Run a fast recursive improvement round:

```bash
bash scripts/run-recursive-round.sh --round-manifest tests/datasets/recursive-round/round-manifest.local.json --mode fast
```

## Test Layers

| Layer | Tool | Scope | When to Use |
|-------|------|-------|-------------|
| 1 - Deterministic | `deterministic-checks.sh` | Single skill | After every skill change |
| 2 - Behavioral | `cogworks-eval.py behavioral` | All cogworks-* skills | Before PRs touching skills |
| 3 - Black-box | `run-black-box-tests.sh` | Framework meta-tests | After framework changes |
| 4 - Recursive | `run-recursive-round.sh` | Full pipeline | Quality improvement rounds |

## Test Infrastructure Layout

```
tests/
├── framework/
│   ├── graders/              # Deterministic check scripts
│   ├── scripts/              # cogworks-eval.py and helpers
│   └── templates/            # Test case templates
├── behavioral/               # Behavioral test cases and traces
│   ├── cogworks-encode/
│   └── cogworks-learn/
├── datasets/                 # Benchmark manifests and fixtures
│   ├── golden-samples/
│   ├── negative-controls/
│   └── recursive-round/
└── run-black-box-tests.sh    # Framework meta-test runner
```

## Workflow

1. **After skill changes**: Run Layer 1 deterministic checks on the changed skill
2. **Before PRs**: Run Layer 2 behavioral tests for all cogworks-* skills
3. **After framework changes**: Run Layer 3 black-box tests
4. **Quality rounds**: Run Layer 4 recursive rounds (requires manifests)
