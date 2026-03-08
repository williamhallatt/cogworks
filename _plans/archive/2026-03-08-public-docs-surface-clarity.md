# Public Docs Refresh For Current Surface Contract

## Summary

Refresh all public/user-facing documentation so it teaches one coherent product
story:

- `cogworks` is the single normal entry point
- the generated skill is the product artifact
- the trust-first sub-agent build path is internal maintainer machinery
- Codex remains relevant only as a portable generated-skill target and benchmark
  surface, not as a supported trust-first build surface

This refresh should prioritize fast comprehension, remove mixed signals, and
make support boundaries explicit at first touch rather than only in maintainer
docs.

## Key Changes

### Product positioning and support matrix

Update the public docs to present a single, repeated support policy in
consistent language:

- supported normal product path: invoke `cogworks` to generate a skill
- supported trust-first sub-agent build surfaces: Claude Code and GitHub
  Copilot CLI only, with Copilot described honestly as evidence-backed rather
  than blanket parity
- Codex position: generated skills are portable there, but the internal
  trust-first sub-agent build flow is not supported on Codex in the current
  phase
- do not imply parity: remove wording or layout that places Codex beside
  supported build surfaces without a nearby caveat

Apply this consistently in:

- `README.md`
- `INSTALL.md`
- `skills/cogworks/README.md`
- `TESTING.md`
- `CONTRIBUTIONS.md`

### Public wording standard

Use one canonical distinction everywhere:

- generated skills are portable across agents that support skills
- the trust-first internal build flow is currently supported only on Claude
  Code and GitHub Copilot CLI
- Codex is not a supported surface for the current trust-first build flow

Avoid weaker variants such as “support is deferred for now” without context, or
examples that list Codex next to supported build surfaces without a caveat.

## Test Plan

- search the refreshed docs for `codex`, `supported`, `portable`, `sub-agent`,
  and `agentic` to confirm there are no contradictory claims
- read each public doc top-to-bottom as a first-time user and verify the
  support boundary is clear before any Codex-specific example or reference
- keep maintainer-only Codex references where they remain accurate for trigger
  smoke or benchmark coverage
- run `bash scripts/test-agentic-contract.sh` after implementation

## Assumptions

- public/user-facing documentation includes `README.md`, `INSTALL.md`,
  `skills/cogworks/README.md`, `TESTING.md`, and contributor-facing guidance in
  `CONTRIBUTIONS.md`
- Codex remains in public docs only as a portable generated-skill target, not
  as a supported trust-first build surface
- no product behavior changes are planned; this is a clarity and support-boundary
  correction across docs only
