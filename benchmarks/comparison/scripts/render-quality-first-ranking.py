#!/usr/bin/env python3
import argparse
import json
import os
from pathlib import Path
from typing import Any, Dict, List


def _load_json(path: Path) -> Dict[str, Any]:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def _load_manifest(path: Path) -> List[Dict[str, Any]]:
    rows = []
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            rows.append(json.loads(line))
    return rows


def _task_quality(run_root: Path, pipeline: str, task_id: str) -> float:
    task_dir = run_root / pipeline / task_id
    if not task_dir.exists():
        return 0.0

    values: List[float] = []
    for root, _, files in os.walk(task_dir):
        if "run-metadata.json" not in files:
            continue
        meta = _load_json(Path(root) / "run-metadata.json")
        try:
            values.append(float(meta.get("quality_score", 0.0)))
        except Exception:
            continue

    if not values:
        return 0.0
    return sum(values) / len(values)


def render(summary: Dict[str, Any], manifest: List[Dict[str, Any]], run_root: Path) -> str:
    lines: List[str] = []
    lines.append("# Quality-First Ranking")
    lines.append("")
    lines.append(f"- Run ID: `{summary.get('run_id', 'unknown')}`")
    lines.append(f"- Winner (utility summary): `{summary.get('winner', 'none')}`")
    lines.append("")

    pipelines = summary.get("pipelines", {})
    ranked = sorted(
        pipelines.items(),
        key=lambda item: item[1].get("quality", {}).get("quality_score", 0.0),
        reverse=True,
    )

    lines.append("## Aggregate Quality Ranking")
    lines.append("| Rank | Pipeline | Quality Score | Disqualified |")
    lines.append("|---:|---|---:|---|")
    for idx, (pipeline, payload) in enumerate(ranked, start=1):
        quality = payload.get("quality", {}).get("quality_score", 0.0)
        disqualified = payload.get("disqualified", False)
        lines.append(f"| {idx} | {pipeline} | {quality:.4f} | {disqualified} |")
    lines.append("")

    lines.append("## Per-Task Quality Ranking")
    for row in manifest:
        task_id = row.get("task_id", "")
        lines.append(f"### {task_id}")
        lines.append("| Rank | Pipeline | Mean Quality Score |")
        lines.append("|---:|---|---:|")

        task_ranked = []
        for pipeline in pipelines.keys():
            task_ranked.append((pipeline, _task_quality(run_root, pipeline, task_id)))
        task_ranked.sort(key=lambda item: item[1], reverse=True)

        for idx, (pipeline, score) in enumerate(task_ranked, start=1):
            lines.append(f"| {idx} | {pipeline} | {score:.4f} |")
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Render quality-first ranking for benchmark summary.")
    parser.add_argument("--summary", required=True)
    parser.add_argument("--manifest", required=True)
    parser.add_argument("--run-root", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()

    summary = _load_json(Path(args.summary))
    manifest = _load_manifest(Path(args.manifest))
    content = render(summary, manifest, Path(args.run_root))
    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(content, encoding="utf-8")
    print(f"Wrote quality-first ranking: {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
