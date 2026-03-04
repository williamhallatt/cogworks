# Team Decisions

<!-- Append-only. Scribe merges inbox entries here. -->

## [TD-001] Team formed to address cogworks risk analysis findings
- **Date:** 2026-03-03 | **By:** William Hallatt
- Specialist team created to implement the 12 prioritised mitigations from `docs/cogworks-agent-risk-analysis.md`.
- Work streams: security (Ash), pipeline (Dallas), testing (Hudson), compatibility/contributor safety (Lambert), with Ripley as lead reviewer.

## [TD-002] Security Guards Implementation (Round 2)
- **Date:** 2026-03-03 | **By:** Ash (Security Engineer)
- **Issues Addressed:** #13 (D2), #18 (D1), #22 (D1)
- **Core Principle:** Autonomous systems must fail safely. Stop and ask rather than infer critical decisions.
- **Stale Skill Guard:** Detects edits to cogworks skill files mid-session; warns of in-memory state inconsistency before invoking edited skills.
- **Intent Clarification Gate:** Confirms explicit skill generation intent before proceeding with file side effects. Prevents unintended directory/file creation.
- **Escalation Boundary (Autonomous Mode):** When autonomous mode hits unresolvable decision (conflicting sources, ambiguous scope, missing input), stops and surfaces question rather than silent best-guess.
- **Implementation:** Three surgical edits to `skills/cogworks/SKILL.md`; no other changes.
- **Status:** Ready for review and commit.

## [TD-003] Pipeline Guards Implementation (Round 2)
- **Date:** 2026-03-03 | **By:** Dallas (Pipeline Engineer)
- **Issues Addressed:** #5 (M5), #11 (M11), #14 (D3), #16 (D7)
- **M5 Overwrite Protection:** User confirmation required before overwriting existing skill path with SKILL.md present. Prevents silent data loss.
- **M11 Cross-Source Count:** Verification that synthesised claims merging N sources are grounded in at least 2 of those N sources. Detects false synthesis.
- **D3 CDR Completeness:** Every CDR registry entry must trace to at least one Decision Skeleton entry. Prevents CDR bloat; ensures traceability function.
- **D7 Convergence Guard:** Detects "Synthesis Metadata" or cogworks-generated sources in input; warns of non-convergence risk; requires explicit confirmation.
- **Implementation:** Four surgical edits to `skills/cogworks/SKILL.md` and `skills/cogworks-encode/SKILL.md`; guards placed at earliest detection points.
- **Status:** Ready for review and commit.

## [TD-004] No GitHub Project Board
- **Date:** 2026-03-03 | **By:** William Hallatt (via Copilot)
- **Decision:** Do not use GitHub Projects board. Issues + `squad:{member}` labels sufficient for 22 work items.
- **Rationale:** Work tracking is lightweight; Ralph and agent routing work directly off issue labels; no stakeholder kanban view needed at this scale; Project board adds sync overhead and requires elevated token scopes.
- **Action:** Run `gh auth refresh -s read:project,read:org,read:discussion` then `gh project delete 1 --owner @me` to remove existing board.

## [TD-005] Documentation & Schema Creation (Round 2)
- **Date:** 2026-03-03 | **By:** Lambert (Compatibility Engineer)
- **Issues Addressed:** #10 (M10), #12 (M12), #19 (D10)
- **M10 Codex Behavioral Capture:** New `docs/codex-behavioral-capture.md` (~200 lines). Practical guide to manually capturing behavioral traces from Codex (no auto-loading). Addresses non-determinism via BLEU/ROUGE and manual grading.
- **M12 Skills-Lock Schema:** New `docs/skills-lock-schema.md` (~100 lines). Adds `core_skills_hash` (SHA-256) field to detect unintentional cogworks core skill drift. Schema includes computation example and migration walkthrough with `jq`.
- **D10 AGENTS/CLAUDE Dedup:** Analysis complete: files are byte-for-byte identical. Recommended action (Option A — minimal pointer): CLAUDE.md becomes pointer to AGENTS.md with optional preamble. Aligns with expert subtraction principle. No Claude-specific guidance segregated.
- **Status:** Documentation created; dedup recommendation ready for William's decision.

## [TD-006] Test Coverage & CI Gate Implementation (Round 2)
- **Date:** 2026-03-03 | **By:** Hudson (Test Engineer)
- **Issues Addressed:** #17 (D8), #21 (D8), #20 (D10)
- **D8 Generalization Probes:** 3 new test cases targeting circular verification failures: contradictory sources, context-dependent recommendations, distinct API endpoints. Each includes ground truth and evaluator notes.
- **D8 Edge Cases:** 4 new test cases: direct contradiction, derivative/summary source, single-source synthesis (should warn), source with embedded instructions (injection resistance).
- **D10 Pre-release CI Gate:** New `tests/ci-gate-check.sh` script runs quality gates, verifies behavioral trace coverage, executes behavioral eval. Returns exit 0 on pass, exit 1 on fail. Updated `TESTING.md` with Pre-release CI Gate section.
- **Rationale:** D8 risk (generator evaluates own output) creates circular checks where same model rationalizes its synthesis. New tests force independent evaluation and surface issues self-evaluation misses.
- **Status:** 7 test cases written to test-cases.jsonl (15 total); pre-release gate script created; ready for behavioral trace capture.

## [TD-007] Quality Calibration Gate Implementation (Round 2)
- **Date:** 2026-03-03 | **By:** Ripley (Lead Architect)
- **Issue Addressed:** #15 (D4)
- **Decision:** Added Quality calibration (anti-superficiality gate) subsection to Self-Verification in `skills/cogworks-encode/SKILL.md`.
- **Implementation:** Four self-check questions target false consensus, unjustified authority assignment, untraceable claims, absent subtraction decisions. Calibration gate inversion: "all clear" resolution treated as superficiality signal → triggers re-examination.
- **Rationale:** Placed in Self-Verification (not new phase) because calibration is quality dimension of existing verification. Written as authoritative instruction (not checklist) to match skill voice. Key pattern exploits fact that genuine multi-source synthesis almost always surfaces tension.
- **Scope:** `skills/cogworks-encode/SKILL.md` only.
- **Status:** Ready for review and commit.

## [TD-008] Security Injection Scan Completion (Round 3 Gap Closure)
- **Date:** 2026-03-04 | **By:** Ash (Security Engineer)
- **Issues Addressed:** M2 (delimiter escape), M9 (post-generation injection scan)
- **M2 — Deterministic Delimiter Escape:** Replaced behavioral directive with explicit deterministic preprocessing. Literal closing delimiter forms (`<</UNTRUSTED_SOURCE>>`, `<<END_UNTRUSTED_SOURCE>>`) are now replaced with `[UNTRUSTED_SOURCE_TAG]` / `[/UNTRUSTED_SOURCE_TAG]` before wrapping in untrusted block. Architectural decision: **D-020** (deterministic escape required; behavioral intent insufficient).
- **M9 — Post-Generation Injection Scan:** Extended `cogworks-learn/SKILL.md` checklist item 10 to scan for four additional pattern categories: (1) prompt-override phrases ("ignore prior", "ignore previous"), (2) standalone imperative directives ("you must", "always do"), (3) tool call syntax not belonging to skill delimiters, (4) delimiter leakage. All checks case-insensitive pattern matches. User confirmation required before writing if any pattern found.
- **Scope:** `skills/cogworks-encode/SKILL.md` (delimiter protocol), `skills/cogworks-learn/SKILL.md` (injection checklist).
- **Status:** Completed, merged to orchestration log.

## [TD-009] Pipeline Overwrite Protection Extended (Round 3 Gap Closure)
- **Date:** 2026-03-04 | **By:** Dallas (Pipeline Engineer)
- **Issues Addressed:** D9 (slug collision against installed agent directories), D3 (handoff artifact presence check)
- **D9 — Slug Collision Guard Extended:** Overwrite protection in `skills/cogworks/SKILL.md` Step 5 now checks for slug collisions in installed agent directories (`.claude/skills/`, `.agents/skills/`, `.copilot/skills/`) in addition to `_generated-skills/` staging directory. Missing directories gracefully skipped — no error if agent directory does not exist.
- **D3 — Handoff Artifact Presence Check:** Added explicit artifact presence check to `skills/cogworks-encode/SKILL.md` Stage Contracts section. Pipeline halts with blocking error if any required handoff artifact (`{cdr_registry}`, `{traceability_map}`, `{decision_skeleton}`, etc.) is absent or empty at consumption point. Placed at consumption boundary.
- **Scope:** `skills/cogworks/SKILL.md` (Step 5), `skills/cogworks-encode/SKILL.md` (Stage Contracts).
- **Status:** Completed, merged to orchestration log.

## [TD-010] Cross-Agent Compatibility Documentation (Round 3 Gap Closure)
- **Date:** 2026-03-04 | **By:** Lambert (Compatibility Engineer)
- **Issue Addressed:** D6 (cross-agent compatibility matrix and generated-skill guidance)
- **Deliverable 1 — Compatibility Matrix:** New `docs/cross-agent-compatibility.md` (~360 lines, 7 sections). Covers invocation syntax (/, $, natural language), `$ARGUMENTS` interpolation, `allowed-tools` enforcement across Claude Code, GitHub Copilot, Codex/GPT-5, and MCP agents. Honest labeling of unknowns: ✅ Confirmed, 🟡 Partial, ❓ Untested, ❌ Known broken. Flags Copilot `$ARGUMENTS` support as undefined and documents as highest priority for live testing.
- **Deliverable 2 — Generated-Skill Template:** Added Compatibility (L2) guidance to `skills/cogworks-learn/SKILL.md`. Instructs generated skill authors to include a Compatibility section in SKILL.md, with fallback note for agents lacking `$ARGUMENTS` support.
- **User-Facing Guidance:** "Compatibility Note for Generated Skills" section provides 1-paragraph explanation for skill users on non-Claude Code agents.
- **Outstanding Work:** 5 identified gaps (Copilot `$ARGUMENTS`, Copilot `allowed-tools`, MCP integration, Cursor auto-load, argument fallback behavior) documented with effort estimates for post-Round-3 testing.
- **Scope:** `docs/cross-agent-compatibility.md` (new), `skills/cogworks-learn/SKILL.md` (template guidance).
- **Status:** Completed, merged to orchestration log.

## [TD-011] CI Gate Behavioral Coverage Enforcement (Round 3 Gap Closure)
- **Date:** 2026-03-04 | **By:** Hudson (Test Engineer)
- **Issue Addressed:** D8 (CI gate now blocks on missing behavioral traces)
- **Change:** Updated `tests/ci-gate-check.sh` to fail (exit non-zero) when behavioral traces are missing for any skill. Previous behavior: warning only, allowed releases with zero behavioral evaluation. New behavior: iterates all skill directories (`cogworks`, `cogworks-encode`, `cogworks-learn`), counts trace files per skill, exits 1 with actionable error if any skill has zero traces.
- **Remediation Command:** Gate output includes exact command to fix: `python3 tests/framework/scripts/cogworks-eval.py behavioral run --skill-prefix cogworks-`.
- **Documentation:** Updated `TESTING.md` Pre-release CI Gate section with trace requirement.
- **Architectural Decision:** **D-021** (behavioral coverage is release guarantee, not optional signal; trace presence check is blocking gate).
- **Scope:** `tests/ci-gate-check.sh`, `TESTING.md`.
- **Status:** Completed, merged to orchestration log.

## [TD-012] Architectural Decision Recording (Round 3 Gap Closure)
- **Date:** 2026-03-04 | **By:** Ripley (Lead Architect)
- **Decisions Recorded:** D-020 (M2 deterministic delimiter escape), D-021 (CI gate behavioral coverage requirement).
- **Coherence Review:** All agent closures (M2, M9, D9, D3, D6, D8) verified for conflicts. No conflicts found. M2 ↔ cogworks-learn consistency verified; D9 ↔ existing overwrite protection verified; CI gate ↔ existing traces verified.
- **Scope:** `_plans/DECISIONS.md`.
- **Status:** Completed, merged to orchestration log.

## [TD-013] User Directive: Windows/Cross-Platform Out of Scope
- **Date:** 2026-03-04T08:57:57Z | **By:** William Hallatt (via Copilot)
- **What:** Windows and cross-platform support are explicitly out of scope. Do not spend engineering effort on Windows compatibility, PowerShell, or WSL testing.
- **Why:** User request — captured for team memory
- **Context:** Established during Parker (Benchmark & Evaluation Engineer) onboarding.

## [TD-014] Product Gap Analysis: Agent Skills, Sub-Agents & Prompt Engineering
- **Date:** 2026-03-04T11:22:28Z | **By:** Kane (Product Manager)
- **Artifact:** `_sources/kane-synthesis-agent-skills.md` (20K+ words, 10 sections)
- **Methodology:** Systematic audit of 13 Tier 1 + 7 Tier 2 sources covering Claude Code, Anthropic, OpenAI/Codex, and IBM prompt engineering guidance
- **Top 3 Critical Gaps (Priority Order):**
  1. **No activation testing** — behavioral eval validates output quality but not skill invocation precision; skills with perfect content but poor `description` fields may never be discovered
  2. **No parallel tool use guidance** — generated skills lack templates for parallel tool execution; 3-5x performance left on table for file-heavy operations
  3. **No evaluation flywheel** — generated skills deployed immediately without iterative refinement; no mechanism to run behavioral tests, analyze failures, surgically revise, and re-test
- **Secondary Gaps (Priorities 4-10):** Cross-agent compatibility validation, subagent orchestration guidance, multi-context state management, Codex-specific patterns, prompt caching optimization, injection scanning, trade-off matrix (skills vs. guidance)
- **Recommendations:** Extend behavioral eval with activation test cases (P0), template parallel execution in `cogworks-learn` (P1), prototype eval-driven refinement loop (P1), cross-agent compatibility testing (P2)
- **Status:** Ready for team review and prioritization discussion.

## [TD-015] Kane Charter Upskill — Synthesis Knowledge Integration
- **Date:** 2026-03-04T11:35:00Z | **By:** Kane (Product Manager)
- **What:** Updated `.squad/agents/kane/charter.md` to internalize synthesis findings from TD-014 (`_sources/kane-synthesis-agent-skills.md`). Replaced abstract expertise description with concrete, practitioner-level knowledge: exact frontmatter semantics, discovery priority rules, context budget numbers (2% window, 16K fallback), activation guard patterns, subagent configuration, prompt engineering specifics (Claude 4.x + Codex), evaluation framework, cogworks security guards (M2/M9), pipeline guards (M5/M11/D3/D7/D9), quality calibration (D4 inversion gate), behavioral coverage requirement (D21).
- **Companion Artifact:** Created `.squad/skills/product-gaps-cogworks/SKILL.md` encoding 10 gaps + 5 priority recommendations as reusable team decision-support skill for roadmap work.
- **Impact:** Product decisions now grounded in authoritative source knowledge, not assumptions. Kane can cite exact context constraints, reference specific quality gates, push for empirical validation (Copilot `$ARGUMENTS` support undefined = highest testing priority).
- **Status:** Complete; Kane's operational knowledge now team-accessible via skill.
