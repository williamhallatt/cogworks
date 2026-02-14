# LLM-as-Judge Rubrics (Layer 2)

Quality assessment rubrics for cogworks skills using Claude Opus 4.6 as evaluator.

## Evaluation Principles

From skill-evaluation skill:
- **Observable behavior focus** - Judge what the skill DOES, not just what it SAYS
- **Anchored scales** - Specific descriptors for each score level
- **Known bias mitigation** - Control for verbosity preference, position bias
- **Structured output** - JSON format for consistent parsing

## Configuration

- **Model**: `claude-opus-4-6`
- **Temperature**: `0.0` (deterministic grading)
- **Max tokens**: `4096`
- **Output format**: JSON with scores and reasoning

## Rubric Categories

### 1. Source Fidelity (Weight: 0.30)

**What it measures**: Accuracy and traceability of claims to source material.

**Scale**:
- **5 - Exceptional**: Every claim has clear citation, contradictions explicitly flagged, synthesis preserves nuance, no fabrication
- **4 - Strong**: 95%+ claims traceable, contradictions noted, minor omissions acceptable
- **3 - Adequate**: 85%+ claims traceable, most contradictions noted, some synthesis gaps
- **2 - Weak**: <85% claims traceable, contradictions missed, noticeable fabrication
- **1 - Failing**: Significant fabrication, missing citations, contradictions ignored

**Evaluation prompt**:
```
Assess source fidelity for this skill by:

1. Identify 10 specific claims/patterns in the skill
2. For each, trace back to source material (check citations)
3. Note any claims without clear source attribution
4. Check if source contradictions are explicitly flagged
5. Calculate traceability percentage

Score on 1-5 scale using rubric above.

Output JSON:
{
  "score": <1-5>,
  "traceability_percentage": <0.0-1.0>,
  "claims_analyzed": <count>,
  "claims_traceable": <count>,
  "fabrications_found": ["claim 1", "claim 2"],
  "contradictions_flagged": <true/false>,
  "reasoning": "<2-3 sentences>"
}
```

### 2. Self-Sufficiency (Weight: 0.25)

**What it measures**: Can the skill be understood and applied without external context?

**Scale**:
- **5 - Exceptional**: Complete standalone understanding, all terms defined, context provided, no external dependencies
- **4 - Strong**: Minor context gaps, 95%+ self-contained, rare external references justified
- **3 - Adequate**: Some context assumed, 85%+ self-contained, user can infer gaps
- **2 - Weak**: Frequent context gaps, relies heavily on external knowledge, terms undefined
- **1 - Failing**: Cannot be understood without external context, many undefined terms

**Evaluation prompt**:
```
Assess self-sufficiency by:

1. List all technical terms/concepts used
2. Check if each is defined or explained
3. Identify assumptions about user knowledge
4. Note dependencies on external context
5. Test: Could a user with no prior context apply this skill?

Score on 1-5 scale using rubric above.

Output JSON:
{
  "score": <1-5>,
  "undefined_terms": ["term 1", "term 2"],
  "context_dependencies": ["dependency 1"],
  "self_contained_percentage": <0.0-1.0>,
  "reasoning": "<2-3 sentences>"
}
```

### 3. Completeness (Weight: 0.20)

**What it measures**: Coverage of stated scope and source material.

**Scale**:
- **5 - Exceptional**: Stated scope fully covered, 90%+ of source material synthesized, no significant gaps
- **4 - Strong**: 85%+ scope covered, minor gaps acceptable, most source material used
- **3 - Adequate**: 75%+ scope covered, some gaps present, reasonable source coverage
- **2 - Weak**: <75% scope covered, significant gaps, sparse source usage
- **1 - Failing**: Incomplete coverage, major sections missing, minimal source usage

**Evaluation prompt**:
```
Assess completeness by:

1. Identify stated scope (from description/TL;DR)
2. List main topics in source material
3. Check coverage of each topic in skill
4. Calculate percentage of source material used
5. Note significant gaps or omissions

Score on 1-5 scale using rubric above.

Output JSON:
{
  "score": <1-5>,
  "scope_coverage_percentage": <0.0-1.0>,
  "source_coverage_percentage": <0.0-1.0>,
  "gaps": ["gap 1", "gap 2"],
  "reasoning": "<2-3 sentences>"
}
```

### 4. Specificity (Weight: 0.15)

**What it measures**: Actionability and detail of patterns/guidance.

**Scale**:
- **5 - Exceptional**: All patterns have when/why/how context, concrete examples, clear decision criteria
- **4 - Strong**: 90%+ patterns actionable, minor abstraction acceptable, most have examples
- **3 - Adequate**: 75%+ patterns actionable, some vague guidance, examples present
- **2 - Weak**: <75% actionable, many vague/generic patterns, examples sparse
- **1 - Failing**: Mostly generic advice, no clear patterns, not actionable

**Evaluation prompt**:
```
Assess specificity by:

1. Count total patterns/guidelines in skill
2. For each, check if it includes:
   - When to apply (context/triggers)
   - Why it matters (reasoning/benefits)
   - How to implement (concrete steps)
   - Example demonstrating usage
3. Calculate actionability percentage
4. Note vague or generic patterns

Score on 1-5 scale using rubric above.

Output JSON:
{
  "score": <1-5>,
  "total_patterns": <count>,
  "actionable_patterns": <count>,
  "patterns_with_examples": <count>,
  "vague_patterns": ["pattern 1", "pattern 2"],
  "reasoning": "<2-3 sentences>"
}
```

### 5. No Overlap (Weight: 0.10)

**What it measures**: Skill provides novel value beyond Claude's built-in knowledge.

**Scale**:
- **5 - Exceptional**: Entirely novel content, no overlap with Claude's training, clear specialized value
- **4 - Strong**: 90%+ novel, minor overlap acceptable, adds significant value
- **3 - Adequate**: 75%+ novel, some overlap but skill still justified, moderate value add
- **2 - Weak**: <75% novel, significant overlap, questionable value add
- **1 - Failing**: Mostly duplicates built-in knowledge, no clear value add

**Evaluation prompt**:
```
Assess novelty by:

1. Identify content that would be in Claude's general training:
   - Generic best practices (e.g., "write clear code")
   - Common knowledge (e.g., "functions should be modular")
   - Standard definitions (e.g., "REST is an architectural style")

2. Identify specialized content:
   - Organization-specific patterns
   - Tool-specific workflows
   - Novel methodologies
   - Non-obvious insights

3. Calculate novelty percentage
4. Assess if skill provides sufficient value to justify existence

Score on 1-5 scale using rubric above.

Output JSON:
{
  "score": <1-5>,
  "novelty_percentage": <0.0-1.0>,
  "generic_content": ["item 1", "item 2"],
  "specialized_content": ["item 1", "item 2"],
  "value_justification": "<does this skill add value?>",
  "reasoning": "<2-3 sentences>"
}
```

## Combined Evaluation

After grading each category, compute weighted score:

```python
weighted_score = (
    source_fidelity * 0.30 +
    self_sufficiency * 0.25 +
    completeness * 0.20 +
    specificity * 0.15 +
    no_overlap * 0.10
) / 5.0  # normalize to 0-1 scale
```

## Output Format

```json
{
  "overall_score": 0.87,
  "weighted_score": 4.35,
  "categories": {
    "source_fidelity": {
      "score": 5,
      "weight": 0.30,
      "traceability_percentage": 0.98,
      "reasoning": "All claims traceable, contradictions flagged, no fabrication"
    },
    "self_sufficiency": {
      "score": 4,
      "weight": 0.25,
      "undefined_terms": ["CORS"],
      "reasoning": "Mostly self-contained, one undefined acronym"
    },
    "completeness": {
      "score": 4,
      "weight": 0.20,
      "scope_coverage_percentage": 0.92,
      "reasoning": "Stated scope covered, minor gaps acceptable"
    },
    "specificity": {
      "score": 4,
      "weight": 0.15,
      "actionable_patterns": 8,
      "total_patterns": 9,
      "reasoning": "Most patterns have when/why/how, one could be more concrete"
    },
    "no_overlap": {
      "score": 5,
      "weight": 0.10,
      "novelty_percentage": 0.95,
      "reasoning": "Highly specialized content, clear value add"
    }
  },
  "recommendation": "PASS",
  "critical_issues": [],
  "warnings": ["Minor undefined term: CORS"]
}
```

## Known Biases and Mitigations

### Bias 1: Verbosity Preference
**Description**: LLM judges may favor longer, more detailed content over concise content.

**Mitigation**: Rubrics explicitly allow for conciseness ("minor omissions acceptable"). Calibrate with human grades that value clarity over length.

### Bias 2: Position Bias
**Description**: Items appearing first may receive higher scores.

**Mitigation**: Randomize evaluation order when assessing multiple items. Present rubric categories in consistent order.

### Bias 3: Leniency
**Description**: LLM judges may be reluctant to give low scores.

**Mitigation**: Calibration phase validates that LLM judge can identify failing cases. Use negative controls to ensure judge gives appropriate low scores.

### Bias 4: Recency
**Description**: Judges may weight recent Claude releases' capabilities more heavily.

**Mitigation**: Rubrics reference "Claude's training" broadly, not specific version. Calibration samples span multiple Claude versions.

## Calibration Process

1. **Select 20 skills** across quality spectrum (5 excellent, 10 good, 3 marginal, 2 failing)
2. **Human evaluation** by expert using these rubrics
3. **LLM evaluation** on same 20 skills
4. **Measure agreement**: Within 0.5 points on 5-point scale
5. **Target**: 90%+ agreement
6. **If below target**: Analyze disagreements, adjust rubrics, repeat

## Usage in cogworks-test Skill

```python
def llm_judge_evaluation(skill_path, sources_path):
    """Run LLM-as-judge evaluation on skill"""

    # Read skill content
    skill_content = read_file(f"{skill_path}/SKILL.md")
    source_content = read_sources(sources_path)

    # Evaluate each category
    results = {}
    for category, rubric in RUBRICS.items():
        prompt = rubric["prompt"].format(
            skill=skill_content,
            sources=source_content
        )

        response = claude_api_call(
            model="claude-opus-4-6",
            temperature=0.0,
            max_tokens=4096,
            system="You are an expert evaluator of technical documentation...",
            messages=[{"role": "user", "content": prompt}]
        )

        results[category] = json.loads(response)

    # Compute weighted score
    weighted_score = compute_weighted_score(results)

    # Generate recommendation
    recommendation = "PASS" if weighted_score >= 0.85 else "FAIL"

    return {
        "overall_score": weighted_score,
        "categories": results,
        "recommendation": recommendation
    }
```

## Maintenance

When rubrics need adjustment:
1. Document disagreements between human and LLM grades
2. Identify systematic biases
3. Update scale descriptors or prompts
4. Re-run calibration on affected categories
5. Target: maintain 90%+ agreement
