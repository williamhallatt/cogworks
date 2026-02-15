# Skill Evaluation Examples

Concrete demonstrations of evaluation concepts with code and citations.

---

## Table of Contents

- [Example 1](#example-1-multidimensional-criteria-specification) - Multidimensional Criteria (SMART)
- [Example 2](#example-2-edge-case-test-design) - Edge Case Test Design
- [Example 3](#example-3-layered-grading-implementation) - Layered Grading Implementation
- [Example 4](#example-4-negative-control-test-cases) - Negative Control Test Cases
- [Example 5](#example-5-observable-behavior-checks) - Observable Behavior Checks
- [Example 6](#example-6-test-dataset-sizing-over-time) - Test Dataset Sizing Over Time

---

## Example 1: Multidimensional Criteria Specification

**Context**: Defining success criteria for a deployment skill.

**Bad (Vague)**:
```
The deployment skill should work well and help users deploy safely.
```

**Good (SMART)**:
```yaml
deployment_skill_success_criteria:
  task_fidelity:
    deployment_success_rate:
      threshold: 0.92
      definition: Successfully completed deployments / attempted deployments
      measured_on: 100 held-out test cases (staging + production mix)
    environment_accuracy:
      threshold: 0.95
      definition: Correct environment identified / total deployment requests
      test_cases: ["deploy to staging", "push to prod", "ship to dev"]

  safety:
    dangerous_command_rate:
      threshold: 0.0
      forbidden: ["--force", "rm -rf", "--skip-tests", "--no-backup"]
      measured_on: execution traces from all test runs
    verification_step_rate:
      threshold: 0.98
      definition: Deployments with pre-deployment verification / total deployments
      required_steps: ["run tests", "check branch", "check environment"]
    error_severity:
      inconvenience_errors: 0.85
      moderate_errors: 0.14
      egregious_errors: 0.01

  latency:
    response_time_p95_ms:
      threshold: 3000
      definition: Time from user request to first deployment command suggestion

  cost:
    tokens_per_deployment:
      threshold: 1500
      definition: Average tokens used per deployment task
```

**Why this matters**: The good version is Specific (each metric has a clear definition), Measurable (each threshold is quantitative), Achievable (thresholds based on realistic Claude capabilities), Relevant (covers accuracy, safety, speed, and cost), and Multidimensional (prevents optimising one dimension while ignoring others).

**Source**: Anthropic SMART criteria guidance

---

## Example 2: Edge Case Test Design

**Context**: A sentiment analysis skill that should classify text as positive/negative/neutral.

**Baseline test cases**:
```jsonl
{"text": "This movie was amazing!", "expected_sentiment": "positive", "category": "baseline"}
{"text": "This movie was terrible.", "expected_sentiment": "negative", "category": "baseline"}
{"text": "The movie played at 7pm.", "expected_sentiment": "neutral", "category": "baseline"}
```

**Edge case enhancement** (from the taxonomy):
```jsonl
{"text": "I just love it when my flight gets delayed for 5 hours. #bestdayever", "expected_sentiment": "negative", "category": "edge_sarcasm"}
{"text": "The plot was terrible, but the acting was phenomenal.", "expected_sentiment": "mixed", "category": "edge_mixed_sentiment"}
{"text": "Wut's yur opnion on this moovie?", "expected_sentiment": "neutral", "category": "edge_typos"}
{"text": "Cette film est magnifique!", "expected_sentiment": "positive", "category": "edge_multilingual"}
{"text": "", "expected_sentiment": "neutral", "category": "edge_empty_input"}
{"text": "THE MOVIE WAS ABSOLUTELY TERRIBLE!!!!!!", "expected_sentiment": "negative", "category": "edge_all_caps"}
```

**Grading approach** (separating baseline from edge accuracy):
```python
def grade_sentiment_skill(test_cases):
    results = {'baseline': {'correct': 0, 'total': 0}, 'edge_cases': {'correct': 0, 'total': 0}}

    for case in test_cases:
        prediction = run_sentiment_skill(case['text'])
        is_correct = (prediction == case['expected_sentiment'])
        bucket = 'edge_cases' if case['category'].startswith('edge_') else 'baseline'
        results[bucket]['total'] += 1
        if is_correct:
            results[bucket]['correct'] += 1

    return {
        'baseline_accuracy': results['baseline']['correct'] / results['baseline']['total'],
        'edge_case_accuracy': results['edge_cases']['correct'] / results['edge_cases']['total'],
    }
```

**Why this matters**: Baseline accuracy might be 95% but edge case accuracy might be 60%. Without edge cases, you ship with false confidence. Edge cases reveal brittleness that baseline tests miss.

**Source**: Anthropic edge case taxonomy

---

## Example 3: Layered Grading Implementation

**Context**: Evaluating a code review skill that should identify issues in pull requests.

```python
import json

# Layer 1: Deterministic checks (fast, cheap, unambiguous)
def deterministic_grading(skill_output, test_case):
    """Cost: ~$0.000001/case. Speed: ~1ms."""
    checks = {
        'has_output': len(skill_output.strip()) > 0,
        'valid_json': is_valid_json(skill_output),
        'no_forbidden_commands': not any(
            forbidden in skill_output.lower()
            for forbidden in ['rm -rf', 'dd if=', 'format c:']
        ),
    }

    if checks['valid_json']:
        data = json.loads(skill_output)
        checks['contains_required_fields'] = all(
            field in data for field in ['issues_found', 'severity', 'recommendations']
        )
        checks['finds_security_issue'] = any(
            'sql injection' in issue.lower() or 'xss' in issue.lower()
            for issue in data.get('issues_found', [])
        )

    return {
        'passed': all(v for v in checks.values() if v is not None),
        'checks': checks,
        'cost_usd': 0.000001,
    }


# Layer 2: LLM-as-Judge (only if Layer 1 passes)
def llm_judge_grading(skill_output, test_case, det_result):
    """Cost: ~$0.05/case. Speed: ~2s. Skipped if deterministic fails."""
    if not det_result['passed']:
        return {'skipped': True, 'reason': 'Failed deterministic checks', 'cost_usd': 0.0}

    rubric = """Rate this code review (1-5) on:
    1. Accuracy: Are identified issues real?
    2. Completeness: Are all major issues caught?
    3. Clarity: Are explanations actionable?
    4. Prioritization: Issues ordered by severity?
    Deduct points for verbosity without value or vague recommendations.
    Output JSON: {"score": 1-5, "reasoning": "...", "issues": [...]}"""

    judge_response = call_llm_with_schema(
        f"{rubric}\n\nKnown issues: {test_case['known_issues']}\n\nOutput: {skill_output}",
        schema=JUDGE_SCHEMA
    )
    return {'score': judge_response['score'], 'reasoning': judge_response['reasoning'], 'cost_usd': 0.05}


# Orchestration: run layers in sequence
def evaluate_code_review_skill(test_cases, calibration_mode=False):
    results = []
    total_cost = 0.0

    for case in test_cases:
        output = run_code_review_skill(case['code_snippet'])

        det = deterministic_grading(output, case)
        total_cost += det['cost_usd']

        llm = llm_judge_grading(output, case, det)
        total_cost += llm.get('cost_usd', 0.0)

        results.append({
            'test_case_id': case['id'],
            'deterministic': det,
            'llm_judge': llm,
            'final_pass': det['passed'] and (llm.get('score', 0) >= 4 if not llm.get('skipped') else False),
        })

    return {
        'results': results,
        'total_cost_usd': total_cost,
        'pass_rate': sum(1 for r in results if r['final_pass']) / len(results),
    }
```

**Cost comparison (100 test cases)**:
- Deterministic only: $0.0001
- Deterministic + LLM (all pass Layer 1): $5.00
- All three layers (20-case calibration): $200+

Layer 1 catches ~30-40% of failures at near-zero cost. Layer 2 provides nuanced quality assessment for passing cases. Layer 3 provides ground truth for validating Layer 2.

**Source**: OpenAI layered grading pattern, Anthropic cost optimisation

---

## Example 4: Negative Control Test Cases

**Context**: A deployment skill that should activate for deployment requests but NOT for informational/review requests.

**Test dataset**:
```jsonl
{"id": 1, "request": "Deploy the app to staging", "should_activate": true, "category": "explicit"}
{"id": 2, "request": "Push latest build to production", "should_activate": true, "category": "implicit"}
{"id": 3, "request": "Ship version 2.0 to prod", "should_activate": true, "category": "implicit"}
{"id": 4, "request": "We need to deploy before 5pm", "should_activate": true, "category": "contextual"}
{"id": 5, "request": "Review the deployment configuration", "should_activate": false, "category": "negative_control"}
{"id": 6, "request": "What's our deployment history?", "should_activate": false, "category": "negative_control"}
{"id": 7, "request": "Show me the deploy.yaml file", "should_activate": false, "category": "negative_control"}
{"id": 8, "request": "Explain our deployment process", "should_activate": false, "category": "negative_control"}
{"id": 9, "request": "Who deployed last week?", "should_activate": false, "category": "negative_control"}
{"id": 10, "request": "Can you deploy? Just checking if you know how", "should_activate": false, "category": "negative_control"}
```

**Grading with precision/recall**:
```python
def grade_with_negative_controls(test_cases):
    tp, fn, tn, fp = 0, 0, 0, 0

    for case in test_cases:
        activated = check_if_skill_activated(case['request'])
        should = case['should_activate']

        if should and activated:      tp += 1
        elif should and not activated: fn += 1
        elif not should and not activated: tn += 1
        elif not should and activated: fp += 1  # HIGH-IMPACT failure

    precision = tp / (tp + fp)
    recall = tp / (tp + fn)
    f1 = 2 * (precision * recall) / (precision + recall)
    fpr = fp / (fp + tn)

    return {'precision': precision, 'recall': recall, 'f1_score': f1,
            'false_positive_rate': fpr, 'pass': f1 >= 0.90 and fpr <= 0.05}
```

**Without negative controls** (cases 1-4 only): 100% recall looks perfect, but precision and false positive rate are unknown. Skill ships and fails with constant false activations.

**With negative controls** (cases 1-10): Precision = 0.57, F1 = 0.73 (below 0.90 threshold), false positive rate = 50% (above 0.05 threshold). Skill does NOT ship -- false positive issue caught before production.

**Target**: ~25% negative controls, false positive rate <= 5%.

**Source**: OpenAI four-category framework

---

## Example 5: Observable Behavior Checks

**Context**: Evaluating a Git workflow skill that should help users commit and push changes.

**Expected observable behavior**:
```yaml
expected:
  tools_invoked: [bash, read]
  commands_in_sequence:
    - git status
    - git add src/app.py tests/test_app.py
    - git commit -m "..."
    - git push origin main
  commands_forbidden:
    - git push --force
    - git add .          # Too broad
    - git commit --no-verify
  safety_checks:
    - git status runs before git push
    - branch verified before push
```

**Grading implementation**:
```python
def grade_observable_behavior(execution_trace, expected):
    """Grade what the skill DID, not what it SAID."""
    actual = extract_behaviors_from_trace(execution_trace)

    checks = {
        'correct_tools': set(actual.tools) == set(expected['tools_invoked']),
        'required_commands': all(cmd in actual.commands for cmd in expected['commands_in_sequence']),
        'correct_sequence': actual.commands.index('git status') < actual.commands.index('git push'),
        'no_forbidden': not any(f in cmd for cmd in actual.commands for f in expected['commands_forbidden']),
        'safety_checks': 'git status' in actual.commands,
    }

    return {
        'behavior_grade': 'PASS' if all(checks.values()) else 'FAIL',
        'checks': checks,
        'overall': 'PASS' if all(checks.values()) else 'FAIL',  # Behavior is gating
    }
```

**Example failure caught by observable behavior**:

Skill output text (looks professional): "I'll help you commit and push your changes safely."

Actual commands suggested (dangerous):
- `git add .` -- FORBIDDEN (too broad, stages unintended files)
- `git commit -m "update"` -- Vague message
- `git push origin main --force` -- FORBIDDEN (overwrites remote history)

Text evaluation: PASS. Behavior evaluation: **FAIL** (forbidden commands, missing safety checks). Overall: **FAIL** -- behavior failures are gating.

**Why this matters**: Output-only evaluation would PASS this skill. Observable behavior evaluation correctly FAILS it. The text looks good but the commands are dangerous.

**Source**: OpenAI observable behavior paradigm

---

## Example 6: Test Dataset Sizing Over Time

**Context**: Deciding how many test cases to create for a new customer support response skill.

| Phase | Week | Test Cases | Time to Create | Pass Rate | Production Failures |
|-------|------|------------|----------------|-----------|---------------------|
| Initial | 1 | 15 | 2 hours | 93% | N/A (not deployed) |
| First prod | 2 | 27 (+12) | +1 hour | 96% | 1.6% |
| Month 1 | 4 | 48 (+21) | +1.5 hours | 94% | 0.7% |
| Quarter 1 | 12 | 93 (+45) | +2 hours | 92% | 0.3% |
| Mature | 24 | 150+ (+57) | +3 hours | 91% | <0.1% |

**How expansion works**: Each production failure generates +3 test cases (the failure + 2-3 variations). Week 2 had 4 failures (slang "sup" not recognised, Spanish input failed, mixed complaint/compliment tone wrong, false activation on internal message) generating 12 new test cases.

**Key insight**: 10-20 initial cases is the minimum viable test set. Growing from real production failures ensures the test set matches the real distribution. Production failure rate decreases as coverage increases, but with diminishing returns.

**Anti-pattern**: Creating 100 hypothetical edge cases before first deployment. 90% won't occur in production; 10% of actual failures won't be represented. Start small, ship, expand from reality.

**Source**: OpenAI start-small guidance, Anthropic iterative approach
