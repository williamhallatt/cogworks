# Claude Adapter

Use this document only when `{engine_mode}` is `agentic` and the current surface is Claude Code.

## Goal

Map the agentic runtime onto Claude subagents while preserving: [Source 1][Source 2]
- one coordinator authority surface
- isolated verbose work
- strict role ownership
- benchmarkable outputs under `{run_root}`

## Adapter Defaults

Set:
- `execution_surface = claude-cli`
- `execution_adapter = native-subagents`
- `execution_mode = subagent`
- `specialist_profile_source = canonical-role-specs`

If Claude subagents are unavailable, fall back to:
- `execution_surface = claude-cli`
- `execution_adapter = single-agent-fallback`
- `execution_mode = degraded-single-agent`
- `specialist_profile_source = inline-fallback`

If the `Task` tool is available on the current Claude surface, treat native subagents as available and do not downgrade to `single-agent-fallback`.

Do not misreport fallback execution as native subagent execution.

## Canonical Role Bindings

Canonical role definitions live in:
- `skills/cogworks/role-profiles.json`

For Claude, those canonical role definitions bind to these repo-local agent files:

| Stage | Role | Profile ID | Binding type | Binding ref | Model policy | Preferred dispatch |
|---|---|---|---|---|---|---|
| `source-intake` | `intake-analyst` | `intake-analyst` | `claude-agent-file` | `.claude/agents/cogworks-intake-analyst.md` | `pinned-haiku` | `background` |
| `synthesis` | `synthesizer` | `synthesizer` | `claude-agent-file` | `.claude/agents/cogworks-synthesizer.md` | `pinned-sonnet` | `foreground` |
| `skill-packaging` | `composer` | `composer` | `claude-agent-file` | `.claude/agents/cogworks-composer.md` | `pinned-sonnet` | `foreground` |
| `deterministic-validation` | `validator` | `validator` | `claude-agent-file` | `.claude/agents/cogworks-validator.md` | `pinned-haiku` | `background` |

Before the first specialist dispatch, the coordinator must write `{run_root}/dispatch-manifest.json` recording the canonical profile ID, binding type, binding ref, model policy, preferred dispatch mode, and stage tool scope. Update that manifest when a stage is rerun or downgraded from background to foreground.

If the current surface supports the `Task` tool but any required Claude agent file is missing, stop and surface the runtime misconfiguration instead of silently inventing an inline specialist profile.

## Dispatch Rules

- The coordinator decides when to spawn each role.
- Spawn at most one specialist per stage.
- Prefer fewer total spawns over finer-grained decomposition.
- Do not keep multiple long-lived specialist threads open without a clear dependency reason.
- Reuse the coordinator's cached support-skill contract; do not reopen support SKILL.md files unless a specific blocking rule gap requires it.
- Specialists must not spawn their own subagents.
- If a task needs more decomposition than one specialist can handle, return it to the coordinator as a blocking issue rather than nesting.
- Canonical role profiles are part of the runtime contract. Record the exact Claude binding used for each stage in `dispatch-manifest.json`.

## Coordinator UI Discipline

- Keep user-facing progress terse: one short start or update line is enough.
- Do not narrate the full parsed command, stage graph, or role model unless the user asks.
- If deterministic validators fail, say so plainly and route the work back instead of writing a celebratory summary.

### Spawn Budget

The simplified runtime should usually stay within this envelope:
- `agentic-short-path`: 2-3 specialist spawns total
- `agentic-full-path`: 3-4 specialist spawns total

Do not recreate the old 9-stage fan-out pattern unless the user explicitly asks for deeper benchmarking.

## Background vs Foreground

Use background subagents only when the work is genuinely read-heavy and isolated:
- large source ingestion
- deterministic validation
- targeted probe runs

Use foreground subagents for:
- synthesis
- skill-packaging when precise handoff details matter

If permissions or tool restrictions make background execution brittle, rerun that stage in foreground and record the downgrade in the stage status and dispatch manifest. The `preferred_dispatch_mode` is the default, not a lie license.

## Tool Policy By Role

The generated Claude agent files are the enforcement surface for model tier and base tool allowlist. The rules below describe the intended scope that the coordinator must pass into the dispatch prompt and record in `dispatch-manifest.json`.

### `intake-analyst`
Allowed emphasis:
- read
- grep/search
- directory traversal
- URL fetching when user-approved and supported
- write `source-intake/stage-status.json` plus stage artifacts

Avoid:
- writing outside run artifacts
- editing output skill files

### `synthesizer`
Allowed emphasis:
- read
- synthesis notes written only inside the stage artifact directory
- write `synthesis/stage-status.json`

Avoid:
- final output assembly
- installation actions

### `composer`
Allowed emphasis:
- write final skill files under `{skill_path}` with optional `skill-packaging/skill-draft/` staging
- write metadata and composition notes
- write `skill-packaging/stage-status.json` only after required final files exist

Avoid:
- running final installation
- rewriting upstream stage artifacts

### `validator`
Allowed emphasis:
- read draft skill files
- run validation commands
- write reports under validation stage directories
- write `deterministic-validation/stage-status.json`

Avoid:
- silently mutating synthesis content without routing back through the coordinator
- running a targeted probe unless the run is `agentic-full-path` or validation found a fidelity concern

## Summary Contract

Every Claude subagent must return a compact summary with this shape:

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

Return only the compact summary contract plus the requested artifacts. Do not prepend a long prose recap.

Each specialist must also write its own `stage-status.json` in the stage directory before returning `pass` or `fail`. The coordinator verifies that file, records any higher-level stage index or final summary, and must not overwrite a successful specialist-produced `stage-status.json` unless the stage is being rerun after failure.

Each dispatch record in `dispatch-manifest.json` must record:
- `stage`
- `role`
- `profile_id`
- `binding_type`
- `binding_ref`
- `model_policy`
- `preferred_dispatch_mode`
- `actual_dispatch_mode`
- `tool_scope`
- `status`

## Failure Handling

- Missing required input: fail immediately and return control to the coordinator.
- Permission blockage in background mode: retry once in foreground.
- Empty or low-confidence summary: treat as failed stage; do not infer success.
- If repo validation reports critical generated-skill failures, the stage status must be `fail`; do not downgrade them to warnings.
- If `skill-packaging` claims `pass` before non-empty `SKILL.md`, `reference.md`, and `metadata.json` exist at `{skill_path}`, treat the stage as failed and rerun it with a narrower prompt.
- If the specialist appears to have drifted into another role's responsibility, discard the result and rerun with a narrower prompt.

## Coordinator Prompting Guidance

When spawning a specialist, the coordinator must specify:
- role name
- canonical profile ID
- bound Claude agent file
- stage name
- exact goal
- exact required inputs
- exact expected outputs
- any file-format requirements that are part of the deterministic contract
- tool boundary
- reminder that the specialist may not spawn subagents
- instruction to return only the summary contract plus stage artifacts

## What Counts As Success

The Claude adapter is working correctly when:
- verbose exploration stays in subagent context
- coordinator context receives summaries, not raw logs
- each stage has an explicit owner and artifact record
- each specialist stage maps to a canonical role profile and a concrete Claude agent file with a declared model policy
- no specialist spawns another specialist
- any degraded execution mode is recorded explicitly
- `dispatch-manifest.json` proves which canonical role profiles and Claude bindings were used

## Sources

- [Source 1] [role-profiles.json](role-profiles.json)
- [Source 2] [../../_plans/DECISIONS.md](../../_plans/DECISIONS.md)
