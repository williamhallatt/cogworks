# Human Review Guide (Layer 3)

Guide for expert human evaluation of cogworks skills, used primarily for calibrating LLM-judge accuracy.

## Purpose

Human evaluation serves two roles:
1. **Calibration** - Establish ground truth for LLM-judge validation (90%+ agreement target)
2. **Dispute resolution** - Adjudicate cases where automated grading is uncertain

## When to Use

- **Calibration phase**: Evaluate 20 skills to validate LLM-judge accuracy
- **Spot checks**: Periodic validation (quarterly or after rubric changes)
- **Edge cases**: Unusual skills where automated grading seems questionable
- **Disputes**: User disagrees with automated grade and requests human review

## Evaluation Methodology

### Time Investment

- **Per skill**: 15-30 minutes
- **Calibration set (20 skills)**: 5-10 hours
- **Cost**: ~$100-200 per skill at expert rates ($400-600 calibration set)

### Grading Process

1. **Read source material** (5-10 min)
   - Understand scope and key concepts
   - Note structure and coverage

2. **Read generated skill** (5-10 min)
   - Trace 10-15 claims back to sources
   - Check coverage of source material
   - Assess clarity and actionability

3. **Complete grading form** (5-10 min)
   - Score each quality dimension
   - Provide reasoning
   - Note critical issues

## Grading Form

### Skill Information

- **Skill slug**: _________________
- **Evaluator**: _________________
- **Date**: _________________
- **Source count**: ___ files, ~___ pages

### Category 1: Source Fidelity (Weight: 30%)

**Definition**: Accuracy and traceability of claims to source material.

**Instructions**:
1. Select 10 random claims from the skill
2. For each claim, attempt to trace to source material
3. Check if contradictions between sources are explicitly noted
4. Look for any fabricated content

**Score** (circle one):
- 5 - All claims traceable, contradictions flagged, no fabrication
- 4 - 95%+ traceable, contradictions noted, minor gaps
- 3 - 85%+ traceable, some contradictions missed
- 2 - <85% traceable, noticeable fabrication
- 1 - Significant fabrication, poor traceability

**Evidence**:
- Claims analyzed: ___/10 traceable
- Fabrications found: _______________________________
- Contradictions flagged: YES / NO

**Reasoning** (2-3 sentences):
_______________________________________________________________
_______________________________________________________________

### Category 2: Self-Sufficiency (Weight: 25%)

**Definition**: Can the skill be understood without external context?

**Instructions**:
1. List technical terms/concepts used
2. Check if each is defined or explained in-skill
3. Note any assumptions about reader knowledge
4. Imagine you're unfamiliar with the topic - can you follow it?

**Score** (circle one):
- 5 - Complete standalone understanding, all terms defined
- 4 - 95%+ self-contained, rare external references justified
- 3 - 85%+ self-contained, some gaps inferable
- 2 - Frequent context gaps, terms undefined
- 1 - Cannot understand without external context

**Evidence**:
- Undefined terms: _______________________________
- Context dependencies: _______________________________

**Reasoning** (2-3 sentences):
_______________________________________________________________
_______________________________________________________________

### Category 3: Completeness (Weight: 20%)

**Definition**: Coverage of stated scope and source material.

**Instructions**:
1. Identify stated scope (description/TL;DR)
2. List main topics in source material
3. Check if each topic is addressed in skill
4. Note significant gaps

**Score** (circle one):
- 5 - Scope fully covered, 90%+ of source material synthesized
- 4 - 85%+ scope covered, minor gaps
- 3 - 75%+ scope covered, some gaps
- 2 - <75% covered, significant gaps
- 1 - Incomplete, major sections missing

**Evidence**:
- Scope coverage: ___% (subjective estimate)
- Source coverage: ___% (subjective estimate)
- Major gaps: _______________________________

**Reasoning** (2-3 sentences):
_______________________________________________________________
_______________________________________________________________

### Category 4: Specificity (Weight: 15%)

**Definition**: Actionability and detail of patterns/guidance.

**Instructions**:
1. Count patterns/guidelines in skill
2. For each, check if it includes when/why/how context and examples
3. Identify vague or generic patterns
4. Test: Can you apply this without guessing?

**Score** (circle one):
- 5 - All patterns actionable with when/why/how + examples
- 4 - 90%+ actionable, most have examples
- 3 - 75%+ actionable, some examples
- 2 - <75% actionable, vague guidance
- 1 - Generic advice, not actionable

**Evidence**:
- Total patterns: ___
- Actionable patterns: ___
- Patterns with examples: ___
- Vague patterns: _______________________________

**Reasoning** (2-3 sentences):
_______________________________________________________________
_______________________________________________________________

### Category 5: No Overlap (Weight: 10%)

**Definition**: Skill provides novel value beyond Claude's built-in knowledge.

**Instructions**:
1. Identify generic content Claude would already know
   - Generic best practices
   - Common knowledge
   - Standard definitions
2. Identify specialized/novel content
   - Organization-specific patterns
   - Tool-specific workflows
   - Non-obvious insights
3. Assess if skill justifies existence

**Score** (circle one):
- 5 - Entirely novel, clear specialized value
- 4 - 90%+ novel, significant value add
- 3 - 75%+ novel, moderate value add
- 2 - <75% novel, questionable value
- 1 - Mostly duplicates built-in knowledge

**Evidence**:
- Novelty estimate: ___%
- Generic content examples: _______________________________
- Specialized content examples: _______________________________

**Reasoning** (2-3 sentences):
_______________________________________________________________
_______________________________________________________________

### Overall Assessment

**Weighted Score Calculation**:
```
(Source Fidelity × 0.30) + (Self-Sufficiency × 0.25) +
(Completeness × 0.20) + (Specificity × 0.15) + (No Overlap × 0.10)
```

- Source Fidelity: ___ × 0.30 = ___
- Self-Sufficiency: ___ × 0.25 = ___
- Completeness: ___ × 0.20 = ___
- Specificity: ___ × 0.15 = ___
- No Overlap: ___ × 0.10 = ___

**Total Weighted Score**: ___ / 5.0 = ___ (as decimal 0-1)

**Recommendation** (circle one): PASS (≥0.85) / FAIL (<0.85)

**Critical Issues** (if any):
_______________________________________________________________
_______________________________________________________________

**Warnings** (if any):
_______________________________________________________________
_______________________________________________________________

**Overall Comments**:
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________

## Calibration Analysis

After completing human evaluation on 20 skills:

### 1. Calculate Agreement with LLM-Judge

For each skill, compare human and LLM scores:

```python
def calculate_agreement(human_scores, llm_scores):
    """
    Agreement = within 0.5 points on 5-point scale
    Target: 90%+ agreement
    """
    agreements = 0
    total = len(human_scores)

    for skill_id in human_scores:
        human = human_scores[skill_id]
        llm = llm_scores[skill_id]

        # Check each category
        category_agreements = 0
        for category in human["categories"]:
            diff = abs(human["categories"][category]["score"] -
                      llm["categories"][category]["score"])
            if diff <= 0.5:
                category_agreements += 1

        # Skill agrees if 4/5 categories agree
        if category_agreements >= 4:
            agreements += 1

    return agreements / total
```

**Acceptance criteria**: ≥90% agreement

### 2. Identify Systematic Biases

Look for patterns in disagreements:

- **Category-specific**: Does LLM consistently over/under-score a category?
- **Score-specific**: Does LLM struggle with middle scores (3s)?
- **Content-specific**: Does LLM misjudge certain content types?

Example findings:
- "LLM judge gave 'completeness' scores 0.5-1.0 points higher than human in 60% of cases"
- "LLM struggled to identify generic content, over-scored 'no overlap' in 8/20 cases"

### 3. Rubric Adjustment

Based on systematic biases:

1. **Update scale descriptors** - Add specificity or examples
2. **Refine evaluation prompts** - Add checks or counterexamples
3. **Add calibration notes** - Document known edge cases
4. **Re-test on subset** - Validate improvements

### 4. Documentation

Create calibration report:

```markdown
# LLM-Judge Calibration Report

**Date**: 2026-02-14
**Evaluator**: [Name]
**Skills evaluated**: 20

## Agreement Rate

- Overall: 92% (18/20 skills)
- By category:
  - Source Fidelity: 95% (19/20)
  - Self-Sufficiency: 90% (18/20)
  - Completeness: 85% (17/20) ⚠️
  - Specificity: 95% (19/20)
  - No Overlap: 90% (18/20)

## Systematic Biases Found

1. **Completeness over-scoring** - LLM gave higher scores in 12/20 cases
   - Cause: LLM focused on quantity over quality of coverage
   - Fix: Updated rubric to emphasize "meaningful coverage"

## Rubric Changes

- Updated "Completeness" scale descriptors
- Added example of "high quantity, low quality" coverage
- Added check: "Does coverage address user needs?"

## Re-calibration Results

- Completeness agreement improved to 95% on 10-skill subset
- Overall agreement maintained at 92%

## Recommendation

✅ LLM-judge ready for production use
```

## Best Practices

### Calibration Sample Selection

**Distribution** (20 skills):
- 5 excellent (expected score ≥4.5)
- 10 good (expected score 3.5-4.5)
- 3 marginal (expected score 3.0-3.5)
- 2 failing (expected score <3.0)

**Diversity**:
- Different domains (deployment, testing, security, etc.)
- Different source counts (2-5 sources)
- Different complexities (simple workflows → complex methodologies)

### Avoiding Evaluator Bias

1. **Blind evaluation** - Don't see LLM scores before grading
2. **Random order** - Evaluate in shuffled order to avoid fatigue effects
3. **Breaks** - Evaluate max 5 skills per session
4. **Consistency checks** - Re-evaluate 2-3 skills after completing set

### Edge Case Documentation

When you encounter difficult-to-grade skills:

```markdown
## Edge Case: [Skill Name]

**Challenge**: [What made this hard to grade?]
**Decision**: [How did you score it?]
**Rationale**: [Why?]
**LLM comparison**: [Did LLM agree?]
**Recommendation**: [Should rubric be updated?]
```

## Time-Saving Tips

1. **Pre-read sources** - Understand material before evaluating skill
2. **Use checklist** - Print grading form, check boxes as you go
3. **Batch similar skills** - Evaluate all deployment skills together
4. **Template reasoning** - Keep common phrases ("All claims traceable, no fabrication")
5. **Focus on disagreements** - Spend more time on skills where LLM may struggle

## Quality Checks

After completing evaluation:

- [ ] All scores filled in (no blanks)
- [ ] Reasoning provided for each category (2-3 sentences)
- [ ] Evidence documented (counts, examples)
- [ ] Weighted score calculated correctly
- [ ] Recommendation matches threshold (≥0.85 = PASS)
- [ ] Critical issues noted if score <3.0 in any category
- [ ] Overall comments provided

## Example Completed Evaluation

See `tests/calibration/examples/deployment-skill-human-grade.md` for a fully worked example.
