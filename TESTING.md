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

## Dependencies

Layer 1 deterministic checks require:

- `jq`
- `python3` with `PyYAML` installed

Example install commands:

```bash
# Ubuntu/Debian
sudo apt-get install -y jq python3-pip
python3 -m pip install pyyaml
```

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
├── graders/
│   ├── deterministic-checks.sh    # Layer 1: Fast structural validation (14 checks)
│   ├── llm-judge-rubrics.md       # Layer 2: Quality evaluation rubrics
│   └── human-review-guide.md      # Layer 3: Human evaluation guide
├── scripts/
│   └── calculate-agreement.py     # Calibration: Compare LLM vs human scores
└── templates/
    ├── test-case-template.jsonl   # Template for creating test cases
    └── validation-report.md       # Template for validation reports
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
3. If Layer 1 passes, runs Layer 2 LLM-judge evaluation (inline, no external API)
4. Writes results to `{skill_path}/.cogworks-results/{slug}-results.json` (and copies to `tests/results/` if it exists)
5. Returns PASS/FAIL with scores and recommendations

**Expected output**:

```
=== Layer 1: Deterministic Checks ===
✓ All structural checks passed (14/14)

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
  "layer1": {
    "status": "pass",
    "critical_failures": [],
    "warnings": ["..."],
    "checks_passed": ["... 14 check names ..."]
  },
  "layer2": {
    "source_fidelity": { "score": 4, "weight": 0.30, "evidence": {}, "reasoning": "..." },
    "self_sufficiency": { "score": 4, "weight": 0.25, "evidence": {}, "reasoning": "..." },
    "completeness": { "score": 4, "weight": 0.20, "evidence": {}, "reasoning": "..." },
    "specificity": { "score": 4, "weight": 0.15, "evidence": {}, "reasoning": "..." },
    "no_overlap": { "score": 4, "weight": 0.10, "evidence": {}, "reasoning": "..." }
  },
  "overall": {
    "weighted_score": 0.80,
    "recommendation": "FAIL"
  }
}
```

#### Scenario 3: Layer 1 Only (Fast Feedback)

**When**: Quick structural validation without LLM costs

**Command**:

```bash
bash .claude/test-framework/graders/deterministic-checks.sh .claude/skills/my-skill/
```

**Output**:

```
=== Deterministic Checks Results ===

✓ Passed (14):
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
  - No cross-file heading duplication
  - Frontmatter name format valid
  - Supporting files have substantive content
  - Citation format consistency

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
- **Layer 2**: Weighted score ≥0.85 AND no dimension scores below 3
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

- Layer 2 is **skipped** (saves context and evaluation effort)
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
│   └── mvp-test-cases.jsonl            # 8 test definitions
├── test-data/                          # Test fixtures (frozen snapshots + synthetic)
│   ├── snapshot-skill-evaluation/     # Clean pass baseline
│   ├── snapshot-cogworks-learn/       # Clean pass baseline (exit code 0)
│   ├── no-citations-skill/            # Should trigger citation failure
│   ├── bad-yaml-skill/                # Should trigger YAML failure
│   ├── no-skillmd-skill/             # Should trigger missing SKILL.md failure
│   ├── duplicate-headings-skill/     # Should trigger cross-file duplication warning
│   └── bad-name-skill/               # Should trigger name format warning
├── calibration/                       # Human evaluation templates for LLM-judge calibration
│   └── template-human.yaml           # Template for human scoring
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

1. Reads 8 test cases from `mvp-test-cases.jsonl`
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

[... 6 more tests ...]

╔════════════════════════════════════════════════════════════════╗
║                      TEST RESULTS SUMMARY                       ║
╚════════════════════════════════════════════════════════════════╝

Total Tests:  8
Passed:       8
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
  "id": "mvp-019",
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
  "rationale": "Tests new feature documented in deterministic-checks.sh"
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
  checks_passed: 14
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
# Result: 8/8 passed

# Make framework changes
vim .claude/test-framework/graders/deterministic-checks.sh

# Run tests after changes
bash tests/run-black-box-tests.sh
# Result: 7/8 passed (regression detected!)
```

**If tests fail**:

1. Check `tests/results/black-box-*/` for details
2. Determine if framework bug or test needs update
3. Fix framework if bug, update test if expectations changed

---

## Quick Reference

### Testing Skills (Normal Usage)

| Task                     | Command                                                                                     | Layer | Cost             |
| ------------------------ | ------------------------------------------------------------------------------------------- | ----- | ---------------- |
| Quick structural check   | `bash .claude/test-framework/graders/deterministic-checks.sh .claude/skills/{slug}/`        | L1    | Free             |
| Full quality evaluation  | `/cogworks-test {slug}`                                                                     | L1+L2 | Conversation ctx |
| JSON output (automation) | `/cogworks-test {slug} --json`                                                              | L1+L2 | Conversation ctx |
| Layer 1 only             | `/cogworks-test {slug} --layer1-only`                                                       | L1    | Free             |
| Layer 1 JSON output      | `bash .claude/test-framework/graders/deterministic-checks.sh .claude/skills/{slug}/ --json` | L1    | Free             |

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
| Layer 1 (deterministic checks) | ✅ Fully tested     | 14 checks, 8 meta-tests, 100% pass rate              |
| Layer 2 (LLM-judge)            | ✅ Implemented      | 5 dimensions scored via `/cogworks-test` skill        |
| Layer 3 (human review)         | ⚠️ Manual only      | Guide + calibration templates exist                   |
| Regression baselines           | ✅ 3 golden samples | skill-evaluation, cogworks-learn, advanced-prompting  |

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
# Should show: 9/9 passed (8 existing + 1 new)
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

### "Layer 2 scores seem too high"

**Cause**: LLM-as-judge leniency bias

**Solution**:

- The SKILL.md includes anti-leniency prompting ("Score 5 should be rare")
- If scores are consistently 4-5, the rubric anchors may need tightening
- Run calibration: fill in `tests/calibration/{slug}-human.yaml`, then compare with `python3 .claude/test-framework/scripts/calculate-agreement.py`

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
# Test a skill (Layer 1 + Layer 2)
/cogworks-test my-skill
/cogworks-test my-skill --json
/cogworks-test my-skill --sources _sources/my-skill/
/cogworks-test my-skill --layer1-only

# Test the framework
bash tests/run-black-box-tests.sh

# Quick checks (Layer 1 only, no skill invocation needed)
bash .claude/test-framework/graders/deterministic-checks.sh .claude/skills/my-skill/
bash .claude/test-framework/graders/deterministic-checks.sh .claude/skills/my-skill/ --json

# View results
ls -t tests/results/ | head -1
cat tests/results/black-box-*/summary.csv
cat tests/results/black-box-*/mvp-001-report.txt

# Calibration
python3 .claude/test-framework/scripts/calculate-agreement.py tests/calibration/ tests/results/
```

---

**Last Updated**: 2026-02-15
**Test Coverage**: 8 tests, 100% pass rate (Layer 1 only)
**Golden Samples**: 3 (skill-evaluation, cogworks-learn, advanced-prompting)
**Test inputs**: All tests use frozen snapshots in `tests/test-data/` — no production skill references
