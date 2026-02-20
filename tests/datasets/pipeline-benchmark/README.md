# Pipeline Benchmark Dataset

Shared dataset for Claude-vs-Codex skill-generation benchmark runs.

## Manifest

Path: `tests/datasets/pipeline-benchmark/manifest.jsonl`

Each JSONL row defines:

- `task_id`
- `sources_path`
- `expected_skill_intent`
- `domain`
- `difficulty`
- `risk_tier`

## Run Benchmark

Preferred:

```bash
bash scripts/test-cogworks-pipeline.sh --mode offline --run-id 20260220-ab1
```

Real mode:

```bash
export COGWORKS_BENCH_CLAUDE_CMD="bash scripts/recursive-bench-claude.sh '{sources_path}' '{out_dir}'"
export COGWORKS_BENCH_CODEX_CMD="bash scripts/recursive-bench-codex.sh '{sources_path}' '{out_dir}'"
bash scripts/test-cogworks-pipeline.sh --mode real --run-id 20260220-ab1
```

Decision-grade note:
- Set `COGWORKS_RECURSIVE_BENCH_CLAUDE_REAL_CMD` and `COGWORKS_RECURSIVE_BENCH_CODEX_REAL_CMD` to real benchmark backends.
- Without those, wrapper scripts emit smoke metrics for reproducibility.

## Raw CLI

```bash
python3 tests/framework/scripts/cogworks-eval.py pipeline-benchmark scaffold --run-id 20260220-ab1
python3 tests/framework/scripts/cogworks-eval.py pipeline-benchmark run --run-id 20260220-ab1 \
  --command-template "claude::./scripts/run-claude-benchmark.sh '{sources_path}' '{out_dir}'" \
  --command-template "codex::./scripts/run-codex-benchmark.sh '{sources_path}' '{out_dir}'"
python3 tests/framework/scripts/cogworks-eval.py pipeline-benchmark summarize --run-id 20260220-ab1
```
