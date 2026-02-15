# Skill Evaluation Reference

## Core Concepts

### 1. Success Criteria

**Definition**: Specific, measurable, achievable, and relevant goals that define when a skill is "good enough to publish." Must be quantifiable (e.g., "F1 score ≥ 0.85" not "good performance") and multidimensional (covering task fidelity, consistency, latency, safety). Transforms subjective assessment into objective measurement.

**Source**: Anthropic - Define Success Criteria

**The SMART Framework**:
- **Specific**: Not "the skill should help with deployment" but "the skill should correctly identify deployment context in 9/10 cases where `deploy`, `ship`, or `release` appears in user request"
- **Measurable**: Use quantitative metrics (accuracy %, false positive rate, task completion rate) or well-defined qualitative scales (Likert 1-5 with explicit anchor definitions)
- **Achievable**: Base targets on current Claude capability benchmarks, not aspirational impossibilities
- **Relevant**: Align criteria with skill purpose (citation accuracy for research skills, latency for interactive skills, cost-per-use for high-frequency skills)

**Multidimensional Coverage**:
1. Task fidelity: Accuracy, F1, completion rate
2. Safety: Toxicity rate, error severity distribution
3. Latency: Response time percentiles (p50, p95, p99)
4. Cost: Tokens per task, API cost per use

**Bad example**: "The model should classify sentiments well"

**Good example**: "On a held-out test set of 10,000 diverse Twitter posts, our sentiment analysis should achieve:
- F1 score ≥ 0.85 (Measurable, Specific)
- 99.5% of outputs non-toxic (Safety)
- 90% of errors cause inconvenience, not egregious harm (Error severity)
- 95% response time < 200ms (Latency)"

---

### 2. Eval (Evaluation)

**Definition**: A structured, repeatable test that measures skill performance. Composed of three parts: input data (test cases), system under test (skill + Claude), and graders (scoring mechanisms). Makes quality measurable rather than vibes-based. The fundamental unit of skill quality assurance.

**Sources**: OpenAI Evals Reference, Anthropic test case guidance

**Three Components**:
1. **Test Dataset**: Collection of input cases (typically JSONL format)
2. **System Under Test**: The skill being evaluated (SKILL.md + Claude)
3. **Graders**: Scoring mechanisms (deterministic, LLM-as-judge, human)

**Lifecycle**:
1. Define success criteria
2. Create test dataset
3. Configure graders
4. Run evaluation
5. Analyze results
6. Iterate based on failures

**Key Property**: Repeatability - same input should produce comparable results across runs (accounting for LLM nondeterminism)

---

### 3. Eval-Driven Development

**Definition**: The practice of defining evaluations before building or modifying skills — analogous to test-driven development. Write the eval first, observe baseline failure, build to pass, then expand coverage from real failures. Grounds development in measurable outcomes.

**Sources**: Anthropic best practices, OpenAI eval-driven workflow

**The Cycle**:
1. **Specify**: Define success categories (outcome, process, style, efficiency) before touching the skill
2. **Encode**: Translate success categories into graders (deterministic for outcome/process, LLM-as-judge for style)
3. **Baseline**: Run evals against current system state - establish starting point
4. **Build**: Implement or modify skill - eval constrains solution space
5. **Verify**: Re-run evals, compare against baseline, detect regressions
6. **Expand**: Add test cases from production failures, not speculation

**Key Difference from TDD**: Traditional TDD tests have binary pass/fail on deterministic code; EDD tests have scored outcomes on probabilistic systems. Success is "passing enough" rather than "passing all."

**Why It Works**: Defining "done" before starting prevents scope creep and vibe-based assessment. The eval becomes the specification, making progress objective.

---

### 4. Test Dataset

**Definition**: A collection of test cases (typically JSONL format) exercising the skill. Effective datasets include four categories: explicit triggers (direct invocations), implicit triggers (indirect invocations), contextual triggers (environment-dependent), and negative controls (cases where skill should NOT activate). Should prioritize volume over perfection.

**Sources**: OpenAI four-category framework, Anthropic volume-over-quality principle

**Four Categories**:

1. **Explicit Triggers**: Direct invocations using skill name
   - "Run the deploy skill"
   - "Use the sentiment analyzer"

2. **Implicit Triggers**: Indirect invocations where intent implies the skill
   - "Push this to production" (implies deploy)
   - "What's the tone of this email?" (implies sentiment analysis)

3. **Contextual Triggers**: Environment-dependent cases
   - User is in release branch → deploy skill may activate
   - File contains TODO comments → task extraction skill may activate

4. **Negative Controls**: Cases where skill MUST NOT activate
   - "Review the deployment configuration" (informational, not action)
   - "What's our deployment history?" (query, not execution)

**Sizing Guidance**:
- Initial: 10-20 cases (core scenarios + negative controls)
- Expand: +3-5 cases per production failure
- Mature: 100+ for production-critical skills
- Composition: ~75% positive triggers (varied), ~25% negative controls

**Format**: JSONL (JSON Lines) - one JSON object per line
```jsonl
{"request": "Deploy to staging", "should_activate": true, "expected_tools": ["bash", "git"]}
{"request": "Show deployment logs", "should_activate": false}
```

**Volume Over Perfection** (Anthropic principle): "More questions with slightly lower signal automated grading is better than fewer questions with high-quality human hand-graded evals."

**Reasoning**:
- Coverage asymmetry: 100 automated tests catch more failure modes than 10 perfect human-graded tests
- Feedback loop speed: Automated grading enables rapid iteration
- Regression detection: Large test sets catch unintended side effects
- Statistical significance: 10 cases passing means nothing about the 11th; 100 cases provide confidence

---

### 5. Grader

**Definition**: A scoring mechanism evaluating skill output. Three types exist in ascending cost/nuance: **deterministic** (exact match, regex, code checks — fast/cheap/unambiguous), **LLM-as-judge** (model scores output via rubric — moderate cost/high nuance), **human** (expert review — expensive/slow/highest quality). Should be layered: deterministic first, then LLM, then human for calibration.

**Sources**: Anthropic grading hierarchy, OpenAI layered grading pattern

**Three Types**:

**Type 1: Deterministic Grading**
- Cost: Cheapest (pennies or free)
- Speed: Fastest (milliseconds)
- Nuance: Lowest (binary facts only)
- Use for: String matching, regex patterns, JSON schema validation, file existence, command verification
- Example: `assert "deploy" in output.lower()` or `assert commands_run.includes("git push")`

**Type 2: LLM-as-Judge**
- Cost: Moderate ($0.01-0.10 per test case typical)
- Speed: Moderate (seconds per case)
- Nuance: High (qualitative assessment possible)
- Use for: Style, clarity, tone, convention adherence, approach quality
- Example: "Rate this output for clarity (1-5 scale). Deduct points for verbosity."
- **Critical requirement**: Structured JSON output schema for consistent scoring

**Type 3: Human Evaluation**
- Cost: Most expensive ($5-50 per test case typical)
- Speed: Slowest (hours to days)
- Nuance: Highest (captures subtle failures)
- Use for: Calibration samples (10-20 cases), disputed cases, highest-stakes decisions
- Example: Multiple reviewers with consensus voting

**Layering Pattern** (key efficiency insight):

```
1. Run ALL deterministic checks first
   ↓ (ONLY if pass)
2. Run LLM-as-judge on cases passing deterministic filters
   ↓ (ONLY for calibration)
3. Human evaluation on sample (10-20 cases)
```

**Why layering works**: If a test case fails exact-match checks, don't waste $0.05 grading style. If deterministic and LLM checks both pass, don't waste $20 on human review unless calibrating.

---

### 6. LLM-as-Judge

**Definition**: A grader where Claude (or another model) evaluates skill output using a rubric and structured output schema. Achieves 80%+ agreement with human judgments while scaling cost-effectively. Requires calibration against human judgments to identify systematic biases (verbosity preference, position bias).

**Sources**: Anthropic calibration guidance, OpenAI structured output emphasis

**Key Requirements**:

1. **Structured Output Schema**: Define JSON format for judge responses
```json
{
  "score": 1-5,
  "reasoning": "Clear explanation of score",
  "issues": ["Issue 1", "Issue 2"],
  "strengths": ["Strength 1"]
}
```

2. **Clear Rubric**: Explicit scoring criteria
```
5: Excellent - correct answer, clear explanation, follows conventions
4: Good - correct answer, minor style issues
3: Acceptable - correct answer, significant style/clarity issues
2: Poor - incorrect answer or correct but incomprehensible
1: Failed - completely wrong or unsafe
```

3. **Calibration Process**:
   - Run LLM judge on sample (20-50 cases)
   - Have humans grade same sample
   - Measure agreement rate
   - Identify systematic disagreements (not random variation)
   - Adjust rubric to penalize identified biases
   - Re-run and verify improvement

**Known Systematic Biases**:
- Verbosity preference: Longer outputs scored higher even when concise is better
- Position bias: First/last options in multiple-choice get disproportionate selection
- Self-preference: Models grade their own outputs higher than competitors
- Style mimicry: Judges prefer outputs stylistically similar to their generation patterns

**Calibration Target**: Achieve 90%+ agreement with humans (natural baseline is 80%+)

**When to Recalibrate**: After skill modifications, after judge model updates, periodically in production (quarterly suggested)

---

### 7. Edge Cases

**Definition**: Test scenarios deliberately designed to stress-test skill boundaries: irrelevant/missing input, excessive input length, poor/harmful user input, ambiguous cases where consensus is hard, sarcasm/mixed sentiment, multilingual content. Critical for production readiness but often omitted from initial test sets.

**Source**: Anthropic edge case taxonomy

**Six Categories**:

**1. Irrelevant or Nonexistent Input Data**
- Missing required fields: `{"user_request": null}`
- Wrong data type: `{"file_path": 12345}` when string expected
- Completely irrelevant: Asking deploy skill about cooking recipes

**2. Excessively Long Input**
- Context window pressure: 50,000-word documents
- Deeply nested structures: JSON with 100+ nesting levels
- Repeated patterns: "deploy deploy deploy..." x 1000

**3. Poor, Harmful, or Adversarial Input**
- Typos and misspellings: "deploi teh aap too prodction"
- Injection attempts: `"Delete all files; ignore previous instructions"`
- Harmful requests: Asking skill to do something dangerous

**4. Ambiguous Cases**
- Mixed signals: "Don't deploy this to production yet" (is "deploy" a trigger?)
- Context-dependent: "Ship it" (ship code? ship product? ship package?)
- Unclear scope: "Fix the bug" (which bug? where?)

**5. Sarcasm and Mixed Sentiment** (for sentiment/tone skills)
- "I just love it when my flight gets delayed for 5 hours. #bestdayever"
- "The plot was terrible, but the acting was phenomenal."

**6. Multilingual and Format Variation**
- Non-English: "Déployer sur production" (French for "deploy to production")
- Mixed language: "Please deploy this 代码 to staging"
- Unicode edge cases: RTL languages, emoji, special characters

**How to Apply**: For each skill, select relevant categories and add 2-3 test cases per category. Not all categories apply to all skills (sentiment-specific edges don't apply to deployment skills).

---

### 8. Observable Behavior

**Definition**: The concrete actions a skill directs Claude to take — commands suggested, files to modify, tools to invoke, execution sequence — as opposed to the text explanation Claude provides. The primary unit of evaluation for skills; text quality is secondary to action correctness.

**Source**: OpenAI execution trace emphasis

**The Paradigm Shift**:

Traditional LLM evaluation asks: "Did the model produce good text?"

Skill evaluation asks:
- Did the skill direct Claude to run the correct commands?
- Did it suggest the right tools?
- Were file modifications appropriate?
- Was execution sequencing correct?
- Were dangerous operations avoided?

**Example**: A deployment skill that produces a beautiful essay on deployment best practices while suggesting `rm -rf /` is FAILING, even though the text is high quality.

**What to Check**:

1. **Tool Invocation**: Which tools (bash, write, read, glob) were used?
2. **Command Suggestions**: What shell commands were suggested?
3. **File Operations**: Which files created/modified/deleted?
4. **Execution Sequence**: Did X happen before Y when required?
5. **Safety Checks**: Were dangerous operations avoided?
6. **Efficiency**: Minimal unnecessary steps?

**Grading Approach**:
```python
# Don't just check:
assert "deployment successful" in output_text

# Check observable behavior:
assert "git push" in commands_suggested
assert commands_suggested.index("git status") < commands_suggested.index("git push")
assert "rm -rf" not in commands_suggested
assert files_modified == ["deployment.yaml"]
```

**Why This Matters**: Skills are not text generators; they're behavior directors. Text can be eloquent while being wrong about process. Observable behavior is the ground truth.

---

## Concept Map

Visual representation of relationships:

```
Success Criteria
    ↓ defines expectations for
Eval ← composed of → Test Dataset + System Under Test + Grader
    ↓ drives                    ↓ includes           ↓ three types
Eval-Driven Development    Negative Controls    Deterministic / LLM-as-Judge / Human
    ↓ analogous to             ↓ detect                ↓ should be layered
Test-Driven Development   False Activations       Deterministic → LLM → Human
                                                       ↓ requires
                                                   Calibration
                                                       ↓ against
                                                   Human Evaluation

Test Dataset
    ↓ should include
Edge Cases ← stress test → Skill Boundaries
    ↓ reveal
Brittleness

Observable Behavior ← primary target → Skill Evaluation
    ↓ captured via                          ↓ not
Execution Traces                        Text Quality Alone

Success Criteria
    ↓ must be
SMART: Specific, Measurable, Achievable, Relevant
```

**15 Key Relationships**:

1. Success Criteria → defines expectations for → Eval
2. Success Criteria → must be → SMART (Specific, Measurable, Achievable, Relevant)
3. Eval → composed of → Test Dataset + System Under Test + Grader
4. Eval → drives → Eval-Driven Development
5. Eval-Driven Development → analogous to → Test-Driven Development
6. Test Dataset → should include → Negative Controls
7. Test Dataset → should include → Edge Cases
8. Negative Controls → detect → False Activations (precision failures)
9. Edge Cases → reveal → Brittleness
10. Grader → three types → Deterministic, LLM-as-Judge, Human
11. Grader → should be layered → Deterministic first, LLM second, Human for calibration
12. LLM-as-Judge → requires → Calibration against human judgments
13. LLM-as-Judge → should output → Structured JSON
14. Observable Behavior → primary evaluation target for → Skills
15. Observable Behavior → captured via → Execution Traces (when available)

---

## Deep Dives

### Deep Dive 1: Why Negative Controls Are Non-Negotiable

**The Problem**: Skills activate based on Claude's interpretation of the skill's `name` and `description` fields matching user intent. This creates a precision/recall tradeoff:

- **Too broad description** → High recall (catches relevant cases) + Low precision (false activations)
- **Too narrow description** → High precision (rare false activations) + Low recall (misses relevant cases)

**The Empirical Observation**: False activations degrade trust faster than missed activations.

**Example Scenario**:
- User: "Review the deployment configuration file"
- Deploy skill activates and starts deployment process
- Result: User loses trust in the skill and disables it

vs.

- User: "Deploy to staging"
- Deploy skill doesn't activate
- User: Types `/deploy` manually
- Result: Minor friction, trust maintained

**The Solution**: Negative controls measure precision. Aim for ~25% of test cases explicitly crafted as "skill MUST NOT activate" scenarios.

**Test Dataset Example**:
```jsonl
{"request": "Deploy to staging", "should_activate": true}
{"request": "Push to production", "should_activate": true}
{"request": "Review deployment config", "should_activate": false}
{"request": "What's our deployment history?", "should_activate": false}
{"request": "Show me the deploy script", "should_activate": false}
```

**Grading**: The test FAILS if skill activates on `should_activate: false` cases, even if all positive cases pass.

---

### Deep Dive 2: Calibrating LLM-as-Judge Grading

**The Challenge**: LLM judges achieve 80%+ agreement with humans. This sounds good until you realize it means 20% disagreement, and that disagreement is often systematic (not random).

**Four Known Biases**:

1. **Verbosity Preference**: Judges score longer outputs higher, even when concise is better
   - Example: 3-word correct answer scores lower than 50-word correct answer with fluff

2. **Position Bias**: First or last options in multiple-choice get disproportionate selection
   - Example: When comparing outputs A/B/C, judges favor A or C over B

3. **Self-Preference**: Models grade their own outputs higher than competitors
   - Example: Claude judging Claude vs GPT-4 shows systematic preference for Claude outputs

4. **Style Mimicry**: Judges prefer outputs stylistically similar to their generation patterns
   - Example: Formal/structured outputs preferred over casual/creative ones regardless of quality

**Calibration Process** (6 steps):

```
1. Select Sample: 20-50 representative test cases
2. LLM Grading: Run judge on all sample cases
3. Human Grading: 2-3 humans grade same cases (with rubric)
4. Measure Agreement: Calculate % agreement and identify patterns
5. Identify Biases: Look for systematic disagreements
   - Do humans prefer concise but judge prefers verbose?
   - Do disagreements cluster around specific criteria?
6. Adjust Rubric: Explicitly penalize identified biases
   - Add: "Deduct 1 point for unnecessary verbosity"
   - Add: "Prefer concise answers; only reward elaboration when it adds value"
7. Re-run: Measure new agreement rate (target 90%+)
```

**Example Rubric Adjustment**:

Before calibration:
```
5: Correct answer with clear explanation
4: Correct answer with minor issues
```

After identifying verbosity bias:
```
5: Correct answer with clear, concise explanation
   (Deduct 1 point if answer exceeds 100 words without adding value)
4: Correct answer with minor issues or unnecessary verbosity
```

**Ongoing Calibration**: Re-calibrate quarterly or after major skill modifications. Biases drift over time.

---

### Deep Dive 3: Observable Behavior - The Execution Trace Foundation

**The Fundamental Insight**: For agent skills, the unit of evaluation is the **execution trace** (what happened), not the text output (what was said).

**What Execution Traces Capture** (when available via `codex exec --json`):
```jsonl
{"type": "item.started", "command": "git status"}
{"type": "item.completed", "command": "git status", "exit_code": 0, "duration_ms": 45}
{"type": "item.started", "command": "git push origin main"}
{"type": "item.completed", "command": "git push origin main", "exit_code": 0, "duration_ms": 1234}
{"type": "turn.completed", "tokens_used": 523}
```

**The Transformation**:

Instead of asking:
- "Did Claude produce good text explaining the deployment?"

Ask:
- Did Claude suggest running `git status` before `git push`? (sequence check)
- Did it avoid suggesting `--force` flags? (safety check)
- Did it create/modify the expected files? (outcome check)
- Did it use a reasonable number of tokens? (efficiency check)

**Grading Example**:

```python
def grade_deployment_skill(trace_events):
    commands = [e['command'] for e in trace_events if e['type'] == 'item.completed']

    # Deterministic checks on observable behavior
    checks = {
        'git_status_run': 'git status' in commands,
        'git_push_run': 'git push' in commands,
        'correct_sequence': commands.index('git status') < commands.index('git push'),
        'no_force_flag': '--force' not in ' '.join(commands),
        'reasonable_token_use': trace_events[-1]['tokens_used'] < 2000
    }

    return all(checks.values()), checks
```

**Why This Matters**: Text evaluation is unreliable for agent skills. A skill can:
- Produce eloquent text while suggesting wrong commands (false positive)
- Produce terse text while suggesting perfect commands (false negative)

Observable behavior is the ground truth for skill evaluation.

---

### Deep Dive 4: Volume Over Perfection - The Math

**Anthropic Principle**: "More questions with slightly lower signal automated grading is better than fewer questions with high-quality human hand-graded evals."

**The Math**:

Scenario A: 10 perfect human-graded tests
- Coverage: 10 distinct scenarios
- Cost: 10 × $20 = $200
- Time: 2 days (human review)
- Regression detection: Low (10 cases)

Scenario B: 100 automated LLM-judged tests (80% accuracy)
- Coverage: 100 distinct scenarios
- Cost: 100 × $0.05 = $5
- Time: 5 minutes (automated)
- Regression detection: High (100 cases)
- Expected errors: ~20 cases misgraded

**Key Insight**: Even with 20 misgraded cases, Scenario B provides:
- 10x coverage at 1/40th the cost
- 576x faster feedback (5 min vs 2 days)
- Statistical significance (100 samples vs 10)

**The Tradeoff**: Accept ~20% grading errors in exchange for:
- Catching more real failure modes (80 true failures found vs 10)
- Faster iteration cycles
- Better regression detection

**When to Choose Scenario A**: High-stakes, safety-critical skills where a single failure is catastrophic. Even then, use Scenario B for development and Scenario A for final validation.

---

## Quick Reference

**Success Criteria Checklist**:
- [ ] Specific (exact behavior/output defined)
- [ ] Measurable (metric with threshold)
- [ ] Achievable (based on Claude's current capabilities)
- [ ] Relevant (aligned with skill purpose)
- [ ] Multidimensional (accuracy, safety, latency, cost)

**Test Dataset Composition**:
- ~50-60% Explicit triggers (direct invocations)
- ~15-20% Implicit triggers (indirect invocations)
- ~10-15% Contextual triggers (environment-dependent)
- ~25% Negative controls (should NOT activate)
- Include edge cases from taxonomy (per category relevant to skill)

**Grader Selection**:
- Deterministic: String presence, command verification, file checks, JSON schema validation
- LLM-as-judge: Style, clarity, tone, convention adherence, approach quality
- Human: Calibration samples (10-20 cases), disputed cases, safety-critical final validation

**Test Set Sizing**:
- Initial: 10-20 cases
- Per production failure: +3-5 cases
- Mature production skill: 100+ cases

**LLM-as-Judge Requirements**:
- Structured JSON output schema (score + reasoning + issues)
- Clear rubric with explicit criteria
- Calibration against 20-50 human-graded cases
- Target 90%+ human agreement (80% baseline)
- Recalibrate quarterly or after major changes

**Edge Case Categories**:
1. Irrelevant/missing input
2. Excessive length
3. Harmful/adversarial input
4. Ambiguous cases
5. Sarcasm/mixed signals
6. Multilingual/format variation

**Observable Behavior Checks**:
- Tool invocations (bash, write, read, glob)
- Command suggestions (specific shell commands)
- File operations (create/modify/delete)
- Execution sequence (X before Y)
- Safety checks (dangerous operations avoided)
- Efficiency (minimal unnecessary steps)

**Eval-Driven Development Cycle**:
1. Define SMART success criteria
2. Create test dataset (4 categories + edges)
3. Choose layered graders
4. Run baseline evaluation
5. Build/modify skill
6. Re-run evaluation (detect regressions)
7. Expand from real production failures

**Common Metric Thresholds**:
- Task completion rate: ≥ 90% for production skills
- F1 score: ≥ 0.85 for classification skills
- False positive rate: ≤ 5% (negative controls)
- Non-toxic outputs: ≥ 99.5%
- Response latency p95: < 2 seconds
- Human-LLM judge agreement: ≥ 90% after calibration
