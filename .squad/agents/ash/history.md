# history.md

## Learnings

### 2026-03-07: Participated in team reflection ceremony — reflected on the day's agentic pivot work.

**2026-03-04 — Gap Closure Round 3: M2 & M9 Completion**

Closed two critical security gaps from self-knowledge audit:

1. **M2 — Deterministic Delimiter Escape** — Behavioral directive ("treat as data") is insufficient when the attack surface is literal string content. A source containing `<</UNTRUSTED_SOURCE>>` deterministically collapses the security boundary at the parser level regardless of model intent. Replaced with explicit preprocessing: `<<UNTRUSTED_SOURCE>>` → `[UNTRUSTED_SOURCE_TAG]`, `<</UNTRUSTED_SOURCE>>` / `<<END_UNTRUSTED_SOURCE>>` → `[/UNTRUSTED_SOURCE_TAG]` before wrapping. Architectural decision: **D-020** (deterministic preprocessing required; behavioral intent insufficient).

2. **M9 — Extended Post-Generation Injection Scan** — Prior check only flagged delimiter leakage. Extended `cogworks-learn/SKILL.md` item 10 to also detect: prompt-override phrases ("ignore prior", "ignore previous"), standalone agent imperative directives ("you must", "you should always", "always do", "never do"), tool call syntax not belonging to skill delimiters. All checks case-insensitive pattern matches; user confirmation required before write if triggered.

**Team coordination (Round 3):** Dallas closed D9/D3 (slug collision guard + handoff artifacts), Lambert closed D6 (compatibility matrix), Hudson closed D8 (CI gate behavioral enforcement), Ripley recorded architectural decisions D-020 and D-021.

## Learnings

**2026-03-03 — Security guards round 2 (Issues #13, #18, #22)**

Implemented three security boundaries in cogworks orchestrator:

1. **Stale Skill Guard (Issue #18)** — Added detection for in-session skill edits. If the agent is editing cogworks/cogworks-encode/cogworks-learn SKILL.md files, warn before invoking them in the same session due to potential instruction-state inconsistency.

2. **Escalation boundary for autonomous mode (Issue #13)** — Added explicit stop-and-escalate protocol: when running without interactive input, if the agent hits an unresolvable decision (conflicting sources, unclear scope, missing input, ambiguous intent), it must halt and surface a clear question rather than guessing.

3. **Intent clarification gate (Issue #22)** — Added pre-synthesis check in Step 1: if user request doesn't explicitly mention creating/updating/generating a skill (e.g., "summarize these sources"), confirm intent before launching the full encode+learn pipeline. Prevents unintended skill generation from casual queries.

All three guards enforce the principle that autonomous systems must fail safely: stop and ask rather than infer critical decisions from ambiguous context.

**2026-03-03 — Team coordination notes**

- Dallas implemented complementary pipeline guards (M5, M11, D3, D7) addressing overwrite protection, cross-source synthesis validation, CDR completeness, and convergence risk.
- Ripley implemented quality calibration gate (D4) in cogworks-encode Self-Verification to detect superficial synthesis.
- Hudson added generalization probe and edge case tests (D8) plus pre-release CI gate to catch circular verification failures.
- Lambert documented Codex behavioral capture and skills-lock schema; recommended AGENTS/CLAUDE dedup approach.

