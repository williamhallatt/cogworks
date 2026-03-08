# Claude Adapter

Maintainer-only reference for mapping the internal sub-agent build runtime onto
Claude Code.

## Goal

Use Claude sub-agents to preserve:
- one coordinator authority surface
- isolated verbose work
- strict role ownership
- truthful run artifacts under `{run_root}`

## Adapter Defaults

Set:
- `execution_surface = claude-cli`
- `specialist_profile_source = canonical-role-specs`

If the `Task` tool is unavailable, the current Claude surface does not satisfy
the validated sub-agent build path. Stop and surface that limitation rather than
pretending equivalence.

## Canonical Role Bindings

Canonical role definitions live in:
- `skills/cogworks/role-profiles.json`

Claude binds them to these repo-local agent files:

| Stage | Role | Profile ID | Binding type | Binding ref | Model policy | Preferred dispatch |
|---|---|---|---|---|---|---|
| `source-intake` | `intake-analyst` | `intake-analyst` | `claude-agent-file` | `.claude/agents/cogworks-intake-analyst.md` | `pinned-haiku` | `background` |
| `synthesis` | `synthesizer` | `synthesizer` | `claude-agent-file` | `.claude/agents/cogworks-synthesizer.md` | `pinned-sonnet` | `foreground` |
| `skill-packaging` | `composer` | `composer` | `claude-agent-file` | `.claude/agents/cogworks-composer.md` | `pinned-sonnet` | `foreground` |
| `deterministic-validation` | `validator` | `validator` | `claude-agent-file` | `.claude/agents/cogworks-validator.md` | `pinned-haiku` | `background` |

Before the first specialist dispatch, the coordinator must write
`{run_root}/dispatch-manifest.json` recording the canonical profile ID, binding
type, binding ref, model policy, preferred dispatch mode, actual dispatch mode,
and tool scope.

If any required Claude agent file is missing, stop and surface the runtime
misconfiguration.

## Dispatch Rules

- The coordinator decides when to spawn each role.
- Spawn at most one specialist per stage.
- Prefer fewer total spawns over finer-grained decomposition.
- Specialists must not spawn their own sub-agents.
- If a background dispatch is blocked by permissions or tooling limits, rerun
  that stage in foreground and record the actual mode honestly.

## Summary Contract

Every Claude specialist must return this compact summary:

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

Each specialist must also write its own `stage-status.json`.

## What Counts As Success

The Claude adapter is working correctly when:
- verbose exploration stays in sub-agent context
- coordinator context receives summaries, not raw logs
- each specialist stage maps to a canonical role profile and concrete Claude
  agent file
- no specialist spawns another specialist
- `dispatch-manifest.json` proves which canonical role profiles and Claude
  bindings were used

## Sources

- [Source 1] [role-profiles.json](role-profiles.json)
- [Source 2] [../../_plans/DECISIONS.md](../../_plans/DECISIONS.md)
