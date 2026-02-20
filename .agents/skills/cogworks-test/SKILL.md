---
name: cogworks-test
description: Validates generated cogworks skills through structural checks and semantic quality evaluation. Tests structure, citations, source fidelity, completeness, and specificity. Use when validating generated skills, checking quality after generation, or running regression tests.
---

# Cogworks Skill Validator

**Codex note**: Layer 1 deterministic checks are fully supported and are the default Codex workflow. Layer 2, behavioral, and calibration gates are optional advanced checks.

**Scope**: This skill validates generated skills only. Framework meta-tests live under `tests/` and are run separately (see `TESTING.md`).

Layered validation: deterministic checks (Layer 1), semantic quality evaluation (Layer 2), plus behavioral and calibration gates.

## Invocation

```
/cogworks-test {slug} [--sources {path}] [--skill-path {path}] [--json] [--layer1-only]
```

- `{slug}` — skill directory name (resolved from `.agents/skills/{slug}/`, `~/.agents/skills/{slug}/`, or `tests/test-data/{slug}/` unless `--skill-path` is provided)
- `--sources {path}` — path to source material directory (defaults to `_sources/{slug}/`)
- `--skill-path {path}` — explicit path to the skill directory (overrides slug resolution)
- `--json` — output results as JSON
- `--layer1-only` — skip Layer 2 semantic evaluation

## Workflow

### Step 1: Resolve Skill Path

Look for the skill directory in this order:
1. `--skill-path {path}` (if provided)
2. `.agents/skills/{slug}/`
3. `~/.agents/skills/{slug}/`
4. `tests/test-data/{slug}/`

If not found, report error and stop.

### Step 2: Run Layer 1 Deterministic Checks

```bash
bash .claude/test-framework/graders/deterministic-checks.sh {skill_path} --json
```

Parse the JSON output. If any critical failures exist, report them and STOP — do not proceed to Layer 2.

### Step 3: Check for Layer 1-Only Mode

If `--layer1-only` was specified, report Layer 1 results and stop.

### Step 4: Load Skill Content

Read all skill files:
- `{skill_path}/SKILL.md` (required)
- `{skill_path}/reference.md` (if exists)
- `{skill_path}/patterns.md` (if exists)
- `{skill_path}/examples.md` (if exists)

### Step 5: Load Source Material

Resolve source material path:
1. Use `--sources {path}` if provided
2. Otherwise try `_sources/{slug}/`
3. If no sources found, warn and evaluate without source comparison (source fidelity score capped at 3)

Read all files in the sources directory.

### Step 6: Evaluate 5 Quality Dimensions

Evaluate each dimension independently following the rubrics below. For each dimension, produce a score (1-5), evidence, and reasoning.

**Anti-leniency requirement**: Score 5 should be rare. Most good skills score 3-4. If uncertain between two scores, choose the lower one. After scoring all dimensions, review scores as a set — a skill cannot credibly score 5 on source fidelity but 2 on self-sufficiency.

#### Dimension 1: Source Fidelity (Weight: 0.30)

Accuracy and traceability of claims to source material.

Evaluation steps:
1. Sample 10 specific claims or patterns from the skill
2. Trace each back to source material using citations
3. Note claims without clear source attribution
4. Check if source contradictions are explicitly flagged
5. Calculate traceability percentage

| Score | Criteria |
|-------|----------|
| 5 | Every claim cited, contradictions flagged, no fabrication, consistent format |
| 4 | 95%+ traceable, contradictions noted, minor omissions |
| 3 | 85%+ traceable, most contradictions noted, some synthesis gaps |
| 2 | <85% traceable, contradictions missed, noticeable fabrication |
| 1 | Significant fabrication, missing citations, contradictions ignored |

#### Dimension 2: Self-Sufficiency (Weight: 0.25)

Can the skill be understood and applied without external context?

Evaluation steps:
1. List all technical terms and concepts used
2. Check if each is defined or explained within the skill
3. Identify assumptions about user knowledge
4. Note dependencies on external context
5. Test: could a user with no prior context apply this skill?

| Score | Criteria |
|-------|----------|
| 5 | Complete standalone understanding, all terms defined, no external dependencies |
| 4 | Minor context gaps, 95%+ self-contained |
| 3 | Some context assumed, 85%+ self-contained |
| 2 | Frequent context gaps, relies on external knowledge |
| 1 | Cannot understand without external context |

#### Dimension 3: Completeness (Weight: 0.20)

Coverage of stated scope and source material.

Evaluation steps:
1. Identify stated scope from description and TL;DR
2. List main topics in source material
3. Check coverage of each topic in skill
4. Calculate percentage of source material synthesised
5. Note significant gaps or omissions

| Score | Criteria |
|-------|----------|
| 5 | Stated scope fully covered, 90%+ source material synthesised |
| 4 | 85%+ scope covered, minor gaps |
| 3 | 75%+ scope covered, some gaps |
| 2 | <75% scope covered, significant gaps |
| 1 | Incomplete coverage, major sections missing |

#### Dimension 4: Specificity (Weight: 0.15)

Actionability and detail of patterns and guidance.

Evaluation steps:
1. Count total patterns and guidelines in skill
2. For each, check for: when to apply, why it matters, how to implement, example
3. Calculate actionability percentage
4. Note vague or generic patterns
5. Assess prompt engineering quality: positive framing, action clarity, verification gates

| Score | Criteria |
|-------|----------|
| 5 | All patterns have when/why/how context and examples, immediately actionable |
| 4 | 90%+ patterns actionable, most have examples |
| 3 | 75%+ patterns actionable, examples present |
| 2 | <75% actionable, many vague patterns |
| 1 | Mostly generic advice, not actionable |

#### Dimension 5: No Overlap (Weight: 0.10)

Skill provides novel value beyond Claude's built-in knowledge.

Evaluation steps:
1. Identify generic content (common best practices, standard definitions)
2. Identify specialised content (org-specific patterns, tool-specific workflows, novel insights)
3. Calculate novelty percentage
4. Assess whether skill justifies its existence

| Score | Criteria |
|-------|----------|
| 5 | Entirely novel content, clear specialised value |
| 4 | 90%+ novel, significant value add |
| 3 | 75%+ novel, skill still justified |
| 2 | <75% novel, questionable value add |
| 1 | Mostly duplicates built-in knowledge |

### Step 7: Compute Results

Calculate weighted score:

```
weighted_score = (
    source_fidelity * 0.30 +
    self_sufficiency * 0.25 +
    completeness * 0.20 +
    specificity * 0.15 +
    no_overlap * 0.10
) / 5.0
```

Determine recommendation:
- **PASS**: weighted_score >= 0.85 AND no dimension scores below 3
- **FAIL**: weighted_score < 0.85 OR any dimension below 3

If behavioral and/or calibration gates are executed, they must also pass for the final recommendation to remain PASS.

### Step 8: Behavioral Gate (External)

Run behavioral tests (activation + traces) and confirm the skill passes the behavioral gate:

```bash
python3 .claude/test-framework/scripts/cogworks-test-framework.py behavioral run --skills-root .agents/skills
```

Behavioral pass criteria:
- activation_f1 >= 0.85
- false_positive_rate <= 0.05
- negative control ratio >= 0.25
- no missing traces

If behavioral tests fail, mark the overall recommendation as FAIL even if Layer 1/2 pass.
