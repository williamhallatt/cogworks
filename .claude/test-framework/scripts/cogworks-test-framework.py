#!/usr/bin/env python3
import argparse
import json
import os
import sys
from datetime import datetime
from typing import Any, Dict, List

from behavioral_lib import load_json, load_jsonl, validate_case, compute_f1


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
    lines.append(f"F1: {summary['activation_f1']:.3f}")
    lines.append(f"False positive rate: {summary['false_positive_rate']:.3f}")
    lines.append(f"Negative control ratio: {summary['negative_control_ratio']:.3f}\n")

    if summary["failures"]:
        lines.append("Failures:")
        for f in summary["failures"]:
            lines.append(f"- {f}")
        lines.append("")

    lines.append("Case Results:")
    for case in case_results:
        status = "PASS" if case["pass"] else "FAIL"
        lines.append(f"- {case['case_id']}: {status}")
        if case["issues"]:
            for issue in case["issues"]:
                lines.append(f"  {issue}")

    return "\n".join(lines) + "\n"


def _collect_skills(skills_root: str, prefixes: List[str]) -> List[str]:
    skills = []
    for name in os.listdir(skills_root):
        path = os.path.join(skills_root, name)
        if not os.path.isdir(path):
            continue
        if not os.path.exists(os.path.join(path, "SKILL.md")):
            continue
        if prefixes and not any(name.startswith(p) for p in prefixes):
            continue
        skills.append(name)
    return sorted(skills)


def behavioral_run(args: argparse.Namespace) -> int:
    timestamp = args.timestamp or datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
    results_dir = os.path.join(args.results_root, timestamp)
    os.makedirs(results_dir, exist_ok=True)

    overall = {
        "timestamp": timestamp,
        "skills": [],
        "status": "PASS",
        "failures": [],
    }

    for skill in _collect_skills(args.skills_root, args.skill_prefix):
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

        case_results = []
        if not os.path.exists(test_cases_path):
            msg = f"missing test cases: {test_cases_path}"
            if not args.allow_missing_tests:
                skill_summary["status"] = "FAIL"
                skill_summary["failures"].append(msg)
            else:
                skill_summary["failures"].append(f"WARN: {msg}")
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

        ids = [c.get("id") for c in cases]
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
                case_results.append({
                    "case_id": case_id,
                    "pass": False,
                    "issues": [msg],
                })
                skill_summary["status"] = "FAIL"
                skill_summary["failures"].append(msg)
                continue

            trace = load_json(trace_path)
            result = validate_case(case, trace)
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

        if neg_ratio < 0.25:
            skill_summary["status"] = "FAIL"
            skill_summary["failures"].append("negative control ratio < 0.25")

        if f1 < 0.85:
            skill_summary["status"] = "FAIL"
            skill_summary["failures"].append(f"activation_f1 < 0.85 ({f1:.3f})")

        if fpr > 0.05:
            skill_summary["status"] = "FAIL"
            skill_summary["failures"].append(f"false_positive_rate > 0.05 ({fpr:.3f})")

        overall["skills"].append(skill_summary)
        if skill_summary["status"] == "FAIL":
            overall["status"] = "FAIL"
            overall["failures"].append(f"{skill}: behavioral gate failed")

        json_path = os.path.join(results_dir, f"{skill}-behavioral.json")
        md_path = os.path.join(results_dir, f"{skill}-behavioral.md")
        _write_json(json_path, {"summary": skill_summary, "cases": case_results})
        _write_text(md_path, _format_md_report(skill, skill_summary, case_results))

    overall_path = os.path.join(results_dir, "summary.json")
    overall_md_path = os.path.join(results_dir, "summary.md")
    _write_json(overall_path, overall)
    _write_text(overall_md_path, json.dumps(overall, indent=2) + "\n")

    return 0 if overall["status"] == "PASS" else 1


def behavioral_validate(args: argparse.Namespace) -> int:
    cases = load_jsonl(args.test_cases)
    case = next((c for c in cases if c.get("id") == args.case_id), None)
    if case is None:
        print(f"Case id not found: {args.case_id}", file=sys.stderr)
        return 2

    trace = load_json(args.trace)
    result = validate_case(case, trace)

    if args.json:
        print(json.dumps(result, indent=2))
    else:
        status = "PASS" if result["pass"] else "FAIL"
        print(f"Case {result['case_id']}: {status}")
        if result["issues"]:
            for issue in result["issues"]:
                print(f"- {issue}")

    return 0 if result["pass"] else 1


def behavioral_scaffold(args: argparse.Namespace) -> int:
    def default_cases(slug: str) -> List[dict]:
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
                "id": f"{slug}-exp-002",
                "category": "explicit",
                "user_request": f"Run the {slug} skill on these sources.",
                "should_activate": True,
                "expected_tools": [],
                "expected_commands": [],
                "forbidden_commands": [],
                "expected_files_modified": [],
                "expected_files_created": [],
                "notes": "Explicit skill name should activate",
            },
            {
                "id": f"{slug}-imp-001",
                "category": "implicit",
                "user_request": f"Synthesize these sources into a skill about {slug}.",
                "should_activate": True,
                "expected_tools": [],
                "expected_commands": [],
                "forbidden_commands": [],
                "expected_files_modified": [],
                "expected_files_created": [],
                "notes": "Implicit intent should activate",
            },
            {
                "id": f"{slug}-ctx-001",
                "category": "contextual",
                "user_request": f"We are working in this repo; help generate a {slug} skill.",
                "should_activate": True,
                "expected_tools": [],
                "expected_commands": [],
                "forbidden_commands": [],
                "expected_files_modified": [],
                "expected_files_created": [],
                "notes": "Contextual intent should activate",
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
            {
                "id": f"{slug}-neg-002",
                "category": "negative_control",
                "user_request": f"Explain what {slug} is.",
                "should_activate": False,
                "expected_tools": [],
                "expected_commands": [],
                "forbidden_commands": [],
                "expected_files_modified": [],
                "expected_files_created": [],
                "notes": "Meta question should not activate",
            },
        ]

    def write_jsonl(path: str, cases: List[dict]) -> None:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            for case in cases:
                f.write(json.dumps(case) + "\n")

    def collect_skills(skills_root: str, prefixes: List[str]) -> List[str]:
        skills = []
        for name in os.listdir(skills_root):
            path = os.path.join(skills_root, name)
            if not os.path.isdir(path):
                continue
            if not os.path.exists(os.path.join(path, "SKILL.md")):
                continue
            if prefixes and not any(name.startswith(p) for p in prefixes):
                continue
            skills.append(name)
        return sorted(skills)

    skills = args.skill or collect_skills(args.skills_root, args.skill_prefix)
    for slug in skills:
        cases_path = os.path.join(args.tests_root, slug, "test-cases.jsonl")
        if os.path.exists(cases_path) and not args.force:
            print(f"Skip (exists): {cases_path}")
            continue
        cases = default_cases(slug)
        write_jsonl(cases_path, cases)
        print(f"Wrote: {cases_path}")

    return 0


def calibration_summarize(args: argparse.Namespace) -> int:
    import yaml
    from pathlib import Path

    categories = [
        "source_fidelity",
        "self_sufficiency",
        "completeness",
        "specificity",
        "no_overlap",
    ]

    def load_human(grades_dir: Path):
        grades = {}
        for yaml_file in grades_dir.glob("*-human.yaml"):
            skill_slug = yaml_file.stem.replace("-human", "")
            with open(yaml_file, "r", encoding="utf-8") as f:
                data = yaml.safe_load(f)
            grades[skill_slug] = data.get("categories", {})
        return grades

    def load_llm(results_dir: Path):
        grades = {}
        for json_file in results_dir.glob("*-results.json"):
            skill_slug = json_file.stem.replace("-results", "")
            with open(json_file, "r", encoding="utf-8") as f:
                data = json.load(f)
            if "layer2" in data:
                grades[skill_slug] = data["layer2"]
            elif "categories" in data:
                grades[skill_slug] = data["categories"]
        return grades

    def within(a: float, b: float, tol: float = 0.5) -> bool:
        return abs(a - b) <= tol

    human = load_human(Path(args.human_grades))
    llm = load_llm(Path(args.llm_results))

    skills = sorted(set(human.keys()) & set(llm.keys()))
    if not skills:
        return 1

    overall_agree = 0
    category_agreement = {c: 0 for c in categories}

    for skill in skills:
        agree_categories = 0
        for cat in categories:
            h = human[skill].get(cat, {}).get("score", 0)
            l = llm[skill].get(cat, {}).get("score", 0)
            if within(h, l):
                category_agreement[cat] += 1
                agree_categories += 1
        if agree_categories >= 4:
            overall_agree += 1

    total = len(skills)
    summary = {
        "agreement_overall": overall_agree / total,
        "agreement_by_category": {c: category_agreement[c] / total for c in categories},
        "num_skills": total,
    }

    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    with open(args.out, "w", encoding="utf-8") as f:
        json.dump(summary, f, indent=2)

    return 0


def calibration_check(args: argparse.Namespace) -> int:
    try:
        with open(args.summary, "r", encoding="utf-8") as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"Missing calibration summary: {args.summary}", file=sys.stderr)
        return 2

    overall = data.get("agreement_overall")
    by_cat = data.get("agreement_by_category") or {}

    failures = []
    if overall is None or overall < args.overall_min:
        failures.append(f"agreement_overall < {args.overall_min} ({overall})")

    for cat, score in by_cat.items():
        if score < args.category_min:
            failures.append(f"{cat} < {args.category_min} ({score})")

    if failures:
        print("Calibration check FAIL")
        for f in failures:
            print(f"- {f}")
        return 1

    print("Calibration check PASS")
    return 0


def calibration_run(args: argparse.Namespace) -> int:
    # Summarize first, then check thresholds.
    summarize_args = argparse.Namespace(
        human_grades=args.human_grades,
        llm_results=args.llm_results,
        out=args.out,
    )
    summarize_status = calibration_summarize(summarize_args)
    if summarize_status != 0:
        return summarize_status

    check_args = argparse.Namespace(
        summary=args.out,
        overall_min=args.overall_min,
        category_min=args.category_min,
    )
    return calibration_check(check_args)


def leakage_audit(args: argparse.Namespace) -> int:
    def read_files(root: str) -> Dict[str, str]:
        data = {}
        for dirpath, _, filenames in os.walk(root):
            for name in filenames:
                path = os.path.join(dirpath, name)
                try:
                    with open(path, "r", encoding="utf-8") as f:
                        data[path] = f.read()
                except Exception:
                    continue
        return data

    def extract_candidate_lines(text: str) -> List[str]:
        lines = []
        for raw in text.splitlines():
            line = raw.strip()
            if len(line) < 40 or len(line) > 200:
                continue
            if line.startswith("#"):
                continue
            if line.startswith("-") or line.startswith("*") or line.startswith("+"):
                continue
            if "[Source" in line or ")" in line and ":" in line:
                continue
            lines.append(line)
        return lines

    sources = read_files(args.sources_dir)
    skill_files = read_files(args.skill_dir)

    candidates = []
    for content in sources.values():
        candidates.extend(extract_candidate_lines(content))
    candidates = list(dict.fromkeys(candidates))

    findings = []
    for path, content in skill_files.items():
        for line in candidates:
            if line in content:
                findings.append({"file": path, "match": line})

    result = {
        "skill_dir": args.skill_dir,
        "sources_dir": args.sources_dir,
        "findings": findings,
        "status": "FAIL" if findings else "PASS",
    }

    if args.json:
        print(json.dumps(result, indent=2))
    else:
        print(f"Leakage audit: {result['status']}")
        for f in findings:
            print(f"- {f['file']}: {f['match']}")

    return 0 if result["status"] == "PASS" else 1


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Cogworks test framework CLI")
    sub = parser.add_subparsers(dest="command", required=True)

    behavioral = sub.add_parser("behavioral", help="Behavioral tests")
    behavioral_sub = behavioral.add_subparsers(dest="subcommand", required=True)

    run = behavioral_sub.add_parser("run", help="Run behavioral tests")
    run.add_argument("--skills-root", default=".claude/skills")
    run.add_argument("--tests-root", default="tests/behavioral")
    run.add_argument("--results-root", default="tests/results/behavioral")
    run.add_argument("--timestamp", default=None)
    run.add_argument("--skill-prefix", action="append", default=[], help="Only include skills with this prefix (repeatable)")
    run.add_argument("--allow-missing-tests", action="store_true")
    run.set_defaults(func=behavioral_run)

    validate = behavioral_sub.add_parser("validate", help="Validate a single trace")
    validate.add_argument("--test-cases", required=True)
    validate.add_argument("--case-id", required=True)
    validate.add_argument("--trace", required=True)
    validate.add_argument("--json", action="store_true")
    validate.set_defaults(func=behavioral_validate)

    scaffold = behavioral_sub.add_parser("scaffold", help="Scaffold behavioral test cases")
    scaffold.add_argument("--skills-root", default=".claude/skills")
    scaffold.add_argument("--tests-root", default="tests/behavioral")
    scaffold.add_argument("--skill", action="append", default=[], help="Specific skill slug (repeatable)")
    scaffold.add_argument("--skill-prefix", action="append", default=[], help="Only include skills with this prefix (repeatable)")
    scaffold.add_argument("--force", action="store_true")
    scaffold.set_defaults(func=behavioral_scaffold)

    calibration = sub.add_parser("calibration", help="Calibration utilities")
    calibration_sub = calibration.add_subparsers(dest="subcommand", required=True)

    run = calibration_sub.add_parser("run", help="Summarize calibration agreement and check thresholds")
    run.add_argument("--human-grades", default="tests/calibration")
    run.add_argument("--llm-results", default="tests/results/latest")
    run.add_argument("--out", default="tests/calibration/latest/summary.json")
    run.add_argument("--overall-min", type=float, default=0.90)
    run.add_argument("--category-min", type=float, default=0.85)
    run.set_defaults(func=calibration_run)

    leakage = sub.add_parser("leakage", help="Leakage audit")
    leakage_sub = leakage.add_subparsers(dest="subcommand", required=True)

    audit = leakage_sub.add_parser("audit", help="Run leakage audit")
    audit.add_argument("--skill-dir", required=True)
    audit.add_argument("--sources-dir", required=True)
    audit.add_argument("--json", action="store_true")
    audit.set_defaults(func=leakage_audit)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
