# Recursive Round Runbook (Canonical)

This is the canonical runbook for the recursive TDD improvement workflow.

## What This Runs

A round executes these phases:

1. `pre_round`
2. `generate`
3. `improve`
4. `regenerate`
5. invariant checks (runtime/artifact)
6. behavioral checks
7. optional benchmark (`deep` mode)
8. `post_round`

All rounds write artifacts under `tests/results/meta-loop/<run-id>/`.

## Required Files

- `scripts/run-recursive-round.sh`
- `scripts/run-recursive-hook.sh`
- `scripts/hash-test-bundle.sh`
- `scripts/pin-test-bundle-hash.sh`
- `tests/datasets/recursive-round/round-manifest.example.json`

## 5-Minute Quickstart (Smoke)

```bash
cp tests/datasets/recursive-round/round-manifest.example.json \
  tests/datasets/recursive-round/round-manifest.local.json

bash scripts/pin-test-bundle-hash.sh \
  tests/datasets/recursive-round/round-manifest.local.json

source scripts/recursive-env.example.sh

bash scripts/run-recursive-round.sh \
  --round-manifest tests/datasets/recursive-round/round-manifest.local.json \
  --mode fast \
  --run-id rr-fast-$(date +%Y%m%d-%H%M%S)

bash scripts/run-recursive-round.sh \
  --round-manifest tests/datasets/recursive-round/round-manifest.local.json \
  --mode deep \
  --smoke-only \
  --run-id rr-deep-smoke-$(date +%Y%m%d-%H%M%S)
```

## Decision-Grade Deep Round

1. Set real benchmark backends:

```bash
export COGWORKS_RECURSIVE_BENCH_CLAUDE_REAL_CMD="<real claude benchmark command that writes metrics.json>"
export COGWORKS_RECURSIVE_BENCH_CODEX_REAL_CMD="<real codex benchmark command that writes metrics.json>"
```

2. Keep benchmark env vars pointed at concrete wrappers:

```bash
export COGWORKS_BENCH_CLAUDE_CMD="bash scripts/recursive-bench-claude.sh '{sources_path}' '{out_dir}'"
export COGWORKS_BENCH_CODEX_CMD="bash scripts/recursive-bench-codex.sh '{sources_path}' '{out_dir}'"
```

3. Run deep mode (no `--smoke-only`):

```bash
bash scripts/run-recursive-round.sh \
  --round-manifest tests/datasets/recursive-round/round-manifest.local.json \
  --mode deep \
  --run-id rr-deep-real-$(date +%Y%m%d-%H%M%S)
```

Decision-grade requirement:

- `signal_mode = real`
- `ranking_eligible = true` (equivalent to `ranking_eligible=true`)

## Hook Commands

`run-recursive-round.sh` reads hook command arrays from the manifest and executes them. The default recommended pattern is to call `scripts/run-recursive-hook.sh` for each phase.

Hook env vars consumed by `scripts/run-recursive-hook.sh`:

- `COGWORKS_RECURSIVE_PRE_ROUND_CMD`
- `COGWORKS_RECURSIVE_GENERATE_CMD`
- `COGWORKS_RECURSIVE_IMPROVE_CMD`
- `COGWORKS_RECURSIVE_REGENERATE_CMD`
- `COGWORKS_RECURSIVE_POST_ROUND_CMD`

If a variable is unset, the phase is skipped with an informational message.

## Round Manifest Contract

Required top-level keys:

- `round_id`
- `test_bundle`
- `selection`

`test_bundle` requires:

- `bundle_paths` (non-empty list)
- `expected_sha256` (recommended; null allowed)

`selection` requires:

- `weights.quality`
- `weights.robustness`
- `weights.cost`
- `max_total_tokens`
- `max_runtime_sec`

## Artifact Contract

Per run outputs:

- `manifest-state.json`
- `round-manifest.json` (snapshot)
- `invariants-clean.json`
- `invariants-negative.json`
- `behavioral-claude/<timestamp>/summary.json`
- `behavioral-codex/<timestamp>/summary.json`
- `round-summary.json`
- `round-report.md`

Deep mode adds references to:

- `tests/results/pipeline-benchmark/<run-id>/benchmark-summary.json`
- `tests/results/pipeline-benchmark/<run-id>/benchmark-report.md`

## Troubleshooting

1. Hash mismatch
- Re-pin: `bash scripts/pin-test-bundle-hash.sh tests/datasets/recursive-round/round-manifest.local.json`

2. Missing benchmark env vars
- Set `COGWORKS_BENCH_CLAUDE_CMD` and `COGWORKS_BENCH_CODEX_CMD`

3. Deep run is non-decision-grade
- Ensure real backend env vars are set and wrappers are writing real metrics.

4. Behavioral failures
- Check `tests/results/meta-loop/<run-id>/behavioral-*/<timestamp>/summary.json`
