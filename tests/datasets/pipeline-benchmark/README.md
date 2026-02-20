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
export COGWORKS_BENCH_CLAUDE_CMD="your-claude-runner --sources '{sources_path}' --out '{out_dir}'"
export COGWORKS_BENCH_CODEX_CMD="your-codex-runner --sources '{sources_path}' --out '{out_dir}'"
bash scripts/test-cogworks-pipeline.sh --mode real --run-id 20260220-ab1
```

## Raw CLI

```bash
python3 tests/framework/scripts/cogworks-eval.py pipeline-benchmark scaffold --run-id 20260220-ab1
python3 tests/framework/scripts/cogworks-eval.py pipeline-benchmark run --run-id 20260220-ab1 \
  --command-template "claude::./scripts/run-claude-benchmark.sh '{sources_path}' '{out_dir}'" \
  --command-template "codex::./scripts/run-codex-benchmark.sh '{sources_path}' '{out_dir}'"
python3 tests/framework/scripts/cogworks-eval.py pipeline-benchmark summarize --run-id 20260220-ab1
```
