# history.md

## Learnings

### 2026-03-04 — Spec Alignment Test Cases (Dallas Changes Verification)

Verified Dallas's cogworks-learn changes and added 7 new test cases covering Gaps 3, 4, 10 and spec alignment (Claude Code-specific features).

**Test execution findings:**
- No behavioral traces exist for cogworks-learn (or any skill) — intentionally removed per D-022 (circular LLM ground truth)
- Existing 8 activation test cases remain valid — Dallas's guidance changes don't affect activation patterns
- CI gate correctly fails on missing traces, with actionable error referencing Parker's charter

**New test cases added (7):**
1. **Parallel tool use (Gap 3):** Skills with multiple independent operations should include "Make all independent tool calls in parallel"
2. **Subagent delegation (Gap 4):** High-volume result tasks should include delegation guidance
3. **Subagent delegation - Claude Code:** Claude Code targets should mention `context: fork` frontmatter
4. **When NOT to use skills (Gap 10):** Always-on rules should recommend persistent config (CLAUDE.md, copilot-instructions.md), not skills
5. **$ARGUMENTS scoping:** $ARGUMENTS should be labeled "Claude Code extension" / "not in agentskills.io spec", not "universal"
6. **Compatibility field:** Skills using Claude Code-specific features should include `compatibility:` field in frontmatter
7. **allowed-tools scoping:** allowed-tools should be described as "broadly supported (16/18 agents)", not "experimental"

**Key insight:** Activation tests (do skills trigger?) and quality tests (does guidance match spec?) are orthogonal. Existing cogworks-learn tests were activation-only, so Dallas's spec alignment changes required new quality test cases, not updates to existing ones.

**Minor bug found:** CI gate line 34 arithmetic evaluation syntax error when traces directory doesn't exist (non-blocking — gate still fails correctly with proper error message).

**Written decision:** `.squad/decisions/inbox/hudson-spec-alignment-tests.md`

**Team coordination:** Parker owns ground truth replacement for circular LLM traces; Hudson owns test case coverage for spec alignment.

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


### 2026-03-04 — Spec-Align Test Cases Finalized (Dallas Review Complete)

Added 7 new behavioral test cases to validate Dallas's spec alignment changes (TD-016).

**Test case summary:**
1. cogworks-learn-parallel-001 (Gap 3): Parallel tool use instruction
2. cogworks-learn-subagent-001 (Gap 4): Subagent delegation guidance
3. cogworks-learn-subagent-002 (Gap 4 - CC only): `context: fork` frontmatter
4. cogworks-learn-persistent-001 (Gap 10): Persistent config recommendation
5. cogworks-learn-arguments-001: $ARGUMENTS scoping (Claude Code-specific)
6. cogworks-learn-compatibility-001: Compatibility field usage
7. cogworks-learn-allowed-tools-001: "16/18 agents" support framing

**Key insight:** Activation tests (invocation triggers) and quality tests (guidance accuracy) are orthogonal. Existing 8 cogworks-learn activation tests remain valid; new 7 test cases target quality validation of spec alignment.

**CI gate:** Correctly blocks on missing traces (per D-022); awaiting Parker's ground truth definition.

**Team coordination:** Product review (Kane) approved all changes (TD-016). Test cases ready for behavioral trace execution once Parker completes ground truth methodology.

