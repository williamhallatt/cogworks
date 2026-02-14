---
name: cogworks-test
description: "Systematic validation of cogworks skills through layered grading (deterministic checks, LLM-as-judge, optional human review). Tests synthesis quality, skill structure, source fidelity, and observable behavior. Use when validating generated skills, checking regression, or calibrating quality metrics."
tools: [Read, Glob, Bash, Write]
context: inline
---

# Cogworks Testing Framework

Automated testing and validation for cogworks-generated skills using eval-driven development methodology.

## Purpose

Validates that generated skills meet quality requirements through three-layer grading:

1. **Deterministic checks** (fast, cheap) - Structure, syntax, required elements
2. **LLM-as-judge** (moderate cost) - Content quality, source fidelity, actionability
3. **Human review** (optional) - Calibration and dispute resolution

## When to Use

- **After skill generation** - Validate cogworks-encode → cogworks-learn output
- **Regression testing** - Verify golden samples still pass after framework changes
- **Quality assurance** - Check skills meet requirements before production use
- **Calibration** - Validate LLM-judge accuracy against human grades

## Knowledge Base Summary

- **Layered grading prevents waste** - $0.00001 deterministic checks filter failures before $1.50 LLM evaluation (150,000× cost difference)
- **Five weighted quality dimensions** - Source fidelity (30%), self-sufficiency (25%), completeness (20%), specificity (15%), no overlap (10%)
- **Success threshold is 0.85** - Overall score ≥0.85 with zero critical failures required to pass
- **Three-layer architecture** - Fast deterministic → moderate LLM-judge → expensive human review (only when needed)
- **Test data organization** - Golden samples (regression), negative controls (should fail), edge cases (boundary conditions)
- **Integration ready** - Automatically invoked via `@cogworks encode --test` flag

## Invocation

```bash
# Test a generated skill
/cogworks-test {skill-slug}

# Test with JSON output
/cogworks-test {skill-slug} --json

# Test and compare against golden sample
/cogworks-test {skill-slug} --compare-against tests/datasets/golden-samples/{slug}/

# Full test suite including human review prompts
/cogworks-test {skill-slug} --full
```

## Core Testing Workflow

**Step 1: Locate Skill** - Resolve skill path, verify exists

**Step 2: Load Configuration** - Read framework-config.yaml (thresholds, weights, critical failures)

**Step 3: Run Layer 1** - Execute deterministic-checks.sh, exit early if critical failures found

**Step 4: Run Layer 2** - Evaluate 5 quality dimensions using LLM-judge rubrics, compute weighted score

**Step 5: Generate Reports** - Create JSON (machine-readable) and Markdown (human-readable) outputs

**Step 6: Report Results** - Display PASS/FAIL with scores, category breakdown, warnings, and recommendations

See [reference.md](reference.md) for complete workflow details, bash examples, configuration structure, and quality rubrics.

## Quick Decision Framework

- **Skill just generated?** → Run `/cogworks-test {slug}` immediately
- **Test failing?** → Check Layer 1 (deterministic) first, then Layer 2 (LLM-judge) scores
- **Need comparison?** → Use `--compare-against tests/datasets/golden-samples/{slug}/`
- **LLM-judge inconsistent?** → Run calibration with `--generate-human-review-form`, check agreement
- **Want automation?** → Use `@cogworks encode <sources> --test` for automatic validation

## Success Indicators

Framework is working correctly when:

- All golden samples pass with scores ≥0.85
- Negative controls correctly fail or warn
- Deterministic checks catch structural issues instantly
- LLM-judge aligns with human evaluation (90%+ agreement)
- Test execution completes in <2 minutes
- Reports are clear and actionable

## Files and References

**Full knowledge base**: [reference.md](reference.md) - Complete methodology, rubrics, configuration, troubleshooting

**Testing patterns**: [patterns.md](patterns.md) - Layered grading, weighted scoring, machine + human readable outputs

**Usage examples**: [examples.md](examples.md) - Concrete test scenarios, calibration workflows, regression testing

**Framework files**:

- `.claude/test-framework/config/framework-config.yaml` - All settings and thresholds
- `.claude/test-framework/graders/deterministic-checks.sh` - Layer 1 bash script
- `.claude/test-framework/graders/llm-judge-rubrics.md` - Layer 2 evaluation rubrics
- `.claude/test-framework/graders/human-review-guide.md` - Layer 3 calibration guide
- `.claude/test-framework/templates/` - Test case templates and report templates
