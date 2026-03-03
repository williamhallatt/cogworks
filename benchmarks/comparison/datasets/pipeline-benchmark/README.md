# Pipeline Benchmark Dataset

Shared dataset for Claude-vs-Codex skill-generation benchmark runs.
Canonical run order and troubleshooting: `benchmarks/comparison/RUNBOOK.md`.

Hard-suite tasks are included through `pb-010-*`; use `protocol-hard-v2.json` for expanded comparison runs.

## Manifest

Path: `benchmarks/comparison/datasets/pipeline-benchmark/manifest.jsonl`

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
bash benchmarks/comparison/scripts/test-cogworks-pipeline.sh --mode offline --run-id 20260220-ab1
```

Real mode:

```bash
export COGWORKS_BENCH_CLAUDE_CMD="bash scripts/recursive-bench.sh claude '{sources_path}' '{out_dir}'"
export COGWORKS_BENCH_CODEX_CMD="bash scripts/recursive-bench.sh codex '{sources_path}' '{out_dir}'"
bash benchmarks/comparison/scripts/test-cogworks-pipeline.sh --mode real --run-id 20260220-ab1
```

Comparator comparison mode (cogworks vs generator-a vs generator-b):

```bash
bash benchmarks/comparison/scripts/test-generator-comparison.sh \
  --comparators benchmarks/comparison/datasets/pipeline-benchmark/comparators.local.json \
  --mode offline \
  --run-id comp-20260303-smoke1
```

Protocol-run comparator benchmark (authoritative for workflow-style generators):

```bash
bash benchmarks/comparison/scripts/run-protocol-benchmark.sh \
  --protocol benchmarks/comparison/datasets/pipeline-benchmark/protocol-pilot.json \
  --mode offline \
  --run-id protocol-20260303-smoke1 \
  --force
```

Hard-suite protocol run:

```bash
bash benchmarks/comparison/scripts/run-protocol-benchmark.sh \
  --protocol benchmarks/comparison/datasets/pipeline-benchmark/protocol-hard-v2.json \
  --mode real \
  --run-id protocol-hard-v2-real-$(date +%Y%m%d-%H%M%S) \
  --force
```

If you explicitly need legacy comparator summary files for downstream tooling, add:

```bash
--compat-summary
```

Decision-grade note:
- Set `COGWORKS_RECURSIVE_BENCH_CLAUDE_REAL_CMD` and `COGWORKS_RECURSIVE_BENCH_CODEX_REAL_CMD` to real benchmark backends.
- Without those, wrapper scripts emit smoke metrics for reproducibility.

## Raw CLI

```bash
python3 tests/framework/scripts/cogworks-eval.py pipeline-benchmark scaffold --run-id 20260220-ab1
python3 tests/framework/scripts/cogworks-eval.py pipeline-benchmark run --run-id 20260220-ab1 \
  --command-template "claude::./benchmarks/comparison/scripts/run-benchmark.sh claude '{sources_path}' '{out_dir}'" \
  --command-template "codex::./benchmarks/comparison/scripts/run-benchmark.sh codex '{sources_path}' '{out_dir}'"
python3 tests/framework/scripts/cogworks-eval.py pipeline-benchmark summarize --run-id 20260220-ab1
```

If running raw CLI directly, set:

```bash
export PYTHONPATH="$(pwd)/benchmarks/comparison/scripts:${PYTHONPATH:-}"
```
