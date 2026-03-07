# history.md

## Learnings

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


### 2026-03-05: CC-Only Labeling — examples.md and patterns.md

- Added `**[Claude Code only]**` notes to 8 examples in `examples.md` (Examples 2, 4, 5, 6, 7, 8, 10, 11) covering `context: fork`, `disable-model-invocation`, `argument-hint`, `$ARGUMENTS`, `${CLAUDE_SESSION_ID}`, `user-invocable: false`, and `~/.claude/skills/` paths.
- Added inline `# [Claude Code only]` YAML comments and heading-level notes to 7 patterns/anti-patterns in `patterns.md` (Patterns 2, 4, 6, 7, 8, 10; Anti-Patterns 3, 4, 7, 8).
- Consistent with `reference.md` labeling established in TD-017/TD-018.
- Labels are additive only — no examples, logic, or structure was changed.
- Pattern 10 received a prose note after the code block (not YAML) since the CC-only aspect is the directory path convention, not a frontmatter field.

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

### 2026-03-12: Cross-Agent Path Fixes — Testing Docs and Fixture Sync

Fixed three compatibility gaps:

1. **TESTING.md case count (line 93):** Updated from "31 cases" to "39 cases" (cogworks=8, cogworks-encode=15, cogworks-learn=16). Verified cross-agent path examples already present in Layer 1.
2. **cogworks-eval.py default paths (lines 419, 439):** Changed `--skills-root` default from `.claude/skills` to `.agents/skills` for both `run` and `scaffold` subcommands. Aligns CLI defaults with cross-agent convention.
3. **snapshot-cogworks-learn fixture identity:** Synced description field from Claude Code-specific "Expert knowledge on writing Claude Code skills..." to cross-agent "Use when creating or revising agent skills..." per current live `skills/cogworks-learn/SKILL.md`. Updated body line 13 from "writing Claude Code skills" to "writing agent skills". Preserved `snapshot_date`, `license`, `metadata` fields unchanged.

**Key learning:** Test fixtures can drift from live skills when skills evolve identity/scope. Cross-agent path defaults should match primary convention (`.agents/skills/` = cross-agent, `.claude/skills/` = Claude Code-specific).

**Scope:** Surgical changes only—did not touch other defaults, logic, or unrelated fixture fields.

**Commit:** [pending]
