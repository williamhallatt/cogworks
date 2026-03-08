# Hardening Plan: Benchmark Truthfulness and Context Hygiene

## Summary

Bring the new benchmark and agentic-evidence surfaces up to the same standard as the runtime contract: strict, auditable, low-noise, and resistant to false confidence.

This plan treats the main problem as two coupled failures:
- the benchmark runner is not yet strict enough to justify decisions about the agentic pivot
- the repo still carries avoidable context risk from realistic but non-canonical artifact surfaces

The target state is:
- benchmark verdicts are policy-complete and cannot silently overclaim
- invalid evidence is rejected or rerun, not scored
- activation metrics reflect candidate behavior, not dataset shape
- non-canonical artifact surfaces are either removed from tracked state or clearly demoted to deliberate fixtures/examples

## Key Changes

### 1. Make `run-skill-benchmark.py` decision-complete
- Enforce the full verdict policy already stated in `evals/skill-benchmark/README.md`.
- Add explicit activation disqualifiers to verdict computation, at minimum for false-positive regression on `must_not_activate` cases.
- Treat invalid trials as invalid:
  - command failure
  - missing observation
  - observation validation failure
  - malformed judge output when required
- Rerun invalid trials until both candidates reach the requested valid trial count, or fail the benchmark with a clear terminal status after a bounded retry limit.
- Report both `valid_trial_count` and `invalid_trial_count` per candidate and per case in `benchmark-results.json` and `benchmark-summary.json`.
- Stop using synthesized fallback observations as scored evidence; keep them only as debug artifacts if needed, clearly marked and excluded from scoring.
- Rework `ambiguous_trigger_rate` so it measures candidate behavior on `may_activate` cases rather than counting the presence of those cases.
- Add explicit schema validation for case, observation, judge-output, and summary payloads against the JSON schemas under `evals/skill-benchmark/`.
- Add a machine-readable “benchmark integrity” section to the summary:
  - `ranking_eligible`
  - `decision_eligible`
  - `invalid_trial_policy_applied`
  - `activation_gate_passed`
  - `schema_validation_passed`

### 2. Tighten the benchmark contract and docs so they match the implementation exactly
- Update `evals/skill-benchmark/README.md`, `evals/skill-benchmark/runbook.md`, and `tests/framework/README.md` to describe:
  - what counts as an invalid trial
  - retry/fail behavior
  - exact activation disqualifiers
  - what summary fields are authoritative for publication decisions
- Keep the benchmark intentionally narrow; do not expand feature surface until integrity rules are enforced.
- Add one short doctrine rule: no benchmark result may be used in decision-making unless `decision_eligible = true`.

### 3. Harden the Codex adapter as evidence, not just convenience
- Keep `skill-benchmark-codex-adapter.py` surface-neutral, but make normalization stricter:
  - distinguish “not observed” from “observed false”
  - carry raw event parsing anomalies into explicit integrity flags
  - emit enough metadata for the harness to reject incomplete replay/live traces cleanly
- Add a small integrity contract for replay mode so offline smoke coverage cannot masquerade as decision-grade live evidence.

### 4. Reduce repo context risk from tracked generated artifacts
- Stop treating tracked `.cogworks-runs/**` and `tmp-agentic-output/**` as ordinary repo content.
- Replace the currently tracked live smoke output with one of these patterns, chosen consistently:
  - preferred: remove live run trees from tracked state and keep only small hand-curated example fixtures in a clearly named example directory
  - acceptable: preserve a single minimized canonical example artifact set with explicit “example only / not default retrieval” framing and no production-shaped scratch naming
- Ensure docs, examples, and retrieval policy all point to the same canonical example surface.
- Keep `.gitignore`, `TESTING.md`, `AGENTS.md`, and example locations aligned so the repo does not teach one policy while embodying another.

### 5. Add regression tests for the standards themselves
- Add benchmark-runner tests covering:
  - invalid trial rerun path
  - hard failure after retry exhaustion
  - activation regression blocking a winner
  - CI overlap yielding `no_clear_winner`
  - ranking-ineligible runs yielding `insufficient_evidence`
  - schema-invalid observation/judge payload rejection
  - `may_activate` cases not inflating ambiguous-trigger rate by construction
- Add a small hygiene test or deterministic check that fails if new tracked artifact surfaces appear in non-canonical locations without explicit README/policy markers.
- Keep tests cheap and deterministic; do not add new LLM-dependent checks for this hardening pass.

## Public Interfaces and Artifacts

### Benchmark summary additions
Add fields to the benchmark summary schema and emitted summary:
- `decision_eligible: boolean`
- `activation_gate_passed: boolean`
- `schema_validation_passed: boolean`
- `valid_trial_count`
- `invalid_trial_count`
- optional `terminal_status: "completed" | "failed_invalid_trials" | "failed_schema_validation"`

### Benchmark results additions
Add per-case/per-candidate integrity details:
- `valid_trials`
- `invalid_trials`
- `invalid_reasons`
- explicit exclusion markers for unscored trial artifacts

### No broad runtime-interface changes
- Do not change the core agentic stage contract in this pass.
- Do not broaden the benchmark to new agent surfaces before the existing harness is strict.

## Test Plan

- Run deterministic self-checks for the benchmark runner and schemas using synthetic fixtures only.
- Run the existing pilot benchmark fixtures and verify:
  - summary validates against schema
  - invalid-trial handling is exercised by a deliberately failing fixture
  - activation gating blocks an otherwise positive efficacy result when false positives regress
- Run the Codex replay smoke and verify replay runs are marked non-decision-grade unless all decision-eligibility conditions are met.
- Re-run `bash scripts/test-agentic-contract.sh` to confirm no accidental runtime regression while hardening docs and evidence surfaces.
- Re-run the committed-example artifact validator path, if an example artifact set is retained, using the same strict validation commands documented in `TESTING.md`.

## Assumptions and Defaults

- Default policy: benchmark integrity is more important than convenience; failing closed is preferred over producing a misleading summary.
- Default activation gate: regressions on `must_not_activate` behavior are disqualifying unless the benchmark config explicitly defines a tolerated threshold.
- Default invalid-trial behavior: rerun up to a small bounded retry count per candidate/case, then fail the benchmark rather than silently scoring degraded evidence.
- Default repo-hygiene choice: remove tracked live scratch outputs and replace them with a single minimized canonical example surface, because this best matches the repository’s own retrieval-hygiene doctrine.
- This pass does not attempt to finish the broader D-026 behavioral-delta harness; it hardens the benchmark and artifact surfaces that already exist so they become worthy building blocks for later work.
