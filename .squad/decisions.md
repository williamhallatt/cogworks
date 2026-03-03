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
