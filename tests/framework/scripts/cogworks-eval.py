#!/usr/bin/env python3
import argparse
import json
import os
import sys
from datetime import UTC, datetime
from typing import Any, Dict, List, Optional

from behavioral_lib import load_json, load_jsonl, validate_case, compute_f1
from pipeline_benchmark import run_benchmark, scaffold_layout, summarize_benchmark


def _write_json(path: str, payload: Dict[str, Any]) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2)


def _write_text(path: str, content: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)


def _format_md_report(skill: str, summary: Dict[str, Any], case_results: List[Dict[str, Any]]) -> str:
    lines = []
    lines.append(f"# Behavioral Test Report: {skill}\n")
    lines.append(f"Status: {summary['status']}")
    lines.append(f"Cases: {summary['cases_total']}")
    lines.append("\n## Activation Metrics")
    lines.append(f"- Activation F1: {summary['activation_f1']:.3f}")
    lines.append(f"- False Positive Rate: {summary['false_positive_rate']:.3f}")
    lines.append(f"- Negative Control Ratio: {summary['negative_control_ratio']:.3f}\n")

    if summary["failures"]:
        lines.append("## Failures")
        for failure in summary["failures"]:
            lines.append(f"- {failure}")
        lines.append("")

    lines.append("## Case Results")
    for case in case_results:
        status = "PASS" if case["pass"] else "FAIL"
        lines.append(f"- {case['case_id']}: {status}")
        for issue in case["issues"]:
            lines.append(f"  {issue}")

    return "\n".join(lines) + "\n"


def _collect_skills(skills_root: str, prefixes: List[str]) -> List[str]:
    if not os.path.isdir(skills_root):
        return []

    skills = []
    for name in os.listdir(skills_root):
        path = os.path.join(skills_root, name)
        if not os.path.isdir(path):
            continue
        if not os.path.exists(os.path.join(path, "SKILL.md")):
            continue
        if prefixes and not any(name.startswith(prefix) for prefix in prefixes):
            continue
        skills.append(name)
    return sorted(skills)


def _infer_pipeline_from_skills_root(skills_root: str) -> Optional[str]:
    normalized = os.path.normpath(skills_root)
    if normalized.endswith(os.path.normpath(".claude/skills")):
        return "claude"
    if normalized.endswith(os.path.normpath(".agents/skills")):
        return "codex"
    return None


def _parse_timestamp(value: str) -> bool:
    if not isinstance(value, str) or not value.strip():
        return False
    text = value.strip()
    if text.endswith("Z"):
        text = text[:-1] + "+00:00"
    try:
        datetime.fromisoformat(text)
    except ValueError:
        return False
    return True


def _validate_trace_provenance(
    trace: Dict[str, Any], strict: bool, expected_pipeline: Optional[str] = None
) -> List[str]:
    issues: List[str] = []
    pipeline = str(trace.get("pipeline", "")).strip().lower()
    harness = str(trace.get("harness", "")).strip().lower()
    model = str(trace.get("model", "")).strip().lower()
    trace_source = str(trace.get("trace_source", "")).strip().lower()
    captured_at = trace.get("captured_at")
    placeholder_values = {"", "n/a", "na", "manual", "placeholder", "unknown"}

    if strict:
        for field in ("pipeline", "harness", "model", "trace_source", "captured_at", "activation_source"):
            value = trace.get(field)
            if value is None or (isinstance(value, str) and not value.strip()):
                issues.append(f"missing required provenance field: {field}")

    if expected_pipeline and pipeline and pipeline not in {expected_pipeline, "shared"}:
        issues.append(f"pipeline mismatch (expected={expected_pipeline}, trace={pipeline})")

    if strict:
        if pipeline and pipeline not in {"claude", "codex", "shared"}:
            issues.append(f"invalid pipeline value: {pipeline}")
        if harness in placeholder_values:
            issues.append(f"placeholder harness not allowed in strict mode: {trace.get('harness')}")
        if model in placeholder_values:
            issues.append(f"placeholder model not allowed in strict mode: {trace.get('model')}")
        if trace_source != "captured":
            issues.append(
                f"trace_source must be 'captured' in strict mode (got: {trace.get('trace_source')})"
            )
        if not _parse_timestamp(str(captured_at) if captured_at is not None else ""):
            issues.append(f"invalid captured_at timestamp: {captured_at}")

    return issues


def behavioral_run(args: argparse.Namespace) -> int:
    timestamp = args.timestamp or datetime.now(UTC).strftime("%Y%m%dT%H%M%SZ")
    results_dir = os.path.join(args.results_root, timestamp)
    os.makedirs(results_dir, exist_ok=True)

    overall = {
        "timestamp": timestamp,
        "skills": [],
        "status": "PASS",
        "failures": [],
    }

    collected_skills = _collect_skills(args.skills_root, args.skill_prefix)
    requested_skills = set(args.skill or [])
    expected_pipeline = _infer_pipeline_from_skills_root(args.skills_root)

    if requested_skills:
        selected = [skill for skill in collected_skills if skill in requested_skills]
        missing = sorted(requested_skills - set(selected))
        if missing:
            overall["status"] = "FAIL"
            overall["failures"].append(
                f"requested skills not found under {args.skills_root}: {', '.join(missing)}"
            )
    else:
        selected = collected_skills

    for skill in selected:
        test_cases_path = os.path.join(args.tests_root, skill, "test-cases.jsonl")
        traces_dir = os.path.join(args.tests_root, skill, "traces")

        skill_summary = {
            "skill": skill,
            "status": "PASS",
            "cases_total": 0,
            "activation_f1": 0.0,
            "false_positive_rate": 0.0,
            "negative_control_ratio": 0.0,
            "failures": [],
        }

        case_results: List[Dict[str, Any]] = []
        if not os.path.exists(test_cases_path):
            msg = f"missing test cases: {test_cases_path}"
            if args.allow_missing_tests:
                skill_summary["failures"].append(f"WARN: {msg}")
            else:
                skill_summary["status"] = "FAIL"
                skill_summary["failures"].append(msg)
            overall["skills"].append(skill_summary)
            if skill_summary["status"] == "FAIL":
                overall["status"] = "FAIL"
                overall["failures"].append(f"{skill}: {msg}")
            continue

        cases = load_jsonl(test_cases_path)
        if not cases:
            msg = "no test cases found"
            skill_summary["status"] = "FAIL"
            skill_summary["failures"].append(msg)
            overall["status"] = "FAIL"
            overall["failures"].append(f"{skill}: {msg}")
            overall["skills"].append(skill_summary)
            continue

        ids = [case.get("id") for case in cases]
        if len(ids) != len(set(ids)):
            skill_summary["status"] = "FAIL"
            skill_summary["failures"].append("duplicate case ids")

        tp = fp = fn = tn = 0
        negative_controls = 0

        for case in cases:
            case_id = case.get("id")
            skill_summary["cases_total"] += 1

            if case.get("category") == "negative_control":
                negative_controls += 1

            trace_path = os.path.join(traces_dir, f"{case_id}.json")
            if not os.path.exists(trace_path):
                msg = f"missing trace: {trace_path}"
                case_results.append({"case_id": case_id, "pass": False, "issues": [msg]})
                skill_summary["status"] = "FAIL"
                skill_summary["failures"].append(msg)
                continue

            trace = load_json(trace_path)
            result = validate_case(case, trace)
            provenance_issues = _validate_trace_provenance(
                trace, strict=args.strict_provenance, expected_pipeline=expected_pipeline
            )
            if args.strict_provenance and bool(case.get("should_activate")):
                evidence_mode = str(case.get("activation_evidence", "allow_fallback")).strip().lower()
                activation_source = str(trace.get("activation_source", "none")).strip().lower()
                if evidence_mode == "tool_call_only" and activation_source != "skill_tool":
                    provenance_issues.append(
                        "strict-provenance requires activation_source=skill_tool "
                        f"(got: {trace.get('activation_source')})"
                    )
            if provenance_issues:
                result["issues"].extend(provenance_issues)
                result["pass"] = False
            case_results.append(result)

            should_activate = bool(case.get("should_activate"))
            activated = bool(trace.get("activated"))
            if should_activate and activated:
                tp += 1
            elif should_activate and not activated:
                fn += 1
            elif not should_activate and activated:
                fp += 1
            else:
                tn += 1

            if not result["pass"]:
                skill_summary["status"] = "FAIL"

        f1 = compute_f1(tp, fp, fn)
        fpr = fp / (fp + tn) if (fp + tn) > 0 else 0.0
        neg_ratio = negative_controls / len(cases)

        skill_summary["activation_f1"] = f1
        skill_summary["false_positive_rate"] = fpr
        skill_summary["negative_control_ratio"] = neg_ratio

        if f1 < 0.85:
            skill_summary["status"] = "FAIL"
            skill_summary["failures"].append(f"activation_f1 < 0.85 ({f1:.3f})")
        if fpr > 0.05:
            skill_summary["status"] = "FAIL"
            skill_summary["failures"].append(f"false_positive_rate > 0.05 ({fpr:.3f})")
        if neg_ratio < 0.25:
            skill_summary["status"] = "FAIL"
            skill_summary["failures"].append("negative control ratio < 0.25")

        overall["skills"].append(skill_summary)
        if skill_summary["status"] == "FAIL":
            overall["status"] = "FAIL"
            overall["failures"].append(f"{skill}: behavioral gate failed")

        json_path = os.path.join(results_dir, f"{skill}-behavioral.json")
        md_path = os.path.join(results_dir, f"{skill}-behavioral.md")
        _write_json(json_path, {"summary": skill_summary, "cases": case_results})
        _write_text(md_path, _format_md_report(skill, skill_summary, case_results))

    _write_json(os.path.join(results_dir, "summary.json"), overall)
    _write_text(os.path.join(results_dir, "summary.md"), json.dumps(overall, indent=2) + "\n")
    return 0 if overall["status"] == "PASS" else 1


def behavioral_validate(args: argparse.Namespace) -> int:
    cases = load_jsonl(args.test_cases)
    case = next((entry for entry in cases if entry.get("id") == args.case_id), None)
    if case is None:
        print(f"Case id not found: {args.case_id}", file=sys.stderr)
        return 2

    trace = load_json(args.trace)
    result = validate_case(case, trace)
    provenance_issues = _validate_trace_provenance(
        trace, strict=args.strict_provenance, expected_pipeline=args.expected_pipeline
    )
    if provenance_issues:
        result["issues"].extend(provenance_issues)
        result["pass"] = False
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        status = "PASS" if result["pass"] else "FAIL"
        print(f"Case {result['case_id']}: {status}")
        for issue in result["issues"]:
            print(f"- {issue}")
    return 0 if result["pass"] else 1


def behavioral_scaffold(args: argparse.Namespace) -> int:
    def default_cases(slug: str) -> List[Dict[str, Any]]:
        return [
            {
                "id": f"{slug}-exp-001",
                "category": "explicit",
                "user_request": f"Use /{slug} to help with this task.",
                "should_activate": True,
                "expected_tools": [],
                "expected_commands": [],
                "forbidden_commands": [],
                "expected_files_modified": [],
                "expected_files_created": [],
                "notes": "Explicit invocation should activate",
            },
            {
                "id": f"{slug}-neg-001",
                "category": "negative_control",
                "user_request": "Summarize this document.",
                "should_activate": False,
                "expected_tools": [],
                "expected_commands": [],
                "forbidden_commands": [],
                "expected_files_modified": [],
                "expected_files_created": [],
                "notes": "Unrelated request should not activate",
            },
        ]

    def write_jsonl(path: str, cases: List[Dict[str, Any]]) -> None:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            for case in cases:
                f.write(json.dumps(case) + "\n")

    skills = args.skill or _collect_skills(args.skills_root, args.skill_prefix)
    for slug in skills:
        cases_path = os.path.join(args.tests_root, slug, "test-cases.jsonl")
        if os.path.exists(cases_path) and not args.force:
            print(f"Skip (exists): {cases_path}")
            continue
        write_jsonl(cases_path, default_cases(slug))
        print(f"Wrote: {cases_path}")

    return 0


def pipeline_benchmark_scaffold(args: argparse.Namespace) -> int:
    return scaffold_layout(args)


def pipeline_benchmark_run(args: argparse.Namespace) -> int:
    return run_benchmark(args)


def pipeline_benchmark_summarize(args: argparse.Namespace) -> int:
    return summarize_benchmark(args)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Cogworks evaluation CLI")
    sub = parser.add_subparsers(dest="command", required=True)

    behavioral = sub.add_parser("behavioral", help="Behavioral tests")
    behavioral_sub = behavioral.add_subparsers(dest="subcommand", required=True)

    run = behavioral_sub.add_parser("run", help="Run behavioral tests")
    run.add_argument("--skills-root", default=".claude/skills")
    run.add_argument("--tests-root", default="tests/behavioral")
    run.add_argument("--results-root", default="tests/results/behavioral")
    run.add_argument("--timestamp", default=None)
    run.add_argument("--skill", action="append", default=[], help="Specific skill slug (repeatable)")
    run.add_argument("--skill-prefix", action="append", default=[], help="Only include skills with this prefix (repeatable)")
    run.add_argument("--allow-missing-tests", action="store_true")
    run.add_argument("--strict-provenance", action="store_true")
    run.set_defaults(func=behavioral_run)

    validate = behavioral_sub.add_parser("validate", help="Validate a single trace")
    validate.add_argument("--test-cases", required=True)
    validate.add_argument("--case-id", required=True)
    validate.add_argument("--trace", required=True)
    validate.add_argument("--json", action="store_true")
    validate.add_argument("--strict-provenance", action="store_true")
    validate.add_argument("--expected-pipeline", choices=["claude", "codex"], default=None)
    validate.set_defaults(func=behavioral_validate)

    scaffold = behavioral_sub.add_parser("scaffold", help="Scaffold behavioral test cases")
    scaffold.add_argument("--skills-root", default=".claude/skills")
    scaffold.add_argument("--tests-root", default="tests/behavioral")
    scaffold.add_argument("--skill", action="append", default=[], help="Specific skill slug (repeatable)")
    scaffold.add_argument("--skill-prefix", action="append", default=[], help="Only include skills with this prefix (repeatable)")
    scaffold.add_argument("--force", action="store_true")
    scaffold.set_defaults(func=behavioral_scaffold)

    pipeline = sub.add_parser("pipeline-benchmark", help="Cross-pipeline benchmark")
    pipeline_sub = pipeline.add_subparsers(dest="subcommand", required=True)

    pb_scaffold = pipeline_sub.add_parser("scaffold", help="Scaffold benchmark layout")
    pb_scaffold.add_argument("--manifest", default="tests/datasets/pipeline-benchmark/manifest.jsonl")
    pb_scaffold.add_argument("--results-root", default="tests/results/pipeline-benchmark")
    pb_scaffold.add_argument("--run-id", required=True)
    pb_scaffold.add_argument("--repeats", type=int, default=1)
    pb_scaffold.add_argument("--variant", action="append", default=[])
    pb_scaffold.add_argument("--force", action="store_true")
    pb_scaffold.add_argument("--pipeline", action="append", default=[])
    pb_scaffold.set_defaults(func=pipeline_benchmark_scaffold)

    pb_run = pipeline_sub.add_parser("run", help="Run benchmark commands")
    pb_run.add_argument("--manifest", default="tests/datasets/pipeline-benchmark/manifest.jsonl")
    pb_run.add_argument("--results-root", default="tests/results/pipeline-benchmark")
    pb_run.add_argument("--run-id", required=True)
    pb_run.add_argument("--repeats", type=int, default=1)
    pb_run.add_argument("--variant", action="append", default=[])
    pb_run.add_argument("--pipeline", action="append", default=[])
    pb_run.add_argument("--command-template", action="append", default=[])
    pb_run.add_argument("--cwd", default=None)
    pb_run.add_argument("--dry-run", action="store_true")
    pb_run.add_argument("--force", action="store_true")
    pb_run.set_defaults(func=pipeline_benchmark_run)

    pb_summary = pipeline_sub.add_parser("summarize", help="Summarize benchmark")
    pb_summary.add_argument("--manifest", default="tests/datasets/pipeline-benchmark/manifest.jsonl")
    pb_summary.add_argument("--results-root", default="tests/results/pipeline-benchmark")
    pb_summary.add_argument("--run-id", required=True)
    pb_summary.add_argument("--pipeline", action="append", default=[])
    pb_summary.add_argument("--output-json", default=None)
    pb_summary.add_argument("--output-md", default=None)
    pb_summary.set_defaults(func=pipeline_benchmark_summarize)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    if args.command == "pipeline-benchmark":
        if not args.pipeline:
            args.pipeline = ["claude", "codex"]
        if hasattr(args, "variant") and not args.variant:
            args.variant = ["clean"]
        if getattr(args, "output_json", None) is None:
            args.output_json = f"{args.results_root}/{args.run_id}/benchmark-summary.json"
        if getattr(args, "output_md", None) is None:
            args.output_md = f"{args.results_root}/{args.run_id}/benchmark-report.md"

    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
