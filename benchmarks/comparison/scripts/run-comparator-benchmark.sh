#!/bin/bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <generator-a|generator-b> <sources_path> <out_dir>" >&2
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
generator="$1"
sources_path="$2"
out_dir="$3"
raw_dir="$out_dir/comparator-raw"
mkdir -p "$raw_dir"

if [[ "$generator" != "generator-a" && "$generator" != "generator-b" ]]; then
  echo "Generator must be 'generator-a' or 'generator-b', got: $generator" >&2
  exit 2
fi

if [[ "${COGWORKS_COMPARATOR_OFFLINE:-0}" == "1" ]]; then
  if [[ "$generator" == "generator-a" ]]; then
    cat > "$out_dir/metrics.json" <<'EOF'
{
  "signal_mode": "offline-smoke",
  "layer1_pass": true,
  "quality_score": 0.85,
  "activation_f1": 0.84,
  "false_positive_rate": 0.05,
  "negative_control_ratio": 0.30,
  "perturbation_success": true,
  "runtime_sec": 11.2,
  "usage": {
    "total_tokens": 7700,
    "context_tokens": 3000
  },
  "failed": false
}
EOF
  else
    cat > "$out_dir/metrics.json" <<'EOF'
{
  "signal_mode": "offline-smoke",
  "layer1_pass": true,
  "quality_score": 0.83,
  "activation_f1": 0.82,
  "false_positive_rate": 0.06,
  "negative_control_ratio": 0.28,
  "perturbation_success": true,
  "runtime_sec": 10.8,
  "usage": {
    "total_tokens": 7400,
    "context_tokens": 2800
  },
  "failed": false
}
EOF
  fi
  exit 0
fi

runner="$ROOT_DIR/benchmarks/comparison/scripts/run-$generator.sh"
if [[ ! -x "$runner" ]]; then
  echo "Runner is missing or not executable: $runner" >&2
  exit 2
fi

started="$(date +%s.%N)"
set +e
bash "$runner" "$sources_path" "$out_dir" >"$raw_dir/stdout.log" 2>"$raw_dir/stderr.log"
runner_exit=$?
set -e
ended="$(date +%s.%N)"

runtime_sec="$(python3 - "$started" "$ended" <<'PY'
import sys
start=float(sys.argv[1])
end=float(sys.argv[2])
print(f"{max(0.0, end-start):.4f}")
PY
)"

python3 - "$out_dir" "$generator" "$runtime_sec" "$runner_exit" <<'PY'
import json
import os
import sys
from pathlib import Path

out_dir = Path(sys.argv[1])
generator = sys.argv[2]
runtime_sec = float(sys.argv[3])
runner_exit = int(sys.argv[4])

def load_json(path: Path):
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}


existing_metrics = load_json(out_dir / "metrics.json")
raw_metrics = load_json(out_dir / "comparator-raw" / "metrics.json")
run_meta = load_json(out_dir / "run-metadata.json")
quality_meta = load_json(out_dir / "quality.json")
behavior_meta = load_json(out_dir / "behavioral-summary.json")

if not isinstance(existing_metrics, dict):
    existing_metrics = {}
if not isinstance(raw_metrics, dict):
    raw_metrics = {}
if not isinstance(run_meta, dict):
    run_meta = {}
if not isinstance(quality_meta, dict):
    quality_meta = {}
if not isinstance(behavior_meta, dict):
    behavior_meta = {}

def get_num(*values, default=0.0):
    for value in values:
        if value is None:
            continue
        try:
            return float(value)
        except Exception:
            continue
    return float(default)

quality_score = get_num(
    existing_metrics.get("quality_score"),
    raw_metrics.get("quality_score"),
    run_meta.get("quality_score"),
    quality_meta.get("weighted_score"),
    default=0.0,
)

activation_f1 = get_num(
    existing_metrics.get("activation_f1"),
    behavior_meta.get("activation_f1"),
    run_meta.get("activation_f1"),
    default=0.0,
)

false_positive_rate = get_num(
    existing_metrics.get("false_positive_rate"),
    behavior_meta.get("false_positive_rate"),
    run_meta.get("false_positive_rate"),
    default=1.0,
)

negative_control_ratio = get_num(
    existing_metrics.get("negative_control_ratio"),
    behavior_meta.get("negative_control_ratio"),
    run_meta.get("negative_control_ratio"),
    default=0.0,
)

usage = {}
for container in (existing_metrics, raw_metrics, run_meta):
    if isinstance(container.get("usage"), dict):
        usage = container["usage"]
        break

total_tokens = get_num(
    usage.get("total_tokens"),
    existing_metrics.get("total_tokens"),
    run_meta.get("total_tokens"),
    default=0.0,
)
context_tokens = get_num(
    usage.get("context_tokens"),
    existing_metrics.get("context_tokens"),
    run_meta.get("context_tokens"),
    default=0.0,
)

runtime = get_num(
    existing_metrics.get("runtime_sec"),
    run_meta.get("runtime_sec"),
    default=runtime_sec,
)

telemetry_present = any(
    [
        quality_score > 0.0,
        activation_f1 > 0.0,
        total_tokens > 0.0,
        context_tokens > 0.0,
        runtime > 0.0,
    ]
)

failed = bool(existing_metrics.get("failed", False)) or runner_exit != 0
if not telemetry_present:
    failed = True

metrics = {
    "pipeline": generator,
    "layer1_pass": bool(existing_metrics.get("layer1_pass", runner_exit == 0 and telemetry_present)),
    "quality_score": quality_score,
    "activation_f1": activation_f1,
    "false_positive_rate": false_positive_rate,
    "negative_control_ratio": negative_control_ratio,
    "perturbation_success": bool(existing_metrics.get("perturbation_success", True)),
    "runtime_sec": runtime,
    "usage": {
        "total_tokens": total_tokens,
        "context_tokens": context_tokens,
    },
    "failed": failed,
}

notes = []
if not telemetry_present:
    notes.append("Adapter could not derive usable telemetry. Marked as failed.")
if runner_exit != 0:
    notes.append(f"Comparator command exited non-zero: {runner_exit}")
if notes:
    metrics["adapter_notes"] = notes

def parse_budget(env_key):
    value = os.environ.get(env_key, "").strip()
    if not value:
        return None
    try:
        return float(value)
    except Exception:
        return None

max_total = parse_budget("COGWORKS_BENCH_MAX_TOTAL_TOKENS")
max_context = parse_budget("COGWORKS_BENCH_MAX_CONTEXT_TOKENS")
max_runtime = parse_budget("COGWORKS_BENCH_MAX_RUNTIME_SEC")

budget_violations = []
if max_total is not None and metrics["usage"]["total_tokens"] > max_total:
    budget_violations.append(f"total_tokens>{max_total}")
if max_context is not None and metrics["usage"]["context_tokens"] > max_context:
    budget_violations.append(f"context_tokens>{max_context}")
if max_runtime is not None and metrics["runtime_sec"] > max_runtime:
    budget_violations.append(f"runtime_sec>{max_runtime}")

if budget_violations:
    metrics["failed"] = True
    metrics["layer1_pass"] = False
    metrics.setdefault("adapter_notes", []).append(
        "Budget violations: " + ", ".join(budget_violations)
    )

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

for key in required:
    if key not in metrics:
        raise SystemExit(f"missing required metrics key: {key}")

if not isinstance(metrics["usage"], dict):
    raise SystemExit("usage must be an object")
if "total_tokens" not in metrics["usage"] or "context_tokens" not in metrics["usage"]:
    raise SystemExit("usage must include total_tokens and context_tokens")

(out_dir / "metrics.json").write_text(json.dumps(metrics, indent=2), encoding="utf-8")
PY
