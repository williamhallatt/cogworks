# Reference: Cogworks Testing Framework

Complete methodology for validating cogworks-generated skills through eval-driven development.

## Implementation Status

| Component | Status | Location |
|-----------|--------|----------|
| Layer 1: Deterministic checks (14 checks) | Implemented | `deterministic-checks.sh` |
| Layer 2: LLM-as-judge (5 dimensions) | Implemented | `cogworks-test/SKILL.md` |
| Layer 3: Human review | Guide defined, manual process | `human-review-guide.md` |
| Calibration loop | Template infrastructure | `tests/calibration/` |
| Meta-test suite (8 tests) | Implemented | `tests/run-black-box-tests.sh` |

## Layer 1: Deterministic Checks

**Authoritative source**: `.claude/test-framework/graders/deterministic-checks.sh`

The script header documents all thresholds. There is no external config file — all values are inline in the script. The script runs 14 checks:

1. SKILL.md exists
2. Frontmatter is valid YAML
3. Required frontmatter fields (name, description)
4. Line count <= 500
5. Source citations present
6. No forbidden patterns
7. Supporting files follow 3+ entry rule
8. Description has sufficient content (>= 10 words)
9. No duplicate section headers
10. Markdown syntax valid (code fences balanced)
11. No cross-file heading duplication
12. Frontmatter name format (lowercase, numbers, hyphens; max 64 chars; no reserved words)
13. Supporting file substantiveness (>50% of sections must have >= 20 words)
14. Citation format consistency (file-path citations have plausible line numbers)

## Quality Dimension Rubrics (Layer 2)

Rubric scales, evaluation prompts, and scoring formula are defined in two places:

- **Inline execution**: `cogworks-test/SKILL.md` — condensed tables used during evaluation
- **Full specification**: `.claude/test-framework/graders/llm-judge-rubrics.md` — source of truth with detailed scales and evaluation prompts

This file covers scoring philosophy, known biases, and troubleshooting below.

## LLM-as-Judge Known Biases

- **Verbosity preference** — May favour longer content. Mitigation: rubrics explicitly allow conciseness.
- **Position bias** — Items appearing first may score higher. Mitigation: randomise evaluation order.
- **Leniency** — Reluctant to give low scores. Mitigation: anti-leniency prompting in SKILL.md; calibrate with negative controls.
- **Recency** — May weight recent Claude capabilities more heavily. Mitigation: reference training broadly.

**When to trust LLM scores**: Calibration shows >90% agreement, skill fits standard patterns, scores are extreme (1-2 or 4-5), multiple dimensions agree.

**When to be skeptical**: Agreement <90%, scores cluster around threshold (3-4), single dimension dramatically different, novel skill structure.

## Weighted Scoring Philosophy

Weights reflect **failure impact**, **recovery cost**, and **trust damage**:

- **Source Fidelity (30%)** — Fabrication destroys trust. Requires complete re-synthesis to fix.
- **Self-Sufficiency (25%)** — Unusable without external context. Moderate recovery.
- **Completeness (20%)** — Reduces utility but doesn't create false information. Easy recovery.
- **Specificity (15%)** — Vague but not wrong. Easy recovery.
- **No Overlap (10%)** — Still useful with minor overlap. Trivial recovery.

Tune based on: user expertise (novices need higher self-sufficiency), context budget (tight budgets need higher no-overlap), trust requirements (high-stakes need higher source fidelity).

## Troubleshooting

### Layer 1 Takes Too Long

Large skill files or many supporting files. Check 500-line limit first.

### All Skills Failing on Same Check

Review recent changes (`git log`), check thresholds in the script header, re-run meta-tests.

### False Positives in Deterministic Checks

Forbidden pattern list too broad or check logic doesn't handle valid edge cases. Review the script directly and add exceptions for valid usage.

### Layer 2 Scores Too High

Check anti-leniency prompting in SKILL.md. Score 5 should be rare. If all skills score 4-5, the rubric anchors need tightening or the evaluation is not sampling claims critically enough.

## Cost and Performance

| Layer | Cost | Duration |
|-------|------|----------|
| Layer 1 (Deterministic) | ~free | <1 sec |
| Layer 2 (LLM-as-Judge) | Part of conversation context | ~30 sec |
| Layer 3 (Human Review) | ~$100 | ~20 min |

Layer 2 uses the invoking Claude instance directly — no external API calls needed.

## Sources

1. `.claude/test-framework/graders/deterministic-checks.sh` — Layer 1 implementation (authoritative)
2. `.claude/test-framework/graders/llm-judge-rubrics.md` — Layer 2 rubric specification
3. `.claude/test-framework/graders/human-review-guide.md` — Layer 3 calibration process
4. `CLAUDE.md:48-54` — Quality requirements definition
5. Anthropic eval-driven development best practices
