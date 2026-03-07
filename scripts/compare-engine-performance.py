#!/usr/bin/env python3
"""Compare legacy and agentic cogworks runs.

Emits:
- benchmark-summary.json
- benchmark-report.md

The script accepts optional run-root inputs for either engine. When a run root
is present it extracts stage-level metrics from run artifacts. When it is
absent, the comparison falls back to log-level and generated-skill metrics.
"""

from __future__ import annotations

import argparse
import json
import math
import os
import subprocess
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


STAGE_ORDER = [
    "source-intake",
    "synthesis",
    "skill-packaging",
    "deterministic-validation",
    "final-review",
    # Historical v1 stage names kept for older saved runs.
    "source-ingest",
    "source-audit",
    "synthesis-critique",
    "decision-architecture",
    "skill-composition",
    "generalization-probe",
    "final-review-package",
]


def iso_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def safe_div(numerator: float | int, denominator: float | int) -> float | None:
    if denominator in (0, 0.0):
        return None
    return numerator / denominator


def percent_delta(baseline: float | int | None, candidate: float | int | None) -> float | None:
    if baseline in (None, 0, 0.0) or candidate is None:
        return None
    return ((candidate - baseline) / baseline) * 100.0


def read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def find_result_event(log_path: Path) -> dict[str, Any] | None:
    if not log_path.exists():
        return None
    for line in log_path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        try:
            obj = json.loads(line)
        except json.JSONDecodeError:
            continue
        if obj.get("type") == "result":
            return obj
    return None


def file_word_count(path: Path) -> int | None:
    if not path.exists():
        return None
    return len(path.read_text(encoding="utf-8").split())


def file_line_count(path: Path) -> int | None:
    if not path.exists():
        return None
    return len(path.read_text(encoding="utf-8").splitlines())


def count_citations(path: Path) -> int | None:
    if not path.exists():
        return None
    text = path.read_text(encoding="utf-8")
    return text.count("[Source ")


def run_generated_skill_validator(repo_root: Path, skill_path: Path) -> dict[str, Any]:
    validator = repo_root / "skills" / "cogworks-learn" / "scripts" / "validate-skill.sh"
    if not validator.exists():
        return {"status": "unavailable", "exit_code": None}

    result = subprocess.run(
        ["bash", str(validator), str(skill_path)],
        cwd=repo_root,
        capture_output=True,
        text=True,
        check=False,
    )
    status = "pass" if result.returncode in (0, 2) else "fail"
    return {
        "status": status,
        "exit_code": result.returncode,
        "stdout": result.stdout.strip(),
    }


def normalize_warning_count(value: Any) -> int:
    if isinstance(value, list):
        return len(value)
    if isinstance(value, str):
        return 0 if value.strip().lower() == "none" else 1
    if isinstance(value, (int, float)):
        return int(value)
    return 0


def normalize_blocking_count(value: Any) -> int:
    if isinstance(value, list):
        return len(value)
    if isinstance(value, str):
        return 0 if value.strip().lower() == "none" else 1
    if isinstance(value, (int, float)):
        return int(value)
    return 0


def aggregate_model_usage(model_usage: Any) -> dict[str, int] | None:
    if not isinstance(model_usage, dict):
        return None

    totals = {
        "input_tokens": 0,
        "output_tokens": 0,
        "cache_read_input_tokens": 0,
        "cache_creation_input_tokens": 0,
    }
    found_any = False

    for usage in model_usage.values():
        if not isinstance(usage, dict):
            continue
        found_any = True
        totals["input_tokens"] += int(usage.get("inputTokens", 0) or 0)
        totals["output_tokens"] += int(usage.get("outputTokens", 0) or 0)
        totals["cache_read_input_tokens"] += int(usage.get("cacheReadInputTokens", 0) or 0)
        totals["cache_creation_input_tokens"] += int(usage.get("cacheCreationInputTokens", 0) or 0)

    return totals if found_any else None


def extract_stage_metrics(run_root: Path) -> dict[str, Any]:
    stage_index_path = run_root / "stage-index.json"
    stage_index = read_json(stage_index_path) if stage_index_path.exists() else None
    dispatch_manifest_path = run_root / "dispatch-manifest.json"
    dispatch_manifest = read_json(dispatch_manifest_path) if dispatch_manifest_path.exists() else None

    run_manifest = read_json(run_root / "run-manifest.json")
    started_at = run_manifest.get("started_at")
    started_ts = None
    if isinstance(started_at, str):
        try:
            started_ts = datetime.fromisoformat(started_at.replace("Z", "+00:00")).timestamp()
        except ValueError:
            started_ts = None

    stage_completion_times: dict[str, float] = {}
    stage_metrics: list[dict[str, Any]] = []
    previous_completion = started_ts

    for stage_name in STAGE_ORDER:
        status_path = run_root / stage_name / "stage-status.json"
        if not status_path.exists():
            continue
        status = read_json(status_path)
        completion = status_path.stat().st_mtime
        stage_completion_times[stage_name] = completion
        duration_ms = None
        if previous_completion is not None:
            duration_ms = max(0, round((completion - previous_completion) * 1000))
        previous_completion = completion

        stage_metrics.append(
            {
                "stage": stage_name,
                "status": status.get("status"),
                "warnings": normalize_warning_count(status.get("warnings")),
                "blocking_failures": normalize_blocking_count(status.get("blocking_failures")),
                "artifacts_count": len(status.get("artifacts", status.get("produced_artifacts", status.get("output_files", []))))
                if isinstance(status.get("artifacts", status.get("produced_artifacts", status.get("output_files", []))), list)
                else None,
                "approx_duration_ms": duration_ms,
                "completed_at_epoch": completion,
            }
        )

    summary: dict[str, Any] = {
        "stage_count": len(stage_metrics),
        "stages": stage_metrics,
    }

    if stage_index:
        summary["stage_index"] = stage_index
        summary["stage_warnings_total"] = stage_index.get("summary", {}).get("total_warnings")
        summary["stage_blocking_failures_total"] = stage_index.get("summary", {}).get("total_blocking_failures")

    if dispatch_manifest:
        summary["dispatch_manifest"] = dispatch_manifest
        dispatches = dispatch_manifest.get("dispatches", [])
        if isinstance(dispatches, list):
            summary["dispatch_binding_types"] = sorted(
                {
                    dispatch.get("binding_type")
                    for dispatch in dispatches
                    if isinstance(dispatch, dict) and dispatch.get("binding_type")
                }
            )
            summary["dispatch_model_policies"] = sorted(
                {
                    dispatch.get("model_policy")
                    for dispatch in dispatches
                    if isinstance(dispatch, dict) and dispatch.get("model_policy")
                }
            )

    deterministic = run_root / "deterministic-validation" / "deterministic-gate-report.json"
    if deterministic.exists():
        summary["deterministic_validation"] = read_json(deterministic)

    probe = run_root / "generalization-probe" / "probe-results.json"
    if probe.exists():
        summary["generalization_probe"] = read_json(probe)

    targeted_probe = run_root / "deterministic-validation" / "targeted-probe-report.md"
    if targeted_probe.exists():
        summary["targeted_probe_ran"] = True
        summary["targeted_probe_report"] = targeted_probe.read_text(encoding="utf-8")
    else:
        summary["targeted_probe_ran"] = False

    return summary


@dataclass
class EngineInput:
    name: str
    skill_path: Path
    log_path: Path | None
    run_root: Path | None


def extract_engine_metrics(repo_root: Path, engine: EngineInput) -> dict[str, Any]:
    skill_path = engine.skill_path
    result_event = find_result_event(engine.log_path) if engine.log_path else None

    summary: dict[str, Any] = {
        "engine": engine.name,
        "skill_path": str(skill_path),
        "log_path": str(engine.log_path) if engine.log_path else None,
        "run_root": str(engine.run_root) if engine.run_root else None,
        "generated_skill_validation": run_generated_skill_validator(repo_root, skill_path),
        "generated_skill_metrics": {
            "skill_md_word_count": file_word_count(skill_path / "SKILL.md"),
            "skill_md_line_count": file_line_count(skill_path / "SKILL.md"),
            "reference_word_count": file_word_count(skill_path / "reference.md"),
            "reference_line_count": file_line_count(skill_path / "reference.md"),
            "reference_citation_count": count_citations(skill_path / "reference.md"),
        },
    }

    if result_event:
        usage = result_event.get("usage") or {}
        model_usage = result_event.get("modelUsage")
        summary["runtime"] = {
            "duration_ms": result_event.get("duration_ms"),
            "duration_api_ms": result_event.get("duration_api_ms"),
            "total_cost_usd": result_event.get("total_cost_usd"),
            "input_tokens": usage.get("input_tokens"),
            "cache_creation_input_tokens": usage.get("cache_creation_input_tokens"),
            "cache_read_input_tokens": usage.get("cache_read_input_tokens"),
            "output_tokens": usage.get("output_tokens"),
        }
        if model_usage:
            summary["model_usage"] = model_usage
            summary["billed_token_totals"] = aggregate_model_usage(model_usage)

    if engine.run_root:
        summary["run"] = extract_stage_metrics(engine.run_root)
        run_manifest_path = engine.run_root / "run-manifest.json"
        if run_manifest_path.exists():
            summary["run_manifest"] = read_json(run_manifest_path)

    return summary


def build_comparison(legacy: dict[str, Any], agentic: dict[str, Any]) -> dict[str, Any]:
    legacy_runtime = legacy.get("runtime", {})
    agentic_runtime = agentic.get("runtime", {})
    legacy_billed = legacy.get("billed_token_totals", {})
    agentic_billed = agentic.get("billed_token_totals", {})

    comparison = {
        "duration_ms": {
            "legacy": legacy_runtime.get("duration_ms"),
            "agentic": agentic_runtime.get("duration_ms"),
        },
        "duration_api_ms": {
            "legacy": legacy_runtime.get("duration_api_ms"),
            "agentic": agentic_runtime.get("duration_api_ms"),
        },
        "total_cost_usd": {
            "legacy": legacy_runtime.get("total_cost_usd"),
            "agentic": agentic_runtime.get("total_cost_usd"),
        },
        "billed_input_tokens": {
            "legacy": legacy_billed.get("input_tokens"),
            "agentic": agentic_billed.get("input_tokens"),
        },
        "billed_output_tokens": {
            "legacy": legacy_billed.get("output_tokens"),
            "agentic": agentic_billed.get("output_tokens"),
        },
        "billed_cache_read_input_tokens": {
            "legacy": legacy_billed.get("cache_read_input_tokens"),
            "agentic": agentic_billed.get("cache_read_input_tokens"),
        },
        "billed_cache_creation_input_tokens": {
            "legacy": legacy_billed.get("cache_creation_input_tokens"),
            "agentic": agentic_billed.get("cache_creation_input_tokens"),
        },
        "reference_citations": {
            "legacy": legacy.get("generated_skill_metrics", {}).get("reference_citation_count"),
            "agentic": agentic.get("generated_skill_metrics", {}).get("reference_citation_count"),
        },
    }

    comparison["deltas"] = {
        "duration_ms_delta": (
            None
            if comparison["duration_ms"]["legacy"] is None or comparison["duration_ms"]["agentic"] is None
            else comparison["duration_ms"]["agentic"] - comparison["duration_ms"]["legacy"]
        ),
        "duration_ms_delta_percent": percent_delta(
            comparison["duration_ms"]["legacy"],
            comparison["duration_ms"]["agentic"],
        ),
        "total_cost_usd_delta": (
            None
            if comparison["total_cost_usd"]["legacy"] is None or comparison["total_cost_usd"]["agentic"] is None
            else comparison["total_cost_usd"]["agentic"] - comparison["total_cost_usd"]["legacy"]
        ),
        "total_cost_usd_delta_percent": percent_delta(
            comparison["total_cost_usd"]["legacy"],
            comparison["total_cost_usd"]["agentic"],
        ),
        "billed_input_tokens_delta": (
            None
            if comparison["billed_input_tokens"]["legacy"] is None or comparison["billed_input_tokens"]["agentic"] is None
            else comparison["billed_input_tokens"]["agentic"] - comparison["billed_input_tokens"]["legacy"]
        ),
        "billed_output_tokens_delta": (
            None
            if comparison["billed_output_tokens"]["legacy"] is None or comparison["billed_output_tokens"]["agentic"] is None
            else comparison["billed_output_tokens"]["agentic"] - comparison["billed_output_tokens"]["legacy"]
        ),
    }
    return comparison


def format_duration_ms(duration_ms: Any) -> str:
    if duration_ms is None:
        return "n/a"
    seconds = duration_ms / 1000.0
    minutes = seconds / 60.0
    if minutes >= 1:
        return f"{minutes:.2f} min"
    return f"{seconds:.2f} s"


def format_number(value: Any, precision: int = 2) -> str:
    if value is None:
        return "n/a"
    if isinstance(value, float):
        return f"{value:.{precision}f}"
    return str(value)


def write_report(path: Path, legacy: dict[str, Any], agentic: dict[str, Any], comparison: dict[str, Any]) -> None:
    legacy_runtime = legacy.get("runtime", {})
    agentic_runtime = agentic.get("runtime", {})
    agentic_manifest = agentic.get("run_manifest", {})
    lines = [
        "# Engine Comparison Report",
        "",
        f"Generated: {iso_now()}",
        "",
        "## Summary",
        "",
        "| Metric | Legacy | Agentic | Delta |",
        "|---|---:|---:|---:|",
        f"| Total duration | {format_duration_ms(legacy_runtime.get('duration_ms'))} | {format_duration_ms(agentic_runtime.get('duration_ms'))} | {format_duration_ms(comparison['deltas']['duration_ms_delta'])} |",
        f"| API duration | {format_duration_ms(legacy_runtime.get('duration_api_ms'))} | {format_duration_ms(agentic_runtime.get('duration_api_ms'))} | n/a |",
        f"| Total cost (USD) | {format_number(legacy_runtime.get('total_cost_usd'), 4)} | {format_number(agentic_runtime.get('total_cost_usd'), 4)} | {format_number(comparison['deltas']['total_cost_usd_delta'], 4)} |",
        f"| Billed input tokens | {format_number(legacy.get('billed_token_totals', {}).get('input_tokens'), 0)} | {format_number(agentic.get('billed_token_totals', {}).get('input_tokens'), 0)} | {format_number(comparison['deltas']['billed_input_tokens_delta'], 0)} |",
        f"| Billed output tokens | {format_number(legacy.get('billed_token_totals', {}).get('output_tokens'), 0)} | {format_number(agentic.get('billed_token_totals', {}).get('output_tokens'), 0)} | {format_number(comparison['deltas']['billed_output_tokens_delta'], 0)} |",
        f"| Billed cache-read tokens | {format_number(legacy.get('billed_token_totals', {}).get('cache_read_input_tokens'), 0)} | {format_number(agentic.get('billed_token_totals', {}).get('cache_read_input_tokens'), 0)} | n/a |",
        f"| Billed cache-create tokens | {format_number(legacy.get('billed_token_totals', {}).get('cache_creation_input_tokens'), 0)} | {format_number(agentic.get('billed_token_totals', {}).get('cache_creation_input_tokens'), 0)} | n/a |",
        f"| Reference citations | {format_number(legacy.get('generated_skill_metrics', {}).get('reference_citation_count'), 0)} | {format_number(agentic.get('generated_skill_metrics', {}).get('reference_citation_count'), 0)} | n/a |",
        "",
        "## Validation",
        "",
        f"- Legacy generated-skill validation: `{legacy.get('generated_skill_validation', {}).get('status')}`",
        f"- Agentic generated-skill validation: `{agentic.get('generated_skill_validation', {}).get('status')}`",
        "",
    ]

    agentic_run = agentic.get("run", {})
    if agentic_manifest:
        lines.extend(
            [
                "## Agentic Runtime",
                "",
                f"- Execution surface: `{agentic_manifest.get('execution_surface', 'n/a')}`",
                f"- Execution adapter: `{agentic_manifest.get('execution_adapter', 'n/a')}`",
                f"- Execution mode: `{agentic_manifest.get('execution_mode', 'n/a')}`",
                f"- Specialist profile source: `{agentic_manifest.get('specialist_profile_source', 'n/a')}`",
                f"- Agentic path: `{agentic_manifest.get('agentic_path', 'n/a')}`",
                f"- Stages expected: `{', '.join(agentic_manifest.get('stages_expected', [])) or 'n/a'}`",
                f"- Targeted probe ran: `{'yes' if agentic_run.get('targeted_probe_ran') else 'no'}`",
                "",
            ]
        )

    if agentic_run.get("dispatch_binding_types") or agentic_run.get("dispatch_model_policies"):
        lines.extend(
            [
                "## Agentic Dispatch",
                "",
                f"- Binding types: `{', '.join(agentic_run.get('dispatch_binding_types', [])) or 'n/a'}`",
                f"- Model policies: `{', '.join(agentic_run.get('dispatch_model_policies', [])) or 'n/a'}`",
                "",
            ]
        )

    if agentic_run.get("stages"):
        lines.extend(
            [
                "## Agentic Stage Timing",
                "",
                "| Stage | Status | Approx Duration | Warnings | Blocking Failures |",
                "|---|---|---:|---:|---:|",
            ]
        )
        for stage in agentic_run["stages"]:
            lines.append(
                f"| {stage['stage']} | {stage.get('status', 'n/a')} | {format_duration_ms(stage.get('approx_duration_ms'))} | "
                f"{format_number(stage.get('warnings'), 0)} | {format_number(stage.get('blocking_failures'), 0)} |"
            )
        lines.append("")

    lines.extend(
        [
            "## Caveats",
            "",
            "- Stage timings are approximate and derived from stage artifact completion times when available.",
            "- Legacy runs without a run root cannot produce comparable stage-level timings.",
            "- Token comparisons use aggregated `modelUsage` totals because Claude's top-level `usage` fields can undercount multi-model work.",
            "- Do not claim quality superiority from this report alone; use it for cost/latency comparison and saved artifacts.",
            "",
        ]
    )

    path.write_text("\n".join(lines), encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Compare legacy and agentic cogworks runs.")
    parser.add_argument("--legacy-skill-path", required=True)
    parser.add_argument("--agentic-skill-path", required=True)
    parser.add_argument("--legacy-log")
    parser.add_argument("--agentic-log")
    parser.add_argument("--legacy-run-root")
    parser.add_argument("--agentic-run-root")
    parser.add_argument("--out-dir", required=True)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    repo_root = Path(__file__).resolve().parents[1]
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    legacy = extract_engine_metrics(
        repo_root,
        EngineInput(
            name="legacy",
            skill_path=Path(args.legacy_skill_path),
            log_path=Path(args.legacy_log) if args.legacy_log else None,
            run_root=Path(args.legacy_run_root) if args.legacy_run_root else None,
        ),
    )
    agentic = extract_engine_metrics(
        repo_root,
        EngineInput(
            name="agentic",
            skill_path=Path(args.agentic_skill_path),
            log_path=Path(args.agentic_log) if args.agentic_log else None,
            run_root=Path(args.agentic_run_root) if args.agentic_run_root else None,
        ),
    )

    comparison = build_comparison(legacy, agentic)
    summary = {
        "generated_at": iso_now(),
        "legacy": legacy,
        "agentic": agentic,
        "comparison": comparison,
    }

    summary_path = out_dir / "benchmark-summary.json"
    report_path = out_dir / "benchmark-report.md"
    summary_path.write_text(json.dumps(summary, indent=2), encoding="utf-8")
    write_report(report_path, legacy, agentic, comparison)

    print(f"Wrote {summary_path}")
    print(f"Wrote {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
