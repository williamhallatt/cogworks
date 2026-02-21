#!/bin/bash

# Real capture runners (decision-grade target)
export COGWORKS_BEHAVIORAL_CLAUDE_REAL_CMD="bash scripts/run-behavioral-case-claude.sh '{skill_slug}' '{case_id}' '{case_json_path}' '{raw_trace_path}'"
export COGWORKS_BEHAVIORAL_CODEX_REAL_CMD="bash scripts/run-behavioral-case-codex.sh '{skill_slug}' '{case_id}' '{case_json_path}' '{raw_trace_path}'"

# Canonical capture wrapper templates consumed by refresh-behavioral-traces.sh
export COGWORKS_BEHAVIORAL_CLAUDE_CAPTURE_CMD="bash scripts/behavioral-capture-claude.sh '{skill_slug}' '{case_id}' '{case_json_path}' '{raw_trace_path}'"
export COGWORKS_BEHAVIORAL_CODEX_CAPTURE_CMD="bash scripts/behavioral-capture-codex.sh '{skill_slug}' '{case_id}' '{case_json_path}' '{raw_trace_path}'"

# Optional tuning
# export COGWORKS_BEHAVIORAL_EVENTS_ROOT="/tmp/cogworks-behavioral-raw"
# export COGWORKS_BEHAVIORAL_CLAUDE_TIMEOUT_SEC="900"
# export COGWORKS_BEHAVIORAL_CODEX_TIMEOUT_SEC="900"
# export COGWORKS_BEHAVIORAL_CLAUDE_PERMISSION_MODE="default"
