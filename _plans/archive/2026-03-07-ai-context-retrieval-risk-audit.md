# AI Context Retrieval Risk Audit Plan

## Status

Accepted and completed on 2026-03-07.

## Summary

Audit the full repository, including ignored generated artifacts physically present in the workspace, and identify anything that increases the risk of ineffective context retrieval or context pollution for AI agents.

## Decisions

- Scan the repository by directory class rather than produce a raw per-file dump.
- Distinguish canonical load surfaces from accidental retrieval surfaces.
- Rank findings by retrieval-risk mechanism:
  - auto-load hazards
  - instruction conflicts
  - historical-memory pollution
  - research-corpus pollution
  - generated-artifact contamination
  - fixture/example ambiguity
  - directory-shape retrieval traps
- Preserve a concrete audit artifact so future cleanup work can target named files and directories.

## Scope

- `AGENTS.md`
- `CLAUDE.md`
- `README.md`
- `TESTING.md`
- `CONTRIBUTIONS.md`
- `INSTALL.md`
- `_plans/**`
- `.github/agents/**`
- `skills/**`
- `.claude/agents/**`
- `.squad/**`
- `_sources/**`
- `docs/**`
- `evals/**`
- `.cogworks-runs/**`
- `tmp-agentic-output/**`
- `tests/**`

## Deliverables

- `docs/ai-context-retrieval-risk-audit-2026-03-07.md`
- `_plans/DECISIONS.md` updated with the default retrieval policy for canonical vs non-canonical surfaces

## Verification

- Repository inventory completed across all non-`.git` files present in the workspace
- High-risk files and directories cited concretely in the audit report
