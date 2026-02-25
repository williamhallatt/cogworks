#!/bin/bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <claude|codex> <sources_path> <out_dir>" >&2
  exit 2
fi

pipeline="$1"
sources_path="$2"
out_dir="$3"

if [[ "$pipeline" != "claude" && "$pipeline" != "codex" ]]; then
  echo "Pipeline must be 'claude' or 'codex', got: $pipeline" >&2
  exit 2
fi

mkdir -p "$out_dir"

if [[ "$pipeline" == "claude" ]]; then
  real_cmd="${COGWORKS_RECURSIVE_BENCH_CLAUDE_REAL_CMD:-}"
  smoke_msg="[recursive-bench] claude: using smoke metrics. Set COGWORKS_RECURSIVE_BENCH_CLAUDE_REAL_CMD for decision-grade runs."
  quality_score="0.90"
  activation_f1="0.89"
  fpr="0.03"
  ncr="0.33"
  runtime="12.0"
  total_tokens="8200"
  context_tokens="3000"
else
  real_cmd="${COGWORKS_RECURSIVE_BENCH_CODEX_REAL_CMD:-}"
  smoke_msg="[recursive-bench] codex: using smoke metrics. Set COGWORKS_RECURSIVE_BENCH_CODEX_REAL_CMD for decision-grade runs."
  quality_score="0.88"
  activation_f1="0.88"
  fpr="0.04"
  ncr="0.31"
  runtime="10.6"
  total_tokens="7400"
  context_tokens="2800"
fi

if [[ -n "$real_cmd" ]]; then
  cmd="${real_cmd//\{sources_path\}/$sources_path}"
  cmd="${cmd//\{out_dir\}/$out_dir}"
  bash -lc "$cmd"
  exit 0
fi

cat > "$out_dir/metrics.json" <<EOF
{
  "signal_mode": "offline-smoke",
  "layer1_pass": true,
  "quality_score": $quality_score,
  "activation_f1": $activation_f1,
  "false_positive_rate": $fpr,
  "negative_control_ratio": $ncr,
  "perturbation_success": true,
  "runtime_sec": $runtime,
  "usage": {
    "total_tokens": $total_tokens,
    "context_tokens": $context_tokens
  },
  "failed": false
}
EOF

echo "$smoke_msg" >&2
