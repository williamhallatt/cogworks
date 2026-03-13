# Copilot Adapter

Maintainer-only reference for mapping the internal sub-agent build runtime onto
GitHub Copilot CLI.

## Goal

Use Copilot delegated-task support while preserving the same five-stage build
contract, the same generated-skill output contract, and truthful evidence about
what the surface actually provided.

## Adapter Defaults

Set:
- `execution_surface = copilot-cli`
- `specialist_profile_source = canonical-role-specs`
- `model_policy = inherit-session-model`

This adapter is valid only when Copilot exposes the delegated-task behavior
required for the sub-agent build path. If it does not, stop and surface that
limitation rather than inventing an equivalent-looking fallback.

Copilot ignores Claude-specific model pinning, so `inherit-session-model` is
the truthful default policy.

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

Executable project-scoped Copilot agents are generated from those canonical role
profiles with:

```bash
python3 scripts/render-agentic-role-bindings.py --surface copilot-cli
```

This materializes `.github/agents/cogworks-*.agent.md` files. The JSON role
profiles remain canonical; the `.github/agents/` files are the executable
bridge Copilot CLI consumes.

Record the canonical role binding and the truthful model policy in
`dispatch-manifest.json`.

## Dispatch Rules

- The coordinator decides when to spawn each role.
- Spawn at most one specialist per stage.
- Preserve the same stage order and blocking rules as the core runtime.
- Specialists must not spawn sub-agents.
- Record the actual dispatch mode honestly. If the surface only supports
  foreground task execution, `actual_dispatch_mode = foreground` for that run.

## Summary Contract

Every Copilot specialist must return the same compact summary contract as the
Claude adapter.

## What Counts As Success

The Copilot adapter is working correctly when:
- the same five-stage contract runs on Copilot CLI
- generated-skill validation remains the hard gate
- `dispatch-manifest.json` records Copilot bindings and `inherit-session-model`
- no Claude-only capability is assumed where Copilot has not proven it

## Sources

- [Source 1] [role-profiles.json](role-profiles.json)
- [Source 2] [../../_plans/DECISIONS.md](../../_plans/DECISIONS.md)
