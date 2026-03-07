# Copilot CLI Agentic Adapter Plan

## Status

Accepted and completed on 2026-03-07.

## Summary

Implement Copilot support as a native `copilot-cli` adapter for the existing 5-stage agentic runtime, but only after generalizing the runtime contract so both Claude and Copilot fit the same truthful execution model.

## Decisions

- Generalize the runtime contract from a Claude-specific schema to a surface-neutral schema with:
  - `execution_surface`
  - `execution_adapter`
  - `execution_mode`
  - `specialist_profile_source`
- Introduce one canonical source of truth for specialist roles in `skills/cogworks/role-profiles.json`.
- Derive Claude role-agent files from those canonical role specs instead of treating `.claude/agents/*.md` as the source of truth.
- Add a dedicated `copilot-adapter.md` that uses the same canonical role IDs with `copilot-inline-prompt` bindings.
- Require native-subagent runs to emit a generalized `dispatch-manifest.json` containing:
  - `profile_id`
  - `binding_type`
  - `binding_ref`
  - `model_policy`
  - `preferred_dispatch_mode`
  - `actual_dispatch_mode`
  - `tool_scope`
  - `status`
- Keep Copilot honest:
  - default `model_policy = inherit-session-model`
  - do not invent a `.copilot/agents/` format
  - do not claim native subagents unless the surface actually exposes a spawn primitive

## Scope

- `skills/cogworks/SKILL.md`
- `skills/cogworks/agentic-runtime.md`
- `skills/cogworks/claude-adapter.md`
- `skills/cogworks/copilot-adapter.md`
- `skills/cogworks/role-profiles.json`
- `.claude/agents/cogworks-intake-analyst.md`
- `.claude/agents/cogworks-synthesizer.md`
- `.claude/agents/cogworks-composer.md`
- `.claude/agents/cogworks-validator.md`
- `scripts/render-agentic-role-bindings.py`
- `scripts/validate-agentic-run.sh`
- `scripts/run-agentic-quality-compare.py`
- `scripts/compare-engine-performance.py`
- `scripts/test-agentic-contract.sh`
- `README.md`
- `skills/cogworks/README.md`
- `TESTING.md`
- `tests/agentic-smoke/README.md`

## Verification

- `python3 -m py_compile scripts/render-agentic-role-bindings.py scripts/run-agentic-quality-compare.py scripts/compare-engine-performance.py`
- `bash scripts/test-agentic-contract.sh`
- `bash tests/framework/graders/deterministic-checks.sh skills/cogworks`
