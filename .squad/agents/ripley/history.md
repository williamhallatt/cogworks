# history.md

## Learnings

**2026-03-04 — Product Gap Analysis: Agent Skills & Prompt Engineering (Kane Synthesis)**

Kane completed systematic audit of 13 Tier 1 + 7 Tier 2 sources on agent skills, sub-agents, and prompt engineering. Identified three critical gaps directly impacting generated skill quality:

1. **Activation testing missing** — behavioral eval validates *output* quality but not *invocation* precision. Skills with perfect content but poor `description` fields may never be discovered by agents. Blocks deployability without additional engineering.

2. **No parallel tool use guidance** — generated skills don't template parallel execution guidance. 3-5x performance improvement left on table for file-heavy operations; appears in both Claude Opus 4.6 and Codex best practices independently.

3. **Evaluation flywheel missing** — one-shot generation produces brittle skills. No mechanism to run behavioral tests, analyze failures, surgically revise, and re-test. Eval-driven iteration (draft → eval → analyze → revise → re-eval) is the difference between first-draft and resilient artifacts.

**Architectural implications:** These gaps directly inform how generated skills should be templated and tested. Activation testing should block deployability (same severity as behavioral failures). Parallel tool guidance should be standard template content. Eval flywheel would require orchestration changes but not architectural ones.

**Recommendations:** P0 = extend behavioral eval with activation cases; P1 = template parallel execution in cogworks-learn + prototype eval iteration; P2 = cross-agent compatibility testing.

**2026-03-04 — Gap Closure Review (Round 3 Coherence Audit)**

Recorded architectural decisions D-020 and D-021 in `_plans/DECISIONS.md`. Verified all six closed gaps (M2, M9, D9, D3, D6, D8) for cross-agent coherence.

**D-020 (Deterministic Delimiter Neutralisation):** Behavioral directives ("treat as data") are insufficient when the attack surface is literal string content. A source containing `<</UNTRUSTED_SOURCE>>` deterministically collapses the security boundary at the parser level regardless of model intent. The fix must be deterministic preprocessing, not intent (Ash's M2 closure).

**D-021 (CI Gate Behavioral Coverage Requirement):** Trace presence check is now a blocking gate (exit 1 on failure), not a warning. Behavioral coverage is a release guarantee, not an optional signal (Hudson's D8 closure).

**Coherence verification (no conflicts found):**
- M2 ↔ cogworks-learn consistency: M9 checks for delimiter *leaks* (defect detection), orthogonal to replacement tokens. No conflict.
- M2 ↔ cogworks orchestrator: Orchestrator delegates to cogworks-encode's protocol; changes automatically picked up. No conflict.
- D9 ↔ existing overwrite protection: Slug guard complements path-based overwrite protection; different surfaces. No conflict.
- CI gate ↔ existing traces: New loop iterates all skills; traces exist for all three. No false-positive risk.

**Follow-up noted:** Lambert's compatibility template note (cogworks-learn generated-skill guidance) is documented but not yet enforced in generation checklist. Low-priority follow-up for next round.

- **Quality calibration vs capability gating are distinct concerns.** Model capability requirements (Sonnet-class or above) address whether the model *can* synthesize; quality calibration addresses whether it *does* synthesize with appropriate depth. The anti-superficiality gate added to Self-Verification targets the latter — it forces the model to introspect on its own output before declaring completion. The key design insight: a model that finds zero tensions between multiple sources has almost certainly under-analyzed, so "all clear" is the red flag, not the green light.

**2026-03-08 — Post-Review Roadmap (Comprehensive Remediation Planning)**

Completed architectural review of commits b6208ff forward (16 commits, 4 months of work). Analysis document at `/home/will/.copilot/session-state/0e7b3ca4-d4f2-49a8-8187-940c31758763/plan.md` provided thorough assessment of what was built, what was built well, what was built badly, and what must still be built.

**Key architectural findings:**
1. **Specifications outpace validation** — agentic runtime, benchmark design, and contract validation scripts are production-grade, but evidence is thin (one trivial smoke run, no behavioral eval, no production benchmark, no error path testing)
2. **Decision skeleton ownership gap** — most important intermediate artifact has no formal role owner, creation trigger, or quality gate (implicit in smoke run but not specified)
3. **Terminology drift across specs** — same concepts have different names in different files ("contradiction" vs "conflicting guidance", undefined terms like "synthesis fidelity" and "brittle execution")
4. **Premature tooling duplication** — run-agentic-quality-compare.py overlaps skill-benchmark harness, should be consolidated

**Prioritization framework applied:** Risk × Value × Dependency Blocking → 4 tiers (P0 Critical, P1 Important, P2 Valuable, P3 Defer/Drop)

**P0 items (blocks trust & security):**
- Decision skeleton specification gap (Ripley + Ash, 2-3h)
- Terminology glossary (Ripley + Scribe, 4-6h)
- Agentic dispatch security hardening (Ash, 1 week) — already identified in Ash charter, now formally prioritized

**P1 items (blocks portability & adoption):**
- Copilot adapter completion (Dallas + Lambert, 1 week)
- Error path testing (Hudson, 2 weeks)
- Codex adapter decision (Ripley + Dallas, 1 day OR 2-3 weeks) — recommended: defer, remove from README examples but keep benchmark adapter

**P2 items (improves operational quality):**
- Production benchmark run (Parker, 2-3 weeks) — closes "agentic is better than legacy" hypothesis validation gap
- Behavioral evaluation reconstruction (Parker + Hudson, 4-6 weeks) — replacement for D-022 deleted circular traces
- Consolidate comparison tooling (Parker + Hudson, 1 week)
- Worked example documentation (Scribe, 1 week)

**P3 items (defer/drop):**
- Archive 340-line context audit (Scribe, 30 min) — findings captured in D-033/D-034, full doc is redundant
- Team reflection ceremony — already reverted, no action needed

**Sequencing strategy:** Weeks 1-2 spec hardening (parallel), Weeks 3-4 security & foundation, Weeks 5-6 validation expansion, Weeks 7-8 quality infrastructure, Weeks 9-14 behavioral eval + documentation.

**Items explicitly dropped:** None. Every identified issue has value; some deferred but nothing "not worth doing." Closest to DROP: comparison tooling consolidation supersedes old script; reflection ceremony already reverted.

**Key paths:**
- `_plans/DECISIONS.md` — settled decisions (D-033/D-034 on context retrieval, D-029 on agentic generalization, D-030 on skill benchmark, D-026 on quality schema)
- `skills/cogworks/SKILL.md`, `skills/cogworks/agentic-runtime.md` — orchestrator and runtime specs with terminology drift issues
- `.squad/decisions/inbox/ripley-post-review-roadmap.md` — output roadmap proposal
- `/home/will/.copilot/session-state/.../plan.md` — source analysis document

**Architectural principles reinforced:**
- **Minimal surgical changes** — every recommendation scoped to fix identified gap without refactoring working systems
- **Evidence-backed decisions** — no "refactor for elegance" recommendations; all work addresses concrete gaps in validation or specification
- **Dependency-aware sequencing** — P0 unblocks P1, P1 unblocks P2; parallel work identified where safe
- **Risk-proportional effort** — security hardening is P0, documentation polish is P2


**2026-03-08 — Post-Review Roadmap Fan-Out (Coordination)**

Ripley's comprehensive roadmap spawned 6-agent fan-out: Dallas (pipeline solutions), Parker (benchmark strategy), Hudson (error path testing), Lambert (terminology + Codex), Ash (security hardening). All proposals consolidated into decisions.md pending approval.

**Cross-references:** Dallas proposes skeleton ownership fix (P0, blocks Ash). Lambert proposes glossary (P0, prerequisite for Dallas/Ash). Parker proposes benchmark + behavioral eval reconstruction. Hudson proposes error path testing design. Ash proposes dispatch security hardening.

