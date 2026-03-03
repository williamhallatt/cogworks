# history.md

## Learnings

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
