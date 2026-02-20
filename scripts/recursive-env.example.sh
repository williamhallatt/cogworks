#!/bin/bash
# shellcheck disable=SC2034

# Benchmark command contracts consumed by scripts/test-cogworks-pipeline.sh
export COGWORKS_BENCH_CLAUDE_CMD="bash scripts/recursive-bench-claude.sh '{sources_path}' '{out_dir}'"
export COGWORKS_BENCH_CODEX_CMD="bash scripts/recursive-bench-codex.sh '{sources_path}' '{out_dir}'"

# Optional real backend commands consumed by recursive benchmark wrappers.
# If unset, wrappers emit deterministic smoke metrics with a warning.
export COGWORKS_RECURSIVE_BENCH_CLAUDE_REAL_CMD=""
export COGWORKS_RECURSIVE_BENCH_CODEX_REAL_CMD=""

# Hook commands consumed by scripts/run-recursive-hook.sh.
# Replace echo statements with your actual generation/improvement commands.
export COGWORKS_RECURSIVE_PRE_ROUND_CMD="echo pre-round checks"
export COGWORKS_RECURSIVE_GENERATE_CMD="echo generate candidates"
export COGWORKS_RECURSIVE_IMPROVE_CMD="echo run improvement skills over pipelines"
export COGWORKS_RECURSIVE_REGENERATE_CMD="echo regenerate pipelines and improvement skills"
export COGWORKS_RECURSIVE_POST_ROUND_CMD="echo post-round bookkeeping"
