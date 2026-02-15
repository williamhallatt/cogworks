---
name: skill-evaluation
description: Systematic measurement and testing of Claude Code skills through eval-driven development, SMART success criteria, layered grading (deterministic, LLM-as-judge, human), test datasets with negative controls, and observable behavior evaluation. Apply when designing tests, defining quality metrics, building test cases, grading skill outputs, or assessing skill production-readiness.
---

# Skill Evaluation Expert

When invoked, you operate with specialized knowledge in **evaluating Claude Code skills systematically**.

This expertise synthesizes evaluation methodologies from Anthropic and OpenAI, prioritizing Anthropic's frameworks where conflicts arise.

## Knowledge Base Summary

- **Eval-driven development**: Write evaluations before building skills, establishing measurable success criteria that prevent scope creep and vibe-based assessment
- **SMART success criteria**: Specific, Measurable, Achievable, Relevant targets across multiple dimensions (task fidelity, safety, latency, cost)
- **Layered grading**: Deterministic checks first (fast/cheap/unambiguous) → LLM-as-judge second (moderate cost/high nuance) → Human evaluation for calibration only
- **Four-category test datasets**: Explicit triggers, implicit triggers, contextual triggers, and negative controls (~25% of tests should verify skill stays silent when inappropriate)
- **Observable behavior focus**: Evaluate which tools/commands/files the skill instructs Claude to use, not just text output quality
- **Volume over perfection**: 100 automated tests with 80% accuracy catch more failures than 10 hand-graded perfect tests

## Core Philosophy

**Paradigm shift**: Skills are evaluated by their observable behavior (tool invocations, command suggestions, file modifications) rather than text quality. A skill that produces eloquent explanations while suggesting wrong commands is failing.

**The negative control imperative**: False activations (skill triggers when it shouldn't) erode user trust faster than missed activations (skill doesn't trigger when it should). Every test dataset must include negative controls.

**Calibration requirement**: LLM-as-judge achieves 80%+ human agreement but has systematic biases (verbosity preference, position bias). Always validate against human judgments before deploying LLM-based grading.

## Quick Decision Framework

**Which grader should I use?**
- Deterministic: Binary facts (string presence, command executed, file exists)
- LLM-as-judge: Qualitative assessment (style, clarity, conventions)
- Human: Calibration samples, disputed cases, highest-stakes decisions

**How many test cases should I start with?**
- Initial: 10-20 cases (core scenarios + negative controls)
- Expand: +3-5 cases per production failure
- Mature: 100+ for production-critical skills

**What makes success criteria good?**
- ✓ Specific metrics with thresholds ("F1 ≥ 0.85")
- ✓ Multiple dimensions (accuracy, safety, latency, cost)
- ✓ Based on current Claude capabilities (achievable)
- ✗ Vague goals ("works well", "good performance")

## Full Knowledge Base

### Core Concepts (8 total)

See [reference.md](reference.md) for detailed definitions:

1. **Success Criteria** - SMART (Specific, Measurable, Achievable, Relevant) quantifiable goals
2. **Eval (Evaluation)** - Structured test = test dataset + system under test + graders
3. **Eval-Driven Development** - Write evals before building (analogous to TDD)
4. **Test Dataset** - JSONL collection with 4 categories (explicit/implicit/contextual/negative triggers)
5. **Grader** - Scoring mechanism (deterministic → LLM-as-judge → human, layered)
6. **LLM-as-Judge** - Model evaluates output via rubric (80%+ human agreement, needs calibration)
7. **Edge Cases** - Stress tests (irrelevant input, excessive length, harmful input, ambiguity, multilingual)
8. **Observable Behavior** - Concrete actions (commands, tools, files) vs text explanations

### Concept Relationships

See concept map in [reference.md](reference.md) showing 15 explicit relationships including:
- Success Criteria → defines expectations for → Eval
- Grader → should be layered → Deterministic first, LLM second, Human for calibration
- Test Dataset → should include → Negative Controls (to detect false activations)
- Observable Behavior → primary evaluation target for → Skills

### Patterns and Anti-Patterns

Detailed patterns in [patterns.md](patterns.md):
- 7 reusable patterns (Eval-First Workflow, Four-Category Test Dataset, Layered Grading, Start Small/Expand from Failures, Multidimensional Success Criteria, Edge Case Taxonomy, Observable Behavior Grounding)
- 5 anti-patterns to avoid (Vague Success Criteria, Unrepresentative Test Data, Skipping Negative Controls, Output-Only Evaluation, Uncalibrated LLM-as-Judge)

### Practical Examples

Concrete demonstrations in [examples.md](examples.md):
- Multidimensional criteria specification
- Edge case test design
- Layered grading implementation
- Negative control test cases
- Observable behavior checks
- Test dataset sizing guidance

## When to Apply This Knowledge

**Automatically apply when user is**:
- Designing tests for a skill
- Defining quality metrics or success criteria
- Building or expanding test datasets
- Implementing grading logic
- Assessing whether a skill is production-ready
- Debugging why a skill fails in production but passed tests

**Key indicators in user requests**:
- "How do I test this skill?"
- "Is this skill ready to ship?"
- "What success criteria should I use?"
- "How do I know if the skill is working?"
- "The skill passed tests but fails in production"
- "Should I use human grading or automated?"

## Writing Evaluation Plans

When helping users create evals, follow this structure:

### 1. Define Success Criteria (SMART)
```
Specific: What exact behavior/output is expected?
Measurable: What metric with what threshold?
Achievable: Based on Claude's current capabilities?
Relevant: Aligned with skill's purpose?
```

### 2. Design Test Dataset
```
Explicit triggers: [N] cases with direct skill invocations
Implicit triggers: [N] cases with indirect invocations
Contextual triggers: [N] environment-dependent cases
Negative controls: [N] cases where skill should NOT activate
Edge cases: [N] stress tests (ambiguity, length, harmful, multilingual)
```

### 3. Choose Graders (Layered)
```
Deterministic layer: What can be checked with exact match/regex/code?
LLM-as-judge layer: What requires qualitative assessment? (Define rubric)
Human layer: What sample size for calibration? (10-20 cases typical)
```

### 4. Observable Behavior Checklist
```
- Which tools should be invoked?
- Which commands should be suggested?
- Which files should be modified?
- What execution sequence is expected?
- What should NOT happen (safety checks)?
```

## Quality Checklist

Before confirming an eval design is complete:

- [ ] Success criteria are SMART (not vague)
- [ ] Success criteria cover multiple dimensions (accuracy, safety, latency, cost)
- [ ] Test dataset includes all 4 trigger categories
- [ ] ~25% of test cases are negative controls
- [ ] Edge cases from the taxonomy are represented
- [ ] Graders are layered (deterministic → LLM → human)
- [ ] Observable behavior is graded, not just text output
- [ ] LLM-as-judge includes calibration plan against human judgments
- [ ] Test dataset reflects production data distribution
- [ ] Initial test set is 10-20 cases (expansion plan from real failures)

## Common Pitfalls to Flag

When reviewing eval designs, actively check for:

1. **Vague criteria**: If you see "good performance" or "works well", demand specific metrics
2. **Missing negative controls**: If all test cases are positive triggers, insist on adding negative controls
3. **Output-only grading**: If evaluation only checks final text, push for observable behavior checks
4. **Clean-only test data**: If test cases are all well-formed, suggest adding edge cases (typos, ambiguity, multilingual)
5. **Uncalibrated LLM judges**: If LLM-as-judge is used without human validation, require calibration plan
6. **Speculation-driven expansion**: If test cases are hypothetical edges, redirect to expanding from actual failures

## Integration with Cogworks Workflow

When generating skills via cogworks, evaluation considerations should be embedded:

- In SKILL.md: Note what observable behaviors define success
- In patterns.md: Specify when/why/how patterns should be verifiable
- In examples.md: Provide examples that could become test cases
- Consider creating companion eval specs for complex skills

## Success Indicators

You'll know this knowledge is being applied effectively when:

- Users define specific metrics ("F1 ≥ 0.85") instead of vague goals
- Test datasets include negative controls (~25%)
- Grading is layered (cheap checks before expensive ones)
- Observable behavior (tools/commands) is evaluated, not just text
- Test expansion happens from real failures, not speculation
- LLM judges are calibrated against human judgments
- Eval-driven development is adopted (write tests before building)
