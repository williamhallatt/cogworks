# Claude Fail-Closed Example

Preserved fail-closed evidence from the March 8, 2026 release-validation
session.

## What This Contains

- `blocking-report.md`: the live Claude Code CLI blocking report produced
  during the March 8, 2026 release-validation session

## Why It Matters

This is the canonical fail-closed artifact from the session. Later
investigation showed the report's diagnosis was not fully correct:

- the local `claude -p` surface did expose the delegated-agent primitive
- the real repo-side blocker was missing executable provisioning for the four
  canonical `cogworks` Claude specialist roles
- the repo currently has abstract role profiles in
  `skills/cogworks/role-profiles.json`, but no `.claude/agents/` files and no
  `claude --agents ...` bridge that injects equivalent custom agents

## Validation Command

```bash
bash tests/validate-fail-closed-run.sh \
  --report-path tests/agentic-smoke/examples/claude-cli-no-task-fail-closed-20260308/blocking-report.md
```

So the preserved artifact remains valid as fail-closed evidence, but not as
proof that Claude lacked delegated-agent support.
