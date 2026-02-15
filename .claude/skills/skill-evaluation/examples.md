# Skill Evaluation Examples

## Example 1: Multidimensional Criteria for Deployment Skill

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
      inconvenience_errors: 0.85  # 85% of failures are minor (wrong env selected)
      moderate_errors: 0.14       # 14% are moderate (deployment partial)
      egregious_errors: 0.01      # 1% are egregious (data loss risk)

  latency:
    response_time_p95_ms:
      threshold: 3000
      definition: Time from user request to first deployment command suggestion
      measured_on: production traffic sample (n=1000)

    unnecessary_steps:
      threshold: 0.05
      definition: Deployments with >2 unnecessary commands / total deployments

  cost:
    tokens_per_deployment:
      threshold: 1500
      definition: Average tokens used per deployment task

    cost_per_deployment_usd:
      threshold: 0.08
      calculation: (tokens_per_deployment * cost_per_token)
```

**Why this matters**: The good version is:
- **Specific**: Each metric has a clear definition
- **Measurable**: Each threshold is quantitative
- **Achievable**: Thresholds based on realistic Claude capabilities
- **Relevant**: Covers accuracy, safety, speed, and cost
- **Multidimensional**: Prevents optimizing one dimension while ignoring others

**Source**: Anthropic SMART criteria guidance

---

## Example 2: Edge Case Test Design for Sentiment Analysis

**Context**: A sentiment analysis skill that should classify text as positive/negative/neutral.

**Baseline Test Cases (Clean)**:
```jsonl
{"text": "This movie was amazing!", "expected_sentiment": "positive"}
{"text": "This movie was terrible.", "expected_sentiment": "negative"}
{"text": "The movie played at 7pm.", "expected_sentiment": "neutral"}
```

**Edge Case Enhancement**:

```jsonl
{"text": "This movie was amazing!", "expected_sentiment": "positive", "category": "baseline"}

{"text": "I just love it when my flight gets delayed for 5 hours. #bestdayever", "expected_sentiment": "negative", "category": "edge_sarcasm"}

{"text": "The plot was terrible, but the acting was phenomenal.", "expected_sentiment": "mixed", "category": "edge_mixed_sentiment"}

{"text": "Wut's yur opnion on this moovie?", "expected_sentiment": "neutral", "category": "edge_typos"}

{"text": "Cette film est magnifique!", "expected_sentiment": "positive", "category": "edge_multilingual_french"}

{"text": "这部电影很好看", "expected_sentiment": "positive", "category": "edge_multilingual_chinese"}

{"text": "The movie 😍🎬🎭🎪", "expected_sentiment": "positive", "category": "edge_emoji_only"}

{"text": "", "expected_sentiment": "neutral", "category": "edge_empty_input"}

{"text": "THE MOVIE WAS ABSOLUTELY TERRIBLE AND I HATED EVERY SECOND OF IT!!!!!!", "expected_sentiment": "negative", "category": "edge_all_caps_excessive"}

{"text": "movie" * 1000, "expected_sentiment": "neutral", "category": "edge_excessive_length"}
```

**Grading Approach**:
```python
def grade_sentiment_skill(test_cases):
    results = {
        'baseline': {'correct': 0, 'total': 0},
        'edge_cases': {'correct': 0, 'total': 0},
    }

    for case in test_cases:
        prediction = run_sentiment_skill(case['text'])
        expected = case['expected_sentiment']
        is_correct = (prediction == expected)

        category = 'edge_cases' if case['category'].startswith('edge_') else 'baseline'
        results[category]['total'] += 1
        if is_correct:
            results[category]['correct'] += 1

    return {
        'baseline_accuracy': results['baseline']['correct'] / results['baseline']['total'],
        'edge_case_accuracy': results['edge_cases']['correct'] / results['edge_cases']['total'],
        'overall_accuracy': (results['baseline']['correct'] + results['edge_cases']['correct']) /
                            (results['baseline']['total'] + results['edge_cases']['total']),
    }
```

**Why this matters**:
- Baseline accuracy might be 95%
- Edge case accuracy might be 60%
- Without edge cases in the test set, you'd ship with false confidence
- Edge cases reveal brittleness that baseline tests miss

**Source**: Anthropic edge case taxonomy

---

## Example 3: Layered Grading Implementation

**Context**: Evaluating a code review skill that should identify issues in pull requests.

```python
import re
import json

# Layer 1: Deterministic checks (fast, cheap, unambiguous)
def deterministic_grading(skill_output, test_case):
    """
    Cost: ~$0.000001 per case
    Speed: ~1ms per case
    """
    checks = {
        'has_output': len(skill_output.strip()) > 0,
        'valid_json': is_valid_json(skill_output),
        'contains_required_fields': None,
        'no_forbidden_commands': not any(
            forbidden in skill_output.lower()
            for forbidden in ['rm -rf', 'dd if=', 'format c:']
        ),
        'finds_security_issue': None,
    }

    # JSON structure check
    if checks['valid_json']:
        try:
            data = json.loads(skill_output)
            checks['contains_required_fields'] = all(
                field in data
                for field in ['issues_found', 'severity', 'recommendations']
            )
            checks['finds_security_issue'] = any(
                'sql injection' in issue.lower() or 'xss' in issue.lower()
                for issue in data.get('issues_found', [])
            )
        except:
            checks['contains_required_fields'] = False
            checks['finds_security_issue'] = False

    passed = all(v for v in checks.values() if v is not None)
    return {
        'layer': 'deterministic',
        'passed': passed,
        'checks': checks,
        'cost_usd': 0.000001,
    }


# Layer 2: LLM-as-Judge (moderate cost, high nuance)
def llm_judge_grading(skill_output, test_case, deterministic_result):
    """
    Cost: ~$0.05 per case
    Speed: ~2 seconds per case
    Only run if deterministic checks pass
    """
    if not deterministic_result['passed']:
        return {
            'layer': 'llm_judge',
            'skipped': True,
            'reason': 'Failed deterministic checks',
            'cost_usd': 0.0,
        }

    rubric = """
    Rate this code review output (1-5 scale) on:
    1. Accuracy: Are identified issues real? (not false positives)
    2. Completeness: Are all major issues caught?
    3. Clarity: Are explanations clear and actionable?
    4. Prioritization: Are issues ordered by severity?

    Deduct points for:
    - Verbosity without value (>500 words for simple issue)
    - Vague recommendations ("fix the bug" vs "add input validation")

    Output JSON: {
        "score": 1-5,
        "accuracy_score": 1-5,
        "completeness_score": 1-5,
        "clarity_score": 1-5,
        "prioritization_score": 1-5,
        "reasoning": "Detailed explanation",
        "issues_identified": ["issue1", "issue2"]
    }
    """

    judge_prompt = f"""
    {rubric}

    Test case context:
    {test_case['code_snippet']}

    Known issues in this code:
    {test_case['known_issues']}

    Skill output to grade:
    {skill_output}
    """

    judge_response = call_llm_with_schema(judge_prompt, schema=JUDGE_SCHEMA)

    return {
        'layer': 'llm_judge',
        'score': judge_response['score'],
        'subscores': {
            'accuracy': judge_response['accuracy_score'],
            'completeness': judge_response['completeness_score'],
            'clarity': judge_response['clarity_score'],
            'prioritization': judge_response['prioritization_score'],
        },
        'reasoning': judge_response['reasoning'],
        'cost_usd': 0.05,
    }


# Layer 3: Human evaluation (expensive, slow, highest quality)
def human_grading(skill_output, test_case, llm_judge_result):
    """
    Cost: ~$10 per case
    Speed: ~10 minutes per case (expert review)
    Only run for calibration sample
    """
    # This would be a manual review interface in practice
    # For calibration: run on 20-50 cases to validate LLM judge
    return {
        'layer': 'human',
        'score': None,  # Set by human reviewer
        'notes': None,  # Human reviewer comments
        'cost_usd': 10.0,
    }


# Orchestration: run layers in sequence
def evaluate_code_review_skill(test_cases, calibration_mode=False):
    results = []
    total_cost = 0.0

    for test_case in test_cases:
        skill_output = run_code_review_skill(test_case['code_snippet'])

        # Layer 1: Always run
        det_result = deterministic_grading(skill_output, test_case)
        total_cost += det_result['cost_usd']

        # Layer 2: Only if Layer 1 passes
        llm_result = llm_judge_grading(skill_output, test_case, det_result)
        total_cost += llm_result.get('cost_usd', 0.0)

        # Layer 3: Only in calibration mode, on sample
        human_result = None
        if calibration_mode and len(results) < 20:  # First 20 cases only
            human_result = human_grading(skill_output, test_case, llm_result)
            total_cost += human_result['cost_usd']

        results.append({
            'test_case_id': test_case['id'],
            'deterministic': det_result,
            'llm_judge': llm_result,
            'human': human_result,
            'final_pass': det_result['passed'] and
                          (llm_result.get('score', 0) >= 4 if not llm_result.get('skipped') else False),
        })

    return {
        'results': results,
        'total_cost_usd': total_cost,
        'pass_rate': sum(1 for r in results if r['final_pass']) / len(results),
    }


# Example usage
test_cases = [
    {
        'id': 1,
        'code_snippet': 'SELECT * FROM users WHERE id = ' + user_input,
        'known_issues': ['SQL injection vulnerability'],
    },
    # ... more test cases
]

# Development: run without human grading (fast, cheap)
dev_results = evaluate_code_review_skill(test_cases, calibration_mode=False)
print(f"Pass rate: {dev_results['pass_rate']:.2%}")
print(f"Cost: ${dev_results['total_cost_usd']:.4f}")

# Calibration: include human grading on sample (slow, expensive)
calibration_results = evaluate_code_review_skill(test_cases[:20], calibration_mode=True)
```

**Cost Comparison**:
- 100 test cases, deterministic only: $0.0001
- 100 test cases, deterministic + LLM (all pass Layer 1): $5.00
- 20 test cases, all three layers (calibration): $200.00

**Why this matters**:
- Layering saves cost by not running expensive grading on obviously-failing cases
- Layer 1 catches ~30-40% of failures immediately at near-zero cost
- Layer 2 provides nuanced quality assessment for cases passing Layer 1
- Layer 3 provides ground truth for validating Layer 2

**Source**: OpenAI layered grading pattern, Anthropic cost optimization

---

## Example 4: Negative Control Test Cases

**Context**: A deployment skill that should activate for deployment requests but NOT for informational/review requests.

**Test Dataset with Negative Controls**:

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

**Grading Logic**:

```python
def grade_with_negative_controls(test_cases):
    results = {
        'true_positives': 0,   # Correctly activated
        'false_negatives': 0,  # Should activate but didn't
        'true_negatives': 0,   # Correctly stayed silent
        'false_positives': 0,  # Activated when shouldn't
    }

    for case in test_cases:
        skill_activated = check_if_skill_activated(case['request'])
        should_activate = case['should_activate']

        if should_activate and skill_activated:
            results['true_positives'] += 1
        elif should_activate and not skill_activated:
            results['false_negatives'] += 1
        elif not should_activate and not skill_activated:
            results['true_negatives'] += 1
        elif not should_activate and skill_activated:
            results['false_positives'] += 1
            # THIS IS CRITICAL - false activations are high-impact failures

    # Calculate metrics
    precision = results['true_positives'] / (results['true_positives'] + results['false_positives'])
    recall = results['true_positives'] / (results['true_positives'] + results['false_negatives'])
    f1_score = 2 * (precision * recall) / (precision + recall)
    false_positive_rate = results['false_positives'] / (results['false_positives'] + results['true_negatives'])

    return {
        'precision': precision,
        'recall': recall,
        'f1_score': f1_score,
        'false_positive_rate': false_positive_rate,
        'breakdown': results,
        'pass': f1_score >= 0.90 and false_positive_rate <= 0.05,  # Both matter!
    }
```

**Example Results**:

**Scenario A: No Negative Controls (Incomplete)**
```python
# Test dataset: only positive cases (id 1-4)
{
    'recall': 1.00,  # All positive cases activated (looks perfect!)
    'precision': ???,  # Unknown - no negative controls to measure false positives
    'false_positive_rate': ???  # Unknown
}
# Skill ships, then fails in production with constant false activations
```

**Scenario B: With Negative Controls (Complete)**
```python
# Test dataset: positive + negative cases (id 1-10)
{
    'precision': 0.57,  # Low! (4 true positives, 3 false positives)
    'recall': 1.00,      # High! (all positive cases caught)
    'f1_score': 0.73,    # Below 0.90 threshold - FAIL
    'false_positive_rate': 0.50,  # Way above 0.05 threshold - FAIL
    'breakdown': {
        'true_positives': 4,
        'false_negatives': 0,
        'true_negatives': 3,
        'false_positives': 3,  # Skill activates on "Review...", "Show me...", "Explain..."
    }
}
# Skill does NOT ship - false positive issue caught before production
```

**Why this matters**:
- Without negative controls, you'd ship a skill with 100% recall but 50% false positive rate
- Users would experience constant inappropriate activations
- Trust would erode faster than value is created
- The skill would be disabled

**Target**: ~25% negative controls, false positive rate ≤ 5%

**Source**: OpenAI four-category framework, negative control emphasis

---

## Example 5: Observable Behavior Checks

**Context**: Evaluating a Git workflow skill that should help users commit and push changes.

**Test Case**:
```json
{
  "user_request": "Commit my changes and push to the main branch",
  "files_modified": ["src/app.py", "tests/test_app.py"],
  "current_branch": "feature-123"
}
```

**Observable Behavior Specification**:
```yaml
expected_observable_behavior:
  tools_invoked:
    - bash
    - read  # Should read git status, current branch

  commands_suggested_in_sequence:
    - git status  # Check current state
    - git add src/app.py tests/test_app.py  # Stage specific files
    - git commit -m "..."  # Commit with message
    - git checkout main  # Switch to main (currently on feature-123)
    - git pull origin main  # Update main
    - git merge feature-123  # Merge feature branch
    - git push origin main  # Push to remote

  commands_forbidden:
    - git push --force
    - git push -f
    - git add .  # Too broad, should be specific files
    - git commit --no-verify  # Bypasses hooks

  files_checked:
    - .git/config  # Should verify remote configuration
    - .git/HEAD  # Should check current branch

  safety_checks:
    - verify_on_correct_branch: true  # Must check branch before push
    - verify_remote_exists: true  # Must verify remote before push
    - no_uncommitted_changes: true  # Must verify clean state
```

**Grading Implementation**:

```python
def grade_observable_behavior(execution_trace, expected):
    """Grade what the skill actually DID, not what it SAID"""

    actual = extract_behaviors_from_trace(execution_trace)

    checks = {
        'correct_tools_used': (
            set(actual.tools_invoked) == set(expected.tools_invoked)
        ),

        'required_commands_present': all(
            required in actual.commands_suggested
            for required in expected.commands_suggested_in_sequence
        ),

        'correct_command_sequence': verify_sequence(
            actual.commands_suggested,
            expected.commands_suggested_in_sequence
        ),

        'no_forbidden_commands': not any(
            forbidden in cmd.lower()
            for cmd in actual.commands_suggested
            for forbidden in expected.commands_forbidden
        ),

        'safety_checks_performed': all([
            'git status' in actual.commands_suggested,
            actual.commands_suggested.index('git status') < actual.commands_suggested.index('git push'),
            'git branch' in actual.commands_suggested or 'git rev-parse --abbrev-ref HEAD' in actual.commands_suggested,
        ]),

        'files_checked_before_action': all(
            file in actual.files_read
            for file in expected.files_checked
        ),
    }

    # Text quality is SECONDARY to behavior
    text_checks = {
        'explains_branch_switch': 'switching to main' in execution_trace.output_text.lower(),
        'warns_about_merge': 'merge' in execution_trace.output_text.lower(),
    }

    return {
        'behavior_grade': 'PASS' if all(checks.values()) else 'FAIL',
        'behavior_checks': checks,
        'text_grade': 'PASS' if all(text_checks.values()) else 'ACCEPTABLE',
        'text_checks': text_checks,
        'overall': 'PASS' if all(checks.values()) else 'FAIL',  # Behavior is gating
    }


def verify_sequence(actual_commands, expected_sequence):
    """Verify commands appear in the correct order"""
    actual_indices = {}
    for i, cmd in enumerate(actual_commands):
        for expected in expected_sequence:
            if expected.lower() in cmd.lower():
                if expected not in actual_indices:
                    actual_indices[expected] = i

    # Check if all expected commands found
    if len(actual_indices) != len(expected_sequence):
        return False

    # Check if order is preserved
    for i in range(len(expected_sequence) - 1):
        curr = expected_sequence[i]
        next_cmd = expected_sequence[i + 1]
        if actual_indices[curr] >= actual_indices[next_cmd]:
            return False  # Order violated

    return True
```

**Example Failure Caught by Observable Behavior**:

```python
# Skill output (text looks good):
skill_output_text = """
I'll help you commit and push your changes. Here's what we'll do:
1. Stage your files
2. Commit with a message
3. Push to main branch

This will ensure your changes are safely stored in the repository.
"""

# Observable behavior (DANGEROUS):
actual_commands = [
    'git add .',  # FORBIDDEN - too broad
    'git commit -m "update"',  # Vague message
    'git push origin main --force',  # FORBIDDEN - force push
]

# Grading result:
{
    'behavior_grade': 'FAIL',
    'behavior_checks': {
        'correct_tools_used': True,
        'required_commands_present': False,  # Missing git status, branch checks
        'correct_command_sequence': False,  # Wrong order
        'no_forbidden_commands': False,  # Contains --force
        'safety_checks_performed': False,  # Missing safety checks
    },
    'text_grade': 'PASS',  # Text explanation is fine
    'overall': 'FAIL',  # Behavior failures are gating
}
```

**Why this matters**:
- The text explanation looks professional and helpful
- But the actual commands suggested are DANGEROUS:
  - `git add .` stages everything, including files that shouldn't be committed
  - `--force` can overwrite remote history and cause data loss
  - No safety checks (branch verification, clean state check)
- Output-only evaluation would PASS this (text is good)
- Observable behavior evaluation correctly FAILS it (commands are unsafe)

**Source**: OpenAI observable behavior paradigm

---

## Example 6: Test Dataset Sizing Guidance

**Context**: Deciding how many test cases to create for a new customer support response skill.

**Phase-by-Phase Approach**:

**Phase 1: Initial Development (Week 1)**
```
Test cases: 15
Composition:
  - 8 explicit triggers: "Help customer with X" variations
  - 3 implicit triggers: "Customer asks about Y"
  - 1 contextual: "Customer email contains Z"
  - 3 negative controls: "Internal discussion about customers" (should NOT trigger)

Time investment: 2 hours to create
Pass threshold: 13/15 (87%)

Result: Skill built, passes 14/15 (93%)
```

**Phase 2: First Production Week (Week 2)**
```
Production usage: 247 customer interactions
Failures observed: 4
  - Customer used slang "sup" instead of "support" → skill didn't activate
  - Customer wrote in Spanish → skill failed
  - Customer mixed complaint with compliment → wrong tone
  - Skill activated on internal Slack message mentioning "customer"

Action: Add 4 × 3 = 12 new test cases (3 variations per failure)

New test cases: 12
  - 3 slang variations: "sup", "help me out", "need assistance"
  - 3 multilingual: Spanish, French, Mandarin
  - 3 mixed sentiment: complaint + compliment combinations
  - 3 negative controls: internal messages that shouldn't trigger

Total test cases: 27
Pass threshold: 24/27 (89%)

Result: Retrained/fixed, now passes 26/27 (96%)
```

**Phase 3: Month 1 Review (Week 4)**
```
Production usage: 1,032 customer interactions
Failures observed: 7 more
  - Edge cases with excessive length (5000+ word rants)
  - Sarcasm not detected
  - Multi-turn conversations losing context
  - etc.

Action: Add 7 × 3 = 21 new test cases

Total test cases: 48
Pass threshold: 43/48 (90%)
```

**Phase 4: Quarter 1 Review (Week 12)**
```
Production usage: 12,450 customer interactions
Failures observed: 15 more (but rate is decreasing)

Action: Add 15 × 3 = 45 new test cases

Total test cases: 93
Pass threshold: 84/93 (90%)
```

**Phase 5: Mature Skill (Month 6)**
```
Total test cases: 150+
Pass threshold: 135/150 (90%)
Production failure rate: <1% (down from ~1.6% in Week 2)

Edge case coverage:
  - Multilingual: 12 languages
  - Slang/informal: 20 variations
  - Sentiment: 15 mixed/ambiguous cases
  - Length: 5 excessive length cases
  - Format: 8 unusual format cases
  - Negative controls: 35 cases
```

**Key Metrics by Phase**:

| Phase | Week | Test Cases | Time to Create | Pass Rate | Production Failures |
|-------|------|------------|----------------|-----------|---------------------|
| 1. Initial | 1 | 15 | 2 hours | 93% | N/A (not deployed) |
| 2. First Prod | 2 | 27 | +1 hour | 96% | 1.6% |
| 3. Month 1 | 4 | 48 | +1.5 hours | 94% | 0.7% |
| 4. Quarter 1 | 12 | 93 | +2 hours | 92% | 0.3% |
| 5. Mature | 24 | 150+ | +3 hours | 91% | <0.1% |

**Why this matters**:
- Starting with 100+ cases delays shipping by weeks (unnecessary)
- Starting with <10 cases leads to high production failure rate (risky)
- 10-20 initial cases is the minimum viable test set
- Growing from real production failures (not speculation) ensures test set matches real distribution
- Failure rate decreases as test coverage increases, but with diminishing returns

**Anti-pattern**: Creating 100 hypothetical edge cases before first deployment
- 90% of hypothetical edges don't occur in production
- 10% of actual failures aren't represented in hypothetical edges
- Weeks of work on low-value test cases

**Better**: Start small (15 cases), ship, expand from real failures (organic growth to 150+ over 6 months)

**Source**: OpenAI start-small guidance, Anthropic iterative approach
