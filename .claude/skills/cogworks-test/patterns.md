# Testing Patterns

Reusable patterns for evaluating cogworks skills and other technical documentation.

## Pattern: Layered Grading

**When to use**: Testing any skill, documentation, or generated content

**Why**: Avoid expensive LLM calls on obviously-failing content. Save time and cost by catching structural issues first.

**How**:

1. **Layer 1** (deterministic) - Fast bash checks for structure, syntax, required elements
2. **Layer 2** (LLM-judge) - Only run if Layer 1 passes, evaluates content quality
3. **Layer 3** (human) - Optional, for calibration or disputes

**Example**:

```bash
# Run Layer 1
bash deterministic-checks.sh "$SKILL_PATH" --json
EXIT_CODE=$?

# Only proceed to Layer 2 if Layer 1 passed
if [ $EXIT_CODE -eq 0 ]; then
    # Run LLM-judge evaluation
    run_llm_judge "$SKILL_PATH"
else
    echo "Critical failures in Layer 1, skipping expensive checks"
fi
```

**Cost impact**: Saves $1.50 per obviously-failing skill by catching issues in Layer 1

---

## Pattern: Stop on Critical

**When to use**: Any testing pipeline with severity levels

**Why**: Critical issues must be fixed before quality assessment matters. Don't waste resources evaluating fundamentally broken content.

**How**:

1. Define critical failures (missing frontmatter, no citations, security issues)
2. Check for critical failures first
3. If any found, stop immediately and report
4. Only proceed to quality checks if no critical failures

**Example**:

```python
def validate_skill(skill_path):
    # Layer 1: Check for critical failures
    result = run_deterministic_checks(skill_path)

    if result["critical_failures"]:
        return {
            "status": "FAIL",
            "reason": "critical_failures",
            "failures": result["critical_failures"]
        }

    # Only run expensive checks if no critical issues
    quality_result = run_llm_judge(skill_path)
    return quality_result
```

**When NOT to use**: When all checks are equally fast/cheap, no need to short-circuit

---

## Pattern: Weighted Scoring

**When to use**: Combining multiple quality dimensions with different importance

**Why**: Not all quality dimensions are equally important. Source fidelity matters more than minor style issues.

**How**:

1. Define weights for each dimension (must sum to 1.0)
2. Score each dimension independently
3. Compute weighted average
4. Use weighted score for pass/fail decision

**Example**:

```python
# From framework-config.yaml
WEIGHTS = {
    "source_fidelity": 0.30,      # Most important
    "self_sufficiency": 0.25,
    "completeness": 0.20,
    "specificity": 0.15,
    "no_overlap": 0.10            # Least important
}

def compute_weighted_score(scores):
    weighted = sum(
        scores[dimension] * WEIGHTS[dimension]
        for dimension in scores
    )
    return weighted / 5.0  # Normalize to 0-1 scale
```

**Tuning weights**: Adjust based on your priorities, but keep source_fidelity highest for factual accuracy

---

## Pattern: Machine + Human Readable Outputs

**When to use**: Generating test results, reports, or any output consumed by both humans and automation

**Why**:

- JSON for automation, CI/CD, programmatic access
- Markdown for human review, git-friendly diffs, readability

**How**:

1. Generate structured data first (JSON)
2. Transform to human-readable format (Markdown)
3. Save both side-by-side with consistent naming
4. Reference JSON path in Markdown for programmatic access

**Example**:

```python
def generate_report(results, timestamp, skill_slug):
    # Machine-readable
    json_path = f"tests/results/{timestamp}/{skill_slug}-results.json"
    write_json(json_path, results)

    # Human-readable
    md_path = f"tests/results/{timestamp}/{skill_slug}-report.md"
    markdown = render_template("validation-report.md", results)
    write_file(md_path, markdown)

    return {"json": json_path, "markdown": md_path}
```

**Git-friendly tips**: Use stable formatting (sorted keys, consistent indentation) for readable diffs

---

## Pattern: Golden Sample Regression

**When to use**: Validating that framework changes don't break known-good cases

**Why**: Catch regressions early before they affect production. Build confidence in changes.

**How**:

1. Create golden samples - known-good skills that pass validation
2. Store expected outputs (scores, structure, content)
3. Run tests against golden samples after changes
4. Compare actual vs expected with tolerance thresholds
5. Fail if significant deviation detected

**Example**:

```bash
# Test all golden samples
for sample in tests/datasets/golden-samples/*/; do
    slug=$(basename "$sample")
    expected=$(cat "$sample/metadata.yaml")

    # Run validation
    actual=$(cogworks-test "$slug" --json)

    # Compare with tolerance
    if ! compare_within_tolerance "$actual" "$expected" 0.05; then
        echo "REGRESSION: $slug deviated from expected"
        exit 1
    fi
done
```

**Tolerance**: Allow 5% deviation for LLM non-determinism, but 0% for structural checks

---

## Pattern: Negative Controls

**When to use**: Testing that validation correctly identifies failure modes

**Why**: A test that never fails is not useful. Validate that your tests can catch problems.

**How**:

1. Create negative control samples - intentionally flawed skills
2. Define expected outcome (should fail or warn)
3. Run validation on negative controls
4. Verify that validation correctly identifies the flaw
5. If negative control passes, your tests have a blind spot

**Example**:

```python
# Negative control: skill with no citations
def test_no_citations_detected():
    skill_path = "tests/datasets/negative-controls/no-citations/"
    result = validate_skill(skill_path)

    # Should fail on source fidelity
    assert result["status"] == "FAIL"
    assert "no_source_citations" in result["critical_failures"]
```

**Coverage**: Aim for ~25% of test dataset to be negative controls (from skill-evaluation)

---

## Pattern: Observable Behavior Focus

**When to use**: Evaluating skills that will be invoked by Claude in production

**Why**: What a skill DOES matters more than what it SAYS. Test actual behavior, not just documentation.

**How**:

1. Define test scenarios (user requests)
2. For each scenario, define expected behavior:
   - Should activate? (true/false)
   - What actions should it take?
   - What output should it produce?
3. Test in simulation or production-like environment
4. Verify actual behavior matches expected

**Example**:

```json
// Test case for deployment skill
{
  "scenario": "User says 'deploy to staging'",
  "should_activate": true,
  "expected_actions": ["check_git_status", "run_tests", "deploy"],
  "should_not_activate_for": [
    "write unit tests",
    "fix bug in login",
    "what is REST?"
  ]
}
```

**Limitation**: Full invocability testing requires integration with Claude execution environment

---

## Pattern: Calibration Loop

**When to use**: Validating LLM-as-judge accuracy against human evaluation

**Why**: Ensure automated grading aligns with human judgment (90%+ agreement target)

**How**:

1. **Select sample** - 20 skills across quality spectrum
2. **Human grades** - Expert evaluates using same rubrics
3. **LLM grades** - Automated evaluation on same skills
4. **Measure agreement** - Within 0.5 points on 5-point scale
5. **Adjust rubrics** - If agreement <90%, identify systematic biases and update
6. **Re-test** - Validate improvements on subset
7. **Document** - Record calibration results and rubric changes

**Example**:

```python
def calibrate_llm_judge():
    skills = select_calibration_sample(20)

    human_grades = {}
    llm_grades = {}

    for skill in skills:
        human_grades[skill] = expert_evaluate(skill)
        llm_grades[skill] = llm_judge_evaluate(skill)

    agreement = calculate_agreement(human_grades, llm_grades)

    if agreement < 0.90:
        biases = identify_systematic_biases(human_grades, llm_grades)
        adjust_rubrics(biases)
        return "NEEDS_RECALIBRATION"

    return "CALIBRATED"
```

**Frequency**: Re-calibrate quarterly or after significant rubric changes

---

## Pattern: Test Dataset Composition

**When to use**: Building a test suite for any evaluation system

**Why**: Balance between happy path (explicit examples) and edge cases (negative controls, variations)

**How**: Use 4-category composition from skill-evaluation:

- **50% Explicit examples** - Clear, positive test cases
- **15% Implicit patterns** - Requires inference
- **10% Contextual variations** - Edge cases, boundary conditions
- **25% Negative controls** - Should NOT pass

**Example**:

```yaml
# Test suite composition for deployment skill
total_tests: 40

explicit_examples: 20  # 50%
  - deploy_to_staging
  - deploy_to_production
  - rollback_deployment
  ...

implicit_patterns: 6   # 15%
  - "push my changes live"  # should recognize as deployment
  - "make it available to users"
  ...

contextual_variations: 4  # 10%
  - deploy_with_feature_flags
  - deploy_with_rollback_plan
  ...

negative_controls: 10  # 25%
  - "run tests"  # should NOT activate
  - "fix bug"
  - "write documentation"
  ...
```

**Evolution**: Start with 10-20 tests, expand to 100+ as you discover failure modes

---

## Pattern: Fail-Fast Validation

**When to use**: Pre-submission checks before expensive operations

**Why**: Catch obvious errors before committing resources to processing

**How**:

1. Define quick pre-flight checks (file exists, valid format, size limits)
2. Run these BEFORE expensive operations
3. Fail immediately with clear error message
4. Only proceed if all pre-flight checks pass

**Example**:

```bash
function validate_skill_presubmit() {
    local skill_path="$1"

    # Pre-flight checks (< 1 second)
    if [ ! -f "$skill_path/SKILL.md" ]; then
        echo "Error: SKILL.md not found"
        exit 1
    fi

    if ! grep -q "^---$" "$skill_path/SKILL.md"; then
        echo "Error: Missing frontmatter"
        exit 1
    fi

    # All pre-flight checks passed, proceed to full validation
    run_full_validation "$skill_path"
}
```

**Cost savings**: Avoids $1.50 LLM call when obvious error present

---

## Pattern: Snapshot Testing

**When to use**: Validating that generated content remains stable over time

**Why**: Detect unintended changes to generated output

**How**:

1. Generate "golden" output from known-good input
2. Save as snapshot file
3. In subsequent runs, generate output and compare to snapshot
4. If diff detected, either:
   - Bug (reject change)
   - Intentional improvement (update snapshot)

**Example**:

```bash
# Generate snapshot
cogworks-encode sources/ > snapshot.md

# Later, validate against snapshot
NEW=$(cogworks-encode sources/)
DIFF=$(diff snapshot.md <(echo "$NEW"))

if [ -n "$DIFF" ]; then
    echo "Output changed from snapshot:"
    echo "$DIFF"
    read -p "Accept change? (y/n) " -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "$NEW" > snapshot.md
    fi
fi
```

**Git-friendly**: Store snapshots in git for diff visibility
