---
name: "cogworks-agentic"
description: "How Squad coordinates a cogworks agentic run on Copilot CLI using the task tool and role-profiles.json"
domain: "cogworks-pipeline"
confidence: "high"
source: "live-run"
validated_by: "scripts/validate-agentic-run.sh (50/50 checks passed, 2026-03-07)"
---

## Context

cogworks v4+ has two execution engines: `legacy` (default) and `agentic` (opt-in via `--engine agentic`). The agentic engine runs a 5-stage pipeline using specialist sub-agents.

Squad IS the natural cogworks coordinator on Copilot CLI. This skill encodes how to run and validate an agentic cogworks pipeline from within a Copilot session.

## Key Facts

### Agent Registration

Copilot CLI reads `.claude/agents/` for agent definitions. The four cogworks specialists are registered there and available to Squad's `task` tool:

- `cogworks-intake-analyst` — source-intake stage
- `cogworks-synthesizer` — synthesis stage
- `cogworks-composer` — skill-packaging stage
- `cogworks-validator` — deterministic-validation stage

**No `.github/agents/cogworks-*.agent.md` files are needed.** `.claude/agents/` is shared infrastructure for both platforms.

### Adapter Values (Copilot CLI)

```
execution_surface = copilot-cli
execution_adapter = native-subagents   ← confirmed via live run
execution_mode = subagent
specialist_profile_source = canonical-role-specs
model_policy = inherit-session-model   ← Copilot ignores per-agent model frontmatter
```

Copilot ignores Claude-specific frontmatter fields (`model:`, `color:`, etc.) in `.claude/agents/` files. All stages run with the session model.

**Dispatch modes**: Copilot v1 does not expose parallel background dispatch. All stages run in `actual_dispatch_mode = foreground`. Record this honestly — do not claim `background` unless future testing proves it.

### Canonical Role Definitions

Canonical specs live in `skills/cogworks/role-profiles.json`. The `.claude/agents/` files are derived bindings. If role specs change, update `role-profiles.json` first.

## Patterns

### Running a Cogworks Agentic Pipeline

Dispatch each stage in sequence using the `task` tool:

```
1. cogworks-intake-analyst  → source-intake artifacts
2. cogworks-synthesizer     → synthesis artifacts
3. cogworks-composer        → skill-packaging + generated skill
4. cogworks-validator       → deterministic-validation artifacts
5. write run-manifest.json, dispatch-manifest.json, stage-index.json, final-summary.md
6. run final-review (coordinator can write these directly)
```

Each stage specialist returns a compact summary. Proceed to the next stage only on `Status: pass`.

### Required Run Artifacts

Every agentic run must produce:

```
{run_root}/
  run-manifest.json           ← run_id, engine_mode, execution_surface, execution_adapter, stages_expected
  dispatch-manifest.json      ← profile_source, execution_surface, execution_adapter, dispatches[]
  stage-index.json
  final-summary.md  OR  final-review/final-summary.md
  source-intake/
    source-inventory.json
    source-manifest.json
    source-trust-report.md
    stage-status.json
  synthesis/
    synthesis.md              ← NOT synthesis-notes.md — the validator checks synthesis.md
    cdr-registry.md
    traceability-map.md
    stage-status.json
  skill-packaging/
    decision-skeleton.json
    composition-notes.md
    stage-status.json
  deterministic-validation/
    deterministic-gate-report.json
    final-gate-report.json
    stage-status.json
  final-review/
    stage-status.json
    final-summary.md

{skill_path}/
  SKILL.md        ← must have YAML frontmatter with name: and description:
  reference.md    ← must have TL;DR, Decision Rules, Anti-Patterns, Quick Reference, Sources sections
  metadata.json   ← must have skill_name, engine_mode, execution_surface, generated_at
```

### dispatch-manifest.json Top-Level Fields (required)

```json
{
  "profile_source": "canonical-role-specs",    ← NOT "specialist_profile_source"
  "execution_surface": "copilot-cli",
  "execution_adapter": "native-subagents",
  "dispatches": [...]
}
```

Each dispatch record requires: `stage`, `role`, `profile_id`, `binding_type`, `binding_ref`, `model_policy`, `preferred_dispatch_mode`, `actual_dispatch_mode`, `tool_scope`, `status`.

For Copilot CLI: `binding_type = "copilot-inline-prompt"`, `binding_ref = "skills/cogworks/role-profiles.json#{role}"`.

### reference.md Required Sections

The synthesis validator checks for these headings (case-insensitive):
- `TL;DR`
- `Decision Rules`
- `Anti-Patterns`
- `Quick Reference`
- `Sources`

Missing any of these is a critical failure.

## Validation

After every agentic run, validate before claiming success:

```bash
bash scripts/validate-agentic-run.sh \
  --run-root <run-root> \
  --skill-path <skill-path> \
  --expect-surface copilot-cli \
  --expect-adapter native-subagents
```

Static contract checks (no live run needed):
```bash
bash scripts/test-agentic-contract.sh
bash tests/framework/graders/deterministic-checks.sh skills/cogworks
```

Smoke fixture: `tests/agentic-smoke/fixtures/api-auth-smoke/`

## Anti-Patterns

- **Claiming `native-subagents` without a live run.** Prove it; don't assert it.
- **Creating `.github/agents/cogworks-*.agent.md` files.** Not needed — `.claude/agents/` serves both platforms.
- **Using `synthesis-notes.md` instead of `synthesis.md`.** The validator checks `synthesis.md` specifically.
- **Using `specialist_profile_source` as the dispatch-manifest top-level key.** The validator checks for `profile_source`.
- **Omitting `preferred_dispatch_mode` or `tool_scope` from dispatch records.** The validator checks both.
- **Claiming per-role model pinning.** Copilot uses `inherit-session-model` — document this honestly.

## Source References

- `skills/cogworks/copilot-adapter.md` — Copilot surface adapter contract
- `skills/cogworks/role-profiles.json` — canonical role specs
- `skills/cogworks/agentic-runtime.md` — 5-stage runtime contract
- `.claude/agents/cogworks-*.md` — specialist agent definitions (shared with Claude Code)
- `scripts/validate-agentic-run.sh` — official run validator
- `tests/agentic-smoke/README.md` — live smoke runbook
- `_plans/2026-03-07-squad-copilot-handoff.md` — Codex handoff that initiated this work
