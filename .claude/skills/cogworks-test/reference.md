# Reference: Cogworks Testing Framework

Complete methodology for validating cogworks-generated skills through eval-driven development.

## TL;DR

The cogworks testing framework validates skills through three-layer grading: fast deterministic checks ($0.00001, 5 seconds) catch structural issues; LLM-as-judge ($1.50, 45 seconds) evaluates five weighted quality dimensions (source fidelity 30%, self-sufficiency 25%, completeness 20%, specificity 15%, no overlap 10%); optional human review ($100, 20 minutes) calibrates judge accuracy. Success requires overall score ≥0.85 with zero critical failures. Golden samples provide regression testing, negative controls validate failure detection. The framework integrates with cogworks workflow via `--test` flag and generates machine-readable JSON plus human-readable Markdown reports.

## Table of Contents

1. Core Concepts
2. Complete Testing Workflow
3. Quality Dimension Rubrics
4. Layer 1: Deterministic Checks
5. Layer 2: LLM-as-Judge
6. Layer 3: Human Calibration
7. Test Data Organization
8. Configuration Reference
9. Integration with Cogworks
10. Troubleshooting Guide
11. Cost and Performance
12. Deep Dives
13. Quick Reference
14. Sources

## Core Concepts

1. **Layered Grading** - Progressive evaluation: cheap deterministic checks (Layer 1) gate expensive LLM evaluation (Layer 2), with optional human review (Layer 3) for calibration. Prevents waste by filtering obviously-failing skills early.

2. **Quality Dimensions** - Five measurable aspects scored 1-5 and combined using weights: source fidelity, self-sufficiency, completeness, specificity, no overlap. See [Quality Dimension Rubrics](#quality-dimension-rubrics).

3. **Critical Failures** - Structural issues that immediately fail a skill regardless of content quality. Any critical failure stops evaluation at Layer 1. See [Configuration Reference](#configuration-reference) for the full list.

4. **LLM-as-Judge** - Using Claude to evaluate skill quality against structured rubrics. Faster and cheaper than human review but requires calibration to ensure reliability. Known biases include verbosity preference, position bias, and leniency.

5. **Golden Samples** - Known-good skills with documented expected outcomes used for regression testing. Each includes sources, expected synthesis, expected skill structure, and test cases.

6. **Negative Controls** - Test inputs designed to fail validation, verifying the framework correctly detects quality issues. Types: insufficient sources, overlapping builtin knowledge, structural violations.

7. **Weighted Scoring** - Combining quality dimensions using importance weights rather than simple averaging. Overall score = weighted sum / 5.0. See [Configuration Reference](#configuration-reference) for weights.

8. **Test Reports** - Dual-format output: JSON for automation/CI/CD and Markdown for human review. Both generated simultaneously with consistent data.

9. **Calibration** - Validating LLM-judge accuracy by comparing automated grades against human expert grades. Target: within 0.5 points on 5-point scale for 90%+ of skills.

10. **Framework Configuration** - Central YAML file defining all thresholds, weights, and tuning parameters. See [Configuration Reference](#configuration-reference).

## Complete Testing Workflow

### Step 1: Locate Skill

Resolve skill slug to filesystem path and verify skill exists.

```bash
SKILL_SLUG="deployment-skill"
SKILL_PATH=".claude/skills/${SKILL_SLUG}"

if [ ! -d "$SKILL_PATH" ] || [ ! -f "$SKILL_PATH/SKILL.md" ]; then
    echo "Error: Skill not found at $SKILL_PATH"
    exit 1
fi
```

### Step 2: Load Configuration

Read thresholds, weights, and critical failure definitions from `.claude/test-framework/config/framework-config.yaml`. See [Configuration Reference](#configuration-reference) for complete structure.

### Step 3: Run Layer 1 (Deterministic Checks)

Execute bash script that validates structure and syntax without LLM calls.

```bash
bash .claude/test-framework/graders/deterministic-checks.sh "$SKILL_PATH" --json > layer1-results.json

LAYER1_STATUS=$(jq -r '.status' layer1-results.json)
CRITICAL_FAILURES=$(jq -r '.critical_failures | length' layer1-results.json)

if [ "$LAYER1_STATUS" = "fail" ] || [ "$CRITICAL_FAILURES" -gt 0 ]; then
    echo "❌ Layer 1 FAILED - Critical issues detected"
    jq -r '.critical_failures[]' layer1-results.json
    echo "Fix critical failures before proceeding to Layer 2"
    exit 1
fi
```

**Output format**:

```json
{
  "status": "pass",
  "critical_failures": [],
  "warnings": ["Minor undefined term: CORS"],
  "checks_passed": 12,
  "checks_total": 13,
  "duration_seconds": 4.2
}
```

### Step 4: Run Layer 2 (LLM-as-Judge)

Only runs if Layer 1 passed. For each quality dimension, load the rubric from `llm-judge-rubrics.md`, construct an evaluation prompt with skill content and source material, call Claude API, and parse the structured JSON response.

**Scoring formula**:

```python
scores = {dim: evaluate(dim) for dim in DIMENSIONS}

# Apply weights from framework-config.yaml
weighted_score = sum(scores[dim] * weights[dim] for dim in scores)
overall_score = weighted_score / 5.0  # Normalize to 0-1

# Example: (5×0.30 + 4×0.25 + 4×0.20 + 4×0.15 + 5×0.10) / 5.0 = 0.88
```

### Step 5: Generate Validation Report

Create dual-format output. Save both to `tests/results/{timestamp}/{skill-slug}-{results.json,report.md}`.

**JSON** contains: overall_score, weighted_score, recommendation (PASS/FAIL), critical_failures, warnings, layer_1 results, layer_2 per-dimension scores with reasoning.

**Markdown** uses template from `.claude/test-framework/templates/validation-report.md` with narrative explanations, score table, per-dimension reasoning, and recommendations.

### Step 6: Report Results

**If PASS** (overall_score ≥ 0.85 AND no critical failures):

```
✅ Skill validation PASSED

Overall score: 0.88/1.0 (target: ≥0.85)
Weighted score: 4.4/5.0

Category scores:
- Source Fidelity: 5/5 ✓
- Self-Sufficiency: 4/5 ✓
- Completeness: 4/5 ✓
- Specificity: 4/5 ✓
- No Overlap: 5/5 ✓

Warnings (1):
- Minor undefined term: CORS

Full report: tests/results/2026-02-14T10-30-00Z/deployment-skill-report.md
```

**If FAIL** (overall_score < 0.85 OR any critical failures):

```
❌ Skill validation FAILED

Overall score: 0.72/1.0 (target: ≥0.85)

Critical failures (2):
- No source citations found
- SKILL.md exceeds 500 lines (612 lines)

Category scores:
- Source Fidelity: 2/5 ✗ (fabrication detected)
- Self-Sufficiency: 4/5 ✓
- Completeness: 3/5 ⚠ (gaps in scope coverage)
- Specificity: 4/5 ✓
- No Overlap: 5/5 ✓

Recommendations:
1. Add citations to all claims (see llm-judge-rubrics.md)
2. Move detailed content to reference.md to reduce SKILL.md size
3. Address fabricated claims in sections: [list sections]
```

## Quality Dimension Rubrics

### Source Fidelity (Weight: 0.30)

**Definition**: Accuracy and traceability of claims to source material.

**5 - Exceptional**: Every claim cited, contradictions flagged, synthesis preserves nuance, no fabrication, consistent citation format.

**4 - Strong**: 95%+ claims traceable, contradictions noted, minor omissions acceptable, rare citation inconsistencies.

**3 - Adequate**: 85%+ claims traceable, most contradictions noted, some synthesis gaps, mostly consistent citations.

**2 - Weak**: <85% claims traceable, contradictions missed, noticeable fabrication, poor citation practices.

**1 - Failing**: Significant fabrication, missing citations throughout, contradictions ignored, cannot verify claims.

**Evaluation Process**:

1. Sample 10 specific claims randomly
2. Trace each back to source material using citations
3. Check if source disagreements are explicitly noted
4. Calculate traceability percentage
5. Note fabrications not supported by sources

**Output Format**:

```json
{
  "score": 1-5,
  "traceability_percentage": 0.0-1.0,
  "claims_analyzed": 10,
  "claims_traceable": 9,
  "fabrications_found": ["claim about feature X not in sources"],
  "contradictions_flagged": true,
  "reasoning": "95% claims traceable with one minor fabrication"
}
```

### Self-Sufficiency (Weight: 0.25)

**Definition**: Can the skill be understood and applied without external context?

**5 - Exceptional**: Complete standalone understanding, all terms defined, no external dependencies.

**4 - Strong**: Minor context gaps, 95%+ self-contained, rare external references justified.

**3 - Adequate**: Some context assumed, 85%+ self-contained, user can infer gaps.

**2 - Weak**: Frequent context gaps, relies on external knowledge, terms undefined.

**1 - Failing**: Cannot understand without external context, many undefined terms.

**Evaluation Process**:

1. List technical terms/concepts used
2. Check if each is defined or explained in-skill
3. Identify assumptions about user knowledge
4. Note dependencies on external context
5. Test: Could a user with no prior context apply this skill?

**Output Format**:

```json
{
  "score": 1-5,
  "undefined_terms": ["CORS", "CI/CD"],
  "context_dependencies": ["Assumes familiarity with GitHub"],
  "self_contained_percentage": 0.92,
  "reasoning": "Most terms defined, minor context assumptions acceptable"
}
```

### Completeness (Weight: 0.20)

**Definition**: Coverage of stated scope and source material.

**5 - Exceptional**: Stated scope fully covered, 90%+ source material synthesized, no significant gaps.

**4 - Strong**: 85%+ scope covered, minor gaps acceptable, key topics well-covered.

**3 - Adequate**: 75%+ scope covered, some gaps present, main topics addressed.

**2 - Weak**: <75% scope covered, significant gaps, important topics missing.

**1 - Failing**: Incomplete coverage, major sections missing, minimal source usage.

**Evaluation Process**:

1. Identify stated scope from description/TL;DR
2. List main topics in source material
3. Check coverage of each topic in skill
4. Calculate percentage of source material used
5. Note significant gaps or omissions

**Output Format**:

```json
{
  "score": 1-5,
  "scope_coverage_percentage": 0.85,
  "source_coverage_percentage": 0.87,
  "gaps": ["Edge case handling not covered"],
  "reasoning": "85% scope coverage with minor edge case gaps acceptable"
}
```

### Specificity (Weight: 0.15)

**Definition**: Actionability and detail of patterns/guidance.

**5 - Exceptional**: All patterns have when/why/how context, concrete examples throughout, immediately actionable.

**4 - Strong**: 90%+ patterns actionable, minor abstraction acceptable, most have examples.

**3 - Adequate**: 75%+ patterns actionable, some vague guidance, examples present.

**2 - Weak**: <75% actionable, many vague/generic patterns, examples sparse.

**1 - Failing**: Mostly generic advice, no clear patterns, not actionable.

**Evaluation Process**:

1. Count total patterns/guidelines
2. For each, check for: **When** (context), **Why** (reasoning), **How** (steps), **Example**
3. Calculate actionability percentage
4. Note vague or generic patterns

**Output Format**:

```json
{
  "score": 1-5,
  "total_patterns": 15,
  "actionable_patterns": 13,
  "patterns_with_examples": 12,
  "vague_patterns": ["Pattern 7 lacks concrete steps"],
  "reasoning": "87% patterns actionable with clear when/why/how context"
}
```

### No Overlap (Weight: 0.10)

**Definition**: Skill provides novel value beyond Claude's built-in knowledge.

**5 - Exceptional**: Entirely novel content, clear specialized value, unique insights.

**4 - Strong**: 90%+ novel, minor overlap acceptable, specialized knowledge.

**3 - Adequate**: 75%+ novel, some overlap but skill still justified.

**2 - Weak**: <75% novel, significant overlap, questionable value add.

**1 - Failing**: Mostly duplicates built-in knowledge, no clear value add.

**Evaluation Process**:

1. Identify generic content (common best practices, standard definitions)
2. Identify specialized content (org-specific patterns, tool-specific workflows, novel methodologies)
3. Calculate novelty percentage
4. Assess value justification

**Output Format**:

```json
{
  "score": 1-5,
  "novelty_percentage": 0.95,
  "generic_content": ["Section on code review benefits"],
  "specialized_content": ["Deployment workflow specific to infrastructure"],
  "value_justification": "Adds specialized deployment knowledge not in Claude's training",
  "reasoning": "95% novel with organization-specific deployment patterns"
}
```

### Decision Thresholds

- **PASS**: overall_score ≥ 0.85 AND no critical failures
- **FAIL**: overall_score < 0.85 OR any critical failures
- **WARNING**: 0.75 ≤ overall_score < 0.85

## Layer 1: Deterministic Checks

Fast bash-based validation of skill structure and syntax.

**Script**: `.claude/test-framework/graders/deterministic-checks.sh`

**Checks performed**:

1. Frontmatter present (YAML block at start of SKILL.md)
2. Required fields (description, tools, context)
3. Line count (SKILL.md ≤ 500 lines)
4. Markdown syntax valid
5. Source citations present (at least one)
6. No forbidden patterns
7. Expected file structure (SKILL.md required, others optional)
8. Valid YAML frontmatter syntax
9. Valid tool names if specified
10. Valid context value (inline, fork)

**Critical failures** block Layer 2. **Warnings** are noted but allow progression. See [Configuration Reference](#configuration-reference) for the critical failure and forbidden pattern lists.

**Performance**: ~5 seconds, ~$0.00001

## Layer 2: LLM-as-Judge

AI-powered evaluation of content quality using structured rubrics.

**Rubrics**: `.claude/test-framework/graders/llm-judge-rubrics.md`

**Process**: Read skill + sources → evaluate each dimension against rubric → parse JSON responses → compute weighted score.

**Known Biases**:

- **Verbosity preference** - May favor longer content. Mitigation: rubrics explicitly allow conciseness.
- **Position bias** - Items appearing first may score higher. Mitigation: randomize evaluation order.
- **Leniency** - Reluctant to give low scores. Mitigation: calibrate with negative controls.
- **Recency** - May weight recent Claude capabilities more heavily. Mitigation: reference training broadly.

**Performance**: ~45 seconds, ~$1.50

## Layer 3: Human Calibration

Optional human review for validating LLM-judge accuracy.

**Guide**: `.claude/test-framework/graders/human-review-guide.md`

**Process**:

1. Generate human review form: `/cogworks-test {slug} --generate-human-review-form`
2. Expert completes form using same 5-point rubrics
3. Calculate agreement: `python .claude/test-framework/scripts/calculate-agreement.py`
4. Metrics: per-dimension agreement, overall agreement, systematic bias detection

**Target**: 90%+ agreement (within 0.5 points) across 20+ diverse skills

**When to run**: Initial setup, after rubric changes, quarterly validation, when scores seem off.

**Performance**: ~20 minutes, ~$100 opportunity cost

## Test Data Organization

```
tests/
├── datasets/
│   ├── golden-samples/              # Known-good skills for regression
│   │   └── deployment-skill/
│   │       ├── sources/             # Original source files
│   │       ├── expected-synthesis.md
│   │       ├── expected-skill/      # Expected SKILL.md + supporting files
│   │       ├── test-cases.jsonl
│   │       └── metadata.yaml        # Expected scores and structure
│   ├── negative-controls/           # Should fail or warn
│   │   ├── insufficient-sources/
│   │   │   ├── sparse-content.md
│   │   │   └── expected-outcome.yaml
│   │   └── overlapping-builtin/
│   │       ├── generic-coding-advice.md
│   │       └── expected-outcome.yaml
│   └── edge-cases/                  # Boundary conditions
│       ├── exactly-500-lines/
│       ├── multiple-contradictions/
│       └── highly-technical/
├── results/                         # Test run outputs (gitignored)
└── calibration/                     # Human grades for validation
```

- **Golden samples**: Regression testing — ensure framework changes don't affect quality detection
- **Negative controls**: Validate framework correctly identifies quality issues
- **Edge cases**: Test boundary conditions and unusual but valid inputs

## Configuration Reference

**File**: `.claude/test-framework/config/framework-config.yaml`

This is the single source of truth for all thresholds, weights, and tuning parameters.

```yaml
thresholds:
  overall_minimum: 0.85
  critical_failure_tolerance: 0
  llm_judge:
    minimum_average: 4.0
    minimum_per_dimension: 3.0
  layer_1:
    max_skill_md_lines: 500
    min_citations: 1

weights:
  source_fidelity: 0.30      # Fabrication most critical
  self_sufficiency: 0.25     # Must work standalone
  completeness: 0.20         # Scope coverage important
  specificity: 0.15          # Actionability matters
  no_overlap: 0.10           # Minor overlap acceptable

critical_failures:
  - missing_frontmatter
  - no_source_citations
  - skill_md_exceeds_500_lines
  - broken_markdown_syntax
  - forbidden_patterns

forbidden_patterns:
  - "rm -rf"
  - "eval"
  - ">/dev/null 2>&1 &"
  - "curl | bash"

tuning:
  llm_temperature: 0.0
  llm_max_tokens: 2000
  layer1_timeout_seconds: 30
  layer2_timeout_seconds: 120
```

**When to adjust weights**: Increase source_fidelity for high-stakes domains, self_sufficiency for novice users, no_overlap when context budget is tight.

**When to adjust thresholds**: Raise overall_minimum (e.g., 0.90) for production-critical skills, lower (e.g., 0.80) during prototyping.

## Integration with Cogworks

**Automatic invocation** via `--test` flag:

```bash
@cogworks encode deployment-sources/ --test
# Workflow: encode → learn → test (automatic) → report
```

**Manual invocation**:

```bash
/cogworks-test deployment-skill
/cogworks-test deployment-skill --compare-against tests/datasets/golden-samples/deployment-skill/
/cogworks-test deployment-skill --full
```

**Integration point**: Step 6.5 in `.claude/agents/cogworks.md` — optional testing after skill generation. Blocks completion if validation fails when `--test` flag is used.

## Troubleshooting Guide

### Layer 1 Takes Too Long

**Symptoms**: Deterministic checks exceed 30 seconds.

**Causes**: Large skill files, many supporting files, inefficient bash patterns.

**Solutions**: Check 500-line limit first, optimize bash script, increase layer1_timeout_seconds if justified.

### LLM-Judge Scores Inconsistent

**Symptoms**: Same skill gets different scores on repeated tests.

**Causes**: Temperature > 0.0, rubric ambiguity, evaluation prompt not specific enough, model version changes.

**Solutions**: Verify temperature = 0.0, run calibration, tighten rubric language, add concrete examples to rubrics.

### All Skills Failing on Same Check

**Symptoms**: Multiple unrelated skills fail same validation.

**Causes**: Configuration too strict, recent framework code change, rubric interpretation changed.

**Solutions**: Review recent changes (git log), check thresholds, test negative controls, re-run golden samples.

### False Positives in Deterministic Checks

**Symptoms**: Valid patterns flagged as critical failures.

**Causes**: Forbidden pattern list too broad, check logic doesn't handle valid edge cases (e.g., "rm -rf" in quoted examples).

**Solutions**: Review forbidden_patterns, add exceptions for valid usage contexts.

### Low Calibration Agreement

**Symptoms**: LLM and human grades differ on >10% of skills.

**Causes**: Rubric ambiguity, human reviewer misunderstanding, systematic LLM bias.

**Solutions**: Review disagreement patterns, clarify rubric language, add negative controls for disagreement areas.

## Cost and Performance

### Per-Skill Test Run

| Layer | Cost | Duration | What It Does |
|-------|------|----------|--------------|
| Layer 1 (Deterministic) | ~$0.00001 | ~5 sec | Structure, syntax, required elements |
| Layer 2 (LLM-as-Judge) | ~$1.50 | ~45 sec | 5 quality dimensions with reasoning |
| Layer 3 (Human Review) | ~$100 | ~20 min | Expert calibration |
| **Typical (L1+L2)** | **~$1.50** | **<1 min** | |

### Cost Asymmetry

Layer 2 / Layer 1 cost = $1.50 / $0.00001 = **150,000×**. This massive asymmetry justifies layered grading:

- If 30% of skills have critical failures, Layer 1 saves 30% × $1.50 = $0.45/skill
- For 100 skills over 100 test runs during development: ~$1,500 saved
- Time savings: 30 failed skills × 45 seconds = 22.5 minutes saved per batch

### Full Golden Sample Suite (20 samples)

- **Layer 1 only**: $0.0002, ~2 minutes
- **Layer 1 + Layer 2**: $30, ~15 minutes
- **With human calibration**: Add ~$2,000 + 7 hours

**Recommendation**: Full suite (L1+L2) on every framework change. Human calibration quarterly.

### Optimization Strategies

- **Reduce Layer 2 cost**: Filter with Layer 1 first, use shorter source excerpts, cache evaluations for unchanged skills, batch dimension evaluations
- **Reduce Layer 1 duration**: Optimize bash (avoid loops, use grep), parallelize independent checks
- **Reduce human cost**: Start with 5-skill sample, focus on dimensions with known disagreements

## Deep Dives

### Weighted Scoring Philosophy

Why weights differ between quality dimensions:

**Source Fidelity (30%)** — Fabrication destroys trust in all skill content. Users cannot distinguish fabricated from accurate claims. Requires complete re-synthesis to fix.

**Self-Sufficiency (25%)** — Skill unusable without external context. Users cannot apply skill without additional research. Moderate recovery — can add definitions.

**Completeness (20%)** — Missing content reduces utility but doesn't create false information. Easy recovery — add missing content.

**Specificity (15%)** — Vague guidance harder to apply but not wrong. Easy recovery — add examples and specifics.

**No Overlap (10%)** — Skill still useful if minor overlap exists. Trivial recovery — trim generic sections.

Weights reflect **failure impact**, **recovery cost**, and **trust damage**. Tune based on: user expertise (novices need higher self-sufficiency), context budget (tight budgets need higher no-overlap), trust requirements (high-stakes need higher source fidelity).

### LLM-as-Judge Reliability

**When to trust LLM scores**: Calibration shows >90% agreement, skill fits standard patterns, scores are extreme (1-2 or 4-5), multiple dimensions agree.

**When to be skeptical**: Agreement <90%, scores cluster around threshold (3-4), single dimension dramatically different, novel skill structure, systematic bias suspected.

**Mitigation strategies**: Regular calibration (quarterly), negative controls, rubric tightening with concrete examples, ensemble scoring (multiple evaluations averaged), automatic human escalation for ambiguous scores.

**Key insight**: LLM-as-judge is a probabilistic tool, not ground truth. Use as fast filter with human escalation for edge cases.

## Quick Reference

### Command Cheatsheet

```bash
/cogworks-test {skill-slug}                    # Basic test
/cogworks-test {skill-slug} --json             # JSON output
/cogworks-test {skill-slug} --full             # Include human review prompts
/cogworks-test {skill-slug} --generate-human-review-form
/cogworks-test {skill-slug} --compare-against tests/datasets/golden-samples/{slug}/
/cogworks-test {skill-slug} --compare-grades \
    --human tests/calibration/{slug}-human.yaml \
    --llm tests/results/latest/{slug}-results.json

# Test all golden samples
for sample in tests/datasets/golden-samples/*/; do
    /cogworks-test "$(basename "$sample")"
done
```

### File Locations

```
.claude/test-framework/
├── config/framework-config.yaml          # All settings
├── graders/
│   ├── deterministic-checks.sh          # Layer 1
│   ├── llm-judge-rubrics.md             # Layer 2
│   └── human-review-guide.md            # Layer 3
├── templates/
│   ├── test-case-template.jsonl
│   └── validation-report.md
└── scripts/
    └── calculate-agreement.py

tests/
├── datasets/                             # Test data
├── results/                              # Outputs (gitignored)
└── calibration/                          # Human grades
```

## Sources

This framework synthesizes knowledge from:

1. `.claude/test-framework/README.md` - Framework overview and architecture
2. `.claude/test-framework/config/framework-config.yaml` - Configuration structure and defaults
3. `.claude/test-framework/graders/deterministic-checks.md` - Layer 1 validation rules
4. `.claude/test-framework/graders/deterministic-checks.sh` - Layer 1 implementation
5. `.claude/test-framework/graders/llm-judge-rubrics.md` - Layer 2 evaluation rubrics
6. `.claude/test-framework/graders/human-review-guide.md` - Layer 3 calibration process
7. `.claude/test-framework/templates/validation-report.md` - Report format and structure
8. `CLAUDE.md:48-54` - Quality requirements definition
9. `.claude/agents/cogworks.md` - Integration with cogworks workflow
10. Anthropic eval-driven development best practices
