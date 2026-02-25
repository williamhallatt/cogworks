audited_through: 2026-02-25

# Decision Log

This file is the agent context surface for `_plans/`. Load this for settled decisions.
Check `_plans/*.md` (root only) for active in-flight plans. Treat `_plans/archive/` as
human-readable history only.

---

## [D-001] Layered testing framework for cogworks skills
- **Date**: 2026-02-14 | **Source**: 14-02-2026-eval-based-skill-evaluation-impl-summary.md | **Status**: implemented
- Adopted a three-layer testing framework (deterministic → LLM-as-judge → human review) for validating generated skills, with an 85% weighted pass threshold.
- Layered approach was chosen to minimize cost: structural failures caught by cheap bash checks before expensive LLM evaluation.
- The `cogworks-test` skill and supporting infrastructure under `tests/` are the current implementation; the `cogworks-test` skill is not an active baseline dependency in the default workflow.

## [D-002] Agent-specific invocation syntax in all user-facing docs
- **Date**: 2026-02-24 | **Source**: 2026-02-24-agent-specific-invocation-syntax-docs.md | **Status**: implemented
- All user-facing invocation examples now show both Claude Code (`/`) and Codex CLI (`$`) prefixes; section headings used as identifiers were left unchanged.
- Different agents use different slash-command prefixes; documenting both prevents silent failures for Codex CLI users.
- Files affected: `README.md`, `skills/cogworks/README.md`, `INSTALL.md`, `skills/cogworks-learn/reference.md`.

## [D-003] Docs and roadmap realignment
- **Date**: 2026-02-20 | **Source**: 20-02-2026-docs-roadmap-realignment-plan.md | **Status**: implemented
- Removed completed roadmap items; aligned docs to deterministic-checks-first baseline; removed stale `cogworks-test` and Layer 2/3 baseline claims from active docs.
- Roadmap should only carry outstanding work; completed items create false authority for agents reading the file.
- Constraints still in force: `_plans/` and `_sources/` historical artifacts are left untouched.

## [D-004] Decision log + plan archive structure (this file)
- **Date**: 2026-02-25 | **Source**: (plan accepted 2026-02-25, not yet filed in archive) | **Status**: implemented
- `_plans/DECISIONS.md` is the agent context surface; completed plans move to `_plans/archive/`; active plans stay at `_plans/` root. The close ritual is atomic: extract decision → move file → update `audited_through`.
- An append-only `_plans/` with no closure mechanism caused completed plans to sit alongside active ones, giving fresh agent sessions false authority over stale implementation steps.
- Any plan with a date later than `audited_through` is implicitly unreviewed; agents must not treat it as settled.
