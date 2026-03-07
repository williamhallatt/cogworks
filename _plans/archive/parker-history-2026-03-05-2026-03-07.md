# Parker — Project History

## Session: 2026-03-05 — TDD Quality Standards Documentation

### Task
Document the team's testing quality definition and evaluation standards for external teams learning TDD practices.

### Context Gathered
- Reviewed `.squad/agents/parker/charter.md` — core mandate and quality measurement philosophy
- Reviewed `_plans/DECISIONS.md` — D-022 (circular traces deleted), D-023 (capture scripts deleted), D-021 (CI gate enforcement), D-024 (delimiter preprocessing)
- Reviewed `TESTING.md` — three-layer framework (structural, behavioral, pipeline benchmark)
- Reviewed semantic search results on TDD sources, behavioral evaluation, quality measurement
- Reviewed test framework scripts (`cogworks-eval.py`, `behavioral_lib.py`)
- Reviewed test case definitions (`tests/behavioral/*/test-cases.jsonl`)

### Key Findings

**Circular testing problem (D-022):**
- Prior behavioral traces were LLM-generated outputs used as ground truth for future LLM runs
- `quality_score: null` on all core skill traces — quality never operationally defined
- `task_completed: false` in baseline runs — placeholder data, not real measurements
- Validated consistency (run N matches run N-1) not correctness (is output actually right)

**Three-layer framework:**
- Layer 1 (structural/deterministic) — working, fast, passes CI reliably
- Layer 2 (behavioral traces) — blocked pending Parker's quality ground truth definition
- Layer 3 (pipeline benchmark) — exists but winner criterion under audit for objectivity

**Test case definitions:**
- 39 human-authored test cases across 3 skills (cogworks: 8, cogworks-encode: 10, cogworks-learn: 21)
- Valid and retained after trace deletion — define activation intent, not ground truth
- Mix of positive cases and negative controls

**Statistical validity gaps:**
- No confidence intervals on quality scores (single-number estimates)
- No sample size justification or power analysis
- Inter-rater reliability not calculated where human judgment involved

**Cross-model independence:**
- Acknowledged as critical principle in charter
- Not implemented in deleted traces (same model generated and evaluated)
- Multiple approaches available: different model as judge, human ground truth, multi-model consensus

### Deliverable Created

**File:** `.squad/agents/parker/tdd-quality-standards.md`

**Structure:**
1. What makes a test "good"? — External ground truth, behavior measurement, deterministic-first, single-behavior scope
2. How to avoid circular testing — Cross-model independence, judging protocols
3. Baseline comparison approach — Agent WITH skill vs WITHOUT skill behavioral delta
4. Statistical standards — Confidence intervals, sample sizes, significance testing
5. Adversarial testing principles — Generalization probes, negative controls, perturbation tests
6. Current assessment — Honest audit of what's working and what's blocked
7. Prompt for other teams — 18 questions to answer before claiming TDD quality
8. Key learnings — What we got wrong and how we fixed it (D-022, D-023, D-021)
9. References — Internal docs and external sources informing approach
10. Contact and feedback section

**Tone:** Skeptical and precise. No softening. Explicit about failures and pending work.

### Architectural Decisions

**Quality measurement principles:**
- Tests must measure correctness, not consistency
- External ground truth required (human-authored, cross-model, or observable behavior)
- Baseline comparison is only honest quality signal (WITH skill vs WITHOUT skill)
- Statistical validity non-negotiable (confidence intervals, sample sizes, p-values)
- Adversarial probes required to expose blind spots

**Three-layer gate sequence:**
- Validity → Behavior → Quality (deterministic first, probabilistic second)
- Layer 1 out of scope for Parker's audit (validity, not quality)
- Layer 2 blocked pending Parker's protocol design
- Layer 3 under audit for winner criterion objectivity

**Test quality criteria:**
1. External ground truth (not self-referential)
2. Behavior measurement over text quality
3. Deterministic checks before LLM-as-judge
4. Single-behavior scope per test
5. Public API testing (not implementation coupling)
6. Non-flaky by design

### Key File Paths

**Testing infrastructure:**
- `tests/framework/scripts/cogworks-eval.py` — behavioral evaluation scaffold and benchmark commands
- `tests/framework/scripts/behavioral_lib.py` — trace validation logic
- `tests/framework/graders/deterministic-checks.sh` — Layer 1 structural checks
- `tests/ci-gate-check.sh` — pre-release quality gate (exits 1 on missing traces)

**Test definitions:**
- `tests/behavioral/cogworks/test-cases.jsonl` — 8 test cases
- `tests/behavioral/cogworks-encode/test-cases.jsonl` — 10 test cases
- `tests/behavioral/cogworks-learn/test-cases.jsonl` — 21 test cases
- `tests/framework/templates/behavioral-trace-template.json` — trace schema (quality_score undefined)

**Benchmark infrastructure:**
- `benchmarks/comparison/scripts/test-cogworks-pipeline.sh` — A/B pipeline comparison

---

## Decisions Made

- 2026-03-05: TDD Quality Standards Documentation (completed)
- 2026-03-05: quality_score Field Definition and Schema Versioning (schema defined, implementation pending)

## Work Products

- 2026-03-05: `.squad/agents/parker/tdd-quality-standards.md` — Comprehensive quality evaluation standards
- 2026-03-05: Quality schema definition (`tests/framework/QUALITY-SCHEMA.md` expected)

---

**Last updated:** 2026-03-05T00:46:55Z by Scribe
- `benchmarks/comparison/scripts/test-generator-comparison.sh` — multi-comparator benchmark
- `benchmarks/comparison/scripts/run-protocol-benchmark.sh` — workflow toolkit protocol runner
- `tests/datasets/recursive-round/README.md` — recursive improvement loop runbook

**Documentation:**
- `TESTING.md` — three-layer framework overview
- `_plans/DECISIONS.md` — settled team decisions
- `.squad/agents/parker/charter.md` — Parker's mandate
- `.squad/agents/hudson/charter.md` — Hudson's test infrastructure ownership

### User Preferences

- Prefer skeptical, evidence-based tone over reassurance
- Explicit acknowledgment of failures and pending work
- Statistical validity required (confidence intervals, not single numbers)
- Cross-model independence non-negotiable
- Baseline comparison (WITH vs WITHOUT) is honest quality signal

### Patterns

**Documentation structure for quality standards:**
- Start with principles (what makes X good?)
- Provide anti-patterns (what we got wrong, how we detected, how we fixed)
- Give concrete prompts/questions for others to self-assess
- Reference internal and external sources
- Be explicit about what's working vs blocked vs under audit

**Quality audit approach:**
- Audit from first principles ("what should this measure?") not current state
- Authority to reject measurement as invalid without implementing fix
- Deliverable format: what measured, how measured, result with uncertainty, team implications
- Statistical validity required: confidence intervals, sample sizes, inter-rater reliability

**Three-layer testing gate sequence:**
- Layer 1 (validity): deterministic, fast, no LLM calls
- Layer 2 (behavior): activation correctness, WITH/WITHOUT comparison
- Layer 3 (quality): cross-pipeline A/B, decision-grade vs smoke mode distinction

---

## Learnings

### Process Insights

1. **Circular testing is easy to miss** — if the system under test also defines "good", you're measuring self-consistency
2. **`quality_score: null` is honest** — shipping with empty field better than shipping with circular measurement
3. **Baseline runs are hard** — claiming to have baselines vs actually capturing them are different things
4. **Statistical validity requires discipline** — confidence intervals, sample sizes, significance tests don't happen by default
5. **Cross-model independence is non-negotiable** — if Model A judges Model A's output, it's not external validation

### Anti-Patterns Identified

1. **LLM-generated ground truth** — traces captured from runs, used to evaluate future runs (consistency, not correctness)
2. **Placeholder baseline data** — `baseline_run: false`, `task_completed: false` in all records (not real measurements)
3. **Undefined quality fields** — shipping with `quality_score: null` because quality never operationally defined
4. **Gates that never fail** — CI check that warns but exits 0 (structurally a no-op)
5. **Aggregated "quality scores" without uncertainty** — single numbers without confidence intervals

### Decision Rules

1. **External ground truth required** — human-authored, cross-model judged, or observable behavior specification
2. **Validity gates before quality gates** — deterministic structural checks first, behavioral checks second, LLM-as-judge last
3. **Baseline comparison is the signal** — agent WITH skill vs WITHOUT skill on identical tasks
4. **Statistical validity non-negotiable** — report confidence intervals, sample sizes, p-values, effect sizes
5. **Adversarial probes required** — contradictions, edge cases, negative controls, security patterns

### Technical Patterns

**Test case structure:**
- `id`, `category`, `user_request`, `should_activate`, `expected_content`, `forbidden_content`, `notes`
- Positive cases (should activate), negative controls (should NOT activate), adversarial probes

**Trace schema:**
- `skill_slug`, `case_id`, `activated`, `tools_used`, `commands`, `files_modified`, `task_completed`, `quality_score`, `baseline_run`, `pipeline`, `model`, `captured_at`
- `quality_score` currently `null` — under definition
- `baseline_run` distinguishes baselines from treatments (but baselines never actually captured in deleted traces)

**Quality measurement protocol (pending):**
1. Define quality independently of generating model
2. Select judging approach (cross-model, human, consensus, observable behavior)
3. Design baseline comparison (WITH vs WITHOUT on identical tasks)
4. Statistical validity (sample sizes, confidence intervals, significance tests)
5. Adversarial probes (expose blind spots)

---

## Next Actions (Parker's Pending Work)

1. **Define `quality_score` operationally** — multi-dimensional rubric, behavioral delta, or cross-model consensus?
2. **Design baseline comparison protocol** — what tasks, how many runs, how to capture baselines
3. **Select cross-model judging approach** — different model as judge, human ground truth, or multi-model consensus
4. **Statistical validity plan** — sample size requirements, confidence interval calculation, significance testing
5. **Adversarial probe design** — test cases exposing what generating model wouldn't self-report
6. **Reference implementation** — scripts for capturing baselines and running comparisons
7. **Validation demonstration** — proof that new approach is NOT circular (generating model ≠ judging model)
