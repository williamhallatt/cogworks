---
last_updated: 2026-03-13
---

# Team Wisdom

Reusable patterns and heuristics learned through work. NOT transcripts — each entry is a distilled, actionable insight.

## Patterns

**Pattern:** Trust-first, fail-closed. Weak or contradictory sources → blocking trust report, never a best-effort skill. The pipeline produces exactly one of: validated skill OR blocking report. Never both, never neither.  
**Context:** Core contract for all cogworks output decisions. Applies to every pipeline run.

**Pattern:** Single user-facing entry point. `cogworks` is the only invocation surface; `cogworks-encode` and `cogworks-learn` are expert doctrine, not separate user commands. Sub-agents are internal.  
**Context:** Routing, documentation, and onboarding. Agents should never tell users to invoke encode or learn directly.

**Pattern:** Canonical singles — one source of truth per concern. `role-profiles.json` owns specialist bindings. `reference.md` owns doctrine. `_plans/DECISIONS.md` owns settled decisions. Don't duplicate; reference.  
**Context:** Preventing architectural drift across files. When in doubt, check the canonical source.

**Pattern:** Staged context discipline. Each pipeline stage loads only the artifacts it needs — no preloading everything. Agents follow the same retrieval contract (AGENTS.md §Retrieval Contract).  
**Context:** Context window efficiency. Applies to both pipeline stages and agent session startup.

**Pattern:** No circular reasoning. Cross-model judge (generator ≠ judge family per D-036). Deterministic checks break self-verification loops.  
**Context:** All quality evaluation — behavioral testing, benchmarks, and skill review.

**Pattern:** Expert subtraction. True expertise = removal, not addition. Show only what matters. Novices demonstrate knowledge; experts demonstrate understanding.  
**Context:** Skill generation, documentation, and code review. The deep dive confirmed this is the repo's design philosophy at every level.

**Pattern:** Plans lifecycle is atomic: Save to `_plans/` → Extract decision to `DECISIONS.md` → Delete plan file. Deleting without extracting is not a close. Git history is the archive.  
**Context:** All plan management. Three steps, always together.

**Pattern:** Live-edit hazard. Editing `skills/cogworks*/SKILL.md` immediately changes the instructions for every running session reading it via `.claude/skills/` or `.agents/skills/` symlinks.  
**Context:** Any skill file editing. Note it at session start; don't invoke the skill you're editing.

**Pattern:** Plugin-first install. `copilot plugin install` / `claude plugin marketplace` is the recommended path. `npx skills add` is the manual fallback, not the primary.  
**Context:** Installation guidance and documentation. Plugin manifests (`plugin.json`, `.claude-plugin/`) are the canonical install surfaces.
