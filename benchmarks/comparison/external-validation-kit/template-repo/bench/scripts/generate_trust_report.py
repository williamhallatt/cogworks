#!/usr/bin/env python3
import argparse
import json
import os
from pathlib import Path


def read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def aggregate_v2(run_root: Path, pipelines: list[str], tasks: list[str]):
    scores = {p: [] for p in pipelines}
    for p in pipelines:
        for t in tasks:
            for qf in (run_root / p / t).rglob("quality-eval-v2.json"):
                obj = read_json(qf)
                scores[p].append(float(obj.get("weighted_quality_score", 0.0)))
    means = {p: (sum(v) / len(v) if v else 0.0) for p, v in scores.items()}
    ranking = sorted(means.items(), key=lambda x: x[1], reverse=True)
    winner = ranking[0][0] if ranking else "none"
    return means, winner


def aggregate_v2_by_mode(means, pipeline_modes):
    grouped = {}
    for p, score in means.items():
        mode = pipeline_modes.get(p, "protocol_prompt")
        grouped.setdefault(mode, []).append((p, score))
    winners = {}
    means_by_mode = {}
    for mode, rows in grouped.items():
        rows = sorted(rows, key=lambda x: x[1], reverse=True)
        winners[mode] = rows[0][0] if rows else "none"
        means_by_mode[mode] = {k: v for k, v in rows}
    return means_by_mode, winners


def skill_gate_status(run_root: Path, protocol: dict):
    issues = []
    checks = []
    for pipeline, payload in protocol.get("pipelines", {}).items():
        if payload.get("execution_mode") != "skill_installed":
            continue
        for task in protocol.get("tasks", []):
            task_root = run_root / pipeline / task
            for run_dir in task_root.rglob("run-metadata.json"):
                rd = run_dir.parent
                install = rd / "skill-install-report.json"
                evidence = rd / "skill-use-evidence.json"
                if not install.exists():
                    issues.append(f"missing install report: {install}")
                    continue
                if not evidence.exists():
                    issues.append(f"missing skill-use evidence: {evidence}")
                    continue
                inst = read_json(install)
                ev = read_json(evidence)
                if not bool(inst.get("success", False)):
                    issues.append(f"install failed: {install}")
                if not bool(ev.get("pass", False)):
                    issues.append(f"usage evidence failed: {evidence}")
                checks.append({
                    "run_dir": str(rd),
                    "install_success": bool(inst.get("success", False)),
                    "usage_evidence_pass": bool(ev.get("pass", False)),
                })
    return (len(issues) == 0), issues, checks


def detect_real_mode(run_root: Path) -> bool:
    """Infer whether the run executed in real mode from case artifacts."""
    reports = list(run_root.rglob("skill-install-report.json"))
    if not reports:
        return False
    seen_real = False
    for p in reports:
        try:
            payload = read_json(p)
        except Exception:
            continue
        if payload.get("mode") == "real":
            seen_real = True
            break
    return seen_real


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--run-root", required=True)
    p.add_argument("--protocol", required=True)
    p.add_argument("--out-json", required=True)
    p.add_argument("--out-md", required=True)
    args = p.parse_args()

    run_root = Path(args.run_root)
    protocol = read_json(Path(args.protocol))
    tasks = protocol.get("tasks", [])
    pipelines = list(protocol.get("pipelines", {}).keys())
    pipeline_modes = {
        name: payload.get("execution_mode", "protocol_prompt")
        for name, payload in protocol.get("pipelines", {}).items()
    }

    pilot = read_json(run_root / "pilot-summary.json")
    winner_v1 = pilot.get("winner", "none")
    winners_v1_by_mode = pilot.get("winners_by_mode", {})

    means_v2, winner_v2 = aggregate_v2(run_root, pipelines, tasks)
    means_v2_by_mode, winners_v2_by_mode = aggregate_v2_by_mode(means_v2, pipeline_modes)

    contamination = read_json(run_root / "contamination-report.json")
    reproducibility = read_json(run_root / "reproducibility-report.json")

    repeats_min = int(protocol.get("reproducibility", {}).get("repeats_min", 3))
    repeat_indices = set()
    for meta in run_root.rglob("run-metadata.json"):
        try:
            payload = read_json(meta)
        except Exception:
            continue
        idx = payload.get("repeat_index")
        if isinstance(idx, int):
            repeat_indices.add(idx)
    repeat_count = len(repeat_indices)

    skill_gates_ok, skill_gate_issues, skill_gate_checks = skill_gate_status(run_root, protocol)
    is_real_mode = detect_real_mode(run_root)
    is_ci = os.environ.get("CI", "").lower() in {"1", "true", "yes"}
    authoritative_run = is_real_mode and is_ci
    if not authoritative_run:
        if not is_real_mode:
            authoritative_reason = "run mode is not real"
        elif not is_ci:
            authoritative_reason = "run did not execute in CI"
        else:
            authoritative_reason = "authoritative preconditions not met"
    else:
        authoritative_reason = "real mode run executed in CI"

    skill_installed_agreement = True
    if "skill_installed" in winners_v1_by_mode or "skill_installed" in winners_v2_by_mode:
        skill_installed_agreement = winners_v1_by_mode.get("skill_installed") == winners_v2_by_mode.get("skill_installed")

    trust_checks = {
        "winner_agreement": winner_v1 == winner_v2,
        "skill_installed_winner_agreement": skill_installed_agreement,
        "contamination_clear": contamination.get("status") == "pass",
        "reproducibility_pass": reproducibility.get("status") == "pass",
        "repeat_count_min": repeat_count >= repeats_min,
        "skill_installed_gates_pass": skill_gates_ok,
        "authoritative_run": authoritative_run,
    }
    trust_level = "high" if all(trust_checks.values()) else "conditional"

    payload = {
        "run_root": str(run_root),
        "pipeline_modes": pipeline_modes,
        "winner_v1": winner_v1,
        "winner_v2": winner_v2,
        "winners_v1_by_mode": winners_v1_by_mode,
        "winners_v2_by_mode": winners_v2_by_mode,
        "v2_means": means_v2,
        "v2_means_by_mode": means_v2_by_mode,
        "repeat_directories_seen": repeat_count,
        "repeats_min_required": repeats_min,
        "authoritative_run": authoritative_run,
        "authoritative_reason": authoritative_reason,
        "skill_gate_checks": skill_gate_checks,
        "skill_gate_issues": skill_gate_issues,
        "trust_checks": trust_checks,
        "trust_level": trust_level,
    }

    Path(args.out_json).write_text(json.dumps(payload, indent=2), encoding="utf-8")

    md = [
        "# Trust Report",
        "",
        f"- Run root: `{run_root}`",
        f"- Winner (scorer v1): `{winner_v1}`",
        f"- Winner (scorer v2): `{winner_v2}`",
        f"- Authoritative run: `{authoritative_run}` ({authoritative_reason})",
        f"- Trust level: `{trust_level}`",
        "",
        "## Winners By Execution Mode",
    ]
    all_modes = sorted(set(winners_v1_by_mode.keys()) | set(winners_v2_by_mode.keys()))
    for mode in all_modes:
        md.append(f"- `{mode}`: v1=`{winners_v1_by_mode.get(mode,'none')}`, v2=`{winners_v2_by_mode.get(mode,'none')}`")

    md.extend(["", "## Checks"])
    for k, v in trust_checks.items():
        md.append(f"- `{k}`: {'PASS' if v else 'FAIL'}")

    if skill_gate_issues:
        md.extend(["", "## Skill Gate Issues"])
        for issue in skill_gate_issues:
            md.append(f"- {issue}")

    md.extend(["", "## Scorer v2 Means"])
    for p, v in sorted(means_v2.items(), key=lambda x: x[1], reverse=True):
        md.append(f"- `{p}`: {v:.4f} ({pipeline_modes.get(p, 'protocol_prompt')})")

    Path(args.out_md).write_text("\n".join(md) + "\n", encoding="utf-8")

    print(f"trust level: {trust_level}")
    if trust_level != "high":
        raise SystemExit(1)


if __name__ == "__main__":
    main()
