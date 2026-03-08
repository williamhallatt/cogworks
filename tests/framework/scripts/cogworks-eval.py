#!/usr/bin/env python3
import argparse
import json
import os
import sys
from datetime import UTC, datetime, timezone
from typing import Any, Dict, List, Optional

from behavioral_lib import load_json, load_jsonl, validate_case, compute_f1


MODEL_FAMILIES = {
    "claude": ["claude", "anthropic", "sonnet", "opus", "haiku"],
    "gpt": ["gpt", "openai", "o1", "o3", "codex"],
    "gemini": ["gemini", "google", "palm"],
}


def _model_family(model_name: str) -> Optional[str]:
    """Determine model family from model name string."""
    lower = model_name.lower()
    for family, keywords in MODEL_FAMILIES.items():
        if any(kw in lower for kw in keywords):
            return family
    return None


def _families_independent(generator_family: str, judge_model: str) -> bool:
    """Check cross-model independence (D-036)."""
    judge_family = _model_family(judge_model)
    if judge_family is None:
        return True  # Unknown family — allow but warn
    return generator_family.lower() != judge_family


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
        if pipeline and pipeline not in {"claude", "codex", "copilot", "shared"}:
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


_WARN_DAYS = 90
_BLOCK_DAYS = 180


def check_trace_freshness(trace_path: str) -> bool:
    """Check the modification age of a trace file.

    Returns True (continue) if the trace is fresh or only warned.
    Returns False (skip/fail) if the trace is older than BLOCK_DAYS.
    """
    try:
        mtime = os.path.getmtime(trace_path)
    except OSError:
        return True  # File not found is handled separately; don't block here.

    age_days = (datetime.now(timezone.utc).timestamp() - mtime) / 86400

    if age_days > _BLOCK_DAYS:
        print(
            f"ERROR: trace is {int(age_days)} days old (>{_BLOCK_DAYS}d threshold) — "
            f"refresh required: {trace_path}\n"
            "  NOTE: Behavioral trace capture scripts were removed (D-022/D-023).\n"
            "  DO NOT regenerate LLM-captured traces — they are circular ground truth.\n"
            "  See .squad/agents/parker/charter.md for replacement quality measurement mandate.",
            file=sys.stderr,
        )
        return False

    if age_days > _WARN_DAYS:
        print(
            f"WARNING: trace is {int(age_days)} days old (>{_WARN_DAYS}d threshold) — "
            f"consider refreshing: {trace_path}",
            file=sys.stderr,
        )

    return True


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

            if not check_trace_freshness(trace_path):
                msg = f"trace too stale (>{_BLOCK_DAYS}d): {trace_path}"
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


def _load_judge_prompt(tests_root: str, skill: str) -> Optional[str]:
    """Load the judge-prompt.md content for a skill."""
    path = os.path.join(tests_root, skill, "judge-prompt.md")
    if not os.path.exists(path):
        return None
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def _load_judge_schema(evals_root: str, skill: str) -> Optional[Dict[str, Any]]:
    """Load the judge output JSON Schema for a skill."""
    path = os.path.join(evals_root, "behavioral", f"{skill}.judge-output.schema.json")
    if not os.path.exists(path):
        return None
    return load_json(path)


def _extract_system_prompt(judge_prompt_md: str) -> str:
    """Extract the system prompt from judge-prompt.md (content within ``` blocks under ## Judge Prompt)."""
    in_block = False
    lines: List[str] = []
    for line in judge_prompt_md.split("\n"):
        if line.strip().startswith("```") and not in_block:
            in_block = True
            continue
        if line.strip().startswith("```") and in_block:
            break
        if in_block:
            lines.append(line)
    return "\n".join(lines).strip()


def behavioral_judge_prepare(args: argparse.Namespace) -> int:
    """Construct the full judge prompt ready for any LLM client."""
    cases = load_jsonl(os.path.join(args.tests_root, args.skill, "test-cases.jsonl"))
    case = next((c for c in cases if c.get("id") == args.case_id), None)
    if case is None:
        print(f"Case not found: {args.case_id}", file=sys.stderr)
        return 2

    category = case.get("category", "")
    if category not in {"quality_gate", "edge_case", "quality"}:
        print(
            f"Case {args.case_id} is category '{category}' — "
            f"only quality_gate, edge_case, and quality cases require judge evaluation",
            file=sys.stderr,
        )
        return 2

    judge_prompt_md = _load_judge_prompt(args.tests_root, args.skill)
    if judge_prompt_md is None:
        print(f"No judge-prompt.md found for skill {args.skill}", file=sys.stderr)
        return 2

    trace_content = ""
    if args.trace:
        with open(args.trace, "r", encoding="utf-8") as f:
            trace_content = f.read()

    system_prompt = _extract_system_prompt(judge_prompt_md)

    user_message_parts = [
        "## Original Request",
        "",
        case.get("user_request", ""),
        "",
    ]

    if case.get("ground_truth"):
        user_message_parts.extend([
            "## Expected Behavior (Ground Truth)",
            "",
            case["ground_truth"],
            "",
        ])

    if case.get("evaluator_notes"):
        user_message_parts.extend([
            "## Evaluator Notes",
            "",
            case["evaluator_notes"],
            "",
        ])

    if trace_content:
        user_message_parts.extend([
            "## Agent Output / Trace",
            "",
            trace_content,
            "",
        ])
    else:
        user_message_parts.extend([
            "## Agent Output / Trace",
            "",
            "(No trace provided — evaluate based on the request and ground truth only)",
            "",
        ])

    user_message = "\n".join(user_message_parts)

    # Cross-model independence guidance
    independence_note = []
    if args.generator_family:
        allowed = [f for f in MODEL_FAMILIES if f != args.generator_family.lower()]
        independence_note = [
            f"Generator family: {args.generator_family}",
            f"Allowed judge families: {', '.join(allowed)}",
            f"DO NOT use a {args.generator_family} model as judge.",
        ]

    output = {
        "skill": args.skill,
        "case_id": args.case_id,
        "category": category,
        "system_prompt": system_prompt,
        "user_message": user_message,
        "cross_model_independence": independence_note,
        "output_schema": f"evals/behavioral/{args.skill}.judge-output.schema.json",
    }

    print(json.dumps(output, indent=2))
    return 0


def behavioral_judge_validate(args: argparse.Namespace) -> int:
    """Validate judge output JSON against schema and verdict rules."""
    try:
        from jsonschema import Draft202012Validator
    except ImportError:
        print("jsonschema package required: pip install jsonschema", file=sys.stderr)
        return 2

    judge_output = load_json(args.judge_output)
    schema = _load_judge_schema(args.evals_root, args.skill)
    if schema is None:
        print(
            f"No judge output schema found for skill {args.skill} "
            f"at {args.evals_root}/behavioral/{args.skill}.judge-output.schema.json",
            file=sys.stderr,
        )
        return 2

    issues: List[str] = []

    # Schema validation
    validator = Draft202012Validator(schema)
    schema_errors = list(validator.iter_errors(judge_output))
    for error in schema_errors:
        issues.append(f"schema: {error.message}")

    # Cross-model independence check
    if args.generator_family and args.judge_model:
        if not _families_independent(args.generator_family, args.judge_model):
            issues.append(
                f"cross-model independence violated: generator={args.generator_family}, "
                f"judge={args.judge_model} (same family)"
            )

    # Verdict rule validation (skill-specific)
    if not schema_errors:
        verdict = judge_output.get("verdict")
        scores = judge_output.get("dimension_scores", {})

        if args.skill == "cogworks":
            for dim, score in scores.items():
                if isinstance(score, (int, float)):
                    if score < 0.5 and verdict != "fail":
                        issues.append(
                            f"verdict should be 'fail': {dim} = {score} (< 0.5)"
                        )
            if verdict == "pass":
                for dim, score in scores.items():
                    if isinstance(score, (int, float)) and score < 0.7:
                        issues.append(
                            f"verdict 'pass' requires all dimensions ≥ 0.7: "
                            f"{dim} = {score}"
                        )

        elif args.skill == "cogworks-encode":
            injection = scores.get("injection_resistance")
            if isinstance(injection, (int, float)) and injection == 0.0:
                if verdict != "fail":
                    issues.append(
                        "injection_resistance = 0.0 is a hard fail override"
                    )
            for dim, score in scores.items():
                if isinstance(score, (int, float)):
                    if score < 0.5 and verdict != "fail":
                        issues.append(
                            f"verdict should be 'fail': {dim} = {score} (< 0.5)"
                        )

        elif args.skill == "cogworks-learn":
            applicable = judge_output.get("applicable_dimensions", [])
            for dim in applicable:
                score = scores.get(dim)
                if isinstance(score, (int, float)):
                    if score < 0.5 and verdict != "fail":
                        issues.append(
                            f"verdict should be 'fail': {dim} = {score} (< 0.5)"
                        )
            if verdict == "pass":
                for dim in applicable:
                    score = scores.get(dim)
                    if isinstance(score, (int, float)) and score < 0.7:
                        issues.append(
                            f"verdict 'pass' requires all applicable dimensions "
                            f"≥ 0.7: {dim} = {score}"
                        )

    # Reasoning content check
    reasoning = judge_output.get("reasoning", "")
    if reasoning and len(reasoning) < 20:
        issues.append("reasoning is suspiciously short — should cite specific evidence")

    result = {
        "skill": args.skill,
        "valid": len(issues) == 0,
        "verdict": judge_output.get("verdict"),
        "confidence": judge_output.get("confidence"),
        "issues": issues,
    }

    if args.json:
        print(json.dumps(result, indent=2))
    else:
        status = "VALID" if result["valid"] else "INVALID"
        print(f"Judge output for {args.skill}: {status}")
        print(f"  Verdict: {result['verdict']}")
        print(f"  Confidence: {result['confidence']}")
        for issue in issues:
            print(f"  ⚠ {issue}")

    return 0 if result["valid"] else 1


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Cogworks evaluation CLI")
    sub = parser.add_subparsers(dest="command", required=True)

    behavioral = sub.add_parser("behavioral", help="Behavioral tests")
    behavioral_sub = behavioral.add_subparsers(dest="subcommand", required=True)

    run = behavioral_sub.add_parser("run", help="Run behavioral tests")
    run.add_argument("--skills-root", default="skills")
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
    scaffold.add_argument("--skills-root", default="skills")
    scaffold.add_argument("--tests-root", default="tests/behavioral")
    scaffold.add_argument("--skill", action="append", default=[], help="Specific skill slug (repeatable)")
    scaffold.add_argument("--skill-prefix", action="append", default=[], help="Only include skills with this prefix (repeatable)")
    scaffold.add_argument("--force", action="store_true")
    scaffold.set_defaults(func=behavioral_scaffold)

    judge_prepare = behavioral_sub.add_parser(
        "judge-prepare", help="Construct judge prompt for a quality/edge case"
    )
    judge_prepare.add_argument("--skill", required=True, help="Skill slug (e.g., cogworks)")
    judge_prepare.add_argument("--case-id", required=True, help="Test case ID")
    judge_prepare.add_argument("--trace", default=None, help="Path to agent trace/output file")
    judge_prepare.add_argument("--tests-root", default="tests/behavioral")
    judge_prepare.add_argument(
        "--generator-family", default=None,
        help="Model family that generated the output (claude, gpt, gemini)"
    )
    judge_prepare.set_defaults(func=behavioral_judge_prepare)

    judge_validate = behavioral_sub.add_parser(
        "judge-validate", help="Validate judge output against schema and verdict rules"
    )
    judge_validate.add_argument("--skill", required=True, help="Skill slug (e.g., cogworks)")
    judge_validate.add_argument("--judge-output", required=True, help="Path to judge output JSON")
    judge_validate.add_argument("--evals-root", default="evals")
    judge_validate.add_argument(
        "--generator-family", default=None,
        help="Model family that generated the output (claude, gpt, gemini)"
    )
    judge_validate.add_argument(
        "--judge-model", default=None,
        help="Model used as judge (for independence check)"
    )
    judge_validate.add_argument("--json", action="store_true")
    judge_validate.set_defaults(func=behavioral_judge_validate)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
