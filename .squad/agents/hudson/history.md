# history.md

## Learnings

### 2026-03-04 — Kane's Product Gap Synthesis: Impact on Testing Strategy

Kane's analysis identifies **activation testing** as the highest-priority gap (P0). Current behavioral eval validates output quality but not whether skills trigger on relevant prompts. This directly impacts Hudson's testing roadmap:

- **Activation test cases:** 2-4 cases per skill needed (positive: prompts that SHOULD trigger; negative: similar prompts that should NOT)
- **Blocking gate:** Activation test failures should have same severity as behavioral test failures — currently only behavioral checks block deployment
- **Integration point:** `cogworks-eval.py behavioral run` must extend to cover activation precision, not just output quality
- **CI gate implication:** `tests/ci-gate-check.sh` should fail on activation test coverage gaps, same as behavioral trace gaps

**Related to Hudson's D8 closure (generalization probes):** The quality gate tests Hudson added (contradictory sources, context-dependent recommendations) are orthogonal but complementary to activation testing. Quality gates target self-verification accuracy; activation tests target discovery precision.

**Parallel insight:** Kane's "parallel tool use" and "eval flywheel" findings suggest two further testing extensions (P1-P2):
1. Test execution time assumptions in behavioral traces (parallel execution should improve latency 3-5x for file-heavy operations)
2. Eval iteration harness: capture failure modes from behavioral eval, annotate root cause, verify fix on re-run

**Team coordination:** Kane's synthesis informs testing strategy; no conflicts with Hudson's existing D8 closure (generalization probes + CI gate).

### 2026-03-04 — Gap Closure Round 3: CI Gate Behavioral Coverage Enforcement

Completed D8 gap closure. Updated `tests/ci-gate-check.sh` to fail (exit non-zero) when behavioral traces are missing for any skill.

**Old behavior:** Missing traces triggered a warning but did NOT set EXIT_CODE=1. A pre-release gate could pass with zero behavioral evaluation. Only `cogworks-encode/traces` checked — missing `cogworks` and `cogworks-learn` entirely.

**New behavior:**
- Loop over all skill directories in `tests/behavioral/*/`
- Count trace files per skill
- Exit non-zero with actionable remediation command if any skill has zero traces
- Prints exact command: `python3 tests/framework/scripts/cogworks-eval.py behavioral run --skill-prefix cogworks-`

**Updated documentation:** TESTING.md Pre-release CI Gate section now lists trace capture as Step 1 and makes exit-non-zero behavior explicit.

**Architectural decision:** **D-021** (behavioral coverage is release guarantee, not optional signal; trace presence check is blocking gate, not warning-only).

**Key lesson:** A gate that warns-but-passes on its primary enforcement condition provides false confidence. The warn-not-fail choice was defensible at creation (live capture is expensive) but the implicit contract — "CI green means behavioral coverage was verified" — was broken. Fail loudly and tell the operator exactly how to fix it.

**Team coordination (Round 3):** Ash closed M2/M9 (security), Dallas closed D9/D3 (pipeline), Lambert closed D6 (compatibility), Ripley recorded architectural decisions D-020 and D-021.

### 2026-03-03 — CI Gate Closure (self-knowledge audit)

Discovered that `tests/ci-gate-check.sh` was a structural no-op for behavioral coverage: missing traces triggered a warning but did NOT set `EXIT_CODE=1`. A pre-release gate could pass with zero behavioral signal.

Also found the gate only checked `tests/behavioral/cogworks-encode/traces` — missing `cogworks` and `cogworks-learn` entirely.

Fixed in two surgical changes:
- **`tests/ci-gate-check.sh`:** Replaced single-skill TRACE_COUNT check with a per-skill loop over all `tests/behavioral/*/` directories. Missing traces for any skill now sets `EXIT_CODE=1` and emits the exact remediation command.
- **`TESTING.md`:** Rewrote the Pre-release CI Gate section to list trace capture as Step 1 and made the exit-non-zero behavior explicit.

Written decision: `.squad/decisions/inbox/hudson-ci-gate-closure.md`

Key lesson: A gate that warns-but-passes on its primary enforcement condition provides false confidence. The warn-not-fail choice was defensible at creation (live capture is expensive) but the implicit contract — "CI green means behavioral coverage was verified" — was broken. Fail loudly and tell the operator exactly how to fix it.

### 2026-03-03 — Test Coverage Round 2 (Issues #17, #21, #20)

Added 7 new behavioral test cases to `tests/behavioral/cogworks-encode/test-cases.jsonl`:
- 3 quality gate cases (D8 generalization probe) testing circular verification: contradictory sources, context-dependent recommendations, distinct API endpoints
- 4 edge cases testing: direct contradictions, derivative sources, single-source synthesis, embedded instruction injection

Created `tests/ci-gate-check.sh` as pre-release quality gate combining:
- Deterministic checks (validate-quality-gates.sh)
- Behavioral trace coverage verification
- Behavioral evaluation against stored traces

Updated `TESTING.md` with Pre-release CI Gate section documenting the new gate script and its usage.

Key insight: The D8 risk (generator evaluating its own output) requires test cases specifically designed to expose circular reasoning — contradictions, context preservation, and entity distinction are areas where self-verification tends to over-smooth or rationalize away real quality issues that an independent evaluator would catch.

**2026-03-03 — Team coordination notes**

- Dallas implemented pipeline guards (M5, M11, D3, D7) addressing overwrite protection, cross-source synthesis validation, CDR completeness, and convergence risk.
- Ash implemented security guards (D2, D1, D1) addressing escalation boundaries, stale skill detection, and intent clarification.
- Ripley implemented quality calibration gate (D4) in cogworks-encode Self-Verification to detect superficial synthesis.
- Lambert documented Codex behavioral capture and skills-lock schema; recommended AGENTS/CLAUDE dedup approach.

