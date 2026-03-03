# 2026-03-03 Comparison Benchmark Isolation + Hard Suite Expansion

## Context
Comparison benchmarking artifacts had grown across `scripts/`, `tests/datasets/`, `docs/`, and `comparators/`, which increased coupling with non-benchmark cogworks workflows.

## Accepted Plan
1. Move all comparison testing assets into `benchmarks/comparison/`.
2. Perform hard cutover (no backward-compatible path aliases).
3. Update all script defaults, command templates, and docs to the new location.
4. Expand benchmark dataset with six additional hard tasks (`pb-005` through `pb-010`).
5. Add `protocol-hard-v2.json` for expanded protocol evaluation.

## Implementation Notes
- Benchmark scripts now live in `benchmarks/comparison/scripts/`.
- Dataset manifest and protocol manifests now live in `benchmarks/comparison/datasets/pipeline-benchmark/`.
- Comparator repos moved under `benchmarks/comparison/comparators/`.
- Runbooks moved to `benchmarks/comparison/docs/protocols/`.

## Status
Implemented and archived on 2026-03-03.
