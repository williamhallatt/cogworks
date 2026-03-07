# history.md

## Learnings

### 2026-03-07: Participated in team reflection ceremony — reflected on the day's agentic pivot work.

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

**Team coordination (Round 3):** All five agents completed parallel work on 6 gaps with zero conflicts. Orchestration, session log, decision merge, and history updates all captured for commit.

- **Learnings**

- **Quality calibration vs capability gating are distinct concerns.** Model capability requirements (Sonnet-class or above) address whether the model *can* synthesize; quality calibration addresses whether it *does* synthesize with appropriate depth. The anti-superficiality gate added to Self-Verification targets the latter — it forces the model to introspect on its own output before declaring completion. The key design insight: a model that finds zero tensions between multiple sources has almost certainly under-analyzed, so "all clear" is the red flag, not the green light.

**2026-03-03 — Team coordination notes**

- Dallas implemented pipeline guards (M5, M11, D3, D7) addressing overwrite protection, cross-source synthesis validation, CDR completeness, and convergence risk.
- Ash implemented security guards (D2, D1, D1) addressing escalation boundaries, stale skill detection, and intent clarification.
- Hudson added generalization probe and edge case tests (D8) plus pre-release CI gate to catch circular verification failures.
- Lambert documented Codex behavioral capture and skills-lock schema; recommended AGENTS/CLAUDE dedup approach.

### 2026-03-04: Context-Impact Remediation
- Added context-budget warning bullet to AGENTS.md Auto-Loading hazard section
- Improves awareness of squad.agent.md circular edit hazard during skill development
- Sharpens developer friction point for F4/F5 risk mitigation

### 2026-03-04: Gap Closure Review (Self-Knowledge Audit)
- Recorded D-020 (deterministic delimiter neutralisation) and D-021 (CI gate fails on missing traces) in `_plans/DECISIONS.md`.
- Verified all four agents' changes (Ash/M2, Dallas/D9, Lambert/D6, Hudson/CI gate) are coherent — no cross-agent conflicts found.
- Key insight: behavioral-only security boundaries are insufficient when the attack surface is literal string content. Deterministic preprocessing is the correct layer for delimiter integrity.
- Follow-up noted: Lambert's compatibility template note is documented but not yet enforced in cogworks-learn's generation checklist.

