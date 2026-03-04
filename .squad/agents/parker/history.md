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

## Learnings

### 2026-03-04: Round 3 Issues Closure — Fabricated Scores Disclaimer

Issue #32: golden sample metadata.yaml (deployment-skill) contained hand-authored scores and validation history with no actual evaluation run. Added two YAML comment disclaimer blocks to unmistakably flag fabricated provenance to any contributor reviewing the file:
- Top disclaimer above `expected_scores:` notes aspirational targets never measured
- Bottom disclaimer above `## Validation History` notes table was hand-authored and should be removed once real evaluation occurs

**Principle:** Evaluation integrity requires honest labeling of provenance. Undisclosed fabrication undermines contributor confidence in benchmark baselines and corrupts regression signals.

**Commit:** Merged to main via Ralph coordination (98d4056).

### Session 2026-03-04: Golden Sample Sync

Golden sample regression testing requires baseline updates when live skill files change. The deterministic-checks.sh harness is evolving—the Layer 1 checker now executes 17 checks instead of the documented 10, driven by the addition of [Claude Code only] field validation and reference materialization checks.

**Why this matters:** Stale golden samples report false regression failures. A regression test that compares current output against outdated baselines becomes a noise generator, degrading signal. Every checkpoint that changes the skill structure (like the checkpoint 009 [Claude Code only] labeling work) requires golden sample re-baseline.

**Outcome:** Golden sample updated with post-spec-alignment examples.md and patterns.md. metadata.yaml checks_passed count rebaselined from 10 to 17. Usage notes path updated to canonical .agents/skills convention.

**Commit:** Merged to main via Ralph coordination (2a76e10).
