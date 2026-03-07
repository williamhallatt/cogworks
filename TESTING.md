# Cogworks Testing Guide

## Current Testing Surface

The benchmark implementation has been removed. The active testing strategy for cogworks is now:

| Layer | What it tests | Invokes live agent? | Cost |
|---|---|---|---|
| **1 — Deterministic** | Skill file structure, YAML, citations, sections, metadata | No | Free / instant |
| **2 — Trigger smoke** | Whether the right skill activates on representative prompts | Yes | Low |
| **3 — Agentic contract smoke** | Whether the new `--engine agentic` flow writes the required runtime artifacts and still produces a generated skill | Optional live run | Low to medium |
| **4 — Behavioral evaluation** | Quality/activation judged against external rubrics | Pending harness completion | High |

Use these layers in order. Do not make quality or performance claims from Layer 1 or Layer 3 alone.

---

## Before You Start

> Before opening an AI coding session: `git clean -fdx tests/results/`

These cached outputs are gitignored, but on-disk files can still leak into agent context.

---

## Prerequisites

- `python3`
- `jq`
- Python package `PyYAML`
- Optional for live tests: the target agent surface CLI (for example `claude`, Copilot CLI, or another compatible surface)

---

## Layer 1 — Deterministic Checks

Validates skill file structure statically. No agent is invoked.

**Pass criteria:** exit code `0`, zero critical failures. Exit code `2` means warnings only.

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

---

## Layer 2 — Trigger Smoke

Checks that the expected skill activates on representative prompts.

Run:

```bash
bash scripts/run-trigger-smoke-tests.sh claude
bash scripts/run-trigger-smoke-tests.sh codex
```

These tests validate invocation behavior only. They do not validate output quality.

---

## Layer 3 — Agentic Contract Smoke

This is the current way to test the new opt-in agentic flow.

### 3.1 Static contract smoke

Run:

```bash
bash scripts/test-agentic-contract.sh
```

This verifies that the repo contains the required agentic contract surface:
- `--engine agentic` documented in the right places
- stage graph defined
- canonical role specs defined
- Claude and Copilot CLI adapters defined
- deterministic validation still passes for `skills/cogworks`
- testing docs point to the current smoke tooling

### 3.2 Live agentic smoke

Run a real agentic encode using the fixture sources in:

```text
tests/agentic-smoke/fixtures/api-auth-smoke/
```

Run from the repo root if you want to use that repo-relative path directly. If you use a disposable workspace outside the repo, replace it with the fixture directory's absolute path.

The canonical manual runbook is:

- `tests/agentic-smoke/README.md`

After the live run completes, validate artifacts with:

```bash
bash scripts/validate-agentic-run.sh \
  --run-root <resolved-run-root> \
  --skill-path <generated-skill-path>
```

Optional stricter validation when you know the adapter used:

```bash
bash scripts/validate-agentic-run.sh \
  --run-root <resolved-run-root> \
  --skill-path <generated-skill-path> \
  --expect-surface claude-cli \
  --expect-adapter native-subagents
```

Copilot CLI examples:

```bash
bash scripts/validate-agentic-run.sh \
  --run-root <resolved-run-root> \
  --skill-path <generated-skill-path> \
  --expect-surface copilot-cli \
  --expect-adapter native-subagents

bash scripts/validate-agentic-run.sh \
  --run-root <resolved-run-root> \
  --skill-path <generated-skill-path> \
  --expect-surface copilot-cli \
  --expect-adapter single-agent-fallback
```

### Pass criteria

A passing live agentic smoke run must prove all of the following:
- generated skill output still exists and is the primary artifact
- generated `reference.md` passes `validate-synthesis.sh` without critical failures
- generated skill directory passes `validate-skill.sh` without critical failures
- `run-manifest.json` exists
- `dispatch-manifest.json` exists for `native-subagents` runs
- `stage-index.json` exists, whether emitted at the run root or under `final-review/`
- `final-summary.md` exists, whether emitted at the run root or under `final-review/`
- all five stage directories exist
- each stage directory contains `stage-status.json`
- `run-manifest.json` records `engine_mode`, `execution_surface`, `execution_adapter`, `execution_mode`, `specialist_profile_source`, and `agentic_path`
- `dispatch-manifest.json` records the canonical role profiles, surface bindings, model policy, and actual dispatch modes for each specialist stage when `execution_adapter = native-subagents`
- degraded execution is reported honestly when subagents are unavailable

Do not treat a run as stalled only because `deterministic-validation/` or
`final-review/` appears later than earlier stage outputs.

Layer 3 proves that the flow works. It does **not** prove it is better than legacy.

---

## Engine Comparison

Once you have one completed legacy run and one completed agentic run for the
same fixture, generate saved comparison artifacts with:

```bash
python3 scripts/compare-engine-performance.py \
  --legacy-skill-path <legacy-skill-path> \
  --legacy-log <legacy-claude-jsonl-log> \
  --agentic-skill-path <agentic-skill-path> \
  --agentic-log <agentic-claude-jsonl-log> \
  --agentic-run-root <agentic-run-root> \
  --out-dir tests/results/engine-comparison/<run-id>
```

This emits:
- `benchmark-summary.json`
- `benchmark-report.md`

Use the same fixture and destination style for both runs. Do not compare runs
from different source sets or prompt surfaces.

The comparison report is suitable for:
- total duration
- API duration
- billed token counts aggregated from Claude `modelUsage`
- cost
- agentic stage timing approximations

It is **not** sufficient on its own to claim quality superiority.

---

## Layer 4 — Behavioral Evaluation

Behavioral evaluation remains under reconstruction after D-022/D-026. Current authoritative references:

- `tests/framework/QUALITY-SCHEMA.md`
- `tests/framework/HARNESS-SPEC.md`
- `tests/behavioral/cogworks/judge-prompt.md`
- `tests/behavioral/cogworks-encode/judge-prompt.md`
- `tests/behavioral/cogworks-learn/judge-prompt.md`

Current status:
- test cases are retained
- judge prompts are retained
- the replacement harness is not fully implemented yet

### Targeted quality comparison

For the current decision point, use the lightweight cross-model comparison:

```bash
python3 scripts/run-agentic-quality-compare.py \
  --claude-workdir <workspace-with-cogworks-installed>
```

Defaults:
- runs a fixed three-case synthesis set
- uses Claude as generator and Codex as judge
- emits `benchmark-summary.json` and `benchmark-report.md`
- recommends only `continue` or `simplify`

This is a focused decision tool, not a general replacement for the full behavioral harness.

Do not treat behavioral quality as established until the harness exists and emits saved artifacts.

---

## Pre-release Minimum

Before shipping changes to the cogworks orchestrator or agentic runtime, run at least:

```bash
bash tests/framework/graders/deterministic-checks.sh skills/cogworks
bash tests/run-black-box-tests.sh
bash scripts/test-agentic-contract.sh
```

For any claim that the live agentic flow works in Claude Code, also run one manual live smoke from `tests/agentic-smoke/README.md` and validate the result with `scripts/validate-agentic-run.sh`.

---

## What We Cannot Claim Yet

Without a restored comparison harness, you cannot honestly claim:
- agentic is faster
- agentic is more robust
- agentic is higher quality than legacy

Current smoke coverage supports only:
- the contract exists
- the docs are aligned
- the live flow can be exercised and validated for artifact completeness
