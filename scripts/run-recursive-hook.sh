#!/bin/bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <pre_round|generate|improve|regenerate|post_round>" >&2
  exit 2
fi

phase="$1"
var_name=""

case "$phase" in
  pre_round)
    var_name="COGWORKS_RECURSIVE_PRE_ROUND_CMD"
    ;;
  generate)
    var_name="COGWORKS_RECURSIVE_GENERATE_CMD"
    ;;
  improve)
    var_name="COGWORKS_RECURSIVE_IMPROVE_CMD"
    ;;
  regenerate)
    var_name="COGWORKS_RECURSIVE_REGENERATE_CMD"
    ;;
  post_round)
    var_name="COGWORKS_RECURSIVE_POST_ROUND_CMD"
    ;;
  *)
    echo "Invalid phase: $phase" >&2
    exit 2
    ;;
esac

cmd="${!var_name:-}"
if [[ -z "$cmd" ]]; then
  echo "[$phase] No command configured in $var_name; skipping phase."
  exit 0
fi

echo "[$phase] Executing: $cmd"
bash -lc "$cmd"
