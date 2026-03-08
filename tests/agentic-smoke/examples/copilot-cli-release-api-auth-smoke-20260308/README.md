# Copilot Release API Auth Smoke

Preserved live artifact set from the March 8, 2026 release-validation session.

## What This Contains

- `run-root/`: a complete five-stage Copilot live sub-agent run
- `skill-output/`: the generated skill that passed
  `scripts/validate-agentic-run.sh`

## Validation Command

```bash
bash scripts/validate-agentic-run.sh \
  --run-root tests/agentic-smoke/examples/copilot-cli-release-api-auth-smoke-20260308/run-root \
  --skill-path tests/agentic-smoke/examples/copilot-cli-release-api-auth-smoke-20260308/skill-output \
  --expect-surface copilot-cli
```

## Origin

- fixture: `tests/agentic-smoke/fixtures/api-auth-smoke/`
- surface: GitHub Copilot CLI
- execution surface recorded in manifest: `copilot-cli`
- artifact source: `/tmp/cogworks-release-20260308-225034/copilot-v2`

This example is also the default `candidate_a` context source for the
maintained API-auth release benchmark dataset under
`tests/test-data/skill-benchmark-api-auth-release/`.
