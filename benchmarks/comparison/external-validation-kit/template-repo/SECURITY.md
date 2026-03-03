# Security and Isolation

## Threat Model

Primary threats:
- cross-run contamination (reading prior outputs)
- pipeline cross-talk
- mutable execution environment drift
- false claims of skill usage without installation

## Controls

- Ephemeral per-case sandbox workspace
- No direct reuse of previous outputs during generation
- Contamination scanner hard-fails on forbidden patterns
- Per-case isolated install environment for `npx skills add`
- Skill usage evidence verifier for `skill_installed` pipelines
- CI-only authoritative runs

## Operator Rules

- Never publish claims from runs with contamination findings.
- Never publish skill-quality claims from `protocol_prompt` mode.
- Never publish skill-quality claims when install/usage evidence gates fail.
- Treat offline/local runs as non-authoritative diagnostics.
- Publish high-trust claims only from real-mode CI runs.
