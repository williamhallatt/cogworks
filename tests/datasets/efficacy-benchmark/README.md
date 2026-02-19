# Efficacy Benchmark Dataset

This dataset validates that the cogworks pipeline consistently produces effective skills.

## Purpose

**Layer 2.5** (behavioral tests) validates skill activation correctness.
**Efficacy benchmarks** validate that generated skills actually improve task performance.

## Structure

Each benchmark task follows this layout:

```
efficacy-benchmark/
  task-{id}-{name}/
    instruction.md          # Task description for agent
    sources/                # Input materials for skill generation
      *.md, *.txt, URLs
    baseline-traces/        # Pre-captured baseline runs (no skill)
      run-{N}.json
    verify.py              # Success criteria checker (optional)
    metadata.json          # Task metadata
```

## Example Task Structure

### task-001-api-synthesis/

**Objective**: Generate a skill from API documentation, then use it to implement an endpoint.

**Files**:
- `instruction.md`: "Implement a REST API endpoint for user authentication"
- `sources/`: API documentation files
- `baseline-traces/`: Traces of agent attempting task without skill (captured once)
- `verify.py`: Checks if implementation matches spec
- `metadata.json`: Domain, expected baseline success rate, target with-skill rate

## Validation Workflow

### 1. Generate Skill from Sources

```bash
# In cogworks agent
cogworks encode \
  --sources tests/datasets/efficacy-benchmark/task-001-api-synthesis/sources/ \
  --output .claude/skills/test-generated-skill
```

### 2. Run Benchmark Task with Generated Skill

```bash
# Execute instruction.md with skill active
# Capture trace with task_completed field
```

### 3. Compare Against Baseline

```bash
python3 .claude/test-framework/scripts/cogworks-test-framework.py efficacy validate \
  --generated-skill .claude/skills/test-generated-skill \
  --benchmark-task tests/datasets/efficacy-benchmark/task-001-api-synthesis/
```

### 4. Report Efficacy Delta

```
Task: task-001-api-synthesis
Baseline Success: 22% (from pre-captured traces)
With Generated Skill: 87%
Efficacy Delta: +65pp
Status: PASS (exceeds +10pp threshold)
```

## Baseline Trace Capture

Baseline traces are **pre-captured** (one-time cost) to avoid re-running expensive baseline measurements.

### Capture Process

1. Run task without skill 5-10 times
2. Record `task_completed: true/false` for each run
3. Save traces to `baseline-traces/run-{N}.json`
4. Compute baseline success rate
5. Store in `metadata.json`

### Baseline Trace Format

```json
{
  "run_id": 1,
  "task_id": "task-001-api-synthesis",
  "skill_active": false,
  "task_completed": false,
  "execution_time_sec": 47.3,
  "model": "claude-opus-4-6",
  "timestamp": "2026-02-19T12:00:00Z",
  "notes": "Agent attempted but missing authentication logic"
}
```

## Metadata Format

Each task includes `metadata.json`:

```json
{
  "task_id": "task-001-api-synthesis",
  "domain": "software-engineering",
  "description": "Generate API skill and implement authentication endpoint",
  "baseline_success_rate": 0.22,
  "target_with_skill_rate": 0.85,
  "baseline_runs": 10,
  "difficulty": "medium",
  "estimated_time_min": 5
}
```

## Adding New Benchmark Tasks

### 1. Choose Task

Select tasks that:
- Represent core cogworks use cases
- Have clear success/failure criteria
- Show significant baseline gap (20-50% success)
- Are deterministically verifiable

### 2. Create Directory

```bash
mkdir -p tests/datasets/efficacy-benchmark/task-{id}-{name}/{sources,baseline-traces}
```

### 3. Add Materials

- `instruction.md`: Clear task description
- `sources/`: Materials for skill generation
- `verify.py`: Optional automated checker

### 4. Capture Baseline

Run task 5-10 times without skill, record traces.

### 5. Add Metadata

Create `metadata.json` with domain, baseline rate, target rate.

## Benchmark Task Ideas

### Implemented
- ✅ `task-001-api-synthesis`: Generate API skill, implement endpoint

### Planned
- ⏳ `task-002-troubleshooting`: Generate Kubernetes troubleshooting skill, debug cluster issue
- ⏳ `task-003-deployment`: Generate deployment skill, ship to staging
- ⏳ `task-004-testing`: Generate testing skill, write comprehensive test suite
- ⏳ `task-005-refactoring`: Generate refactoring skill, modernize legacy code

## CI Integration

Efficacy benchmarks can be added to CI pipeline:

```yaml
- name: Efficacy Validation
  run: |
    # Generate test skill from benchmark sources
    # Run benchmark tasks with generated skill
    # Compare to baseline (pre-captured)
    # Fail if delta < threshold
```

## References

- Efficacy measurement guide: `.claude/test-framework/docs/efficacy-measurement-guide.md`
- Domain taxonomy: `.claude/test-framework/docs/domain-taxonomy.md`
- SkillsBench methodology: `_sources/skillsbench/skillsbench-assessment.md`

## Example Skills

The `example-skills/` directory contains 4 successfully generated skills from the February 2026 validation:

- **api-authentication-benchmark/** - REST API authentication patterns with JWT tokens
- **k8s-troubleshooting-benchmark/** - Kubernetes pod failure diagnostic workflows
- **deployment-workflow-benchmark/** - Safe production deployment with staging verification
- **testing-patterns-benchmark/** - Comprehensive test suite patterns with AAA structure

These skills demonstrate:
- What cogworks produces from source materials
- Efficacy validation results (all 4 skills passed with 100% task success rates)
- SKILL.md format and structure
- Domain-specific knowledge synthesis

**Note**: These are test artifacts demonstrating the framework's output, not production skills for general use. They serve as reference examples for evaluating cogworks efficacy.

---

Last updated: 2026-02-19
