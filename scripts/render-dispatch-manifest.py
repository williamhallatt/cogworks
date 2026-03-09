#!/usr/bin/env python3
"""Render a canonical cogworks dispatch-manifest.json for one surface."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


ROOT_DIR = Path(__file__).resolve().parents[1]
DEFAULT_ROLE_PROFILES = ROOT_DIR / "skills" / "cogworks" / "role-profiles.json"
AGENT_DEFINITION_SOURCE = "skills/cogworks/role-profiles.json"


def parse_kv(items: list[str], label: str) -> dict[str, str]:
    result: dict[str, str] = {}
    for item in items:
        if "=" not in item:
            raise SystemExit(f"Invalid {label}: {item!r}; expected profile_id=value")
        key, value = item.split("=", 1)
        if not key or not value:
            raise SystemExit(f"Invalid {label}: {item!r}; expected profile_id=value")
        result[key] = value
    return result


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Render canonical dispatch-manifest.json from role profiles."
    )
    parser.add_argument(
        "--surface",
        required=True,
        choices=("claude-cli", "copilot-cli"),
        help="Execution surface binding to resolve",
    )
    parser.add_argument(
        "--output",
        required=True,
        help="Path to dispatch-manifest.json output file",
    )
    parser.add_argument(
        "--actual-mode",
        action="append",
        default=[],
        help="Repeatable profile_id=mode override for actual_dispatch_mode",
    )
    parser.add_argument(
        "--status",
        action="append",
        default=[],
        help="Repeatable profile_id=status override",
    )
    parser.add_argument(
        "--role-profiles",
        default=str(DEFAULT_ROLE_PROFILES),
        help="Path to role-profiles.json",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    payload = json.loads(Path(args.role_profiles).read_text(encoding="utf-8"))
    profiles = payload.get("profiles")
    if not isinstance(profiles, list) or not profiles:
        raise SystemExit(f"Invalid or empty profiles in {args.role_profiles}")

    actual_modes = parse_kv(list(args.actual_mode), "actual-mode")
    statuses = parse_kv(list(args.status), "status")
    dispatches: list[dict[str, str]] = []

    for profile in profiles:
        profile_id = str(profile["profile_id"])
        binding = profile.get("bindings", {}).get(args.surface)
        if not isinstance(binding, dict):
            raise SystemExit(f"No binding for {args.surface} on profile {profile_id}")
        preferred_mode = str(binding["preferred_dispatch_mode"])
        dispatches.append(
            {
                "stage": str(profile["stage"]),
                "role": str(profile["role"]),
                "profile_id": profile_id,
                "binding_type": str(binding["binding_type"]),
                "binding_ref": str(binding["binding_ref"]),
                "model_policy": str(binding["model_policy"]),
                "preferred_dispatch_mode": preferred_mode,
                "actual_dispatch_mode": actual_modes.get(profile_id, preferred_mode),
                "tool_scope": str(profile["tool_scope"]),
                "status": statuses.get(profile_id, "completed"),
            }
        )

    output = {
        "profile_source": "canonical-role-specs",
        "execution_surface": args.surface,
        "agent_definition_source": AGENT_DEFINITION_SOURCE,
        "dispatches": dispatches,
    }

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(output, indent=2), encoding="utf-8")
    print(f"Wrote {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
