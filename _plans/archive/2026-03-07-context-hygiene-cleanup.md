# Context Hygiene Cleanup Plan

## Status

Accepted and completed on 2026-03-07.

## Summary

Reduce the highest retrieval-pollution risks identified by the repository-wide context audit without deleting useful history, fixtures, or run evidence.

## Decisions

- Enforce the default-load allowlist in `AGENTS.md`.
- Reconcile `TESTING.md` with the current `evals/` benchmark surface.
- Mark non-canonical high-risk directories in place with warning files rather than rely on one central policy file.
- Default future smoke and benchmark output to disposable paths outside the repository.
- Move stale session-handoff material out of active `_plans/`.

## Scope

- `.gitignore`
- `AGENTS.md`
- `TESTING.md`
- `tests/agentic-smoke/README.md`
- `.github/agents/squad.agent.md`
- `.squad/**`
- `_sources/README.md`
- `.cogworks-runs/README.md`
- `tmp-agentic-output/README.md`
- `tests/test-data/README.md`
- `tests/datasets/golden-samples/README.md`
- `docs/testing-workflow-guide.md`
- `docs/cogworks-agent-risk-analysis.md`
- `_plans/2026-03-06-agentic-v2-next-session.md`

## Verification

- Non-canonical surfaces now self-identify as non-default context.
- `TESTING.md` no longer claims the benchmark surface is absent.
- Live smoke docs now prefer disposable output roots outside the repository.
