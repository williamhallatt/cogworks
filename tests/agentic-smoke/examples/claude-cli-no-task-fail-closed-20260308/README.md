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
- that historical diagnosis is preserved for auditability, but the current repo
  now does provide executable project-scoped Claude agents via `.claude/agents/`
  rendered from `skills/cogworks/role-profiles.json`

## Validation Command

```bash
bash tests/validate-fail-closed-run.sh \
  --report-path tests/agentic-smoke/examples/claude-cli-no-task-fail-closed-20260308/blocking-report.md \
  --skill-path /tmp/cogworks-release-20260308-225034/claude/skill-output/api-auth-smoke-claude \
  --expect-pattern "BLOCKED - Runtime Misconfiguration"
```

So the preserved artifact remains valid as fail-closed evidence, but not as
proof that Claude currently lacks delegated-agent support.
