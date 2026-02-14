# Testing Examples

Concrete examples of cogworks-test skill usage and test execution scenarios.

## Example 1: Basic Skill Validation

**Scenario**: Validate a newly generated deployment skill

```bash
# User invocation
/cogworks-test deployment-skill
```

**What happens**:

1. **Locate skill**:

```bash
SKILL_PATH=".claude/skills/deployment-skill"
# Verifies directory exists, contains SKILL.md
```

2. **Layer 1 - Deterministic checks** (~5 seconds):

```bash
bash .claude/test-framework/graders/deterministic-checks.sh \
    "$SKILL_PATH" --json
```

Output:

```json
{
  "critical_failures": [],
  "warnings": ["Description is very short (8 words)"],
  "checks_passed": [
    "SKILL.md exists",
    "Frontmatter is valid YAML",
    "Required frontmatter fields present",
    "Line count within limit (287/500)",
    "Citations present (15 found)",
    "No forbidden patterns",
    "Supporting files follow 3+ entry rule",
    "No duplicate headers",
    "Markdown syntax valid"
  ],
  "status": "pass"
}
```

3. **Layer 2 - LLM-as-judge** (~45 seconds):

For each category, evaluate using rubrics:

Source Fidelity:

```json
{
  "score": 5,
  "traceability_percentage": 0.97,
  "claims_analyzed": 10,
  "claims_traceable": 10,
  "fabrications_found": [],
  "contradictions_flagged": true,
  "reasoning": "All sampled claims traceable to sources. Source disagreement on rollback timing explicitly flagged."
}
```

Self-Sufficiency:

```json
{
  "score": 4,
  "undefined_terms": ["CORS"],
  "context_dependencies": [],
  "self_contained_percentage": 0.95,
  "reasoning": "Mostly self-contained. One undefined acronym (CORS) but inferable from context."
}
```

(Similar for Completeness, Specificity, No Overlap...)

4. **Weighted score**:

```
(5 × 0.30) + (4 × 0.25) + (4 × 0.20) + (4 × 0.15) + (5 × 0.10) = 4.40/5.0
Overall: 0.88/1.0
```

5. **Result reported to user**:

```
✅ Skill validation PASSED

Overall score: 0.88/1.0 (target: ≥0.85)
Weighted score: 4.40/5.0

Category scores:
- Source Fidelity: 5/5 ✓
- Self-Sufficiency: 4/5 ✓
- Completeness: 4/5 ✓
- Specificity: 4/5 ✓
- No Overlap: 5/5 ✓

Warnings (2):
- Description is very short (8 words) - add keywords
- Minor undefined term: CORS

Full report: tests/results/2026-02-14-103045/deployment-skill-report.md
JSON output: tests/results/2026-02-14-103045/deployment-skill-results.json
```

---

## Example 2: Skill Fails Validation

**Scenario**: Skill has no source citations (critical failure)

```bash
/cogworks-test buggy-skill
```

**Layer 1 output**:

```json
{
  "critical_failures": [
    "No source citations found",
    "SKILL.md exceeds 500 lines (612 lines)"
  ],
  "warnings": [],
  "checks_passed": [...],
  "status": "fail"
}
```

**Decision**: Stop here, don't run Layer 2 (save $1.50)

**Result reported to user**:

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
/cogworks-test buggy-skill

Full report: tests/results/2026-02-14-104312/buggy-skill-report.md
```

---

## Example 3: Golden Sample Regression Test

**Scenario**: Verify deployment-skill still passes after framework changes

```bash
/cogworks-test deployment-skill \
    --compare-against tests/datasets/golden-samples/deployment-skill/
```

**What happens**:

1. Load expected outcomes from `metadata.yaml`:

```yaml
expected_scores:
  overall_score: 0.87
  source_fidelity: 5
  self_sufficiency: 4
  completeness: 4
  specificity: 4
  no_overlap: 5

expected_structure:
  skill_md_lines: 287
  patterns_md_entries: 5
  examples_md_entries: 4
```

2. Run full validation (Layer 1 + Layer 2)

3. Compare actual vs expected:

```python
def compare_with_tolerance(actual, expected, tolerance=0.05):
    if abs(actual - expected) / expected > tolerance:
        return False  # Deviation exceeds 5%
    return True
```

4. Report result:

```
✅ Golden sample regression test PASSED

Comparison with expected (tolerance: 5%):
- Overall score: 0.88 vs 0.87 expected (1.1% diff) ✓
- Source Fidelity: 5/5 (exact match) ✓
- Self-Sufficiency: 4/5 (exact match) ✓
- Completeness: 4/5 (exact match) ✓
- Specificity: 4/5 (exact match) ✓
- No Overlap: 5/5 (exact match) ✓
- SKILL.md lines: 287 (exact match) ✓

No regressions detected.
```

---

## Example 4: Testing All Golden Samples

**Scenario**: Validate framework changes don't break any known-good skills

```bash
# Shell script or manual commands
for sample in tests/datasets/golden-samples/*/; do
    slug=$(basename "$sample")
    echo "Testing $slug..."
    /cogworks-test "$slug" --compare-against "$sample"
done
```

**Output**:

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

**Scenario**: Verify framework correctly identifies insufficient sources

```bash
# This should produce a warning or suggestion to reconsider
@cogworks encode tests/datasets/negative-controls/insufficient-sources/ --test
```

**Expected outcome** (from `expected-outcome.yaml`):

```yaml
should_warn: true
warning_type: "insufficient_sources"
message_contains: "source material is too sparse"
should_proceed: false
```

**Actual validation**:

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

**Test assertion**:

```python
def test_insufficient_sources_negative_control():
    result = validate_synthesis("tests/datasets/negative-controls/insufficient-sources/")

    assert result["warnings"]
    assert any("sparse" in w.lower() for w in result["warnings"])
    assert result["recommendation"] == "RECONSIDER"
```

✅ Negative control correctly identified issue

---

## Example 6: Calibration Workflow

**Scenario**: Validate LLM-judge accuracy against human evaluation

**Step 1: Human evaluation** (using human-review-guide.md)

```bash
# Expert evaluates 20 skills manually
# Records scores in calibration/human-grades/
deployment-skill-human.yaml
testing-skill-human.yaml
...
```

**Step 2: LLM evaluation**

```bash
# Run automated grading on same 20 skills
for skill in deployment-skill testing-skill ...; do
    /cogworks-test "$skill" --save-grades-to calibration/llm-grades/
done
```

**Step 3: Compare agreement**

```bash
# Python script to calculate agreement
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

Disagreements:
1. api-design-skill:
   - Human Completeness: 3
   - LLM Completeness: 4
   - Diff: +1.0 (LLM too lenient)

2. security-skill:
   - Human Completeness: 4
   - LLM Completeness: 5
   - Diff: +1.0 (LLM too lenient)

Systematic bias detected:
- Completeness: LLM scores 0.5-1.0 higher than human in 60% of cases
- Cause: LLM focuses on quantity over quality of coverage

Recommendations:
1. Update Completeness rubric to emphasize meaningful coverage
2. Add examples of "high quantity, low quality" in rubric
3. Re-test on 10-skill subset

Status: NEEDS_RECALIBRATION (target: 90%+)
```

**Step 4: Adjust rubrics and re-test**

```markdown
# Update to completeness rubric

**3 - Adequate**:

- 75%+ scope covered
- Some gaps present
- Reasonable source coverage

* Coverage addresses user needs (not just quantity) # NEW
* Focus on meaningful synthesis, not just including everything # NEW
```

---

## Example 7: Integration with Cogworks Workflow

**Scenario**: User generates skill with --test flag

```bash
# User command
@cogworks encode _sources/deployment-workflows/ --test
```

**What happens**:

1. **Cogworks agent** runs normal workflow:
   - Encode sources → synthesis
   - Learn skill → generate SKILL.md
   - Validate output

2. **Step 6.5** (from cogworks.md): Optional testing
   - Detects --test flag
   - Invokes /cogworks-test deployment-workflows

3. **Test results** included in confirmation:

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

Ready to use:
/deployment-workflows <your-request>
```

---

## Example 8: Debugging a Failed Test

**Scenario**: Test fails unexpectedly, need to understand why

```bash
/cogworks-test api-design-skill --json
```

**JSON output** saved to `tests/results/latest/api-design-skill-results.json`:

```json
{
  "overall_score": 0.72,
  "recommendation": "FAIL",
  "categories": {
    "source_fidelity": {
      "score": 3,
      "traceability_percentage": 0.82,
      "claims_analyzed": 10,
      "claims_traceable": 8,
      "fabrications_found": [
        "Always use PUT for updates (not found in sources)",
        "DELETE should return 204 No Content (contradicted by source B)"
      ],
      "reasoning": "Multiple fabricated claims not supported by sources."
    }
  }
}
```

**Debugging steps**:

1. **Read the skill** to find the fabricated claims:

```bash
grep -n "Always use PUT" .claude/skills/api-design-skill/SKILL.md
# Line 124: "Always use PUT for updates"
```

2. **Check sources** to verify claim:

```bash
grep -r "PUT" _sources/api-design-skill/
# No mention of PUT in sources
```

3. **Identify root cause**: Synthesis introduced opinion not from sources

4. **Fix**: Update synthesis to only include source-backed claims

5. **Re-test**:

```bash
/cogworks-test api-design-skill
# ✅ Now passes with score 0.86
```

---

## Example 9: Cost and Performance Benchmarks

**Test run statistics** for typical skill:

```
Skill: deployment-skill (287 lines, 3 supporting files)
Sources: 4 files (~2000 words)

Layer 1 (Deterministic):
- Duration: 4.2 seconds
- Cost: $0.00001
- Checks passed: 9/10
- Warnings: 1
- Critical failures: 0

Layer 2 (LLM-as-Judge):
- Duration: 43 seconds
- Cost: $1.48
- Model: claude-opus-4-6
- Token usage: ~8000 tokens
- Categories evaluated: 5

Total:
- Duration: 47.2 seconds
- Cost: $1.48
- Status: PASS
- Score: 0.88/1.0

Files generated:
- tests/results/2026-02-14-112034/deployment-skill-results.json (12 KB)
- tests/results/2026-02-14-112034/deployment-skill-report.md (8 KB)
```

**Cost savings** from layered grading:

- If skill has critical failures → Layer 2 skipped, saves $1.48
- Across 100 skills with 20% critical failure rate → saves $29.60
