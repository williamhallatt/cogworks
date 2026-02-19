# Efficacy Testing Quick Start

Get started with SkillsBench-based efficacy testing in 5 minutes.

## What is Efficacy Testing?

**Efficacy** measures whether a skill **actually improves task performance** versus baseline (no skill).

**Why it matters**: SkillsBench research proves curated skills (like cogworks generates) provide **+16.2pp improvement**, while self-generated skills provide **-1.3pp** (harmful!).

## Quick Commands

### 1. Run Behavioral Tests with Efficacy

```bash
python3 .claude/test-framework/scripts/cogworks-test-framework.py behavioral run \
  --skill-prefix cogworks- \
  --with-baseline
```

**What it does**:
- Runs existing behavioral tests
- Computes efficacy metrics if traces include `task_completed` field
- Shows efficacy delta and normalized gain
- Provides domain-contextualized assessment

### 2. Validate Skill Against Benchmark

```bash
python3 .claude/test-framework/scripts/cogworks-test-framework.py efficacy validate \
  --generated-skill .claude/skills/my-skill \
  --benchmark-task tests/datasets/efficacy-benchmark/task-001-api-synthesis
```

**What it does**:
- Loads benchmark metadata (domain, baseline rate, target)
- Loads pre-captured baseline traces
- Checks for skill traces
- Computes efficacy metrics
- Reports pass/fail against thresholds

### 3. Run All Benchmarks

```bash
python3 .claude/test-framework/scripts/cogworks-test-framework.py efficacy run \
  --generated-skill .claude/skills/my-skill \
  --benchmarks-root tests/datasets/efficacy-benchmark
```

**What it does**:
- Runs all 4 benchmark tasks
- Aggregates results
- Requires 70%+ to pass

## Available Benchmarks

| Task | Domain | What It Tests |
|------|--------|---------------|
| task-001 | software-engineering | Generate API skill, implement authentication |
| task-002 | devops-infrastructure | Generate K8s skill, diagnose crash loop |
| task-003 | devops-infrastructure | Generate deployment skill, safe production deploy |
| task-004 | software-engineering | Generate testing skill, comprehensive test suite |

## Example: Test a Generated Skill

### Step 1: Generate Skill from Benchmark

```bash
# Navigate to benchmark sources
cd tests/datasets/efficacy-benchmark/task-001-api-synthesis/sources/

# Use cogworks-encode to generate skill
# (In Claude Code with cogworks loaded)
# Read api-spec.md and generate skill
```

### Step 2: Run Benchmark Task

```bash
# Read instruction.md
cat tests/datasets/efficacy-benchmark/task-001-api-synthesis/instruction.md

# Run the task with the generated skill
# Record whether task completed successfully
```

### Step 3: Capture Skill Trace

```bash
# Create skill-traces directory
mkdir tests/datasets/efficacy-benchmark/task-001-api-synthesis/skill-traces

# Add trace
cat > tests/datasets/efficacy-benchmark/task-001-api-synthesis/skill-traces/run-001.json << 'EOF'
{
  "run_id": 1,
  "task_id": "task-001-api-synthesis",
  "skill_active": true,
  "task_completed": true,
  "quality_score": 0.92,
  "model": "claude-opus-4-6",
  "timestamp": "2026-02-19T16:00:00Z",
  "notes": "Skill activated and completed successfully"
}
EOF
```

Run 3-5 times to capture variance.

### Step 4: Run Validation

```bash
python3 .claude/test-framework/scripts/cogworks-test-framework.py efficacy validate \
  --generated-skill .claude/skills/my-generated-skill \
  --benchmark-task tests/datasets/efficacy-benchmark/task-001-api-synthesis
```

**Expected output**:
```
Validating skill against benchmark: task-001-api-synthesis
Domain: software-engineering
Baseline success rate: 22.0%
Target with skill: 85.0%

Baseline traces loaded: 3
With-skill traces loaded: 5

=== EFFICACY METRICS ===
Baseline Success Rate: 22.0%
With Skill Success Rate: 87.0%
Absolute Delta: +65.0%
Normalized Gain: 83.3%

Domain: software-engineering
Assessment: Exceptional efficacy for Software Engineering (above typical 4.5%)

Status: PASS
Skill exceeds efficacy thresholds for task-001-api-synthesis
```

## Understanding Metrics

### Absolute Delta
Direct improvement: `with_skill - baseline`

**Example**: 87% - 22% = +65pp

**Pass threshold**: >= 0.10 (10pp improvement)

### Normalized Gain
Proportional improvement toward perfect performance:

```
normalized_gain = delta / (1.0 - baseline)
```

**Example**: 65pp / (100% - 22%) = 65/78 = 83.3%

**Meaning**: Skill closes 83.3% of the gap to perfect performance

**Pass threshold**: >= 0.15 (15% proportional improvement)

### Domain Assessment

Efficacy expectations vary by domain:

| Domain | Typical Range |
|--------|--------------|
| Healthcare | +40-60pp |
| Manufacturing | +35-50pp |
| Data Analysis | +15-30pp |
| **Software Engineering** | **+5-15pp** |
| DevOps | +5-15pp |
| Mathematics | +5-12pp |

**Software engineering** has low procedural gap (agents already know patterns), so +65pp is **exceptional**.

## Test Case Format

Add efficacy fields to test cases:

```json
{
  "id": "deploy-001",
  "category": "explicit",
  "user_request": "Deploy application to staging",
  "should_activate": true,
  "expected_tools": ["Bash"],
  "baseline_success_rate": 0.30,
  "with_skill_target": 0.85,
  "domain": "devops-infrastructure",
  "notes": "Deployment workflow"
}
```

## Trace Format

### Baseline Trace (no skill)
```json
{
  "skill_slug": "deployment-skill",
  "case_id": "deploy-001",
  "activated": false,
  "baseline_run": true,
  "task_completed": false,
  "tools_used": ["Bash"],
  "notes": "Baseline - agent failed to complete"
}
```

### Skill Trace (with skill)
```json
{
  "skill_slug": "deployment-skill",
  "case_id": "deploy-001",
  "activated": true,
  "baseline_run": false,
  "task_completed": true,
  "quality_score": 0.92,
  "tools_used": ["Bash"],
  "notes": "Skill activated and completed successfully"
}
```

## Pass Criteria

### Activation (existing)
- Activation F1 >= 0.85
- False Positive Rate <= 0.05
- Negative Control Ratio >= 0.25

### Efficacy (new)
- Efficacy Delta >= 0.10
- Normalized Gain >= 0.15

Both must pass for overall PASS.

## Common Questions

### Q: Why is my efficacy delta low?

**A**: Check domain expectations. Software engineering typically shows +5-15pp (low procedural gap). If you're getting +8pp, that's actually good for the domain.

### Q: Do I need to capture baseline traces every time?

**A**: No. Baseline traces are pre-captured once and reused. Only skill traces need to be captured for each new skill.

### Q: How many traces do I need?

**A**: Minimum 3 per condition (baseline and skill), ideally 5+ to account for variance.

### Q: What if my skill shows negative efficacy?

**A**: This means the skill is harmful (overloading context or providing incorrect patterns). Review the skill content - it may be too comprehensive. SkillsBench shows comprehensive skills hurt performance (-2.9pp).

### Q: Can I test with real users?

**A**: Yes, but for cogworks validation, we use simulated agent runs. Real user testing would be A/B testing in production.

## Documentation

- **Full Guide**: `.claude/test-framework/docs/efficacy-measurement-guide.md`
- **Domain Taxonomy**: `.claude/test-framework/docs/domain-taxonomy.md`
- **Integration Docs**: `.claude/test-framework/docs/skillsbench-integration.md`
- **Testing Guide**: `TESTING.md`

## Help

```bash
# See all options
python3 .claude/test-framework/scripts/cogworks-test-framework.py efficacy --help

# Validate command help
python3 .claude/test-framework/scripts/cogworks-test-framework.py efficacy validate --help

# Run command help
python3 .claude/test-framework/scripts/cogworks-test-framework.py efficacy run --help
```

## Next Steps

1. ✅ Read this quickstart
2. Run `efficacy validate` with a benchmark task
3. Capture skill traces for your generated skills
4. Run full validation
5. Add efficacy results to skill documentation

---

Quick start guide | Last updated: 2026-02-19
