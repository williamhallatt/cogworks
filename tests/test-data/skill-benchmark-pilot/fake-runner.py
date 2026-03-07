#!/usr/bin/env python3

import json
import os
from pathlib import Path


def write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2), encoding="utf-8")


def main() -> int:
    benchmark_id = os.environ["COGWORKS_BENCHMARK_ID"]
    case_id = os.environ["COGWORKS_BENCHMARK_CASE_ID"]
    case_file = Path(os.environ["COGWORKS_BENCHMARK_CASE_FILE"])
    candidate_id = os.environ["COGWORKS_BENCHMARK_CANDIDATE_ID"]
    trial_id = os.environ["COGWORKS_BENCHMARK_TRIAL_ID"]
    work_dir = Path(os.environ["COGWORKS_BENCHMARK_WORK_DIR"])
    observation_path = Path(os.environ["COGWORKS_BENCHMARK_OBSERVATION_PATH"])
    judge_output_path = Path(os.environ["COGWORKS_BENCHMARK_JUDGE_OUTPUT_PATH"])
    model = os.environ["COGWORKS_BENCHMARK_MODEL"]
    agent_surface = os.environ["COGWORKS_BENCHMARK_AGENT_SURFACE"]

    case = json.loads(case_file.read_text(encoding="utf-8"))
    artifacts_dir = work_dir / "artifacts"
    artifacts_dir.mkdir(parents=True, exist_ok=True)

    invoked = case["expected_activation"] != "must_not_activate"
    commands = [{"command": "generate-skill --case " + case_id, "exit_code": 0}]
    tool_calls = [{"tool_name": "exec_command", "success": True, "duration_ms": 5}]
    files_written = []
    safety_violations = []
    judge_score = 0.75

    if case_id == "pilot-invoked-file":
        result_path = artifacts_dir / "result.txt"
        content = "EXPECTED MARKER\n"
        if candidate_id == "skill-b":
            content = "MISSING MARKER\n"
            judge_score = 0.30
        else:
            judge_score = 0.92
        result_path.write_text(content, encoding="utf-8")
        files_written.append({"path": str(result_path), "bytes_written": len(content.encode("utf-8"))})
    elif case_id == "pilot-hard-negative":
        invoked = False
        commands = [{"command": "inspect-task --case " + case_id, "exit_code": 0}]
        judge_score = 0.80
    elif case_id == "pilot-boundary-judge":
        note_path = artifacts_dir / "boundary.txt"
        content = "Boundary handled.\n"
        note_path.write_text(content, encoding="utf-8")
        files_written.append({"path": str(note_path), "bytes_written": len(content.encode("utf-8"))})
        if candidate_id == "skill-b":
            judge_score = 0.35
        else:
            judge_score = 0.85

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
        "safety_violations": safety_violations,
        "timing": {"wall_clock_ms": 1250 if candidate_id == "skill-a" else 1180, "step_count": 2},
        "cost": {"input_tokens": 100, "output_tokens": 80, "estimated_usd": 0.02 if candidate_id == "skill-a" else 0.018},
        "artifact_root": str(artifacts_dir),
        "output_ref": str(next(iter([entry["path"] for entry in files_written]), "")) or None,
        "notes": "Synthetic pilot runner.",
    }
    judge_output = {
        "score": judge_score,
        "verdict": "pass" if judge_score >= 0.5 else "fail",
        "confidence": 0.9,
        "dimension_scores": {"coverage": judge_score},
        "issues": [] if judge_score >= 0.5 else ["marker missing"],
        "reasoning_summary": "Synthetic judge output for harness smoke test.",
    }
    write_json(observation_path, observation)
    write_json(judge_output_path, judge_output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
