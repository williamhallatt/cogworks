# Cogworks Testing Framework

Automated validation system for cogworks-generated skills using layered grading methodology.

## Overview

The cogworks testing framework validates that generated skills meet quality requirements through three evaluation layers:

1. **Layer 1: Deterministic checks** (~5 sec, ~$0.00001) - Fast structural validation
2. **Layer 2: LLM-as-judge** (~45 sec, ~$1.50) - Content quality assessment
3. **Layer 3: Human review** (optional, ~20 min, ~$100) - Calibration and disputes

## Quick Start

### Test a Skill

```bash
# Basic validation
/cogworks-test deployment-skill

# With JSON output
/cogworks-test deployment-skill --json

# Compare against golden sample
/cogworks-test deployment-skill --compare-against tests/datasets/golden-samples/deployment-skill/
```

### Generate Skill with Testing

```bash
# Integrated workflow (creates + tests)
@cogworks encode _sources/my-topic/ --test
```

### Test All Golden Samples

```bash
# Regression test suite
for sample in tests/datasets/golden-samples/*/; do
    slug=$(basename "$sample")
    /cogworks-test "$slug" --compare-against "$sample"
done
```

## Directory Structure

```
.claude/test-framework/
├── graders/
│   ├── deterministic-checks.sh     # Layer 1 bash script (thresholds documented inline)
│   ├── llm-judge-rubrics.md        # Layer 2 evaluation rubrics
│   └── human-review-guide.md       # Layer 3 calibration guide
├── templates/
│   ├── test-case-template.jsonl    # Example test case formats
│   └── validation-report.md        # Report template (Handlebars)
└── README.md                        # This file

tests/
├── datasets/
│   ├── golden-samples/              # Known-good skills for regression
│   │   └── deployment-skill/
│   │       ├── sources/             # Original source files
│   │       ├── expected-synthesis.md
│   │       ├── expected-skill/      # Expected SKILL.md, etc.
│   │       ├── test-cases.jsonl
│   │       └── metadata.yaml
│   ├── negative-controls/           # Should fail or warn
│   │   ├── insufficient-sources/
│   │   └── overlapping-builtin/
│   └── edge-cases/                  # Boundary conditions
├── results/                         # Test outputs (timestamped, gitignored)
└── calibration/                     # Human grades for LLM validation
```

## Configuration

All Layer 1 thresholds are documented inline in the `deterministic-checks.sh` script header. There is no external config file — the script is the single source of truth for all deterministic check values.

To adjust thresholds, edit the script directly and run the meta-test suite to verify changes:

```bash
bash tests/run-black-box-tests.sh
```

## Quality Requirements

Skills must meet these criteria (from CLAUDE.md):

| Dimension        | Weight | Description                                    |
| ---------------- | ------ | ---------------------------------------------- |
| Source Fidelity  | 30%    | Accurately represents sources, no fabrication  |
| Self-Sufficiency | 25%    | Understandable without external context        |
| Completeness     | 20%    | Covers stated scope thoroughly                 |
| Specificity      | 15%    | Actionable patterns with when/why/how          |
| No Overlap       | 10%    | Novel value beyond Claude's built-in knowledge |

**Pass threshold**: Overall score ≥ 0.85 AND zero critical failures

## Layered Grading

### Layer 1: Deterministic Checks

**Purpose**: Catch structural issues instantly before expensive LLM calls

**Checks**:

- SKILL.md exists
- Frontmatter is valid YAML
- Required fields present (name, description)
- Line count ≤ 500
- Citations present
- No forbidden patterns (API keys, TODOs)
- Supporting files follow 3+ entry rule
- Markdown syntax valid

**Usage**:

```bash
bash .claude/test-framework/graders/deterministic-checks.sh .claude/skills/my-skill
```

**Exit codes**:

- `0` = All checks passed
- `1` = Critical failure (blocks Layer 2)
- `2` = Warnings only (proceed to Layer 2)

### Layer 2: LLM-as-Judge

**Purpose**: Evaluate content quality using Claude Opus 4.6

**Categories** (see `graders/llm-judge-rubrics.md` for full rubrics):

1. **Source Fidelity** (30%) - Traceability, no fabrication, contradictions flagged
2. **Self-Sufficiency** (25%) - Standalone understanding, terms defined
3. **Completeness** (20%) - Scope coverage, source utilization
4. **Specificity** (15%) - Actionable patterns with examples
5. **No Overlap** (10%) - Novel value beyond built-ins

**Each category scored 1-5**, then weighted average computed:

```python
weighted_score = (
    source_fidelity * 0.30 +
    self_sufficiency * 0.25 +
    completeness * 0.20 +
    specificity * 0.15 +
    no_overlap * 0.10
) / 5.0
```

**Model configuration**:

- Model: `claude-opus-4-6`
- Temperature: `0.0` (deterministic)
- Cost: ~$1.50 per skill
- Duration: ~45 seconds

### Layer 3: Human Review (Optional)

**Purpose**: Calibrate LLM-judge accuracy, resolve disputes

**When to use**:

- Calibration (20 skills, quarterly)
- Spot checks (after rubric changes)
- Disputes (user disagrees with score)

**Process**:

1. Expert evaluates using same rubrics
2. Records scores in `tests/calibration/`
3. Compare with LLM scores
4. Measure agreement (target: 90%+)
5. Adjust rubrics if systematic biases found

See `graders/human-review-guide.md` for full process.

## Test Datasets

### Golden Samples

Known-good skills that should always pass. Use for:

- Regression testing after framework changes
- Calibration reference
- Training examples

**Creating a golden sample**:

1. Create directory: `tests/datasets/golden-samples/{slug}/`
2. Add source files: `sources/*.md`
3. Generate skill normally: `@cogworks encode sources/`
4. Copy to expected-skill: `cp -r .claude/skills/{slug}/ expected-skill/`
5. Create metadata.yaml with expected scores
6. Create test-cases.jsonl
7. Run test: `/cogworks-test {slug} --compare-against golden-samples/{slug}/`

### Negative Controls

Intentionally flawed scenarios that should fail/warn:

- **insufficient-sources** - Too sparse, should warn
- **overlapping-builtin** - Generic content, should suggest reconsidering
- **no-citations** - Missing citations, should fail
- **contradictory-only** - Sources only contradict, should flag

**Purpose**: Validate that testing can identify problems, not just pass everything.

### Edge Cases

Boundary conditions:

- Single source skill
- Large source set (5+ files)
- Minimal content skill
- Very long SKILL.md (approaching 500 lines)

## Validation Reports

Tests generate two outputs:

### JSON (Machine-Readable)

```json
{
  "skill_slug": "deployment-skill",
  "timestamp": "2026-02-14T10:30:00Z",
  "overall_score": 0.87,
  "recommendation": "PASS",
  "categories": { ... },
  "critical_failures": [],
  "warnings": ["Minor undefined term: CORS"]
}
```

Saved to: `tests/results/{timestamp}/{slug}-results.json`

### Markdown (Human-Readable)

Comprehensive report with:

- Summary and recommendation
- Deterministic check results
- LLM-judge scores by category
- Source fidelity deep dive
- Actionable recommendations

Saved to: `tests/results/{timestamp}/{slug}-report.md`

## Calibration

### Running Calibration

1. **Select 20 skills** across quality spectrum:
   - 5 excellent (≥4.5)
   - 10 good (3.5-4.5)
   - 3 marginal (3.0-3.5)
   - 2 failing (<3.0)

2. **Human evaluation**:

   ```bash
   # Use guide to evaluate each skill
   # Record in tests/calibration/{slug}-human.yaml
   ```

3. **LLM evaluation**:

   ```bash
   for skill in {list}; do
       /cogworks-test "$skill"
   done
   ```

4. **Measure agreement**:

   ```bash
   python3 scripts/calculate-agreement.py \
       tests/calibration/*-human.yaml \
       tests/results/latest/*-results.json
   ```

5. **Target**: 90%+ agreement (within 0.5 points on 5-point scale)

6. **If below target**:
   - Identify systematic biases
   - Update rubrics
   - Re-test on subset
   - Document changes

### Known Biases

- **Verbosity preference**: LLM may favor longer content
- **Position bias**: First items may score higher
- **Leniency**: May be reluctant to give low scores
- **Recency**: May weight recent capabilities more

See `graders/llm-judge-rubrics.md` for mitigation strategies.

## Cost and Performance

### Per-Skill Test Run

| Layer                   | Duration | Cost      |
| ----------------------- | -------- | --------- |
| Layer 1 (deterministic) | ~5 sec   | ~$0.00001 |
| Layer 2 (LLM-judge)     | ~45 sec  | ~$1.50    |
| Layer 3 (human)         | ~20 min  | ~$100     |

**Typical test**: Layer 1 + Layer 2 = ~50 seconds, ~$1.50

**Cost savings from layered grading**:

- 20% of skills have critical failures
- Skipping Layer 2 saves $1.50 × 20% = $0.30 per skill on average

### Batch Testing

```bash
# Test 10 golden samples
# Total: ~8 minutes, ~$15
```

## Troubleshooting

### Tests Taking Too Long

**Check**: Is Layer 1 slow?

```bash
time bash .claude/test-framework/graders/deterministic-checks.sh .claude/skills/my-skill
```

**Solution**: Should be <5 seconds. If slower, optimize bash script.

**Check**: Is Layer 2 slow?
**Solution**: Should be ~45 seconds. If slower, check Claude API latency.

### False Positives

**Issue**: Skill should pass but fails deterministic check
**Solution**: Review check logic in `graders/deterministic-checks.sh`, add exception for valid pattern

**Issue**: LLM-judge score seems wrong
**Solution**: Run human evaluation, compare with LLM, adjust rubric if systematic bias

### All Skills Failing

**Check**: Are thresholds too strict?
**Solution**: Review `config/framework-config.yaml`, consider lowering `thresholds.overall_minimum`

**Check**: Is rubric biased?
**Solution**: Run calibration to validate LLM-judge accuracy

### Critical Failure on Valid Skill

**Check**: What's the failure?

```bash
bash .claude/test-framework/graders/deterministic-checks.sh .claude/skills/my-skill
```

**Common causes**:

- Citation format not recognized (update pattern in script)
- Supporting file has 2 entries (should fold into reference.md)
- SKILL.md exactly 500 lines (increase tolerance)

## Integration

### With Cogworks Workflow

Automatically invoked when user runs:

```bash
@cogworks encode <sources> --test
```

See `.claude/agents/cogworks.md` Step 6.5 for implementation.

### With CI/CD (Future)

```yaml
# .github/workflows/test-skills.yml
on: [push]
jobs:
  test-golden-samples:
    runs-on: ubuntu-latest
    steps:
      - checkout
      - run: |
          for sample in tests/datasets/golden-samples/*/; do
            /cogworks-test $(basename $sample) --compare-against $sample
          done
```

## Extending the Framework

### Adding New Checks

**Deterministic checks**:

1. Add function to `graders/deterministic-checks.sh`
2. Call in `run_all_checks()`
3. Use `log_critical()` or `log_warning()`
4. Test with known-good and known-bad samples

**LLM-judge rubrics**:

1. Define new category in `graders/llm-judge-rubrics.md`
2. Create 5-point scale with anchors
3. Write evaluation prompt
4. Add weight to `config/framework-config.yaml`
5. Run calibration to validate

### Adding Golden Samples

1. Create directory structure
2. Add source files
3. Generate skill
4. Create metadata.yaml
5. Create test-cases.jsonl
6. Validate: `/cogworks-test {slug} --compare-against golden-samples/{slug}/`

### Creating Negative Controls

1. Create flawed source material
2. Define expected outcome in expected-outcome.yaml
3. Create test cases
4. Validate that framework correctly identifies the flaw

## References

- **CLAUDE.md** - Quality requirements and platform limitations
- **ROADMAP.md Section 3** - Testing strategy requirements
- **skill-evaluation skill** - Eval-driven development methodology
- **cogworks-learn skill** - Skill structure requirements

## Support

Report issues: <https://github.com/anthropics/claude-code/issues>

---

_Framework version: 1.0.0_
_Last updated: 2026-02-15_
