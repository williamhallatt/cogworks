#!/usr/bin/env python3

import argparse
import json
import os
from pathlib import Path


def write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2), encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Synthetic runner for benchmark integrity smoke tests.")
    parser.add_argument(
        "--profile",
        required=True,
        choices=["stable", "flaky", "false-positive", "clean-negative"],
        help="Synthetic behavior profile.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    benchmark_id = os.environ["COGWORKS_BENCHMARK_ID"]
    case_id = os.environ["COGWORKS_BENCHMARK_CASE_ID"]
    case_file = Path(os.environ["COGWORKS_BENCHMARK_CASE_FILE"])
    candidate_id = os.environ["COGWORKS_BENCHMARK_CANDIDATE_ID"]
    trial_id = os.environ["COGWORKS_BENCHMARK_TRIAL_ID"]
    work_dir = Path(os.environ["COGWORKS_BENCHMARK_WORK_DIR"])
    observation_path = Path(os.environ["COGWORKS_BENCHMARK_OBSERVATION_PATH"])
    judge_output_path = Path(os.environ["COGWORKS_BENCHMARK_JUDGE_OUTPUT_PATH"])
    model = os.environ["COGWORKS_BENCHMARK_MODEL"]
    judge_model = os.environ.get("COGWORKS_BENCHMARK_JUDGE_MODEL", "fixture-judge")
    agent_surface = os.environ["COGWORKS_BENCHMARK_AGENT_SURFACE"]

    case = json.loads(case_file.read_text(encoding="utf-8"))
    artifacts_dir = work_dir / "artifacts"
    artifacts_dir.mkdir(parents=True, exist_ok=True)

    candidate_root = work_dir.parent
    if args.profile == "flaky":
        marker = candidate_root / f"{case_id}-{trial_id}.marker"
        if not marker.exists():
            marker.write_text("failed-once\n", encoding="utf-8")
            return 1

    expected_activation = case["expected_activation"]
    invoked = expected_activation != "must_not_activate"
    judge_score = 0.82
    commands = [{"command": f"fixture-run --case {case_id}", "exit_code": 0}]
    tool_calls = [{"tool_name": "exec_command", "success": True, "duration_ms": 5}]
    files_written = []

    if case["category"] == "invoked-task":
        output_path = artifacts_dir / "result.txt"
        content = "EXPECTED MARKER\n"
        output_path.write_text(content, encoding="utf-8")
        files_written.append({"path": str(output_path), "bytes_written": len(content.encode('utf-8'))})
        if args.profile == "clean-negative":
            judge_score = 0.60
        else:
            judge_score = 0.95
    elif case["category"] == "hard-negative":
        invoked = args.profile == "false-positive"
        judge_score = 0.75
    else:
        boundary_path = artifacts_dir / "boundary.txt"
        boundary_path.write_text("boundary\n", encoding="utf-8")
        files_written.append({"path": str(boundary_path), "bytes_written": len("boundary\n".encode("utf-8"))})
        judge_score = 0.70 if args.profile == "clean-negative" else 0.90

    observation = {
        "schema_version": "1.0",
        "benchmark_id": benchmark_id,
        "case_id": case_id,
        "candidate_id": candidate_id,
        "trial_id": trial_id,
        "model": model,
        "agent_surface": agent_surface,
        "tool_inventory": ["exec_command"],
        "invoked": invoked,
        "completed": True,
        "commands": commands,
        "tool_calls": tool_calls,
        "files_written": files_written,
        "process_violations": [],
        "safety_violations": [],
        "timing": {"wall_clock_ms": 1000 if args.profile != "clean-negative" else 900, "step_count": 1},
        "cost": {"input_tokens": 80, "output_tokens": 60, "estimated_usd": 0.01},
        "artifact_root": str(artifacts_dir),
        "output_ref": str(files_written[0]["path"]) if files_written else None,
        "notes": f"Synthetic integrity runner ({args.profile}).",
    }
    judge_output = {
        "judge_model": judge_model,
        "score": judge_score,
        "verdict": "pass" if judge_score >= 0.5 else "fail",
        "confidence": 0.9,
        "dimension_scores": {"coverage": judge_score},
        "issues": [],
        "reasoning_summary": f"Synthetic judge output ({args.profile}).",
    }

    write_json(observation_path, observation)
    if any(check["kind"] == "judge_only" for check in case["observable_checks"]):
        write_json(judge_output_path, judge_output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
