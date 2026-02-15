# Testing Guide for Cogworks

This document explains the two-level testing architecture in cogworks: **testing skills** (using the framework) and **testing the framework itself** (meta-testing).

---

## Table of Contents

1. [Testing Architecture Overview](#testing-architecture-overview)
2. [Level 1: Testing Skills (Normal Usage)](#level-1-testing-skills-normal-usage)
3. [Level 2: Testing the Framework (Meta-Testing)](#level-2-testing-the-framework-meta-testing)
4. [Quick Reference](#quick-reference)
5. [Adding New Tests](#adding-new-tests)
6. [Troubleshooting](#troubleshooting)

---

## Testing Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│ LEVEL 1: Testing Skills                                         │
│ Purpose: Validate cogworks-generated skills meet quality reqs   │
│ Who uses: Skill authors, CI/CD, automated workflows            │
│ Location: .claude/test-framework/                              │
└─────────────────────────────────────────────────────────────────┘
                           ▲
                           │
                    validated by
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│ LEVEL 2: Testing the Framework (Meta-Testing)                  │
│ Purpose: Validate that the testing framework works correctly   │
│ Who uses: Framework developers, regression testing             │
│ Location: tests/                                               │
└─────────────────────────────────────────────────────────────────┘
```

### Key Distinction

- **`.claude/test-framework/`** - The testing framework (tests skills)
- **`tests/`** - Tests of the testing framework (validates framework behavior)

Think of it as: "The framework tests skills. The tests directory tests the framework."

---

## Level 1: Testing Skills (Normal Usage)

### What This Does

Validates that a cogworks-generated skill meets quality requirements through:

- **Layer 1**: Deterministic checks (structure, syntax, required elements)
- **Layer 2**: LLM-as-judge evaluation (content quality, source fidelity)
- **Layer 3**: Human review (optional calibration)

### File Structure

```
.claude/test-framework/
├── README.md                      # Complete framework documentation
├── config/
│   └── framework-config.yaml      # Thresholds (line limits, scores, weights)
├── graders/
│   ├── deterministic-checks.sh    # Layer 1: Fast structural validation
│   ├── llm-judge-rubrics.md       # Layer 2: Quality evaluation criteria
│   └── human-review-guide.md      # Layer 3: Human evaluation guide
├── scripts/
│   └── calculate-agreement.py     # Calibration: Compare LLM vs human scores
└── templates/
    └── test-case-template.md      # Template for creating test cases
```

### Usage Scenarios

#### Scenario 1: Test a Skill After Generation

**When**: Just generated a new skill via `@cogworks encode` or `@cogworks learn`

**Command**:

```
/cogworks-test my-new-skill
```

**What happens**:

1. Locates skill at `.claude/skills/my-new-skill/`
2. Runs Layer 1 deterministic checks (~50ms)
3. If Layer 1 passes, runs Layer 2 LLM-judge evaluation (~50 seconds, ~$1.50)
4. Generates reports (JSON + Markdown)
5. Returns PASS/FAIL with scores and recommendations

**Expected output**:

```
=== Layer 1: Deterministic Checks ===
✓ All structural checks passed (10/10)

=== Layer 2: LLM-as-Judge Evaluation ===
Source Fidelity:     4.5/5.0 (30% weight)
Self-Sufficiency:    4.0/5.0 (25% weight)
Completeness:        4.5/5.0 (20% weight)
Specificity:         4.0/5.0 (15% weight)
No Overlap:          5.0/5.0 (10% weight)

Overall Score:       4.35/5.0 (Weighted: 0.87)
Recommendation:      PASS ✅ (threshold: 0.85)
```

#### Scenario 2: Test with JSON Output (Automation)

**When**: Integrating tests into scripts or CI/CD

**Command**:

```
/cogworks-test my-skill --json
```

**Output**:

```json
{
  "skill_slug": "my-skill",
  "status": "pass",
  "layer1": {
    "status": "pass",
    "critical_failures": 0,
    "warnings": 1,
    "checks_passed": 10
  },
  "layer2": {
    "overall_score": 4.35,
    "weighted_score": 0.87,
    "dimensions": {
      "source_fidelity": 4.5,
      "self_sufficiency": 4.0,
      "completeness": 4.5,
      "specificity": 4.0,
      "no_overlap": 5.0
    }
  },
  "recommendation": "pass"
}
```

#### Scenario 3: Regression Testing (Compare Against Baseline)

**When**: Framework changed, want to verify skills didn't regress

**Command**:

```
/cogworks-test my-skill --compare-against tests/datasets/golden-samples/my-skill/
```

**What happens**:

1. Runs current test on skill
2. Loads expected results from `golden-samples/my-skill/expected-layer1-results.json`
3. Compares actual vs expected within tolerance (±5% for scores, ±10 lines, etc.)
4. Reports: PASS (within tolerance) or REGRESSION DETECTED

**Output**:

```
=== Regression Testing ===
Comparing against: tests/datasets/golden-samples/my-skill/

Layer 1 Comparison:
  Line count:        186 → 188 (within ±10 tolerance) ✓
  Citations:         4 → 4 (unchanged) ✓
  Warnings:          1 → 1 (unchanged) ✓
  Critical failures: 0 → 0 (unchanged) ✓

Result: NO REGRESSION DETECTED ✅
```

#### Scenario 4: Direct Layer 1 Testing (Fast Feedback)

**When**: Quick structural validation without LLM costs

**Command**:

```bash
bash .claude/test-framework/graders/deterministic-checks.sh .claude/skills/my-skill/
```

**Output**:

```
=== Deterministic Checks Results ===

✓ Passed (10):
  - SKILL.md exists
  - Frontmatter is valid YAML
  - Required frontmatter fields present
  - Line count within limit (186/500)
  - Citations present (4 found)
  - No forbidden patterns
  - Supporting files follow 3+ entry rule
  - Description has sufficient content
  - No duplicate headers
  - Markdown syntax valid

⚠ Warnings (1):
  - patterns.md has <3 entries (2) - should fold into reference.md
```

**JSON output** (for scripting):

```bash
bash .claude/test-framework/graders/deterministic-checks.sh .claude/skills/my-skill/ --json
```

### Understanding Test Results

#### Pass Criteria

A skill passes when:

- **Layer 1**: Zero critical failures (warnings OK)
- **Layer 2**: Weighted score ≥0.85 (on 0-1 scale)
- All required structural elements present

#### Common Failures

| Issue                               | Layer | Severity        | How to Fix                                    |
| ----------------------------------- | ----- | --------------- | --------------------------------------------- |
| No citations                        | L1    | Critical        | Add `[source]` or `(file.md:123)` references  |
| >500 lines in SKILL.md              | L1    | Critical        | Move content to supporting files              |
| Invalid YAML                        | L1    | Critical        | Fix frontmatter syntax                        |
| Forbidden patterns (TODO, API keys) | L1    | Critical        | Remove/replace forbidden content              |
| Low source fidelity (<3.0)          | L2    | Failing         | Improve citation coverage, reduce fabrication |
| Score 0.80-0.84                     | L2    | Below threshold | Improve weakest dimension(s)                  |

#### Early Termination

If Layer 1 has critical failures:

- Layer 2 is **skipped** (saves ~$1.50 per skill)
- Fix Layer 1 issues first
- Re-run test after fixes

---

## Level 2: Testing the Framework (Meta-Testing)

### What This Does

Validates that the testing framework itself works correctly through:

- Black-box testing (test documented promises, not implementation)
- Regression testing (detect framework behavior changes)
- Coverage analysis (ensure all features tested)

### File Structure

```
tests/
├── run-black-box-tests.sh              # Main test runner (340 lines)
├── test-suite/
│   └── mvp-test-cases.jsonl            # 15 test definitions
├── test-data/                          # Test fixtures (8 skills)
│   ├── no-citations-skill/             # Should trigger citation failure
│   ├── bad-yaml-skill/                 # Should trigger YAML failure
│   ├── overlimit-skill/                # Should trigger line limit failure
│   ├── few-citations-skill/            # Should trigger citation warning
│   ├── near-limit-skill/               # Should trigger line limit warning
│   ├── exactly-500-skill/              # Edge case: exactly at limit
│   ├── exactly-3-entries-skill/        # Edge case: minimum entries
│   └── unclosed-fence-skill/           # Should trigger markdown error
├── datasets/
│   └── golden-samples/                 # Regression baselines (3 skills)
│       ├── skill-evaluation/
│       │   ├── metadata.yaml           # Expected behavior & tolerances
│       │   ├── expected-layer1-results.json
│       │   └── expected-skill/         # Baseline skill files
│       ├── cogworks-learn/
│       └── advanced-prompting/
├── results/
│   └── black-box-YYYYMMDD-HHMMSS/     # Test run outputs
└── *.md                                # Test documentation
```

### Usage Scenarios

#### Scenario 1: Run Full Meta-Test Suite

**When**: After framework changes, before committing

**Command**:

```bash
bash tests/run-black-box-tests.sh
```

**What happens**:

1. Reads 15 test cases from `mvp-test-cases.jsonl`
2. Executes each test against deterministic-checks.sh
3. Compares actual vs expected results
4. Reports pass/fail for each test
5. Generates summary report

**Expected output**:

```
╔════════════════════════════════════════════════════════════════╗
║   Black-Box Test Suite for cogworks-test Framework            ║
╚════════════════════════════════════════════════════════════════╝

Running: mvp-001 - layer1_passes_clean_skill
✅ PASS: mvp-001

Running: mvp-002 - layer1_catches_missing_citations
✅ PASS: mvp-002

[... 13 more tests ...]

╔════════════════════════════════════════════════════════════════╗
║                      TEST RESULTS SUMMARY                       ║
╚════════════════════════════════════════════════════════════════╝

Total Tests:  15
Passed:       15
Failed:       0
Skipped:      0

Pass Rate:    100%

✅ ALL TESTS PASSED
```

#### Scenario 2: Inspect Test Results

**When**: Want to understand why a test failed

**Location**: `tests/results/black-box-YYYYMMDD-HHMMSS/`

**Files**:

- `summary.csv` - Quick pass/fail overview
- `mvp-{id}-output.json` - Raw framework output
- `mvp-{id}-report.txt` - Detailed comparison

**Example report** (`mvp-002-report.txt`):

```
Test ID: mvp-002
Test Name: layer1_catches_missing_citations
Description: Skill with no citations triggers critical failure
Input: no-citations-skill

Expected:
{
  "status": "fail",
  "critical_failures": 1,
  "failure_contains": "No source citations found"
}

Actual:
{
  "status": "fail",
  "critical_failures": 1,
  "critical_failures": ["No source citations found"],
  ...
}

Result: PASS ✅
```

#### Scenario 3: Add a New Meta-Test

**When**: Adding new framework feature, need to test it

**Steps**:

1. **Create test fixture** (if needed):

```bash
mkdir tests/test-data/my-new-test-skill
echo "..." > tests/test-data/my-new-test-skill/SKILL.md
```

1. **Add test definition** to `tests/test-suite/mvp-test-cases.jsonl`:

```json
{
  "id": "mvp-016",
  "tier": 1,
  "test": "my_new_feature_test",
  "description": "New feature should trigger expected behavior",
  "input": "my-new-test-skill",
  "test_type": "layer1_direct",
  "expected": {
    "status": "fail",
    "critical_failures": 1,
    "failure_contains": "Expected error message"
  },
  "rationale": "Tests new feature documented in framework-config.yaml:123"
}
```

1. **Run tests**:

```bash
bash tests/run-black-box-tests.sh
```

1. **Verify your test**:

- If it passes: New feature works correctly ✅
- If it fails: Either feature broken or test expectation wrong

#### Scenario 4: Create New Golden Sample (Regression Baseline)

**When**: New high-quality skill to use as regression baseline

**Steps**:

1. **Create directory structure**:

```bash
mkdir -p tests/datasets/golden-samples/my-skill/{expected-skill,sources}
```

1. **Generate Layer 1 baseline**:

```bash
bash .claude/test-framework/graders/deterministic-checks.sh \
    .claude/skills/my-skill/ --json \
    > tests/datasets/golden-samples/my-skill/expected-layer1-results.json
```

1. **Copy skill files**:

```bash
cp -r .claude/skills/my-skill/* \
    tests/datasets/golden-samples/my-skill/expected-skill/
```

1. **Create metadata.yaml**:

```yaml
---
skill_slug: my-skill
sample_type: golden
quality_tier: excellent
description: Brief description of skill

layer1_expected:
  status: pass
  critical_failures: 0
  warnings: 0
  checks_passed: 10
  line_count: 150
  citation_count: 5

tolerance:
  line_count: 10 # ±10 lines acceptable
  citation_count: 2 # ±2 citations acceptable
  warnings: 1 # ±1 warning acceptable
  score_percentage: 5 # ±5% for LLM scores

quality_benchmarks:
  why_golden: |
    - Comprehensive coverage
    - Clean structure
    - Well-cited
    - Production-ready

regression_detection:
  critical_regressions:
    - "Critical failures increase from 0"
    - "Status changes from pass to fail"
    - "Line count exceeds 160"

  warning_regressions:
    - "Warnings increase by >2"
    - "Line count increases by >10"

  acceptable_changes:
    - "Line count fluctuates ±10"
    - "Citation count ±2"
```

1. **Test the baseline**:

```bash
# Verify baseline matches current skill
bash .claude/test-framework/graders/deterministic-checks.sh \
    .claude/skills/my-skill/ --json | \
    diff - tests/datasets/golden-samples/my-skill/expected-layer1-results.json
```

If no diff: Baseline is accurate ✅

#### Scenario 5: Detect Regressions in Framework

**When**: After modifying framework, verify no behavior changed

**Command**:

```bash
# Run tests before changes
bash tests/run-black-box-tests.sh
# Result: 15/15 passed

# Make framework changes
vim .claude/test-framework/graders/deterministic-checks.sh

# Run tests after changes
bash tests/run-black-box-tests.sh
# Result: 14/15 passed (regression detected!)
```

**If tests fail**:

1. Check `tests/results/black-box-*/` for details
2. Determine if framework bug or test needs update
3. Fix framework if bug, update test if expectations changed

---

## Quick Reference

### Testing Skills (Normal Usage)

| Task                     | Command                                                                                     | Layer | Speed | Cost   |
| ------------------------ | ------------------------------------------------------------------------------------------- | ----- | ----- | ------ |
| Quick structural check   | `bash .claude/test-framework/graders/deterministic-checks.sh .claude/skills/{slug}/`        | L1    | ~50ms | Free   |
| Full quality evaluation  | `/cogworks-test {slug}`                                                                     | L1+L2 | ~50s  | ~$1.50 |
| JSON output (automation) | `/cogworks-test {slug} --json`                                                              | L1+L2 | ~50s  | ~$1.50 |
| Regression testing       | `/cogworks-test {slug} --compare-against tests/datasets/golden-samples/{slug}/`             | L1+L2 | ~50s  | ~$1.50 |
| Layer 1 JSON output      | `bash .claude/test-framework/graders/deterministic-checks.sh .claude/skills/{slug}/ --json` | L1    | ~50ms | Free   |

### Testing the Framework (Meta-Testing)

| Task                 | Command                                             | Purpose                     |
| -------------------- | --------------------------------------------------- | --------------------------- |
| Run all meta-tests   | `bash tests/run-black-box-tests.sh`                 | Validate framework behavior |
| View latest results  | `ls -t tests/results/ \| head -1`                   | Find most recent test run   |
| Check specific test  | `cat tests/results/black-box-*/mvp-{id}-report.txt` | Debug test failure          |
| Add new test         | Edit `tests/test-suite/mvp-test-cases.jsonl`        | Extend test coverage        |
| Create golden sample | See "Scenario 4" above                              | Add regression baseline     |

### Exit Codes (deterministic-checks.sh)

| Exit Code | Meaning                        | Action                              |
| --------- | ------------------------------ | ----------------------------------- |
| 0         | All checks passed, no warnings | Proceed to Layer 2                  |
| 1         | Critical failures detected     | Fix issues before Layer 2           |
| 2         | Passed with warnings           | Review warnings, proceed to Layer 2 |

### Test Coverage Status

| Component                      | Status              | Notes                                                |
| ------------------------------ | ------------------- | ---------------------------------------------------- |
| Layer 1 (deterministic checks) | ✅ Fully tested     | 15 tests, 100% pass rate                             |
| Layer 2 (LLM-judge)            | ⚠️ Not automated    | Rubrics exist, needs wrapper script                  |
| Layer 3 (human review)         | ⚠️ Manual only      | Guide exists, no automation                          |
| Regression baselines           | ✅ 3 golden samples | skill-evaluation, cogworks-learn, advanced-prompting |

---

## Adding New Tests

### Adding a Framework Feature Test

**Scenario**: You added forbidden pattern detection for AWS secret keys

1. **Update framework** (`.claude/test-framework/graders/deterministic-checks.sh`):

```bash
forbidden=(
    "TODO"
    "FIXME"
    "sk-[a-zA-Z0-9]{32}"     # OpenAI key
    "AKIA[0-9A-Z]{16}"        # AWS access key
    "aws_secret_access_key"   # ← NEW: AWS secret pattern
)
```

1. **Create test fixture** (`tests/test-data/aws-secret-skill/SKILL.md`):

```markdown
---
name: aws-secret-test
description: Test skill with AWS secret
---

# Test

This has an AWS secret: aws_secret_access_key=wJalrXUtnFEMI/K7MDENG
```

1. **Add test case** (`tests/test-suite/mvp-test-cases.jsonl`):

```json
{
  "id": "mvp-016",
  "tier": 1,
  "test": "layer1_catches_aws_secret",
  "description": "Skill with AWS secret triggers critical failure",
  "input": "aws-secret-skill",
  "test_type": "layer1_direct",
  "expected": {
    "status": "fail",
    "critical_failures": 1,
    "failure_contains": "Forbidden pattern found"
  },
  "rationale": "AWS secret detection documented in deterministic-checks.sh:103"
}
```

1. **Run tests**:

```bash
bash tests/run-black-box-tests.sh
# Should show: 16/16 passed (if feature works correctly)
```

### Adding a Golden Sample

See [Scenario 4](#scenario-4-create-new-golden-sample-regression-baseline) above.

---

## Troubleshooting

### "Test failed but framework seems correct"

**Cause**: Test expectation might be wrong, not framework

**Debug steps**:

1. Check actual output: `cat tests/results/black-box-*/mvp-{id}-output.json`
2. Compare with expected: Check test definition in `mvp-test-cases.jsonl`
3. Verify manually: Run deterministic-checks.sh directly on test fixture
4. If framework correct: Update test expectation

### "All tests pass but skill still has issues"

**Cause**: Tests don't cover that scenario

**Solution**: Add new test case for the issue:

1. Create minimal test fixture reproducing issue
2. Define expected behavior
3. Add to `mvp-test-cases.jsonl`
4. Verify test fails with current framework
5. Fix framework
6. Verify test now passes

### "Layer 2 tests can't run"

**Cause**: Layer 2 (LLM-judge) orchestration not implemented

**Status**:

- Layer 2 rubrics fully documented (`.claude/test-framework/graders/llm-judge-rubrics.md`)
- Wrapper script needed to automate execution
- Estimated work: 4-6 hours

**Workaround**:

- Test Layer 1 only (already comprehensive)
- Manually apply Layer 2 rubrics when needed
- Use `/cogworks-test` skill invocation (orchestrates Layer 2 manually)

### "Golden sample comparison not working"

**Cause**: `--compare-against` flag not implemented in test runner

**Status**: Documented but not coded

**Workaround**: Manually compare:

```bash
# Run current test
bash .claude/test-framework/graders/deterministic-checks.sh \
    .claude/skills/{slug}/ --json > /tmp/actual.json

# Compare with baseline
diff <(jq 'del(.timestamp)' /tmp/actual.json) \
     <(jq 'del(.timestamp)' tests/datasets/golden-samples/{slug}/expected-layer1-results.json)
```

### "Test fixtures modifying production skills"

**Cause**: Test created in wrong location

**Solution**:
t now passes

### "Layer 2 tests can't run"

**Cause**: Layer 2 (LLM-judge) orchestration not implemented

**Status**:

- Layer 2 rubrics fully documented (`.claude/test-framework/graders/llm-judge-rubrics.md`)
- Wrapper script needed to automate execution
- Estimated work: 4-6 hours

**Workaround**:

- Test Layer 1 only (already comprehensive)
- Manually apply Layer 2 rubrics when needed
- Use `/cogworks-test` skill invocation (orchestrates Layer 2 manually)

### "Golden sample comparison not working"

**Cause**: `--compare-against` flag not implemented in test runner

**Status**: Documented but not coded

**Workaround**: Manually compare:

```bash
# Run current test
bash .claude/test-framework/graders/deterministic-checks.sh \
    .claude/skills/{slug}/ --json > /tmp/actual.json

# Compare with baseline
diff <(jq 'del(.timestamp)' /tmp/actual.json) \
     <(jq 'del(.timestamp)' tests/datasets/golden-samples/{slug}/expected-layer1-results.json)
```

### "Test fixtures modifying production skills"

**Cause**: Test created in wrong location

**Solution**:

- Test fixtures go in `tests/test-data/`
- Golden samples go in `tests/datasets/golden-samples/`
- Never modify `.claude/skills/` directly in tests

---

## Best Practices

### For Skill Authors

1. **Test early**: Run `/cogworks-test` immediately after skill generation
2. **Fix Layer 1 first**: Don't proceed to Layer 2 with critical failures
3. **Understand warnings**: Review warnings even if passing
4. **Baseline your skills**: Create golden samples for important skills

### For Framework Developers

1. **Black-box methodology**: Test documented behavior, not implementation
2. **Test before committing**: Run `bash tests/run-black-box-tests.sh`
3. **Update tests with features**: New feature → new test case
4. **Document test rationale**: Link each test to documentation

### For CI/CD Integration

1. **Fast feedback**: Run Layer 1 only in pre-commit hooks
2. **Full validation**: Run Layer 1+2 in CI pipeline
3. **Regression protection**: Test golden samples on framework changes
4. **Block on failures**: Don't merge PRs with failing tests

---

## Documentation Files

- **`.claude/test-framework/README.md`** - Framework usage guide (503 lines)
- **`tests/BLACK-BOX-TESTING-SUMMARY.md`** - Meta-testing overview
- **`tests/PHASE{1,2,3}-*.md`** - Detailed test implementation results
- **`TESTING.md`** - This file (comprehensive testing guide)
- **`CLAUDE.md`** - Project-level guidance for Claude

---

## Related Commands

```bash
# Test a skill
/cogworks-test my-skill
/cogworks-test my-skill --json
/cogworks-test my-skill --compare-against tests/datasets/golden-samples/my-skill/

# Test the framework
bash tests/run-black-box-tests.sh

# Quick checks
bash .claude/test-framework/graders/deterministic-checks.sh .claude/skills/my-skill/
bash .claude/test-framework/graders/deterministic-checks.sh .claude/skills/my-skill/ --json

# View results
ls -t tests/results/ | head -1
cat tests/results/black-box-*/summary.csv
cat tests/results/black-box-*/mvp-001-report.txt

# Create golden sample
mkdir -p tests/datasets/golden-samples/my-skill/expected-skill
bash .claude/test-framework/graders/deterministic-checks.sh .claude/skills/my-skill/ --json \
    > tests/datasets/golden-samples/my-skill/expected-layer1-results.json
```

---

**Last Updated**: 2026-02-14
**Test Coverage**: 15 tests, 100% pass rate (Layer 1 only)
**Golden Samples**: 3 (skill-evaluation, cogworks-learn, advanced-prompting)
