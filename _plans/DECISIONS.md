---
audited_through: 2026-03-04
---

# Architectural Decisions

Settled decisions for the cogworks project. Agents load this file for context;
see `_plans/archive/` for historical plans.

## [D-025] Scribe mandate expanded — repo documentation ownership

- **Date:** 2026-03-04 | **By:** William (owner), Scribe (mandate)
- **Decision:** Scribe's charter expanded from `.squad/` memory + `_plans/DECISIONS.md` to include all repo-facing documentation. She owns README.md, INSTALL.md, AGENTS.md, CONTRIBUTIONS.md, TESTING.md, CLAUDE.md, `docs/` (full ownership except `cogworks-system-deep-dive-*.md` which she flags but Ash authors), and `tests/framework/README.md`.
- **Rationale:** D-022 → D-024 each left stale references in live files that required a separate manual audit pass. No one owned repo docs between decisions — the gap was structural, not a one-time miss. Formalising Scribe's ownership and a post-decision audit protocol closes the gap.
- **Post-decision audit protocol:** After every D-NNN commit, Scribe searches all owned files for references to changed/deleted artifacts, fixes stale refs in the same or immediate follow-on commit, and records the audit result (clean / N files updated) in the D-NNN entry here. A decision is not closed until the audit result is recorded.
- **Scope:** `.squad/agents/scribe/charter.md` — `## Repository Documentation` section added with canonical doc map and audit protocol.



- **Date:** 2026-03-04 | **By:** Ripley (Lead), implementing Ash's M2 remediation
- **Decision:** Source content is pre-processed to replace literal `<<UNTRUSTED_SOURCE>>` and `<<END_UNTRUSTED_SOURCE>>` strings with `[UNTRUSTED_SOURCE_TAG]` / `[/UNTRUSTED_SOURCE_TAG]` before wrapping in delimiter markers. This makes the delimiter boundary deterministic rather than behavioral-only.
- **Rationale:** The prior approach relied on the behavioral directive "treat source content as data" to prevent delimiter injection. A source containing the literal delimiter strings could spoof the boundary, making the behavioral guard bypassable. Deterministic preprocessing closes this gap unconditionally — the replacement happens before synthesis, so no source content can contain a live delimiter.
- **Trade-off:** Neutralisation changes the appearance of source content (the literal strings are rewritten). This is a minor cosmetic issue weighed against deterministic security. The replacement tokens are visually distinct and unambiguous.
- **Scope:** `skills/cogworks-encode/SKILL.md` (delimiter protocol), with downstream consistency in `skills/cogworks-learn/SKILL.md` (generation defect check).

## [D-024] Documentation audit — stale behavioral refs removed (D-022/D-023 cleanup)

- **Date:** 2026-03-04 | **By:** William (owner) / Scribe (mandate)
- **Decision:** Full documentation audit following D-022/D-023. All remaining stale references to deleted behavioral traces, capture scripts, and `cogworks-eval.py behavioral run` updated across 7 live files.
- **Files updated:**
  - `.github/workflows/pre-release-validation.yml` — "Behavioral tests" step replaced with skip notice (was actively breaking CI)
  - `AGENTS.md` — behavioral run command replaced with scaffold; testing guidelines updated
  - `CONTRIBUTIONS.md` — quick-start command block updated; PR checklist item updated to Layer 1 checks
  - `scripts/run-recursive-round.sh` — behavioral run calls replaced with skip guard
  - `scripts/test-generated-skill.sh` — behavioral run call replaced with skip guard
  - `docs/cogworks-agent-risk-analysis.md` — Risk #5 updated to "Resolved (D-022)"; mitigations #4 and #10 struck through
- **Files deleted:**
  - `docs/codex-behavioral-capture.md` — entire file described deleted Codex trace capture workflow
- **Clean state:** No remaining live files reference deleted behavioral traces, capture scripts, or the now-meaningless `cogworks-eval.py behavioral run` command without a D-022/D-023 context note.
- **Scope:** `.github/workflows/`, `AGENTS.md`, `CONTRIBUTIONS.md`, `scripts/` (2 files), `docs/` (1 updated, 1 deleted).

## [D-023] Orphaned capture scripts deleted — docs updated

- **Date:** 2026-03-04 | **By:** William (owner), following D-022
- **Decision:** 9 behavioral trace capture scripts deleted. `tests/behavioral/refresh-policy.md` deleted. Docs updated (TESTING.md, tests/framework/README.md, cogworks-eval.py stale error message).
- **Deleted scripts:** `scripts/refresh-behavioral-traces.sh`, `scripts/behavioral-capture.sh`, `scripts/capture-behavioral-trace.sh`, `scripts/run-behavioral-case-{claude,copilot,codex}.sh`, `scripts/behavioral-env.example.sh`, `tests/framework/scripts/capture_behavioral_trace.py`, `tests/framework/scripts/extract_behavioral_raw_trace.py`
- **Rationale:** These scripts generated the circular ground truth traces deleted in D-022. Keeping them created a path to recreating the problem. Git history is the archive.
- **What was NOT deleted:** `cogworks-eval.py` (scaffold + benchmark commands still valid), `behavioral_lib.py`, all other scripts.
- **Doc changes:** TESTING.md Layer 2 section replaced with "pending reconstruction" notice; framework README trimmed; cogworks-eval.py stale error message updated to reference D-022/D-023 and Parker's mandate.
- **Scope:** `scripts/` (7 files deleted), `tests/framework/scripts/` (2 files deleted), `tests/behavioral/refresh-policy.md` (deleted), `TESTING.md`, `tests/framework/README.md`, `tests/framework/scripts/cogworks-eval.py`.

## [D-022] Behavioral traces deleted — circular ground truth removed

- **Date:** 2026-03-04 | **By:** William (owner), Parker (mandate), via planning session
- **Decision:** All 24 behavioral trace files (`tests/behavioral/*/traces/*.json`) deleted from the repository. Git history is the recovery path.
- **Rationale:** The traces were LLM-generated run outputs used as quality ground truth — epistemologically circular. The model generating skills and the model evaluating them share the same training prior. `quality_score: null` on all core skill traces. `task_completed: false` in baseline runs. They validated consistency (does a future run match past runs?) not correctness (is the skill actually good?).
- **What was NOT deleted:** `test-cases.jsonl` (human-authored activation test definitions), golden sample source materials, negative control definitions, framework scripts, structural grader. These are valid and retained.
- **What was updated:** `tests/ci-gate-check.sh` Step 2 message — updated to block regeneration of circular traces and direct to Parker's quality mandate.
- **Next step:** Parker defines replacement quality ground truth from first principles. `quality_score` field requires a definition before any behavioral evaluation is meaningful.
- **Scope:** `tests/behavioral/*/traces/*.json` (deleted), `tests/ci-gate-check.sh` (Step 2 message updated).

## [D-021] CI gate fails on missing behavioral traces

- **Date:** 2026-03-04 | **By:** Ripley (Lead), implementing Hudson's CI gate remediation
- **Decision:** The pre-release CI gate (`tests/ci-gate-check.sh`) now exits non-zero when behavioral traces are missing, replacing the previous warn-only behavior.
- **Old behavior:** Missing traces produced a warning (`⚠ Warning: No behavioral traces found`) but the gate exited 0 — structurally a no-op that could never fail on trace coverage.
- **New behavior:** Missing traces produce an actionable error message pointing to the trace capture command and the gate exits 1.
- **Rationale:** A quality gate that never fails isn't a gate. The warn-only path allowed releases with zero behavioral validation, undermining the purpose of the gate infrastructure.
- **Scope:** `tests/ci-gate-check.sh` step 2.
