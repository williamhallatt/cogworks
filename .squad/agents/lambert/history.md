# history.md

## Learnings

### 2026-03-04: Round 3 Completion — D6 Cross-Agent Compatibility Closure

Completed full D6 risk mitigation. Created comprehensive compatibility matrix covering invocation syntax, `$ARGUMENTS` interpolation, and `allowed-tools` enforcement across Claude Code, GitHub Copilot, Codex/GPT-5, and generic MCP agents.

**Deliverables:**
1. **docs/cross-agent-compatibility.md** (~360 lines, 7 sections): Overview, invocation syntax matrix, `$ARGUMENTS` analysis, `allowed-tools` matrix, known gaps with testing roadmap, user guidance, skill author recommendations. Honest labeling (✅ Confirmed | 🟡 Partial | ❓ Untested | ❌ Known broken).
2. **cogworks-learn/SKILL.md Compatibility (L2):** Generated-skill template guidance. When skills use `$ARGUMENTS`, authors must add Compatibility section to SKILL.md with fallback note for non-interpolating agents.
3. **User-facing guidance:** "Compatibility Note for Generated Skills" explains portability, limitations, testing approach.

**Key findings:**
- cogworks, cogworks-encode, cogworks-learn do NOT use `$ARGUMENTS` internally; documentation is for skill authors.
- Copilot `$ARGUMENTS` support marked ❓ (undefined per risk analysis); highest-priority live testing candidate.
- Copilot `allowed-tools` enforcement also undefined; documented impact and author recommendations.
- 5 gaps identified with effort estimates for post-Round-3 testing (Copilot `$ARGUMENTS`, Copilot `allowed-tools`, MCP integration, Cursor auto-load, argument fallback).

**Risk remapping:** D6 partially closed (documentation complete; live testing roadmap documented for future rounds).

**Team coordination (Round 3):** Ash closed M2/M9 (security), Dallas closed D9/D3 (pipeline), Hudson closed D8 (CI gate), Ripley recorded architectural decisions D-020 and D-021.

### Round 3: Cross-Agent Compatibility Audit (2026-03-11)

**D6 Risk Closure (Cross-Agent Compatibility)**
- Created `docs/cross-agent-compatibility.md` with 7 sections: Overview, Invocation Syntax by Agent (5 agents + MCP), $ARGUMENTS Interpolation (per-skill + agent matrix), allowed-tools Compatibility, Known Gaps (5 untested items with effort estimates), user-facing Compatibility Note, and skill-author recommendations.
- **Key findings:**
  - cogworks, cogworks-encode, cogworks-learn do NOT use `$ARGUMENTS` internally; documentation is for skill authors writing generated skills
  - Copilot `$ARGUMENTS` support marked ❓ (undefined per risk analysis); flagged as highest-priority unknown
  - Copilot `allowed-tools` enforcement also undefined; documented impact and recommendation for authors
- **Generated-skill template update:** Added Compatibility (L2) guidance to cogworks-learn/SKILL.md instructing authors to include Compatibility section in generated SKILL.md when skills use `$ARGUMENTS`, with fallback guidance for non-interpolating agents
- **User guidance:** "Compatibility Note for Generated Skills" section explains portability, limitations, and testing approach for multi-agent skill deployment
- **Honest unknowns:** Copilot support marked as undefined (not guessed); 5 gaps identified with testing roadmap
- **Risk remapping:** D6 partially closed (documentation complete, live testing remains); Copilot testing prioritized post-Round-3

### Round 2: Compatibility Documentation & Schema (2026-03-10)

**Core Skills Hash Tracking (Issue #12)**
- Proposed `core_skills_hash` field in `skills-lock.json` to detect unintentional drift of cogworks core
- Hash computed from combined SKILL.md of three core skills (lexicographic sort)
- Agent integration: warn on mismatch but don't block; support override flag
- Migration path: compute + jq + commit pattern for existing lock files
- Future-proofed schema versioning model defined

**Codex Behavioral Capture Pipeline (Issue #10)**
- Codex lacks auto-loading (no `.claude/skills/` symlink equivalence); skills must be explicitly injected
- Behavioral traces are inherently non-deterministic; evaluator uses structural/semantic checks, not byte-for-byte
- Capture format: JSON in `tests/behavioral/{skill}/traces/{case_id}.json` + JSONL test registry
- Key fields: `skill_slug`, `case_id`, `activation_source`, `model`, `trace_source`, quality metadata
- Non-determinism handling: BLEU/ROUGE scoring + manual quality gates in shared evaluator

**AGENTS.md vs CLAUDE.md Deduplication (Issue #19)**
- Files are currently byte-for-byte identical (verified via diff)
- No Claude-specific sections exist in AGENTS.md that would warrant divergence
- Auto-loading & live-edit hazard already documented in both
- Recommendation: CLAUDE.md → minimal pointer to AGENTS.md with optional 2-line preamble
- Expert subtraction principle applied: remove duplication, retain discoverability

**2026-03-03 — Team coordination notes**

- Dallas implemented complementary pipeline guards (M5, M11, D3, D7) addressing overwrite protection, cross-source synthesis validation, CDR completeness, and convergence risk.
- Ash implemented security guards (D2, D1, D1) addressing escalation boundaries, stale skill detection, and intent clarification.
- Ripley implemented quality calibration gate (D4) in cogworks-encode Self-Verification to detect superficial synthesis.
- Hudson added generalization probe and edge case tests (D8) plus pre-release CI gate to catch circular verification failures.

### 2026-03-04: Context-Impact Remediation
- Converted CLAUDE.md from symlink (mode 120000) to regular file (mode 100644)
- Replaced content with 3-line pointer to AGENTS.md per expert subtraction principle
- Eliminated F2/F3 context bloat from byte-for-byte duplication

