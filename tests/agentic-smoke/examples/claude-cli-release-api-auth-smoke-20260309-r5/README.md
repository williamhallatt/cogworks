# Claude Release API Auth Smoke

Preserved live artifact set from the March 9, 2026 provenance-hardening
release-validation session.

## What This Contains

- `run-root/`: a complete five-stage Claude live sub-agent run
- `skill-output/`: the generated skill that passed
  `scripts/validate-agentic-run.sh`

## Validation Command

```bash
bash scripts/validate-agentic-run.sh \
  --run-root tests/agentic-smoke/examples/claude-cli-release-api-auth-smoke-20260309-r5/run-root \
  --skill-path tests/agentic-smoke/examples/claude-cli-release-api-auth-smoke-20260309-r5/skill-output \
  --expect-surface claude-cli
```

## Origin

- fixture: `tests/agentic-smoke/fixtures/api-auth-smoke/`
- surface: Claude Code CLI
- execution surface recorded in manifest: `claude-cli`
- artifact source: live maintained release-validation rerun after hardening the
  Claude dispatch manifest so it records canonical per-stage `tool_scope`
  values from `skills/cogworks/role-profiles.json`

This is the canonical preserved Claude happy-path evidence for the current
release-grade validation bar.

It is reference evidence and a debugging aid. Fresh release validation should
prefer a newly generated Claude artifact set when the release candidate has
changed.
