# Efficacy Testing Quick Reference

## Commands

### Run with efficacy measurement
```bash
python3 .claude/test-framework/scripts/cogworks-test-framework.py behavioral run \
  --skill-prefix cogworks- \
  --with-baseline \
  --efficacy-delta-min 0.10 \
  --normalized-gain-min 0.15
```

### Scaffold test cases (with efficacy fields)
```bash
python3 .claude/test-framework/scripts/cogworks-test-framework.py behavioral scaffold \
  --skill my-skill
```

## Test Case Format

```json
{
  "id": "case-001",
  "category": "explicit",
  "user_request": "Deploy to staging",
  "should_activate": true,
  "baseline_success_rate": 0.30,
  "with_skill_target": 0.85,
  "domain": "devops-infrastructure",
  "expected_tools": ["Bash"],
  "notes": "Deployment workflow"
}
```

## Trace Format

**Baseline** (no skill):
```json
{
  "skill_slug": "my-skill",
  "case_id": "case-001",
  "activated": false,
  "baseline_run": true,
  "task_completed": false
}
```

**With skill**:
```json
{
  "skill_slug": "my-skill",
  "case_id": "case-001",
  "activated": true,
  "baseline_run": false,
  "task_completed": true,
  "quality_score": 0.92
}
```

## Pass Criteria

### Activation (existing)
- Activation F1 >= 0.85
- False Positive Rate <= 0.05
- Negative Control Ratio >= 0.25

### Efficacy (new)
- Efficacy Delta >= 0.10 (10pp improvement)
- Normalized Gain >= 0.15 (15% proportional improvement)

## Metrics Explained

| Metric | Formula | Meaning |
|--------|---------|---------|
| Baseline Success | completed/total | Success rate without skill |
| With Skill Success | completed/total | Success rate with skill |
| Absolute Delta | with_skill - baseline | Direct improvement |
| Normalized Gain | delta / (1 - baseline) | % of gap closed |

**Example**: Baseline 30%, With Skill 85%
- Delta: +55pp
- Gain: 55 / (1 - 0.30) = 78.6%

## Domain Expected Ranges

| Domain | Range | Typical |
|--------|-------|---------|
| Healthcare | +40-60pp | +51.9pp |
| Manufacturing | +35-50pp | - |
| Data Analysis | +15-30pp | - |
| Software Engineering | +5-15pp | +4.5pp |
| DevOps | +5-15pp | - |
| Mathematics | +5-12pp | - |

## Workflow

1. **Create test cases** with efficacy fields
2. **Capture baseline traces** (5+ runs, `baseline_run: true`)
3. **Capture skill traces** (5+ runs, `baseline_run: false`)
4. **Run tests**: `behavioral run --with-baseline`
5. **Check results**: Look for efficacy delta and normalized gain

## Common Issues

### High variance
**Solution**: More runs (5-10), deterministic checks

### Baseline too high (>80%)
**Solution**: Choose harder tasks, rely on normalized gain

### Negative efficacy
**Solution**: Skill may be too comprehensive, review content

## Files to Reference

- Full guide: `.claude/test-framework/docs/efficacy-measurement-guide.md`
- Domain taxonomy: `.claude/test-framework/docs/domain-taxonomy.md`
- Integration docs: `.claude/test-framework/docs/skillsbench-integration.md`
- Testing guide: `TESTING.md`

## SkillsBench Context

- Curated skills: **+16.2pp** average
- Self-generated: **-1.3pp** (harmful!)
- Focused (2-3 modules): **+18.6pp**
- Comprehensive: **-2.9pp** (harmful!)

**Takeaway**: Cogworks' source-driven approach is validated by research.

---

Quick reference | Last updated: 2026-02-19
