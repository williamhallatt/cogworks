# Cogworks Squad Decisions

Consolidated decision record for cross-agent coordination and architectural choices.

**Last audited:** 2026-03-05T00:46:55Z
**Audited by:** Scribe

---

## Decision: TDD Philosophy Synthesis for Cross-Squad Knowledge Transfer

**Date:** 2026-03-05
**Author:** Ripley (Lead)
**Status:** Informational — knowledge synthesis

### Context

William requested review of team's TDD testing approach from architectural perspective, synthesized into prompt for cross-squad knowledge transfer.

### Synthesis Delivered

5-section architectural overview covering:

1. **Core Philosophy** — Breaking circular ground truth problem (LLM-generated traces validating LLM outputs = consistency check, not correctness)
2. **Three-Layer Architecture** — Deterministic (Layer 1), Behavioral (Layer 2), Pipeline (Layer 3) with clear cost/benefit trade-offs
3. **Key Architectural Decisions** — D-022 (traces deleted), D-023 (capture scripts removed), D-025 (doc ownership), D-026 (delimiter injection hardening)
4. **Coordination Patterns** — Test-first with Layer 1, offline defaults, framework meta-tests, post-decision doc audits
5. **Transfer Prompt** — Distilled 200-word summary capturing principles and discipline

### Key Architectural Insights

- **Circular ground truth is epistemological failure, not just technical shortcut** — Team chose correctness over convenience by deleting "working" tests that validated wrong thing
- **Layer 1 deterministic checks are incorruptible** — Mechanical validation can't be gamed by prompt engineering, breaks self-verification circularity
- **Behavioral testing is valuable only with non-circular ground truth** — Team blocked Layer 2 evaluation rather than perpetuate meaningless validation
- **Documentation ownership prevents architectural drift** — No decision closes until stale references cleaned (D-025 protocol)

### Recommendation

This synthesis should be considered canonical description of cogworks testing philosophy for external knowledge transfer. If TESTING.md or AGENTS.md ever diverge from these principles, documentation is stale.

### Scope

- Knowledge synthesis only — no code or doc changes proposed
- Input artifacts: TESTING.md, AGENTS.md, _plans/DECISIONS.md, tests/framework/, scripts/validate-quality-gates.sh, scripts/test-generated-skill.sh
- Output: Architectural overview + 200-word transfer prompt

---

## Decision: TDD Quality Standards Documentation

**Date:** 2026-03-05
**Author:** Parker (Benchmark & Evaluation Engineer)
**Status:** Completed — documentation delivered

### Context

William requested: "Team, I want to teach another squad how you approach TDD testing. Please review your process carefully and tell me the exact prompt I need to provide the other team to get them up to your standard."

Required synthesizing team's quality measurement philosophy, lessons learned from D-022/D-023 (circular ground truth deletion), and statistical validity standards into clear, actionable document for external teams.

### Decision

Created `.squad/agents/parker/tdd-quality-standards.md` — comprehensive TDD quality evaluation standards document covering:

1. Quality criteria for tests (external ground truth, behavior measurement, non-circular)
2. Cross-model independence protocols (avoiding circular validation)
3. Baseline comparison approach (agent WITH skill vs WITHOUT skill)
4. Statistical validity standards (confidence intervals, sample sizes, significance testing)
5. Adversarial testing principles (generalization probes, negative controls)
6. Honest audit of current state (what's working, what's blocked)
7. 18 self-assessment questions for other teams
8. Key learnings from failures (D-022, D-023, D-021) and fixes

### Rationale

**Why this structure:**
- Start with principles (what makes test "good"?) not mechanics
- Provide anti-patterns (what we got wrong, how we detected, how we fixed)
- Give concrete prompts for self-assessment (18 questions)
- Be explicit about what's blocked/under audit (no false confidence)

**Why skeptical tone:**
- Parker's mandate: "It looks right" is not evidence
- Quality measurement requires external validation, not self-approval
- Other teams need to understand failure modes, not just success patterns

**Why statistical validity emphasis:**
- Results without uncertainty quantification are not results
- Confidence intervals, sample sizes, significance tests are non-negotiable
- Single-number "quality scores" are insufficient

**Why baseline comparison focus:**
- Agent WITH skill vs WITHOUT skill is only honest quality signal
- Prior traces had `baseline_run: false` — baselines never actually captured
- Replacement protocol must include real baseline measurements

### Key Principles Documented

#### 1. Quality Definition (Non-Circular)

**The trap:** Tests measuring consistency (run N matches run N-1) not correctness (is output right?)

**The fix:** External ground truth required:
- Human-authored expectations
- Cross-model judging (different model or multi-model consensus)
- Observable behavior specifications from domain experts
- Known-correct reference implementations

#### 2. Cross-Model Independence

**Hard rule:** If Model A generated artifact, Model A cannot be sole judge.

**Approaches:**
- Different model as judge (Claude generates, GPT evaluates)
- Human ground truth (3+ examples per category, 2+ raters, inter-rater reliability ≥ 0.70)
- Multi-model consensus (3+ independent models, different families)
- Observable behavior grounding (deterministic trace checks, no LLM judgment)

#### 3. Baseline Comparison Protocol

**Structure:**
1. Identical task set (same prompts, sources, expected outcomes)
2. Baseline run (agent WITHOUT skill) — capture activation, task completion, quality
3. Treatment run (agent WITH skill) — capture same metrics
4. Statistical comparison (p-value, effect size, confidence intervals)

**Pass criteria:**
- Treatment outperforms baseline on task completion
- No increase in false positive rate
- Statistical significance (p < 0.05, appropriate sample size)

#### 4. Statistical Validity Requirements

**Confidence intervals:** Report uncertainty bounds, not just point estimates
- Example: "Quality score: 0.87 ± 0.04 (95% CI, n=15)"

**Sample sizes:** Justify with power analysis
- Behavioral evaluation: ≥15 activation cases, ≥5 negative controls per skill
- Baseline comparison: ≥10 identical tasks per condition
- Human ground truth: ≥3 reference skills per category, ≥2 raters each

**Significance testing:** Report p-values, effect sizes, multiple comparison corrections

### Scope

- Documentation deliverable only — no code changes
- Input artifacts: charter.md, DECISIONS.md (D-022, D-023, D-021, D-024), TESTING.md, test framework scripts, test case definitions
- Output: `.squad/agents/parker/tdd-quality-standards.md` (comprehensive standards document)

### Status

✅ **Completed** — Quality standards documented for external team handoff

---

## Decision: quality_score Field Definition and Schema Versioning

**Date:** 2026-03-05
**Author:** Parker (Benchmark & Evaluation Engineer)
**Status:** Schema defined — implementation pending

### Context

D-022 deleted all behavioral traces due to circular ground truth problem. The `quality_score` field was never operationally defined — traces had `quality_score: null` throughout. This decision closes that gap with statistically valid, non-circular definition.

### Decision

The `quality_score` field in behavioral traces is formally defined. The top-level field is deprecated (remains null). A new `quality` object replaces it with:

- **behavioral_delta** (primary signal) — Agent WITH skill vs WITHOUT skill performance improvement
- **judge_model** — Model or process used for evaluation (must differ from generator)
- **judge_confidence** — Confidence score from judge (0.0 to 1.0)
- **dimension_scores** — Breakdown by evaluation dimension (correctness, completeness, etc.)
- **sample_size** — Number of test cases evaluated
- **confidence_interval_95** — Statistical uncertainty bounds
- **verdict** — Human-readable quality assessment

**Schema documentation:** `tests/framework/QUALITY-SCHEMA.md`

### Pass Thresholds

- `behavioral_delta` ≥ 0.20
- `judge_confidence` ≥ 0.70
- `sample_size` ≥ 5
- Confidence interval lower bound > 0

### Cross-Model Independence

**Hard rule:** Generator and judge must be different model families (Claude ≠ GPT ≠ Gemini)

This prevents circular validation where same model judges its own outputs.

### Next Steps

Hudson implements evaluation harness per `HARNESS-SPEC.md` (Parker's next deliverable after schema definition).

### Scope

- Schema definition only — no harness implementation yet
- Output: `tests/framework/QUALITY-SCHEMA.md` (expected)
- Blocks: Layer 2 behavioral evaluation unblocked once harness implemented

---

### Hudson Action Item: HARNESS-SPEC.md Ready for Implementation

**Date:** 2026-03-05 | **By:** Parker (via Scribe)
**What:** Parker's behavioral delta harness specification (`tests/framework/HARNESS-SPEC.md`) is complete and ready for Hudson to implement. All quality gates this spec depends on are now in place: three judge prompts (one per skill), QUALITY-SCHEMA.md, and calibration notes showing all 3 skills at "ready for harness" status.
**Why:** Hudson owns harness implementation; Parker owns spec and methodology. This entry signals handoff.
**Action required (Hudson):** Read `tests/framework/HARNESS-SPEC.md` and implement the behavioral delta runner. Implement cross-model independence check at startup (generator model ≠ judge model). Do not store run outputs as future ground truth.
**Blocked until:** Hudson implements the harness — CI behavioral coverage gate remains failing.
