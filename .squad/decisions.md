# Cogworks Squad Decisions

> Scope warning: this is Squad-local coordination memory, not the repo-wide decision ledger. For canonical project decisions, load `_plans/DECISIONS.md` first.

Consolidated decision record for cross-agent coordination and architectural choices.

**Last audited:** 2026-03-13
**Audited by:** Scribe (post-deep-dive sync)

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

---

## Repo-Level Decisions Affecting Squad Work (D-037 through D-042)

> **Canonical source:** `_plans/DECISIONS.md`. These are cross-references only — do not duplicate full content here.

| Decision | Date | Summary | Squad Impact |
|----------|------|---------|-------------|
| **D-037** | 2026-03-06 | Cogworks resets to one trust-first product entry point | Single `cogworks` invocation; encode/learn are internal doctrine. Changes routing and onboarding. |
| **D-038** | 2026-03-07 | Test surface subtraction removes dead contracts | Test layers renumbered; some inbox proposals may reference stale test surfaces. |
| **D-039** | 2026-03-07 | Public docs state surface support boundaries explicitly | Platform matrix (Claude ✅, Copilot ✅, Codex portable-only). Affects Lambert's adapter work. |
| **D-040** | 2026-03-08 | AGENTS.md defines staged retrieval with stop rules | All agents follow retrieval contract. Non-default surfaces not auto-loaded. |
| **D-041** | 2026-03-08 | Closed plans retained as extracted decisions only | Plans lifecycle is atomic (save → extract → delete). Affects Scribe's archival protocol. |
| **D-042** | 2026-03-09 | Dispatch manifests record canonical stage scope | Native sub-agents bound via dispatch-manifest.json rendered from role-profiles.json. |

**Last synced:** 2026-03-13

---

## Pending Proposals (2026-03-08 Fan-Out Session)

> **Status:** Triaged 2026-03-13. Verdicts applied to inbox files. 3 ACCEPT, 2 ACCEPT WITH REVISIONS, 1 PARTIALLY SUPERSEDED. See individual files for detailed verdicts.

---


### Proposal 1: Ripley — Post-Review Implementation Roadmap

**Date:** 2026-03-08  
**Author:** Ripley (Lead)  
**Status:** Proposal  

**Summary:** Comprehensive remediation roadmap organizing 10 identified issues into 4 tiers (P0-P3) based on risk × value × dependency blocking. P0 items (decision skeleton spec, terminology glossary, security hardening) block trust and downstream work. P1 items (Copilot adapter, error path testing, Codex decision) block adoption. P2 items (production benchmark, behavioral eval reconstruction) improve operational quality. P3 items are cleanup/deferred. Total estimated effort: ~14-20 weeks with significant parallelization.

**Key Decisions Required:**
- Accept P0-P2 roadmap in sequence
- Codex adapter decision: defer (Option B), implement (Option A), or drop (Option C)
- Sequencing: Weeks 1-2 spec hardening → Weeks 3-4 security/foundation → Weeks 5-6 validation → Weeks 7-8 quality infrastructure

**File:** `.squad/decisions/inbox/ripley-post-review-roadmap.md` (356 lines)

---

### Proposal 2: Dallas — Pipeline Solutions (3 Ownership Gaps)

**Date:** 2026-03-08  
**Author:** Dallas (Pipeline Engineer)  
**Status:** Proposal  

**Summary:** Three specification ownership gaps with concrete solutions:
1. **Decision Skeleton Ownership** — Assign to `composer` role in skill-packaging stage; update role-profiles.json, agentic-runtime.md, SKILL.md, adapters; formalize 5-7 entry quality gate.
2. **Copilot Adapter Underspecification** — Add runtime capability detection, inherit-session-model fallback, inline binding resolution, degraded mode spec.
3. **Comparison Tooling Consolidation** — Deprecate run-agentic-quality-compare.py; extend run-skill-benchmark.py via datasets and flexible config.

**Key Decisions Required:**
- Accept all three solutions; Dallas implements in parallel with Ripley's P0 hardening
- Order: Skeleton ownership first (unblocks everything), then adapter completion, then tooling consolidation

**File:** `.squad/decisions/inbox/dallas-pipeline-solutions.md` (510 lines)

---

### Proposal 3: Parker — Benchmark Strategy (2 Major Gaps)

**Date:** 2026-03-08  
**Author:** Parker (Benchmark & Evaluation)  
**Status:** Proposal  

**Summary:** Two evidence gaps addressed:
1. **First Real Benchmark Run** — Execute legacy vs agentic comparison with 15-case dataset (invoked-task, hard-negative, boundary). Cross-model judge (GPT/Gemini). 5 trials per case. Phase 1-4 execution plan over 5-7 days.
2. **Behavioral Evaluation Reconstruction** — Two-track architecture: Activation track (deterministic, observable behavior) runs in CI; Efficacy track (cross-model judge, WITH vs WITHOUT baseline) runs manually. Replaces D-022 deleted circular traces with non-circular protocol.

**Key Decisions Required:**
- Accept benchmark methodology; approve dataset authorship (Parker scaffolds, William reviews?)
- Approve efficacy track scope (2-3 weeks per track after judge calibration)
- Cross-model judge availability and cost budget

**File:** `.squad/decisions/inbox/parker-benchmark-strategy.md` (460 lines)

---

### Proposal 4: Hudson — Error Path Testing Design

**Date:** 2026-03-08  
**Author:** Hudson (Test Infrastructure)  
**Status:** Proposal  

**Summary:** Comprehensive error path testing strategy for agentic engine addressing gap: success paths validated, error/recovery paths untested. Designs 8 scenarios:
1. Contradictory source inputs (escalation)
2. Missing stage artifacts (stop and emit failed status)
3. Stage failure + retry
4. Fallback to single-agent
5. Invalid dispatch manifest
6. Context overflow
7. Tool degradation
8. Blocking rule violations

Each scenario has fixture specs, expected behaviors, validation criteria. Implementation plan: deterministic error corpus (27 cases), behavioral error traces, recovery validation, CI regression gate.

**Key Decisions Required:**
- Accept error path design; Hudson implements 2-week project
- Prioritize which scenarios block P1 vs can defer to P2

**File:** `.squad/decisions/inbox/hudson-error-path-testing.md` (699 lines)

---

### Proposal 5: Lambert — Terminology Glossary + Codex Adapter

**Date:** 2026-03-08  
**Author:** Lambert (Compatibility Engineer)  
**Status:** Proposal  

**Summary:** Two cross-specification coordination gaps:
1. **Terminology Glossary** — Same concepts have different names across specs ("contradiction" vs "conflicting guidance", undefined terms like "synthesis fidelity", "brittle execution"). Solution: Canonical glossary document (`docs/agentic-terminology.md`) with single definition per term, cross-references in all specs.
2. **Codex Adapter Decision** — Three options: (A) Full production (2-3 weeks), (B) Benchmark-only (simpler), (C) Defer/remove. Recommendation: Option B for near-term.

**Key Decisions Required:**
- Approve glossary priority (P0 blocker for Ash/Dallas implementations)
- Codex adapter decision (B recommended but user may prefer A/C)

**File:** `.squad/decisions/inbox/lambert-terminology-codex.md` (424 lines)

---

### Proposal 6: Ash — Agentic Dispatch Security Hardening

**Date:** 2026-03-08  
**Author:** Ash (Security & Hardening)  
**Status:** Proposal  

**Summary:** Comprehensive security hardening for agentic dispatch (P0 priority). Threat surface: untrusted source injection, stage output tampering, cross-agent privilege escalation, model API response poisoning. Hardening layers:
1. Input validation — Strict schema enforcement on inter-stage contracts
2. Artifact integrity — Cryptographic signatures on intermediate outputs
3. Dispatch isolation — Privilege separation between stages
4. Output verification — Deterministic checks on model responses

Timeline: 1 week for P0 core (input validation + integrity), 2-3 weeks for full suite.

**Key Decisions Required:**
- Accept security hardening as P0; Ash leads implementation
- Phasing: core (Week 3-4) then full suite (Weeks 5-8)

**File:** `.squad/decisions/inbox/ash-agentic-security.md` (410 lines)

---

## Proposal Coordination Notes

**Fan-out context:** All 6 agents analyzed their problem domains and proposed concrete solutions in response to Ripley's comprehensive post-review roadmap. No conflicts detected; dependency graph is acyclic:

- **Dallas's skeleton fix** is P0 blocker for Ash's security hardening
- **Lambert's glossary** is prerequisite for Ash and Dallas implementations
- **Parker's behavioral eval** depends on D-026 quality schema (not proposal, already settled)
- **Hudson's error paths** integrate with Parker's evaluation harness
- **Ripley's roadmap** informs sequencing for all others

**Next step:** User reviews inbox + proposals → approves subset → assigns owners → Phase 1 begins.

