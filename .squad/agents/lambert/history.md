# history.md

## Learnings

### 2026-03-14: Compatibility Review II — Terminology & Codex Adapter Analysis

Completed comprehensive analysis of two compatibility issues identified in b6208ff+ review:

**Issue 1: Terminology Glossary**
- Cataloged five terminology gaps across agentic-runtime.md, SKILL.md, claude-adapter.md, copilot-adapter.md:
  1. "contradiction" (SKILL.md) vs "conflicting guidance" (agentic-runtime.md) — used interchangeably, not defined
  2. "synthesis fidelity" (SKILL.md, agentic-runtime.md) — used operationally but never defined; critical for validator routing
  3. "brittle execution" (claude-adapter.md) — used to justify foreground downgrade but undefined
  4. Escalation criteria drift — agentic-runtime.md specifies five criteria (including untrusted-content), SKILL.md only four
  5. Secondary gaps: "trust-boundary", "entity-boundary", "derivative-source" listed but underspecified

- Proposed solution: Add 250-line "Terminology" section to agentic-runtime.md after Operating Principle section, with subsections for each term + operational examples. Update SKILL.md and claude-adapter.md to reference glossary and align terminology.
- Key finding: Agents interpreting agentic-runtime.md literally would implement validator routing (fidelity-failure → synthesis, other-failure → packaging) but lack the definitions of what counts as "fidelity failure". Glossary is operationally critical, not just pedagogical.

**Issue 2: Codex Adapter Resolution**
- Status: agentic-runtime.md defers Codex adapter support (line 38: "Codex adapter documentation is deferred — no Codex subagent primitives have been sourced yet")
- Evidence: README.md lines 137–142 show Codex CLI examples suggesting agentic engine works on Codex. Benchmark infrastructure (skill-benchmark-codex-adapter.py, codex-adapter-spec.md) consumes Codex traces post-hoc, but does not represent agentic orchestration support.
- Finding: Codex does not expose a subagent/agent-spawn primitive equivalent to Claude's Task tool or Copilot's task tool. Agentic runtime is built on subagent abstraction; without it, Codex would require wholesale rewrite.
- Recommended decision: Remove Codex from README.md user-facing documentation (lines 137–142 delete, line 148 remove "Codex" from list). Rationale: Misleading examples cost more than one-time re-addition if Codex capabilities change.

**Artifacts:** Comprehensive proposal document written to `.squad/decisions/inbox/lambert-terminology-codex.md` with:
- Complete terminology inventory (5 gaps + 3 secondary)
- Proposed glossary format and content (~250 lines)
- Exact file/line changes needed for consistency (5 edits across 3 files)
- Codex adapter gap evidence and two decision paths with change lists

**Key learning:** In systems designed for AI interpretation, terminological drift is not just a documentation quality issue—it's an operational correctness issue. Agents following validator routing logic need precise definitions of "fidelity" to work correctly. Glossaries in agentic systems are control surfaces, not optional pedagogical aids.

### 2026-03-04: Round 3 Issues Closure — Cross-Agent Path Sync & Defaults Update

Completed final Ralph-coordinated remediation for cross-agent compatibility defaults:

1. **TESTING.md case count:** Updated from 31 to 39 cases (cogworks=8, cogworks-encode=15, cogworks-learn=16).
2. **cogworks-eval.py defaults:** Changed `--skills-root` default from `.claude/skills` → `.agents/skills` on lines 419, 439 (both `run` and `scaffold` subcommands). Aligns CLI defaults with primary cross-agent convention.
3. **snapshot-cogworks-learn fixture:** Synced description from "writing Claude Code skills..." → "writing agent skills..." per live `skills/cogworks-learn/SKILL.md`. Preserved snapshot_date, license, and metadata unchanged.

**Key decision:** Primary cross-agent convention is `.agents/skills/` (universal); `.claude/skills/` is Claude Code-specific. CLI defaults must reflect this ordering.

**Commit:** Merged to main via Ralph coordination (34d0d08).

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

### 2026-03-12: Cross-Agent Path Fixes — INSTALL.md and CONTRIBUTIONS.md

- Fixed INSTALL.md Manual Installation section (lines 38-50): Added `.agents/skills/` as primary cross-agent path alongside `.claude/skills/` (Claude Code only).
- Fixed INSTALL.md Verify Installation section (lines 54-66): Added `.agents/skills/` verification commands alongside `.claude/skills/`.
- Fixed INSTALL.md Invoking Skills table (line 75): Corrected Codex CLI invocation from incorrect `$` prefix to `varies | natural language or see Codex docs`.
- Fixed CONTRIBUTIONS.md dev install command (line 15): Changed `npx skills add ./skills` → `npx skills add .` per AGENTS.md.
- Fixed CONTRIBUTIONS.md PR checklist (lines 45, 49): Added `.agents/**` alongside `.claude/**` in Layer 1 checks and pre-release validation workflow path list.
- Fixed CONTRIBUTIONS.md Step 1: Validate symlink check (lines 67-75): Added second loop for `.agents/skills/` verification alongside `.claude/skills/`.
- Fixed CONTRIBUTIONS.md Release validation checklist (line 112): Added `.agents/skills/` symlinks alongside `.claude/skills/`.
- Fixed CONTRIBUTIONS.md Broken symlinks section (lines 130-134): Added `ls -la .agents/skills/` command alongside `.claude/skills/`.
- **Key learning:** Codex invocation prefix `$` was incorrect; Codex uses natural language (varies). `.agents/skills/` is the primary cross-agent path; `.claude/skills/` is Claude Code-specific.
- **Decision captured:** TD-019 in team decisions.md (merged from inbox).
- **Commit:** ca8f5cb


**2026-03-08 — Post-Review Fan-Out (Terminology + Codex)**

Lambert proposed two solutions: (1) Canonical terminology glossary to resolve name drift across specs ("contradiction" vs "conflicting guidance", undefined terms), (2) Codex adapter decision (recommend Option B: benchmark-only, defer engine adapter). Proposals consolidated into decisions.md pending approval.

**Cross-references:** Ripley prioritized glossary as P0 blocker; glossary is prerequisite for Ash/Dallas implementations to avoid divergent interpretations. Codex decision relates to Ripley's Codex adapter deferral recommendation.

