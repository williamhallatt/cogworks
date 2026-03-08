# Cogworks Test Suite — Success Criteria

This document defines explicit, measurable pass/fail criteria for each layer of
the cogworks test suite. It is the DR-1 prerequisite: success criteria defined
before evaluation design.

## Offline Bar

**Command:** `bash tests/run-all.sh`
**Pass condition:** Exit code 0 — all headless suites pass.

### Layer 1 — Deterministic Checks

| Criterion | Threshold | Evidence |
|---|---|---|
| All test cases pass | 0 failures | `tests/run-black-box-tests.sh` exit 0 |
| Test case count | ≥ 15 cases in `mvp-test-cases.jsonl` | JSONL line count |
| Coverage categories | tier 1 (core), tier 2 (exit codes), tier 3 (edge cases) | Case metadata |

**What it proves:** Generated skill structure, YAML frontmatter, citations,
section presence, forbidden patterns, and line limits are mechanically correct.

**What it does NOT prove:** Skill content quality, activation accuracy, or
end-to-end pipeline correctness.

### Layer 2 — Trigger Smoke Parser

| Criterion | Threshold | Evidence |
|---|---|---|
| Parser smoke passes | Exit 0 | `tests/run-trigger-smoke-parser-smoke.sh` |
| Both surfaces tested | Claude and Codex parsers | Script output |

**What it proves:** Activation prompt parsing works offline for known triggers.

**What it does NOT prove:** Live activation behavior in a real agent session.

### Layer 3 — Agentic Contract Smoke

| Criterion | Threshold | Evidence |
|---|---|---|
| Contract smoke passes | Exit 0 | `tests/run-agentic-contract-smoke.sh` |
| All contract surfaces verified | Docs, adapters, deterministic checks | Script output |

**What it proves:** Static contract obligations (file presence, path
correctness, adapter integrity) are satisfied.

**What it does NOT prove:** Runtime behavior of the agentic workflow.

### Layer 4 — Skill Benchmark Smoke

| Criterion | Threshold | Evidence |
|---|---|---|
| Benchmark harness passes | Exit 0 | `tests/run-skill-benchmark-smoke.sh` |
| Synthetic paired comparison works | Both candidates run | Script output |

**What it proves:** The benchmark harness infrastructure is functional and
produces valid output against synthetic test data.

**What it does NOT prove:** Actual skill quality differences (that requires live
benchmark runs with real models).

### Layer 5a — Deterministic Behavioral Checks

| Criterion | Threshold | Evidence |
|---|---|---|
| All structural checks pass | 0 failures | `tests/run-behavioral-deterministic.sh` exit 0 |
| Explicit activation consistency | 100% — explicit cases contain skill slug | Per-case results |
| Negative control consistency | 100% — negative controls do not contain skill slug | Per-case results |
| Implicit/contextual boundary | 0 implicit/contextual cases contain explicit skill slug | Per-case results |
| Category coverage | Each skill has explicit + negative_control categories | Category distribution |
| Negative control ratio | ≥ 15% of cases per skill | Ratio check |
| Case ID uniqueness | 0 duplicates per skill | ID check |
| Quality/edge case field completeness | quality_gate/edge_case have ground_truth; quality have expected_content | Field presence |
| Forbidden commands format | All regex patterns compile | Regex validation |

**What it proves:** Behavioral test case definitions are structurally correct,
internally consistent, and follow design conventions (explicit cases reference
the skill name, negative controls do not, category distribution is adequate).

**What it does NOT prove:** Actual agent activation behavior or output quality.

### Schema Validation

| Criterion | Threshold | Evidence |
|---|---|---|
| All schemas valid JSON Schema | Draft 2020-12 compliance | `tests/run-schema-validation-smoke.sh` exit 0 |
| Examples validate against schemas | 0 validation errors | Schema validation output |

**What it proves:** All machine-readable interfaces are well-formed.

## Release Bar

**Command:** `bash tests/run-release-validation.sh --claude-run-root ... --copilot-run-root ... --fail-closed-report ... --fail-closed-skill-path ... --fail-closed-pattern ... --benchmark-summary ...`

### Layer 5b — LLM-Judged Quality Evaluation

| Criterion | Threshold | Evidence |
|---|---|---|
| Cross-model independence | Judge family ≠ generator family | Model metadata in results |
| All applicable dimensions ≥ 0.7 | Per judge prompt scoring rules | Judge output JSON |
| No dimension < 0.5 | Hard fail on any sub-0.5 score | Judge output JSON |
| Verdict not "fail" | Per-skill verdict rules | Judge output JSON |
| Output validates against schema | `judge-output.schema.json` per skill | JSON Schema validation |
| Evidence citations present | `reasoning` field quotes actual output | Judge output inspection |

**Verdict rules** (from D-026, per skill):
- **cogworks:** "pass" = all 5 dimensions ≥ 0.7. "fail" = any dimension < 0.5.
- **cogworks-encode:** "pass" = all 6 dimensions ≥ 0.7. "fail" = any dimension
  < 0.5 OR injection_resistance = 0.0 (hard fail override).
- **cogworks-learn:** "pass" = all applicable (non-null) dimensions ≥ 0.7.
  "fail" = any applicable dimension < 0.5.

**What it proves:** Generated skill output meets quality standards as evaluated
by an independent model, with quantified evidence.

**What it does NOT prove:** Human satisfaction or real-world deployment
effectiveness.

### Live Artifact Validation

| Criterion | Threshold | Evidence |
|---|---|---|
| Claude run artifacts valid | Contract checks pass | `validate-agentic-run.sh` |
| Copilot run artifacts valid | Contract checks pass | `validate-agentic-run.sh` |
| Fail-closed report present | Blocking report validates and intended skill path remains uninstalled | Release validation |
| Benchmark evidence present | `decision_eligible = true` with maintained input provenance | `benchmark-summary.json` |

## Cross-Model Independence (D-026 / D-036)

All judge-evaluated results must enforce cross-model independence:

| Generator family | Allowed judge families |
|---|---|
| Claude (Sonnet, Opus, Haiku) | GPT, Gemini |
| GPT (4.1, 5-mini, 5-codex) | Claude, Gemini |
| Gemini | Claude, GPT |

Violation of this constraint invalidates the evaluation regardless of scores.
This is enforced mechanically by the Layer 5b runner, not by reviewer judgment.

## Fail-Closed Default (D-036)

When evidence is missing, ambiguous, or cannot be independently verified:
- The test suite defaults to **fail**, not pass.
- Missing traces = fail. Missing schemas = fail. Missing judge output = fail.
- The burden of proof is on the evidence, not on the reviewer.
