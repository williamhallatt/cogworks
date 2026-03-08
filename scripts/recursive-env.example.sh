#!/bin/bash
# shellcheck disable=SC2034

# Hook commands consumed by scripts/run-recursive-hook.sh.
# Replace echo statements with your actual generation/improvement commands.
export COGWORKS_RECURSIVE_PRE_ROUND_CMD="echo pre-round checks"
export COGWORKS_RECURSIVE_GENERATE_CMD="echo generate candidates"
export COGWORKS_RECURSIVE_IMPROVE_CMD="echo run improvement skills over pipelines"
export COGWORKS_RECURSIVE_REGENERATE_CMD="echo regenerate pipelines and improvement skills"
export COGWORKS_RECURSIVE_POST_ROUND_CMD="echo post-round bookkeeping"
