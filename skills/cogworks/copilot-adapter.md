# Copilot Adapter

Use this document only when `{engine_mode}` is `agentic` and the current surface is GitHub Copilot CLI.

## Goal

Map the agentic runtime onto Copilot CLI while preserving the same five-stage contract, the same generated-skill output contract, and honest evidence about what the surface actually provided. [Source 1][Source 2]

## Adapter Defaults

Set:
- `execution_surface = copilot-cli`
- `execution_adapter = native-subagents` when Copilot CLI exposes a real subagent or agent-spawn primitive
- `execution_mode = subagent` when native subagents are available
- `specialist_profile_source = canonical-role-specs` for native-subagent runs

If Copilot CLI does not expose a real subagent primitive, fall back to:
- `execution_surface = copilot-cli`
- `execution_adapter = single-agent-fallback`
- `execution_mode = degraded-single-agent`
- `specialist_profile_source = inline-fallback`

Do not invent Copilot-native subagent support if the surface only supports a single-agent conversation.

## Agent Registration

Copilot CLI reads `.claude/agents/` for agent definitions. The four cogworks specialist files in that directory are available to Copilot CLI's `task` tool under the same names (`cogworks-intake-analyst`, `cogworks-synthesizer`, `cogworks-composer`, `cogworks-validator`). No separate `.github/agents/cogworks-*.agent.md` files are required.

Copilot CLI ignores Claude-specific frontmatter fields (`model`, `color`, `permissionMode`, `isolation`, etc.) from those files. Model policy falls back to `inherit-session-model` — which is the correct Copilot default.

## Capability Detection

Treat Copilot CLI as capability-based:
- if the surface exposes a native subagent or agent-spawn primitive, use `native-subagents`
- if it does not, use `single-agent-fallback`
- do not assume per-role model pinning — Copilot uses `inherit-session-model` regardless of the Claude frontmatter

The adapter must record what happened, not what was desired.

## Canonical Role Bindings

Canonical role definitions live in:
- `skills/cogworks/role-profiles.json`

For Copilot CLI, use the same canonical profile IDs as Claude:

| Stage | Role | Profile ID | Binding type | Binding ref | Model policy | Preferred dispatch |
|---|---|---|---|---|---|---|
| `source-intake` | `intake-analyst` | `intake-analyst` | `copilot-inline-prompt` | `skills/cogworks/role-profiles.json#intake-analyst` | `inherit-session-model` | `background` |
| `synthesis` | `synthesizer` | `synthesizer` | `copilot-inline-prompt` | `skills/cogworks/role-profiles.json#synthesizer` | `inherit-session-model` | `foreground` |
| `skill-packaging` | `composer` | `composer` | `copilot-inline-prompt` | `skills/cogworks/role-profiles.json#composer` | `inherit-session-model` | `foreground` |
| `deterministic-validation` | `validator` | `validator` | `copilot-inline-prompt` | `skills/cogworks/role-profiles.json#validator` | `inherit-session-model` | `background` |

There is no v1 `.copilot/agents/` file format contract. Specialist agent definitions are sourced from `.claude/agents/cogworks-*.md` — those files are read by both Claude Code and Copilot CLI. Record the canonical role profile binding in `dispatch-manifest.json`.

## Dispatch Rules

- The coordinator decides when to spawn each role.
- Spawn at most one specialist per stage.
- Preserve the same stage order, retry policy, and blocking rules as the core runtime.
- Specialists must not spawn subagents.
- If the current Copilot CLI surface only supports blocking specialist execution, record `actual_dispatch_mode = foreground` even when the preferred dispatch mode was `background`.
- If the surface supports parallel subagent launches in one turn, record `actual_dispatch_mode = background` for the relevant stages.

## Model Policy

Copilot CLI v1 must not claim per-role model pinning unless live testing proves it.

Default rule:
- `model_policy = inherit-session-model`

The dispatch manifest should record that value explicitly instead of pretending Copilot used a cheaper or deeper specialist model.

## Summary Contract

Every Copilot specialist prompt must require the same compact summary contract as Claude:

```text
Stage: <stage-name>
Status: pass | fail
Artifacts:
- <artifact-path>
- <artifact-path>
Blocking failures:
- <failure or "none">
Warnings:
- <warning or "none">
Recommended next action: <single sentence>
```

The runtime must preserve the same stage artifact requirements and `stage-status.json` ownership rules as the Claude adapter.

## What Counts As Success

The Copilot adapter is working correctly when:
- the same five-stage contract runs on Copilot CLI
- generated-skill validation remains the hard gate
- native-subagent runs emit `dispatch-manifest.json` with Copilot bindings and `inherit-session-model`
- fallback runs are explicit and never masquerade as native subagent runs
- no Claude-only mechanism is assumed where Copilot CLI has not proven it

## Sources

- [Source 1] [role-profiles.json](role-profiles.json)
- [Source 2] [../../_plans/DECISIONS.md](../../_plans/DECISIONS.md)
