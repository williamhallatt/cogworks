#!/usr/bin/env python3
"""Render adapter-specific role bindings from canonical cogworks role profiles."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ROLE_PROFILES_PATH = ROOT / "skills" / "cogworks" / "role-profiles.json"


def model_name(policy: str) -> str:
    if policy == "pinned-haiku":
        return "haiku"
    if policy == "pinned-sonnet":
        return "sonnet"
    raise ValueError(f"Unsupported Claude model policy: {policy}")


def section(title: str, lines: list[str]) -> list[str]:
    output = ["", f"## {title}", ""]
    output.extend(f"- {line}" for line in lines)
    return output


def render_claude_agent(profile: dict) -> str:
    binding = profile["bindings"]["claude-cli"]
    body: list[str] = [
        "---",
        f"name: {binding['display_name']}",
        f'description: Use this agent for cogworks agentic `{profile["stage"]}` work. {profile["purpose"]}',
        f'tools: {", ".join(binding["tools"])}',
        f'model: {model_name(binding["model_policy"])}',
        f'color: {binding["color"]}',
        "---",
        "",
        f"<!-- Derived from skills/cogworks/role-profiles.json#{profile['profile_id']} -->",
        "",
        f"You are the `{profile['role']}` role for the cogworks agentic runtime.",
        "",
        "## Scope",
        "",
        f"You own only the `{profile['stage']}` stage.",
    ]
    body.extend(section("Required outputs", profile["required_outputs"]))
    body.append("")
    body.append("Tool scope: " + profile["tool_scope"])
    body.extend(section("Boundaries", profile["boundaries"]))
    body.extend(section("Context Discipline", profile["context_discipline"]))
    body.extend(section("Quality Bar", profile["quality_bar"]))
    return "\n".join(body).rstrip() + "\n"


def main() -> None:
    data = json.loads(ROLE_PROFILES_PATH.read_text(encoding="utf-8"))
    for profile in data["profiles"]:
        binding = profile["bindings"]["claude-cli"]
        output_path = ROOT / binding["binding_ref"]
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(render_claude_agent(profile), encoding="utf-8")


if __name__ == "__main__":
    main()
