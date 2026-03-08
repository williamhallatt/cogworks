# Sub-Agent Build Runtime

Maintainer-only reference for the internal `cogworks` sub-agent build path.

This document describes implementation machinery, not a public product mode.

## Purpose

The sub-agent build path exists to improve:
- synthesis quality
- context isolation
- stage ownership
- trustworthiness of the final generated skill

It preserves the generated skill as the primary artifact.

## Supported Surfaces

Use this runtime only on surfaces with a proven delegated-task primitive:
- `claude-cli`
- `copilot-cli`

Codex is out of scope for this runtime in the current phase.

If the current surface cannot provide the validated sub-agent path, the build
should fail closed rather than degrade and present the result as equivalent.

## Execution Model

The runtime has three layers:
1. **Pipeline core**: stage order, blocking rules, retries
2. **Role model**: one specialist owner per stage
3. **Surface adapter**: concrete Claude or Copilot bindings

Defaults:
- `run_type = subagent-skill-build`
- `specialist_profile_source = canonical-role-specs`
- the coordinator is the only role allowed to dispatch specialists
- no recursive sub-agent spawning

Canonical role definitions live in:
- `skills/cogworks/role-profiles.json`

## Stage Graph

Execute stages in this order:
1. `source-intake`
2. `synthesis`
3. `skill-packaging`
4. `deterministic-validation`
5. `final-review`

### Stage ownership

| Stage | Owner | Required outputs |
|---|---|---|
| `source-intake` | `intake-analyst` | `source-inventory.json`, `source-manifest.json`, `source-trust-report.md`, `source-trust-gate.json` |
| `synthesis` | `synthesizer` | `synthesis.md`, `cdr-registry.md`, `traceability-map.md` |
| `skill-packaging` | `composer` | `decision-skeleton.json`, final skill files at `{skill_path}` |
| `deterministic-validation` | `validator` | deterministic report, final gate report |
| `final-review` | `coordinator` | `final-summary.md`, `stage-index.json` |

## Blocking Rules

- A stage may not start until all required inputs exist and are non-empty.
- Each specialist-owned stage must write its own `stage-status.json` before
  returning `pass`.
- The coordinator verifies specialist-authored status files and must not rewrite
  a successful specialist-authored `stage-status.json`.
- `synthesis` must not start until
  `source-intake/source-trust-gate.json` exists with `gate_passed: true`.
- Any critical failure from `validate-synthesis.sh` or `validate-skill.sh`
  blocks `deterministic-validation`.
- `final-review` may not start while generated-skill validation still has
  critical failures.
- The coordinator must never summarize around a failed stage.

## Retry Policy

Default maximum retries:
- `synthesis`: 1
- `skill-packaging`: 1
- `validator`: 1 rerun after a fix

If the same stage fails twice for the same blocking reason, stop and surface the
issue to the user.

## Run Directory Layout

Write runtime artifacts to:

```text
{run_root}/
  run-manifest.json
  dispatch-manifest.json
  stage-index.json
  final-summary.md
  source-intake/
    stage-status.json
    source-trust-gate.json
    ...artifacts...
  synthesis/
    stage-status.json
    ...artifacts...
  skill-packaging/
    stage-status.json
    ...artifacts...
  deterministic-validation/
    stage-status.json
    ...artifacts...
  final-review/
    stage-status.json
    ...artifacts...
```

## Run Manifest Contract

`run-manifest.json` must include:
- `run_id`
- `run_type`
- `execution_surface`
- `specialist_profile_source`
- `topic`
- `skill_path`
- `started_at`
- `stages_expected`

Required values:
- `run_type = subagent-skill-build`
- `execution_surface = claude-cli | copilot-cli`
- `specialist_profile_source = canonical-role-specs`

## Dispatch Manifest Contract

`dispatch-manifest.json` is required for this runtime.

Top-level fields:
- `profile_source`
- `execution_surface`
- `agent_definition_source`
- `dispatches`

Each dispatch record must include:
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

## Success Criteria

The sub-agent build runtime is working correctly when:
- the generated skill at `{skill_path}` contains non-empty `SKILL.md`,
  `reference.md`, and `metadata.json`
- the run root contains a complete five-stage record
- trust gating happens before synthesis
- each specialist stage maps to a canonical role profile and a concrete surface
  binding
- no specialist spawns another specialist
- the generated skill does not leak runtime metadata into public frontmatter or
  `metadata.json`

## Sources

- [Source 1] [role-profiles.json](role-profiles.json)
- [Source 2] [../../_plans/DECISIONS.md](../../_plans/DECISIONS.md)
