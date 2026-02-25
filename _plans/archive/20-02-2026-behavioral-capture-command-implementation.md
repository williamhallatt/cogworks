# Behavioral Capture Command Implementation Plan (Accepted 2026-02-20)

## Summary

Implement decision-grade behavioral capture via per-pipeline adapter scripts and keep environment-configured command templates as the canonical integration point.

## Decisions

- Capture mode: decision-grade real capture only
- Adapter shape: per-pipeline scripts
- Script naming: `scripts/behavioral-capture-claude.sh` and `scripts/behavioral-capture-codex.sh`

## Interfaces

- `COGWORKS_BEHAVIORAL_CLAUDE_CAPTURE_CMD`
- `COGWORKS_BEHAVIORAL_CODEX_CAPTURE_CMD`
- `COGWORKS_BEHAVIORAL_CLAUDE_REAL_CMD`
- `COGWORKS_BEHAVIORAL_CODEX_REAL_CMD`

Capture command template values:

```bash
export COGWORKS_BEHAVIORAL_CLAUDE_CAPTURE_CMD="bash scripts/behavioral-capture-claude.sh '{skill_slug}' '{case_id}' '{case_json_path}' '{raw_trace_path}'"
export COGWORKS_BEHAVIORAL_CODEX_CAPTURE_CMD="bash scripts/behavioral-capture-codex.sh '{skill_slug}' '{case_id}' '{case_json_path}' '{raw_trace_path}'"
```

Real command template placeholders required:

- `{skill_slug}`
- `{case_id}`
- `{case_json_path}`
- `{raw_trace_path}`

## Raw Trace Contract

Required JSON fields:

- `activated` (bool)
- `tools_used` (array)
- `commands` (array)
- `files_modified` (array)
- `files_created` (array)

Optional fields:

- `task_completed`
- `quality_score`
- `baseline_run`
- `notes`

## Acceptance Tests

1. Adapter scripts fail fast when required `*_REAL_CMD` env vars are not set.
2. Adapter scripts fail when raw output is missing or does not satisfy required key/type contract.
3. `bash scripts/refresh-behavioral-traces.sh --mode capture` succeeds with wrapper templates plus real command templates set.
4. `bash scripts/refresh-behavioral-traces.sh --mode validate` passes strict provenance for both pipelines.
