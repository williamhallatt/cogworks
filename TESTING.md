# Cogworks Testing Guide

## Test Layers

There are three test layers, ordered by cost:

| Layer | What it tests | Invokes agent CLI? | Cost |
|---|---|---|---|
| **1 — Deterministic** | Skill file structure, YAML, citations, sections, metadata | No | Free / instant |
| **2 — Behavioral** | Skill activation, tool use, negative controls (against stored traces) | No (evaluation only) | Low |
| **2 — Behavioral (live capture)** | Same, but runs agent to generate fresh traces first | Yes | High — burns real tokens |
| **3 — Pipeline benchmark** | Full `cogworks encode` end-to-end, both pipelines, A/B comparison | Yes (real mode only) | Very high |

**Offline/smoke mode** (Layer 3 default) uses hardcoded deterministic metrics to verify the benchmark plumbing works. Results in offline mode are not decision-grade — no real encoding runs and the winner is meaningless.

**Decision-grade** results require real backends for both Layer 2 live capture and Layer 3 real mode.

---

## Before you start

> **Before opening an AI coding session:** run `git clean -fdx tests/results/` to remove cached test outputs. These are gitignored but on-disk files will be surfaced in agent context.

---

## Prerequisites

- `python3`
- `jq`
- Python package `PyYAML`

---

## Pre-release CI Gate

Before any release, run the pre-release quality gate:

```bash
bash tests/ci-gate-check.sh
```

This gate runs:
1. Deterministic checks via `scripts/validate-quality-gates.sh`
2. Behavioral trace coverage check — **exits non-zero (D-022/D-023 pending reconstruction)**

> **Note:** The behavioral evaluation step is blocked pending Parker's quality ground truth definition (D-022). The CI gate will fail on behavioral coverage until replacement ground truth is in place. Layer 1 deterministic checks still pass independently.

Exit code 0 indicates all gates passed. Exit code 1 indicates failure.

---

## Layer 1 — Deterministic Checks

Validates skill file structure statically. No agent invoked. Runs in under a second.

**Pass criteria:** exit code 0, zero critical failures. Warnings produce exit code 2 (not a hard failure for CI, but indicate drift from best practices).

Run against a generated skill:

```bash
bash scripts/test-generated-skill.sh --skill-path .claude/skills/my-skill
bash scripts/test-generated-skill.sh --skill-path .agents/skills/my-skill
```

Run the framework meta-tests (validates the test harness itself):

```bash
bash tests/run-black-box-tests.sh
```

Run directly against any skill directory:

```bash
bash tests/framework/graders/deterministic-checks.sh path/to/skill
bash tests/framework/graders/deterministic-checks.sh path/to/skill --json   # machine-readable output
```

---

## Layer 2 — Behavioral Tests

> **⚠️ Pending reconstruction (D-022/D-023).**
> Behavioral traces were deleted — they were LLM-generated circular ground truth (`quality_score: null` on all core skill traces; `task_completed: false` in baseline runs). The capture scripts that generated them have also been removed.
> The CI gate blocks regeneration. Parker (Benchmark & Evaluation Engineer) is defining replacement quality ground truth from first principles. See `.squad/agents/parker/charter.md`.

Evaluates whether skills activate on the right prompts and stay silent on negative controls.

**Target pass criteria (to be re-established by Parker):**
- `activation_f1 >= 0.85`
- `false_positive_rate <= 0.05`
- `negative_control_ratio >= 0.25`

Test cases (`tests/behavioral/*/test-cases.jsonl`) are valid and retained — they define activation intent, not ground truth. 39 cases across 3 skills.

To scaffold test cases for a new skill:

```bash
python3 tests/framework/scripts/cogworks-eval.py behavioral scaffold --skill cogworks-newskill
```

Fast trigger smoke tests (checks skill invocation only — not full behavioral eval):

```bash
bash scripts/run-trigger-smoke-tests.sh claude
bash scripts/run-trigger-smoke-tests.sh codex
```

---

## Layer 3 — Pipeline Benchmark (A/B)

Runs `cogworks encode` end-to-end against benchmark datasets and compares claude vs codex pipelines.

**Guardrails** (both pipelines must pass to be eligible for winner selection):
- `structural_pass_rate >= 0.95`
- `activation_f1 >= 0.85`
- `false_positive_rate <= 0.05`
- `negative_control_ratio >= 0.25`

**Offline mode** (default) — verifies benchmark plumbing only. Uses hardcoded deterministic metrics; no real encoding runs; winner is not meaningful.

**Real mode** — runs actual encode pipelines; produces decision-grade results.

### Options (`benchmarks/comparison/scripts/test-cogworks-pipeline.sh`)

| Flag | Default | Description |
|---|---|---|
| `--run-id <id>` | `ab-<timestamp>` | Run identifier |
| `--manifest <path>` | `benchmarks/comparison/datasets/pipeline-benchmark/manifest.jsonl` | Benchmark dataset manifest |
| `--results-root <path>` | `benchmarks/comparison/results/pipeline-benchmark` | Output root |
| `--repeats <n>` | `3` | Repeat count per task |
| `--variant <label>` | `clean source-order-shuffled` | Variants to run (repeatable) |
| `--mode <offline\|real>` | `offline` | `offline` = plumbing check; `real` = decision-grade |
| `--force` | off | Overwrite existing run output (required to re-run after a partial run) |
| `--dry-run` | off | Write placeholder metadata only; skip summarize |

### Offline (plumbing verification)

```bash
bash benchmarks/comparison/scripts/test-cogworks-pipeline.sh --mode offline --run-id 20260220-ab1
```

### Real mode (decision-grade)

Point the benchmark commands at your actual encode runners:

```bash
export COGWORKS_BENCH_CLAUDE_CMD="your-claude-runner --sources '{sources_path}' --out '{out_dir}'"
export COGWORKS_BENCH_CODEX_CMD="your-codex-runner --sources '{sources_path}' --out '{out_dir}'"
bash benchmarks/comparison/scripts/test-cogworks-pipeline.sh --mode real --run-id 20260220-ab1
```

Each command must write `<out_dir>/metrics.json` with at least:
`layer1_pass`, `quality_score`, `activation_f1`, `false_positive_rate`, `negative_control_ratio`, `perturbation_success`, `runtime_sec`, `usage.total_tokens`, `usage.context_tokens`, `failed`.

Re-running after a partial run:

```bash
bash benchmarks/comparison/scripts/test-cogworks-pipeline.sh --mode real --run-id 20260220-ab1 --force
```

Outputs:
- `benchmarks/comparison/results/pipeline-benchmark/{run_id}/benchmark-summary.json`
- `benchmarks/comparison/results/pipeline-benchmark/{run_id}/benchmark-report.md`

### Comparator Benchmark (A/B/C)

Compare cogworks against two external generators (`generator-a`, `generator-b`) with shared fairness controls (same model family + budget limits) from:

- `benchmarks/comparison/datasets/pipeline-benchmark/comparators.local.json`

Expected local comparator paths:

- `benchmarks/comparison/comparators/generator-a/`
- `benchmarks/comparison/comparators/generator-b/`

Run plumbing check (offline):

```bash
bash benchmarks/comparison/scripts/test-generator-comparison.sh --mode offline --run-id comp-20260303-smoke1
```

Run decision-grade comparison (real mode):

```bash
bash benchmarks/comparison/scripts/test-generator-comparison.sh --mode real --run-id comp-20260303-real1
```

Override comparator commands when their local default scripts differ:

```bash
export COGWORKS_BENCH_GENERATOR_A_CMD="bash {comparator_dir}/scripts/benchmark.sh '{sources_path}' '{out_dir}'"
export COGWORKS_BENCH_GENERATOR_B_CMD="bash {comparator_dir}/scripts/benchmark.sh '{sources_path}' '{out_dir}'"
```

Comparator adapters normalize outputs through:

- `benchmarks/comparison/scripts/run-comparator-benchmark.sh`
- `benchmarks/comparison/scripts/run-generator-a.sh`
- `benchmarks/comparison/scripts/run-generator-b.sh`

Additional output:

- `benchmarks/comparison/results/pipeline-benchmark/{run_id}/quality-first-ranking.md`

### Protocol-Run Comparator Benchmark (Authoritative for Workflow Toolkits)

Use this path when comparators are workflow/process repositories (not one-shot generators with a stable metrics contract).

Canonical operational runbook:
- `benchmarks/comparison/RUNBOOK.md`

Protocol manifests:
- `benchmarks/comparison/datasets/pipeline-benchmark/protocol-pilot.json` (fast pilot)
- `benchmarks/comparison/datasets/pipeline-benchmark/protocol-hard-v2.json` (expanded hard suite)

Runbooks:
- `benchmarks/comparison/docs/protocols/cogworks.md`
- `benchmarks/comparison/docs/protocols/generator-a.md`
- `benchmarks/comparison/docs/protocols/generator-b.md`

Pilot tasks (current default): `pb-001-api-auth`, `pb-002-k8s-troubleshoot`

Offline protocol smoke run:

```bash
bash benchmarks/comparison/scripts/run-protocol-benchmark.sh \
  --protocol benchmarks/comparison/datasets/pipeline-benchmark/protocol-pilot.json \
  --mode offline \
  --run-id protocol-20260303-smoke1 \
  --force
```

Real protocol run:

```bash
bash benchmarks/comparison/scripts/run-protocol-benchmark.sh \
  --protocol benchmarks/comparison/datasets/pipeline-benchmark/protocol-pilot.json \
  --mode real \
  --run-id protocol-20260303-real1 \
  --force
```

Hard-suite real protocol run:

```bash
bash benchmarks/comparison/scripts/run-protocol-benchmark.sh \
  --protocol benchmarks/comparison/datasets/pipeline-benchmark/protocol-hard-v2.json \
  --mode real \
  --run-id protocol-hard-v2-real1 \
  --force
```

Optional legacy compatibility summary:

```bash
bash benchmarks/comparison/scripts/run-protocol-benchmark.sh \
  --protocol benchmarks/comparison/datasets/pipeline-benchmark/protocol-pilot.json \
  --mode real \
  --run-id protocol-20260303-real1 \
  --force \
  --compat-summary
```

Artifacts:
- `benchmarks/comparison/results/pipeline-benchmark/{run_id}/pilot-summary.json` (protocol summary)
- `benchmarks/comparison/results/pipeline-benchmark/{run_id}/pilot-report.md`
- `benchmarks/comparison/results/pipeline-benchmark/{run_id}/quality-first-ranking.md`

Optional compatibility artifact:
- `benchmarks/comparison/results/pipeline-benchmark/{run_id}/benchmark-summary.json` (legacy comparator summary; non-authoritative in protocol mode)

Per-run artifacts:
- `generation-artifact.json`
- `quality-eval.json`
- `metrics.json`

---

## Recursive Improvement Round (TDD-First)

Canonical runbook: `tests/datasets/recursive-round/README.md`

1. Start from the example manifest:

```bash
cp tests/datasets/recursive-round/round-manifest.example.json \
  tests/datasets/recursive-round/round-manifest.local.json
```

2. Freeze tests by writing `expected_sha256`:

```bash
bash scripts/pin-test-bundle-hash.sh \
  tests/datasets/recursive-round/round-manifest.local.json
```

3. Load concrete defaults for hook + benchmark commands:

```bash
source scripts/recursive-env.example.sh
```

4. Fast round (Layer 1 only, no benchmark):

```bash
bash scripts/run-recursive-round.sh \
  --round-manifest tests/datasets/recursive-round/round-manifest.local.json \
  --mode fast \
  --run-id rr-20260220-fast1
```

5. Deep smoke round (full pipeline, offline metrics — plumbing check):

```bash
bash scripts/run-recursive-round.sh \
  --round-manifest tests/datasets/recursive-round/round-manifest.local.json \
  --mode deep \
  --smoke-only \
  --run-id rr-20260220-deep-smoke1
```

6. Decision-grade deep round (set real backends first):

```bash
export COGWORKS_RECURSIVE_BENCH_CLAUDE_REAL_CMD="<real claude benchmark command with {sources_path} and {out_dir}>"
export COGWORKS_RECURSIVE_BENCH_CODEX_REAL_CMD="<real codex benchmark command with {sources_path} and {out_dir}>"
bash scripts/run-recursive-round.sh \
  --round-manifest tests/datasets/recursive-round/round-manifest.local.json \
  --mode deep \
  --run-id rr-20260220-deep-real1
```

Hook execution is driven by `tests/datasets/recursive-round/round-manifest.local.json` via:

```bash
bash scripts/run-recursive-hook.sh pre_round|generate|improve|regenerate|post_round
```

Round outputs:
- `tests/results/meta-loop/{run_id}/round-summary.json`
- `tests/results/meta-loop/{run_id}/round-report.md`

Signal policy: deep mode with `signal_mode=real` and `ranking_eligible=true` is decision-grade. `--smoke-only` and `--mode fast` are plumbing verification only.

Validate docs consistency:

```bash
bash scripts/validate-recursive-docs.sh
```

---

## Advanced Manual CLI

The `pipeline-benchmark` subcommand requires `benchmarks/comparison/scripts/` on `PYTHONPATH` (for `pipeline_benchmark.py`). Prefer `benchmarks/comparison/scripts/test-cogworks-pipeline.sh` as the entry point. For direct CLI access:

```bash
export PYTHONPATH="$PWD/scripts:${PYTHONPATH:-}"
python3 tests/framework/scripts/cogworks-eval.py pipeline-benchmark scaffold --run-id 20260220-ab1
python3 tests/framework/scripts/cogworks-eval.py pipeline-benchmark run --run-id 20260220-ab1 \
  --command-template "claude::./benchmarks/comparison/scripts/run-benchmark.sh claude '{sources_path}' '{out_dir}'" \
  --command-template "codex::./benchmarks/comparison/scripts/run-benchmark.sh codex '{sources_path}' '{out_dir}'"
python3 tests/framework/scripts/cogworks-eval.py pipeline-benchmark summarize --run-id 20260220-ab1
```

---

## References

- `tests/framework/README.md`
- `benchmarks/comparison/datasets/pipeline-benchmark/README.md`
- `tests/datasets/recursive-round/README.md`
- `tests/run-black-box-tests.sh`
