# Testing Framework for Cogworks Skill Creation Workflow

## Context

The cogworks agent currently has **no automated testing** (CLAUDE.md:40, ROADMAP.md:36). All validation relies on manual user feedback, making it difficult to:

- Detect regressions when modifying cogworks-encode or cogworks-learn
- Validate synthesis quality before skill generation
- Ensure generated skills meet quality requirements consistently
- Catch structural issues early in the pipeline

ROADMAP.md Section 3 identifies this as a priority, requesting:
- Testing strategy for synthesis output quality
- Test harness for skill structure and correctness
- Regression tests for known-good synthesis scenarios
- Snapshot-style testing for reference.md stability

This plan implements a testing framework that integrates with the existing cogworks pipeline while leveraging the skill-evaluation skill's methodology (SMART criteria, layered grading, negative controls, observable behavior focus).

## Approach

### Integration Strategy

**Opt-in testing** via `--test` flag in cogworks workflow:
- Add Step 6.5 (after validation, before confirmation) to invoke testing
- Testing is optional initially to avoid disrupting existing workflows
- Can be made default once framework is mature

### Architecture Overview

**Three-layer structure:**

1. **Test Infrastructure** (`.claude/test-framework/`)
   - Grading methodology (deterministic checks, LLM-judge rubrics, human review guides)
   - Configuration (success thresholds, weights, test composition rules)
   - Templates (test case format, validation report format)

2. **Test Data** (`tests/`)
   - `datasets/` - Golden samples, negative controls, edge cases
   - `results/` - Timestamped test run outputs
   - `calibration/` - Human grades for LLM-judge validation

3. **Testing Orchestration** (`.claude/skills/cogworks-test/`)
   - New skill that executes test suites
   - Runs layered grading: deterministic → LLM-judge → human (optional)
   - Generates validation reports in JSON + Markdown

### Test Categories

**Category A: Synthesis Quality** (cogworks-encode output)
- Structure validation (required sections, concept/pattern counts)
- Content quality (LLM-judge: concept clarity, synthesis integration)
- Source fidelity (all claims traceable, citations present, conflicts flagged)
- Negative controls (insufficient sources → warns user)

**Category B: Skill Structure** (cogworks-learn output)
- File structure (SKILL.md exists, frontmatter valid, ≤500 lines)
- Supporting files (only created if 3+ entries, per CLAUDE.md:59)
- Description quality (keyword-rich for discovery)
- Organization (reference vs task content patterns)

**Category C: Observable Behavior**
- Skill invocability (activates on relevant requests)
- Negative controls (doesn't activate on unrelated requests)
- Tool usage (if applicable)

### Grading Methodology

**Layered approach** (from skill-evaluation skill):

1. **Deterministic checks** (Layer 1 - always run first)
   - Cost: ~$0.00001 per skill
   - Speed: <5 seconds
   - Validates: Structure, syntax, required elements, citation presence
   - Implementation: Bash scripts with grep/wc/python YAML validation

2. **LLM-as-judge** (Layer 2 - run if Layer 1 passes)
   - Cost: ~$0.50-2.00 per skill
   - Speed: 30-60 seconds
   - Validates: Content quality, integration, clarity, actionability
   - Implementation: Structured rubrics with JSON output, Claude Opus 4.6

3. **Human evaluation** (Layer 3 - optional, for calibration)
   - Cost: ~$50-200 per skill (expert time)
   - Speed: 15-30 minutes
   - Validates: Calibrates LLM-judge, resolves disputes
   - Target: 90%+ agreement between human and LLM grades

### Test Data Format

**JSONL for test cases** (industry standard for evals):
```jsonl
{"id": "test-001", "type": "synthesis_structure", "check": "has_tldr_section", "expected": true}
{"id": "test-002", "type": "skill_structure", "check": "skill_md_line_count", "expected": {"max": 500}}
{"id": "test-003", "type": "invocability", "user_request": "Deploy to staging", "should_activate": true}
```

**YAML for metadata and configuration:**
- `metadata.yaml` per golden sample (expected outputs, source info)
- `framework-config.yaml` (success thresholds, grading weights)

**Markdown + JSON for results:**
- `test-summary.json` (machine-readable, CI/CD integration)
- `validation-report.md` (human-readable, git-friendly)

### Success Criteria

**Overall pass requirements** (aligned with CLAUDE.md quality requirements):
- Weighted score ≥ 0.85
- Zero critical failures (frontmatter invalid, no source citations, etc.)
- Source fidelity ≥ 0.95 (95% of claims traceable)
- LLM-judge average ≥ 4.0/5
- All deterministic checks pass

**Quality dimensions** (from CLAUDE.md:48-54):
- Source fidelity (30% weight)
- Self-sufficiency (25% weight)
- Completeness (20% weight)
- Specificity (15% weight)
- No overlap (10% weight)

## Critical Files

### Files to Create

**1. `.claude/skills/cogworks-test/SKILL.md`**
- Testing orchestration skill
- Methods: test_synthesis_quality(), test_skill_structure(), test_source_fidelity(), generate_validation_report()
- Frontmatter: `user-invocable: true`, `tools: [Read, Glob, Bash]`, `context: inline`

**2. `.claude/test-framework/graders/deterministic-checks.md`**
- Bash scripts for Layer 1 validation
- Checks: required sections, line counts, frontmatter validity, citation presence, forbidden patterns
- Exit codes: 0=pass, 1=critical fail, 2=warning

**3. `.claude/test-framework/graders/llm-judge-rubrics.md`**
- Rubrics for Layer 2 quality assessment
- Categories: concept clarity, synthesis integration, pattern actionability, description keywords, example relevance
- Includes calibration notes and known biases (verbosity preference, position bias)

**4. `.claude/test-framework/graders/human-review-guide.md`**
- Guide for Layer 3 human evaluation
- 5-point scales aligned with quality requirements
- Grading form with weighted scoring
- Calibration analysis methods

**5. `.claude/test-framework/config/framework-config.yaml`**
- Success thresholds (concept count: 5-10, pattern count: ≥5, etc.)
- Grading weights by category
- Test dataset composition rules (50% explicit, 15% implicit, 10% contextual, 25% negative controls)
- Calibration parameters (20 sample size, 90% target agreement)

**6. `.claude/test-framework/templates/test-case-template.jsonl`**
- Example test cases in JSONL format
- Demonstrates structure for each test type
- Includes positive and negative controls

**7. `.claude/test-framework/templates/validation-report.md`**
- Template for human-readable reports
- Sections: Summary, Deterministic Checks, LLM-as-Judge, Source Fidelity, Recommendations

**8. `tests/datasets/golden-samples/deployment-skill/`** (first golden sample)
- `sources/` - 2-3 source files on deployment workflows
- `expected-synthesis.md` - Known-good cogworks-encode output
- `expected-skill/` - Known-good SKILL.md, reference.md, patterns.md
- `test-cases.jsonl` - 10-15 test cases (structure, content, invocability)
- `metadata.yaml` - Expected statistics, configuration

**9. `tests/datasets/negative-controls/insufficient-sources/`**
- `one-paragraph.md` - Sparse content (should trigger warning)
- `expected-outcome.yaml` - Should warn user about insufficient content
- `test-cases.jsonl` - Validates warning behavior

**10. `tests/datasets/negative-controls/overlapping-builtin/`**
- Source material on generic topic (e.g., "writing good code")
- `expected-outcome.yaml` - Should suggest not creating skill
- Tests the "no overlap" quality requirement

### Files to Modify

**11. `.claude/agents/cogworks.md`**
- Add Step 6.5 after "Validate Generated Output"
- Logic:
  ```markdown
  ### 6.5. Optional: Automated Testing

  If user invoked with `--test` flag:

  1. Invoke `/cogworks-test {slug}`
  2. Pass context: generated skill directory path (`.claude/skills/{slug}/`)
  3. Receive validation report with scores and recommendations
  4. If critical failures:
     - Present failures to user
     - Offer to fix automatically or proceed anyway
  5. If warnings only:
     - Present validation summary in success confirmation
  6. Log test results to `tests/results/{timestamp}/`
  ```
- Update Step 7 (Confirm Success) to include test summary when applicable

### Supporting Infrastructure

**12. Directory structure**
```
.claude/
  test-framework/
    graders/
    templates/
    config/
  skills/
    cogworks-test/

tests/
  datasets/
    golden-samples/
    negative-controls/
    edge-cases/
  results/
  calibration/
```

## Reusable Patterns

**From skill-evaluation skill:**
- Four-category test dataset composition (~25% negative controls)
- Layered grading (deterministic first to avoid expensive checks on obviously-failing cases)
- Observable behavior focus (validate what skills DO, not just what they SAY)
- SMART success criteria (Specific, Measurable, Achievable, Relevant)
- Start small, expand from failures (10-20 initial cases → 100+ mature)

**From cogworks-learn skill:**
- Progressive disclosure (SKILL.md ~100-500 lines, supporting files on-demand)
- Supporting file heuristic (3+ entries to justify separate file, per CLAUDE.md:59)
- Writing checklist pattern for pre-finalization validation

**From cogworks-encode skill:**
- Concept extraction (5-10 target)
- Pattern identification (5-10 target)
- Citation requirements (every example must cite source)
- Conflict flagging (explicitly note source disagreements)

## Implementation Phases

### Phase 1: Foundation (Core Infrastructure)
- Create directory structure
- Write framework config (framework-config.yaml)
- Write deterministic checks (bash scripts)
- Write LLM-judge rubrics
- Write human review guide
- Write templates (test cases, validation reports)

### Phase 2: Testing Skill
- Create cogworks-test skill (SKILL.md)
- Implement test execution logic
- Implement layered grading coordination
- Implement validation report generation
- Write supporting files (reference.md, patterns.md, examples.md)

### Phase 3: Golden Samples
- Create deployment-skill golden sample (complete end-to-end)
- Create 2 more golden samples in different domains
- Document expected outputs
- Write test cases (10-15 per sample)

### Phase 4: Negative Controls
- Create insufficient-sources scenario
- Create overlapping-builtin scenario
- Create contradictory-only scenario
- Write expected outcomes and test cases

### Phase 5: Integration
- Modify cogworks.md to add Step 6.5
- Update Step 7 confirmation to include test summary
- Test integration with existing cogworks workflow
- Document usage (README.md update)

### Phase 6: Calibration
- Run LLM-judge on 20 skills
- Collect human grades on same 20 skills
- Measure agreement rate (target: 90%+)
- Adjust rubrics if systematic biases detected
- Document calibration results

## Verification Plan

### Unit Testing
After creating each component:

**Test deterministic checks:**
```bash
# Create test skill with known issues
mkdir -p .test-workspace/test-skill
# Missing frontmatter
echo "# Test Skill" > .test-workspace/test-skill/SKILL.md

# Run deterministic checks
bash .claude/test-framework/graders/deterministic-checks.sh .test-workspace/test-skill

# Should return exit code 1 (critical failure) for missing frontmatter
```

**Test LLM-judge rubrics:**
```bash
# Invoke cogworks-test with a sample skill
/cogworks-test deployment-skill

# Verify:
# - JSON output is valid
# - Scores are in 1-5 range
# - Reasoning is provided
# - Issues are specific
```

**Test validation report generation:**
```bash
# Run full test suite on golden sample
/cogworks-test deployment-skill --full

# Verify tests/results/latest/ contains:
# - test-summary.json (valid JSON)
# - validation-report.md (all sections present)
# - Scores match success criteria thresholds
```

### Integration Testing
After modifying cogworks.md:

**Test opt-in flag:**
```bash
# Normal invocation (no testing)
@cogworks encode _sources/test-topic/

# Should complete without invoking cogworks-test
```

```bash
# With test flag
@cogworks encode _sources/test-topic/ --test

# Should:
# 1. Generate skill normally
# 2. Invoke /cogworks-test automatically
# 3. Present validation report
# 4. Include test summary in confirmation
```

**Test failure handling:**
```bash
# Create sources with known issues (no citations, fabricated claims)
@cogworks encode _sources/bad-sources/ --test

# Should:
# 1. Generate skill
# 2. Run tests
# 3. Report critical failures
# 4. Offer to fix or proceed
```

### End-to-End Validation
Test complete workflow:

**Golden sample regression:**
```bash
# Test all golden samples
for sample in tests/datasets/golden-samples/*/; do
  /cogworks-test $(basename $sample) --compare-against $sample
done

# Should:
# - All pass with scores ≥ 0.85
# - No critical failures
# - Match expected outputs (structure, content quality)
```

**Negative control validation:**
```bash
# Test insufficient sources
@cogworks encode tests/datasets/negative-controls/insufficient-sources/ --test

# Should warn user about sparse content

# Test overlapping builtin
@cogworks encode tests/datasets/negative-controls/overlapping-builtin/ --test

# Should suggest reconsidering skill creation
```

**Calibration check:**
```bash
# Measure human-LLM agreement
python3 .claude/test-framework/scripts/calculate-agreement.py \
  tests/calibration/human-grades/ \
  tests/results/latest/grading-details/llm-judge-scores.json

# Should report ≥90% agreement within 0.5 points on 5-point scale
```

### Success Indicators

Framework is production-ready when:
- ✅ All 3 golden samples pass with scores ≥ 0.85
- ✅ Negative controls correctly identify failure modes
- ✅ Deterministic checks catch all structural issues
- ✅ LLM-judge achieves 90%+ human agreement
- ✅ Integration with cogworks workflow functions correctly
- ✅ Validation reports are clear and actionable
- ✅ Test execution completes in <2 minutes for typical skill
- ✅ Documentation enables users to add new test cases

## Implementation Notes

**Context efficiency:**
- cogworks-test SKILL.md should be ≤500 lines (per cogworks-learn guidance)
- Supporting files (reference.md, patterns.md) loaded on-demand
- Test datasets stored separately from operational skills

**Progressive rollout:**
- Phase 1-2: Foundation usable by developers manually invoking /cogworks-test
- Phase 3-4: Golden samples enable regression detection
- Phase 5: Integration makes testing accessible via --test flag
- Phase 6: Calibration validates grading accuracy

**Future enhancements** (not in initial scope):
- CI/CD integration (GitHub Actions running tests on commits)
- Invocability simulation (test activation without deployment)
- Comparative testing (compare before/after skill modifications)
- Test case generation (AI-generated test cases from sources)

## References

**Existing skills to leverage:**
- `skill-evaluation` - Testing methodology and patterns
- `cogworks-encode` - Synthesis quality criteria
- `cogworks-learn` - Skill structure requirements and validation checklist

**Documentation:**
- CLAUDE.md - Quality requirements, platform limitations
- ROADMAP.md - Section 3 (automated testing requirements)
- cogworks.md - Workflow integration points

**File structure patterns:**
- `.claude/skills/{slug}/` - Standard skill organization
- Progressive disclosure (SKILL.md + supporting files)
- Supporting files only if 3+ distinct entries (CLAUDE.md:59)
