# SkillsBench Methodology Integration

This document describes the integration of SkillsBench research findings into the cogworks testing framework.

## Overview

**SkillsBench** (2025, Laude Institute) is a benchmark framework that validates a critical finding: **curated skills provide +16.2pp average improvement while self-generated skills provide -1.3pp**. This validates cogworks' entire approach of synthesizing skills from authoritative sources rather than pure LLM generation.

The cogworks testing framework now incorporates SkillsBench methodology through:

1. **Efficacy measurement** - Validates that skills improve task performance vs. baseline
2. **Domain-specific expectations** - Contextualizes results by domain
3. **Paired evaluation** - Compares with-skill vs. without-skill performance
4. **Benchmark dataset** - Pipeline-level validation tasks

## Implementation Status

### ✅ Phase 1: Foundation (COMPLETED)

**Goal**: Add efficacy measurement to behavioral tests

**Completed Components**:

1. **Extended test case format** (`.claude/test-framework/templates/behavioral-test-case-template.jsonl`):
   - Added `baseline_success_rate`: Expected success without skill
   - Added `with_skill_target`: Target success with skill
   - Added `domain`: Task domain classification

2. **Extended trace format** (`.claude/test-framework/templates/behavioral-trace-template.json`):
   - Added `task_completed`: Boolean success indicator
   - Added `quality_score`: Optional quality metric
   - Added `baseline_run`: Distinguishes baseline from skill runs

3. **Efficacy calculation** (`behavioral_lib.py`):
   - `compute_efficacy_delta()`: Absolute improvement
   - `compute_normalized_gain()`: Proportional improvement
   - `compute_efficacy_metrics()`: Full efficacy analysis

4. **Enhanced test framework** (`cogworks-test-framework.py`):
   - `--with-baseline` flag: Enables efficacy calculation
   - `--efficacy-delta-min`: Configurable threshold (default: 0.10)
   - `--normalized-gain-min`: Configurable threshold (default: 0.15)
   - Domain-contextualized assessment
   - Enhanced reporting with efficacy metrics

5. **Documentation**:
   - Updated `TESTING.md` with efficacy workflow
   - Created `efficacy-measurement-guide.md`
   - Created `domain-taxonomy.md`
   - Created `skillsbench-integration.md` (this document)

### ⏳ Phase 2: Pipeline Validation (STARTED)

**Goal**: Validate that cogworks pipeline produces effective skills

**Completed Components**:

1. **Efficacy benchmark structure** (`tests/datasets/efficacy-benchmark/`):
   - Created directory structure
   - Added README with workflow documentation
   - Created example task: `task-001-api-synthesis`
   - Includes instruction, sources, metadata, verification script
   - Added sample baseline traces

**Remaining Work**:

1. Add efficacy validation command to `cogworks-test-framework.py`:
   ```bash
   python3 .claude/test-framework/scripts/cogworks-test-framework.py efficacy validate \
     --generated-skill .claude/skills/my-skill \
     --benchmark-tasks tests/datasets/efficacy-benchmark/
   ```

2. Implement validation logic:
   - Generate skill from benchmark sources
   - Run benchmark task with generated skill
   - Compare against pre-captured baseline traces
   - Report efficacy delta

3. Add to CI pipeline (`.github/workflows/pre-release-validation.yml`)

4. Create 4-5 additional benchmark tasks covering:
   - Kubernetes troubleshooting
   - Deployment workflows
   - Testing patterns
   - Refactoring operations

### ⏸️ Phase 3: Advanced Features (OPTIONAL)

**Goal**: SkillsBench task integration and research validation

**Planned Components**:

1. **SkillsBench task integration**:
   - Clone Harbor framework
   - Select 10-15 relevant tasks
   - Create Harbor wrapper
   - Use for golden sample promotion

2. **Self-generated comparison**:
   - Research mode comparing cogworks vs. self-generated
   - Validates curated approach empirically

**Priority**: Low (research/academic validation)

## Usage Guide

### Test Cases with Efficacy Fields

```json
{
  "id": "deploy-001",
  "category": "explicit",
  "user_request": "Deploy application to staging",
  "should_activate": true,
  "baseline_success_rate": 0.30,
  "with_skill_target": 0.85,
  "domain": "devops-infrastructure",
  "expected_tools": ["Bash"],
  "notes": "Deployment workflow"
}
```

### Traces with Outcome Fields

**Baseline trace** (no skill):
```json
{
  "skill_slug": "deployment-skill",
  "case_id": "deploy-001",
  "activated": false,
  "baseline_run": true,
  "task_completed": false,
  "tools_used": ["Bash"],
  "notes": "Agent attempted but failed"
}
```

**With-skill trace**:
```json
{
  "skill_slug": "deployment-skill",
  "case_id": "deploy-001",
  "activated": true,
  "baseline_run": false,
  "task_completed": true,
  "quality_score": 0.92,
  "tools_used": ["Bash"],
  "commands": [
    {"cmd": "git push origin staging", "exit_code": 0}
  ],
  "notes": "Skill activated and completed successfully"
}
```

### Running Efficacy Tests

```bash
# Run behavioral tests with efficacy measurement
python3 .claude/test-framework/scripts/cogworks-test-framework.py behavioral run \
  --skill-prefix cogworks- \
  --with-baseline \
  --efficacy-delta-min 0.10 \
  --normalized-gain-min 0.15
```

### Interpreting Results

```
Skill: deployment-skill
Status: PASS

## Activation Metrics
- Activation F1: 0.95
- False Positive Rate: 0.02
- Negative Control Ratio: 0.30

## Efficacy Metrics
- Baseline Success Rate: 30.0% (without skill)
- With Skill Success Rate: 85.0% (with skill)
- Absolute Delta: +55.0pp
- Normalized Gain: 78.6%
- Baseline Runs: 5
- Skill Runs: 5

## Domain Context
- Domain: devops-infrastructure
- Assessment: Exceptional efficacy for DevOps/Infrastructure (above typical 5-15%)
```

## Key Metrics

### Activation Metrics (Layer 2.5 - existing)

- **Activation F1**: Precision and recall of skill activation
- **False Positive Rate**: Skill fires when it shouldn't
- **Negative Control Ratio**: Percentage of test cases where skill should NOT fire

**Thresholds**: F1 >= 0.85, FPR <= 0.05, NCR >= 0.25

### Efficacy Metrics (Layer 2.5 - new)

- **Baseline Success Rate**: Task completion without skill
- **With Skill Success Rate**: Task completion with skill
- **Absolute Delta**: Direct improvement (with_skill - baseline)
- **Normalized Gain**: Proportional improvement toward perfection

**Thresholds**: Delta >= 0.10 (10pp), Gain >= 0.15 (15%)

### Domain Context

| Domain | Expected Range | Explanation |
|--------|---------------|-------------|
| Healthcare | +40-60pp | High procedural gap |
| Manufacturing | +35-50pp | Process-heavy workflows |
| Data Analysis | +15-30pp | Statistical reasoning |
| Software Engineering | +5-15pp | Low procedural gap |
| DevOps/Infrastructure | +5-15pp | Configuration/deployment |
| Mathematics | +5-12pp | Formal reasoning |

## SkillsBench Research Context

### Key Findings

1. **Curated skills beat self-generated**: +16.2pp vs. -1.3pp
   - Validates cogworks' source-driven synthesis approach

2. **Focused skills beat comprehensive**: +18.6pp vs. -2.9pp
   - Skills covering 2-3 modules optimal
   - Comprehensive skills overload context

3. **Domain variance is massive**: +51.9pp (Healthcare) vs. +4.5pp (Software)
   - High procedural gap domains benefit most
   - Software engineering has low gap (agents already know patterns)

4. **Quality matters**: Curated skills from experts show consistent gains
   - Self-generated skills often harmful or ineffective

### Implications for Cogworks

1. **Validate synthesis approach**: Efficacy measurement proves value of source-driven skills
2. **Focus over breadth**: Favor narrow, deep skills over comprehensive coverage
3. **Domain-aware testing**: Different expectations by domain
4. **Quality gates**: Efficacy thresholds prevent publishing ineffective skills

## Testing Layers

### Layer 1: Structural (Deterministic)
- SKILL.md format validation
- Frontmatter completeness
- File structure checks
**Tool**: `deterministic-checks.sh`

### Layer 2: Quality (LLM-as-Judge)
- Source fidelity, self-sufficiency, completeness, specificity, no overlap
- Weighted scoring (>=0.85), no dimension <3
**Tool**: `/cogworks-test` skill

### Layer 2.5: Behavioral (Activation + Efficacy)
- **Activation**: Does skill fire correctly? (F1, FPR, NCR)
- **Efficacy**: Does skill improve performance? (Delta, Gain) [NEW]
**Tool**: `behavioral run --with-baseline`

### Layer 3: Calibration (Human Review)
- Human grades vs. LLM grades alignment
- Ensures LLM judge reliability
**Tool**: `calibration run`

## Files Modified

### Core Framework
- `.claude/test-framework/scripts/behavioral_lib.py`
  - Added efficacy calculation functions
- `.claude/test-framework/scripts/cogworks-test-framework.py`
  - Added `--with-baseline` support
  - Added domain assessment
  - Enhanced reporting
- `.claude/test-framework/templates/behavioral-test-case-template.jsonl`
  - Added efficacy fields
- `.claude/test-framework/templates/behavioral-trace-template.json`
  - Added outcome fields

### Documentation
- `TESTING.md`
  - Added efficacy measurement section
- `.claude/test-framework/docs/efficacy-measurement-guide.md` [NEW]
- `.claude/test-framework/docs/domain-taxonomy.md` [NEW]
- `.claude/test-framework/docs/skillsbench-integration.md` [NEW] (this file)

### Benchmark Dataset
- `tests/datasets/efficacy-benchmark/` [NEW]
  - README.md
  - task-001-api-synthesis/
    - instruction.md
    - sources/api-spec.md
    - metadata.json
    - verify.py
    - baseline-traces/ (3 samples)

## Next Steps

### Immediate (Complete Phase 2)

1. Implement `efficacy validate` command in `cogworks-test-framework.py`
2. Add pipeline efficacy validation to CI
3. Create 2-3 more benchmark tasks

### Short-term (Production Ready)

1. Run efficacy tests on existing `cogworks-*` skills
2. Add efficacy pass criteria to release checklist
3. Document efficacy results in skill README files

### Long-term (Optional)

1. Integrate Harbor framework for SkillsBench task validation
2. Use for golden sample promotion criteria
3. Publish cogworks efficacy benchmarks as research validation

## References

- **SkillsBench Paper**: `_sources/skillsbench/skillsbench-assessment.md`
- **Harbor Framework**: https://github.com/laude-institute/harbor
- **Efficacy Guide**: `.claude/test-framework/docs/efficacy-measurement-guide.md`
- **Domain Taxonomy**: `.claude/test-framework/docs/domain-taxonomy.md`
- **Original Plan**: See project plan document

---

Last updated: 2026-02-19
