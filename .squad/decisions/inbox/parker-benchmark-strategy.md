# Parker's Benchmark Strategy Proposals

**Date:** 2026-03-08
**Status:** Proposal — awaiting review and approval

---

## Executive Summary

The benchmark infrastructure is production-ready but unused. Behavioral evaluation was correctly deleted (D-022) but never reconstructed. Both gaps block any credible claim that agentic skills are better than legacy skills.

This document proposes:
1. A concrete path to the **first real benchmark run** (legacy vs agentic comparison)
2. A **reconstruction strategy for behavioral evaluation** that avoids circular validation

---

## Issue 1: First Real Benchmark Run

### Current State

✅ **What exists:**
- Benchmark harness (`scripts/run-skill-benchmark.py`) — 748 lines, schema-validated, bootstrap CI support
- Four JSON schemas (case, observation, judge-output, benchmark-summary)
- Pilot smoke test passes (synthetic fixtures)
- Codex adapter with replay mode
- Research justification document (D-030)

❌ **What's missing:**
- Zero published skill-vs-skill comparisons
- No real benchmark dataset
- No decision based on benchmark evidence

**The gap:** The system is a specification without a capability.

---

### Proposal: Legacy vs Agentic Comparison (First Benchmark Run)

#### What to Compare

**Comparison target:** `cogworks` skill (legacy engine) vs `cogworks-agentic` skill (agentic engine)

**Rationale:**
- Legacy and agentic engines already coexist in `skills/cogworks/SKILL.md`
- Agentic path has live smoke evidence (`.cogworks-runs/api-auth-smoke-copilot-smoke/`)
- The agentic pivot's entire justification depends on proving quality improvement — this benchmark is the decision gate

**Artifacts:**
- **Candidate A:** Legacy prompt-orchestrated run (current default)
- **Candidate B:** Agentic 5-stage run (D-028 simplified architecture)

---

#### Benchmark Dataset Requirements

**Minimum viable dataset: 15 cases across 3 categories**

| Category | Count | Purpose |
|----------|-------|---------|
| `invoked-task` | 8 cases | Skills where both engines should activate and produce a working skill |
| `hard-negative` | 4 cases | Inputs where neither should produce a skill (reject/error handling) |
| `boundary` | 3 cases | Adversarial: contradictory sources, security probes, edge cases |

**Case selection criteria:**

1. **Invoked-task cases (8):**
   - 3 simple: single source, clear domain (e.g., API patterns, CLI conventions)
   - 3 moderate: 2-3 sources, synthesis required (e.g., security + usability guidance)
   - 2 complex: contradictory sources, entity boundaries, trust distinctions

2. **Hard-negative cases (4):**
   - Insufficient source material (empty or stub content)
   - Explicitly non-skill content (narrative blog post, changelog)
   - Overtly harmful or policy-violating requests
   - Malformed or unparseable source files

3. **Boundary cases (3):**
   - Source containing delimiter injection attempt (`<<UNTRUSTED_SOURCE>>` literal — D-024 hardens this)
   - Contradictory guidance with no clear resolution
   - Ambiguous task scope (is this a skill or just reference documentation?)

**Observable checks per category:**

- **Invoked-task:**
  - `file_exists`: Generated `SKILL.md` exists
  - `file_contains`: Required frontmatter fields present
  - `deterministic_checks`: Layer 1 validation passes (`scripts/test-generated-skill.sh`)
  - `judge_only`: Cross-model judge evaluates correctness, completeness, synthesis fidelity (weight: 0.3)

- **Hard-negative:**
  - `state_assertion`: Process exits gracefully (no crash)
  - `file_not_exists`: No skill generated (or skill marked `INVALID`)
  - `log_contains`: Error message explains rejection

- **Boundary:**
  - Mix of deterministic and judge-based depending on scenario
  - Delimiter injection: deterministic check that source was sanitized
  - Contradictions: judge evaluates whether both perspectives preserved
  - Ambiguity: judge evaluates graceful degradation or clarification request

---

#### Judge Model & Protocol

**Judge model:** `gpt-4.1` or `gemini-3-pro-preview`

**Rationale:**
- Generator is Claude Sonnet 4.6 (legacy) or Claude Haiku 4.5 (agentic roles)
- Cross-model family independence required (D-026)
- GPT or Gemini provides non-circular judgment

**Judge protocol:**
- **Input:** Source materials, generated skill, case-specific rubric
- **Output:** Structured JSON per `judge-output.schema.json`
  - `score`: 0.0 to 1.0
  - `confidence`: Judge's self-assessed certainty
  - `reasoning`: Justification for score
  - `dimension_scores`: Breakdown (correctness, completeness, synthesis_fidelity)
- **Calibration:** Before production run, judge 3 human-labeled reference cases per category to verify inter-rater reliability ≥ 0.70

---

#### Execution Plan (Step-by-Step)

**Phase 1: Dataset Creation (2-3 days)**

1. Author 15 case definitions in `case.schema.json` format
2. Create source materials for each case under `tests/datasets/legacy-vs-agentic/sources/`
3. Manually validate that cases are unambiguous and executable
4. Write expected outcomes for deterministic checks (file presence, schema validity)

**Phase 2: Judge Calibration (1 day)**

1. Select 3 reference cases (1 per category)
2. Have 2 human raters score each case independently
3. Run judge on same cases
4. Calculate inter-rater reliability (target: ≥ 0.70)
5. Adjust rubric if judge/human divergence is systematic

**Phase 3: Benchmark Execution (1 day)**

1. Run harness with 5 trials per case:
   ```bash
   python3 scripts/run-skill-benchmark.py \
     --benchmark-id legacy-vs-agentic-2026-03-08 \
     --cases-file tests/datasets/legacy-vs-agentic/cases.jsonl \
     --candidate-a cogworks-legacy \
     --candidate-a-command "scripts/legacy-runner.sh" \
     --candidate-b cogworks-agentic \
     --candidate-b-command "scripts/agentic-runner.sh" \
     --model claude-sonnet-4.6 \
     --agent-surface copilot-cli \
     --trials 5
   ```
2. Harness emits `benchmark-summary.json`, `benchmark-report.md`, `benchmark-results.json`
3. Archive raw run artifacts under `evals/results/legacy-vs-agentic-2026-03-08/`

**Phase 4: Analysis & Decision (1 day)**

1. Review `benchmark-report.md` for:
   - Mean paired delta (candidate_b - candidate_a)
   - 95% confidence interval
   - Win rate by category
   - Safety/compliance regressions
   - Activation diagnostics
2. Manual review of boundary case failures
3. Decision outcome:
   - **Agentic wins:** Mean delta > 0, CI excludes zero, no safety regressions → document in D-NNN and default to agentic
   - **Legacy wins:** Mean delta < 0 → document failure, revert or fix agentic
   - **No clear winner:** CI overlaps zero → insufficient evidence, investigate category-specific patterns
   - **Insufficient data:** Sample too small, re-run with more trials

**Deliverables:**
- `tests/datasets/legacy-vs-agentic/cases.jsonl` (15 cases)
- `tests/datasets/legacy-vs-agentic/sources/` (source materials)
- `evals/results/legacy-vs-agentic-2026-03-08/benchmark-summary.json`
- `evals/results/legacy-vs-agentic-2026-03-08/benchmark-report.md`
- `evals/results/legacy-vs-agentic-2026-03-08/benchmark-results.json`
- Decision document: `_plans/DECISIONS.md` D-NNN entry with benchmark verdict

---

#### Risk & Mitigation

**Risk 1: Agentic engine is slower/costlier and performs worse**
- **Likelihood:** Medium (D-028 notes latency/cost penalty)
- **Impact:** High (invalidates pivot justification)
- **Mitigation:** Benchmark answers this definitively — better to know now than after broader adoption

**Risk 2: Judge model introduces bias (position, verbosity, self-preference)**
- **Likelihood:** Medium (documented in LLM-as-judge literature)
- **Impact:** Medium (skews comparison)
- **Mitigation:** Use deterministic checks for 70% of score weight, judge only for residual 30%. Calibrate judge against human labels before production run.

**Risk 3: Dataset is too easy/hard and fails to discriminate**
- **Likelihood:** Medium (first benchmark dataset)
- **Impact:** Medium (no clear winner, wasted effort)
- **Mitigation:** Include boundary/hard-negative cases. Manual review of 3 pilot cases before full run. If pilot shows no delta, revise dataset before full execution.

**Risk 4: 15 cases × 5 trials = 75 skill generation runs is expensive**
- **Likelihood:** High (estimate: 15-30 min per agentic run, 2-5 min per legacy run)
- **Impact:** Low (cost acceptable for decision-grade evidence)
- **Mitigation:** Run overnight. If cost prohibitive, reduce to 3 trials per case (minimum for CI).

---

## Issue 2: Behavioral Evaluation Reconstruction

### Current State

❌ **What was deleted (D-022/D-023):**
- All 24 behavioral trace files (LLM-generated outputs used as ground truth)
- 9 capture scripts
- `cogworks-eval.py behavioral run` command

✅ **What remains:**
- `test-cases.jsonl` (human-authored activation test definitions)
- Scaffolding command (`cogworks-eval.py behavioral scaffold`)
- Framework structure (`tests/framework/`, `tests/behavioral/`)

**The gap:** No way to measure whether a generated skill changes agent behavior.

---

### Proposal: Non-Circular Behavioral Evaluation

#### Design Principles

1. **External ground truth required** — no LLM-generated outputs as validation data
2. **Cross-model independence** — different judge family from generator (D-026)
3. **Observable behavior preferred** — deterministic checks before judge-based checks
4. **Baseline comparison is the signal** — WITH skill vs WITHOUT skill

---

#### Architecture: Two-Track Evaluation

**Track 1: Activation Testing (Deterministic)**

**Scope:** Does the skill activate when it should, and stay silent when it shouldn't?

**Method:**
- Human-authored test cases define expected activation behavior
- Run agent with and without skill on same prompt
- Compare tool calls, file access patterns, command invocations (observable behavior)
- No judge required — purely trace-based

**Artifacts:**
- Input: `tests/behavioral/{skill}/test-cases.jsonl`
- Output: `tests/behavioral/{skill}/activation-results.json`

**Example check:**
```json
{
  "case_id": "cogworks-invoke-positive",
  "prompt": "Generate a skill for API rate limiting best practices from these markdown docs",
  "expected_activation": "must_activate",
  "observable_checks": [
    {"kind": "tool_called", "target": "cogworks", "required": true},
    {"kind": "file_created", "pattern": "*.md/SKILL.md", "required": true}
  ]
}
```

**Pass criteria:**
- Precision ≥ 0.85 (true positives / (true positives + false positives))
- Recall ≥ 0.80 (true positives / (true positives + false negatives))

---

**Track 2: Efficacy Testing (Cross-Model Judge)**

**Scope:** When the skill activates, does it improve task outcomes?

**Method:**
- Select 10 representative tasks per skill
- Run each task 5 times WITH skill, 5 times WITHOUT skill (baseline)
- Use cross-model judge to score task outcomes on rubric (correctness, completeness, safety)
- Compute behavioral delta: `mean_with_skill - mean_without_skill`

**Artifacts:**
- Input: Task set definition (e.g., `tests/behavioral/{skill}/efficacy-tasks.jsonl`)
- Output: `tests/behavioral/{skill}/efficacy-results.json`

**Judge contract:**
- **Input:** Task prompt, WITH-skill output, WITHOUT-skill output
- **Output:** Structured JSON per `judge-output.schema.json`
  - Pairwise comparison: "Which outcome better satisfies the task requirements?"
  - Score delta: -1.0 (baseline better) to +1.0 (skill better)
  - Confidence and reasoning
- **Model:** Different family from generator (e.g., GPT judges Claude, Gemini judges GPT)

**Pass criteria (D-026):**
- `behavioral_delta` ≥ 0.20
- `judge_confidence` ≥ 0.70
- `sample_size` ≥ 5 (10 tasks × 5 trials = 50 paired comparisons)
- `confidence_interval_95` lower bound > 0

---

#### Relationship to Skill Benchmark

**Behavioral evaluation is skill-specific. Skill benchmark is comparative.**

| Dimension | Behavioral Evaluation | Skill Benchmark |
|-----------|----------------------|-----------------|
| **Scope** | Single skill (WITH vs WITHOUT) | Two skills (A vs B) |
| **Purpose** | Validate skill improves behavior | Compare which skill is better |
| **Baseline** | Agent without skill | Alternate skill implementation |
| **Frequency** | Per skill on generation/update | Periodic, for architectural decisions |
| **Infrastructure** | `tests/behavioral/{skill}/` | `evals/skill-benchmark/` + harness |

**Sequencing:**
1. Behavioral evaluation runs first (validates each skill independently)
2. Skill benchmark runs second (compares validated skills)

They share:
- Cross-model judge protocol
- Observable behavior preference
- Repeated-trial uncertainty reporting

They do NOT share:
- Case datasets (behavioral = activation + efficacy per skill; benchmark = paired comparison)
- Runner contract (behavioral = direct invocation; benchmark = env-var adapter contract)

---

#### Implementation Plan

**Phase 1: Activation Track (Deterministic) — 2 weeks**

1. Write activation trace capture script (`scripts/capture-activation-trace.sh`)
   - Runs agent WITH and WITHOUT skill
   - Extracts observable behaviors (tool calls, file ops, command invocations)
   - Outputs structured JSON (no free-form LLM judgment)
2. Update `cogworks-eval.py behavioral run` to run activation checks only
3. Validate on 3 existing skills (cogworks, cogworks-encode, cogworks-learn)
4. Document pass/fail criteria in `tests/framework/README.md`

**Phase 2: Efficacy Track (Cross-Model Judge) — 3 weeks**

1. Define efficacy task format (extends `case.schema.json` with baseline requirement)
2. Write efficacy runner (`scripts/run-behavioral-efficacy.py`)
   - Executes WITH and WITHOUT runs
   - Invokes cross-model judge for pairwise comparison
   - Computes behavioral delta with bootstrap CI
3. Integrate D-026 schema (quality object with `behavioral_delta`, `judge_confidence`, `sample_size`, `confidence_interval_95`)
4. Calibrate judge on 5 human-labeled reference cases
5. Run efficacy evaluation on 1 pilot skill

**Phase 3: CI Integration — 1 week**

1. Update `tests/ci-gate-check.sh` to run activation checks (deterministic only)
2. Add CI workflow step for activation tests on PR
3. Efficacy tests remain manual/periodic (too expensive for every PR)
4. Update TESTING.md with new workflow

**Deliverables:**
- `scripts/capture-activation-trace.sh` (deterministic trace capture)
- `scripts/run-behavioral-efficacy.py` (cross-model efficacy runner)
- `cogworks-eval.py behavioral run` (reconstructed, two-track)
- `tests/framework/BEHAVIORAL-SPEC.md` (two-track architecture doc)
- Updated `tests/ci-gate-check.sh` (activation checks only)
- Updated `TESTING.md` (Layer 2 reconstruction guidance)

---

#### Risk & Mitigation

**Risk 1: Efficacy evaluation is too expensive for CI**
- **Likelihood:** High (10 tasks × 5 trials × 2 conditions = 100 runs per skill)
- **Impact:** Medium (can't gate every PR on behavioral)
- **Mitigation:** Activation checks (deterministic) run in CI. Efficacy checks (judge-based) run manually before release.

**Risk 2: Baseline runs (without skill) are difficult to execute reliably**
- **Likelihood:** Medium (how do you "turn off" a skill in trace capture?)
- **Impact:** High (can't compute behavioral delta without baseline)
- **Mitigation:** Baseline runs use a clean agent environment with no skill installed. Document baseline environment setup in runner scripts.

**Risk 3: Cross-model judge availability (cost, API limits)**
- **Likelihood:** Medium (GPT/Gemini API costs for 50-100 judgments per skill)
- **Impact:** Medium (evaluation cost becomes prohibitive)
- **Mitigation:** Use deterministic checks for 70% of weight, judge for 30%. Batch judge requests. Cache judge outputs per (task, WITH-output, WITHOUT-output) tuple to avoid re-judging on re-runs.

**Risk 4: Behavioral delta is statistically insignificant (CI overlaps zero)**
- **Likelihood:** Medium (many skills may have small effect sizes)
- **Impact:** Medium (can't claim skill improves behavior)
- **Mitigation:** This is a validity signal, not a failure. If delta is insignificant, skill doesn't pass efficacy gate — correct outcome. Adjust sample size (more trials) or skill design (make stronger guidance) before retrying.

---

## Sequencing Recommendations

**Critical path to first evidence-based decision:**

1. **Immediate (Week 1-2):** Execute legacy vs agentic benchmark (Issue 1)
   - Most urgent: no published benchmark exists, agentic pivot justification is untested
   - Delivers: First real skill-vs-skill comparison, decision-grade evidence

2. **Parallel (Week 2-4):** Reconstruct activation track (Issue 2, Phase 1)
   - Unblocks deterministic behavioral checks for CI
   - Low risk, high value (pure trace-based, no judge circularity)

3. **Follow-on (Week 5-7):** Reconstruct efficacy track (Issue 2, Phase 2)
   - Depends on cross-model judge protocol (same as benchmark)
   - Can reuse judge calibration from legacy vs agentic benchmark

4. **Polish (Week 8):** CI integration and docs (Issue 2, Phase 3)

**Why this order:**
- Benchmark delivers decision-grade evidence fastest (harness exists, just needs dataset)
- Activation reconstruction is lower risk than efficacy (deterministic vs judge-based)
- Efficacy reconstruction benefits from benchmark learnings (judge calibration, rubric refinement)

---

## Success Criteria

**Issue 1 complete when:**
- ✅ 15-case legacy vs agentic dataset exists
- ✅ Benchmark harness executed successfully (5 trials per case)
- ✅ `benchmark-summary.json` published with verdict (`candidate_a` / `candidate_b` / `no_clear_winner`)
- ✅ Decision recorded in `_plans/DECISIONS.md` (D-NNN: benchmark result + architectural choice)

**Issue 2 complete when:**
- ✅ Activation checks (deterministic) run in CI for all core skills
- ✅ Efficacy evaluation (cross-model judge) validated on 1 pilot skill
- ✅ `quality_score: null` replaced with `quality.behavioral_delta` per D-026 schema
- ✅ TESTING.md Layer 2 section updated from "pending reconstruction" to "operational"

---

## Open Questions

1. **Dataset authorship:** Who writes the 15 benchmark cases? (Parker scaffolds, William reviews?)
2. **Judge API access:** Do we have GPT/Gemini API keys configured? Cost budget?
3. **Baseline environment:** How do we execute "agent without skill" runs reliably? (Clean agent install? Symlink removal? Environment variable flag?)
4. **Calibration budget:** Human labeling for 3-5 reference cases — who does the labeling? (William + 1 external reviewer?)
5. **Failure mode:** If agentic loses the benchmark, what's the decision protocol? (Revert to legacy? Fix and re-run? Document as "not ready"?)

---

## Conclusion

The infrastructure is sound. The methodology is justified. The schemas are production-grade.

**What's missing is execution.**

Legacy vs agentic benchmark can run in 5-7 days if dataset authorship is unblocked.

Behavioral evaluation reconstruction is a 5-week project with well-defined phases.

Both are necessary. The benchmark is more urgent because the agentic pivot depends on it.

This proposal provides concrete steps, resource estimates, and decision criteria.

Ready to proceed on approval.

—Parker
