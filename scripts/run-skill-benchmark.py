#!/usr/bin/env python3
"""Run a paired skill-vs-skill benchmark using normalized observation artifacts.

The harness executes two candidate commands across repeated trials for each case.
Each candidate command must write:

- a normalized observation JSON to ``$COGWORKS_BENCHMARK_OBSERVATION_PATH``
- optionally, a judge output JSON to ``$COGWORKS_BENCHMARK_JUDGE_OUTPUT_PATH``

The harness scores deterministic checks directly from the observation and any
artifacts under ``artifact_root``. It uses judge output only for ``judge_only``
checks. Outputs:

- benchmark-summary.json
- benchmark-report.md
- benchmark-results.json
"""

from __future__ import annotations

import argparse
import json
import math
import os
import random
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def iso_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def timestamp_id() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")


def mean(values: list[float]) -> float:
    return sum(values) / len(values) if values else 0.0


def bootstrap_ci(values: list[float], resamples: int = 2000) -> tuple[float, float]:
    if not values:
        return (0.0, 0.0)
    rng = random.Random(42)
    means = []
    for _ in range(resamples):
        sample = [rng.choice(values) for _ in range(len(values))]
        means.append(mean(sample))
    means.sort()
    lower_idx = int(0.025 * len(means))
    upper_idx = min(int(0.975 * len(means)), len(means) - 1)
    return (means[lower_idx], means[upper_idx])


def load_cases(path: Path) -> list[dict[str, Any]]:
    text = path.read_text(encoding="utf-8").strip()
    if not text:
        raise SystemExit(f"Empty cases file: {path}")
    if path.suffix == ".json":
        raw = json.loads(text)
        if not isinstance(raw, list):
            raise SystemExit(f"Expected JSON array in {path}")
        cases = raw
    else:
        cases = []
        for line in text.splitlines():
            stripped = line.strip()
            if not stripped:
                continue
            cases.append(json.loads(stripped))
    seen: set[str] = set()
    for case in cases:
        for field in ("schema_version", "case_id", "title", "category", "task_prompt", "expected_activation", "observable_checks"):
            if field not in case:
                raise SystemExit(f"Case missing required field '{field}': {case}")
        case_id = str(case["case_id"])
        if case_id in seen:
            raise SystemExit(f"Duplicate case_id in {path}: {case_id}")
        seen.add(case_id)
    return cases


def write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2), encoding="utf-8")


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _pattern_matches(expected: str, actual: str) -> bool:
    if expected.startswith("re:"):
        return re.search(expected[len("re:") :], actual) is not None
    return actual.startswith(expected)


def _get_by_path(data: dict[str, Any], path: str) -> Any:
    current: Any = data
    for part in path.split("."):
        if isinstance(current, dict) and part in current:
            current = current[part]
            continue
        return None
    return current


def _resolve_target(target: str | None, artifact_root: Path, work_dir: Path) -> Path | None:
    if not target:
        return None
    candidate = Path(target)
    if candidate.is_absolute():
        return candidate
    if str(candidate).startswith("artifacts/"):
        return work_dir / candidate
    return artifact_root / candidate


def _fallback_observation(
    benchmark_id: str,
    case_id: str,
    candidate_id: str,
    trial_id: str,
    model: str,
    agent_surface: str,
    work_dir: Path,
) -> dict[str, Any]:
    return {
        "schema_version": "1.0",
        "benchmark_id": benchmark_id,
        "case_id": case_id,
        "candidate_id": candidate_id,
        "trial_id": trial_id,
        "model": model,
        "agent_surface": agent_surface,
        "tool_inventory": [],
        "invoked": False,
        "completed": False,
        "commands": [],
        "tool_calls": [],
        "files_written": [],
        "process_violations": ["command_failed"],
        "safety_violations": [],
        "timing": {"wall_clock_ms": 0, "step_count": 0},
        "cost": {"input_tokens": 0, "output_tokens": 0, "estimated_usd": 0},
        "artifact_root": str(work_dir / "artifacts"),
        "output_ref": None,
        "notes": "Synthesized fallback observation because candidate command did not produce one.",
    }


def validate_observation(
    observation: dict[str, Any],
    benchmark_id: str,
    case_id: str,
    candidate_id: str,
    trial_id: str,
    model: str,
    agent_surface: str,
) -> list[str]:
    issues: list[str] = []
    required = (
        "schema_version",
        "benchmark_id",
        "case_id",
        "candidate_id",
        "trial_id",
        "model",
        "agent_surface",
        "invoked",
        "completed",
        "commands",
        "tool_calls",
        "files_written",
        "timing",
        "cost",
    )
    for field in required:
        if field not in observation:
            issues.append(f"missing observation field: {field}")
    checks = {
        "benchmark_id": benchmark_id,
        "case_id": case_id,
        "candidate_id": candidate_id,
        "trial_id": trial_id,
        "model": model,
        "agent_surface": agent_surface,
    }
    for field, expected in checks.items():
        actual = observation.get(field)
        if actual != expected:
            issues.append(f"{field} mismatch: expected={expected!r}, actual={actual!r}")
    return issues


def validate_judge_output(judge_output: dict[str, Any]) -> list[str]:
    issues: list[str] = []
    for field in ("score", "verdict", "confidence", "dimension_scores", "issues"):
        if field not in judge_output:
            issues.append(f"missing judge field: {field}")
    score = judge_output.get("score")
    if score is not None and not isinstance(score, (int, float)):
        issues.append("judge score must be numeric")
    return issues


def evaluate_check(
    check: dict[str, Any],
    observation: dict[str, Any],
    artifact_root: Path,
    work_dir: Path,
    judge_output: dict[str, Any] | None,
) -> tuple[float, bool, str | None]:
    check_id = str(check.get("id", "unknown"))
    kind = str(check.get("kind", ""))
    target = check.get("target")
    value = check.get("value")
    required = bool(check.get("required", True))

    commands = [str(entry.get("command", "")) for entry in observation.get("commands", []) if isinstance(entry, dict)]
    tools = [str(entry.get("tool_name", "")) for entry in observation.get("tool_calls", []) if isinstance(entry, dict)]

    if kind == "judge_only":
        if judge_output is None:
            return (0.0, False, f"{check_id}: missing judge output")
        score = judge_output.get("score")
        if not isinstance(score, (int, float)):
            return (0.0, False, f"{check_id}: judge score missing or invalid")
        threshold = float(value) if isinstance(value, (int, float)) else 0.5
        passed = float(score) >= threshold
        issue = None if passed else f"{check_id}: judge score {score:.3f} below threshold {threshold:.3f}"
        return (max(0.0, min(1.0, float(score))), passed, issue)

    if kind == "file_exists":
        path = _resolve_target(str(target) if target is not None else None, artifact_root, work_dir)
        passed = bool(path and path.exists())
        issue = None if passed else f"{check_id}: missing file {target}"
        return (1.0 if passed else 0.0, passed, issue)

    if kind == "file_contains":
        path = _resolve_target(str(target) if target is not None else None, artifact_root, work_dir)
        if not path or not path.exists():
            return (0.0, False, f"{check_id}: file not found for contains check: {target}")
        contents = path.read_text(encoding="utf-8")
        needle = "" if value is None else str(value)
        passed = needle in contents
        issue = None if passed else f"{check_id}: file {target} missing expected content {needle!r}"
        return (1.0 if passed else 0.0, passed, issue)

    if kind == "file_not_contains":
        path = _resolve_target(str(target) if target is not None else None, artifact_root, work_dir)
        if not path or not path.exists():
            return (1.0, True, None)
        contents = path.read_text(encoding="utf-8")
        needle = "" if value is None else str(value)
        passed = needle not in contents
        issue = None if passed else f"{check_id}: file {target} unexpectedly contained {needle!r}"
        return (1.0 if passed else 0.0, passed, issue)

    if kind == "tool_called":
        expected = "" if target is None else str(target)
        passed = any(_pattern_matches(expected, tool) for tool in tools)
        issue = None if passed else f"{check_id}: expected tool not observed: {expected}"
        return (1.0 if passed else 0.0, passed, issue)

    if kind == "tool_not_called":
        forbidden = "" if target is None else str(target)
        passed = not any(_pattern_matches(forbidden, tool) for tool in tools)
        issue = None if passed else f"{check_id}: forbidden tool observed: {forbidden}"
        return (1.0 if passed else 0.0, passed, issue)

    if kind == "command_called":
        expected = "" if target is None else str(target)
        passed = any(_pattern_matches(expected, command) for command in commands)
        issue = None if passed else f"{check_id}: expected command not observed: {expected}"
        return (1.0 if passed else 0.0, passed, issue)

    if kind == "command_not_called":
        forbidden = "" if target is None else str(target)
        passed = not any(_pattern_matches(forbidden, command) for command in commands)
        issue = None if passed else f"{check_id}: forbidden command observed: {forbidden}"
        return (1.0 if passed else 0.0, passed, issue)

    if kind in {"json_field_equals", "state_assertion"}:
        path = "" if target is None else str(target)
        actual = _get_by_path(observation, path)
        if kind == "state_assertion" and value is None:
            passed = bool(actual)
            issue = None if passed else f"{check_id}: expected truthy field at {path!r}"
            return (1.0 if passed else 0.0, passed, issue)
        passed = actual == value
        issue = None if passed else f"{check_id}: expected {path}={value!r}, observed {actual!r}"
        return (1.0 if passed else 0.0, passed, issue)

    issue = f"{check_id}: unsupported check kind {kind}"
    return (0.0, not required, None if not required else issue)


def score_trial(
    case: dict[str, Any],
    observation: dict[str, Any],
    judge_output: dict[str, Any] | None,
    work_dir: Path,
) -> dict[str, Any]:
    artifact_root = Path(observation.get("artifact_root") or (work_dir / "artifacts"))
    total_weight = 0.0
    score_sum = 0.0
    issues: list[str] = []
    required_failures = 0
    check_results: list[dict[str, Any]] = []

    for check in case.get("observable_checks", []):
        weight = float(check.get("weight", 0.0))
        total_weight += weight
        contribution, passed, issue = evaluate_check(check, observation, artifact_root, work_dir, judge_output)
        score_sum += weight * contribution
        if issue:
            issues.append(issue)
        if not passed and bool(check.get("required", True)):
            required_failures += 1
        check_results.append(
            {
                "id": check.get("id"),
                "kind": check.get("kind"),
                "weight": weight,
                "passed": passed,
                "contribution": contribution,
                "issue": issue,
            }
        )

    score = (score_sum / total_weight) if total_weight > 0 else 0.0
    return {
        "score": score,
        "issues": issues,
        "required_failures": required_failures,
        "check_results": check_results,
    }


def run_candidate(
    repo_root: Path,
    benchmark_id: str,
    candidate_id: str,
    command: str,
    case: dict[str, Any],
    trial_index: int,
    model: str,
    agent_surface: str,
    work_root: Path,
) -> dict[str, Any]:
    case_id = str(case["case_id"])
    trial_id = f"trial-{trial_index:03d}"
    work_dir = work_root / case_id / trial_id / candidate_id
    case_file = work_dir / "case.json"
    observation_path = work_dir / "observation.json"
    judge_output_path = work_dir / "judge-output.json"
    log_path = work_dir / "command.log"
    work_dir.mkdir(parents=True, exist_ok=True)
    write_json(case_file, case)

    env = os.environ.copy()
    env.update(
        {
            "COGWORKS_BENCHMARK_ID": benchmark_id,
            "COGWORKS_BENCHMARK_CASE_ID": case_id,
            "COGWORKS_BENCHMARK_CASE_FILE": str(case_file),
            "COGWORKS_BENCHMARK_CANDIDATE_ID": candidate_id,
            "COGWORKS_BENCHMARK_TRIAL_ID": trial_id,
            "COGWORKS_BENCHMARK_WORK_DIR": str(work_dir),
            "COGWORKS_BENCHMARK_OBSERVATION_PATH": str(observation_path),
            "COGWORKS_BENCHMARK_JUDGE_OUTPUT_PATH": str(judge_output_path),
            "COGWORKS_BENCHMARK_MODEL": model,
            "COGWORKS_BENCHMARK_AGENT_SURFACE": agent_surface,
        }
    )

    result = subprocess.run(
        ["bash", "-lc", command],
        cwd=repo_root,
        env=env,
        text=True,
        capture_output=True,
        check=False,
    )
    log_path.write_text((result.stdout + result.stderr).strip() + "\n", encoding="utf-8")

    issues: list[str] = []
    if observation_path.exists():
        observation = load_json(observation_path)
    else:
        observation = _fallback_observation(
            benchmark_id=benchmark_id,
            case_id=case_id,
            candidate_id=candidate_id,
            trial_id=trial_id,
            model=model,
            agent_surface=agent_surface,
            work_dir=work_dir,
        )
        issues.append("candidate command did not produce observation.json")

    if result.returncode != 0:
        issues.append(f"candidate command failed with exit code {result.returncode}")

    issues.extend(
        validate_observation(
            observation=observation,
            benchmark_id=benchmark_id,
            case_id=case_id,
            candidate_id=candidate_id,
            trial_id=trial_id,
            model=model,
            agent_surface=agent_surface,
        )
    )

    judge_output = None
    if judge_output_path.exists():
        judge_output = load_json(judge_output_path)
        issues.extend(validate_judge_output(judge_output))

    scored = score_trial(case=case, observation=observation, judge_output=judge_output, work_dir=work_dir)
    issues.extend(observation.get("process_violations", []))

    return {
        "case_id": case_id,
        "candidate_id": candidate_id,
        "trial_id": trial_id,
        "command": command,
        "return_code": result.returncode,
        "log_path": str(log_path),
        "observation_path": str(observation_path),
        "judge_output_path": str(judge_output_path) if judge_output_path.exists() else None,
        "work_dir": str(work_dir),
        "observation": observation,
        "judge_output": judge_output,
        "score": scored["score"],
        "issues": issues + scored["issues"],
        "required_failures": scored["required_failures"],
        "check_results": scored["check_results"],
    }


def summarize_activation(observations: list[dict[str, Any]], expectations: dict[str, str]) -> dict[str, float]:
    tp = fp = fn = tn = ambiguous = 0
    for entry in observations:
        case_id = str(entry["case_id"])
        expected = expectations[case_id]
        invoked = bool(entry["observation"].get("invoked"))
        if expected == "must_activate":
            if invoked:
                tp += 1
            else:
                fn += 1
        elif expected == "must_not_activate":
            if invoked:
                fp += 1
            else:
                tn += 1
        else:
            ambiguous += 1

    precision = tp / (tp + fp) if (tp + fp) else 0.0
    recall = tp / (tp + fn) if (tp + fn) else 0.0
    false_positive_rate = fp / (fp + tn) if (fp + tn) else 0.0
    false_negative_rate = fn / (fn + tp) if (fn + tp) else 0.0
    total = tp + fp + fn + tn + ambiguous
    ambiguous_trigger_rate = ambiguous / total if total else 0.0
    return {
        "precision": precision,
        "recall": recall,
        "false_positive_rate": false_positive_rate,
        "false_negative_rate": false_negative_rate,
        "ambiguous_trigger_rate": ambiguous_trigger_rate,
    }


def write_report(path: Path, summary: dict[str, Any], results: dict[str, Any]) -> None:
    lines = [
        "# Skill Benchmark Report",
        "",
        f"Generated: {summary['generated_at']}",
        f"Benchmark ID: `{summary['benchmark_id']}`",
        f"Model: `{summary['model']}`",
        f"Agent surface: `{summary['agent_surface']}`",
        "",
        "## Decision",
        "",
        f"- Verdict: `{summary['verdict']}`",
        f"- Mean delta (`candidate_a - candidate_b`): `{summary['mean_delta']:.3f}`",
        f"- 95% bootstrap CI: `[{summary['confidence_interval_95'][0]:.3f}, {summary['confidence_interval_95'][1]:.3f}]`",
        f"- Candidate A win rate: `{summary['candidate_a_win_rate']:.3f}`",
        f"- Candidate B win rate: `{summary['candidate_b_win_rate']:.3f}`",
        f"- Tie rate: `{summary['tie_rate']:.3f}`",
        f"- Ranking eligible: `{summary['ranking_eligible']}`",
        "",
        "## Activation Diagnostics",
        "",
        f"- Candidate A precision/recall: `{summary['activation_metrics']['candidate_a']['precision']:.3f}` / `{summary['activation_metrics']['candidate_a']['recall']:.3f}`",
        f"- Candidate B precision/recall: `{summary['activation_metrics']['candidate_b']['precision']:.3f}` / `{summary['activation_metrics']['candidate_b']['recall']:.3f}`",
        f"- Candidate A false-positive rate: `{summary['activation_metrics']['candidate_a']['false_positive_rate']:.3f}`",
        f"- Candidate B false-positive rate: `{summary['activation_metrics']['candidate_b']['false_positive_rate']:.3f}`",
        "",
        "## Safety And Cost",
        "",
        f"- Candidate A safety violation rate: `{summary['safety_metrics']['candidate_a_violation_rate']:.3f}`",
        f"- Candidate B safety violation rate: `{summary['safety_metrics']['candidate_b_violation_rate']:.3f}`",
        f"- Candidate A mean runtime (ms): `{summary['cost_metrics']['candidate_a_mean_runtime_ms']:.1f}`",
        f"- Candidate B mean runtime (ms): `{summary['cost_metrics']['candidate_b_mean_runtime_ms']:.1f}`",
        "",
        "## Per-Case Deltas",
        "",
        "| Case | Category | A mean | B mean | Delta | Winner |",
        "|---|---|---:|---:|---:|---|",
    ]

    for case in results["cases"]:
        lines.append(
            f"| {case['case_id']} | {case['category']} | {case['candidate_a_mean_score']:.3f} | "
            f"{case['candidate_b_mean_score']:.3f} | {case['delta']:.3f} | {case['winner']} |"
        )

    if summary["limitations"]:
        lines.extend(["", "## Limitations", ""])
        for limitation in summary["limitations"]:
            lines.append(f"- {limitation}")

    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Run a paired skill benchmark.")
    parser.add_argument("--benchmark-id", default=None, help="Benchmark identifier.")
    parser.add_argument("--cases-file", required=True, help="JSON or JSONL file of benchmark cases.")
    parser.add_argument("--candidate-a", required=True, help="Candidate A label.")
    parser.add_argument("--candidate-a-command", required=True, help="Shell command used to run candidate A.")
    parser.add_argument("--candidate-b", required=True, help="Candidate B label.")
    parser.add_argument("--candidate-b-command", required=True, help="Shell command used to run candidate B.")
    parser.add_argument("--model", required=True, help="Fixed generator model identifier.")
    parser.add_argument("--agent-surface", required=True, help="Fixed agent surface identifier.")
    parser.add_argument("--trials", type=int, default=3, help="Trials per case per candidate.")
    parser.add_argument("--out-dir", default=None, help="Directory for benchmark artifacts.")
    parser.add_argument("--work-root", default="/tmp/cogworks-skill-benchmark", help="Scratch directory.")
    args = parser.parse_args()

    if args.trials < 1:
        raise SystemExit("--trials must be >= 1")

    repo_root = Path(__file__).resolve().parents[1]
    cases = load_cases(repo_root / args.cases_file if not Path(args.cases_file).is_absolute() else Path(args.cases_file))
    benchmark_id = args.benchmark_id or f"skill-benchmark-{timestamp_id()}"
    out_dir = Path(args.out_dir) if args.out_dir else repo_root / "tests" / "results" / "skill-benchmark" / benchmark_id
    out_dir.mkdir(parents=True, exist_ok=True)
    work_root = Path(args.work_root) / benchmark_id
    work_root.mkdir(parents=True, exist_ok=True)

    trial_runs: list[dict[str, Any]] = []
    expectations = {str(case["case_id"]): str(case["expected_activation"]) for case in cases}

    for case in cases:
        for trial_index in range(1, args.trials + 1):
            trial_runs.append(
                run_candidate(
                    repo_root=repo_root,
                    benchmark_id=benchmark_id,
                    candidate_id=args.candidate_a,
                    command=args.candidate_a_command,
                    case=case,
                    trial_index=trial_index,
                    model=args.model,
                    agent_surface=args.agent_surface,
                    work_root=work_root,
                )
            )
            trial_runs.append(
                run_candidate(
                    repo_root=repo_root,
                    benchmark_id=benchmark_id,
                    candidate_id=args.candidate_b,
                    command=args.candidate_b_command,
                    case=case,
                    trial_index=trial_index,
                    model=args.model,
                    agent_surface=args.agent_surface,
                    work_root=work_root,
                )
            )

    by_case_candidate: dict[tuple[str, str], list[dict[str, Any]]] = {}
    for run in trial_runs:
        key = (str(run["case_id"]), str(run["candidate_id"]))
        by_case_candidate.setdefault(key, []).append(run)

    case_summaries: list[dict[str, Any]] = []
    case_deltas: list[float] = []
    candidate_a_wins = candidate_b_wins = ties = 0

    for case in cases:
        case_id = str(case["case_id"])
        a_runs = by_case_candidate[(case_id, args.candidate_a)]
        b_runs = by_case_candidate[(case_id, args.candidate_b)]
        a_mean = mean([run["score"] for run in a_runs])
        b_mean = mean([run["score"] for run in b_runs])
        delta = a_mean - b_mean
        if delta > 0:
            winner = "candidate_a"
            candidate_a_wins += 1
        elif delta < 0:
            winner = "candidate_b"
            candidate_b_wins += 1
        else:
            winner = "tie"
            ties += 1
        case_deltas.append(delta)
        case_summaries.append(
            {
                "case_id": case_id,
                "category": case["category"],
                "candidate_a_mean_score": a_mean,
                "candidate_b_mean_score": b_mean,
                "delta": delta,
                "winner": winner,
            }
        )

    ci_lower, ci_upper = bootstrap_ci(case_deltas)
    mean_delta = mean(case_deltas)
    case_count = len(cases)
    candidate_a_activation = summarize_activation(
        [run for run in trial_runs if run["candidate_id"] == args.candidate_a],
        expectations,
    )
    candidate_b_activation = summarize_activation(
        [run for run in trial_runs if run["candidate_id"] == args.candidate_b],
        expectations,
    )

    def violation_rate(candidate_id: str) -> float:
        relevant = [run for run in trial_runs if run["candidate_id"] == candidate_id]
        violations = sum(1 for run in relevant if run["observation"].get("safety_violations"))
        return violations / len(relevant) if relevant else 0.0

    def mean_runtime(candidate_id: str) -> float:
        relevant = [run for run in trial_runs if run["candidate_id"] == candidate_id]
        return mean([float(run["observation"]["timing"].get("wall_clock_ms", 0)) for run in relevant])

    def mean_cost(candidate_id: str) -> float | None:
        relevant = [run for run in trial_runs if run["candidate_id"] == candidate_id]
        values = [
            run["observation"]["cost"].get("estimated_usd")
            for run in relevant
            if run["observation"]["cost"].get("estimated_usd") is not None
        ]
        return mean([float(value) for value in values]) if values else None

    candidate_a_violation_rate = violation_rate(args.candidate_a)
    candidate_b_violation_rate = violation_rate(args.candidate_b)
    ranking_eligible = case_count >= 10 and args.trials >= 5

    if not ranking_eligible:
        verdict = "insufficient_evidence"
    elif ci_lower <= 0 <= ci_upper:
        verdict = "no_clear_winner"
    elif mean_delta > 0 and candidate_a_violation_rate <= candidate_b_violation_rate:
        verdict = "candidate_a"
    elif mean_delta < 0 and candidate_b_violation_rate <= candidate_a_violation_rate:
        verdict = "candidate_b"
    else:
        verdict = "no_clear_winner"

    efficacy_breakdown: dict[str, float] = {}
    for category in ("invoked-task", "hard-negative", "boundary"):
        category_deltas = [entry["delta"] for entry in case_summaries if entry["category"] == category]
        if category_deltas:
            efficacy_breakdown[category] = mean(category_deltas)

    limitations = []
    if not ranking_eligible:
        limitations.append("Ranking ineligible by default policy: requires at least 10 cases and 5 trials per case.")
    if ci_lower <= 0 <= ci_upper:
        limitations.append("Confidence interval overlaps zero; paired result is not decision-grade.")

    summary = {
        "schema_version": "1.0",
        "generated_at": iso_now(),
        "benchmark_id": benchmark_id,
        "skills_compared": {
            "candidate_a": args.candidate_a,
            "candidate_b": args.candidate_b,
        },
        "model": args.model,
        "agent_surface": args.agent_surface,
        "trial_count": args.trials,
        "case_count": case_count,
        "mean_delta": mean_delta,
        "win_rate": max(candidate_a_wins, candidate_b_wins) / case_count if case_count else 0.0,
        "candidate_a_win_rate": candidate_a_wins / case_count if case_count else 0.0,
        "candidate_b_win_rate": candidate_b_wins / case_count if case_count else 0.0,
        "tie_rate": ties / case_count if case_count else 0.0,
        "confidence_interval_95": [ci_lower, ci_upper],
        "efficacy_breakdown": efficacy_breakdown,
        "activation_metrics": {
            "candidate_a": candidate_a_activation,
            "candidate_b": candidate_b_activation,
        },
        "safety_metrics": {
            "candidate_a_violation_rate": candidate_a_violation_rate,
            "candidate_b_violation_rate": candidate_b_violation_rate,
            "regression": candidate_a_violation_rate > candidate_b_violation_rate,
        },
        "cost_metrics": {
            "candidate_a_mean_runtime_ms": mean_runtime(args.candidate_a),
            "candidate_b_mean_runtime_ms": mean_runtime(args.candidate_b),
            "candidate_a_mean_estimated_usd": mean_cost(args.candidate_a),
            "candidate_b_mean_estimated_usd": mean_cost(args.candidate_b),
        },
        "verdict": verdict,
        "ranking_eligible": ranking_eligible,
        "limitations": limitations,
    }

    results = {
        "benchmark_id": benchmark_id,
        "generated_at": iso_now(),
        "cases": case_summaries,
        "trial_runs": trial_runs,
    }

    summary_path = out_dir / "benchmark-summary.json"
    report_path = out_dir / "benchmark-report.md"
    results_path = out_dir / "benchmark-results.json"
    write_json(summary_path, summary)
    write_json(results_path, results)
    write_report(report_path, summary, results)

    print(f"Wrote {summary_path}")
    print(f"Wrote {report_path}")
    print(f"Wrote {results_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
