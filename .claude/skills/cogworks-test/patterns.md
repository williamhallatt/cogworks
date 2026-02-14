# Testing Patterns

Reusable patterns for evaluating cogworks skills and other technical documentation.

## Pattern: Layered Grading with Early Termination

**When to use**: Testing any content where validation methods have different costs.

**Why**: Cost asymmetry between validation layers (150,000× between deterministic and LLM) means running expensive checks on obviously-failing content wastes resources. Cheap checks act as a fast-reject filter.

**How**:

1. Define validation layers ordered by cost (cheapest first)
2. Define critical failures that block progression to the next layer
3. Run each layer sequentially; stop on critical failure
4. Only run expensive checks on content that passes cheap checks

**Example**:

```bash
# Layer 1: deterministic (seconds, ~free)
bash deterministic-checks.sh "$SKILL_PATH" --json > results.json
if [ "$(jq -r '.critical_failures | length' results.json)" -gt 0 ]; then
    echo "Critical failures found, skipping expensive checks"
    exit 1
fi

# Layer 2: LLM-judge (minutes, ~$1.50) — only reached if Layer 1 passes
run_llm_judge "$SKILL_PATH"
```

**When NOT to use**: When all checks are equally cheap, or when you need all results regardless of failures.

---

## Pattern: Weighted Multi-Dimension Scoring

**When to use**: Combining multiple quality dimensions with different importance levels.

**Why**: Simple averaging treats all dimensions equally. Weighting lets you encode priorities — fabrication matters more than minor style issues.

**How**:

1. Define dimensions and assign weights that sum to 1.0
2. Score each dimension independently (same scale)
3. Compute weighted average
4. Compare against threshold for pass/fail

**Example**:

```python
WEIGHTS = {"accuracy": 0.40, "clarity": 0.35, "novelty": 0.25}

def compute_score(dimension_scores):
    weighted = sum(dimension_scores[d] * WEIGHTS[d] for d in dimension_scores)
    return weighted / max_score  # Normalize to 0-1
```

**Tuning**: Adjust weights based on audience and use case. Document the rationale for each weight.

---

## Pattern: Dual-Format Reporting

**When to use**: Generating results consumed by both humans and automation.

**Why**: JSON for programmatic access and CI/CD; Markdown for human review and git-friendly diffs. Generating both from the same data ensures consistency.

**How**:

1. Generate structured data first (JSON)
2. Transform to human-readable format (Markdown) from the same data
3. Save both with consistent naming: `{slug}-results.json`, `{slug}-report.md`

**Example**:

```python
def generate_report(results, timestamp, slug):
    json_path = f"results/{timestamp}/{slug}-results.json"
    write_json(json_path, results)

    md_path = f"results/{timestamp}/{slug}-report.md"
    write_file(md_path, render_template("report.md", results))
```

**Git-friendly tip**: Use sorted keys and consistent indentation for readable diffs.

---

## Pattern: Golden Sample Regression

**When to use**: Validating that framework changes don't break known-good cases.

**Why**: Without regression testing, framework improvements can silently degrade quality detection. Golden samples provide a stable baseline.

**How**:

1. Create golden samples — known-good outputs with documented expected results
2. Store expected scores and structure alongside the sample
3. After framework changes, re-run validation on golden samples
4. Compare actual vs expected with tolerance for non-determinism
5. Fail if deviation exceeds tolerance

**Example**:

```bash
for sample in tests/datasets/golden-samples/*/; do
    slug=$(basename "$sample")
    expected=$(cat "$sample/metadata.yaml")
    actual=$(run_validation "$slug" --json)

    if ! compare_within_tolerance "$actual" "$expected" 0.05; then
        echo "REGRESSION: $slug deviated from expected"
        exit 1
    fi
done
```

**Tolerance**: Allow 5% for LLM non-determinism, 0% for structural checks. Store snapshots in git for diff visibility. When output legitimately improves, update the golden sample.

---

## Pattern: Negative Controls

**When to use**: Testing that validation correctly identifies failure modes.

**Why**: A test suite that never fails is worthless. Negative controls verify your validators can catch problems.

**How**:

1. Create intentionally flawed inputs (missing citations, sparse content, generic overlap)
2. Define expected outcome (should fail, should warn, specific failure type)
3. Run validation on negative controls
4. Assert validation detects the expected flaw
5. If a negative control passes, your validator has a blind spot

**Example**:

```python
def test_no_citations_detected():
    result = validate_skill("tests/negative-controls/no-citations/")
    assert result["status"] == "FAIL"
    assert "no_source_citations" in result["critical_failures"]
```

**Coverage**: Aim for ~25% of test dataset to be negative controls.

---

## Pattern: Observable Behavior Testing

**When to use**: Evaluating skills that will be invoked by Claude in production.

**Why**: What a skill DOES matters more than what it SAYS. Static quality checks can miss invocability problems.

**How**:

1. Define test scenarios (user requests that should/shouldn't activate the skill)
2. For each scenario, define expected behavior (activates, actions taken, output format)
3. Test in simulation or production-like environment
4. Verify actual behavior matches expected

**Example**:

```json
{
  "scenario": "User says 'deploy to staging'",
  "should_activate": true,
  "expected_actions": ["check_git_status", "run_tests", "deploy"],
  "should_not_activate_for": ["write unit tests", "fix bug in login"]
}
```

**Limitation**: Full invocability testing requires integration with Claude's execution environment.

---

## Pattern: Calibration Loop

**When to use**: Validating automated grading accuracy against human judgment.

**Why**: Automated graders (LLM-as-judge) have biases. Calibration quantifies reliability and reveals systematic errors.

**How**:

1. Select diverse sample (20+ items across quality spectrum)
2. Human grades using same rubrics as automated grader
3. Automated grading on same items
4. Measure agreement (within tolerance threshold)
5. If agreement < target, identify systematic biases and update rubrics
6. Re-test on subset to confirm improvement

**Target**: 90%+ agreement within 0.5 points on 5-point scale.

**Frequency**: Re-calibrate quarterly or after significant rubric changes.

---

## Pattern: Test Dataset Composition

**When to use**: Building a test suite for any evaluation system.

**Why**: Balanced datasets prevent overfitting to happy-path scenarios.

**How**: Use 4-category composition:

- **50% Explicit examples** — Clear, positive test cases
- **15% Implicit patterns** — Requires inference (e.g., "push my changes live" → deployment)
- **10% Contextual variations** — Edge cases, boundary conditions
- **25% Negative controls** — Should NOT pass

**Evolution**: Start with 10-20 tests. Expand to 100+ as you discover failure modes. Each discovered failure mode becomes a new test case.
