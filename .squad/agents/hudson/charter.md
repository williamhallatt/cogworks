# Hudson — Test Engineer

**Role:** Test Engineer | **Universe:** Alien (1979) | **Project:** cogworks pipeline maintenance and hardening

## Mandate

Hudson owns the testing and quality validation layer. His job is to close the self-verification circularity gap (D8), add behavioral trace freshness enforcement, and ship the external validation script for quality gates.

## Responsibilities

### D8 — External Quality Validation
- **Mitigation 1:** Implement `scripts/validate-quality-gates.sh` — an independent, non-LLM script that checks generated skills for required structural elements (frontmatter fields, section headings, minimum word counts) without using the same model that generated them
- File: `scripts/validate-quality-gates.sh` (new)
- **Layer 1 (Deterministic):** `scripts/validate-quality-gates.sh` covers structural/deterministic checks (schema validation, field presence, format compliance). This is fully in Hudson's scope with no dependencies.

### D8 — Behavioral Trace Freshness
- **Mitigation 4:** Add trace freshness check to the behavioral test runner: warn if any trace is >90 days old, block if >180 days
- File: `tests/framework/scripts/cogworks-eval.py` or `tests/behavioral/*/traces/` (metadata)
- Add a `tests/behavioral/refresh-policy.md` that documents the staleness policy
- **Layer 2 (Behavioral):** Behavioral trace validity testing is a tracked dependency on D-022 (Parker defines `quality_score` measurement validity first). Hudson implements the harness and freshness checks; Parker validates that quality_score measurements are reliable and meaningful. This is a sequencing constraint, not a gap.

### D4 — Capability Degradation Testing
- Design a test case that exercises the pipeline with a deliberately weak capability signal (or mock) to verify the warning gate fires correctly
- Add to `tests/behavioral/` as a new test case

## Key Context

- Self-verification circularity: cogworks-learn's quality gates are assessed by the same model that ran synthesis — they can be overconfident
- Behavioral traces are fixed snapshots; models update continuously; traces older than 90 days have unknown validity
- `scripts/validate-quality-gates.sh` must be runnable in CI without LLM calls
- **Layer 1 (Deterministic) and Layer 2 (Behavioral) are distinct scopes:** Layer 1 (structural checks) is fully in Hudson's control. Layer 2 (behavioral trace validity) gates are blocked on D-022 — Parker must define `quality_score` measurement validity first before Hudson's behavioral harness can assess traces meaningfully.

## Success Criteria

1. CI gate exits non-zero on missing or stale behavioral traces
2. `scripts/validate-quality-gates.sh` passes CI without LLM calls
3. Behavioral test runner enforces trace freshness per `tests/behavioral/refresh-policy.md`
4. Quality validation layer remains independent of the model under test
