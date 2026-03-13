#!/usr/bin/env python3
"""Render live release-version surfaces from the canonical VERSION file."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
from pathlib import Path


ROOT_DIR = Path(__file__).resolve().parents[1]
SKILL_DIRS = ("cogworks", "cogworks-encode", "cogworks-learn")
FRONTMATTER_VERSION_RE = re.compile(
    r"(^metadata:\n(?:.*\n)*?  version:\s*)(?:v)?[0-9]+\.[0-9]+\.[0-9]+",
    re.MULTILINE,
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Render versioned release files from the canonical VERSION file."
    )
    parser.add_argument(
        "--root-dir",
        default=str(ROOT_DIR),
        help="Repository root.",
    )
    parser.add_argument(
        "--version",
        help="Explicit semantic version to render instead of reading VERSION.",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Exit non-zero if committed files differ from rendered version surfaces.",
    )
    return parser.parse_args()


def resolve_version(root_dir: Path, explicit: str | None) -> str:
    cmd = ["python3", str(root_dir / "scripts" / "resolve-release-version.py")]
    if explicit:
        cmd.extend(["--version", explicit])
    completed = subprocess.run(
        cmd,
        cwd=root_dir,
        check=True,
        capture_output=True,
        text=True,
    )
    return completed.stdout.strip()


def render_json(path: Path, version: str) -> str:
    data = json.loads(path.read_text(encoding="utf-8"))
    if path == ROOT_DIR / "plugin.json":
        data["version"] = version
    elif path == ROOT_DIR / ".claude-plugin" / "marketplace.json":
        data["plugins"][0]["version"] = version
    elif path == ROOT_DIR / ".github" / "plugin" / "marketplace.json":
        data["metadata"]["version"] = version
        data["plugins"][0]["version"] = version
    elif path.name == "metadata.json":
        data["version"] = version
        data["cogworks_version"] = version
    else:
        raise SystemExit(f"Unsupported JSON render target: {path}")
    return json.dumps(data, indent=2) + "\n"


def render_skill(path: Path, version: str) -> str:
    text = path.read_text(encoding="utf-8")
    if not FRONTMATTER_VERSION_RE.search(text):
        raise SystemExit(f"Failed to update metadata.version in {path}")
    return FRONTMATTER_VERSION_RE.sub(rf"\g<1>{version}", text, count=1)


def target_paths(root_dir: Path) -> list[Path]:
    paths = [
        root_dir / "plugin.json",
        root_dir / ".claude-plugin" / "marketplace.json",
        root_dir / ".github" / "plugin" / "marketplace.json",
    ]
    for skill in SKILL_DIRS:
        paths.append(root_dir / "skills" / skill / "metadata.json")
        paths.append(root_dir / "skills" / skill / "SKILL.md")
    return paths


def main() -> None:
    args = parse_args()
    root_dir = Path(args.root_dir)
    version = resolve_version(root_dir, args.version)
    mismatches: list[str] = []

    for path in target_paths(root_dir):
        rendered = render_json(path, version) if path.suffix == ".json" else render_skill(path, version)
        if args.check:
            current = path.read_text(encoding="utf-8")
            if current != rendered:
                mismatches.append(str(path.relative_to(root_dir)))
            continue
        path.write_text(rendered, encoding="utf-8")

    if mismatches:
        raise SystemExit(
            "Rendered release version surfaces are out of date:\n" + "\n".join(mismatches)
        )


if __name__ == "__main__":
    main()
