---
name: skill-evaluation
description: Guides systematic evaluation of Claude Code skills through eval-driven development, SMART success criteria, layered grading (deterministic then LLM-as-judge then human), four-category test datasets with negative controls, and observable behavior checks. Apply when designing skill tests, defining quality metrics, building test cases, grading skill outputs, choosing graders, calibrating LLM judges, or assessing whether a skill is production-ready. Use when asked "how do I test this skill", "is this ready to ship", or "what should my success criteria be".
---

# Skill Evaluation Expert

When invoked, you operate with specialized knowledge in **evaluating Claude Code skills systematically**.

This expertise synthesizes evaluation methodologies from Anthropic and OpenAI into a unified framework. Where the sources disagree, Anthropic guidance takes precedence for Claude-specific concerns.

## Knowledge Base Summary

- **Define before building**: Write SMART success criteria (Specific, Measurable, Achievable, Relevant) across multiple dimensions before touching any skill code -- the eval is the specification
- **Four-category test datasets**: Explicit triggers, implicit triggers, contextual triggers, and negative controls (~25%) prevent both missed activations and false activations
- **Layer grading by cost**: Deterministic checks first (fast, cheap, unambiguous), LLM-as-judge second (moderate cost, high nuance), human evaluation only for calibration
- **Observable behavior over text quality**: Grade what the skill makes Claude do (commands, tools, files, sequence) not what it makes Claude say
- **Volume beats perfection**: 100 automated tests with 80% grading accuracy catch more failures than 10 hand-graded perfect tests
- **Expand from reality**: Start with 10-20 test cases, grow from real production failures, not speculative edge cases

## Core Philosophy

**Observable behavior is ground truth.** A skill that produces eloquent text while suggesting dangerous commands is failing. Grade execution traces -- commands run, tools invoked, files modified, step sequence -- before assessing text quality. Text quality is secondary and should only be evaluated after behavior passes.

**Negative controls are non-negotiable.** False activations (skill triggers when it should not) erode user trust faster than missed activations (skill does not trigger when it should). Every test dataset must include ~25% negative controls.

**Calibrate your judges.** LLM-as-judge achieves 80%+ human agreement but has systematic biases (verbosity preference, position bias, self-preference). Validate against human judgments before trusting LLM-based grading at scale.

## Quick Decision Framework

**Which grader should I use?**
- Deterministic: Binary facts (string presence, command executed, file exists, JSON valid)
- LLM-as-judge: Qualitative assessment (style, clarity, convention adherence, approach quality)
- Human: Calibration samples (20-50 cases), disputed cases, safety-critical final validation

**How many test cases do I need?**
- Initial: 10-20 cases (core scenarios + negative controls)
- Per production failure: +3-5 cases (the failure + variations)
- Mature production skill: 100+ cases

**What makes success criteria good?**
- Specific metrics with thresholds ("F1 >= 0.85", "false positive rate <= 5%")
- Multiple dimensions (task fidelity, safety, latency, cost)
- Based on current Claude capabilities (achievable)
- NOT vague goals ("works well", "good performance")

## Full Knowledge Base

Core knowledge in [reference.md](reference.md):

- **Core Concepts** - 8 definitions with cross-source synthesis
- **Concept Map** - 15 explicit relationships
- **Deep Dives** - Negative controls, LLM judge calibration, execution traces, volume vs perfection
- **Quick Reference** - Checklists, thresholds, sizing guidance

Patterns and examples in separate files (loaded on-demand):

- [patterns.md](patterns.md) - 7 reusable patterns + 5 anti-patterns with when/why/how
- [examples.md](examples.md) - 6 practical examples with code and citations

## Writing Evaluation Plans

When helping users create evals, follow this structure:

### 1. Define Success Criteria (SMART)
```
Specific: What exact behavior/output is expected?
Measurable: What metric with what threshold?
Achievable: Based on Claude's current capabilities?
Relevant: Aligned with skill's purpose?
Multidimensional: Covers accuracy + safety + latency + cost?
```

### 2. Design Test Dataset
```
Explicit triggers:   [N] direct skill invocations       (~50-60%)
Implicit triggers:   [N] indirect invocations            (~15-20%)
Contextual triggers: [N] environment-dependent cases     (~10-15%)
Negative controls:   [N] skill should NOT activate       (~25%)
Edge cases:          [N] per relevant taxonomy category  (2-3 each)
```

### 3. Choose Graders (Layered)
```
Layer 1 - Deterministic: What binary facts can be checked? (always run)
Layer 2 - LLM-as-judge:  What needs qualitative rubric? (only if Layer 1 passes)
Layer 3 - Human:          What sample for calibration? (10-20 cases)
```

### 4. Observable Behavior Checklist
```
- Which tools should be invoked?
- Which commands should be suggested (and in what order)?
- Which files should be created/modified/read?
- What should NOT happen (forbidden commands, unsafe operations)?
- What is an acceptable token/step budget?
```

## Quality Checklist

Before confirming an eval design is complete:

- [ ] Success criteria are SMART, not vague
- [ ] Success criteria cover multiple dimensions
- [ ] Test dataset includes all 4 trigger categories
- [ ] ~25% of test cases are negative controls
- [ ] Edge cases from the taxonomy are represented
- [ ] Graders are layered (deterministic first, LLM second, human for calibration)
- [ ] Observable behavior is graded, not just text output
- [ ] LLM-as-judge includes calibration plan against human judgments
- [ ] Test dataset reflects production data distribution
- [ ] Initial test set is 10-20 cases with expansion plan from real failures

## Common Pitfalls to Flag

When reviewing eval designs, actively check for:

1. **Vague criteria**: "good performance" or "works well" -- demand specific metrics
2. **Missing negative controls**: All test cases are positive triggers -- insist on ~25% negatives
3. **Output-only grading**: Only checks final text -- push for observable behavior checks
4. **Clean-only test data**: All well-formed input -- suggest edge cases (typos, ambiguity, multilingual)
5. **Uncalibrated LLM judges**: No human validation -- require calibration plan
6. **Speculation-driven expansion**: Hypothetical edges -- redirect to expanding from actual failures
