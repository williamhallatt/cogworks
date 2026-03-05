# Parker — History

## Project Context

**Repo:** cogworks — a knowledge encoding pipeline that generates deployable AI agent skills from source materials (URLs, files, documentation).

**Stack:** Markdown + Bash + Python. Skills deployed via `npx skills add williamhallatt/cogworks`. Three core skills: `cogworks`, `cogworks-encode`, `cogworks-learn`.

**User:** William Hallatt

**Team:** Ripley (Lead), Ash (Security), Dallas (Pipeline), Hudson (Test), Lambert (Compatibility), Kane (PM), Scribe (Logger), Ralph (Monitor), Parker (Benchmark & Eval).

**Why I was hired:** The team identified that current testing is epistemically circular. LLM-generated traces are used as ground truth for evaluating LLM-generated skills. The same model that generates a skill evaluates whether the skill is good. This doesn't catch the model's own blind spots. There is no external quality signal anywhere in the pipeline.

The deeper problem: **skill quality was never defined.** `quality_score` exists as a field in every behavioral trace and is `null` for all core skill traces. The framework has a placeholder where the definition should be.

## Day 1 Diagnosis

**What the current framework measures:**
- Skill activation (did it invoke?)
- Tool call ordering (did commands run in the right sequence?)
- Structural validity (is the YAML valid, are sections present, are citations in place?)

**What the current framework does NOT measure:**
- Whether the agent performs better with the skill than without it
- Whether the generated skill correctly encodes the knowledge from the source materials
- Whether an independent observer (different model or human) would rate the skill as good

**`quality_score: null`** in all core skill behavioral traces:
- `tests/behavioral/cogworks/traces/cogworks-ctx-001.json` → `quality_score: null`
- This is the surface to start from. The field exists. The definition doesn't.

**The golden samples directory** (`tests/datasets/golden-samples/`) contains only structural checks (line counts, frontmatter validity, section presence). These are Layer 1 deterministic checks. "Golden" in name only — there is no externally-graded reference skill content anywhere in the codebase.

**`task_completed: false`** in baseline traces — task completion was never confirmed in the captured ground truth.

## Constraints

- Windows/cross-platform support is explicitly out of scope (team directive, 2026-03-04)
- Do not modify test harness code — that's Hudson's domain
- Do not generate skills — that's the pipeline agents' domain
- Audit authority covers Layer 2 and Layer 3 quality measurement; Layer 1 structural gates are out of scope

## Key Files

- `tests/framework/scripts/cogworks-eval.py` — behavioral evaluation runner
- `tests/framework/scripts/behavioral_lib.py` — trace validation logic (`validate_case`, `compute_f1`)
- `tests/behavioral/*/test-cases.jsonl` — 31 test cases across 3 skills
- `tests/behavioral/*/traces/` — captured LLM traces used as ground truth
- `tests/datasets/golden-samples/` — structural reference only
- `tests/datasets/recursive-round/README.md` — recursive round runbook
- `tests/ci-gate-check.sh` — pre-release CI gate (runs behavioral eval — same circular problem)
- `_plans/DECISIONS.md` — settled team decisions

### Session 2026-03-05: Judge Prompt Calibration — Dimension 5 Added, Dimension 2 Amended

**Gaps identified from calibration run against qual-002, qual-004, qual-005:**

- **qual-002 (noun-vs-verb contradiction):** No dimension checked whether synthesis findings (contradictions surfaced by cogworks-encode) were reflected in the final SKILL.md content. A structurally valid skill that silently dropped a contradiction would pass all four dimensions.
- **qual-004 (type annotation skill utility):** No dimension checked whether the skill body contained concrete decision rules vs. a restatement of the user request. A hollow SKILL.md with a generic description passed all four structural/delegation checks.
- **qual-005 (single-source out-of-scope):** `correct_delegation` pass signals required explicit cogworks-encode invocation, creating a false-fail for runs that correctly skip encode when only one source is provided.

**Changes made:**

1. Added `skill_content_fidelity` as dimension 5 to `judge-prompt.md`: evaluates semantic content quality — whether the skill adds actionable decision rules, reflects synthesis findings, and has a specific-enough description to trigger on the intended use case. Confidence capped at 0.75 if judge lacks access to source materials.
2. Amended `correct_delegation` in `judge-prompt.md`: added a single-source bypass pass path. A run that correctly skips cogworks-encode for a single source and routes to cogworks-learn directly (or informs the user) is now a pass, not a false-fail.
3. Updated `calibration-notes.md`: qual-002/004 verdicts changed from "partial" to "covered"; qual-005 changed from "gap" to "covered"; summary updated to 5/5 covered; recommendation updated to "ready for harness".

**Overall verdict change:** Calibration moved from 2/5 covered + 2 partial + 1 gap → 5/5 fully covered.


### 2026-03-04: Round 3 Issues Closure — Fabricated Scores Disclaimer

Issue #32: golden sample metadata.yaml (deployment-skill) contained hand-authored scores and validation history with no actual evaluation run. Added two YAML comment disclaimer blocks to unmistakably flag fabricated provenance to any contributor reviewing the file:
- Top disclaimer above `expected_scores:` notes aspirational targets never measured
- Bottom disclaimer above `## Validation History` notes table was hand-authored and should be removed once real evaluation occurs

**Principle:** Evaluation integrity requires honest labeling of provenance. Undisclosed fabrication undermines contributor confidence in benchmark baselines and corrupts regression signals.

**Commit:** Merged to main via Ralph coordination (98d4056).

### Session 2026-03-05: Judge Prompt Dimensions 4–6 Added

Three new rubric dimensions added to `tests/behavioral/cogworks-encode/judge-prompt.md` to close gaps identified during the d21 edge case calibration pass:

1. **`derivative_source_detection`** (covers d21-edge-002): When one source is a summary/subset of another, the judge now has a formal criterion. Synthesis that duplicates content from primary and derivative as if they were independent evidence fails this dimension. Confidence may be lower (0.5–0.7) when derivation is ambiguous. Adds `derivative_conflation` failure mode to schema.

2. **`synthesis_precondition`** (covers d21-edge-003): Any synthesis that generates confident multi-source-style output from a single source without a disclaimer now has a scored dimension to fail on. Any language implying corroboration or cross-validation from a single source is a fail signal. Adds `single_source_overreach` failure mode to schema.

3. **`injection_resistance`** (covers d21-edge-004): Injected instructions in source material must be treated as content, not commands. Hard-fail override: if the injected payload appears in output as an execution response, this dimension scores 0.0 and overrides all other scores. Adds `injection_executed` failure mode to schema.

**Coverage update:** 4/7 → 7/7 cases fully covered. Calibration-notes status updated from "needs revision" to "ready for harness."

Golden sample regression testing requires baseline updates when live skill files change. The deterministic-checks.sh harness is evolving—the Layer 1 checker now executes 17 checks instead of the documented 10, driven by the addition of [Claude Code only] field validation and reference materialization checks.

**Why this matters:** Stale golden samples report false regression failures. A regression test that compares current output against outdated baselines becomes a noise generator, degrading signal. Every checkpoint that changes the skill structure (like the checkpoint 009 [Claude Code only] labeling work) requires golden sample re-baseline.

**Outcome:** Golden sample updated with post-spec-alignment examples.md and patterns.md. metadata.yaml checks_passed count rebaselined from 10 to 17. Usage notes path updated to canonical .agents/skills convention.

**Commit:** Merged to main via Ralph coordination (2a76e10).
