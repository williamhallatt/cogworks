# Cogworks Testing Guide

This repository has two testing workflows:

- Testing the cogworks toolchain (cross-pipeline benchmark)
- Testing generated skills (deterministic + behavioral)
- Running recursive improvement rounds (test-first, outcome-gated)

## Prerequisites

- `python3`
- `jq`
- Python package `PyYAML`

## Quick Start

Framework meta-tests:

```bash
bash tests/run-black-box-tests.sh
```

Behavioral tests for repo skills:

```bash
python3 tests/framework/scripts/cogworks-eval.py behavioral run --skill-prefix cogworks-
```

Strict provenance mode (fails placeholder/manual traces):

```bash
python3 tests/framework/scripts/cogworks-eval.py behavioral run --skill-prefix cogworks- --strict-provenance
```

Fast trigger smoke tests:

```bash
bash scripts/run-trigger-smoke-tests.sh claude
bash scripts/run-trigger-smoke-tests.sh codex
```

## Docs Attestation Validation

Commits to trunk must include docs attestation trailers in commit messages.

Install local hooks:

```bash
bash scripts/install-git-hooks.sh
```

Hooks are local to each clone. Re-run the installer for every clone.

Validate a single commit:

```bash
bash scripts/validate-docs-attestation.sh --commit HEAD
```

Validate a commit range:

```bash
bash scripts/validate-docs-attestation.sh --range <base_sha>..<head_sha>
```

Trailer contract:

```text
Docs-Impact: updated|none|required-followup
Docs-Updated: <csv-paths>|none
Docs-Why-None: <required when Docs-Impact is none or required-followup>
```

## Test Generated Skills

Layer 1 deterministic checks:

```bash
bash scripts/test-generated-skill.sh --skill-path .claude/skills/my-skill
bash scripts/test-generated-skill.sh --skill-path .agents/skills/my-skill
```

Optional behavioral gate:

```bash
bash scripts/test-generated-skill.sh --skill-path .agents/skills/my-skill --with-behavioral
```

Behavioral pass criteria:

- `activation_f1 >= 0.85`
- `false_positive_rate <= 0.05`
- `negative_control_ratio >= 0.25`
- strict provenance requires `activation_source=skill_tool` for positive activation cases

Capture normalized traces for each pipeline:

```bash
bash scripts/capture-behavioral-trace-claude.sh <case_id> <skill_slug> <raw_trace.json> <out_trace.json>
bash scripts/capture-behavioral-trace-codex.sh <case_id> <skill_slug> <raw_trace.json> <out_trace.json>
```

Refresh traces for both pipelines and strict-validate:

```bash
export COGWORKS_BEHAVIORAL_CLAUDE_REAL_CMD="bash scripts/run-behavioral-case-claude.sh '{skill_slug}' '{case_id}' '{case_json_path}' '{raw_trace_path}'"
export COGWORKS_BEHAVIORAL_CODEX_REAL_CMD="bash scripts/run-behavioral-case-codex.sh '{skill_slug}' '{case_id}' '{case_json_path}' '{raw_trace_path}'"
export COGWORKS_BEHAVIORAL_CLAUDE_CAPTURE_CMD="bash scripts/behavioral-capture-claude.sh '{skill_slug}' '{case_id}' '{case_json_path}' '{raw_trace_path}'"
export COGWORKS_BEHAVIORAL_CODEX_CAPTURE_CMD="bash scripts/behavioral-capture-codex.sh '{skill_slug}' '{case_id}' '{case_json_path}' '{raw_trace_path}'"
bash scripts/refresh-behavioral-traces.sh --mode all
```

For slower environments, run per skill to reduce runtime and context/token burn:

```bash
bash scripts/refresh-behavioral-traces.sh --mode all --skill cogworks-learn
bash scripts/refresh-behavioral-traces.sh --mode all --skill cogworks-encode
```

You can load the same defaults from:

```bash
source scripts/behavioral-env.example.sh
```

Prerequisites for decision-grade capture:
- `codex` and `claude` CLIs are installed and authenticated
- network access to model backends is available during capture

If capture fails, inspect pipeline event logs under:
- `/tmp/cogworks-behavioral-raw/<skill_slug>/<case_id>.codex.events.jsonl`
- `/tmp/cogworks-behavioral-raw/<skill_slug>/<case_id>.claude.events.jsonl`

## Test Cogworks Pipeline (A/B)

Recommended end-to-end command:

```bash
bash scripts/test-cogworks-pipeline.sh --mode offline --run-id 20260220-ab1
```

Real pipeline mode:

```bash
export COGWORKS_BENCH_CLAUDE_CMD="your-claude-runner --sources '{sources_path}' --out '{out_dir}'"
export COGWORKS_BENCH_CODEX_CMD="your-codex-runner --sources '{sources_path}' --out '{out_dir}'"
bash scripts/test-cogworks-pipeline.sh --mode real --run-id 20260220-ab1
```

Outputs:

- `tests/results/pipeline-benchmark/{run_id}/benchmark-summary.json`
- `tests/results/pipeline-benchmark/{run_id}/benchmark-report.md`

## Run Recursive Improvement Round (TDD-First)

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

4. Run a fast round:

```bash
bash scripts/run-recursive-round.sh \
  --round-manifest tests/datasets/recursive-round/round-manifest.local.json \
  --mode fast \
  --run-id rr-20260220-fast1
```

5. Run a deep smoke round:

```bash
bash scripts/run-recursive-round.sh \
  --round-manifest tests/datasets/recursive-round/round-manifest.local.json \
  --mode deep \
  --smoke-only \
  --run-id rr-20260220-deep-smoke1
```

6. Decision-grade deep round (set real backends):

```bash
export COGWORKS_RECURSIVE_BENCH_CLAUDE_REAL_CMD="<real claude benchmark command with {sources_path} and {out_dir}>"
export COGWORKS_RECURSIVE_BENCH_CODEX_REAL_CMD="<real codex benchmark command with {sources_path} and {out_dir}>"
bash scripts/run-recursive-round.sh \
  --round-manifest tests/datasets/recursive-round/round-manifest.local.json \
  --mode deep \
  --run-id rr-20260220-deep-real1
```

Hook execution is driven by `tests/datasets/recursive-round/round-manifest.local.json` via:

- `bash scripts/run-recursive-hook.sh pre_round|generate|improve|regenerate|post_round`

Round outputs:

- `tests/results/meta-loop/{run_id}/round-summary.json`
- `tests/results/meta-loop/{run_id}/round-report.md`

Signal policy:

- Deep mode with `signal_mode=real` and `ranking_eligible=true` is decision-grade.
- `--smoke-only` deep mode is plumbing verification only.

Validate docs consistency:

```bash
bash scripts/validate-recursive-docs.sh
```

## Advanced Manual CLI

```bash
python3 tests/framework/scripts/cogworks-eval.py pipeline-benchmark scaffold --run-id 20260220-ab1
python3 tests/framework/scripts/cogworks-eval.py pipeline-benchmark run --run-id 20260220-ab1 \
  --command-template "claude::./scripts/run-claude-benchmark.sh '{sources_path}' '{out_dir}'" \
  --command-template "codex::./scripts/run-codex-benchmark.sh '{sources_path}' '{out_dir}'"
python3 tests/framework/scripts/cogworks-eval.py pipeline-benchmark summarize --run-id 20260220-ab1
```

## References

- `tests/framework/README.md`
- `tests/datasets/pipeline-benchmark/README.md`
- `tests/run-black-box-tests.sh`
