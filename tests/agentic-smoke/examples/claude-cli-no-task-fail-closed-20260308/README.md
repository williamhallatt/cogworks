# Claude No-Task Fail-Closed Example

Preserved fail-closed evidence from the March 8, 2026 release-validation
session.

## What This Contains

- `blocking-report.md`: the live Claude Code CLI blocking report produced when
  the surface could not provide the delegated-task path required by the current
  `cogworks` Claude adapter contract

## Why It Matters

This is the canonical evidence from the session that the local Claude CLI
surface failed closed instead of inventing an equivalent-looking happy path.

## Validation Command

```bash
bash tests/validate-fail-closed-run.sh \
  --report-path tests/agentic-smoke/examples/claude-cli-no-task-fail-closed-20260308/blocking-report.md
```

The live capability probe during the same session returned `NO-TASK`, so a
truthful Claude happy-path sub-agent release artifact could not be produced on
that machine state.
