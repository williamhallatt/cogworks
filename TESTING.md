# Cogworks Testing Guide

This repository has two testing workflows:

- Testing the cogworks toolchain (cross-pipeline benchmark)
- Testing generated skills (deterministic + behavioral)

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
