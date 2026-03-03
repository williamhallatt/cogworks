#!/usr/bin/env python3
import argparse
import json
import re
from pathlib import Path

REQUIRED_FILES = [
    "run-metadata.json",
    "metrics.json",
    "quality-eval.json",
    "quality-eval-v2.json",
    "generation-artifact.json",
    "execution-mode.json",
    "skill-install-report.json",
    "skill-use-evidence.json",
    "provenance.json",
]


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--run-root", required=True)
    p.add_argument("--protocol", required=True)
    p.add_argument("--out", required=True)
    args = p.parse_args()

    run_root = Path(args.run_root)
    protocol = json.loads(Path(args.protocol).read_text(encoding="utf-8"))
    expected_tasks = set(protocol.get("tasks", []))
    expected_pipelines = set(protocol.get("pipelines", {}).keys())

    missing = []
    seen_tasks = set()
    seen_pipelines = set()

    run_dir_pattern = re.compile(r"^r\d+$")

    for meta in run_root.rglob("run-metadata.json"):
        run_dir = meta.parent
        # Only evaluate canonical run directories: <pipeline>/<task>/rNN/<variant>/
        if len(run_dir.parts) < 4 or not run_dir_pattern.match(run_dir.parts[-2]):
            continue
        parts = run_dir.parts
        seen_pipelines.add(parts[-4])
        seen_tasks.add(parts[-3])
        for filename in REQUIRED_FILES:
            if not (run_dir / filename).exists():
                missing.append(str(run_dir / filename))

    report = {
        "run_root": str(run_root),
        "status": "pass" if (not missing and expected_tasks <= seen_tasks and expected_pipelines <= seen_pipelines) else "fail",
        "missing_files": missing,
        "expected_tasks": sorted(expected_tasks),
        "seen_tasks": sorted(seen_tasks),
        "expected_pipelines": sorted(expected_pipelines),
        "seen_pipelines": sorted(seen_pipelines),
    }
    Path(args.out).write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(f"reproducibility status: {report['status']}")
    if report["status"] != "pass":
        raise SystemExit(1)


if __name__ == "__main__":
    main()
