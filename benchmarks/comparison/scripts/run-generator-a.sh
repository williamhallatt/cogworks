#!/bin/bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <sources_path> <out_dir>" >&2
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
sources_path="$1"
out_dir="$2"
comparator_dir="$ROOT_DIR/benchmarks/comparison/comparators/generator-a"
raw_dir="$out_dir/comparator-raw"
mkdir -p "$raw_dir"

template="${COGWORKS_BENCH_GENERATOR_A_CMD:-}"
default_script="$comparator_dir/scripts/benchmark.sh"

if [[ -z "$template" ]]; then
  if [[ -x "$default_script" ]]; then
    template="bash '$default_script' '{sources_path}' '{out_dir}'"
  else
    echo "Missing comparator runner for generator-a." >&2
    echo "Provide COGWORKS_BENCH_GENERATOR_A_CMD or executable $default_script" >&2
    exit 2
  fi
fi

command="${template//\{sources_path\}/$sources_path}"
command="${command//\{out_dir\}/$out_dir}"
command="${command//\{comparator_dir\}/$comparator_dir}"
command="${command//\{raw_dir\}/$raw_dir}"

bash -lc "$command"
