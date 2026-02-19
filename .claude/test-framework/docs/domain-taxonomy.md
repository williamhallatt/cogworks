# Domain Taxonomy and Expected Efficacy Ranges

This document defines domain categories for cogworks skills and expected efficacy ranges based on SkillsBench research findings.

## Domain Definitions

### Healthcare
**Key**: `healthcare`
**Expected Efficacy**: +40-60pp (0.40-0.60)
**Typical**: +51.9pp

**Characteristics**:
- High procedural gap (significant difference between knowing and executing)
- Complex multi-step workflows
- Critical decision points requiring domain expertise
- Examples: Medical diagnostics, treatment protocols, clinical documentation

### Manufacturing
**Key**: `manufacturing`
**Expected Efficacy**: +35-50pp (0.35-0.50)

**Characteristics**:
- Process-heavy workflows
- Quality control procedures
- Equipment operation protocols
- Examples: Assembly processes, quality assurance, production planning

### Data Analysis
**Key**: `data-analysis`
**Expected Efficacy**: +15-30pp (0.15-0.30)

**Characteristics**:
- Statistical reasoning
- Data transformation workflows
- Interpretation of results
- Examples: Exploratory data analysis, statistical testing, data visualization

### Software Engineering
**Key**: `software-engineering`
**Expected Efficacy**: +5-15pp (0.05-0.15)
**Typical**: +4.5pp

**Characteristics**:
- Low procedural gap (agents already know most patterns)
- Code generation and refactoring
- Debugging and testing
- Examples: API implementation, bug fixes, test writing

### DevOps/Infrastructure
**Key**: `devops-infrastructure`
**Expected Efficacy**: +5-15pp (0.05-0.15)

**Characteristics**:
- Configuration and deployment
- Infrastructure as code
- Monitoring and troubleshooting
- Examples: CI/CD pipelines, Kubernetes operations, cloud deployments

### Mathematics
**Key**: `mathematics`
**Expected Efficacy**: +5-12pp (0.05-0.12)

**Characteristics**:
- Formal reasoning
- Proof techniques
- Problem-solving strategies
- Examples: Mathematical proofs, optimization problems, algorithm analysis

## Usage Guidelines

### When Creating Test Cases

Add domain field to test cases:

```json
{
  "id": "case-001",
  "category": "explicit",
  "user_request": "Deploy the application to staging",
  "should_activate": true,
  "baseline_success_rate": 0.30,
  "with_skill_target": 0.85,
  "domain": "devops-infrastructure",
  "notes": "Deployment workflow"
}
```

### When Interpreting Results

The framework will automatically contextualize efficacy results:

- **Healthcare skill with +45pp**: "Good efficacy for Healthcare (within typical 40-60%)"
- **Software Engineering skill with +12pp**: "Exceptional efficacy for Software Engineering (above typical 4.5%)"
- **Data Analysis skill with +8pp**: "Below expected for Data Analysis (typical 15-30%)"

### Cross-Domain Skills

If a skill spans multiple domains, either:

1. Use the primary domain (most relevant)
2. Use `mixed` as domain key
3. Create separate test cases for each domain aspect

## SkillsBench Research Context

These ranges are based on the SkillsBench benchmark (2025), which evaluated agent skills across 84 tasks in 6 domains.

**Key findings**:

- **Curated skills** (like cogworks produces): +16.2pp average improvement
- **Self-generated skills**: -1.3pp (negligible/negative)
- **Focused skills** (2-3 modules): +18.6pp
- **Comprehensive skills**: -2.9pp (actually hurt performance)

**Domain variance**:
- Healthcare showed the highest gain (+51.9pp) - high procedural gap
- Software Engineering showed the lowest gain (+4.5pp) - low procedural gap

**Interpretation**: Domains with high procedural gaps (difference between knowing what to do and actually executing it) benefit more from curated skills.

## References

- SkillsBench paper: `_sources/skillsbench/skillsbench-assessment.md`
- Harbor framework: https://github.com/laude-institute/harbor
- Original research: Laude Institute (2025)

---

Last updated: 2026-02-19
