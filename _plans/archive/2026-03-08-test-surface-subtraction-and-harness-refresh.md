# Test Surface Subtraction And Harness Refresh

## Summary

Align the executable test surface with live repository policy by removing dead
contracts and updating the maintained harnesses.

## Decisions

- Sync `TESTING.md` to the canonical recursive runbook and required helper
  scripts.
- Retire `.claude/agents/**` as an active Claude binding contract and use
  canonical role-profile bindings instead.
- Retire the dead `benchmarks/comparison/**` pipeline benchmark surface.
- Keep recursive rounds maintained only in `--mode fast` and re-pin the local
  frozen-bundle hash.
- Keep trigger smoke, but make execution and activation parsing runner-specific
  for current Claude and Codex CLIs.
- Delete the contradictory `tests/ci-gate-check.sh` script.

## Completed

- Runtime contract and validators updated to remove file-backed Claude bindings.
- Recursive docs and script updated to the maintained fast-mode surface.
- Dead pipeline-benchmark and CI-gate entrypoints removed.
- Trigger smoke harness updated for current runner behavior.

## Outstanding

- None in this cleanup slice; any future decision-grade recursive benchmark or
  behavioral-eval replacement should be introduced as a new surface rather than
  restoring the retired paths here.
