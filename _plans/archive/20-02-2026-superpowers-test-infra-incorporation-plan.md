# Superpowers-Informed Test Infrastructure Improvements (Accepted 2026-02-20)

## Summary

Incorporate high-signal lessons from `_sources/superpowers/` into the current cogworks test framework without replacing existing architecture.

Focus areas:
- Strengthen behavioral evidence provenance
- Add reusable dual-pipeline trace capture scaffolding
- Add targeted anti-premature-execution behavioral cases
- Keep deterministic checks and benchmark framework intact

## Accepted Decisions

1. Add strict provenance mode to behavioral evaluation:
- `behavioral run --strict-provenance`
- `behavioral validate --strict-provenance`
- Fail traces with missing provenance fields or placeholder values

2. Preserve the existing normalized JSON trace contract and evaluator:
- Do not adopt provider-specific grep/parsing as primary evaluator logic

3. Add dual-pipeline trace-capture scaffolding:
- Wrapper scripts for Claude/Codex
- Shared normalizer that writes framework-compatible trace JSON

4. Add no-premature-execution behavioral scenarios:
- For explicit activation requests that should not execute shell commands yet
- Use `forbidden_commands` assertions

5. Apply strict provenance in decision-critical recursive rounds:
- Both Claude and Codex behavioral runs in `scripts/run-recursive-round.sh`

## Out of Scope

- Replacing Layer 1 deterministic checks
- Replacing the pipeline benchmark scorer
- Full migration to superpowers-specific CLI harnessing
