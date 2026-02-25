# Superpowers-Informed Hardening Plan (Accepted 2026-02-21)

## Goal
Harden cogworks skill authoring and testing using high-signal practices from `_sources/superpowers/writing-skills` and adjacent test assets.

## Accepted Scope
1. Tighten behavioral activation provenance and ordering checks.
2. Add multi-turn/isolated harness support for behavioral capture.
3. Add a fast trigger smoke suite for explicit and mid-conversation skill activation.
4. Strengthen skill authoring guidance around trigger-focused descriptions (CSO).
5. Add deterministic warning for workflow-summary leakage in `description`.

## Expected Outputs
- Updated behavioral extraction/validation contracts (`activation_source`, `tool_events`, `order_assertions`).
- Updated capture scripts supporting `conversation_turns`, `harness_mode`, `isolation_mode`.
- New `scripts/run-trigger-smoke-tests.sh` + prompt fixtures.
- `cogworks-learn` reference updates for CSO description discipline.
- Testing/documentation updates reflecting the new gates and commands.
