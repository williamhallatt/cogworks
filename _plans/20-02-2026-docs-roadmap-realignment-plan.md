# 20-02-2026 Docs + Roadmap Realignment Plan (Accepted)

## Scope
- Broad documentation sync across user-facing docs and internal workflow docs.
- Roadmap cleanup to keep only outstanding work.

## Decisions
1. Remove completed roadmap items from `ROADMAP.md` (Codex support and legacy automated testing section).
2. Keep and refine outstanding roadmap areas only.
3. Align docs to current testing baseline (deterministic checks + optional behavioral tests).
4. Remove stale references to `cogworks-test` as an active baseline dependency.
5. Align `.claude/agents/cogworks.md` success reporting and criteria with current validation flow.
6. Leave historical artifacts in `_plans/` and `_sources/` untouched.

## Implementation Targets
- `ROADMAP.md`
- `README.md`
- `RELEASES.md`
- `.claude/agents/cogworks.md`

## Validation
- Grep scan for stale normative references in active docs:
  - `cogworks-test` as active dependency
  - Layer 2/Layer 3 baseline claims
  - `.claude/test-framework` as current framework path
- Confirm documented script/command paths exist.
