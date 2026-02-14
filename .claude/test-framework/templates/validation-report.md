# Validation Report: {{skill_name}}

**Generated**: {{timestamp}}
**Skill path**: {{skill_path}}
**Framework version**: {{framework_version}}

---

## Summary

**Overall Result**: {{result}} ({{overall_score}}/1.0)

**Quick Stats**:
- Weighted score: {{weighted_score}}/5.0
- Critical failures: {{critical_failure_count}}
- Warnings: {{warning_count}}
- Tests passed: {{tests_passed}}/{{tests_total}}

**Recommendation**: {{recommendation}}

---

## Layer 1: Deterministic Checks

**Status**: {{deterministic_status}}
**Duration**: {{deterministic_duration}}s
**Cost**: ${{deterministic_cost}}

### Passed Checks ({{deterministic_passed_count}})

{{#each deterministic_passed}}
- ✓ {{this}}
{{/each}}

### Warnings ({{deterministic_warning_count}})

{{#each deterministic_warnings}}
- ⚠ {{this}}
{{/each}}

### Critical Failures ({{deterministic_failure_count}})

{{#each deterministic_failures}}
- ✗ {{this}}
{{/each}}

---

## Layer 2: LLM-as-Judge Evaluation

{{#if llm_judge_skipped}}
**Status**: SKIPPED (critical failures in Layer 1)
{{else}}

**Status**: {{llm_judge_status}}
**Model**: {{llm_judge_model}}
**Duration**: {{llm_judge_duration}}s
**Cost**: ${{llm_judge_cost}}

### Category Scores

#### Source Fidelity (Weight: 30%)
**Score**: {{source_fidelity_score}}/5 ({{source_fidelity_weighted}})

- Traceability: {{traceability_percentage}}%
- Claims analyzed: {{claims_analyzed}}
- Claims traceable: {{claims_traceable}}
- Fabrications found: {{fabrications_count}}
- Contradictions flagged: {{contradictions_flagged}}

**Reasoning**: {{source_fidelity_reasoning}}

{{#if source_fidelity_issues}}
**Issues**:
{{#each source_fidelity_issues}}
- {{this}}
{{/each}}
{{/if}}

#### Self-Sufficiency (Weight: 25%)
**Score**: {{self_sufficiency_score}}/5 ({{self_sufficiency_weighted}})

- Self-contained percentage: {{self_contained_percentage}}%
- Undefined terms: {{undefined_term_count}}
- Context dependencies: {{context_dependency_count}}

**Reasoning**: {{self_sufficiency_reasoning}}

{{#if undefined_terms}}
**Undefined terms**:
{{#each undefined_terms}}
- {{this}}
{{/each}}
{{/if}}

#### Completeness (Weight: 20%)
**Score**: {{completeness_score}}/5 ({{completeness_weighted}})

- Scope coverage: {{scope_coverage_percentage}}%
- Source coverage: {{source_coverage_percentage}}%
- Major gaps: {{gap_count}}

**Reasoning**: {{completeness_reasoning}}

{{#if gaps}}
**Gaps identified**:
{{#each gaps}}
- {{this}}
{{/each}}
{{/if}}

#### Specificity (Weight: 15%)
**Score**: {{specificity_score}}/5 ({{specificity_weighted}})

- Total patterns: {{total_patterns}}
- Actionable patterns: {{actionable_patterns}}
- Patterns with examples: {{patterns_with_examples}}
- Vague patterns: {{vague_pattern_count}}

**Reasoning**: {{specificity_reasoning}}

{{#if vague_patterns}}
**Vague patterns**:
{{#each vague_patterns}}
- {{this}}
{{/each}}
{{/if}}

#### No Overlap (Weight: 10%)
**Score**: {{no_overlap_score}}/5 ({{no_overlap_weighted}})

- Novelty percentage: {{novelty_percentage}}%
- Generic content items: {{generic_content_count}}
- Specialized content items: {{specialized_content_count}}

**Reasoning**: {{no_overlap_reasoning}}

**Value justification**: {{value_justification}}

{{#if generic_content}}
**Generic content examples**:
{{#each generic_content}}
- {{this}}
{{/each}}
{{/if}}

### Weighted Score Calculation

```
({{source_fidelity_score}} × 0.30) + ({{self_sufficiency_score}} × 0.25) +
({{completeness_score}} × 0.20) + ({{specificity_score}} × 0.15) +
({{no_overlap_score}} × 0.10) = {{weighted_score}}/5.0
```

**Normalized**: {{overall_score}}/1.0

{{/if}}

---

## Source Fidelity Deep Dive

### Citation Analysis

**Total claims analyzed**: {{claims_analyzed}}
**Traceable to sources**: {{claims_traceable}} ({{traceability_percentage}}%)
**Citation format**: {{citation_format_status}}

### Sample Claims Traced

{{#each sample_claims}}
**Claim {{@index}}**: "{{claim}}"
- **Source**: {{source}}
- **Traceable**: {{traceable}}
{{#if note}}
- **Note**: {{note}}
{{/if}}
{{/each}}

### Fabrications (if any)

{{#if fabrications}}
{{#each fabrications}}
- **Claim**: "{{claim}}"
- **Issue**: {{issue}}
- **Severity**: {{severity}}
{{/each}}
{{else}}
✓ No fabrications detected
{{/if}}

### Source Contradictions

{{#if contradictions}}
{{#each contradictions}}
- **Topic**: {{topic}}
- **Source A**: {{source_a}} says "{{claim_a}}"
- **Source B**: {{source_b}} says "{{claim_b}}"
- **Flagged in skill**: {{flagged}}
{{/each}}
{{else}}
✓ No contradictions found in sources
{{/if}}

---

## Test Results by Category

### Synthesis Structure Tests
{{#each synthesis_tests}}
- [{{status_icon}}] {{id}}: {{description}} {{#if status_detail}}({{status_detail}}){{/if}}
{{/each}}

### Skill Structure Tests
{{#each skill_tests}}
- [{{status_icon}}] {{id}}: {{description}} {{#if status_detail}}({{status_detail}}){{/if}}
{{/each}}

### Content Quality Tests
{{#each quality_tests}}
- [{{status_icon}}] {{id}}: {{description}} {{#if status_detail}}({{status_detail}}){{/if}}
{{/each}}

### Security Tests
{{#each security_tests}}
- [{{status_icon}}] {{id}}: {{description}} {{#if status_detail}}({{status_detail}}){{/if}}
{{/each}}

---

## Recommendations

{{#if critical_failures}}
### Critical Issues (Must Fix)
{{#each critical_failures}}
{{@index}}. **{{title}}**
   - **Issue**: {{description}}
   - **Impact**: {{impact}}
   - **Fix**: {{suggested_fix}}
{{/each}}
{{/if}}

{{#if warnings}}
### Warnings (Should Address)
{{#each warnings}}
{{@index}}. **{{title}}**
   - **Issue**: {{description}}
   - **Suggestion**: {{suggestion}}
{{/each}}
{{/if}}

{{#if improvements}}
### Suggested Improvements
{{#each improvements}}
- {{this}}
{{/each}}
{{/if}}

{{#if passing}}
### Quality Highlights
{{#each highlights}}
- ✓ {{this}}
{{/each}}
{{/if}}

---

## Next Steps

{{#if critical_failures}}
1. **Address critical failures** before proceeding
2. Re-run validation after fixes
3. Consider source material quality - may need more/better sources
{{else if warnings}}
1. Review warnings and decide which to address
2. Optional: Re-run validation to confirm improvements
3. Skill is production-ready if you accept warnings
{{else}}
✅ **Skill passed all validation checks**
- No critical issues found
- Quality score: {{overall_score}}/1.0 (target: ≥0.85)
- Ready for production use
{{/if}}

---

## Metadata

**Test execution**:
- Framework version: {{framework_version}}
- Timestamp: {{timestamp}}
- Duration: {{total_duration}}s
- Total cost: ${{total_cost}}

**Skill metadata**:
- Skill slug: {{skill_slug}}
- Source files: {{source_file_count}}
- SKILL.md lines: {{skill_md_lines}}
- Supporting files: {{supporting_files}}

**Grading configuration**:
- Success threshold: ≥0.85
- LLM judge model: {{llm_judge_model}}
- Deterministic checks: {{deterministic_check_count}}
- LLM judge rubrics: 5 categories

---

## Raw Data

Full test results available in JSON format:
`{{json_output_path}}`

For programmatic access:
```bash
cat {{json_output_path}} | jq '.overall_score'
```

---

*Generated by cogworks-test framework v{{framework_version}}*
*Report any issues: https://github.com/anthropics/claude-code/issues*
