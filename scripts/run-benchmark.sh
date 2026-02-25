#!/bin/bash
set -euo pipefail

usage() {
  echo "Usage: $0 <claude|codex> <sources_path> <out_dir>" >&2
}

write_offline_metrics() {
  local pipeline="$1"
  local out_dir="$2"
  if [[ "$pipeline" == "claude" ]]; then
    cat > "$out_dir/metrics.json" <<'EOF'
{
  "layer1_pass": true,
  "quality_score": 0.91,
  "activation_f1": 0.90,
  "false_positive_rate": 0.03,
  "negative_control_ratio": 0.35,
  "perturbation_success": true,
  "runtime_sec": 12.4,
  "usage": {
    "total_tokens": 8400,
    "context_tokens": 3200
  },
  "failed": false
}
EOF
  else
    cat > "$out_dir/metrics.json" <<'EOF'
{
  "layer1_pass": true,
  "quality_score": 0.87,
  "activation_f1": 0.88,
  "false_positive_rate": 0.04,
  "negative_control_ratio": 0.33,
  "perturbation_success": true,
  "runtime_sec": 10.2,
  "usage": {
    "total_tokens": 7100,
    "context_tokens": 2800
  },
  "failed": false
}
EOF
  fi
}

validate_metrics() {
  local metrics_path="$1"
  if [[ ! -f "$metrics_path" ]]; then
    echo "Missing required metrics file: $metrics_path" >&2
    return 1
  fi

  python3 - "$metrics_path" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))

required = [
    "layer1_pass",
    "quality_score",
    "activation_f1",
    "false_positive_rate",
    "negative_control_ratio",
    "perturbation_success",
    "runtime_sec",
    "usage",
    "failed",
]

missing = [k for k in required if k not in data]
if missing:
    print(f"metrics.json missing keys: {', '.join(missing)}", file=sys.stderr)
    sys.exit(1)

usage = data.get("usage", {})
if not isinstance(usage, dict) or "total_tokens" not in usage or "context_tokens" not in usage:
    print("metrics.json usage must include total_tokens and context_tokens", file=sys.stderr)
    sys.exit(1)
PY
}

if [[ $# -ne 3 ]]; then
  usage
  exit 2
fi

pipeline="$1"
sources_path="$2"
out_dir="$3"

if [[ "$pipeline" != "claude" && "$pipeline" != "codex" ]]; then
  echo "Pipeline must be 'claude' or 'codex', got: $pipeline" >&2
  usage
  exit 2
fi

mkdir -p "$out_dir"

if [[ "${COGWORKS_BENCH_OFFLINE:-0}" == "1" ]]; then
  write_offline_metrics "$pipeline" "$out_dir"
  validate_metrics "$out_dir/metrics.json"
  exit 0
fi

if [[ "$pipeline" == "claude" ]]; then
  template="${COGWORKS_BENCH_CLAUDE_CMD:-}"
  env_var="COGWORKS_BENCH_CLAUDE_CMD"
else
  template="${COGWORKS_BENCH_CODEX_CMD:-}"
  env_var="COGWORKS_BENCH_CODEX_CMD"
fi

if [[ -z "$template" ]]; then
  echo "$env_var is required in real mode." >&2
  echo "Example: export $env_var=\"my-runner --sources '{sources_path}' --out '{out_dir}'\"" >&2
  exit 2
fi

command="${template//\{sources_path\}/$sources_path}"
command="${command//\{out_dir\}/$out_dir}"
bash -lc "$command"

validate_metrics "$out_dir/metrics.json"
