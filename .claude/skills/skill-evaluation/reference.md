# Skill Evaluation Reference

Synthesized from Anthropic success criteria and test case guidance, and OpenAI evaluation best practices.

---

## TL;DR

Effective skill evaluation begins before building: define SMART success criteria across multiple dimensions (fidelity, safety, latency, cost), then encode those criteria as layered graders. Grade skills by observable behavior -- commands run, tools invoked, files modified -- not text quality alone. Build test datasets with four categories (explicit triggers, implicit triggers, contextual triggers, negative controls at ~25%) and expand from real production failures rather than speculation. Layer grading from cheap deterministic checks through LLM-as-judge (calibrated against human judgments) to maximise signal per dollar. Volume of automated tests with slightly lower accuracy catches more failures than a few perfect human-graded tests.

---

## Table of Contents

- [Core Concepts](#core-concepts) - 8 fundamental definitions
- [Concept Map](#concept-map) - 15 relationships between concepts
- [Deep Dives](#deep-dives) - Negative controls, LLM calibration, execution traces, volume math
- [Quick Reference](#quick-reference) - Checklists, thresholds, sizing
- [Sources](#sources) - Bibliography

---

## Core Concepts

### 1. Success Criteria

**Definition**: Specific, measurable, achievable, and relevant goals that define when a skill is "good enough to publish." Must be quantifiable and multidimensional. Transforms subjective assessment into objective measurement.

**The SMART Framework**:
- **Specific**: Not "the skill should help with deployment" but "the skill should correctly identify deployment context in 9/10 cases where `deploy`, `ship`, or `release` appears in the user request"
- **Measurable**: Use quantitative metrics (accuracy %, false positive rate, task completion rate) or well-defined qualitative scales (Likert 1-5 with explicit anchor definitions). Even "hazy" topics like safety can be quantified: "less than 0.1% of outputs flagged for toxicity out of 10,000 trials"
- **Achievable**: Base targets on current Claude capability benchmarks, not aspirational impossibilities
- **Relevant**: Align criteria with skill purpose -- citation accuracy for research skills, latency for interactive skills, cost-per-use for high-frequency skills

**Multidimensional Coverage** (most use cases need all four):
1. Task fidelity: Accuracy, F1, completion rate
2. Safety: Toxicity rate, error severity distribution (inconvenience vs moderate vs egregious)
3. Latency: Response time percentiles (p50, p95, p99)
4. Cost: Tokens per task, API cost per use

**Source**: Anthropic - Define Success Criteria

---

### 2. Eval (Evaluation)

**Definition**: A structured, repeatable test measuring skill performance. Composed of three parts: input data (test cases), system under test (skill + Claude), and graders (scoring mechanisms). The fundamental unit of skill quality assurance.

**Three Components**:
1. **Test Dataset**: Collection of input cases (typically JSONL format)
2. **System Under Test**: The skill being evaluated (SKILL.md + Claude)
3. **Graders**: Scoring mechanisms (deterministic, LLM-as-judge, human)

**Key Property**: Repeatability -- same input should produce comparable results across runs, accounting for LLM nondeterminism by using scored outcomes rather than binary pass/fail.

**Sources**: Anthropic test case guidance, OpenAI eval reference

---

### 3. Eval-Driven Development

**Definition**: Defining evaluations before building or modifying skills -- analogous to test-driven development but adapted for nondeterministic systems. The eval becomes the specification.

**The Cycle**:
1. **Specify**: Define success categories (outcome, process, style, efficiency) before touching the skill
2. **Encode**: Translate categories into graders -- deterministic for outcome/process, LLM-as-judge for style
3. **Baseline**: Run evals against current system state to establish the starting point
4. **Build**: Implement or modify skill -- any implementation passing the eval is acceptable
5. **Verify**: Re-run evals, compare against baseline, detect regressions across dimensions
6. **Expand**: Add test cases from production failures, not speculation

**Key Difference from TDD**: Traditional TDD tests have binary pass/fail on deterministic code; EDD tests have scored outcomes on probabilistic systems. Success is "passing enough" rather than "passing all."

**Sources**: Anthropic best practices, OpenAI eval-driven workflow

---

### 4. Test Dataset

**Definition**: A collection of test cases exercising the skill across four categories. Should prioritise volume over perfection -- automated tests with slightly lower signal catch more failure modes than fewer perfect human-graded tests.

**Four Categories**:

1. **Explicit Triggers** (~50-60%): Direct invocations using skill name
2. **Implicit Triggers** (~15-20%): Indirect invocations where intent implies the skill
3. **Contextual Triggers** (~10-15%): Environment-dependent cases
4. **Negative Controls** (~25%): Cases where skill MUST NOT activate

**Format**: JSONL (JSON Lines) -- one JSON object per line
```jsonl
{"request": "Deploy to staging", "should_activate": true, "category": "explicit"}
{"request": "Review deploy config", "should_activate": false, "category": "negative_control"}
```

**Sizing**: Start with 10-20 cases; expand by +3-5 per production failure; mature skills reach 100+.

**Sources**: OpenAI four-category framework, Anthropic volume-over-quality principle

---

### 5. Grader

**Definition**: A scoring mechanism evaluating skill output. Three types exist in ascending cost and nuance. Should be layered: deterministic first, then LLM, then human for calibration.

**Type 1 -- Deterministic**: Cost: essentially free. Speed: milliseconds. Use for binary facts: string presence, regex, JSON schema validation, file existence, command verification.

**Type 2 -- LLM-as-Judge**: Cost: $0.01-0.10 per case. Speed: seconds. Use for qualitative assessment: style, clarity, tone, convention adherence, approach quality. Requires structured JSON output schema for consistent scoring.

**Type 3 -- Human**: Cost: $5-50 per case. Speed: hours to days. Use for calibration samples (20-50 cases), disputed cases, safety-critical final validation.

**Layering Logic**:
```
1. Run ALL deterministic checks
   | (ONLY if pass)
2. Run LLM-as-judge on passing cases
   | (ONLY for calibration)
3. Human evaluation on sample
```

**Sources**: Anthropic grading hierarchy, OpenAI layered grading pattern

---

### 6. LLM-as-Judge

**Definition**: A grader where a model evaluates skill output using a rubric and structured output schema. Achieves 80%+ agreement with human judgments. Requires calibration to identify and correct systematic biases.

**Requirements**:
1. Structured output schema (JSON with score, reasoning, issues fields)
2. Clear rubric with explicit scoring criteria and anchor definitions
3. Calibration against 20-50 human-graded cases
4. Target 90%+ human agreement (baseline is 80%+)

**Known Systematic Biases**:
- Verbosity preference: Longer outputs scored higher even when concise is better
- Position bias: First/last options in multiple-choice get disproportionate selection
- Self-preference: Models grade their own outputs higher than competitors
- Style mimicry: Judges prefer outputs stylistically similar to their generation patterns

**Anthropic best practice**: Use a different model to evaluate than the model that generated the output being evaluated.

**Recalibrate**: After skill modifications, after judge model updates, or quarterly in production.

**Sources**: Anthropic calibration guidance, OpenAI structured output emphasis

---

### 7. Edge Cases

**Definition**: Test scenarios deliberately designed to stress-test skill boundaries. Critical for production readiness but commonly omitted from initial test sets. Add 2-3 test cases per relevant category for each skill.

**Six Categories**:
1. **Irrelevant or nonexistent input**: Missing fields, wrong data types, completely unrelated requests
2. **Excessively long input**: Context window pressure, deeply nested structures, repeated patterns
3. **Harmful or adversarial input**: Typos, injection attempts, malicious requests
4. **Ambiguous cases**: Mixed signals ("don't deploy yet"), context-dependent phrasing, unclear scope
5. **Sarcasm and mixed sentiment**: Sarcastic praise, contradictory evaluations (relevant for tone/sentiment skills)
6. **Multilingual and format variation**: Non-English input, mixed language, emoji, RTL, Unicode edge cases

**Source**: Anthropic edge case taxonomy

---

### 8. Observable Behavior

**Definition**: The concrete actions a skill directs Claude to take -- commands suggested, files to modify, tools to invoke, execution sequence -- as opposed to text explanation. The primary evaluation target for skills.

**The Paradigm Shift**: Traditional LLM evaluation asks "did it produce good text?" Skill evaluation asks:
- Did it run the correct commands?
- Did it run them in the right order?
- Did it create the expected files?
- Were dangerous operations avoided?
- Was token/step usage efficient?

**Why text quality is secondary**: A skill that produces an eloquent essay on deployment best practices while suggesting `rm -rf /` is failing. Text can be eloquent while being wrong about process. Observable behavior is ground truth.

**Source**: OpenAI execution trace emphasis

---

## Concept Map

1. Success Criteria → defines expectations for → Eval
2. Success Criteria → must be → SMART (Specific, Measurable, Achievable, Relevant)
3. Eval → composed of → Test Dataset + System Under Test + Grader
4. Eval → drives → Eval-Driven Development
5. Eval-Driven Development → analogous to → Test-Driven Development (adapted for nondeterminism)
6. Test Dataset → should include → Negative Controls (~25%)
7. Test Dataset → should include → Edge Cases (from taxonomy)
8. Negative Controls → detect → False Activations (precision failures)
9. Edge Cases → reveal → Brittleness (production readiness gaps)
10. Grader → three types → Deterministic, LLM-as-Judge, Human
11. Grader → should be layered → Deterministic first, LLM second, Human for calibration
12. LLM-as-Judge → requires → Calibration against human judgments
13. LLM-as-Judge → should output → Structured JSON (for consistent scoring)
14. Observable Behavior → primary evaluation target for → Skills
15. Observable Behavior → captured via → Execution Traces (commands, tools, files, sequence)

---

## Deep Dives

### Why Negative Controls Are Non-Negotiable

Skills activate based on Claude matching the skill's `name` and `description` fields against user intent. This creates a precision/recall tradeoff:

- **Too broad description** -> High recall (catches relevant cases) + Low precision (false activations)
- **Too narrow description** -> High precision (rare false activations) + Low recall (misses relevant cases)

**The empirical observation**: False activations degrade trust faster than missed activations. When a deploy skill activates on "review the deployment configuration" and starts deploying, the user loses trust and disables the skill. When a deploy skill misses "push to prod" and the user types `/deploy` manually, that is minor friction with trust maintained.

**The solution**: Negative controls measure precision. Target ~25% of test cases as "skill MUST NOT activate" scenarios. The test FAILS if skill activates on any negative control case, even if all positive cases pass perfectly.

**Source**: Cross-source synthesis -- Anthropic task-specific principle + OpenAI four-category framework

---

### Calibrating LLM-as-Judge Grading

LLM judges achieve 80%+ agreement with humans, but the 20% disagreement is often systematic, not random.

**Calibration Process** (6 steps):
1. **Select sample**: 20-50 representative test cases
2. **LLM grading**: Run judge on all sample cases
3. **Human grading**: 2-3 humans grade same cases using the same rubric
4. **Measure agreement**: Calculate percentage and identify clustering patterns
5. **Identify biases**: Look for systematic disagreements (e.g., judge prefers verbose, humans prefer concise)
6. **Adjust rubric**: Explicitly penalise identified biases ("Deduct 1 point for unnecessary verbosity"), re-run, verify improvement targets 90%+

**Example rubric adjustment** (after identifying verbosity bias):

Before: "5: Correct answer with clear explanation"

After: "5: Correct answer with clear, concise explanation. Deduct 1 point if answer exceeds 100 words without adding value."

**Best practice**: Use a different model as judge than the model that generated the output (Anthropic). Recalibrate quarterly or after major skill modifications.

**Sources**: Anthropic calibration guidance, OpenAI judge validation

---

### Execution Traces as the Foundation of Agent Evals

For agent skills, the unit of evaluation is the **execution trace** (what happened), not the text output (what was said).

Execution traces capture: commands executed (with exit codes and timing), files created/modified/read, tool invocations, token usage per turn.

**What to check on traces**:
- Did the agent run the correct commands? (deterministic match)
- Were commands in the right order? (sequence verification)
- Were expected files created? (existence check)
- Were dangerous operations avoided? (safety assertion)
- Was token usage reasonable? (efficiency bound)

**Why this matters**: Without execution traces, you are evaluating the agent's self-report of what it did. This is unreliable for the same reason that testing a function by asking "did you work correctly?" is unreliable. The trace is the observable record; the text is the agent's narrative about the record.

**Source**: OpenAI execution trace emphasis

---

### Volume Over Perfection -- The Math

Anthropic principle: "More questions with slightly lower signal automated grading is better than fewer questions with high-quality human hand-graded evals."

**Comparison**:

| Dimension | 10 human-graded tests | 100 automated tests (80% accuracy) |
|-----------|----------------------|-------------------------------------|
| Coverage | 10 distinct scenarios | 100 distinct scenarios |
| Cost | ~$200 | ~$5 |
| Time | 2 days | 5 minutes |
| Regression detection | Low | High |
| Expected misgraded | 0 | ~20 |

Even with 20 misgraded cases, the automated approach provides 10x coverage at 1/40th cost with 576x faster feedback. The 80 correctly-graded cases catch failure modes the 10 hand-graded tests never exercise.

**When to choose human grading**: Safety-critical skills where a single failure is catastrophic. Even then, use automated grading for development and human grading for final validation.

**Sources**: Anthropic volume principle, OpenAI scalability guidance

---

## Quick Reference

**Success Criteria Checklist**:
- [ ] Specific (exact behavior/output defined)
- [ ] Measurable (metric with threshold)
- [ ] Achievable (based on Claude's current capabilities)
- [ ] Relevant (aligned with skill purpose)
- [ ] Multidimensional (fidelity + safety + latency + cost)

**Test Dataset Composition**:
- ~50-60% Explicit triggers
- ~15-20% Implicit triggers
- ~10-15% Contextual triggers
- ~25% Negative controls
- Edge cases from taxonomy (2-3 per relevant category)

**Grader Selection**:
- Deterministic: String presence, command verification, file checks, JSON validation
- LLM-as-judge: Style, clarity, tone, convention adherence, approach quality
- Human: Calibration (20-50 cases), disputed cases, safety-critical validation

**Test Set Sizing**:
- Initial: 10-20 cases
- Per production failure: +3-5 cases
- Mature production skill: 100+ cases

**LLM-as-Judge Requirements**:
- Structured JSON output schema (score + reasoning + issues)
- Clear rubric with explicit criteria
- Calibration against 20-50 human-graded cases
- Target 90%+ human agreement (80% baseline)
- Use different model as judge than generator (Anthropic)
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
- Command suggestions and sequence
- File operations (create/modify/delete)
- Safety checks (dangerous operations avoided)
- Efficiency (minimal unnecessary steps)

**Common Metric Thresholds**:
- Task completion rate: >= 90% for production skills
- F1 score: >= 0.85 for classification skills
- False positive rate: <= 5% (negative controls)
- Non-toxic outputs: >= 99.5%
- Response latency p95: < 2 seconds
- Human-LLM judge agreement: >= 90% after calibration

**Eval-Driven Development Cycle**:
1. Specify success categories (outcome, process, style, efficiency)
2. Encode as graders (deterministic + LLM-as-judge)
3. Baseline against current system
4. Build/modify skill
5. Verify against baseline (detect regressions)
6. Expand from real production failures

---

## Sources

1. **Define Your Success Criteria** - Anthropic documentation
   - SMART framework for measurable goals, multidimensional coverage (fidelity, safety, latency, cost), quantitative and qualitative metric methods

2. **Create Strong Empirical Evaluations** - Anthropic documentation
   - Eval design principles, test case development, grading methods (code-based, human, LLM-based), volume-over-quality principle, edge case taxonomy

3. **Evaluation Best Practices and Evals Reference** - OpenAI documentation
   - Eval-driven development, architecture-tier evaluation, four-category test datasets, layered grading, execution traces, observable behavior paradigm, LLM-as-judge calibration
