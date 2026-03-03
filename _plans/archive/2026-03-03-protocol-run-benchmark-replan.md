# Protocol-Run Benchmark Replan

**Date:** 2026-03-03
**Status:** accepted

## Trigger
Comparator repos were copied in and deep-dive analysis showed both are workflow-style toolkits, not one-shot source-to-skill CLIs with shared benchmark contracts.

## Decisions
1. Replace adapter-assumed one-shot comparator benchmark with protocol-run benchmarking.
2. Use Codex protocol execution for all three pipelines (cogworks, generator-a, generator-b).
3. Use downstream task-output quality as primary signal; activation/cost are secondary guardrails.
4. Pilot scope is fixed to two tasks: `pb-001-api-auth`, `pb-002-k8s-troubleshoot`.
5. Keep old comparator scripts as non-authoritative compatibility path.

## Implementation Scope
- Add protocol manifest and per-pipeline runbooks.
- Add protocol case runner and skill scorer.
- Add protocol benchmark orchestrator.
- Add protocol summarizer (`pilot-summary.json`, `pilot-report.md`, `quality-first-ranking.md`).
- Update testing docs and dataset README with authoritative protocol-run command.
