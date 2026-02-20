# A/B Pipeline Reproducibility Hardening Plan (Accepted)

## Summary

Fix non-reproducible A/B benchmark instructions by adding real benchmark runner scripts, a single orchestrator command, deterministic offline mode, and aligned documentation for both users and agents.

## Problem

- Docs referenced `scripts/run-claude-benchmark.sh` and `scripts/run-codex-benchmark.sh` that did not exist.
- Users could not execute documented A/B workflow end-to-end without ad hoc setup.
- Reproducibility path for local/CI environments without model/API access was missing.

## Decisions

1. Add configurable benchmark wrappers:
   - `scripts/run-claude-benchmark.sh`
   - `scripts/run-codex-benchmark.sh`
2. Add single orchestrator entrypoint:
   - `scripts/run-pipeline-benchmark.sh`
3. Default reproducibility mode:
   - `--mode offline` with deterministic fixture metrics.
4. Real-mode contract:
   - `COGWORKS_BENCH_CLAUDE_CMD`
   - `COGWORKS_BENCH_CODEX_CMD`
5. Standardized output artifacts:
   - `benchmark-summary.json`
   - `benchmark-report.md`
6. Keep raw framework CLI as advanced/manual path.

## Implementation Scope

- Create and validate benchmark wrapper scripts.
- Add orchestrator with scaffold/run/summarize flow.
- Update smoke test to use orchestrator and assert artifact integrity.
- Update docs in:
  - `.claude/test-framework/README.md`
  - `TESTING.md`
  - `tests/datasets/pipeline-benchmark/README.md`

## Acceptance Criteria

- `bash scripts/run-pipeline-benchmark.sh --mode offline ...` succeeds end-to-end.
- Smoke test verifies both pipelines appear in summary and a winner is selected.
- Real mode fails fast with actionable env var errors when commands are missing.
- Docs are consistent and executable as written.

## Done vs Outstanding (tracking)

- Done:
  - Runner wrappers, orchestrator, smoke test path, and docs updates.
- Outstanding:
  - None intended beyond verification runs and review.
