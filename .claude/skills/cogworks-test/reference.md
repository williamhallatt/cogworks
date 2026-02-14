# Reference: Cogworks Testing Framework

Complete methodology for validating cogworks-generated skills through eval-driven development.

## TL;DR

The cogworks testing framework validates skills through three-layer grading: fast deterministic checks ($0.00001, 5 seconds) catch structural issues; LLM-as-judge ($1.50, 45 seconds) evaluates five weighted quality dimensions (source fidelity 30%, self-sufficiency 25%, completeness 20%, specificity 15%, no overlap 10%); optional human review ($100, 20 minutes) calibrates judge accuracy. Success requires overall score ≥0.85 with zero critical failures. Golden samples provide regression testing, negative controls validate failure detection. The framework integrates with cogworks workflow via `--test` flag and generates machine-readable JSON plus human-readable Markdown reports. Cost asymmetry (150,000× difference between layers) makes layered grading economically essential. LLM-judge agreement with humans must exceed 90% to trust automated scoring.

## Table of Contents

1. Core Concepts
2. Concept Map
3. Complete Testing Workflow
4. Quality Dimension Rubrics
5. Layer 1: Deterministic Checks
6. Layer 2: LLM-as-Judge
7. Layer 3: Human Calibration
8. Test Data Organization
9. Configuration Reference
10. Integration with Cogworks
11. Troubleshooting Guide
12. Cost and Performance
13. Deep Dives
14. Quick Reference
15. Sources

## Core Concepts

### 1. Layered Grading

Progressive quality evaluation starting with cheap deterministic checks (Layer 1), advancing to expensive LLM evaluation only if structural validation passes (Layer 2), and optionally using human review for calibration (Layer 3). Prevents waste by filtering obviously-failing skills before expensive evaluations.

### 2. Quality Dimensions

Five measurable aspects of skill quality: source fidelity (traceability to sources), self-sufficiency (standalone understanding), completeness (scope coverage), specificity (actionable patterns), and no overlap (novel value). Each scored 1-5 and combined using weights reflecting relative importance.

### 3. Critical Failures

Structural issues that immediately fail a skill regardless of content quality: missing frontmatter, no source citations, SKILL.md exceeds 500 lines, broken markdown syntax, forbidden patterns detected. Any critical failure stops evaluation and requires remediation before testing can proceed.

### 4. LLM-as-Judge

Using Claude to evaluate skill quality against structured rubrics. Faster and cheaper than human review (45 seconds vs 20 minutes, $1.50 vs $100) but requires calibration against human grades to ensure reliability. Known biases include verbosity preference, position bias, and leniency.

### 5. Golden Samples

Known-good skills with documented expected outcomes used for regression testing. When framework changes, re-running golden samples validates that quality detection remains consistent. Each golden sample includes sources, expected synthesis, expected skill structure, and test cases.

### 6. Negative Controls

Test inputs designed to fail validation, verifying framework correctly detects quality issues. Types include insufficient sources (should warn about completeness), overlapping builtin knowledge (should warn about no overlap), and structural violations (should fail deterministically).

### 7. Weighted Scoring

Combining quality dimensions using importance weights rather than simple averaging. Source fidelity weighted highest (30%) because fabrication is most critical; no overlap weighted lowest (10%) because minor overlap acceptable if other dimensions strong. Overall score = weighted sum / 5.0.

### 8. Test Reports

Dual-format output: JSON for automation/CI/CD (structured data, exit codes, machine parsing) and Markdown for human review (narrative explanations, git-friendly diffs, actionable recommendations). Both generated simultaneously with consistent data.

### 9. Calibration

Validating LLM-judge accuracy by comparing automated grades against human expert grades on same skills. Target agreement: within 0.5 points on 5-point scale for 90%+ of skills. Low agreement indicates rubric ambiguity or judge bias requiring correction.

### 10. Framework Configuration

Central YAML file (framework-config.yaml) defining all thresholds, weights, critical failures list, and tuning parameters. Allows adjusting sensitivity without code changes. Thresholds include overall_minimum (0.85), llm_judge minimum_average (4.0), and dimension-specific weights.

## Concept Map

**Relationships between concepts:**

1. **Layered Grading** uses **Critical Failures** to gate progression to expensive evaluation
2. **Quality Dimensions** are weighted by **Weighted Scoring** to compute overall score
3. **LLM-as-Judge** requires **Calibration** to ensure reliable scoring
4. **Golden Samples** enable regression testing using **Test Reports** comparison
5. **Negative Controls** validate **Critical Failures** detection works correctly
6. **Framework Configuration** defines thresholds for **Layered Grading** decision logic
7. **Test Reports** contain **Quality Dimensions** scores and **Critical Failures** list
8. **Calibration** measures **LLM-as-Judge** agreement with human grades
9. **Weighted Scoring** prioritizes **Quality Dimensions** by failure severity
10. **Golden Samples** and **Negative Controls** form comprehensive **Test Data Organization**

## Complete Testing Workflow

### Step 1: Locate Skill

Resolve skill slug to filesystem path and verify skill exists.

```bash
# Resolve skill path
SKILL_SLUG="deployment-skill"
SKILL_PATH=".claude/skills/${SKILL_SLUG}"

# Verify skill exists
if [ ! -d "$SKILL_PATH" ]; then
    echo "Error: Skill not found at $SKILL_PATH"
    exit 1
fi

# Verify SKILL.md exists
if [ ! -f "$SKILL_PATH/SKILL.md" ]; then
    echo "Error: SKILL.md not found in $SKILL_PATH"
    exit 1
fi

echo "Testing skill at: $SKILL_PATH"
```

### Step 2: Load Configuration

Read framework configuration from `.claude/test-framework/config/framework-config.yaml`:

```yaml
thresholds:
  overall_minimum: 0.85 # Minimum score to pass
  critical_failure_tolerance: 0 # Zero critical failures allowed
  llm_judge:
    minimum_average: 4.0 # Minimum average score across dimensions
    minimum_per_dimension: 3.0 # No dimension below this

weights:
  source_fidelity: 0.30 # Highest weight - fabrication is critical
  self_sufficiency: 0.25 # Second - must work standalone
  completeness: 0.20 # Third - scope coverage matters
  specificity: 0.15 # Fourth - actionability important
  no_overlap: 0.10 # Lowest - minor overlap acceptable

critical_failures:
  - missing_frontmatter # No YAML frontmatter block
  - no_source_citations # No traceable claims
  - skill_md_exceeds_500_lines # Context budget violation
  - broken_markdown_syntax # Parse failures
  - forbidden_patterns # Dangerous commands/patterns
```

Parse configuration and set validation parameters.

### Step 3: Run Layer 1 (Deterministic Checks)

Execute bash script that validates structure and syntax without LLM calls.

```bash
# Run deterministic checks with JSON output
bash .claude/test-framework/graders/deterministic-checks.sh "$SKILL_PATH" --json > layer1-results.json

# Parse results
LAYER1_STATUS=$(jq -r '.status' layer1-results.json)
CRITICAL_FAILURES=$(jq -r '.critical_failures | length' layer1-results.json)

# Check for critical failures
if [ "$LAYER1_STATUS" = "fail" ] || [ "$CRITICAL_FAILURES" -gt 0 ]; then
    echo "❌ Layer 1 FAILED - Critical issues detected"

    # Display failures
    jq -r '.critical_failures[]' layer1-results.json

    echo ""
    echo "Fix critical failures before proceeding to Layer 2"
    exit 1
fi

echo "✅ Layer 1 PASSED - No critical failures"
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

**Cost**: ~$0.00001, **Duration**: ~5 seconds

### Step 4: Run Layer 2 (LLM-as-Judge)

Only runs if Layer 1 passed (no critical failures).

```bash
# Read skill content and sources
SKILL_CONTENT=$(cat "$SKILL_PATH/SKILL.md")
SOURCES=$(find "$SKILL_PATH/_sources" -type f 2>/dev/null || echo "")

# For each quality dimension, call LLM-judge
for dimension in source_fidelity self_sufficiency completeness specificity no_overlap; do
    # Load rubric for this dimension
    RUBRIC=$(cat .claude/test-framework/graders/llm-judge-rubrics.md | \
             sed -n "/## ${dimension}/,/## [A-Z]/p")

    # Construct evaluation prompt
    PROMPT="Evaluate the following skill on ${dimension} using this rubric:

${RUBRIC}

Skill content:
${SKILL_CONTENT}

Source material:
${SOURCES}

Output JSON with score (1-5), reasoning, and dimension-specific metrics."

    # Call Claude with evaluation prompt
    RESPONSE=$(call_claude_api "$PROMPT")

    # Parse score
    SCORE=$(echo "$RESPONSE" | jq -r '.score')
    echo "${dimension}: ${SCORE}/5"
done
```

**Scoring formula**:

```python
# Extract scores from each dimension evaluation
scores = {
    'source_fidelity': 5,
    'self_sufficiency': 4,
    'completeness': 4,
    'specificity': 4,
    'no_overlap': 5
}

# Apply weights from configuration
weights = {
    'source_fidelity': 0.30,
    'self_sufficiency': 0.25,
    'completeness': 0.20,
    'specificity': 0.15,
    'no_overlap': 0.10
}

# Calculate weighted score
weighted_score = sum(scores[dim] * weights[dim] for dim in scores)

# Normalize to 0-1 scale
overall_score = weighted_score / 5.0

# Example: (5*0.30 + 4*0.25 + 4*0.20 + 4*0.15 + 5*0.10) / 5.0
#        = (1.5 + 1.0 + 0.8 + 0.6 + 0.5) / 5.0
#        = 4.4 / 5.0
#        = 0.88 ✓ (passes threshold of 0.85)
```

**Duration**: ~45 seconds, **Cost**: ~$1.50

### Step 5: Generate Validation Report

Create dual-format output for both machine and human consumption.

**JSON (machine-readable)**:

```json
{
  "skill_slug": "deployment-skill",
  "timestamp": "2026-02-14T10:30:00Z",
  "overall_score": 0.88,
  "weighted_score": 4.4,
  "recommendation": "PASS",
  "critical_failures": [],
  "warnings": ["Minor undefined term: CORS"],
  "layer_1": {
    "status": "pass",
    "checks_passed": 12,
    "checks_total": 13,
    "duration_seconds": 4.2
  },
  "layer_2": {
    "source_fidelity": {
      "score": 5,
      "weight": 0.3,
      "reasoning": "All claims traceable with clear citations"
    },
    "self_sufficiency": {
      "score": 4,
      "weight": 0.25,
      "reasoning": "Minor term undefined but inferable from context"
    },
    "completeness": {
      "score": 4,
      "weight": 0.2,
      "reasoning": "85% source coverage, minor gaps acceptable"
    },
    "specificity": {
      "score": 4,
      "weight": 0.15,
      "reasoning": "Most patterns actionable with examples"
    },
    "no_overlap": {
      "score": 5,
      "weight": 0.1,
      "reasoning": "Entirely novel deployment workflow"
    },
    "duration_seconds": 42.3
  }
}
```

Save to: `tests/results/{timestamp}/{skill-slug}-results.json`

**Markdown (human-readable)**:

Use template from `.claude/test-framework/templates/validation-report.md`:

```markdown
# Validation Report: deployment-skill

**Timestamp**: 2026-02-14T10:30:00Z
**Recommendation**: ✅ PASS

## Summary

Overall score: **0.88/1.0** (threshold: ≥0.85)
Weighted score: **4.4/5.0**

## Layer 1: Deterministic Checks

Status: ✅ PASS
Checks passed: 12/13
Duration: 4.2 seconds

Warnings:

- Minor undefined term: CORS

## Layer 2: LLM-as-Judge

| Dimension        | Score | Weight | Weighted |
| ---------------- | ----- | ------ | -------- |
| Source Fidelity  | 5/5   | 30%    | 1.50     |
| Self-Sufficiency | 4/5   | 25%    | 1.00     |
| Completeness     | 4/5   | 20%    | 0.80     |
| Specificity      | 4/5   | 15%    | 0.60     |
| No Overlap       | 5/5   | 10%    | 0.50     |
| **Total**        |       |        | **4.40** |

Duration: 42.3 seconds

### Source Fidelity (5/5) ✓

All claims traceable with clear citations. No fabrication detected.

### Self-Sufficiency (4/5) ✓

Minor term undefined (CORS) but inferable from context. 95% self-contained.

### Completeness (4/5) ✓

85% source coverage achieved. Minor gaps in edge cases acceptable for stated scope.

### Specificity (4/5) ✓

Most patterns actionable with when/why/how context and examples provided.

### No Overlap (5/5) ✓

Entirely novel deployment workflow, no overlap with Claude's general training.

## Recommendations

1. Define "CORS" term explicitly or add to glossary
2. Consider adding edge case examples for completeness

## Next Steps

- ✅ Skill ready for production use
- Archive test results for regression comparison
- Update golden sample if this represents improved synthesis
```

Save to: `tests/results/{timestamp}/{skill-slug}-report.md`

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

Full report: tests/results/2026-02-14T10-30-00Z/deployment-skill-report.md
```

## Quality Dimension Rubrics

### Source Fidelity Rubric (Weight: 0.30)

**Definition**: Accuracy and traceability of claims to source material.

**5-Point Scale**:

**5 - Exceptional**:

- Every claim has clear citation
- Contradictions explicitly flagged
- Synthesis preserves nuance
- No fabrication
- Citation format consistent

**4 - Strong**:

- 95%+ claims traceable
- Contradictions noted
- Minor omissions acceptable
- Rare citation inconsistencies

**3 - Adequate**:

- 85%+ claims traceable
- Most contradictions noted
- Some synthesis gaps
- Citation format mostly consistent

**2 - Weak**:

- <85% claims traceable
- Contradictions missed
- Noticeable fabrication
- Poor citation practices

**1 - Failing**:

- Significant fabrication
- Missing citations throughout
- Contradictions ignored
- Cannot verify claims

**Evaluation Process**:

1. Sample 10 specific claims from the skill randomly
2. For each claim, attempt to trace back to source material using citations
3. Check contradictions - are source disagreements explicitly noted?
4. Calculate traceability - percentage of sampled claims that can be verified
5. Note fabrications - any claims not supported by sources

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

### Self-Sufficiency Rubric (Weight: 0.25)

**Definition**: Can the skill be understood and applied without external context?

**5-Point Scale**:

**5 - Exceptional**:

- Complete standalone understanding
- All terms defined
- Context provided
- No external dependencies
- New user could apply immediately

**4 - Strong**:

- Minor context gaps
- 95%+ self-contained
- Rare external references justified
- Terms mostly defined

**3 - Adequate**:

- Some context assumed
- 85%+ self-contained
- User can infer gaps
- Most important terms defined

**2 - Weak**:

- Frequent context gaps
- Relies heavily on external knowledge
- Terms undefined
- Difficult to follow

**1 - Failing**:

- Cannot understand without external context
- Many undefined terms
- Assumes significant prior knowledge
- Not usable standalone

**Evaluation Process**:

1. List technical terms/concepts used in skill
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

### Completeness Rubric (Weight: 0.20)

**Definition**: Coverage of stated scope and source material.

**5-Point Scale**:

**5 - Exceptional**:

- Stated scope fully covered
- 90%+ of source material synthesized
- No significant gaps
- All promised topics addressed

**4 - Strong**:

- 85%+ scope covered
- Minor gaps acceptable
- Most source material used
- Key topics well-covered

**3 - Adequate**:

- 75%+ scope covered
- Some gaps present
- Reasonable source coverage
- Main topics addressed

**2 - Weak**:

- <75% scope covered
- Significant gaps
- Sparse source usage
- Important topics missing

**1 - Failing**:

- Incomplete coverage
- Major sections missing
- Minimal source usage
- Stated scope not delivered

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
  "gaps": ["Edge case handling not covered", "Rollback procedures minimal"],
  "reasoning": "85% scope coverage with minor edge case gaps acceptable"
}
```

### Specificity Rubric (Weight: 0.15)

**Definition**: Actionability and detail of patterns/guidance.

**5-Point Scale**:

**5 - Exceptional**:

- All patterns have when/why/how context
- Concrete examples throughout
- Clear decision criteria
- Immediately actionable

**4 - Strong**:

- 90%+ patterns actionable
- Minor abstraction acceptable
- Most have examples
- Clear application guidance

**3 - Adequate**:

- 75%+ patterns actionable
- Some vague guidance
- Examples present
- Can infer application

**2 - Weak**:

- <75% actionable
- Many vague/generic patterns
- Examples sparse
- Difficult to apply

**1 - Failing**:

- Mostly generic advice
- No clear patterns
- Not actionable
- Cannot apply guidance

**Evaluation Process**:

1. Count total patterns/guidelines in skill
2. For each pattern, check if it includes:
   - **When** to apply (context/triggers)
   - **Why** it matters (reasoning/benefits)
   - **How** to implement (concrete steps)
   - **Example** demonstrating usage
3. Calculate actionability percentage
4. Note vague or generic patterns

**Output Format**:

```json
{
  "score": 1-5,
  "total_patterns": 15,
  "actionable_patterns": 13,
  "patterns_with_examples": 12,
  "vague_patterns": ["Pattern 7 lacks concrete steps", "Pattern 11 too generic"],
  "reasoning": "87% patterns actionable with clear when/why/how context"
}
```

### No Overlap Rubric (Weight: 0.10)

**Definition**: Skill provides novel value beyond Claude's built-in knowledge.

**5-Point Scale**:

**5 - Exceptional**:

- Entirely novel content
- No overlap with Claude's training
- Clear specialized value
- Unique insights

**4 - Strong**:

- 90%+ novel
- Minor overlap acceptable
- Adds significant value
- Specialized knowledge

**3 - Adequate**:

- 75%+ novel
- Some overlap but skill still justified
- Moderate value add
- Some unique content

**2 - Weak**:

- <75% novel
- Significant overlap
- Questionable value add
- Mostly generic

**1 - Failing**:

- Mostly duplicates built-in knowledge
- No clear value add
- Generic best practices only
- Skill not justified

**Evaluation Process**:

1. Identify generic content (Claude's general training):
   - Generic best practices (e.g., "write clear code")
   - Common knowledge (e.g., "functions should be modular")
   - Standard definitions (e.g., "REST is an architectural style")

2. Identify specialized content:
   - Organization-specific patterns
   - Tool-specific workflows
   - Novel methodologies
   - Non-obvious insights

3. Calculate novelty percentage
4. Assess value justification - does skill add sufficient value to exist?

**Output Format**:

```json
{
  "score": 1-5,
  "novelty_percentage": 0.95,
  "generic_content": ["Section on code review benefits (standard practice)"],
  "specialized_content": ["Deployment workflow specific to infrastructure", "CI/CD integration patterns"],
  "value_justification": "Adds specialized deployment knowledge not in Claude's training",
  "reasoning": "95% novel with organization-specific deployment patterns"
}
```

### Weighted Score Calculation

```python
weighted_score = (
    source_fidelity * 0.30 +
    self_sufficiency * 0.25 +
    completeness * 0.20 +
    specificity * 0.15 +
    no_overlap * 0.10
)

# Normalize to 0-1 scale
overall_score = weighted_score / 5.0
```

### Decision Thresholds

- **PASS**: overall_score ≥ 0.85 AND no critical failures
- **FAIL**: overall_score < 0.85 OR any critical failures
- **WARNING**: 0.75 ≤ overall_score < 0.85

## Layer 1: Deterministic Checks

Fast bash-based validation of skill structure and syntax.

**Script location**: `.claude/test-framework/graders/deterministic-checks.sh`

**Checks performed**:

1. **Frontmatter present** - YAML block at start of SKILL.md
2. **Required fields** - description, tools, context
3. **Line count** - SKILL.md ≤ 500 lines
4. **Markdown syntax** - Valid markdown, no broken links
5. **Source citations** - At least one citation/reference
6. **Forbidden patterns** - No dangerous commands (rm -rf, eval, etc.)
7. **File structure** - Expected files present (SKILL.md required, others optional)
8. **Frontmatter syntax** - Valid YAML structure
9. **Tool specifications** - Valid tool names if specified
10. **Context modes** - Valid context value (inline, fork)

**Critical vs Warning failures**:

**Critical** (blocks Layer 2):

- Missing frontmatter
- No source citations
- SKILL.md exceeds 500 lines
- Broken markdown syntax
- Forbidden patterns detected

**Warnings** (note but proceed):

- Minor undefined terms
- Optional files missing
- Formatting inconsistencies

**Performance**: ~5 seconds, ~$0.00001

## Layer 2: LLM-as-Judge

AI-powered evaluation of content quality using structured rubrics.

**Rubric location**: `.claude/test-framework/graders/llm-judge-rubrics.md`

**Process**:

1. Read skill content and source material
2. For each quality dimension:
   - Load dimension-specific rubric
   - Construct evaluation prompt with rubric + content
   - Call Claude API for scoring
   - Parse structured JSON response
3. Compute weighted score using configuration weights
4. Generate detailed reasoning for each score

**Known Biases**:

**Verbosity Preference**:

- **Description**: May favor longer, more detailed content over concise content
- **Mitigation**: Rubrics explicitly allow conciseness; calibrate with human grades that value clarity

**Position Bias**:

- **Description**: Items appearing first may receive higher scores
- **Mitigation**: Randomize evaluation order; present rubric categories in consistent order

**Leniency**:

- **Description**: May be reluctant to give low scores
- **Mitigation**: Calibration validates judge can identify failing cases; use negative controls

**Recency**:

- **Description**: May weight recent Claude releases' capabilities more heavily
- **Mitigation**: Reference "Claude's training" broadly, not specific version; calibration spans versions

**Performance**: ~45 seconds, ~$1.50

## Layer 3: Human Calibration

Optional human review for validating LLM-judge accuracy.

**Guide location**: `.claude/test-framework/graders/human-review-guide.md`

**Process**:

1. Generate human review form:

   ```bash
   /cogworks-test deployment-skill --generate-human-review-form
   ```

2. Human expert completes form using same 5-point rubrics

3. Calculate agreement between LLM and human grades:

   ```bash
   python .claude/test-framework/scripts/calculate-agreement.py \
       --human tests/calibration/deployment-skill-human.yaml \
       --llm tests/results/latest/deployment-skill-results.json
   ```

4. Agreement metrics:
   - **Per-dimension agreement** - Percentage within 0.5 points
   - **Overall agreement** - Weighted average across dimensions
   - **Systematic bias** - Consistent direction of disagreement

**Target**: 90%+ agreement across 20+ diverse skills

**When to run**:

- Initial framework setup
- After rubric changes
- Quarterly validation
- When LLM-judge scores seem off

**Performance**: ~20 minutes human time, ~$100 opportunity cost

## Test Data Organization

```
tests/
├── datasets/
│   ├── golden-samples/              # Known-good skills for regression
│   │   └── deployment-skill/
│   │       ├── sources/             # Original source files used
│   │       │   ├── cicd-automation.md
│   │       │   └── deployment-workflow.md
│   │       ├── expected-synthesis.md    # Expected cogworks-encode output
│   │       ├── expected-skill/          # Expected cogworks-learn output
│   │       │   ├── SKILL.md
│   │       │   ├── reference.md
│   │       │   ├── patterns.md
│   │       │   └── examples.md
│   │       ├── test-cases.jsonl         # Test inputs and expected outputs
│   │       └── metadata.yaml            # Expected scores, line counts, structure
│   ├── negative-controls/           # Should fail or warn
│   │   ├── insufficient-sources/
│   │   │   ├── sparse-content.md        # Minimal source material
│   │   │   └── expected-outcome.yaml    # Should warn about completeness
│   │   └── overlapping-builtin/
│   │       ├── generic-coding-advice.md # Generic best practices
│   │       └── expected-outcome.yaml    # Should warn about no overlap
│   └── edge-cases/                  # Boundary conditions
│       ├── exactly-500-lines/           # At line limit
│       ├── multiple-contradictions/     # Source disagreements
│       └── highly-technical/            # Dense specialized content
├── results/                         # Test run outputs (gitignored)
│   └── 2026-02-14T10-30-00Z/
│       ├── deployment-skill-results.json
│       └── deployment-skill-report.md
└── calibration/                    # Human grades for validation
    ├── deployment-skill-human.yaml
    └── agreement-report.md
```

**Golden sample purpose**: Regression testing to ensure framework changes don't affect quality detection

**Negative control purpose**: Validate framework correctly identifies quality issues

**Edge case purpose**: Test boundary conditions and unusual but valid inputs

## Configuration Reference

**File**: `.claude/test-framework/config/framework-config.yaml`

**Complete structure**:

```yaml
thresholds:
  overall_minimum: 0.85 # Minimum overall score to pass
  critical_failure_tolerance: 0 # Zero critical failures allowed
  llm_judge:
    minimum_average: 4.0 # Average across dimensions
    minimum_per_dimension: 3.0 # No dimension below this
  layer_1:
    max_skill_md_lines: 500 # Context budget limit
    min_citations: 1 # At least one source reference

weights:
  source_fidelity: 0.30 # Fabrication most critical
  self_sufficiency: 0.25 # Must work standalone
  completeness: 0.20 # Scope coverage important
  specificity: 0.15 # Actionability matters
  no_overlap: 0.10 # Minor overlap acceptable

critical_failures:
  - missing_frontmatter # No YAML block
  - no_source_citations # No traceable claims
  - skill_md_exceeds_500_lines # Context budget violation
  - broken_markdown_syntax # Parse failures
  - forbidden_patterns # Dangerous commands

forbidden_patterns:
  - "rm -rf" # Destructive file operations
  - "eval" # Code injection risk
  - ">/dev/null 2>&1 &" # Background processes
  - "curl | bash" # Piped execution

tuning:
  llm_temperature: 0.0 # Deterministic scoring
  llm_max_tokens: 2000 # Per evaluation
  layer1_timeout_seconds: 30 # Deterministic check timeout
  layer2_timeout_seconds: 120 # LLM evaluation timeout
```

**When to adjust weights**:

- **Increase source_fidelity** if fabrication is critical concern
- **Increase self_sufficiency** if skills used by novices
- **Increase completeness** if comprehensive coverage required
- **Increase specificity** if actionability is priority
- **Increase no_overlap** if context budget severely constrained

**When to adjust thresholds**:

- **Raise overall_minimum** (e.g., 0.90) for production-critical skills
- **Lower overall_minimum** (e.g., 0.80) during development/prototyping
- **Adjust minimum_per_dimension** if specific dimension is blocker

## Integration with Cogworks

This framework integrates with the cogworks workflow for automatic validation.

**Automatic invocation**:

```bash
# User runs cogworks with --test flag
@cogworks encode deployment-sources/ --test

# Cogworks workflow:
# 1. Run cogworks-encode (synthesis)
# 2. Run cogworks-learn (skill generation)
# 3. Run cogworks-test (validation) ← automatic
# 4. Report results to user
```

**Manual invocation**:

```bash
# Test after manual skill editing
/cogworks-test deployment-skill

# Test with comparison
/cogworks-test deployment-skill --compare-against tests/datasets/golden-samples/deployment-skill/

# Test with full calibration
/cogworks-test deployment-skill --full
```

**CI/CD integration**:

```bash
#!/bin/bash
# In CI pipeline

# Test all golden samples
for sample in tests/datasets/golden-samples/*/; do
    slug=$(basename "$sample")

    # Run test with JSON output
    /cogworks-test "$slug" --json > "results/${slug}.json"

    # Check exit code
    if [ $? -ne 0 ]; then
        echo "Golden sample failed: $slug"
        exit 1
    fi
done

echo "All golden samples passed"
```

**Integration points in `.claude/agents/cogworks.md`**:

- Step 6.5: Optional testing after skill generation
- Uses `--test` flag to trigger automatic validation
- Blocks completion if validation fails (when --test used)

## Troubleshooting Guide

### Issue: Layer 1 Takes Too Long

**Symptoms**: Deterministic checks exceed 30 seconds

**Causes**:

- Large skill files (SKILL.md > 1000 lines)
- Many supporting files to scan
- Inefficient bash script patterns
- Slow filesystem operations

**Solutions**:

1. Check if skill violates 500-line limit first
2. Optimize bash script to avoid expensive operations
3. Use grep/sed efficiently instead of loops
4. Increase layer1_timeout_seconds in config if justified

### Issue: LLM-Judge Scores Inconsistent

**Symptoms**: Same skill gets different scores on repeated tests

**Causes**:

- Temperature > 0.0 introduces randomness
- Rubric ambiguity allows interpretation variance
- Evaluation prompt not specific enough
- Model version changes

**Solutions**:

1. Verify temperature = 0.0 in configuration
2. Run calibration to identify systematic disagreements
3. Tighten rubric language for clarity
4. Add concrete examples to rubrics
5. Check if model version changed (API)

### Issue: All Skills Failing on Same Check

**Symptoms**: Multiple unrelated skills fail same validation

**Causes**:

- Framework configuration too strict
- Recent framework code change introduced bug
- Rubric interpretation changed
- Source material format changed

**Solutions**:

1. Review recent framework changes (git log)
2. Check threshold settings in framework-config.yaml
3. Test negative controls - should they fail differently?
4. Re-run golden samples - did they regress?
5. Adjust thresholds if genuinely too strict

### Issue: False Positives in Deterministic Checks

**Symptoms**: Valid patterns flagged as critical failures

**Causes**:

- Forbidden pattern list too broad
- Check logic doesn't account for valid edge cases
- Markdown parser too strict

**Solutions**:

1. Review forbidden_patterns list in config
2. Add exceptions for valid patterns (e.g., "rm -rf" in quoted examples)
3. Update check logic to distinguish usage contexts
4. Add validation for exception handling

### Issue: Low Calibration Agreement

**Symptoms**: LLM and human grades differ on >10% of skills

**Causes**:

- Rubric ambiguity
- Human reviewer misunderstanding rubrics
- Systematic LLM bias
- Skills outside calibration training set

**Solutions**:

1. Review disagreement patterns - systematic or random?
2. Clarify rubric language where disagreements cluster
3. Re-train human reviewers on rubric interpretation
4. Add negative controls covering disagreement areas
5. Document known edge cases where disagreement acceptable

## Cost and Performance

### Per-Skill Test Run

**Layer 1 (Deterministic)**:

- **Cost**: ~$0.00001 (negligible)
- **Duration**: ~5 seconds
- **What it does**: Structure, syntax, required elements validation

**Layer 2 (LLM-as-Judge)**:

- **Cost**: ~$1.50 (varies with skill size and source length)
- **Duration**: ~45 seconds
- **What it does**: 5 quality dimension evaluations with reasoning

**Layer 3 (Human Review)**:

- **Cost**: ~$100 (opportunity cost at $300/hr engineer rate)
- **Duration**: ~20 minutes
- **What it does**: Expert validation for calibration

**Typical validation**: Layer 1 + Layer 2 = ~$1.50 and <1 minute

### Full Golden Sample Suite

Assuming 20 golden samples:

- **Layer 1 only**: 20 × $0.00001 = $0.0002, ~2 minutes total
- **Layer 1 + Layer 2**: 20 × $1.50 = $30, ~15 minutes total
- **With human calibration**: Add $2000 + 7 hours for 20 skills

**Recommendation**: Run full suite (Layer 1 + 2) on every framework change, human calibration quarterly.

### Optimization Strategies

**Reduce Layer 2 cost**:

- Filter with Layer 1 first (prevents unnecessary LLM calls)
- Use shorter source excerpts when full text not needed
- Cache LLM evaluations for unchanged skills
- Batch multiple dimension evaluations in single prompt

**Reduce Layer 1 duration**:

- Optimize bash scripts (avoid loops, use grep efficiently)
- Parallelize independent checks
- Skip optional checks in fast mode

**Reduce human calibration cost**:

- Start with small sample (5 skills) to identify major issues
- Focus calibration on dimensions with known disagreements
- Use subject matter experts (faster, more accurate)

### Cost Asymmetry Analysis

Layer 1 vs Layer 2 cost difference:

```
Layer 2 cost / Layer 1 cost = $1.50 / $0.00001 = 150,000×
```

This massive asymmetry (150,000× difference) justifies layered grading architecture:

- If 50% of skills have critical failures, Layer 1 saves 50% × $1.50 = $0.75 per skill
- For 20 golden samples, saves $15 per test run
- Over 100 test runs (typical during framework development), saves $1,500

**Key insight**: Even if Layer 1 only catches 10% of failures, the cost savings justify the architecture.

## Deep Dives

### Why Layered Grading Works

Layered grading leverages **cost asymmetry** between validation methods.

**Cost spectrum**:

1. Deterministic checks: $0.00001 (150,000× cheaper than LLM)
2. LLM-as-judge: $1.50 (67× cheaper than human)
3. Human review: $100 (most expensive, most accurate)

**Probability analysis**:

Assume:

- 30% of skills have critical structural failures (caught by Layer 1)
- 50% of remaining skills fail LLM evaluation (caught by Layer 2)
- 5% of LLM passes need human review (caught by Layer 3)

**Without layering** (LLM-judge everything):

- 100 skills × $1.50 = $150

**With layering**:

- Layer 1: 100 skills × $0.00001 = $0.001
- Layer 2: 70 skills × $1.50 = $105 (30% filtered by Layer 1)
- Layer 3: 2 skills × $100 = $200 (5% of 35 LLM passes)
- Total: $305

Wait, this seems more expensive! But:

1. Layer 3 is **optional** - only run quarterly for calibration
2. Layer 1 prevents wasting 45 seconds per obviously-failing skill
3. **Time savings** matter: 30 skills × 45 seconds = 22.5 minutes saved per run

**Corrected analysis (without Layer 3)**:

- Without layering: $150, 75 minutes (100 × 45 seconds)
- With layering: $105, 53 minutes (70 × 45 seconds + 100 × 5 seconds)
- Savings: $45 and 22 minutes per 100 skills

**Key insight**: Layer 1 acts as a **fast reject filter**, preventing expensive operations on obviously-failing inputs.

### Weighted Scoring Philosophy

Why weights differ between quality dimensions:

**Source Fidelity (30% - Highest)**:

- **Failure severity**: Fabrication destroys trust in all skill content
- **Impact**: Users cannot distinguish fabricated from accurate claims
- **Recovery**: Requires complete re-synthesis to fix
- **Example**: Skill claims "Feature X supports Y" but source never mentions this - user tries to use non-existent functionality

**Self-Sufficiency (25% - Second)**:

- **Failure severity**: Skill unusable without external context
- **Impact**: Users cannot apply skill without additional research
- **Recovery**: Moderate - can add definitions/context
- **Example**: Skill uses "CORS" throughout without definition - users unfamiliar with term cannot apply guidance

**Completeness (20% - Third)**:

- **Failure severity**: Missing content reduces utility
- **Impact**: Users miss important edge cases or scenarios
- **Recovery**: Easy - can add missing content
- **Example**: Deployment skill covers happy path but omits rollback procedures

**Specificity (15% - Fourth)**:

- **Failure severity**: Vague guidance harder to apply but not wrong
- **Impact**: Users need to infer implementation details
- **Recovery**: Easy - can add examples and specifics
- **Example**: Pattern says "handle errors appropriately" without showing how

**No Overlap (10% - Lowest)**:

- **Failure severity**: Skill still useful if minor overlap exists
- **Impact**: Some context budget waste but skill adds value
- **Recovery**: Trivial - can trim generic sections
- **Example**: Skill includes "code should be readable" (generic) alongside specialized patterns

**Weight calibration**:

Weights determined by:

1. **Failure impact** - How much does poor performance harm users?
2. **Recovery cost** - How hard is it to fix after detection?
3. **Trust damage** - Does failure undermine confidence in framework?

These weights represent **organizational priorities** and should be tuned based on:

- User expertise (novices need higher self-sufficiency weight)
- Context budget constraints (tight budgets need higher no overlap weight)
- Trust requirements (high-stakes domains need higher source fidelity weight)

### LLM-as-Judge Reliability

When to trust automated scoring vs human review:

**LLM-as-Judge strengths**:

- **Consistency**: Same rubric interpretation every time (temperature = 0.0)
- **Speed**: 45 seconds vs 20 minutes human time
- **Cost**: $1.50 vs $100 opportunity cost
- **Scalability**: Can evaluate thousands of skills

**LLM-as-Judge weaknesses**:

- **Bias sensitivity**: Verbosity preference, position bias, leniency
- **Rubric ambiguity**: Vague rubric language causes interpretation variance
- **Context limits**: Cannot evaluate skills exceeding context window
- **Novel patterns**: May misidentify truly novel approaches as generic

**When to trust LLM scores**:

- Calibration shows >90% agreement with humans
- Skill fits standard patterns (not novel methodology)
- Scores are extreme (1-2 or 4-5) - less ambiguity
- Multiple dimensions agree (not just one dimension low)

**When to be skeptical**:

- Calibration agreement <90%
- Scores cluster around threshold (3-4 range) - ambiguous
- Single dimension dramatically different from others
- Novel skill structure/content LLM hasn't seen before
- Systematic bias suspected (e.g., consistently rates long skills higher)

**Mitigation strategies**:

1. **Regular calibration** - Quarterly validation against human grades
2. **Negative controls** - Verify judge catches known failures
3. **Rubric tightening** - Add concrete examples to reduce ambiguity
4. **Ensemble scoring** - Run multiple evaluations, average results
5. **Human review triggers** - Automatic escalation when scores ambiguous

**Key insight**: LLM-as-judge is a **probabilistic tool**, not ground truth. Use it as fast filter with human escalation for edge cases.

## Quick Reference

### Command Cheatsheet

```bash
# Basic test
/cogworks-test {skill-slug}

# JSON output
/cogworks-test {skill-slug} --json

# Compare to golden sample
/cogworks-test {skill-slug} --compare-against tests/datasets/golden-samples/{slug}/

# Full suite with human review prompts
/cogworks-test {skill-slug} --full

# Generate human review form
/cogworks-test {skill-slug} --generate-human-review-form

# Compare grades
/cogworks-test {skill-slug} --compare-grades \
    --human tests/calibration/{slug}-human.yaml \
    --llm tests/results/latest/{slug}-results.json

# Test all golden samples
for sample in tests/datasets/golden-samples/*/; do
    /cogworks-test "$(basename "$sample")"
done
```

### Configuration Quick Reference

**Key thresholds** (framework-config.yaml):

| Setting                    | Default | Purpose                           |
| -------------------------- | ------- | --------------------------------- |
| overall_minimum            | 0.85    | Minimum overall score to pass     |
| critical_failure_tolerance | 0       | Zero critical failures allowed    |
| llm_judge.minimum_average  | 4.0     | Minimum average across dimensions |
| max_skill_md_lines         | 500     | Context budget limit              |

**Quality dimension weights**:

| Dimension        | Weight | Rationale                 |
| ---------------- | ------ | ------------------------- |
| Source Fidelity  | 30%    | Fabrication most critical |
| Self-Sufficiency | 25%    | Must work standalone      |
| Completeness     | 20%    | Scope coverage important  |
| Specificity      | 15%    | Actionability matters     |
| No Overlap       | 10%    | Minor overlap acceptable  |

### Decision Tree

```
Start: Test skill
    ├─> Run Layer 1 (deterministic checks)
    ├─> Critical failures found?
    │   ├─> YES: Report failures, STOP (don't run Layer 2)
    │   └─> NO: Proceed to Layer 2
    ├─> Run Layer 2 (LLM-as-judge)
    ├─> Overall score ≥ 0.85?
    │   ├─> YES: PASS (report success)
    │   └─> NO: FAIL (report failures and recommendations)
    └─> Optional: Run Layer 3 (human calibration) for validation
```

### File Locations Quick Reference

```
.claude/test-framework/
├── config/
│   └── framework-config.yaml          # All settings
├── graders/
│   ├── deterministic-checks.sh        # Layer 1
│   ├── llm-judge-rubrics.md          # Layer 2
│   └── human-review-guide.md         # Layer 3
├── templates/
│   ├── test-case-template.jsonl      # Example test cases
│   └── validation-report.md          # Report template
└── scripts/
    └── calculate-agreement.py        # Calibration analysis

tests/
├── datasets/                          # Test data
├── results/                          # Test outputs (gitignored)
└── calibration/                      # Human grades
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

All claims in this reference document are traceable to these authoritative sources.
