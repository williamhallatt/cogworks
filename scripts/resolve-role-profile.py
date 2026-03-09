#!/usr/bin/env python3
"""Resolve canonical dispatch-manifest fields for a cogworks role profile."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


ROOT_DIR = Path(__file__).resolve().parents[1]
DEFAULT_ROLE_PROFILES = ROOT_DIR / "skills" / "cogworks" / "role-profiles.json"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Resolve canonical dispatch-manifest fields for one role profile."
    )
    parser.add_argument(
        "--surface",
        required=True,
        choices=("claude-cli", "copilot-cli"),
        help="Execution surface binding to resolve",
    )
    parser.add_argument(
        "--profile-id",
        required=True,
        help="Canonical profile_id from role-profiles.json",
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
    profiles = payload.get("profiles", [])
    for profile in profiles:
        if str(profile.get("profile_id")) != args.profile_id:
            continue
        binding = profile.get("bindings", {}).get(args.surface)
        if not isinstance(binding, dict):
            raise SystemExit(f"No binding for {args.surface} on profile {args.profile_id}")
        result = {
            "stage": profile["stage"],
            "role": profile["role"],
            "profile_id": profile["profile_id"],
            "binding_type": binding["binding_type"],
            "binding_ref": binding["binding_ref"],
            "model_policy": binding["model_policy"],
            "preferred_dispatch_mode": binding["preferred_dispatch_mode"],
            "tool_scope": profile["tool_scope"],
        }
        print(json.dumps(result, indent=2))
        return 0
    raise SystemExit(f"Unknown profile_id: {args.profile_id}")


if __name__ == "__main__":
    raise SystemExit(main())
