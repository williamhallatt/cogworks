#!/usr/bin/env python3
"""Run one live Copilot CLI benchmark attempt against fixed supplied context.

This adapter is intentionally simple:
- it injects a context file directly into the prompt
- it forbids outside knowledge and asks the model to mark unsupported policies
- it emits a normalized observation JSON for ``scripts/run-skill-benchmark.py``

The adapter is useful for repeatable skill-content comparisons where the
candidate difference is the supplied skill/reference content rather than native
auto-activation behavior.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import time
from pathlib import Path


def extract_json(text: str) -> dict | None:
    start = text.find("{")
    if start == -1:
        return None
    depth = 0
    for index in range(start, len(text)):
        char = text[index]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                snippet = text[start : index + 1]
                try:
                    return json.loads(snippet)
                except json.JSONDecodeError:
                    return None
    return None


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Live Copilot CLI adapter for fixed-context skill benchmarks."
    )
    parser.add_argument(
        "--context-file",
        required=True,
        help="Markdown context injected into the Copilot prompt for non-negative cases.",
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
    model = os.environ["COGWORKS_BENCHMARK_MODEL"]
    agent_surface = os.environ["COGWORKS_BENCHMARK_AGENT_SURFACE"]

    case = json.loads(case_file.read_text(encoding="utf-8"))
    artifacts_dir = work_dir / "artifacts"
    artifacts_dir.mkdir(parents=True, exist_ok=True)
    raw_output_path = artifacts_dir / "raw-output.txt"
    response_path = artifacts_dir / "response.json"

    expected_activation = str(case["expected_activation"])
    invoked = expected_activation != "must_not_activate"
    context_text = (
        Path(args.context_file).read_text(encoding="utf-8") if invoked else ""
    )

    prompt = f"""You are executing a fixed-condition skill benchmark case.
Use ONLY the supplied skill context. Do not use outside knowledge.
If the context does not explicitly support a requested policy or distinction,
return explicitly_supported=false and use null/false/unknown for unsupported
fields rather than guessing.

Return ONLY a JSON object with exactly these keys:
explicitly_supported
status_code
must_include_www_authenticate
auth_boundary
token_policy
operator_guidance
answer

Allowed values:
- explicitly_supported: true or false
- status_code: 401, 403, or null
- must_include_www_authenticate: true or false
- auth_boundary: "authentication", "authorization", "not_applicable", or "unknown"
- token_policy: "short-lived" or "unknown"
- operator_guidance: true or false
- answer: short string

Skill context:
{context_text if context_text else "[skill not invoked for this unrelated task]"}

Task:
{case["task_prompt"]}
"""

    command = [
        "copilot",
        "-p",
        prompt,
        "--allow-all-tools",
        "--no-ask-user",
        "--output-format",
        "text",
    ]
    started_at = time.time()
    result = subprocess.run(command, text=True, capture_output=True, check=False)
    wall_clock_ms = (time.time() - started_at) * 1000.0

    combined_output = (result.stdout or "") + (result.stderr or "")
    raw_output_path.write_text(combined_output, encoding="utf-8")
    parsed = extract_json(combined_output)
    if parsed is None:
        return 2
    response_path.write_text(json.dumps(parsed, indent=2), encoding="utf-8")

    observation = {
        "schema_version": "1.0",
        "benchmark_id": benchmark_id,
        "case_id": case_id,
        "candidate_id": candidate_id,
        "trial_id": trial_id,
        "model": model,
        "agent_surface": agent_surface,
        "invoked": invoked,
        "completed": result.returncode == 0,
        "commands": [{"command": "copilot -p <benchmark prompt>", "exit_code": result.returncode}],
        "tool_calls": [{"tool_name": "copilot-cli", "success": result.returncode == 0}],
        "files_written": [
            {"path": str(raw_output_path), "bytes_written": raw_output_path.stat().st_size},
            {"path": str(response_path), "bytes_written": response_path.stat().st_size},
        ],
        "timing": {"wall_clock_ms": wall_clock_ms},
        "cost": {},
        "artifact_root": str(artifacts_dir),
        "output_ref": str(response_path),
        "model_output": parsed,
        "integrity": {"trace_mode": "live-cli"},
        "notes": "Live Copilot CLI benchmark run with fixed supplied context.",
    }
    observation_path.write_text(json.dumps(observation, indent=2), encoding="utf-8")
    return 0 if result.returncode == 0 else result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
