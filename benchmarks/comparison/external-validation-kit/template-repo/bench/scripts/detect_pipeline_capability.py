#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description="Detect pipeline execution capability")
    parser.add_argument("--protocol", required=True)
    parser.add_argument("--pipeline", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()

    cfg = json.loads(Path(args.protocol).read_text(encoding="utf-8"))
    pl = cfg.get("pipelines", {}).get(args.pipeline, {})

    mode = pl.get("execution_mode", "protocol_prompt")
    if mode not in {"skill_installed", "protocol_prompt"}:
        mode = "protocol_prompt"

    skill_install = pl.get("skill_install", {}) if isinstance(pl.get("skill_install"), dict) else {}
    skill_invocation = pl.get("skill_invocation", {}) if isinstance(pl.get("skill_invocation"), dict) else {}

    payload = {
        "pipeline": args.pipeline,
        "execution_mode": mode,
        "skill_install": skill_install,
        "skill_invocation": skill_invocation,
        "capability_valid": True,
        "capability_errors": [],
    }

    if mode == "skill_installed":
        if not skill_install.get("source"):
            payload["capability_valid"] = False
            payload["capability_errors"].append("missing skill_install.source")
        if not skill_invocation.get("required_skill_slug"):
            payload["capability_valid"] = False
            payload["capability_errors"].append("missing skill_invocation.required_skill_slug")

    Path(args.out).write_text(json.dumps(payload, indent=2), encoding="utf-8")
    return 0 if payload["capability_valid"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
