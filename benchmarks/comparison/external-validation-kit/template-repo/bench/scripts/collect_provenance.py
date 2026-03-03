#!/usr/bin/env python3
import argparse
import hashlib
import json
import os
import platform
import subprocess
from datetime import datetime, UTC
from pathlib import Path


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def hash_tree(root: Path) -> dict[str, str]:
    out: dict[str, str] = {}
    if not root.exists():
        return out
    for p in sorted(root.rglob("*")):
        if p.is_file():
            out[str(p)] = sha256_file(p)
    return out


def git_rev(path: Path) -> str:
    try:
        return subprocess.check_output(["git", "-C", str(path), "rev-parse", "HEAD"], text=True).strip()
    except Exception:
        return "unknown"


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--run-root", required=True)
    p.add_argument("--sources-path", required=True)
    p.add_argument("--skill-root", required=True)
    p.add_argument("--sandbox", required=True)
    p.add_argument("--out", default=None)
    args = p.parse_args()

    run_root = Path(args.run_root)
    repo_root = Path(__file__).resolve().parents[2]
    out = Path(args.out) if args.out else run_root / "provenance.json"

    payload = {
        "timestamp_utc": datetime.now(UTC).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "benchmark_commit": git_rev(repo_root),
        "vendor_commits": {
            "cogworks": git_rev(repo_root / "vendors" / "cogworks"),
            "generator-a": git_rev(repo_root / "vendors" / "generator-a"),
            "generator-b": git_rev(repo_root / "vendors" / "generator-b"),
        },
        "container_digest": os.getenv("BENCH_CONTAINER_DIGEST", "unset"),
        "model": {
            "family": os.getenv("BENCH_MODEL_FAMILY", "unknown"),
            "id": os.getenv("BENCH_MODEL_ID", "unknown"),
        },
        "host": {
            "platform": platform.platform(),
            "python": platform.python_version(),
        },
        "paths": {
            "run_root": str(run_root.resolve()),
            "sources_path": str(Path(args.sources_path).resolve()),
            "skill_root": str(Path(args.skill_root).resolve()),
            "sandbox": str(Path(args.sandbox).resolve()),
        },
        "input_hashes": hash_tree(Path(args.sources_path)),
        "output_hashes": hash_tree(Path(args.skill_root)),
        "required_mount_policy": {
            "allowed_mounts": ["sandbox/input", "sandbox/output"],
            "forbidden_paths": ["bench/results", "../"],
        },
    }
    out.write_text(json.dumps(payload, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
