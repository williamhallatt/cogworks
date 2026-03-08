# Cogworks Testing Guide

## Current Testing Surface

The active testing strategy is:

| Layer | What it tests | Invokes live agent? | Cost |
|---|---|---|---|
| **1 — Deterministic** | Generated skill structure, YAML, citations, sections, metadata | No | Free / instant |
| **2 — Trigger smoke** | Whether the right skill activates on representative prompts | Yes | Low |
| **3 — Sub-agent build smoke** | Whether the maintainer-only Claude/Copilot sub-agent build path still produces a valid generated skill and truthful run artifacts | Optional live run | Low to medium |
| **4 — Skill benchmark** | Paired skill-vs-skill efficacy comparison with separate activation diagnostics | Optional live run | Medium to high |
| **5 — Behavioral evaluation** | Broader judged quality work outside the benchmark harness | Pending reconstruction | High |

Use these layers in order. Do not make quality claims from Layer 1 or Layer 3
alone.

The canonical benchmark specification lives under `evals/`.

## Before You Start

> Before opening an AI coding session: `git clean -fdx tests/results/`

These cached outputs are gitignored, but on-disk files can still leak into
agent context.

Prefer disposable output roots outside the repository for live smoke runs and
benchmark runs. Do not use repo-local `.cogworks-runs/` or
`tmp-agentic-output/` as your default scratch paths.

## Prerequisites

- `python3`
- `jq`
- Python packages `PyYAML`, `jsonschema`
- optional for live tests: the target agent surface CLI

## Layer 1 — Deterministic Checks

Validates generated skill structure statically. No agent is invoked.

**Pass criteria:** exit code `0`, zero critical failures. Exit code `2` means
warnings only.

Run against a generated skill:

```bash
bash scripts/test-generated-skill.sh --skill-path .claude/skills/my-skill
bash scripts/test-generated-skill.sh --skill-path .agents/skills/my-skill
```

Run directly against any skill directory:

```bash
bash tests/framework/graders/deterministic-checks.sh path/to/skill
bash tests/framework/graders/deterministic-checks.sh path/to/skill --json
```

Framework self-checks:

```bash
bash tests/run-black-box-tests.sh
```

## Layer 2 — Trigger Smoke

Checks that the expected skill activates on representative prompts.

Run:

```bash
bash scripts/run-trigger-smoke-tests.sh claude
bash scripts/run-trigger-smoke-tests.sh codex
```

These tests validate invocation behavior only. They do not validate output
quality.

## Layer 3 — Sub-Agent Build Smoke

This is a maintainer-only surface. It is not part of the normal user workflow.

### 3.1 Static contract smoke

Run:

```bash
bash scripts/test-agentic-contract.sh
```

This verifies that the repository still expresses the current product model:
- one stable `cogworks` product entry point
- no public engine-selection syntax
- internal Claude and Copilot sub-agent build docs remain defined
- canonical role specs still exist
- deterministic validation still passes for `skills/cogworks`
- testing docs point to the current maintainer smoke tooling

### 3.2 Live sub-agent smoke

Run a real build using the fixture sources in:

```text
tests/agentic-smoke/fixtures/api-auth-smoke/
```

The canonical manual runbook is:

- `tests/agentic-smoke/README.md`

After the live run completes, validate artifacts with:

```bash
bash scripts/validate-agentic-run.sh \
  --run-root <resolved-run-root> \
  --skill-path <generated-skill-path> \
  --expect-surface claude-cli
```

Copilot example:

```bash
bash scripts/validate-agentic-run.sh \
  --run-root <resolved-run-root> \
  --skill-path <generated-skill-path> \
  --expect-surface copilot-cli
```

### Pass criteria

A passing live sub-agent smoke run must prove all of the following:
- generated skill output exists and remains the primary artifact
- generated `reference.md` passes `validate-synthesis.sh` without critical
  failures
- generated skill directory passes `validate-skill.sh` without critical failures
- `run-manifest.json` exists
- `dispatch-manifest.json` exists
- `stage-index.json` exists, whether emitted at the run root or under
  `final-review/`
- `final-summary.md` exists, whether emitted at the run root or under
  `final-review/`
- all five stage directories exist
- each stage directory contains `stage-status.json`
- `run-manifest.json` records `run_type`, `execution_surface`, and
  `specialist_profile_source`
- `dispatch-manifest.json` records the canonical role profiles, surface
  bindings, model policy, and dispatch modes for each specialist stage

Layer 3 proves that the sub-agent build path still works. It does **not** prove
it is better than alternatives.

## Layer 4 — Skill Benchmark

The repository includes a runnable harness for objective skill-vs-skill
comparison.

Authoritative references:

- `evals/README.md`
- `evals/skill-benchmark/README.md`
- `evals/skill-benchmark/runbook.md`
- `tests/framework/README.md`

Primary runner:

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

Integrity rules:

- `--judge-model` is required whenever any case contains `judge_only` checks
- the judge model family must differ from the generator model family
- invalid trials are rerun and excluded from scoring
- replay evidence is valid for smoke coverage but not for decision-grade ranking
- `decision_eligible = true` is the minimum bar for publishing benchmark
  conclusions

Smoke coverage:

```bash
bash tests/run-skill-benchmark-smoke.sh
```

## Layer 5 — Behavioral Evaluation

Broader behavioral evaluation remains under reconstruction.

Until that work is rebuilt, do not treat older behavioral-eval planning surfaces
as an active quality gate.
