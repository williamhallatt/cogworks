#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EVAL_CLI="$ROOT_DIR/tests/framework/scripts/cogworks-eval.py"
BENCH_SCRIPT="$ROOT_DIR/scripts/test-cogworks-pipeline.sh"

ROUND_MANIFEST=""
RUN_ID="rr-$(date +%Y%m%d-%H%M%S)"
MODE="fast"
TASK_MANIFEST="$ROOT_DIR/tests/datasets/pipeline-benchmark/manifest.jsonl"
SMOKE_ONLY=0
SKIP_HOOKS=0

usage() {
  cat <<USAGE
Usage: $0 --round-manifest <path> [options]

Options:
  --round-manifest <path>   Round manifest JSON (required)
  --run-id <id>             Run identifier (default: timestamped)
  --mode <fast|deep>        Evaluation depth (default: fast)
  --task-manifest <path>    Benchmark manifest for deep mode
  --smoke-only              In deep mode, use offline benchmark signal (non-decision-grade)
  --skip-hooks              Do not run generation/improvement hook commands from manifest
  -h, --help                Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --round-manifest)
      ROUND_MANIFEST="$2"
      shift 2
      ;;
    --run-id)
      RUN_ID="$2"
      shift 2
      ;;
    --mode)
      MODE="$2"
      shift 2
      ;;
    --task-manifest)
      TASK_MANIFEST="$2"
      shift 2
      ;;
    --smoke-only)
      SMOKE_ONLY=1
      shift
      ;;
    --skip-hooks)
      SKIP_HOOKS=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$ROUND_MANIFEST" ]]; then
  echo "--round-manifest is required." >&2
  exit 2
fi

if [[ "$MODE" != "fast" && "$MODE" != "deep" ]]; then
  echo "--mode must be fast or deep." >&2
  exit 2
fi

if [[ ! -f "$ROUND_MANIFEST" ]]; then
  echo "Round manifest not found: $ROUND_MANIFEST" >&2
  exit 2
fi

if [[ "$MODE" == "deep" && ! -f "$TASK_MANIFEST" ]]; then
  echo "Task manifest not found: $TASK_MANIFEST" >&2
  exit 2
fi

RESULTS_DIR="$ROOT_DIR/tests/results/meta-loop/$RUN_ID"
mkdir -p "$RESULTS_DIR"

MANIFEST_STATE="$RESULTS_DIR/manifest-state.json"

python3 - "$ROUND_MANIFEST" "$ROOT_DIR" "$MANIFEST_STATE" <<'PY'
import hashlib
import json
import sys
from pathlib import Path

manifest_path = Path(sys.argv[1])
root_dir = Path(sys.argv[2])
out_path = Path(sys.argv[3])
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))

for key in ["round_id", "test_bundle", "selection"]:
    if key not in manifest:
        raise SystemExit(f"round manifest missing required key: {key}")

bundle = manifest["test_bundle"]
paths = bundle.get("bundle_paths")
if not isinstance(paths, list) or not paths:
    raise SystemExit("test_bundle.bundle_paths must be a non-empty list")

files = []
for rel in paths:
    path = (root_dir / rel).resolve()
    if not path.exists():
        raise SystemExit(f"test bundle path does not exist: {rel}")
    if path.is_file():
        files.append(path)
    else:
        files.extend([p for p in path.rglob("*") if p.is_file()])

h = hashlib.sha256()
for p in sorted(files):
    rel = p.relative_to(root_dir).as_posix()
    h.update(rel.encode("utf-8"))
    h.update(b"\0")
    h.update(hashlib.sha256(p.read_bytes()).hexdigest().encode("utf-8"))
    h.update(b"\n")
computed = h.hexdigest()
expected = bundle.get("expected_sha256")
if expected and computed != expected:
    raise SystemExit(f"frozen test bundle hash mismatch: expected={expected} computed={computed}")

selection = manifest["selection"]
for req in ["weights", "max_total_tokens", "max_runtime_sec"]:
    if req not in selection:
        raise SystemExit(f"selection.{req} is required")
for req in ["quality", "robustness", "cost"]:
    if req not in selection["weights"]:
        raise SystemExit(f"selection.weights.{req} is required")

state = {
    "round_id": manifest["round_id"],
    "description": manifest.get("description", ""),
    "manifest_path": str(manifest_path),
    "test_bundle_paths": paths,
    "test_bundle_hash": computed,
    "test_bundle_expected_hash": expected,
    "test_bundle_match": (expected is None) or (expected == computed),
    "pipeline_paths": manifest.get("pipeline_paths", {
        "claude_skills_root": ".claude/skills",
        "codex_skills_root": ".agents/skills",
    }),
    "skill_slugs": manifest.get("skill_slugs", ["cogworks-encode", "cogworks-learn"]),
    "hooks": manifest.get("hooks", {}),
    "selection": selection,
}
out_path.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
PY

cp "$ROUND_MANIFEST" "$RESULTS_DIR/round-manifest.json"

run_hook_phase() {
  local phase="$1"
  local log_file="$RESULTS_DIR/hooks-${phase}.log"
  local cmds
  cmds="$(python3 - "$MANIFEST_STATE" "$phase" <<'PY'
import json
import sys
from pathlib import Path
state = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
phase = sys.argv[2]
for cmd in state.get("hooks", {}).get(phase, []):
    print(cmd)
PY
)"
  while IFS= read -r cmd; do
    [[ -z "$cmd" ]] && continue
    echo "[$phase] $cmd"
    bash -lc "$cmd" >> "$log_file" 2>&1
  done <<< "$cmds"
}

if [[ "$SKIP_HOOKS" -eq 0 ]]; then
  run_hook_phase "pre_round"
  run_hook_phase "generate"
  run_hook_phase "improve"
  run_hook_phase "regenerate"
fi

bash "$ROOT_DIR/tests/framework/graders/deterministic-checks.sh" \
  "$ROOT_DIR/tests/test-data/snapshot-cogworks-learn" \
  --json > "$RESULTS_DIR/invariants-clean.json"

bash "$ROOT_DIR/tests/framework/graders/deterministic-checks.sh" \
  "$ROOT_DIR/tests/test-data/no-citations-skill" \
  --json > "$RESULTS_DIR/invariants-negative.json" || true

python3 - "$RESULTS_DIR/invariants-clean.json" "$RESULTS_DIR/invariants-negative.json" <<'PY'
import json
import sys
from pathlib import Path

clean = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
neg = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

if clean.get("status") != "pass":
    raise SystemExit("Invariant failed: clean deterministic fixture did not pass.")
if neg.get("status") != "fail":
    raise SystemExit("Invariant failed: negative deterministic fixture did not fail.")
PY

mapfile -t STATE_VALUES < <(python3 - "$MANIFEST_STATE" <<'PY'
import json
import sys
from pathlib import Path
s = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
print(s["pipeline_paths"]["claude_skills_root"])
print(s["pipeline_paths"]["codex_skills_root"])
for slug in s["skill_slugs"]:
    print(slug)
PY
)

CLAUDE_ROOT="${STATE_VALUES[0]}"
CODEX_ROOT="${STATE_VALUES[1]}"
SKILL_SLUGS=("${STATE_VALUES[@]:2}")

BEHAVIORAL_ARGS=()
for slug in "${SKILL_SLUGS[@]}"; do
  [[ -z "$slug" ]] && continue
  BEHAVIORAL_ARGS+=(--skill "$slug")
done

python3 "$EVAL_CLI" behavioral run \
  --skills-root "$ROOT_DIR/$CLAUDE_ROOT" \
  --tests-root "$ROOT_DIR/tests/behavioral" \
  --results-root "$RESULTS_DIR/behavioral-claude" \
  --strict-provenance \
  "${BEHAVIORAL_ARGS[@]}"

python3 "$EVAL_CLI" behavioral run \
  --skills-root "$ROOT_DIR/$CODEX_ROOT" \
  --tests-root "$ROOT_DIR/tests/behavioral" \
  --results-root "$RESULTS_DIR/behavioral-codex" \
  --strict-provenance \
  "${BEHAVIORAL_ARGS[@]}"

BENCHMARK_SUMMARY=""
BENCHMARK_REPORT=""
SIGNAL_MODE="not-run"
RANKING_ELIGIBLE="false"
SELECTED_WINNER="none"
SELECTION_STATUS="not-run"

if [[ "$MODE" == "deep" ]]; then
  if [[ "$SMOKE_ONLY" -eq 1 ]]; then
    bash "$BENCH_SCRIPT" --mode offline --run-id "$RUN_ID" --manifest "$TASK_MANIFEST" --force
  else
    if [[ -z "${COGWORKS_BENCH_CLAUDE_CMD:-}" || -z "${COGWORKS_BENCH_CODEX_CMD:-}" ]]; then
      echo "Deep mode requires COGWORKS_BENCH_CLAUDE_CMD and COGWORKS_BENCH_CODEX_CMD unless --smoke-only is set." >&2
      exit 2
    fi
    bash "$BENCH_SCRIPT" --mode real --run-id "$RUN_ID" --manifest "$TASK_MANIFEST" --force
  fi

  BENCHMARK_SUMMARY="$ROOT_DIR/tests/results/pipeline-benchmark/$RUN_ID/benchmark-summary.json"
  BENCHMARK_REPORT="$ROOT_DIR/tests/results/pipeline-benchmark/$RUN_ID/benchmark-report.md"

  mapfile -t BENCH_STATE < <(python3 - "$MANIFEST_STATE" "$BENCHMARK_SUMMARY" <<'PY'
import json
import sys
from pathlib import Path

manifest_state = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
summary = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
sel = manifest_state["selection"]
max_tokens = float(sel["max_total_tokens"])
max_runtime = float(sel["max_runtime_sec"])

signal_mode = summary.get("signal_mode", "offline-smoke")
ranking_eligible = bool(summary.get("ranking_eligible", False))

winner = "none"
status = "FAIL"
best_utility = -1.0
for name, payload in summary.get("pipelines", {}).items():
    if payload.get("disqualified", False):
        continue
    cost = payload.get("cost", {})
    total_tokens = float(cost.get("total_tokens_median", 0.0))
    runtime_sec = float(cost.get("runtime_sec_median", 0.0))
    if total_tokens > max_tokens or runtime_sec > max_runtime:
        continue
    utility = float(payload.get("utility_score", 0.0))
    if utility > best_utility:
        best_utility = utility
        winner = name
        status = "PASS"

print(signal_mode)
print(str(ranking_eligible).lower())
print(winner)
print(status)
PY
)

  SIGNAL_MODE="${BENCH_STATE[0]}"
  RANKING_ELIGIBLE="${BENCH_STATE[1]}"
  SELECTED_WINNER="${BENCH_STATE[2]}"
  SELECTION_STATUS="${BENCH_STATE[3]}"

  if [[ "$SMOKE_ONLY" -eq 0 && "$RANKING_ELIGIBLE" != "true" ]]; then
    echo "Deep mode real run requires ranking_eligible=true in benchmark summary." >&2
    exit 1
  fi
fi

if [[ "$SKIP_HOOKS" -eq 0 ]]; then
  run_hook_phase "post_round"
fi

SUMMARY_JSON="$RESULTS_DIR/round-summary.json"
SUMMARY_MD="$RESULTS_DIR/round-report.md"

python3 - "$MANIFEST_STATE" "$SUMMARY_JSON" "$SUMMARY_MD" "$RUN_ID" "$MODE" "$SIGNAL_MODE" "$RANKING_ELIGIBLE" "$BENCHMARK_SUMMARY" "$BENCHMARK_REPORT" "$SELECTED_WINNER" "$SELECTION_STATUS" <<'PY'
import json
import sys
from datetime import UTC, datetime
from pathlib import Path

state = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
out_json = Path(sys.argv[2])
out_md = Path(sys.argv[3])
run_id = sys.argv[4]
mode = sys.argv[5]
signal_mode = sys.argv[6]
ranking_eligible = sys.argv[7] == "true"
benchmark_summary = sys.argv[8]
benchmark_report = sys.argv[9]
selected_winner = sys.argv[10]
selection_status = sys.argv[11]

recommendation = "continue-fast-iteration"
if mode == "deep":
    if ranking_eligible and selection_status == "PASS" and selected_winner != "none":
        recommendation = f"promote-{selected_winner}"
    elif ranking_eligible:
        recommendation = "no-promotion-within-caps"
    else:
        recommendation = "deep-run-smoke-only"

payload = {
    "timestamp": datetime.now(UTC).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "run_id": run_id,
    "round_id": state["round_id"],
    "description": state.get("description", ""),
    "manifest_path": state["manifest_path"],
    "test_bundle_hash": state["test_bundle_hash"],
    "test_bundle_expected_hash": state.get("test_bundle_expected_hash"),
    "test_bundle_match": state.get("test_bundle_match", True),
    "immutable_core": ["runtime_contract_correctness", "artifact_schema"],
    "selection_policy": {
        "type": "guardrails_plus_weighted_score",
        **state["selection"],
    },
    "mode": mode,
    "signal_mode": signal_mode,
    "ranking_eligible": ranking_eligible,
    "benchmark_summary": benchmark_summary if benchmark_summary else None,
    "benchmark_report": benchmark_report if benchmark_report else None,
    "selected_winner": selected_winner,
    "selection_status": selection_status,
    "recommendation": recommendation,
}
out_json.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

md = [
    "# Recursive Improvement Round Report",
    "",
    f"- Run ID: `{run_id}`",
    f"- Round ID: `{state['round_id']}`",
    f"- Mode: `{mode}`",
    f"- Frozen Test Bundle Hash: `{state['test_bundle_hash']}`",
    f"- Test Bundle Match: `{state.get('test_bundle_match', True)}`",
    f"- Signal Mode: `{signal_mode}`",
    f"- Ranking Eligible: `{ranking_eligible}`",
    f"- Selected Winner: `{selected_winner}`",
    f"- Recommendation: `{recommendation}`",
]
if benchmark_summary:
    md.extend([
        "",
        "## Benchmark Artifacts",
        f"- Summary: `{benchmark_summary}`",
        f"- Report: `{benchmark_report}`",
    ])
out_md.write_text("\n".join(md) + "\n", encoding="utf-8")
PY

echo "Recursive improvement round complete."
echo "Summary: $SUMMARY_JSON"
echo "Report:  $SUMMARY_MD"
