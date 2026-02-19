# Efficacy Measurement Guide

This guide explains how to measure skill efficacy using the SkillsBench methodology integrated into cogworks testing.

## What is Efficacy?

**Efficacy** measures whether a skill actually improves task performance compared to baseline (no skill).

**Activation** (Layer 2.5) tests whether the skill fires correctly.
**Efficacy** tests whether the skill helps complete tasks successfully.

## Key Concepts

### Baseline Success Rate

Task completion rate **without** the skill. Measured by running the same test cases without activating the skill.

Example: Agent completes deployment task 30% of the time without deployment skill.

### With-Skill Success Rate

Task completion rate **with** the skill active.

Example: Agent completes deployment task 85% of the time with deployment skill.

### Absolute Delta

Direct improvement: `with_skill_success - baseline_success`

Example: 0.85 - 0.30 = 0.55 (55 percentage points improvement)

### Normalized Gain

Proportional improvement toward perfect performance:

```
normalized_gain = (with_skill - baseline) / (1.0 - baseline)
```

Example: (0.85 - 0.30) / (1.0 - 0.30) = 0.55 / 0.70 = 0.786 (78.6% of remaining gap closed)

**Why normalized gain matters**: A skill that improves success from 20% to 60% (+40pp) is closing 50% of the gap, while a skill that improves from 80% to 100% (+20pp) is closing 100% of the gap. Normalized gain accounts for this.

## Test Case Setup

### 1. Define Efficacy Fields

Add to test case JSON:

```json
{
  "id": "deploy-001",
  "category": "explicit",
  "user_request": "Deploy the application to staging environment",
  "should_activate": true,
  "baseline_success_rate": 0.30,
  "with_skill_target": 0.85,
  "domain": "devops-infrastructure",
  "expected_tools": ["Bash"],
  "notes": "Complex deployment workflow"
}
```

**Fields**:
- `baseline_success_rate`: Expected success without skill (0.0-1.0)
- `with_skill_target`: Target success with skill (0.0-1.0)
- `domain`: Task domain (see domain-taxonomy.md)

### 2. Capture Baseline Traces

Run test case **without** activating the skill:

```json
{
  "skill_slug": "deployment-skill",
  "case_id": "deploy-001",
  "activated": false,
  "task_completed": false,
  "baseline_run": true,
  "tools_used": ["Bash"],
  "commands": [],
  "notes": "Baseline run - agent attempted but failed to complete deployment"
}
```

**Key fields**:
- `activated`: `false` (skill did not fire)
- `baseline_run`: `true` (this is a baseline measurement)
- `task_completed`: `true/false` (did agent complete the task successfully?)

### 3. Capture With-Skill Traces

Run test case **with** skill activated:

```json
{
  "skill_slug": "deployment-skill",
  "case_id": "deploy-001",
  "activated": true,
  "task_completed": true,
  "quality_score": 0.92,
  "baseline_run": false,
  "tools_used": ["Bash"],
  "commands": [
    {"cmd": "git status", "exit_code": 0},
    {"cmd": "git push origin staging", "exit_code": 0}
  ],
  "notes": "Skill activated and successfully completed deployment"
}
```

**Key fields**:
- `activated`: `true` (skill fired)
- `baseline_run`: `false` (this is a with-skill measurement)
- `task_completed`: `true/false` (did agent complete the task?)
- `quality_score`: Optional 0.0-1.0 quality rating

### 4. Multiple Runs Recommended

For reliable efficacy measurement:

- **3-5 baseline runs** per test case
- **3-5 with-skill runs** per test case

This accounts for variance in agent behavior.

## Running Efficacy Tests

### Command

```bash
python3 .claude/test-framework/scripts/cogworks-test-framework.py behavioral run \
  --skill-prefix my-skill- \
  --with-baseline \
  --efficacy-delta-min 0.10 \
  --normalized-gain-min 0.15
```

### Flags

- `--with-baseline`: Enable efficacy calculation
- `--efficacy-delta-min`: Minimum absolute delta threshold (default: 0.10 = 10pp)
- `--normalized-gain-min`: Minimum normalized gain threshold (default: 0.15 = 15%)

### Pass Criteria

Skill must satisfy **all** of:

1. **Activation criteria** (Layer 2.5):
   - `activation_f1 >= 0.85`
   - `false_positive_rate <= 0.05`
   - `negative_control_ratio >= 0.25`

2. **Efficacy criteria** (new):
   - `efficacy_delta >= 0.10` (10pp improvement minimum)
   - `normalized_gain >= 0.15` (15% proportional improvement minimum)

## Interpreting Results

### Example Report

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

### Domain-Contextualized Assessment

The framework compares efficacy to domain-specific expectations:

| Domain | Typical Range | Your Result | Assessment |
|--------|--------------|-------------|------------|
| Healthcare | +40-60pp | +45pp | Good |
| Manufacturing | +35-50pp | +20pp | Below expected |
| Data Analysis | +15-30pp | +28pp | Good |
| Software Engineering | +5-15pp | +12pp | Exceptional |
| DevOps/Infrastructure | +5-15pp | +18pp | Exceptional |
| Mathematics | +5-12pp | +8pp | Good |

## Best Practices

### 1. Use Deterministic Verification When Possible

Instead of manual judgment, use automated checks:

```python
# In trace capture
task_completed = (exit_code == 0 and "deployed successfully" in output)
```

### 2. Multiple Iterations

Run each test case 3-5 times to account for variance:

```bash
# Capture 3 baseline traces
deploy-001-baseline-1.json
deploy-001-baseline-2.json
deploy-001-baseline-3.json

# Capture 3 with-skill traces
deploy-001-skill-1.json
deploy-001-skill-2.json
deploy-001-skill-3.json
```

### 3. Focus on High-Value Tasks

Efficacy testing is more expensive (2x traces). Focus on:

- Tasks where baseline performance is poor (30-50% success)
- Tasks representative of skill's core value proposition
- Golden sample promotion candidates

### 4. Domain Selection

Choose the most relevant domain. If uncertain:

- Deployment → `devops-infrastructure`
- API implementation → `software-engineering`
- Data pipeline → `data-analysis`
- Diagnostic workflow → `healthcare`

## Troubleshooting

### Issue: High efficacy variance across runs

**Cause**: Nondeterministic agent behavior, environment variance

**Solution**:
- Increase iterations (5-10 runs)
- Use deterministic evaluation where possible
- Focus on large deltas (>10pp) where signal exceeds noise

### Issue: Baseline success already high (>80%)

**Cause**: Task is too easy for baseline agent

**Solution**:
- Choose harder test cases (lower baseline success)
- Normalized gain will handle this better than absolute delta

### Issue: Skill shows negative efficacy

**Cause**: Skill may be harmful or too comprehensive

**Solution**:
- Review skill content (is it overloading context?)
- Check SkillsBench finding: comprehensive skills hurt performance (-2.9pp)
- Consider focusing skill on 2-3 key modules instead

## References

- SkillsBench methodology: `_sources/skillsbench/skillsbench-assessment.md`
- Domain taxonomy: `.claude/test-framework/docs/domain-taxonomy.md`
- Behavioral test templates: `.claude/test-framework/templates/`

---

Last updated: 2026-02-19
