# Parker — Project History

## Decision Rules

1. **External ground truth required** — human-authored, cross-model judged, or observable behavior specification
2. **Validity gates before quality gates** — deterministic structural checks first, behavioral checks second, LLM-as-judge last
3. **Baseline comparison is the signal** — agent WITH skill vs WITHOUT skill on identical tasks
4. **Statistical validity non-negotiable** — report confidence intervals, sample sizes, p-values, effect sizes
5. **Adversarial probes required** — contradictions, edge cases, negative controls, security patterns

## Pending Work

See charter `## Working Context` for current priorities.

## Key References

- `_plans/DECISIONS.md` D-026 — quality ground truth protocol
- `_plans/DECISIONS.md` D-030 — skill benchmark harness
- `_plans/DECISIONS.md` D-031 — recursive round tooling
- `tests/framework/QUALITY-SCHEMA.md` — quality measurement schema

## Learnings

### 2026-03-08: Benchmark Strategy Proposals

**Context:** Comprehensive review identified two critical gaps — no real benchmark run published, and behavioral evaluation deleted but not reconstructed.

**What I learned:**

1. **Specifications without execution are liabilities** — The benchmark harness is 748 lines of production-ready code. Four schemas are validated. Pilot smoke tests pass. Research justification spans evaluation literature from OpenAI, Anthropic, SWE-bench, HELM. Yet zero skill comparisons have been published. A specification that never runs is a maintenance burden masquerading as capability.

2. **The agentic pivot depends on benchmark evidence it hasn't generated** — D-027/D-028/D-029 built a 5-stage agentic runtime with canonical role specs and dual-surface adapters. The entire architectural justification is "agentic produces better skills." That claim is untested. One smoke run with trivial fixtures on the happy path is not proof. The benchmark harness exists to answer this question — it hasn't been asked yet.

3. **Legacy vs agentic comparison is the highest-value first benchmark** — Not because it's easy (it's not), but because it's the decision the repo needs most urgently. The agentic engine consumes more latency and cost (D-028 acknowledges this). If it doesn't improve quality, it's net-negative architecture. The benchmark dataset should force discrimination: simple cases (does basic synthesis work?), moderate cases (does multi-source synthesis work?), complex cases (contradictions, entity boundaries), hard negatives (graceful rejection), and boundary cases (adversarial probes, delimiter injection).

4. **15 cases × 5 trials is the minimum viable benchmark** — Fewer cases can't cover the category mix (invoked-task, hard-negative, boundary). Fewer trials yield confidence intervals too wide for decisions. The pilot proved the harness works with synthetic data — real cases are the only remaining blocker. This is a dataset authorship problem, not an infrastructure problem.

5. **Cross-model judge calibration is non-negotiable** — D-026 mandates different model families for generator and judge (Claude ≠ GPT ≠ Gemini). Before production runs, the judge must be calibrated against human labels (target: inter-rater reliability ≥ 0.70). Without calibration, judge outputs are unvalidated opinions. With calibration, they're evidence.

6. **Behavioral evaluation and skill benchmarks serve different purposes** — Behavioral evaluation answers "does this skill improve behavior?" (single skill, WITH vs WITHOUT baseline). Skill benchmarks answer "which skill is better?" (two skills, paired comparison). The former validates individual skills; the latter decides between architectures. Both require cross-model judges. Both require repeated trials. They share methodology but not datasets or runner contracts.

7. **Deterministic checks must carry 70% of the weight** — Judge-based scoring is expensive, potentially biased (position, verbosity, self-preference per LMSYS research), and hard to debug. Deterministic checks (file existence, schema validation, trace assertions, Layer 1 validators) are cheap, reproducible, and incorruptible. Judges should resolve residual qualitative criteria only — correctness/completeness/synthesis fidelity where no executable oracle exists.

8. **Activation and efficacy are orthogonal failure modes** — A skill can activate correctly but harm task outcomes (efficacy failure). A skill can improve outcomes when invoked but never trigger (activation failure). Collapsing both into one scalar obscures what needs fixing. Behavioral evaluation should report separate scorecards: activation (precision/recall/false positives) and efficacy (behavioral delta with CI). The benchmark harness already encodes this separation (D-030).

9. **Baseline runs are harder than they sound** — "Agent without skill" is conceptually simple but operationally tricky. How do you ensure the skill is truly absent? Clean agent install? Symlink removal? Environment variable override? If baseline setup is unreliable, behavioral delta is meaningless. This needs explicit documentation in runner scripts before efficacy evaluation can be trusted.

10. **The sequencing is benchmark → activation → efficacy** — Legacy vs agentic benchmark is most urgent (unblocks architectural decision). Activation track reconstruction is lower risk (deterministic, no judge). Efficacy track reconstruction is highest complexity (cross-model judge, baseline runs, statistical validity). Judge calibration from the benchmark can be reused for efficacy evaluation. This is a 7-8 week critical path, not a single sprint.

**Proposals delivered:**
- `.squad/decisions/inbox/parker-benchmark-strategy.md` — concrete strategies for first benchmark run and behavioral evaluation reconstruction
- 15-case dataset specification (8 invoked-task, 4 hard-negative, 3 boundary)
- Step-by-step execution plan (dataset creation, judge calibration, benchmark run, analysis)
- Two-track behavioral evaluation architecture (activation = deterministic, efficacy = cross-model judge)
- Risk/mitigation analysis for both proposals
- Sequencing recommendations with 7-8 week timeline

**Open questions flagged:**
- Dataset authorship ownership
- Judge API access and cost budget
- Baseline environment setup protocol
- Calibration labeling resourcing
- Failure mode decision protocol if agentic loses benchmark

**Next actions (pending approval):**
- Author 15 benchmark cases with source materials
- Calibrate judge on 3 human-labeled reference cases
- Execute first legacy vs agentic benchmark run
- Publish benchmark summary and decision (D-NNN)

**2026-03-08 — Post-Review Fan-Out (Benchmark Strategy)**

Parker proposed legacy vs agentic benchmark execution plan + behavioral eval reconstruction strategy addressing evidence gap (no published comparisons, deleted circular traces). Two-track eval architecture (activation deterministic, efficacy cross-model judge) designed. Parker proposals consolidated into decisions.md pending approval.

**Cross-references:** Ripley prioritized issues (benchmark P2); Hudson's error paths integrate with Parker's eval harness. Dallas/Lambert specs must stabilize before benchmark author.

