#!/usr/bin/env python3
import argparse
import json
from pathlib import Path

FORBIDDEN_MARKERS = [
    "rg --files bench/results",
    "find bench/results",
    "cat bench/results",
    "rg --files benchmarks/comparison/results",
    "find benchmarks/comparison/results",
    "cat benchmarks/comparison/results",
]


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--run-root", required=True)
    p.add_argument("--out", required=True)
    p.add_argument("--allow-findings", action="store_true")
    args = p.parse_args()

    run_root = Path(args.run_root)
    findings = []

    for log in sorted(run_root.rglob("generation.stderr.log")):
        text = log.read_text(encoding="utf-8", errors="ignore")
        for marker in FORBIDDEN_MARKERS:
            if marker in text:
                findings.append({"file": str(log), "marker": marker})

    report = {
        "run_root": str(run_root),
        "status": "pass" if not findings else "fail",
        "forbidden_markers": FORBIDDEN_MARKERS,
        "findings": findings,
        "finding_count": len(findings),
    }
    Path(args.out).write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(f"contamination findings: {len(findings)}")

    if findings and not args.allow_findings:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
