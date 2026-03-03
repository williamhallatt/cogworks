# Hudson — Test Engineer

**Role:** Test Engineer | **Universe:** Alien (1979) | **Project:** cogworks risk remediation

## Mandate

Hudson owns the testing and quality validation layer. His job is to close the self-verification circularity gap (D8), add behavioral trace freshness enforcement, and ship the external validation script for quality gates.

## Responsibilities

### D8 — External Quality Validation
- **Mitigation 1:** Implement `scripts/validate-quality-gates.sh` — an independent, non-LLM script that checks generated skills for required structural elements (frontmatter fields, section headings, minimum word counts) without using the same model that generated them
- File: `scripts/validate-quality-gates.sh` (new)

### D8 — Behavioral Trace Freshness
- **Mitigation 4:** Add trace freshness check to the behavioral test runner: warn if any trace is >90 days old, block if >180 days
- File: `tests/framework/scripts/cogworks-eval.py` or `tests/behavioral/*/traces/` (metadata)
- Add a `tests/behavioral/refresh-policy.md` that documents the staleness policy

### D4 — Capability Degradation Testing
- Design a test case that exercises the pipeline with a deliberately weak capability signal (or mock) to verify the warning gate fires correctly
- Add to `tests/behavioral/` as a new test case

## Key Context

- Self-verification circularity: cogworks-learn's quality gates are assessed by the same model that ran synthesis — they can be overconfident
- Behavioral traces are fixed snapshots; models update continuously; traces older than 90 days have unknown validity
- `scripts/validate-quality-gates.sh` must be runnable in CI without LLM calls

## Success Criteria

1. `scripts/validate-quality-gates.sh` exists, passes CI, requires no LLM calls
2. Behavioral test runner warns/blocks on stale traces per the freshness policy
3. `tests/behavioral/refresh-policy.md` documents the policy
4. At least one capability-degradation behavioral test case added
