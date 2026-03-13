#!/usr/bin/env python3
"""Render plugin-facing skill directories from canonical repo skill sources."""

from __future__ import annotations

import argparse
import shutil
from pathlib import Path


ROOT_DIR = Path(__file__).resolve().parents[1]
SOURCE_SKILLS_DIR = ROOT_DIR / "skills"
DEFAULT_OUTPUT_DIR = ROOT_DIR / "plugin" / "skills"

COGWORKS_ALLOWED_FILES = {
    "SKILL.md",
    "README.md",
    "reference.md",
    "metadata.json",
}
COGWORKS_ALLOWED_DIRS = {
    "agents",
}
EXCLUDED_DOC_PATTERNS = (
    "agentic-runtime.md",
    "claude-adapter.md",
    "copilot-adapter.md",
    "role-profiles.json",
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Render plugin-facing skill directories for cogworks."
    )
    parser.add_argument(
        "--source-dir",
        default=str(SOURCE_SKILLS_DIR),
        help="Path to canonical source skills directory",
    )
    parser.add_argument(
        "--output-dir",
        default=str(DEFAULT_OUTPUT_DIR),
        help="Path to rendered plugin skills directory",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Exit non-zero if rendered plugin skills would differ from files on disk.",
    )
    return parser.parse_args()


def copy_tree(src: Path, dst: Path) -> None:
    if dst.exists():
        shutil.rmtree(dst)
    shutil.copytree(src, dst)


def render_cogworks(src: Path, dst: Path) -> None:
    if dst.exists():
        shutil.rmtree(dst)
    dst.mkdir(parents=True, exist_ok=True)

    for entry in src.iterdir():
        if entry.is_file() and entry.name in COGWORKS_ALLOWED_FILES:
            shutil.copy2(entry, dst / entry.name)
        elif entry.is_dir() and entry.name in COGWORKS_ALLOWED_DIRS:
            copy_tree(entry, dst / entry.name)

    skill_path = dst / "SKILL.md"
    text = skill_path.read_text(encoding="utf-8")
    text = text.replace(
        "- build `dispatch-manifest.json` from `role-profiles.json` as the canonical\n"
        "  source for `binding_ref`, `model_policy`, `preferred_dispatch_mode`, and the\n"
        "  canonical `tool_scope` string\n"
        "- after the specialist dispatch modes are known, write\n"
        "  `dispatch-manifest.json` with\n"
        "  `python3 scripts/render-dispatch-manifest.py --surface <surface> --output {run_root}/dispatch-manifest.json ...`\n"
        "  and provide per-profile `--actual-mode profile_id=mode` overrides as needed\n",
        "- preserve truthful runtime artifacts when the supported surface uses the internal sub-agent build path\n",
    )
    text = text.replace(
        "When runtime adapters expose overlapping metadata, the canonical fields from\n"
        "[role-profiles.json](role-profiles.json) win over generated adapter files.\n\n",
        "",
    )
    replacement = """## Supporting Docs

- [README.md](README.md): user-facing product overview and support boundaries
- [reference.md](reference.md): stable product contract and operator checklist
- [metadata.json](metadata.json): repo-local release metadata for this skill
- [agents/openai.yaml](agents/openai.yaml): Codex-specific invocation policy

The frontmatter `metadata` block is a repo-local convention. Other platforms
may ignore it; canonical package metadata for tooling lives in
[metadata.json](metadata.json)."""
    start = text.index("## Supporting Docs")
    end = text.index("The frontmatter `metadata` block is a repo-local convention.")
    text = text[:start] + replacement + text[end + len("The frontmatter `metadata` block is a repo-local convention. Other platforms\nmay ignore it; canonical package metadata for tooling lives in\n[metadata.json](metadata.json)."):]
    skill_path.write_text(text, encoding="utf-8")

    readme_path = dst / "README.md"
    readme_text = readme_path.read_text(encoding="utf-8")
    maintainer_section = """## Maintainer-Only Internal Build Path

Claude Code and GitHub Copilot may use specialist sub-agents internally for:
- source intake
- synthesis
- skill packaging
- deterministic validation

Those are implementation details used to improve quality and context isolation.
They are not a user-facing mode switch.

The recommended install path is plugin-first from the main `cogworks` repo so
the three skills and matching native agent files arrive together. The bootstrap
installer remains a maintainer fallback, and `npx skills add` remains a manual
skill-only path rather than the full product install.

If you are using Codex, treat generated-skill portability and benchmark support
as separate from this internal build path.
"""
    start = readme_text.index("## Maintainer-Only Internal Build Path")
    end = readme_text.index("## Prerequisites")
    readme_text = readme_text[:start] + maintainer_section + "\n" + readme_text[end:]
    readme_path.write_text(readme_text, encoding="utf-8")


def render_plugin_skills(source_dir: Path, output_dir: Path) -> None:
    if output_dir.exists():
        shutil.rmtree(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    for skill_dir in sorted(p for p in source_dir.iterdir() if p.is_dir()):
        target_dir = output_dir / skill_dir.name
        if skill_dir.name == "cogworks":
            render_cogworks(skill_dir, target_dir)
        else:
            copy_tree(skill_dir, target_dir)


def compare_trees(left: Path, right: Path) -> list[str]:
    mismatches: list[str] = []
    left_files = sorted(p.relative_to(left) for p in left.rglob("*") if p.is_file())
    right_files = sorted(p.relative_to(right) for p in right.rglob("*") if p.is_file()) if right.exists() else []
    if left_files != right_files:
        return ["file set differs"]
    for rel in left_files:
        if (left / rel).read_text(encoding="utf-8") != (right / rel).read_text(encoding="utf-8"):
            mismatches.append(str(rel))
    return mismatches


def main() -> None:
    args = parse_args()
    source_dir = Path(args.source_dir)
    output_dir = Path(args.output_dir)

    if args.check:
        temp_dir = output_dir.parent / f".{output_dir.name}.tmp-check"
        if temp_dir.exists():
            shutil.rmtree(temp_dir)
        render_plugin_skills(source_dir, temp_dir)
        mismatches = compare_trees(temp_dir, output_dir)
        shutil.rmtree(temp_dir)
        if mismatches:
            raise SystemExit("Rendered plugin skills are out of date:\n" + "\n".join(mismatches))
        return

    render_plugin_skills(source_dir, output_dir)
    print(f"Rendered plugin skills to {output_dir}")


if __name__ == "__main__":
    main()
