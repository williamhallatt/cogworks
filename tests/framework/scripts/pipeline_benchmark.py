#!/usr/bin/env python3
import json
import os
import shlex
import statistics
import subprocess
import time
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path
from typing import Any, Dict, List, Optional


REQUIRED_MANIFEST_FIELDS = [
    "task_id",
    "sources_path",
    "expected_skill_intent",
    "domain",
    "difficulty",
    "risk_tier",
]

QUALITY_WEIGHTS = {
    "source_fidelity": 0.30,
    "self_sufficiency": 0.25,
    "completeness": 0.20,
    "specificity": 0.15,
    "no_overlap": 0.10,
}

UTILITY_WEIGHTS = {
    "quality": 0.60,
    "robustness": 0.25,
    "cost": 0.15,
}

GUARDRAILS = {
    "structural_pass_rate_min": 0.95,
    "activation_f1_min": 0.85,
    "false_positive_rate_max": 0.05,
    "negative_control_ratio_min": 0.25,
}


@dataclass
class TaskRun:
    task_id: str
    pipeline: str
    layer1_pass: bool
    quality_score: float
    activation_f1: float
    false_positive_rate: float
    negative_control_ratio: float
    perturbation_success: bool
    runtime_sec: float
    total_tokens: float
    context_tokens: float
    failed: bool


def _read_json(path: Path) -> Dict[str, Any]:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def _write_json(path: Path, payload: Dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2)


def _write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)


def _load_manifest(manifest_path: Path) -> List[Dict[str, Any]]:
    cases: List[Dict[str, Any]] = []
    with open(manifest_path, "r", encoding="utf-8") as f:
        for i, raw in enumerate(f, start=1):
            line = raw.strip()
            if not line:
                continue
            item = json.loads(line)
            missing = [k for k in REQUIRED_MANIFEST_FIELDS if k not in item]
            if missing:
                raise ValueError(f"manifest line {i} missing required fields: {', '.join(missing)}")
            cases.append(item)
    if not cases:
        raise ValueError(f"manifest has no cases: {manifest_path}")
    return cases


def _weighted_quality_from_layer2(layer2: Dict[str, Any]) -> float:
    score = 0.0
    for k, w in QUALITY_WEIGHTS.items():
        raw = layer2.get(k, {})
        val = raw.get("score", 0) if isinstance(raw, dict) else 0
        score += float(val) * w
    return score / 5.0


def _clamp01(value: float) -> float:
    return max(0.0, min(1.0, value))


def _normalize_inverse(values: Dict[str, float]) -> Dict[str, float]:
    min_v = min(values.values())
    max_v = max(values.values())
    if abs(max_v - min_v) < 1e-9:
        return {k: 0.5 for k in values}
    return {k: 1.0 - ((v - min_v) / (max_v - min_v)) for k, v in values.items()}


def _normalize_direct(values: Dict[str, float]) -> Dict[str, float]:
    min_v = min(values.values())
    max_v = max(values.values())
    if abs(max_v - min_v) < 1e-9:
        return {k: 0.5 for k in values}
    return {k: (v - min_v) / (max_v - min_v) for k, v in values.items()}


def _mean(values: List[float]) -> float:
    return float(sum(values) / len(values)) if values else 0.0


def _safe_std(values: List[float]) -> float:
    return float(statistics.pstdev(values)) if len(values) > 1 else 0.0


def _p95(values: List[float]) -> float:
    if not values:
        return 0.0
    vals = sorted(values)
    idx = int(round(0.95 * (len(vals) - 1)))
    return float(vals[idx])


def _ci95(values: List[float]) -> Dict[str, float]:
    if not values:
        return {"mean": 0.0, "ci95_low": 0.0, "ci95_high": 0.0, "n": 0}
    mean = _mean(values)
    n = len(values)
    if n == 1:
        return {"mean": mean, "ci95_low": mean, "ci95_high": mean, "n": 1}
    stdev = _safe_std(values)
    se = stdev / (n ** 0.5)
    margin = 1.96 * se
    return {
        "mean": mean,
        "ci95_low": mean - margin,
        "ci95_high": mean + margin,
        "n": n,
    }


def _iter_task_run_dirs(task_dir: Path) -> List[Path]:
    direct_meta = task_dir / "run-metadata.json"
    if direct_meta.exists():
        return [task_dir]

    run_dirs: List[Path] = []
    for root, _, files in os.walk(task_dir):
        if "run-metadata.json" in files:
            run_dirs.append(Path(root))
    return sorted(run_dirs)


def _read_task_run(task_dir: Path, pipeline: str, task_id: str) -> TaskRun:
    meta_path = task_dir / "run-metadata.json"
    meta = _read_json(meta_path) if meta_path.exists() else {}

    quality_path = task_dir / "quality.json"
    quality = _read_json(quality_path) if quality_path.exists() else {}

    behavioral_path = task_dir / "behavioral-summary.json"
    behavioral = _read_json(behavioral_path) if behavioral_path.exists() else {}

    layer1_pass = bool(meta.get("layer1_pass", False))

    if "quality_score" in meta:
        quality_score = float(meta["quality_score"])
    elif "weighted_score" in quality:
        quality_score = float(quality["weighted_score"])
    elif "layer2" in quality and isinstance(quality["layer2"], dict):
        quality_score = _weighted_quality_from_layer2(quality["layer2"])
    else:
        quality_score = 0.0

    activation_f1 = float(behavioral.get("activation_f1", meta.get("activation_f1", 0.0)))
    false_positive_rate = float(
        behavioral.get("false_positive_rate", meta.get("false_positive_rate", 1.0))
    )
    negative_control_ratio = float(
        behavioral.get("negative_control_ratio", meta.get("negative_control_ratio", 0.0))
    )

    usage = meta.get("usage") or {}
    total_tokens = float(usage.get("total_tokens", meta.get("total_tokens", 0.0)))
    context_tokens = float(usage.get("context_tokens", meta.get("context_tokens", 0.0)))
    runtime_sec = float(meta.get("runtime_sec", 0.0))

    perturbation_success = bool(meta.get("perturbation_success", True))
    failed = bool(meta.get("failed", False))

    return TaskRun(
        task_id=task_id,
        pipeline=pipeline,
        layer1_pass=layer1_pass,
        quality_score=quality_score,
        activation_f1=activation_f1,
        false_positive_rate=false_positive_rate,
        negative_control_ratio=negative_control_ratio,
        perturbation_success=perturbation_success,
        runtime_sec=runtime_sec,
        total_tokens=total_tokens,
        context_tokens=context_tokens,
        failed=failed,
    )


def _score_pipeline(runs: List[TaskRun]) -> Dict[str, Any]:
    structural_pass_values = [1.0 if r.layer1_pass else 0.0 for r in runs]
    activation_values = [r.activation_f1 for r in runs]
    fpr_values = [r.false_positive_rate for r in runs]
    neg_values = [r.negative_control_ratio for r in runs]
    quality_values = [r.quality_score for r in runs]

    structural_pass_rate = _mean(structural_pass_values)
    activation_f1 = _mean(activation_values)
    false_positive_rate = _mean(fpr_values)
    negative_control_ratio = _mean(neg_values)
    quality_score = _mean(quality_values)

    perturbation_success_rate = _mean([1.0 if r.perturbation_success else 0.0 for r in runs])
    quality_stddev = _safe_std(quality_values)
    failure_rate = _mean([1.0 if r.failed else 0.0 for r in runs])
    std_component = _clamp01(1.0 - (quality_stddev / 0.20))
    robustness_score_raw = 0.50 * perturbation_success_rate + 0.30 * std_component + 0.20 * (1.0 - failure_rate)

    runtime_median = statistics.median([r.runtime_sec for r in runs]) if runs else 0.0
    total_tokens_median = statistics.median([r.total_tokens for r in runs]) if runs else 0.0
    context_tokens_p95 = _p95([r.context_tokens for r in runs])

    guardrails = {
        "structural_pass_rate": structural_pass_rate >= GUARDRAILS["structural_pass_rate_min"],
        "activation_f1": activation_f1 >= GUARDRAILS["activation_f1_min"],
        "false_positive_rate": false_positive_rate <= GUARDRAILS["false_positive_rate_max"],
        "negative_control_ratio": negative_control_ratio >= GUARDRAILS["negative_control_ratio_min"],
    }
    disqualified = not all(guardrails.values())

    return {
        "num_runs": len(runs),
        "quality": {
            "quality_score": quality_score,
            "structural_pass_rate": structural_pass_rate,
            "activation_f1": activation_f1,
            "false_positive_rate": false_positive_rate,
            "negative_control_ratio": negative_control_ratio,
            "quality_score_ci95": _ci95(quality_values),
            "activation_f1_ci95": _ci95(activation_values),
        },
        "robustness": {
            "perturbation_success_rate": perturbation_success_rate,
            "quality_stddev": quality_stddev,
            "failure_rate": failure_rate,
            "raw_score": robustness_score_raw,
        },
        "cost": {
            "runtime_sec_median": runtime_median,
            "total_tokens_median": total_tokens_median,
            "context_tokens_p95": context_tokens_p95,
        },
        "guardrails": guardrails,
        "disqualified": disqualified,
    }


def _render_report(run_id: str, priority: str, pipeline_scores: Dict[str, Dict[str, Any]], winner: str) -> str:
    lines: List[str] = []
    lines.append("# Pipeline Benchmark Report\n")
    lines.append(f"- Run ID: `{run_id}`")
    lines.append(f"- Priority: `{priority}`")
    lines.append(f"- Winner: `{winner}`")
    lines.append("")
    lines.append("## Scorecard")
    lines.append("| Pipeline | Utility | Quality | Robustness | Cost | Disqualified |")
    lines.append("|---|---:|---:|---:|---:|---|")
    for pipeline, score in pipeline_scores.items():
        lines.append(
            f"| {pipeline} | {score.get('utility_score', 0.0):.4f} | "
            f"{score.get('quality_normalized', 0.0):.4f} | "
            f"{score.get('robustness_normalized', 0.0):.4f} | "
            f"{score.get('cost_normalized', 0.0):.4f} | "
            f"{score.get('disqualified', False)} |"
        )
    lines.append("")
    lines.append("## Confidence")
    for pipeline, score in pipeline_scores.items():
        q_ci = score["quality"]["quality_score_ci95"]
        f1_ci = score["quality"]["activation_f1_ci95"]
        lines.append(f"### {pipeline}")
        lines.append(
            f"- quality_score mean={q_ci['mean']:.4f}, ci95=[{q_ci['ci95_low']:.4f}, {q_ci['ci95_high']:.4f}], n={q_ci['n']}"
        )
        lines.append(
            f"- activation_f1 mean={f1_ci['mean']:.4f}, ci95=[{f1_ci['ci95_low']:.4f}, {f1_ci['ci95_high']:.4f}], n={f1_ci['n']}"
        )
        lines.append("")
    lines.append("## Guardrails")
    for pipeline, score in pipeline_scores.items():
        lines.append(f"### {pipeline}")
        for gate, passed in score["guardrails"].items():
            lines.append(f"- `{gate}`: {'PASS' if passed else 'FAIL'}")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def _default_metadata(task_id: str, pipeline: str, variant: str = "clean", repeat_index: int = 1) -> Dict[str, Any]:
    return {
        "task_id": task_id,
        "pipeline": pipeline,
        "variant": variant,
        "repeat_index": repeat_index,
        "layer1_pass": False,
        "quality_score": 0.0,
        "activation_f1": 0.0,
        "false_positive_rate": 1.0,
        "negative_control_ratio": 0.0,
        "perturbation_success": variant == "clean",
        "runtime_sec": 0.0,
        "usage": {"total_tokens": 0, "context_tokens": 0},
        "failed": False,
    }


def scaffold_layout(args: Any) -> int:
    manifest_cases = _load_manifest(Path(args.manifest))
    pipelines = args.pipeline
    variants = args.variant or ["clean"]
    repeats = int(args.repeats)
    root = Path(args.results_root) / args.run_id

    for pipeline in pipelines:
        for case in manifest_cases:
            task_id = case["task_id"]
            task_root = root / pipeline / task_id
            task_root.mkdir(parents=True, exist_ok=True)

            if repeats == 1 and variants == ["clean"]:
                meta_path = task_root / "run-metadata.json"
                if args.force or not meta_path.exists():
                    _write_json(meta_path, _default_metadata(task_id, pipeline))
                continue

            for rep in range(1, repeats + 1):
                for variant in variants:
                    run_dir = task_root / f"r{rep:02d}" / variant
                    meta_path = run_dir / "run-metadata.json"
                    if args.force or not meta_path.exists():
                        _write_json(meta_path, _default_metadata(task_id, pipeline, variant=variant, repeat_index=rep))

    print(f"Scaffolded benchmark layout at: {root}")
    return 0


def _parse_templates(raw_templates: List[str]) -> Dict[str, str]:
    templates: Dict[str, str] = {}
    for raw in raw_templates:
        if "::" not in raw:
            raise ValueError("command-template must use 'pipeline::command' format")
        pipeline, template = raw.split("::", 1)
        pipeline = pipeline.strip()
        template = template.strip()
        if not pipeline or not template:
            raise ValueError("invalid command-template: empty pipeline or command")
        templates[pipeline] = template
    return templates


def _expand_template(template: str, context: Dict[str, Any]) -> str:
    class SafeDict(dict):
        def __missing__(self, key: str) -> str:
            return ""

    return template.format_map(SafeDict(context))


def run_benchmark(args: Any) -> int:
    manifest_cases = _load_manifest(Path(args.manifest))
    pipelines = args.pipeline
    variants = args.variant or ["clean"]
    repeats = int(args.repeats)
    run_root = Path(args.results_root) / args.run_id

    if args.command_template:
        templates = _parse_templates(args.command_template)
    else:
        templates = {}

    if not args.dry_run:
        missing_templates = [p for p in pipelines if p not in templates]
        if missing_templates:
            print(
                "Error: missing --command-template for pipeline(s): " + ", ".join(missing_templates),
                flush=True,
            )
            return 2

    executed = 0
    failures = 0

    for pipeline in pipelines:
        for case in manifest_cases:
            task_id = case["task_id"]
            for rep in range(1, repeats + 1):
                for variant in variants:
                    out_dir = run_root / pipeline / task_id / f"r{rep:02d}" / variant
                    out_dir.mkdir(parents=True, exist_ok=True)
                    meta_path = out_dir / "run-metadata.json"

                    if meta_path.exists() and not args.force:
                        continue

                    meta = _default_metadata(task_id, pipeline, variant=variant, repeat_index=rep)
                    context = {
                        **case,
                        "pipeline": pipeline,
                        "task_id": task_id,
                        "variant": variant,
                        "repeat_index": rep,
                        "out_dir": str(out_dir),
                    }

                    if args.dry_run:
                        meta["failed"] = False
                        meta["layer1_pass"] = False
                        meta["notes"] = "dry-run placeholder"
                        _write_json(meta_path, meta)
                        executed += 1
                        continue

                    command = _expand_template(templates[pipeline], context)
                    started = time.time()
                    proc = subprocess.run(
                        command,
                        shell=True,
                        cwd=args.cwd or os.getcwd(),
                        capture_output=True,
                        text=True,
                    )
                    elapsed = time.time() - started

                    meta["runtime_sec"] = round(elapsed, 4)
                    meta["failed"] = proc.returncode != 0
                    meta["command"] = command
                    meta["exit_code"] = proc.returncode
                    meta["layer1_pass"] = proc.returncode == 0

                    if proc.stdout:
                        _write_text(out_dir / "stdout.log", proc.stdout)
                    if proc.stderr:
                        _write_text(out_dir / "stderr.log", proc.stderr)

                    metrics_path = out_dir / "metrics.json"
                    if metrics_path.exists():
                        metrics = _read_json(metrics_path)
                        if isinstance(metrics, dict):
                            meta.update({k: v for k, v in metrics.items() if k != "task_id"})

                    _write_json(meta_path, meta)
                    executed += 1
                    if meta["failed"]:
                        failures += 1

    print(f"Executed benchmark runs: {executed}")
    print(f"Failed runs: {failures}")
    return 0 if failures == 0 else 1


def summarize_benchmark(args: Any) -> int:
    manifest_cases = _load_manifest(Path(args.manifest))
    task_ids = {c["task_id"] for c in manifest_cases}
    run_root = Path(args.results_root) / args.run_id
    pipeline_runs: Dict[str, List[TaskRun]] = {}

    for pipeline in args.pipeline:
        runs: List[TaskRun] = []
        for task_id in sorted(task_ids):
            task_dir = run_root / pipeline / task_id
            if not task_dir.exists():
                continue
            for run_dir in _iter_task_run_dirs(task_dir):
                runs.append(_read_task_run(run_dir, pipeline, task_id))
        pipeline_runs[pipeline] = runs

    missing = [p for p, runs in pipeline_runs.items() if not runs]
    if missing:
        print(f"Error: no runs found for pipeline(s): {', '.join(missing)}", flush=True)
        return 2

    raw_scores = {p: _score_pipeline(runs) for p, runs in pipeline_runs.items()}

    quality_values = {p: raw_scores[p]["quality"]["quality_score"] for p in raw_scores}
    robustness_values = {p: raw_scores[p]["robustness"]["raw_score"] for p in raw_scores}

    cost_combined: Dict[str, float] = {}
    for p, r in raw_scores.items():
        c = r["cost"]
        cost_combined[p] = 0.50 * c["total_tokens_median"] + 0.30 * c["context_tokens_p95"] + 0.20 * c["runtime_sec_median"]

    quality_norm = _normalize_direct(quality_values)
    robustness_norm = _normalize_direct(robustness_values)
    cost_norm = _normalize_inverse(cost_combined)

    scored: Dict[str, Dict[str, Any]] = {}
    for p, r in raw_scores.items():
        utility = (
            UTILITY_WEIGHTS["quality"] * quality_norm[p]
            + UTILITY_WEIGHTS["robustness"] * robustness_norm[p]
            + UTILITY_WEIGHTS["cost"] * cost_norm[p]
        )
        item = dict(r)
        item["quality_normalized"] = quality_norm[p]
        item["robustness_normalized"] = robustness_norm[p]
        item["cost_normalized"] = cost_norm[p]
        item["utility_score"] = 0.0 if item["disqualified"] else utility
        scored[p] = item

    non_disqualified = [p for p, s in scored.items() if not s["disqualified"]]
    if not non_disqualified:
        winner = "none"
        status = "FAIL"
    else:
        winner = max(non_disqualified, key=lambda p: scored[p]["utility_score"])
        status = "PASS"

    summary = {
        "timestamp": datetime.now(UTC).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "run_id": args.run_id,
        "priority": "quality-first",
        "weights": {"utility": UTILITY_WEIGHTS, "quality": QUALITY_WEIGHTS},
        "guardrails": GUARDRAILS,
        "pipelines": scored,
        "winner": winner,
        "status": status,
    }

    out_json = Path(args.output_json)
    out_md = Path(args.output_md)
    _write_json(out_json, summary)
    _write_text(out_md, _render_report(args.run_id, "quality-first", scored, winner))

    print(f"Wrote summary: {out_json}")
    print(f"Wrote report:  {out_md}")
    if winner == "none":
        print("No winner selected: all pipelines disqualified.")
        return 1
    print(f"Winner: {winner}")
    return 0
