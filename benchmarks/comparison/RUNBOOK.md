# Comparison Benchmark Runbook

Canonical operational runbook for comparison benchmarking under `benchmarks/comparison/`.

## Scope

This runbook covers:
- pipeline benchmark smoke/deep runs
- comparator runs (`cogworks`, `generator-a`, `generator-b`)
- protocol pilot and hard-suite runs
- required environment and troubleshooting

## Directory Contract

- Scripts: `benchmarks/comparison/scripts/`
- Datasets: `benchmarks/comparison/datasets/pipeline-benchmark/`
- Results: `benchmarks/comparison/results/pipeline-benchmark/`
- Comparator repos: `benchmarks/comparison/comparators/`
- Protocol docs: `benchmarks/comparison/docs/protocols/`

## Environment Contract

Required for `--mode real` (pipeline benchmark):
- `COGWORKS_BENCH_CLAUDE_CMD`
- `COGWORKS_BENCH_CODEX_CMD`

Optional comparator overrides:
- `COGWORKS_BENCH_GENERATOR_A_CMD`
- `COGWORKS_BENCH_GENERATOR_B_CMD`

Recommended for direct raw CLI use:
```bash
export PYTHONPATH="$(pwd)/benchmarks/comparison/scripts:${PYTHONPATH:-}"
```

Network requirement:
- Real protocol runs use `codex exec` and require backend connectivity.

## Command Order (Recommended)

1. Pipeline smoke
```bash
bash tests/run-pipeline-benchmark-smoke.sh
```

2. Comparator dry smoke (offline)
```bash
bash benchmarks/comparison/scripts/test-generator-comparison.sh \
  --comparators benchmarks/comparison/datasets/pipeline-benchmark/comparators.local.json \
  --mode offline \
  --run-id comp-smoke-$(date +%Y%m%d-%H%M%S)
```

3. Protocol pilot (offline smoke)
```bash
bash benchmarks/comparison/scripts/run-protocol-benchmark.sh \
  --protocol benchmarks/comparison/datasets/pipeline-benchmark/protocol-pilot.json \
  --mode offline \
  --run-id protocol-pilot-smoke-$(date +%Y%m%d-%H%M%S) \
  --force
```

4. Protocol pilot (real)
```bash
bash benchmarks/comparison/scripts/run-protocol-benchmark.sh \
  --protocol benchmarks/comparison/datasets/pipeline-benchmark/protocol-pilot.json \
  --mode real \
  --run-id protocol-pilot-real-$(date +%Y%m%d-%H%M%S) \
  --force
```

5. Protocol hard suite (real)
```bash
bash benchmarks/comparison/scripts/run-protocol-benchmark.sh \
  --protocol benchmarks/comparison/datasets/pipeline-benchmark/protocol-hard-v2.json \
  --mode real \
  --run-id protocol-hard-real-$(date +%Y%m%d-%H%M%S) \
  --force
```

Optional legacy compatibility summary:
```bash
# add to protocol command when needed
--compat-summary
```

## Expected Artifacts

Pipeline benchmark:
- `benchmarks/comparison/results/pipeline-benchmark/<run-id>/benchmark-summary.json`
- `benchmarks/comparison/results/pipeline-benchmark/<run-id>/benchmark-report.md`

Protocol benchmark:
- `benchmarks/comparison/results/pipeline-benchmark/<run-id>/pilot-summary.json`
- `benchmarks/comparison/results/pipeline-benchmark/<run-id>/pilot-report.md`
- `benchmarks/comparison/results/pipeline-benchmark/<run-id>/quality-first-ranking.md`

Per-run:
- `run-metadata.json`
- `metrics.json`
- `generation-artifact.json` (protocol)
- `quality-eval.json` (protocol)

## Cleaning Previous Results

Prefer unique run IDs.  
If reusing a run ID, pass `--force`.

Results authority and retention:
- `benchmarks/comparison/results/` is generated output, not source-of-truth content.
- It is safe to delete local run directories after analysis.
- Do not use in-repo local results for external claims; authoritative evidence must come from external benchmark repo CI artifacts.

To remove a specific old run:
```bash
rm -rf "benchmarks/comparison/results/pipeline-benchmark/<run-id>"
```

## Troubleshooting

`No prompt provided via stdin`:
- Ensure protocol manifest uses wrapper templates from `benchmarks/comparison/scripts/run-protocol-generator.sh`.

`stream disconnected ... codex/responses`:
- Real protocol run cannot reach backend; verify network/auth and retry.

`all pipelines disqualified` vs protocol winner mismatch:
- Use `pilot-summary.json` as authoritative for protocol runs.
- `benchmark-summary.json` is legacy comparator summary and optional.

`Missing comparator runner`:
- Set `COGWORKS_BENCH_GENERATOR_A_CMD` / `COGWORKS_BENCH_GENERATOR_B_CMD` or provide executable comparator runner scripts.

## CI Smoke Matrix

Run these in CI for path/contract health:
1. `bash tests/run-pipeline-benchmark-smoke.sh`
2. `bash benchmarks/comparison/scripts/run-protocol-benchmark.sh --protocol benchmarks/comparison/datasets/pipeline-benchmark/protocol-pilot.json --mode offline --run-id ci-protocol-pilot --force`
3. `bash benchmarks/comparison/scripts/run-protocol-benchmark.sh --protocol benchmarks/comparison/datasets/pipeline-benchmark/protocol-hard-v2.json --mode offline --run-id ci-protocol-hard --force`

## External Objective Validation

For high-trust, externally reproducible comparisons, use the standalone kit:

1. Scaffold external repo:
   `bash benchmarks/comparison/external-validation-kit/scaffold-external-repo.sh --target /abs/path/skill-benchmark-lab`
2. Follow external runbook:
   `/abs/path/skill-benchmark-lab/RUNBOOK.md`
3. Treat only CI runs from the external repo as authoritative.
