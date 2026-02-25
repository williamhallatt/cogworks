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

## Prerequisites

- `python3`
- `jq`
- Python package `PyYAML`
- For Layer 2 live capture and Layer 3 real mode: `claude` and `codex` CLIs installed and authenticated with network access

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

Evaluates whether skills activate on the right prompts and stay silent on negative controls, using stored traces.

**Pass criteria:**
- `activation_f1 >= 0.85`
- `false_positive_rate <= 0.05`
- `negative_control_ratio >= 0.25`
- Strict provenance mode additionally requires `activation_source=skill_tool` for all positive activation cases

### Evaluate against stored traces (no agent invoked)

```bash
python3 tests/framework/scripts/cogworks-eval.py behavioral run --skill-prefix cogworks-
```

With strict provenance (rejects placeholder or manually-authored traces):

```bash
python3 tests/framework/scripts/cogworks-eval.py behavioral run --skill-prefix cogworks- --strict-provenance
```

Results are written to `tests/results/behavioral/<timestamp>/`:
- `<skill>-behavioral.json` — per-skill results
- `summary.json` — overall pass/fail

Run per skill to reduce scope:

```bash
python3 tests/framework/scripts/cogworks-eval.py behavioral run --skill cogworks-learn
```

With behavioral gate added to Layer 1:

```bash
bash scripts/test-generated-skill.sh --skill-path .agents/skills/my-skill --with-behavioral
```

### Live capture (invokes agent CLI — expensive)

Runs the agent against each test case and normalizes the output into a behavioral trace. Required before the evaluate step can use fresh traces.

```bash
export COGWORKS_BEHAVIORAL_CLAUDE_REAL_CMD="bash scripts/run-behavioral-case-claude.sh '{skill_slug}' '{case_id}' '{case_json_path}' '{raw_trace_path}'"
export COGWORKS_BEHAVIORAL_CODEX_REAL_CMD="bash scripts/run-behavioral-case-codex.sh '{skill_slug}' '{case_id}' '{case_json_path}' '{raw_trace_path}'"
export COGWORKS_BEHAVIORAL_CLAUDE_CAPTURE_CMD="bash scripts/behavioral-capture.sh claude '{skill_slug}' '{case_id}' '{case_json_path}' '{raw_trace_path}'"
export COGWORKS_BEHAVIORAL_CODEX_CAPTURE_CMD="bash scripts/behavioral-capture.sh codex '{skill_slug}' '{case_id}' '{case_json_path}' '{raw_trace_path}'"
bash scripts/refresh-behavioral-traces.sh --mode all
```

Or load defaults from the example env file:

```bash
source scripts/behavioral-env.example.sh
bash scripts/refresh-behavioral-traces.sh --mode all
```

Scope to one skill to reduce token burn:

```bash
bash scripts/refresh-behavioral-traces.sh --mode all --skill cogworks-learn
```

To normalize a single existing raw trace without re-running the agent:

```bash
bash scripts/capture-behavioral-trace.sh <claude|codex> <case-id> <skill-slug> <raw-trace.json> <out-trace.json>
```

Sample data for manual testing: `tests/test-data/behavioral-capture/`

If capture fails, inspect event logs under:
- `/tmp/cogworks-behavioral-raw/<skill_slug>/<case_id>.claude.events.jsonl`
- `/tmp/cogworks-behavioral-raw/<skill_slug>/<case_id>.codex.events.jsonl`

Fast trigger smoke tests (checks skill invocation only, not full behavioral eval):

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

### Options (`scripts/test-cogworks-pipeline.sh`)

| Flag | Default | Description |
|---|---|---|
| `--run-id <id>` | `ab-<timestamp>` | Run identifier |
| `--manifest <path>` | `tests/datasets/pipeline-benchmark/manifest.jsonl` | Benchmark dataset manifest |
| `--results-root <path>` | `tests/results/pipeline-benchmark` | Output root |
| `--repeats <n>` | `3` | Repeat count per task |
| `--variant <label>` | `clean source-order-shuffled` | Variants to run (repeatable) |
| `--mode <offline\|real>` | `offline` | `offline` = plumbing check; `real` = decision-grade |
| `--force` | off | Overwrite existing run output (required to re-run after a partial run) |
| `--dry-run` | off | Write placeholder metadata only; skip summarize |

### Offline (plumbing verification)

```bash
bash scripts/test-cogworks-pipeline.sh --mode offline --run-id 20260220-ab1
```

### Real mode (decision-grade)

Point the benchmark commands at your actual encode runners:

```bash
export COGWORKS_BENCH_CLAUDE_CMD="your-claude-runner --sources '{sources_path}' --out '{out_dir}'"
export COGWORKS_BENCH_CODEX_CMD="your-codex-runner --sources '{sources_path}' --out '{out_dir}'"
bash scripts/test-cogworks-pipeline.sh --mode real --run-id 20260220-ab1
```

Each command must write `<out_dir>/metrics.json` with at least:
`layer1_pass`, `quality_score`, `activation_f1`, `false_positive_rate`, `negative_control_ratio`, `perturbation_success`, `runtime_sec`, `usage.total_tokens`, `usage.context_tokens`, `failed`.

Re-running after a partial run:

```bash
bash scripts/test-cogworks-pipeline.sh --mode real --run-id 20260220-ab1 --force
```

Outputs:
- `tests/results/pipeline-benchmark/{run_id}/benchmark-summary.json`
- `tests/results/pipeline-benchmark/{run_id}/benchmark-report.md`

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

The `pipeline-benchmark` subcommand requires `scripts/` on PYTHONPATH. Prefer `scripts/test-cogworks-pipeline.sh` as the entry point. For direct CLI access:

```bash
export PYTHONPATH="$PWD/scripts:${PYTHONPATH:-}"
python3 tests/framework/scripts/cogworks-eval.py pipeline-benchmark scaffold --run-id 20260220-ab1
python3 tests/framework/scripts/cogworks-eval.py pipeline-benchmark run --run-id 20260220-ab1 \
  --command-template "claude::./scripts/run-benchmark.sh claude '{sources_path}' '{out_dir}'" \
  --command-template "codex::./scripts/run-benchmark.sh codex '{sources_path}' '{out_dir}'"
python3 tests/framework/scripts/cogworks-eval.py pipeline-benchmark summarize --run-id 20260220-ab1
```

---

## References

- `tests/framework/README.md`
- `tests/datasets/pipeline-benchmark/README.md`
- `tests/datasets/recursive-round/README.md`
- `tests/run-black-box-tests.sh`

