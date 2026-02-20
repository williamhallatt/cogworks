#!/bin/bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <sources_path> <out_dir>" >&2
  exit 2
fi

sources_path="$1"
out_dir="$2"
mkdir -p "$out_dir"

if [[ -n "${COGWORKS_RECURSIVE_BENCH_CODEX_REAL_CMD:-}" ]]; then
  cmd="${COGWORKS_RECURSIVE_BENCH_CODEX_REAL_CMD//\{sources_path\}/$sources_path}"
  cmd="${cmd//\{out_dir\}/$out_dir}"
  bash -lc "$cmd"
  exit 0
fi

cat > "$out_dir/metrics.json" <<'JSON'
{
  "signal_mode": "offline-smoke",
  "layer1_pass": true,
  "quality_score": 0.88,
  "activation_f1": 0.88,
  "false_positive_rate": 0.04,
  "negative_control_ratio": 0.31,
  "perturbation_success": true,
  "runtime_sec": 10.6,
  "usage": {
    "total_tokens": 7400,
    "context_tokens": 2800
  },
  "failed": false
}
JSON

echo "[recursive-bench-codex] Using smoke metrics. Set COGWORKS_RECURSIVE_BENCH_CODEX_REAL_CMD for decision-grade runs." >&2
