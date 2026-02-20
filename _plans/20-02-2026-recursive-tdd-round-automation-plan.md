# Recursive TDD Round Automation Plan (Accepted)

## Summary

Automate cogworks self-improvement as round-based recursion without template-enforced structural constraints. Preserve evolution freedom in pipeline/skill content, while gating promotion on outcome metrics and a minimal immutable contract.

## Key Decisions

1. Keep immutable core minimal:
   - runtime/tool-contract correctness
   - artifact schema and lineage outputs
2. Freeze evolving tests at round boundaries via manifest + test bundle hash.
3. Select winners by guardrails + weighted score under explicit cost/runtime caps.
4. Keep benchmark offline mode as smoke signal only.

## Implementation Scope

1. Add recursive round orchestrator script:
   - `scripts/run-recursive-round.sh`
2. Add test bundle hasher:
   - `scripts/hash-test-bundle.sh`
3. Add round manifest example:
   - `tests/datasets/recursive-round/round-manifest.example.json`
4. Update user-facing docs:
   - `README.md`
   - `TESTING.md`
   - `tests/framework/README.md`
5. Remove prior template-enforcement automation artifacts from active workflow.

## Acceptance Criteria

1. Round runs fail fast if frozen test hash mismatches.
2. Hook-based generation/improvement commands can be executed from manifest.
3. Fast round runs invariant + behavioral checks and writes summary/report artifacts.
4. Deep round runs benchmark and only becomes decision-grade when `ranking_eligible=true`.
5. Output artifacts include round lineage and selection policy details.
