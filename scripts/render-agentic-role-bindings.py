#!/usr/bin/env python3
"""Render native agent bindings from canonical cogworks role profiles.

The canonical source of truth remains ``skills/cogworks/role-profiles.json``.
This script materializes those abstract role contracts into project-scoped
Claude and Copilot agent files so supported surfaces can execute the documented
specialist workflow without hand-maintained adapter drift.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path


ROOT_DIR = Path(__file__).resolve().parents[1]
DEFAULT_ROLE_PROFILES = ROOT_DIR / "skills" / "cogworks" / "role-profiles.json"
DEFAULT_PLUGIN_OUTPUT_DIR = ROOT_DIR / "agents"
DEFAULT_CLAUDE_OUTPUT_DIR = ROOT_DIR / ".claude" / "agents"
DEFAULT_COPILOT_OUTPUT_DIR = ROOT_DIR / ".github" / "agents"

SUMMARY_CONTRACT = """Stage: <stage-name>
Status: pass | fail
Artifacts:
- <artifact-path>
- <artifact-path>
Blocking failures:
- <failure or "none">
Warnings:
- <warning or "none">
Recommended next action: <single sentence>"""


def stage_contract_addendum(profile: dict) -> str:
    stage = str(profile["stage"])
    if stage == "source-intake":
        return """Stage-specific contract:
- `source-inventory.json` must enumerate every input source with stable IDs.
- `source-manifest.json` must record provenance and execution-surface context for the run.
- `source-trust-report.md` must explain the trust decision clearly.
- `source-trust-gate.json` must include `gate_passed` and a non-empty `sources` array.
- Each entry in `sources` should preserve source identity and trust classification."""
    if stage == "synthesis":
        return """Stage-specific contract:
- `synthesis.md` must include these headings: `TL;DR`, `Decision Rules`, `Anti-Patterns`, `Quick Reference`, `Sources`.
- `synthesis.md` must use `[Source N]` citations throughout.
- The `Sources` section must contain numbered entries.
- `cdr-registry.md` and `traceability-map.md` must both be non-empty."""
    if stage == "skill-packaging":
        return """Stage-specific contract:
- `SKILL.md` must have YAML frontmatter with `name` and `description`.
- `reference.md` must include `TL;DR`, `Decision Rules`, `Anti-Patterns`, `Quick Reference`, and `Sources`.
- `reference.md` must use `[Source N]` citations and a numbered `Sources` section.
- `metadata.json` must include `slug`, `version`, `snapshot_date`, `cogworks_version`, `topic`, and a non-empty `sources` array.
- The frontmatter description should be at least 10 words for discoverability."""
    if stage == "deterministic-validation":
        return """Stage-specific contract:
- Run `bash skills/cogworks-encode/scripts/validate-synthesis.sh <synthesis-artifact> --json` on the synthesis output.
- Run `bash skills/cogworks-encode/scripts/validate-synthesis.sh {skill_path}/reference.md --json`.
- Run `bash skills/cogworks-learn/scripts/validate-skill.sh {skill_path} --json`.
- Required output filenames are contractual. Do not substitute `validation-report.md`, `gate-decision.json`, or other alternate names for the required files.
- `deterministic-gate-report.json` must summarize the synthesis validator result and any critical findings.
- `final-gate-report.json` must summarize the overall generated-skill gate decision and warning count.
- `targeted-probe-report.md` must always exist; if no probe is required, write a short note stating that no targeted probe was needed.
- Treat critical validator failures as blocking and report warnings honestly."""
    return ""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Render project-scoped native agent bindings for cogworks."
    )
    parser.add_argument(
        "--role-profiles",
        default=str(DEFAULT_ROLE_PROFILES),
        help="Path to role-profiles.json",
    )
    parser.add_argument(
        "--surface",
        choices=("all", "plugin", "claude-cli", "copilot-cli"),
        default="all",
        help="Which surface bindings to render",
    )
    parser.add_argument(
        "--plugin-output-dir",
        default=str(DEFAULT_PLUGIN_OUTPUT_DIR),
        help="Directory where plugin agent files will be written",
    )
    parser.add_argument(
        "--claude-output-dir",
        default=str(DEFAULT_CLAUDE_OUTPUT_DIR),
        help="Directory where Claude agent files will be written",
    )
    parser.add_argument(
        "--copilot-output-dir",
        default=str(DEFAULT_COPILOT_OUTPUT_DIR),
        help="Directory where Copilot agent files will be written",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Exit non-zero if rendered output would differ from files on disk.",
    )
    return parser.parse_args()


def load_profiles(path: Path) -> list[dict]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    profiles = payload.get("profiles")
    if not isinstance(profiles, list) or not profiles:
        raise SystemExit(f"Invalid or empty profiles in {path}")
    return profiles


def claude_agent_filename(profile_id: str) -> str:
    return f"cogworks-{profile_id}.md"


def copilot_agent_filename(profile_id: str) -> str:
    return f"cogworks-{profile_id}.agent.md"


def plugin_agent_filename(profile_id: str) -> str:
    return f"cogworks-{profile_id}.agent.md"


def build_description(profile: dict) -> str:
    stage = str(profile["stage"])
    purpose = str(profile["purpose"]).rstrip(".")
    return f"{stage} specialist for cogworks. {purpose}."


def build_prompt(profile: dict) -> str:
    required_outputs = "\n".join(
        f"- {output_path}" for output_path in profile.get("required_outputs", [])
    )
    boundaries = "\n".join(f"- {entry}" for entry in profile.get("boundaries", []))
    context_discipline = "\n".join(
        f"- {entry}" for entry in profile.get("context_discipline", [])
    )
    quality_bar = "\n".join(f"- {entry}" for entry in profile.get("quality_bar", []))
    addendum = stage_contract_addendum(profile)

    return f"""You are the `cogworks` specialist role `{profile["role"]}` for the `{profile["stage"]}` stage.

Purpose:
{profile["purpose"]}

You own this stage and must write only this stage's artifacts plus the final compact stage summary.

Required outputs:
{required_outputs}

Tool scope:
- {profile["tool_scope"]}

Boundaries:
{boundaries}

Context discipline:
{context_discipline}

Quality bar:
{quality_bar}

{addendum}

Rules:
- Do not spawn subagents.
- Do not edit downstream stage directories unless the coordinator explicitly reassigns ownership.
- Fail the stage rather than guessing if required inputs are missing or contradictory in a blocking way.
- Required output filenames are contractual. Auxiliary files are allowed only in addition to the listed required outputs, never instead of them.
- Return only the compact stage summary contract after all stage artifacts are written.

Return this summary shape exactly:
{SUMMARY_CONTRACT}
"""


def build_capabilities(profile: dict) -> list[str]:
    stage = str(profile["stage"])
    purpose = str(profile["purpose"]).rstrip(".")
    capabilities = [f"Own the {stage} stage for cogworks", purpose]
    capabilities.extend(str(entry) for entry in profile.get("quality_bar", [])[:2])
    return capabilities


def render_plugin_agent_markdown(profile: dict) -> str:
    description = build_description(profile)
    prompt = build_prompt(profile)
    capabilities = build_capabilities(profile)
    capabilities_yaml = "[" + ", ".join(json.dumps(item) for item in capabilities) + "]"

    return (
        "---\n"
        f"name: {plugin_agent_filename(str(profile['profile_id'])).removesuffix('.agent.md')}\n"
        f"description: {json.dumps(description)}\n"
        f"capabilities: {capabilities_yaml}\n"
        "---\n\n"
        f"{prompt}"
    )


def render_claude_agent_markdown(profile: dict) -> str:
    claude_binding = profile.get("bindings", {}).get("claude-cli", {})
    tools = claude_binding.get("tools", [])
    description = build_description(profile)
    prompt = build_prompt(profile)
    tools_yaml = "[" + ", ".join(json.dumps(tool) for tool in tools) + "]"

    return (
        "---\n"
        f"name: {claude_agent_filename(str(profile['profile_id'])).removesuffix('.md')}\n"
        f"description: {json.dumps(description)}\n"
        f"tools: {tools_yaml}\n"
        "---\n\n"
        f"{prompt}"
    )


def render_copilot_agent_markdown(profile: dict) -> str:
    description = build_description(profile)
    prompt = build_prompt(profile)

    return (
        "---\n"
        f"name: {copilot_agent_filename(str(profile['profile_id'])).removesuffix('.agent.md')}\n"
        f"description: {json.dumps(description)}\n"
        "model: inherit\n"
        "---\n\n"
        f"{prompt}"
    )


def write_agents(
    profiles: list[dict],
    output_dir: Path,
    surface: str,
    check: bool,
) -> int:
    output_dir.mkdir(parents=True, exist_ok=True)
    mismatches: list[str] = []

    for profile in profiles:
        if surface == "plugin":
            target_path = output_dir / plugin_agent_filename(str(profile["profile_id"]))
            rendered = render_plugin_agent_markdown(profile)
        elif surface == "claude-cli":
            target_path = output_dir / claude_agent_filename(str(profile["profile_id"]))
            rendered = render_claude_agent_markdown(profile)
        else:
            target_path = output_dir / copilot_agent_filename(str(profile["profile_id"]))
            rendered = render_copilot_agent_markdown(profile)
        if check:
            if not target_path.exists() or target_path.read_text(encoding="utf-8") != rendered:
                mismatches.append(str(target_path))
            continue
        target_path.write_text(rendered, encoding="utf-8")

    if check and mismatches:
        joined = "\n".join(mismatches)
        raise SystemExit(f"Rendered {surface} agents are out of date:\n{joined}")

    return len(profiles)


def main() -> None:
    args = parse_args()
    profiles = load_profiles(Path(args.role_profiles))
    rendered = []

    if args.surface in ("all", "plugin"):
        plugin_count = write_agents(
            profiles,
            Path(args.plugin_output_dir),
            "plugin",
            args.check,
        )
        if not args.check:
            rendered.append(f"{plugin_count} plugin agents to {args.plugin_output_dir}")

    if args.surface in ("all", "claude-cli"):
        claude_count = write_agents(
            profiles,
            Path(args.claude_output_dir),
            "claude-cli",
            args.check,
        )
        if not args.check:
            rendered.append(f"{claude_count} Claude agents to {args.claude_output_dir}")

    if args.surface in ("all", "copilot-cli"):
        copilot_count = write_agents(
            profiles,
            Path(args.copilot_output_dir),
            "copilot-cli",
            args.check,
        )
        if not args.check:
            rendered.append(f"{copilot_count} Copilot agents to {args.copilot_output_dir}")

    if not args.check:
        print("Rendered " + " and ".join(rendered))


if __name__ == "__main__":
    main()
