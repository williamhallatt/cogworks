# Behavioral Trace Capture: Open Decision Log (2026-02-20)

## Status

Resolved on 2026-02-20.

Implemented command wrappers:
- `scripts/behavioral-capture-claude.sh`
- `scripts/behavioral-capture-codex.sh`
- `scripts/run-behavioral-case-claude.sh`
- `scripts/run-behavioral-case-codex.sh`

Canonical templates:

```bash
export COGWORKS_BEHAVIORAL_CLAUDE_CAPTURE_CMD="bash scripts/behavioral-capture-claude.sh '{skill_slug}' '{case_id}' '{case_json_path}' '{raw_trace_path}'"
export COGWORKS_BEHAVIORAL_CODEX_CAPTURE_CMD="bash scripts/behavioral-capture-codex.sh '{skill_slug}' '{case_id}' '{case_json_path}' '{raw_trace_path}'"
```

Wrappers require:
- `COGWORKS_BEHAVIORAL_CLAUDE_REAL_CMD`
- `COGWORKS_BEHAVIORAL_CODEX_REAL_CMD`

## User Question

"Why aren't they configured yet?"

Context: This refers to `COGWORKS_BEHAVIORAL_CLAUDE_CAPTURE_CMD` and `COGWORKS_BEHAVIORAL_CODEX_CAPTURE_CMD` required by `scripts/refresh-behavioral-traces.sh`.

## Decision Recorded

No default capture commands were configured in-repo yet.

Reason:
- The repository currently has the framework contract and refresh runner, but no canonical end-to-end capture harness for both pipelines that can reliably:
  1. Execute a behavioral case, and
  2. Emit raw JSON to `{raw_trace_path}`.

Therefore, capture commands remain explicit environment configuration, not hardcoded defaults.

## Current State

- Implemented:
  - `scripts/refresh-behavioral-traces.sh`
  - `scripts/capture-behavioral-trace-claude.sh`
  - `scripts/capture-behavioral-trace-codex.sh`
  - Strict provenance enforcement in behavioral eval and recursive rounds
- Outstanding:
  - Provide concrete capture command implementations for Claude and Codex pipelines

## Required Inputs To Resume

Provide one command template per pipeline:

- `COGWORKS_BEHAVIORAL_CLAUDE_CAPTURE_CMD`
- `COGWORKS_BEHAVIORAL_CODEX_CAPTURE_CMD`

Each must support placeholders:
- `{skill_slug}`
- `{case_id}`
- `{case_json_path}`
- `{raw_trace_path}`

Expected output contract at `{raw_trace_path}` (JSON object):
- `activated` (bool)
- `tools_used` (array)
- `commands` (array)
- `files_modified` (array)
- `files_created` (array)
- optional: `task_completed`, `quality_score`, `baseline_run`, `notes`

## Restart Command

After capture templates are provided:

```bash
export COGWORKS_BEHAVIORAL_CLAUDE_CAPTURE_CMD="<your claude capture command>"
export COGWORKS_BEHAVIORAL_CODEX_CAPTURE_CMD="<your codex capture command>"
bash scripts/refresh-behavioral-traces.sh --mode all
```
