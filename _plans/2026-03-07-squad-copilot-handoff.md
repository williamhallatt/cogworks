# Squad Copilot Handoff

## Current State

Cogworks has already been generalized from a Claude-specific agentic runtime to a surface-neutral one.

What is already in place:
- Canonical role specs live in `skills/cogworks/role-profiles.json`
- Claude role bindings are derived under `.claude/agents/`
- Copilot adapter exists in `skills/cogworks/copilot-adapter.md`
- The runtime contract now uses `execution_surface`, `execution_adapter`, `execution_mode`, and `specialist_profile_source`
- Native-subagent runs require a generalized `dispatch-manifest.json`
- `scripts/validate-agentic-run.sh` validates both Claude and Copilot runs
- Static contract checks are passing

What is not yet closed:
- There is not yet a saved live Copilot CLI run proving whether Copilot supports `native-subagents` or only `single-agent-fallback`

## Constraints

- Do not redesign the runtime contract
- Do not revert unrelated worktree changes
- Do not weaken generated-skill validation gates
- Do not invent a `.copilot/agents/` format
- Do not claim per-role model pinning on Copilot
- Do not claim `native-subagents` unless Copilot CLI actually exposes a real spawn primitive
- Prefer one saved, validated Copilot smoke run over more speculative design work

## Work Split

### Kane

Break this into tightly scoped implementation issues with acceptance criteria. Do not assign `@copilot` until the issue text is precise.

### Lambert

Own Copilot surface truth:
- determine the real Copilot CLI invocation surface for `cogworks encode --engine agentic`
- determine whether Copilot exposes a real subagent or agent-spawn primitive
- determine whether the honest outcome is `native-subagents` or `single-agent-fallback`
- document only proven behavior

### Dallas

Own runtime closure after Lambert’s findings:
- align runtime behavior and artifacts with the proven Copilot surface
- fix any remaining mismatch between `copilot-adapter.md`, emitted manifests, and validator expectations
- preserve the canonical role-spec model and honest fallback behavior

### Hudson

Own live validation:
- run one live Copilot smoke using `tests/agentic-smoke/fixtures/api-auth-smoke/`
- validate it with `scripts/validate-agentic-run.sh`
- save the run root, validator output, and observed capability result

## Definition of Done

A Copilot handoff is complete only when:
- one validated Copilot agentic run exists
- `run-manifest.json` honestly records `execution_surface = copilot-cli`
- `execution_adapter` is honestly recorded as either `native-subagents` or `single-agent-fallback`
- `dispatch-manifest.json` exists for native-subagent runs and matches the generalized schema
- generated skill output passes deterministic validation
- docs reflect proven Copilot behavior rather than assumptions

## Validation Sequence

1. `bash scripts/test-agentic-contract.sh`
2. `bash tests/framework/graders/deterministic-checks.sh skills/cogworks`
3. Run one live Copilot smoke
4. Validate with:

```bash
bash scripts/validate-agentic-run.sh \
  --run-root <run-root> \
  --skill-path <skill-path> \
  --expect-surface copilot-cli \
  --expect-adapter <native-subagents|single-agent-fallback>
```

## Pointers

Read these first:
- `_plans/DECISIONS.md` (especially D-028 and D-029)
- `skills/cogworks/copilot-adapter.md`
- `skills/cogworks/role-profiles.json`
- `scripts/validate-agentic-run.sh`
- `tests/agentic-smoke/README.md`
- `docs/cross-agent-compatibility.md`
