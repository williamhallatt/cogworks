# Plan: Improve Cogworks Testing Infrastructure

## Context

The testing infrastructure has the architecture for a three-layer grading system but only Layer 1 (deterministic structural checks) is implemented. Layer 2 (LLM-as-judge) and Layer 3 (human review calibration) exist only as documentation. Meanwhile, cogworks-learn's inline instructions already cover most of what Layer 1 checks. The goal is to make the testing infrastructure earn its keep by implementing the layers that catch real quality problems (semantic, not just structural), wiring testing into the generation workflow, and trimming the over-engineered meta-test suite.

## Execution Order

P3 and P4 are independent and can be done first. P1 depends on a stable Layer 1. P2 depends on P1. P5 depends on P1.

```
P3 (Improve Layer 1) ──┐
                        ├──► P1 (Implement Layer 2) ──► P2 (Wire into workflow)
P4 (Slim meta-tests) ──┘                            └──► P5 (Calibration)
```

---

## P3: Improve Layer 1 with Real-Failure-Mode Checks

**File:** `.claude/test-framework/graders/deterministic-checks.sh`

Add 4 new checks after the existing 10:

| # | Check | Type | Logic |
|---|-------|------|-------|
| 11 | Cross-file heading duplication | warning | Extract `## ` headings from reference.md, patterns.md, examples.md; flag identical headings across files |
| 12 | Frontmatter `name` format | warning | Validate: lowercase + numbers + hyphens only, max 64 chars, no reserved words ("anthropic", "claude") |
| 13 | Supporting file substantiveness | warning | For each `## ` section in supporting files, count words; flag if >50% of sections have <20 words |
| 14 | Citation format consistency | warning | Check file-path citations match pattern `(filename.ext:line)`; flag implausible ones |

Add these to `run_all_checks()` after line 208.

**New test fixtures** (for P4's retained test suite):
- `tests/test-data/duplicate-headings-skill/` — skill with shared headings across supporting files
- `tests/test-data/bad-name-skill/` — skill with `name: My_Skill.v2`

---

## P4: Slim Down Meta-Tests

**File:** `tests/test-suite/mvp-test-cases.jsonl`

Reduce from 16 to 8 tests. Keep:

| ID | Test | Rationale |
|----|------|-----------|
| mvp-001 | Clean pass (all checks) | Baseline functionality |
| mvp-002 | Missing citations = critical | Most important negative control |
| mvp-004 | Bad YAML = critical | Structural validation |
| mvp-010 | Exit code 1 for critical | API contract |
| mvp-012 | Exit code 0 for success | API contract |
| mvp-016 | Missing SKILL.md = graceful failure | Edge case |
| mvp-017 | Cross-file duplication warning | New check from P3 |
| mvp-018 | Bad name format warning | New check from P3 |

Remove mvp-003, 005, 006, 007, 008, 009, 011, 013, 014, 015 and their fixtures.

**Delete fixture directories:** `overlimit-skill/`, `few-citations-skill/`, `near-limit-skill/`, `exactly-500-skill/`, `exactly-3-entries-skill/`, `unclosed-fence-skill/`, `snapshot-advanced-prompting/`, `snapshot-cogworks-encode/`

**Update:** `TESTING.md` — correct test count and fixture list.

---

## P1: Implement Layer 2 LLM-as-Judge

**Key design decision:** The cogworks-test skill itself acts as the judge. Claude is already the evaluator — no external API calls needed. The rubrics in `llm-judge-rubrics.md` become actionable instructions in the skill's SKILL.md.

### Files to modify

**`.claude/skills/cogworks-test/SKILL.md`** — Major rewrite. New structure:

```
Invocation: /cogworks-test {slug} [--sources {path}] [--json] [--layer1-only]

Workflow:
1. Resolve skill path (.claude/skills/{slug}/ or tests/test-data/{slug}/)
2. Run Layer 1 via: bash .claude/test-framework/graders/deterministic-checks.sh {path} --json
3. If critical failures → report and STOP
4. If --layer1-only → report Layer 1 results and stop
5. Load skill files (SKILL.md, reference.md, patterns.md, examples.md)
6. Load source material (--sources path, or _sources/{slug}/, or skip with warning)
7. Evaluate each of 5 dimensions following rubric instructions (embedded in SKILL.md)
8. Compute weighted score, determine pass/fail (threshold: 0.85)
9. Write results to tests/results/{slug}-results.json
```

The 5 dimension evaluation instructions come from `llm-judge-rubrics.md` (lines 22-199), condensed into the SKILL.md as direct instructions. Include anti-leniency prompting: "Score 5 should be rare. Most good skills score 3-4. If uncertain between two scores, choose the lower one."

**`.claude/skills/cogworks-test/reference.md`** — Update implementation status table. Move detailed rubric scales here as reference (SKILL.md has the condensed actionable version).

**`.claude/test-framework/graders/llm-judge-rubrics.md`** — Add header note: "Authoritative specification. Executable version in `.claude/skills/cogworks-test/SKILL.md`. Keep both in sync."

**Layer 2 output format** (appended to Layer 1 JSON):

```json
{
  "layer1": { "status": "pass", "critical_failures": [], "warnings": [], "checks_passed": [] },
  "layer2": {
    "source_fidelity": { "score": 4, "weight": 0.30, "evidence": {...}, "reasoning": "..." },
    "self_sufficiency": { "score": 4, "weight": 0.25, "evidence": {...}, "reasoning": "..." },
    "completeness": { "score": 3, "weight": 0.20, "evidence": {...}, "reasoning": "..." },
    "specificity": { "score": 4, "weight": 0.15, "evidence": {...}, "reasoning": "..." },
    "no_overlap": { "score": 5, "weight": 0.10, "evidence": {...}, "reasoning": "..." }
  },
  "overall": { "weighted_score": 0.81, "recommendation": "FAIL" }
}
```

---

## P2: Wire Testing into Skill Generation Workflow

**File:** `.claude/agents/cogworks.md`

Replace Step 6 (manual checklist at lines 80-92) with automated validation:

```
Step 6: Validate Generated Output (Automated)

1. Run Layer 1:
   bash .claude/test-framework/graders/deterministic-checks.sh .claude/skills/{slug}/ --json
   - If critical failures: fix, re-run (max 1 retry)

2. Run Layer 2 evaluation:
   - Read all skill files + source material from _sources/{topic}/
   - Evaluate each of 5 quality dimensions using rubrics from llm-judge-rubrics.md
   - Compute weighted score

3. If score < 0.85 or any dimension < 3:
   - Identify weakest dimension(s) from evidence
   - Make targeted fixes
   - Re-evaluate (max 1 retry)

4. Report final validation results in Step 7 output
```

Update Step 7 (lines 94-101) to include validation scores in the success confirmation.

The cogworks-learn and cogworks-encode skills are NOT modified — they're knowledge skills. The cogworks agent owns the workflow and the validation step.

---

## P5: Calibration Loop

**Create:** `tests/calibration/` directory with template YAML files for human evaluation:

```yaml
# tests/calibration/{slug}-human.yaml
skill_slug: {slug}
evaluator:
date:
categories:
  source_fidelity: { score: , reasoning: "" }
  self_sufficiency: { score: , reasoning: "" }
  completeness: { score: , reasoning: "" }
  specificity: { score: , reasoning: "" }
  no_overlap: { score: , reasoning: "" }
```

**Modify:** `.claude/test-framework/scripts/calculate-agreement.py` — Update `load_llm_grades` to handle the nested `layer2` format from P1's output.

**Process** (after P1 is implemented):
1. Run `/cogworks-test` on the 3 golden samples
2. User fills in human evaluation YAML files for the same 3 skills
3. Run `calculate-agreement.py` to compare
4. Document rubric adjustments if agreement < 90%

---

## Verification

After all priorities are implemented:

1. **Layer 1:** `bash tests/run-black-box-tests.sh` — all 8 tests pass
2. **Layer 2:** `/cogworks-test cogworks-learn --sources _sources/cogworks-learn/` — produces JSON with 5 dimension scores
3. **Workflow:** Run `cogworks encode` on a test topic — confirm validation step runs automatically and reports scores
4. **Calibration:** `python3 .claude/test-framework/scripts/calculate-agreement.py tests/calibration/ tests/results/` — produces agreement report

## Files Summary

| Action | File | Priority |
|--------|------|----------|
| Modify | `.claude/test-framework/graders/deterministic-checks.sh` | P3 |
| Modify | `tests/test-suite/mvp-test-cases.jsonl` | P4 |
| Delete | 8 test fixture directories | P4 |
| Create | 2 new test fixture directories | P3 |
| Modify | `.claude/skills/cogworks-test/SKILL.md` | P1 |
| Modify | `.claude/skills/cogworks-test/reference.md` | P1 |
| Modify | `.claude/test-framework/graders/llm-judge-rubrics.md` | P1 |
| Modify | `.claude/agents/cogworks.md` | P2 |
| Modify | `TESTING.md` | P4 |
| Modify | `.claude/test-framework/scripts/calculate-agreement.py` | P5 |
| Create | `tests/calibration/` with template files | P5 |
