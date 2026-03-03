# Comparator Benchmark Harness Plan

**Date:** 2026-03-03
**Status:** accepted

## Objective

Implement a decision-grade benchmark harness to compare `cogworks` against two external skill generators (`generator-a`, `generator-b`) under controlled fairness settings:

- Same model family
- Same token/runtime budgets
- Same dataset manifest
- Quality-first interpretation

## Decisions

1. Use two external generators in first pass.
2. Enforce fairness with same model family and same budget across pipelines.
3. Optimize winner interpretation for application quality first; cost and activation are guardrails.
4. Comparator code is sourced as local copies inside repo (`comparators/`).
5. If comparator metrics are partial/unknown, use adapter normalization to derive required `metrics.json`.
6. Deliver scaffold + first run capability in this implementation cycle.

## Implementation Scope

- Add comparator config file with pipeline command templates and budgets.
- Add comparator adapters:
  - `scripts/run-generator-a.sh`
  - `scripts/run-generator-b.sh`
  - `scripts/run-comparator-benchmark.sh`
- Add orchestrator entrypoint:
  - `scripts/test-generator-comparison.sh`
- Add quality-first report renderer:
  - `scripts/render-quality-first-ranking.py`
- Update testing documentation with comparator benchmark workflow.

## Required Comparator Contract

- Local comparator code at:
  - `comparators/generator-a/`
  - `comparators/generator-b/`
- Runners must be invocable through wrapper scripts.
- Final pipeline output must include benchmark-compatible `metrics.json` keys:
  - `layer1_pass`
  - `quality_score`
  - `activation_f1`
  - `false_positive_rate`
  - `negative_control_ratio`
  - `perturbation_success`
  - `runtime_sec`
  - `usage.total_tokens`
  - `usage.context_tokens`
  - `failed`

