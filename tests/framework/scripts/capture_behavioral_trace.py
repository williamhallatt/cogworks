#!/usr/bin/env python3
import argparse
import json
from datetime import UTC, datetime
from pathlib import Path
from typing import Any, Dict, List


def _read_json(path: str) -> Dict[str, Any]:
    with open(path, "r", encoding="utf-8") as f:
        payload = json.load(f)
    if not isinstance(payload, dict):
        raise ValueError(f"raw trace must be a JSON object: {path}")
    return payload


def _write_json(path: str, payload: Dict[str, Any]) -> None:
    out = Path(path)
    out.parent.mkdir(parents=True, exist_ok=True)
    with open(out, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2)


def _to_list(value: Any) -> List[Any]:
    if value is None:
        return []
    if isinstance(value, list):
        return value
    return [value]


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Normalize behavioral trace output for cogworks-eval."
    )
    parser.add_argument("--pipeline", required=True, choices=["claude", "codex", "shared"])
    parser.add_argument("--skill-slug", required=True)
    parser.add_argument("--case-id", required=True)
    parser.add_argument("--raw-trace", required=True, help="Input JSON trace payload")
    parser.add_argument("--out", required=True, help="Output normalized trace path")
    parser.add_argument("--harness", required=True, help="Runtime harness, e.g. claude-code")
    parser.add_argument("--model", required=True, help="Model identifier used by harness")
    parser.add_argument("--trace-source", default="captured", choices=["captured", "simulated"])
    parser.add_argument("--captured-at", default=None, help="ISO-8601 UTC timestamp")
    parser.add_argument("--notes", default="")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    raw = _read_json(args.raw_trace)
    captured_at = args.captured_at or datetime.now(UTC).strftime("%Y-%m-%dT%H:%M:%SZ")

    payload = {
        "skill_slug": args.skill_slug,
        "case_id": args.case_id,
        "activated": bool(raw.get("activated", False)),
        "activation_source": str(raw.get("activation_source", "none")),
        "tools_used": _to_list(raw.get("tools_used")),
        "tool_events": _to_list(raw.get("tool_events")),
        "commands": _to_list(raw.get("commands")),
        "files_modified": _to_list(raw.get("files_modified")),
        "files_created": _to_list(raw.get("files_created")),
        "task_completed": bool(raw.get("task_completed", False)),
        "quality_score": raw.get("quality_score"),
        "baseline_run": bool(raw.get("baseline_run", False)),
        "pipeline": args.pipeline,
        "harness": args.harness,
        "model": args.model,
        "trace_source": args.trace_source,
        "captured_at": captured_at,
        "notes": args.notes or raw.get("notes", ""),
    }
    _write_json(args.out, payload)
    print(f"Wrote normalized trace: {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
