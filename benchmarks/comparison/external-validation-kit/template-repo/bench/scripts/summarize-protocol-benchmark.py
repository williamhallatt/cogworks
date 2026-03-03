#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


def load_json(path: Path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def task_quality(run_root: Path, pipeline: str, task_id: str):
    task_dir = run_root / pipeline / task_id
    if not task_dir.exists():
        return {"quality": 0.0, "valid": False, "reason": "missing task dir"}

    vals = []
    failures = []
    for qf in task_dir.rglob("quality-eval.json"):
        q = load_json(qf)
        vals.append(float(q.get("weighted_quality_score", 0.0)))
        if q.get("status") != "pass":
            failures.append(q.get("reason", "quality eval failed"))

    if not vals:
        return {"quality": 0.0, "valid": False, "reason": "missing quality-eval.json"}

    return {
        "quality": round(sum(vals) / len(vals), 4),
        "valid": len(failures) == 0,
        "reason": "; ".join(failures) if failures else "ok",
    }


def aggregate_by_mode(aggregate_ranking, pipeline_modes):
    mode_groups = {}
    for row in aggregate_ranking:
        mode = pipeline_modes.get(row["pipeline"], "protocol_prompt")
        mode_groups.setdefault(mode, []).append(row)

    winners = {}
    for mode, rows in mode_groups.items():
        rows.sort(key=lambda r: r["mean_quality"], reverse=True)
        winners[mode] = rows[0]["pipeline"] if rows else "none"

    return {
        mode: sorted(rows, key=lambda r: r["mean_quality"], reverse=True)
        for mode, rows in mode_groups.items()
    }, winners


def render_report(summary):
    lines = []
    lines.append("# Protocol Benchmark Pilot Report")
    lines.append("")
    lines.append(f"- Run ID: `{summary['run_id']}`")
    lines.append(f"- Status: `{summary['status']}`")
    lines.append(f"- Model Family: `{summary['model_family']}`")
    lines.append("")

    lines.append("## Aggregate Ranking (All Pipelines)")
    lines.append("| Rank | Pipeline | Execution Mode | Mean Quality | Valid Tasks |")
    lines.append("|---:|---|---|---:|---:|")
    for i, row in enumerate(summary["aggregate_ranking"], start=1):
        mode = summary["pipeline_modes"].get(row["pipeline"], "protocol_prompt")
        lines.append(f"| {i} | {row['pipeline']} | {mode} | {row['mean_quality']:.4f} | {row['valid_tasks']} |")
    lines.append("")

    lines.append("## Winners By Execution Mode")
    for mode, winner in summary.get("winners_by_mode", {}).items():
        lines.append(f"- `{mode}` winner: `{winner}`")
    lines.append("")

    lines.append("## Per-Task Ranking")
    for task in summary["task_rankings"]:
        lines.append(f"### {task['task_id']}")
        lines.append("| Rank | Pipeline | Execution Mode | Quality | Valid | Reason |")
        lines.append("|---:|---|---|---:|---|---|")
        for i, row in enumerate(task["ranking"], start=1):
            mode = summary["pipeline_modes"].get(row["pipeline"], "protocol_prompt")
            lines.append(f"| {i} | {row['pipeline']} | {mode} | {row['quality']:.4f} | {row['valid']} | {row['reason']} |")
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def main():
    p = argparse.ArgumentParser(description="Summarize protocol-run benchmark outputs.")
    p.add_argument("--run-id", required=True)
    p.add_argument("--results-root", default="bench/results/pipeline-benchmark")
    p.add_argument("--protocol", required=True)
    p.add_argument("--out-json", default=None)
    p.add_argument("--out-md", default=None)
    args = p.parse_args()

    protocol = load_json(Path(args.protocol))
    tasks = protocol.get("tasks", [])
    pipelines = list(protocol.get("pipelines", {}).keys())
    pipeline_modes = {
        name: payload.get("execution_mode", "protocol_prompt")
        for name, payload in protocol.get("pipelines", {}).items()
    }
    run_root = Path(args.results_root) / args.run_id

    task_rankings = []
    aggregate = {pl: {"quality_sum": 0.0, "count": 0, "valid_tasks": 0} for pl in pipelines}

    for task in tasks:
        rows = []
        for pl in pipelines:
            q = task_quality(run_root, pl, task)
            rows.append({
                "pipeline": pl,
                "quality": q["quality"],
                "valid": q["valid"],
                "reason": q["reason"],
            })
            aggregate[pl]["quality_sum"] += q["quality"]
            aggregate[pl]["count"] += 1
            if q["valid"]:
                aggregate[pl]["valid_tasks"] += 1

        rows.sort(key=lambda r: r["quality"], reverse=True)
        task_rankings.append({"task_id": task, "ranking": rows})

    aggregate_ranking = []
    for pl, payload in aggregate.items():
        mean_quality = payload["quality_sum"] / payload["count"] if payload["count"] else 0.0
        aggregate_ranking.append({
            "pipeline": pl,
            "mean_quality": round(mean_quality, 4),
            "valid_tasks": payload["valid_tasks"],
        })
    aggregate_ranking.sort(key=lambda r: r["mean_quality"], reverse=True)

    aggregate_modes, winners_by_mode = aggregate_by_mode(aggregate_ranking, pipeline_modes)

    status = "PASS" if any(r["valid_tasks"] > 0 for r in aggregate_ranking) else "FAIL"
    winner = aggregate_ranking[0]["pipeline"] if aggregate_ranking else "none"

    summary = {
        "run_id": args.run_id,
        "status": status,
        "winner": winner,
        "winners_by_mode": winners_by_mode,
        "model_family": protocol.get("model_family", ""),
        "tasks": tasks,
        "pipelines": pipelines,
        "pipeline_modes": pipeline_modes,
        "task_rankings": task_rankings,
        "aggregate_ranking": aggregate_ranking,
        "aggregate_by_execution_mode": aggregate_modes,
    }

    out_json = Path(args.out_json or (run_root / "pilot-summary.json"))
    out_md = Path(args.out_md or (run_root / "pilot-report.md"))
    out_json.parent.mkdir(parents=True, exist_ok=True)
    out_md.parent.mkdir(parents=True, exist_ok=True)
    out_json.write_text(json.dumps(summary, indent=2), encoding="utf-8")
    out_md.write_text(render_report(summary), encoding="utf-8")

    (run_root / "quality-first-ranking.md").write_text(render_report(summary), encoding="utf-8")

    print(f"Wrote summary: {out_json}")
    print(f"Wrote report:  {out_md}")
    print(f"Winner: {winner}")


if __name__ == "__main__":
    main()
