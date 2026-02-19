# Testing Examples

Concrete examples of cogworks-test skill usage and test execution scenarios.

## Example 1: Basic Skill Validation (Codex)

**Scenario**: Validate a newly generated deployment skill.

```bash
/cogworks-test deployment-skill --layer1-only
```

Layer 1 runs deterministic checks (~5 seconds), finds no critical failures but warns about a short description. Layer 2 is skipped in the default Codex workflow.

```
✅ Skill validation PASSED

Layer 2 (LLM-as-judge) was skipped (Codex default).

Warnings (2):
- Description is very short (8 words) - add keywords
- Minor undefined term: CORS

JSON output: tests/results/2026-02-14-103045/deployment-skill-results.json
```

---

## Example 2: Skill Fails Validation (Codex)

**Scenario**: Skill has critical structural issues (no citations, exceeds line limit).

```bash
/cogworks-test buggy-skill --layer1-only
```

Layer 1 detects critical failures — Layer 2 is skipped entirely:

```
❌ Skill validation FAILED

Critical failures (2):
- No source citations found
- SKILL.md exceeds 500 lines (612 lines)

Layer 2 (LLM-as-judge) was skipped due to critical failures.

Recommendations:
1. Add citations to all claims (see cogworks-encode guidance)
2. Move content to supporting files:
   - Extract patterns to patterns.md
   - Extract examples to examples.md
   - Keep SKILL.md ≤500 lines

Re-run validation after fixes:
/cogworks-test buggy-skill --layer1-only
```

---

## Example 3: Golden Sample Regression Test (Advanced)

**Scenario**: Verify deployment-skill still passes after framework changes.

```bash
/cogworks-test deployment-skill \
    --compare-against tests/datasets/golden-samples/deployment-skill/
```

Loads expected scores from `metadata.yaml`, runs full validation, then compares with 5% tolerance. This relies on Layer 2 and is not part of the default Codex workflow.

```
✅ Golden sample regression test PASSED

Comparison with expected (tolerance: 5%):
- Overall score: 0.88 vs 0.87 expected (1.1% diff) ✓
- Source Fidelity: 5/5 (exact match) ✓
- Self-Sufficiency: 4/5 (exact match) ✓
- Completeness: 4/5 (exact match) ✓
- Specificity: 4/5 (exact match) ✓
- No Overlap: 5/5 (exact match) ✓

No regressions detected.
```

---

## Example 4: Testing All Golden Samples (Advanced)

**Scenario**: Batch validation after framework changes.

```bash
for sample in tests/datasets/golden-samples/*/; do
    slug=$(basename "$sample")
    echo "Testing $slug..."
    /cogworks-test "$slug" --compare-against "$sample"
done
```

```
Testing deployment-skill...
✅ PASSED (score: 0.88, no regressions)

Testing testing-skill...
✅ PASSED (score: 0.86, no regressions)

Testing api-design-skill...
❌ FAILED (score: 0.82, below threshold)
  - Completeness dropped from 4 to 3
  - INVESTIGATE: framework change may have broken evaluation

Overall: 2/3 golden samples passed
```

---

## Example 5: Negative Control Validation

**Scenario**: Verify framework correctly identifies insufficient sources.

```bash
@cogworks encode tests/datasets/negative-controls/insufficient-sources/ --test
```

**Expected outcome** (from `expected-outcome.yaml`):

```yaml
should_warn: true
warning_type: "insufficient_sources"
message_contains: "source material is too sparse"
should_proceed: false
```

**Actual result**:

```
⚠ Warning: Insufficient Source Material

The provided sources contain only 1 paragraph (~50 words).
This is likely too sparse to create a useful skill.

Recommendations:
1. Add more comprehensive source material (target: 2-5 pages)
2. Consider if this topic needs a dedicated skill
3. May be better handled by Claude's built-in knowledge

Proceed anyway? (not recommended)
```

Negative control correctly identified the issue.

---

## Example 6: Calibration Workflow

**Scenario**: Validate LLM-judge accuracy against human evaluation.

**Step 1**: Expert evaluates 20 skills manually using rubrics from `human-review-guide.md`.

**Step 2**: Run automated grading on same 20 skills:

```bash
for skill in deployment-skill testing-skill ...; do
    /cogworks-test "$skill" --save-grades-to calibration/llm-grades/
done
```

**Step 3**: Compare agreement:

```bash
python3 .claude/test-framework/scripts/calculate-agreement.py \
    calibration/human-grades/ \
    calibration/llm-grades/
```

**Output**:

```
=== LLM-Judge Calibration Report ===

Skills evaluated: 20
Overall agreement: 91% (18/20 within 0.5 points)

Agreement by category:
- Source Fidelity: 95% (19/20)
- Self-Sufficiency: 90% (18/20)
- Completeness: 85% (17/20) ⚠️
- Specificity: 95% (19/20)
- No Overlap: 90% (18/20)

Systematic bias detected:
- Completeness: LLM scores 0.5-1.0 higher than human in 60% of cases
- Cause: LLM focuses on quantity over quality of coverage

Recommendations:
1. Update Completeness rubric to emphasize meaningful coverage
2. Add examples of "high quantity, low quality" in rubric
3. Re-test on 10-skill subset

Status: NEEDS_RECALIBRATION (target: 90%+)
```

---

## Example 7: Integration with Cogworks Workflow

**Scenario**: User generates skill with `--test` flag for automatic validation.

```bash
@cogworks encode _sources/deployment-workflows/ --test
```

Cogworks runs encode → learn → test automatically. Results included in confirmation:

```
✅ Skill created: deployment-workflows

Files generated:
- .claude/skills/deployment-workflows/SKILL.md (287 lines)
- .claude/skills/deployment-workflows/patterns.md (5 entries)
- .claude/skills/deployment-workflows/examples.md (4 entries)

Validation results:
✅ All tests passed (score: 0.88/1.0)
- Source Fidelity: 5/5
- Self-Sufficiency: 4/5
- Completeness: 4/5
- Specificity: 4/5
- No Overlap: 5/5

⚠ Minor warnings (2):
- Add more keywords to description for discoverability
- Define acronym: CORS

Full test report: tests/results/2026-02-14-111523/deployment-workflows-report.md
```

---

## Example 8: Debugging a Failed Test

**Scenario**: Test fails unexpectedly, need to understand why.

```bash
/cogworks-test api-design-skill --json
```

JSON output reveals source fidelity issues:

```json
{
  "overall_score": 0.72,
  "recommendation": "FAIL",
  "categories": {
    "source_fidelity": {
      "score": 3,
      "traceability_percentage": 0.82,
      "fabrications_found": [
        "Always use PUT for updates (not found in sources)",
        "DELETE should return 204 No Content (contradicted by source B)"
      ]
    }
  }
}
```

**Debugging steps**:

1. Find the fabricated claims in the skill file
2. Check sources to verify — confirm claims aren't supported
3. Root cause: synthesis introduced opinions not from sources
4. Fix: update synthesis to only include source-backed claims
5. Re-test: `/cogworks-test api-design-skill` → now passes with 0.86
