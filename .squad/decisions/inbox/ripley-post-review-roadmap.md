# Post-Review Implementation Roadmap
**Author:** Ripley (Lead)  
**Date:** 2026-03-08  
**Status:** Proposal  

## Executive Summary

The comprehensive review of commits b6208ff forward reveals **well-engineered foundations with a critical evidence gap**. The agentic runtime specification, benchmark design, and validation infrastructure are production-grade. The problem: specifications outpace validation. One trivial smoke run, no behavioral evaluation, no production benchmark, no error path testing.

**Strategic assessment:** The architecture is sound. What was built badly can be fixed surgically. What must still be built is the right next step. What should not have been built is low-noise deletions.

## Prioritization Framework

I'm organizing remediation into four tiers based on **risk × value × dependency blocking**:

- **P0 (Critical):** Blocks trust in the system, creates security exposure, or prevents any downstream work
- **P1 (Important):** Blocks portability, adoption, or operational confidence
- **P2 (Valuable):** Improves quality but system functions without it
- **P3 (Defer/Drop):** Low value-to-effort ratio or premature optimization

## P0: Critical — Blocks Trust & Security

### 1. Decision Skeleton Specification Gap [FIX THE SPEC]
**Owner:** Ripley + Ash  
**Effort:** 2-3 hours  
**Dependencies:** None

**Problem:** Decision skeleton is specified in SKILL.md but has no formal owner in role-profiles.json, no creation trigger in agentic-runtime.md, no quality gate. The smoke run shows it happening implicitly in skill-packaging stage — this must be explicit.

**Fix:**
- Assign decision skeleton creation to `composer` role in role-profiles.json
- Add decision skeleton quality gate to deterministic-validation stage
- Specify 5-7 entry requirement and format constraints in agentic-runtime.md
- Update claude-adapter.md to include skeleton guidance in coordinator prompting

**Success criteria:** Any contributor can read the spec and know who creates the skeleton, when, and what constitutes valid output.

**Risk if unfixed:** Core intermediate artifact has ambiguous ownership; different adapters may implement differently.

### 2. Terminology Glossary [FIX THE SPEC]
**Owner:** Ripley + Scribe  
**Effort:** 4-6 hours  
**Dependencies:** None (parallel with #1)

**Problem:** Same concepts have different names across specification files:
- "contradiction" (SKILL.md) vs "conflicting guidance" (agentic-runtime.md)
- "synthesis fidelity" (agentic-runtime.md) — used but never defined
- "brittle execution" (claude-adapter.md) — used but never defined
- Escalation criteria differ slightly between SKILL.md and agentic-runtime.md

**Fix:**
- Create `skills/cogworks/glossary.md` with canonical term definitions
- Standardize terminology across SKILL.md, agentic-runtime.md, claude-adapter.md, copilot-adapter.md
- Add glossary references to all specification files
- Include escalation trigger checklist in glossary

**Success criteria:** Each critical term has one definition, used consistently across all specs.

**Risk if unfixed:** AI agents interpreting specs may misinterpret intent due to terminological drift.

### 3. Agentic Dispatch Security Hardening [BUILD THE THING]
**Owner:** Ash  
**Effort:** 1 week  
**Dependencies:** #1 (decision skeleton spec)

**Problem:** Source-intake stage dispatches raw user content to cogworks-intake-analyst without explicit untrusted-data classification gate. Ash's charter already identifies this (D2 extension).

**Build:**
- Add explicit trust boundary classification in source-intake stage
- Implement untrusted content sanitization before specialist dispatch
- Add trust-level metadata to source-inventory.json
- Update role-profiles.json with trust-handling guidance for intake-analyst
- Add test fixtures with injection-attempt source material

**Success criteria:** 
- Untrusted sources cannot inject instructions that affect stage execution
- Trust classification is recorded in source-inventory.json for audit
- Test fixtures prove resilience to prompt injection attempts

**Risk if unfixed:** Pre-condition blocker for shipping agentic engine to third-party surfaces.

## P1: Important — Blocks Portability & Adoption

### 4. Copilot Adapter Completion [FIX THE SPEC]
**Owner:** Dallas + Lambert  
**Effort:** 1 week  
**Dependencies:** #1, #2 (terminology must be stable first)

**Problem:** copilot-adapter.md proves basic functionality but lacks:
- Runtime capability detection specification
- Fallback behavior when inherit-session-model fails
- Inline binding resolution mechanics
- Error path handling

**Fix:**
- Document runtime capability detection (how to detect if native subagent spawn exists)
- Specify fallback sequence: native → single-agent-fallback, with honest recording
- Explain inline binding resolution from role-profiles.json
- Add error path specifications (stage timeout, tool failure, specialist unavailable)
- Create worked example showing full dispatch sequence

**Success criteria:** Another contributor can implement Copilot agentic runs without reading smoke test artifacts for clues.

**Risk if unfixed:** Copilot support appears complete but is actually under-documented; adoption will hit friction.

### 5. Error Path Testing [BUILD THE THING]
**Owner:** Hudson  
**Effort:** 2 weeks  
**Dependencies:** #3 (security must be hardened first), #4 (Copilot adapter complete)

**Problem:** All test evidence covers happy path only. No fixtures with:
- Contradictory sources
- Failed tool calls
- Stage timeouts
- Fallback-to-single-agent scenarios
- Invalid source material

**Build:**
- Create error-path fixture set under tests/agentic-errors/
- Add contradictory-source fixture (requires synthesis escalation)
- Add stage-failure fixture (validator finds critical defect)
- Add fallback fixture (subagents unavailable → single-agent mode)
- Update validate-agentic-run.sh to handle error-path manifests
- Document expected error patterns in test README

**Success criteria:** 
- Agentic engine behavior under failure is validated, not just theorized
- Error manifests are well-formed and auditable
- Fallback modes produce correct metadata

**Risk if unfixed:** Production use will encounter errors with unpredictable behavior.

### 6. Codex Adapter Decision [FIX THE SPEC or DROP]
**Owner:** Ripley + Dallas  
**Effort:** 1 day (decision) OR 2-3 weeks (implementation)  
**Dependencies:** #4 (Copilot adapter sets precedent)

**Problem:** Codex is referenced in README examples and acknowledged in benchmark system, but no Codex engine adapter exists. This creates false expectation.

**Decision Required:**
- **Option A (Implement):** Build codex-adapter.md, add Codex specialist bindings, extend test coverage
- **Option B (Defer):** Remove all Codex references from user-facing docs until adapter exists
- **Option C (Drop):** Declare Codex out-of-scope for foreseeable future

**Recommendation:** **Option B (Defer)** — remove from README examples, keep benchmark adapter (already built and functional), defer engine adapter until proven demand exists.

**Scope if deferring:**
- Remove Codex examples from README.md
- Add note in agentic-runtime.md: "Codex adapter deferred pending demand validation"
- Keep skill-benchmark-codex-adapter.py (already working, different surface)

**Risk of wrong choice:** Option A wastes effort if no one uses Codex engine; Option C throws away working benchmark integration.

## P2: Valuable — Improves Operational Quality

### 7. Consolidate Comparison Tooling [BUILD THE THING]
**Owner:** Parker + Hudson  
**Effort:** 1 week  
**Dependencies:** #8 (real benchmark must exist first)

**Problem:** run-agentic-quality-compare.py (636 lines) overlaps significantly with run-skill-benchmark.py. Both emit benchmark-summary.json + benchmark-report.md. Two parallel comparison systems = maintenance burden.

**Fix:**
- Express agentic-vs-legacy comparison as a benchmark dataset
- Feed that dataset to existing skill-benchmark harness
- Deprecate run-agentic-quality-compare.py or refactor to thin wrapper
- Update TESTING.md and evals/README.md to reflect single comparison path

**Success criteria:** One canonical benchmark harness, multiple comparison types expressed as datasets.

**Risk if deferred:** Maintenance overhead; confusion about which tool to use.

### 8. Production Benchmark Run [BUILD THE THING]
**Owner:** Parker  
**Effort:** 2-3 weeks  
**Dependencies:** #2 (terminology stable), #5 (error paths validated)

**Problem:** The harness works. The schemas are sound. The pilot smoke test passes. **But no actual skill-vs-skill comparison has been published.** Until one exists, the benchmark system is a specification, not a capability.

**Build:**
- Create production benchmark dataset (≥10 cases, mix of simple/complex/adversarial)
- Run cogworks-learn vs cogworks-encode-only comparison
- Run agentic-short vs agentic-full comparison (if synthesis complexity justifies)
- Capture benchmark-summary.json + benchmark-report.md
- Archive in tests/datasets/production-benchmark-001/
- Document findings in _plans/DECISIONS.md

**Success criteria:** 
- At least one benchmark run with published results
- Confidence intervals reported, not just point estimates
- Activation + efficacy scores separated and analyzed

**Risk if deferred:** "Agentic produces better skills than legacy" remains an untested hypothesis.

### 9. Behavioral Evaluation Reconstruction [BUILD THE THING]
**Owner:** Parker + Hudson  
**Effort:** 4-6 weeks  
**Dependencies:** #8 (production benchmark methodology proven), D-026 (quality schema settled)

**Problem:** D-022/D-023 correctly deleted circular traces. Replacement with non-circular judge is specified (D-026, QUALITY-SCHEMA.md, HARNESS-SPEC.md) but not implemented.

**Build:**
- Implement behavioral delta harness per HARNESS-SPEC.md
- Cross-model judge integration (Claude generates → GPT judges, or vice versa)
- Baseline capture infrastructure (agent WITHOUT skill)
- Treatment capture infrastructure (agent WITH skill)
- Statistical comparison with confidence intervals
- Integration with ci-gate-check.sh

**Success criteria:**
- Generated skill quality measurable with non-circular ground truth
- Behavioral delta scores pass cross-model independence check
- CI gate enforces behavioral coverage requirement (D-021)

**Risk if deferred:** No way to measure whether generated skills actually improve agent behavior.

### 10. Worked Example Documentation [FIX THE SPEC]
**Owner:** Scribe  
**Effort:** 1 week  
**Dependencies:** #5 (error paths validated), #8 (production benchmark complete)

**Problem:** Smoke run evidence is spread across .cogworks-runs/ and tmp-agentic-output/. A single walkthrough showing input → stage outputs → manifests → final skill would make system accessible to new contributors.

**Build:**
- Create docs/agentic-runtime-walkthrough.md
- Show one complete run end-to-end with annotated artifacts
- Include decision skeleton, CDR, synthesis, validation report
- Link from README.md and agentic-runtime.md
- Add troubleshooting section based on error path testing

**Success criteria:** New contributor can understand agentic pipeline by reading one document and examining one example run.

**Risk if deferred:** Adoption friction; contributors must reverse-engineer from smoke test artifacts.

## P3: Defer or Drop

### 11. 340-line Context Retrieval Risk Audit [DROP ARTIFACT, KEEP DECISIONS]
**Owner:** Scribe  
**Effort:** 30 minutes  
**Recommendation:** Move to _plans/archive/, keep D-033/D-034 as canonical reference

**Rationale:** The findings are valuable and captured in DECISIONS.md (D-033/D-034). The 340-line document largely restates information already in DECISIONS.md and AGENTS.md. Per team's own archival protocol, extract-and-archive is the right move.

**Action:**
- Move docs/ai-context-retrieval-risk-audit-2026-03-07.md → _plans/archive/
- Add note in D-033 pointing to archived full analysis
- Update _plans/DECISIONS.md audited_through date

**Risk of keeping:** Context bloat; redundant maintenance surface.

### 12. Team Reflection Ceremony Artifact [ALREADY HANDLED]
**Recommendation:** No action required

**Rationale:** Commit 9340792 added, d0f921a reverted — net zero in working tree. This is just git history noise, not an actionable issue. The ceremony format should be settled before next attempt.

## Dependencies & Sequencing

### Week 1-2: Specification Hardening (parallel work)
- #1 (Decision Skeleton Spec) — Ripley + Ash
- #2 (Terminology Glossary) — Ripley + Scribe
- #6 (Codex Adapter Decision) — Ripley + Dallas

### Week 3-4: Security & Foundation Building
- #3 (Dispatch Security) — Ash (depends on #1)
- #4 (Copilot Adapter) — Dallas + Lambert (depends on #1, #2)

### Week 5-6: Validation Expansion
- #5 (Error Path Testing) — Hudson (depends on #3, #4)
- #8 (Production Benchmark) — Parker (depends on #2, #5)

### Week 7-8: Quality Infrastructure
- #7 (Consolidate Comparison Tools) — Parker + Hudson (depends on #8)

### Week 9-14: Behavioral Evaluation (parallel with documentation)
- #9 (Behavioral Eval Reconstruction) — Parker + Hudson (depends on #8)
- #10 (Worked Example) — Scribe (depends on #5, #8)

### Immediate Cleanup (30 min)
- #11 (Archive Context Audit) — Scribe

## Items Explicitly Dropped

**None.** Every identified issue has value. Some are P3/deferred, but nothing is "not worth doing eventually."

The closest to DROP is:
- run-agentic-quality-compare.py deletion (superseded by #7 consolidation)
- Team reflection ceremony (already reverted, no artifact to drop)

## Success Metrics

**P0 Complete:**
- Decision skeleton has formal owner, creation trigger, quality gate
- All specification terms have single canonical definition
- Untrusted source dispatch has injection-resistant hardening

**P1 Complete:**
- Copilot adapter documented well enough for external implementation
- Error paths validated, not just theorized
- Codex references match actual capabilities (defer if not implemented)

**P2 Complete:**
- One production benchmark run published with results
- Behavioral evaluation reconstructed with non-circular ground truth
- Single comparison harness replaces dual systems

**P3 Complete:**
- Context audit archived
- Worked example guide published

## Risk Assessment

### If We Execute This Plan:
- **Low risk:** Specification work is surgical, well-scoped, minimal regression surface
- **Medium risk:** Security hardening may surface new edge cases in source-intake
- **High value:** Production benchmark + behavioral eval close the evidence gap

### If We Don't Execute This Plan:
- **Immediate risk:** Decision skeleton ambiguity may cause adapter divergence
- **6-month risk:** Copilot adoption will stall due to under-documentation
- **12-month risk:** Agentic engine remains "sophisticated specification with thin validation" — users lose confidence

## Recommendation

**Phase 1 (Critical, 2-4 weeks):** Execute P0 items #1-3 in parallel. These are specification fixes and security hardening — high value, low risk, unblock everything downstream.

**Phase 2 (Important, 4-6 weeks):** Execute P1 items #4-6 sequentially. Copilot completion and error path testing are adoption prerequisites.

**Phase 3 (Valuable, 8-14 weeks):** Execute P2 items #7-10 with Parker + Hudson focused on benchmark/behavioral infrastructure, Scribe on documentation.

**Immediate (30 min):** Execute P3 item #11 (archive context audit).

---

## Appendix: Assignment Matrix

| Item | Owner(s) | Type | Effort | Priority |
|------|----------|------|--------|----------|
| 1. Decision Skeleton Spec | Ripley + Ash | Spec | 2-3h | P0 |
| 2. Terminology Glossary | Ripley + Scribe | Spec | 4-6h | P0 |
| 3. Dispatch Security | Ash | Build | 1w | P0 |
| 4. Copilot Adapter Completion | Dallas + Lambert | Spec | 1w | P1 |
| 5. Error Path Testing | Hudson | Build | 2w | P1 |
| 6. Codex Adapter Decision | Ripley + Dallas | Decision | 1d | P1 |
| 7. Consolidate Comparison Tools | Parker + Hudson | Build | 1w | P2 |
| 8. Production Benchmark | Parker | Build | 2-3w | P2 |
| 9. Behavioral Eval Reconstruction | Parker + Hudson | Build | 4-6w | P2 |
| 10. Worked Example | Scribe | Docs | 1w | P2 |
| 11. Archive Context Audit | Scribe | Cleanup | 30m | P3 |

**Total estimated effort:** ~14-20 weeks across team (significant parallelization possible in Weeks 1-6)

---

**Ripley's Certification:** This roadmap reflects architectural review of all work from b6208ff forward. The objective was sound, the architecture is well-designed, the main risk is specification-evidence gap. This sequencing closes that gap surgically without introducing new risks.

**Next Step:** William reviews and approves roadmap, then Phase 1 work begins.
