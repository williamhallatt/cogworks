#!/usr/bin/env python3
"""Adapt Codex CLI runs to the skill benchmark observation contract.

The adapter reads benchmark context from ``COGWORKS_BENCHMARK_*`` environment
variables, runs ``codex exec --json`` or replays a saved JSONL event stream,
then writes a normalized observation JSON to
``COGWORKS_BENCHMARK_OBSERVATION_PATH``.

It can also copy a static judge output fixture to
``COGWORKS_BENCHMARK_JUDGE_OUTPUT_PATH`` for replay-based smoke tests.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
from pathlib import Path
from typing import Any


def load_env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise SystemExit(f"Missing required environment variable: {name}")
    return value


def load_case(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2), encoding="utf-8")


def parse_jsonl_events(path: Path) -> tuple[list[dict[str, Any]], list[str]]:
    events: list[dict[str, Any]] = []
    raw_errors: list[str] = []
    if not path.exists():
        return events, [f"raw trace missing: {path}"]
    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        try:
            obj = json.loads(stripped)
        except json.JSONDecodeError:
            if "ERROR" in stripped or "error" in stripped.lower():
                raw_errors.append(stripped)
            continue
        events.append(obj)
    return events, raw_errors


def parse_patch_paths(patch: str) -> list[str]:
    paths: list[str] = []
    for line in patch.splitlines():
        for prefix in ("*** Add File: ", "*** Update File: ", "*** Move to: "):
            if line.startswith(prefix):
                paths.append(line[len(prefix) :].strip())
                break
    return paths


def parse_function_args(payload: dict[str, Any]) -> dict[str, Any]:
    raw = payload.get("arguments")
    if isinstance(raw, str) and raw.strip():
        try:
            parsed = json.loads(raw)
            if isinstance(parsed, dict):
                return parsed
        except json.JSONDecodeError:
            return {"raw_arguments": raw}
    if isinstance(raw, dict):
        return raw
    return {}


def normalize_events_to_observation(
    *,
    benchmark_id: str,
    case_id: str,
    candidate_id: str,
    trial_id: str,
    model: str,
    agent_surface: str,
    work_dir: Path,
    events: list[dict[str, Any]],
    raw_errors: list[str],
    return_code: int,
) -> dict[str, Any]:
    commands: list[dict[str, Any]] = []
    tool_calls: list[dict[str, Any]] = []
    files_written: list[dict[str, Any]] = []
    tool_inventory: set[str] = set()
    invoked = False
    input_tokens = 0
    output_tokens = 0
    estimated_usd: float | None = None
    wall_clock_ms = 0.0
    last_message_path: str | None = None

    for event in events:
        event_type = str(event.get("type", ""))
        payload = event.get("payload")
        if event_type == "response_item" and isinstance(payload, dict):
            payload_type = str(payload.get("type", ""))
            name = str(payload.get("name", ""))
            if name:
                tool_inventory.add(name)
                tool_calls.append({"tool_name": name, "success": True, "duration_ms": None})
            if name == "Skill":
                invoked = True
            if payload_type == "function_call":
                args = parse_function_args(payload)
                command = None
                if name in {"exec_command", "Bash"}:
                    command = args.get("cmd") or args.get("command")
                if isinstance(command, str) and command.strip():
                    commands.append(
                        {
                            "command": command.strip(),
                            "cwd": args.get("workdir"),
                            "exit_code": int(args.get("exit_code", 0)) if str(args.get("exit_code", "")).strip() else 0,
                            "duration_ms": None,
                        }
                    )
            elif payload_type == "custom_tool_call":
                patch_input = str(payload.get("input", ""))
                if name == "apply_patch" and patch_input:
                    for patch_path in parse_patch_paths(patch_input):
                        files_written.append({"path": patch_path, "bytes_written": 0})

        if event_type in {"turn.completed", "turn_completed"}:
            usage = event.get("usage") or {}
            if isinstance(usage, dict):
                input_tokens = int(usage.get("input_tokens", input_tokens) or input_tokens)
                output_tokens = int(usage.get("output_tokens", output_tokens) or output_tokens)
            elapsed = event.get("elapsed_ms")
            if isinstance(elapsed, (int, float)):
                wall_clock_ms = float(elapsed)
            cost = event.get("estimated_usd")
            if isinstance(cost, (int, float)):
                estimated_usd = float(cost)

        if event_type == "result":
            maybe_path = event.get("output_file") or event.get("output_path")
            if isinstance(maybe_path, str) and maybe_path.strip():
                last_message_path = maybe_path

    process_violations = list(raw_errors)
    if return_code != 0:
        process_violations.append(f"codex exec failed with exit code {return_code}")

    return {
        "schema_version": "1.0",
        "benchmark_id": benchmark_id,
        "case_id": case_id,
        "candidate_id": candidate_id,
        "trial_id": trial_id,
        "model": model,
        "agent_surface": agent_surface,
        "tool_inventory": sorted(tool_inventory),
        "invoked": invoked,
        "completed": return_code == 0,
        "commands": commands,
        "tool_calls": tool_calls,
        "files_written": files_written,
        "process_violations": process_violations,
        "safety_violations": [],
        "timing": {"wall_clock_ms": wall_clock_ms, "step_count": len(tool_calls)},
        "cost": {
            "input_tokens": input_tokens,
            "output_tokens": output_tokens,
            "estimated_usd": estimated_usd,
        },
        "artifact_root": str(work_dir / "artifacts"),
        "output_ref": last_message_path,
        "notes": "Normalized from Codex CLI JSONL events.",
    }


def build_prompt(case: dict[str, Any], prompt_prefix: str, prompt_suffix: str) -> str:
    parts = []
    if prompt_prefix:
        parts.append(prompt_prefix.rstrip())
    parts.append(str(case["task_prompt"]).strip())
    if prompt_suffix:
        parts.append(prompt_suffix.lstrip())
    return "\n\n".join(part for part in parts if part)


def main() -> int:
    parser = argparse.ArgumentParser(description="Codex adapter for the skill benchmark harness.")
    parser.add_argument("--sandbox", default="workspace-write", help="Codex sandbox mode.")
    parser.add_argument("--cwd", default=None, help="Working directory passed to codex exec.")
    parser.add_argument("--skip-git-repo-check", action="store_true", help="Pass --skip-git-repo-check to codex exec.")
    parser.add_argument("--prompt-prefix", default="", help="Text prepended to the case task prompt.")
    parser.add_argument("--prompt-suffix", default="", help="Text appended to the case task prompt.")
    parser.add_argument("--replay-events", default=None, help="Replay an existing Codex JSONL event stream instead of running Codex.")
    parser.add_argument("--judge-output-file", default=None, help="Optional static judge JSON to copy to the benchmark judge output path.")
    args = parser.parse_args()

    benchmark_id = load_env("COGWORKS_BENCHMARK_ID")
    case_id = load_env("COGWORKS_BENCHMARK_CASE_ID")
    case_file = Path(load_env("COGWORKS_BENCHMARK_CASE_FILE"))
    candidate_id = load_env("COGWORKS_BENCHMARK_CANDIDATE_ID")
    trial_id = load_env("COGWORKS_BENCHMARK_TRIAL_ID")
    work_dir = Path(load_env("COGWORKS_BENCHMARK_WORK_DIR"))
    observation_path = Path(load_env("COGWORKS_BENCHMARK_OBSERVATION_PATH"))
    judge_output_path = Path(load_env("COGWORKS_BENCHMARK_JUDGE_OUTPUT_PATH"))
    model = load_env("COGWORKS_BENCHMARK_MODEL")
    agent_surface = load_env("COGWORKS_BENCHMARK_AGENT_SURFACE")

    case = load_case(case_file)
    raw_dir = work_dir / "raw"
    raw_dir.mkdir(parents=True, exist_ok=True)
    artifacts_dir = work_dir / "artifacts"
    artifacts_dir.mkdir(parents=True, exist_ok=True)
    raw_events_path = raw_dir / "codex-events.jsonl"
    last_message_path = artifacts_dir / "last-message.txt"

    if args.replay_events:
        replay_path = Path(args.replay_events)
        shutil.copyfile(replay_path, raw_events_path)
        return_code = 0
    else:
        prompt = build_prompt(case, args.prompt_prefix, args.prompt_suffix)
        cmd = [
            "codex",
            "exec",
            "--json",
            "--sandbox",
            args.sandbox,
            "--output-last-message",
            str(last_message_path),
        ]
        if args.skip_git_repo_check:
            cmd.append("--skip-git-repo-check")
        if args.cwd:
            cmd.extend(["--cd", args.cwd])
        cmd.append(prompt)
        result = subprocess.run(
            cmd,
            text=True,
            capture_output=True,
            check=False,
        )
        raw_events_path.write_text((result.stdout + result.stderr).strip() + "\n", encoding="utf-8")
        return_code = result.returncode

    events, raw_errors = parse_jsonl_events(raw_events_path)
    observation = normalize_events_to_observation(
        benchmark_id=benchmark_id,
        case_id=case_id,
        candidate_id=candidate_id,
        trial_id=trial_id,
        model=model,
        agent_surface=agent_surface,
        work_dir=work_dir,
        events=events,
        raw_errors=raw_errors,
        return_code=return_code,
    )
    write_json(observation_path, observation)

    if args.judge_output_file:
        shutil.copyfile(Path(args.judge_output_file), judge_output_path)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
