# Final Summary — api-auth-smoke

**Run ID:** copilot-native-subagents-api-auth-smoke-example-20260307
**Surface:** copilot-cli
**Adapter:** native-subagents
**Model policy:** inherit-session-model
**Agentic path:** agentic-short-path

## Stage Outcomes

| Stage | Status |
|-------|--------|
| source-intake | pass |
| synthesis | pass |
| skill-packaging | pass |
| deterministic-validation | pass |
| final-review | pass |

## Generated Skill

Output: `tests/agentic-smoke/examples/copilot-native-subagents-api-auth-smoke/skill-output/SKILL.md`

The skill covers HTTP 401/403 semantics for API authentication, token failure handling, and the WWW-Authenticate header obligation. Coverage gaps (refresh tokens, revocation, step-up auth) are documented and out of scope for this source set.

## Execution Notes

Dispatches ran in foreground mode. Copilot CLI does not expose background parallel dispatch in v1; `actual_dispatch_mode = foreground` for all stages. `native-subagents` adapter confirmed: specialist agents sourced from `.claude/agents/` and dispatched via Copilot `task` tool.
