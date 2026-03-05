# TDD Testing Quality Standards — Parker's Evaluation Framework

**Context:** This document captures the cogworks team's approach to defining and measuring test quality from first principles. It reflects lessons learned from detecting and removing circular quality measurement (D-022/D-023) and establishing external validity criteria.

**Target audience:** Teams building TDD practices who need to distinguish between tests that validate consistency vs tests that validate correctness.

---

## 1. What Makes a Test "Good"? (Quality Criteria for Tests Themselves)

### 1.1 Core Principle: Tests Must Measure Correctness, Not Consistency

**The circular testing trap:** A test that consistently produces the same result across runs validates **consistency**, not **correctness**. A skill that consistently produces the same wrong output will always pass a consistency check.

**Example of circular measurement (what we removed):**
- LLM generates skill → LLM captures trace from skill execution → trace becomes "ground truth" → future runs compared to trace
- Problem: Model generating skills and model evaluating them share training prior
- `quality_score: null` on all core skill traces — quality was never defined, only consistency
- `task_completed: false` in baseline runs — the baseline comparison was never validated

**What we learned:** If the system that produces the artifact also defines what "good" looks like, you're measuring agreement with itself, not quality.

### 1.2 Quality Criteria (Non-Circular)

A good test:

1. **Has external ground truth** — defined independently of the system under test
   - Human-authored expectations
   - Multiple independent models in consensus (not the same model family)
   - Observable behavior specifications from domain experts
   - Known-correct reference implementations

2. **Measures behavior, not text** — actions taken, not eloquence
   - For agent skills: tool invocations, command sequences, file operations
   - Text quality is secondary; a skill producing beautiful prose while suggesting `git push --force` is failing
   - Grade the trace, not the narrative

3. **Is deterministic first, probabilistic second**
   - Structural checks (file exists, sections present, citations formatted) pass/fail deterministically
   - Behavioral checks (does X happen before Y?) are observable and repeatable
   - LLM-as-judge scoring happens ONLY after deterministic checks pass
   - Order matters: validity gates → behavioral gates → quality judgments

4. **Has clear, single-behavior scope**
   - One test = one behavior under test
   - Failure message must diagnose which behavior failed without reading the test code
   - Prefer "test_deployment_requires_git_status_check" over "test_deployment_process"

5. **Doesn't couple to implementation details**
   - Tests public API and observable state, not internal wiring
   - Mock only at external boundaries or where interaction IS the behavior
   - Refactoring implementation shouldn't break tests if behavior unchanged

6. **Is non-flaky by design**
   - Deterministic inputs → deterministic outputs
   - No timing dependencies, no order-dependent state
   - Quarantine/fix any non-determinism immediately — flaky tests destroy trust

### 1.3 Three-Layer Gate Model (Validity → Behavior → Quality)

**Layer 1 (Structural/Deterministic):** Validity checks, not quality checks
- Pass criteria: exit 0, zero critical failures
- Checks: file structure, YAML frontmatter, citations present, fences balanced
- Runtime: < 1 second, no LLM calls
- **Limitation acknowledged:** Structure validity ≠ semantic correctness. A skill with all sections present but wrong guidance passes Layer 1.

**Layer 2 (Behavioral):** Activation and execution correctness
- Pass criteria: `activation_f1 >= 0.85`, `false_positive_rate <= 0.05`, `negative_control_ratio >= 0.25`
- **Status:** Pending reconstruction (D-022/D-023). Prior traces were circular ground truth.
- Test cases (`tests/behavioral/*/test-cases.jsonl`) are valid — they define activation intent, not ground truth
- Replacement approach: baseline comparison (agent WITH skill vs WITHOUT skill on identical tasks)

**Layer 3 (Pipeline Benchmark A/B):** Cross-pipeline quality comparison
- Real mode (decision-grade): actual encode runs with statistical validity
- Offline mode (plumbing verification): hardcoded metrics, not decision-grade
- Pass criteria: guardrails on structural pass rate, activation F1, false positive rate, negative control ratio
- Winner criterion under audit: must be objective and externally validated

---

## 2. How to Avoid Circular Testing (Cross-Model Independence)

### 2.1 The Independence Principle

**Hard rule:** If Model A generated the artifact, Model A cannot be the sole judge of the artifact's quality.

**Why:** Models have training biases. Evaluating your own output validates that you're consistent with your training distribution, not that you're correct.

### 2.2 Cross-Model Independence Approaches

**Option 1: Different model as judge**
- Claude generates skill → GPT evaluates skill
- Anthropic model generates → OpenAI model judges (different training corpus)
- Requires: judging prompt that doesn't leak generating model's perspective

**Option 2: Human ground truth**
- For known source materials, human grades reference skills
- Generated skills compared to human-graded reference set
- Sample size requirement: minimum 3 human-graded examples per skill category
- Inter-rater reliability required when multiple humans judge

**Option 3: Multi-model consensus**
- 3+ independent models evaluate the same artifact
- Consensus threshold (e.g., 2 of 3 agree) determines pass/fail
- Models must be from different families (not Claude Opus + Claude Sonnet — use Claude + GPT + Gemini)

**Option 4: Observable behavior grounding (strongest)**
- Define expected behaviors independently: commands to run, files to create, sequence ordering
- Write deterministic graders checking trace events
- No LLM judgment required for behavior checks
- Source: OpenAI execution trace emphasis, observable behavior paradigm

### 2.3 What We Implemented

**Current state (2026-03-05):**
- Deleted 24 circular behavioral traces (D-022)
- Deleted 9 trace capture scripts that generated circular ground truth (D-023)
- CI gate blocks regeneration with clear error directing to Parker's mandate
- Test cases (human-authored activation definitions) retained and valid
- Replacement ground truth: TBD by Parker from first principles

**Protocol for new behavioral traces:**
1. Test cases define expected activation (human-authored)
2. Baseline runs (agent WITHOUT skill) captured independently
3. Skill runs (agent WITH skill) captured independently
4. Comparison judged by different model or deterministic behavioral grader
5. `quality_score` defined with confidence intervals, not single number

---

## 3. Baseline Comparison Approach (Agent WITH Skill vs WITHOUT Skill)

### 3.1 The Only Honest Quality Signal

**Principle:** The delta between agent performance WITH skill and WITHOUT skill on identical tasks is the only honest quality measure.

**Why:** "The skill looks good" is not evidence. "An agent equipped with the skill performs measurably better" is evidence.

### 3.2 Baseline Comparison Protocol

**Setup:**
1. Define identical task set (same prompts, same source materials, same expected outcomes)
2. Run baseline (agent WITHOUT skill): capture activation, tools used, task completion, quality of output
3. Run treatment (agent WITH skill): capture same metrics
4. Compare: treatment vs baseline on same tasks

**Metrics to capture:**
- **Activation correctness:** Did skill activate on positive cases? Stay silent on negative controls?
- **Task completion:** Did agent complete the task? (Boolean, observable)
- **Quality of outcome:** If task completed, was the result correct? (External judge, not generating model)
- **Efficiency:** Token usage, runtime, command count (secondary metric)

**Pass criteria:**
- Treatment must outperform baseline on task completion rate
- Treatment must not increase false positive rate (activating on wrong prompts)
- Statistical significance required (e.g., p < 0.05 with appropriate sample size)

### 3.3 Current Implementation Status

**Layer 2 behavioral baseline comparison:**
- **Status:** Blocked pending Parker's quality ground truth definition (D-022)
- **Prior approach (removed):** `baseline_run: false` in traces, but baselines were never actually run — `task_completed: false` in all baseline records was placeholder data
- **Next step:** Define what baseline run looks like, capture real baselines, establish delta measurement

**Layer 3 pipeline benchmark:**
- **Status:** Implemented but winner criterion under audit
- **Current:** A/B comparison of claude vs codex pipelines using aggregated quality score
- **Audit question:** Is the winner criterion objective? Is it externally validated?
- **Guardrails exist:** structural pass rate ≥ 0.95, activation F1 ≥ 0.85, false positive rate ≤ 0.05, negative control ratio ≥ 0.25

---

## 4. Statistical Standards (Confidence Intervals, Sample Sizes, Uncertainty)

### 4.1 Core Principle: Results Without Uncertainty Quantification Are Not Results

**What we require:**
- Confidence intervals, not just point estimates (e.g., "quality score = 0.87 ± 0.04" at 95% CI)
- Sample size justification (power analysis for decision-grade comparisons)
- Inter-rater reliability when human judgment involved (Cohen's kappa or similar)
- Explicit "insufficient data" when sample too small to conclude

**What we reject:**
- Single-run "quality scores" without uncertainty bounds
- Comparisons without significance testing (is the difference real or noise?)
- Pass/fail verdicts without confidence level

### 4.2 Sample Size Requirements

**Minimum for behavioral evaluation:**
- Per-skill test cases: ≥ 15 activation cases, ≥ 5 negative controls
- Current: 39 test cases across 3 skills (cogworks: 8, cogworks-encode: 10, cogworks-learn: 21)

**Minimum for baseline comparison:**
- ≥ 10 identical tasks per condition (WITH skill, WITHOUT skill)
- Larger sample if outcome is noisy (e.g., LLM-as-judge scoring)

**Minimum for human ground truth reference set:**
- ≥ 3 reference skills per category, each graded by ≥ 2 independent human raters
- Inter-rater reliability (Cohen's kappa) ≥ 0.70 required

### 4.3 Confidence Intervals and Significance Testing

**For proportions (e.g., task completion rate):**
- Report with 95% confidence interval using Wilson score interval (handles small samples better than normal approximation)
- Example: "Task completion: 85% (95% CI: 72%-93%, n=20)"

**For continuous scores (e.g., quality ratings):**
- Report mean ± standard error or 95% CI
- Example: "Quality score: 0.87 ± 0.04 (95% CI, n=15)"

**For comparisons (WITH skill vs WITHOUT skill):**
- Report p-value and effect size (Cohen's d for continuous, risk ratio for binary)
- Significance threshold: p < 0.05
- Practical significance: effect size thresholds (small: d > 0.2, medium: d > 0.5, large: d > 0.8)

### 4.4 What `quality_score` Should Mean (Under Definition)

**Current state:** Field exists in behavioral trace template, always `null` for core skills. Quality was never operationally defined.

**Options under consideration:**
1. **Replace with multi-dimensional rubric:** source fidelity, decision utility, boundary quality, citation quality, context efficiency (weighted composite)
2. **Replace with behavioral delta:** (task_completion_rate_WITH_skill - task_completion_rate_WITHOUT_skill) / (1 - task_completion_rate_WITHOUT_skill) [normalized gain]
3. **Replace with cross-model consensus score:** average of 3+ independent model judgments (with inter-rater reliability threshold)

**Decision pending.** Parker's first deliverable is defining this field with measurement protocol.

---

## 5. Adversarial Testing Principles (Probing What the Generator Wouldn't Self-Report)

### 5.1 Core Principle: Test Cases Must Expose Hidden Failures

**The problem:** If test cases are designed by the same model (or person with same perspective) that produced the artifact, they'll miss blind spots.

**Solution:** Source test cases from outside the generating model's perspective:
- Contradictory source materials (does skill flag contradiction or silently pick one?)
- Context-dependent recommendations (does skill specify when/why, or overgeneralize?)
- Edge cases (single source, 5+ sources, minimal content, large dataset)
- Negative controls (prompts that SHOULD NOT activate skill)
- Security probes (command injection patterns, delimiter injection)

### 5.2 Adversarial Probe Categories

**Generalization probes (D8 anti-superficiality gates):**
- Contradictory sources: Skill must flag contradiction, not synthesize false consensus
- Context-dependent decisions: Skill must specify boundaries, not claim universality
- Distinct API endpoints: Skill must track source provenance, not merge incompatible patterns

**Negative controls (activation correctness):**
- Prompts semantically similar but out-of-scope
- Prompts mentioning skill domain but asking for different task
- Generic coding questions where skill adds no value
- **Pass criterion:** `negative_control_ratio >= 0.25` (≥25% of test cases are negative controls)

**Perturbation tests (robustness):**
- Source order shuffled: output should be invariant to ordering
- Source wording paraphrased: core decisions should be preserved
- Single source removed: skill should degrade gracefully, not fail catastrophically

**Security probes (deterministic gates):**
- Command injection patterns: `$(malicious)`, `; rm -rf /`
- Delimiter injection: literal `<<UNTRUSTED_SOURCE>>` in source content (neutralized via preprocessing, D-024)
- Path traversal patterns in file references

### 5.3 Test Case Design Protocol

**When creating new test cases:**
1. **Start with failure modes** — what could go wrong that the generator wouldn't notice?
2. **Design negative controls first** — these define the boundary
3. **Include deliberate ambiguity** — real-world sources are messy
4. **Vary difficulty** — mix trivial, medium, and adversarial cases
5. **Document expected behavior explicitly** — not just pass/fail, but WHY it should pass/fail

**Test case composition target:**
- 60% positive cases (should activate, should complete task)
- 25% negative controls (should NOT activate)
- 15% adversarial probes (contradictions, edge cases, security)

---

## 6. Current Assessment of Behavioral Trace Quality Measurement (Honest Audit)

### 6.1 What's Working

**Layer 1 (Structural/Deterministic):**
- ✅ Fast (< 1 second), no LLM calls, passes CI reliably
- ✅ Clear pass/fail criteria (exit 0 = pass, exit 1 = critical failure, exit 2 = warnings)
- ✅ Black-box tested against documented promises (meta-tests validate the validator)
- ✅ Limitation acknowledged: structure validity ≠ semantic correctness

**Test case definitions:**
- ✅ 39 human-authored test cases defining activation intent across 3 skills
- ✅ Mix of positive cases and negative controls
- ✅ Clear expected/forbidden content specifications
- ✅ Valid and retained after D-022 trace deletion

**Infrastructure:**
- ✅ `cogworks-eval.py` scaffold command works — can generate test case templates
- ✅ `behavioral_lib.py` validation logic exists — deterministic trace checking
- ✅ CI gate enforcement — exits non-zero on missing traces (D-021)

### 6.2 What's Not Working (Blocked or Under Audit)

**Layer 2 (Behavioral Traces):**
- ❌ **BLOCKED:** All 24 behavioral traces deleted (D-022) — they were circular ground truth
- ❌ Trace capture scripts deleted (D-023) — 9 scripts that generated circular traces
- ❌ `quality_score` field undefined — always `null` for core skills
- ❌ Baseline runs never actually executed — `baseline_run: false` in all traces, `task_completed: false` in baseline records (placeholder data, not real measurements)
- ❌ Behavioral evaluation (`cogworks-eval.py behavioral run`) outputs exist but measure consistency, not correctness
- ⚠️ Pending reconstruction: Parker defining replacement quality ground truth from first principles

**Layer 3 (Pipeline Benchmark A/B):**
- ⚠️ **UNDER AUDIT:** Winner criterion exists but objectivity not validated
- ⚠️ Real-mode vs offline-mode distinction clear, but what makes real-mode "decision-grade" needs statistical backing
- ⚠️ Quality score aggregation (weighted composite) uses weights that were tuned, not externally validated
- ⚠️ Guardrails exist (structural pass rate, activation F1) but thresholds need power analysis justification

### 6.3 Next Steps (Parker's Mandate)

**Immediate priorities:**
1. **Define `quality_score` from first principles** — operationalize quality as measurable, reproducible, non-circular construct
2. **Design baseline comparison protocol** — agent WITH skill vs WITHOUT skill on identical tasks
3. **Select cross-model judging approach** — different model, human ground truth, or multi-model consensus
4. **Statistical validity plan** — sample sizes, confidence intervals, significance testing
5. **Adversarial probe design** — test cases exposing what generating model wouldn't self-report

**Deliverable format:**
- Protocol document: what is measured, how it's measured, who judges, sample size
- Reference implementation: scripts for capturing baselines and running comparisons
- Validation: demonstration that new approach is NOT circular (generating model ≠ judging model)
- Statistical report: confidence intervals, p-values, effect sizes — not just pass/fail

**What doesn't change:**
- Test case definitions (already valid, human-authored)
- Layer 1 deterministic checks (validity gates, out of scope for quality audit)
- Test framework structure (Hudson owns harness; Parker owns what it measures)

---

## 7. Prompt for Other Teams: Adopting These Standards

**If you want to build TDD testing at this quality level, answer these questions first:**

### 7.1 Quality Definition

- **Q1:** Is your test measuring consistency (does run N match run N-1?) or correctness (is the output actually right)?
- **Q2:** Who defines "good"? If it's the same system that produces the artifact, you have circular measurement.
- **Q3:** Can you define expected behavior without running the system? (If no, you don't have independent ground truth.)

### 7.2 External Validation

- **Q4:** If Model A generated the artifact, who judges it? If the answer is "Model A", you're measuring self-consistency, not quality.
- **Q5:** Do you have human-graded reference examples? (Minimum: 3 per category, 2 raters each, inter-rater reliability ≥ 0.70)
- **Q6:** Can you specify observable behaviors deterministically? (Commands run, files created, sequence ordering — no LLM judgment required)

### 7.3 Baseline Comparison

- **Q7:** What is your WITH/WITHOUT comparison? (If you don't have baselines, you can't measure improvement.)
- **Q8:** Are your baselines real measurements or placeholder data? (Check your traces — if `task_completed: false` in all baselines, they're not real.)
- **Q9:** What metrics differentiate WITH from WITHOUT? (Task completion rate, quality score, efficiency — specify and measure.)

### 7.4 Statistical Validity

- **Q10:** What's your sample size? (If < 10 per condition, you don't have statistical power.)
- **Q11:** Do your results have confidence intervals? (Single-number "quality scores" without uncertainty bounds are not results.)
- **Q12:** When you report "X is better than Y", what's the p-value and effect size? (Without significance testing, "better" is anecdotal.)

### 7.5 Adversarial Probing

- **Q13:** What test cases would the generating model NOT think to include? (If all tests are "happy path", you're not probing blind spots.)
- **Q14:** What's your negative control ratio? (If < 25%, your tests don't validate activation boundaries.)
- **Q15:** Do you have contradiction/edge-case/security probes? (Real quality measurement requires adversarial thinking.)

### 7.6 честness Check (Meta-Test)

- **Q16:** If you deleted all your test traces and re-captured them, would the "quality score" change? (If yes, your ground truth is a snapshot, not a standard.)
- **Q17:** If a different team implemented your measurement protocol, would they get the same results? (If no, it's not reproducible.)
- **Q18:** Can you show a failure case where your tests caught a real quality problem? (If no examples, your tests may be passing everything.)

---

## 8. Key Learnings (What We Got Wrong and Fixed)

### 8.1 Circular Ground Truth (D-022)

**What we did wrong:**
- Captured LLM-generated traces as "ground truth"
- Used those traces to evaluate future LLM runs
- `quality_score: null` on all traces — quality was never defined

**How we detected it:**
- Audit question: "If the skill consistently produces wrong output, would our tests catch it?" Answer: No.
- Every trace passed because we were measuring consistency with past runs, not correctness

**How we fixed it:**
- Deleted all 24 circular traces (git history is recovery path)
- Deleted 9 capture scripts that generated them
- CI gate blocks regeneration with clear error message
- Defined Parker's mandate: quality ground truth from first principles

### 8.2 Baseline Runs Never Executed (D-022 Analysis)

**What we did wrong:**
- Claimed to have "baseline vs treatment" comparison
- `baseline_run: false` in all traces
- `task_completed: false` in baseline records — not real measurements, placeholder data

**How we detected it:**
- Code review of trace templates and capture scripts
- No evidence of actual baseline runs in git history
- Test cases never specified baseline behavior, only treatment behavior

**How we fixed it:**
- Acknowledged in documentation: baseline comparison was aspirational, not implemented
- Parker's mandate includes designing and implementing real baseline protocol

### 8.3 Quality Score Field Undefined (Ongoing)

**What we did wrong:**
- Added `quality_score` field to trace schema
- Never defined what it should contain
- Set to `null` for all core skill traces — shipped with empty field

**How we detected it:**
- Field exists in template, always `null` in actual traces
- No measurement protocol documented
- No agreement on what "quality" means operationally

**How we're fixing it:**
- Parker's first deliverable: define `quality_score` with measurement protocol
- Options: multi-dimensional rubric, behavioral delta, cross-model consensus
- Requirement: statistical validity (confidence intervals, not single number)

### 8.4 CI Gate That Never Failed (D-021)

**What we did wrong:**
- CI gate checked for behavioral traces
- Missing traces produced warning but exited 0 — structurally a no-op
- Gate could never fail on trace coverage

**How we detected it:**
- Hudson audit: "A quality gate that never fails isn't a gate"
- Releases shipped with zero behavioral validation despite "gate" existing

**How we fixed it:**
- Updated `tests/ci-gate-check.sh` to exit 1 on missing traces
- Error message points to trace capture command and Parker's mandate
- Gate now blocks merges when traces missing (but traces are intentionally missing until Parker defines replacement)

---

## 9. References and Further Reading

### 9.1 Internal Documentation

- [TESTING.md](../../TESTING.md) — Three-layer testing framework overview
- [_plans/DECISIONS.md](../../_plans/DECISIONS.md) — Team decisions (D-022: circular traces deleted, D-023: capture scripts deleted, D-021: CI gate enforcement)
- [.squad/agents/parker/charter.md](.squad/agents/parker/charter.md) — Parker's mandate and responsibilities
- [.squad/agents/hudson/charter.md](.squad/agents/hudson/charter.md) — Hudson's test infrastructure ownership
- `tests/framework/README.md` — Framework command reference
- `tests/datasets/recursive-round/README.md` — Recursive improvement loop runbook

### 9.2 External Sources (Informing Our Approach)

**TDD workflow and philosophy:**
- Kent Beck, "Canon TDD" — test list, red-green-refactor, two-hats separation
- Martin Fowler, "Test Driven Development" — refactoring as key failure point
- Uncle Bob, "The Cycles of TDD" — nano/micro/meso cycle structure

**Test design quality:**
- Google SWE Book, Chapter 12 — test behaviors not methods, DAMP vs DRY, public API testing
- Testing on the Toilet: "Test Behaviors, Not Methods" — single-behavior scope
- Khorikov, "Unit test naming policies" — diagnostic clarity over format rigidity

**Evidence base for TDD adoption:**
- Nagappan et al., "Realizing quality improvement through TDD" (2008) — industrial defect density data
- Bissi et al., systematic review (2016) — quality gains, productivity variability
- Meta-analysis (2012) — small quality effect, neutral productivity

**Observable behavior grounding:**
- OpenAI evals reference — execution trace emphasis, behavior over text
- SkillsBench efficacy testing — baseline comparison, activation + efficacy delta

**Statistical validity:**
- Standard practice: Wilson score interval for proportions, confidence intervals for means
- Inter-rater reliability: Cohen's kappa for human judgments
- Effect size: Cohen's d for continuous outcomes, risk ratio for binary

---

## 10. Contact and Feedback

**Maintained by:** Parker (Benchmark & Evaluation Engineer, cogworks team)

**Questions or feedback:** Submit via `.squad/decisions/inbox/parker-{slug}.md` or direct conversation with Parker in active sessions.

**Version:** 2026-03-05 (initial synthesis following D-022/D-023 trace deletion and quality measurement audit)

**Status:** Living document. Parker updates as quality measurement protocol evolves.

---

**END OF DOCUMENT**
