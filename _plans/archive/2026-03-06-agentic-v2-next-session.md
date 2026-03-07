# Agentic V2 Next Session

## Current State

- The agentic pivot remains active.
- Do **not** kill the pivot without explicit user confirmation.
- The runtime contract has been simplified from the original 9-stage design to a selective 5-stage v2:
  1. `source-intake`
  2. `synthesis`
  3. `skill-packaging`
  4. `deterministic-validation`
  5. `final-review`
- Agentic runs must record:
  - `engine_mode`
  - `execution_adapter`
  - `execution_mode`
  - `agentic_path`
- `agentic_path` must be one of:
  - `agentic-short-path`
  - `agentic-full-path`

## What Was Completed

- Simplified the agentic runtime contract in `skills/cogworks/agentic-runtime.md`
- Updated orchestrator instructions in `skills/cogworks/SKILL.md`
- Updated Claude adapter guidance in `skills/cogworks/claude-adapter.md`
- Updated:
  - `scripts/test-agentic-contract.sh`
  - `scripts/validate-agentic-run.sh`
  - `scripts/run-agentic-quality-compare.py`
  - `scripts/compare-engine-performance.py`
- Updated docs:
  - `README.md`
  - `skills/cogworks/README.md`
  - `TESTING.md`
  - `tests/agentic-smoke/README.md`
- Recorded D-028 in `_plans/DECISIONS.md`

## Verified

- `bash scripts/test-agentic-contract.sh` passes
- `bash tests/framework/graders/deterministic-checks.sh skills/cogworks` passes
- `python3 -m py_compile scripts/compare-engine-performance.py scripts/run-agentic-quality-compare.py` passes

## Known Evidence

- Real engine comparison artifacts already exist at:
  - `tests/results/engine-comparison/engine-compare-20260306-125258/benchmark-summary.json`
  - `tests/results/engine-comparison/engine-compare-20260306-125258/benchmark-report.md`
- That comparison showed the pre-simplification agentic path was much more expensive/slower than legacy.

## Current Blocker

The simplified 3-case quality comparison runner exists, but the live run still bottlenecks on the Claude legacy generation path before it produces a completed comparison artifact set.

This is not a harness design failure. The runner works. The bottleneck is the runtime behavior of the cogworks execution path itself.

## Partial Rerun Artifacts

Use these only as debugging context:

- `/tmp/cogworks-agentic-quality-v2/cogworks-encode-d8-001`
- `/tmp/cogworks-agentic-live`

The known-good Claude skill workspace is:

- `/tmp/cogworks-agentic-live`

## Exact Next Step

Patch the live cogworks prompt/runtime behavior to reduce unnecessary preamble, repeated skill rereads, and validation churn in the legacy and agentic execution paths.

The goal is not new architecture. The goal is to make one 3-case quality comparison finish.

## After The Patch

Rerun:

```bash
python3 scripts/run-agentic-quality-compare.py \
  --work-root /tmp/cogworks-agentic-quality-v2 \
  --claude-workdir /tmp/cogworks-agentic-live
```

Expected result:

- completed `benchmark-summary.json`
- completed `benchmark-report.md`

## Decision Boundary For Next Session

Allowed outcomes after the rerun:

1. `continue`
2. `simplify`

Do **not** recommend or implement `kill` without explicit user confirmation.
<!-- archived: 2026-03-07 during context-hygiene cleanup; this is historical session handoff material, not an active in-flight plan -->
