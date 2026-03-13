#!/usr/bin/env python3
"""Resolve the canonical cogworks release version."""

from __future__ import annotations

import argparse
import re
import subprocess
from pathlib import Path


ROOT_DIR = Path(__file__).resolve().parents[1]
DEFAULT_VERSION_FILE = ROOT_DIR / "VERSION"
SEMVER_RE = re.compile(r"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Resolve the canonical cogworks release version from an explicit "
            "version or the latest git tag."
        )
    )
    parser.add_argument(
        "--version",
        help="Explicit version to normalize (accepts 1.2.3 or v1.2.3).",
    )
    parser.add_argument(
        "--version-file",
        default=str(DEFAULT_VERSION_FILE),
        help="Path to the canonical VERSION file.",
    )
    parser.add_argument(
        "--latest-tag",
        action="store_true",
        help="Resolve from the latest git tag instead of the VERSION file.",
    )
    parser.add_argument(
        "--format",
        choices=("bare", "tag"),
        default="bare",
        help="Output format: semantic version only or v-prefixed tag form.",
    )
    parser.add_argument(
        "--default-tag",
        help="Fallback v-prefixed tag to use when the repo has no version tags.",
    )
    parser.add_argument(
        "--root-dir",
        default=str(ROOT_DIR),
        help="Repository root used when resolving the latest git tag.",
    )
    return parser.parse_args()


def normalize_version(raw: str) -> str:
    version = raw.strip().removeprefix("v")
    if not SEMVER_RE.fullmatch(version):
        raise SystemExit(f"Invalid semantic version: {raw}")
    return version


def resolve_latest_version(root_dir: Path, default_tag: str | None) -> str:
    completed = subprocess.run(
        ["git", "tag", "--sort=-version:refname"],
        cwd=root_dir,
        check=True,
        capture_output=True,
        text=True,
    )
    tags = [line.strip() for line in completed.stdout.splitlines() if line.strip()]
    if tags:
        return normalize_version(tags[0])
    if default_tag is not None:
        return normalize_version(default_tag)
    raise SystemExit("No version tags found")


def resolve_version_file(path: Path) -> str:
    if not path.is_file():
        raise SystemExit(f"Version file not found: {path}")
    return normalize_version(path.read_text(encoding="utf-8").strip())


def main() -> None:
    args = parse_args()
    if args.version:
        version = normalize_version(args.version)
    elif args.latest_tag:
        version = resolve_latest_version(Path(args.root_dir), args.default_tag)
    else:
        version = resolve_version_file(Path(args.version_file))

    if args.format == "tag":
        print(f"v{version}")
        return
    print(version)


if __name__ == "__main__":
    main()
