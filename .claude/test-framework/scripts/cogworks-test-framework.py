#!/usr/bin/env python3
import argparse
import json
import os
import sys
from datetime import datetime
from typing import Any, Dict, List

from behavioral_lib import (
    load_json,
    load_jsonl,
    validate_case,
    compute_f1,
    compute_efficacy_metrics,
)


def _write_json(path: str, payload: Dict[str, Any]) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2)


def _write_text(path: str, content: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)


def _assess_domain_efficacy(domain: str, efficacy_delta: float) -> str:
    """Assess efficacy delta in context of domain-specific expectations.

    Based on SkillsBench findings:
    - Healthcare: +51.9pp typical
    - Manufacturing: +35-50pp typical
    - Data Analysis: +15-30pp typical
    - Software Engineering: +4.5pp typical
    - Mathematics: +5-12pp typical
    """
    domain_ranges = {
        "healthcare": (0.40, 0.60, "Healthcare"),
        "manufacturing": (0.35, 0.50, "Manufacturing"),
        "data-analysis": (0.15, 0.30, "Data Analysis"),
        "software-engineering": (0.05, 0.15, "Software Engineering"),
        "devops-infrastructure": (0.05, 0.15, "DevOps/Infrastructure"),
        "mathematics": (0.05, 0.12, "Mathematics"),
    }

    domain_key = domain.lower()
    if domain_key in domain_ranges:
        low, high, display_name = domain_ranges[domain_key]
        typical = (low + high) / 2
        if efficacy_delta >= high:
            return f"Exceptional efficacy for {display_name} (above typical {typical:.1%})"
        elif efficacy_delta >= low:
            return f"Good efficacy for {display_name} (within typical {low:.1%}-{high:.1%})"
        else:
            return f"Below expected for {display_name} (typical {low:.1%}-{high:.1%})"
    else:
        # Unknown domain - provide generic assessment
        if efficacy_delta >= 0.25:
            return f"Exceptional efficacy ({efficacy_delta:.1%})"
        elif efficacy_delta >= 0.10:
            return f"Good efficacy ({efficacy_delta:.1%})"
        else:
            return f"Modest efficacy ({efficacy_delta:.1%})"


def _format_md_report(skill: str, summary: Dict[str, Any], case_results: List[Dict[str, Any]]) -> str:
    lines = []
    lines.append(f"# Behavioral Test Report: {skill}\n")
    lines.append(f"Status: {summary['status']}")
    lines.append(f"Cases: {summary['cases_total']}")

    # Activation metrics
    lines.append("\n## Activation Metrics")
    lines.append(f"- Activation F1: {summary['activation_f1']:.3f}")
    lines.append(f"- False Positive Rate: {summary['false_positive_rate']:.3f}")
    lines.append(f"- Negative Control Ratio: {summary['negative_control_ratio']:.3f}")

    # Efficacy metrics (if available)
    if summary.get("efficacy_metrics"):
        efficacy = summary["efficacy_metrics"]
        lines.append("\n## Efficacy Metrics")
        lines.append(f"- Baseline Success Rate: {efficacy['baseline_success_rate']:.1%} (without skill)")
        lines.append(f"- With Skill Success Rate: {efficacy['with_skill_success_rate']:.1%} (with skill)")
        lines.append(f"- Absolute Delta: {efficacy['efficacy_delta']:+.1%}")
        lines.append(f"- Normalized Gain: {efficacy['normalized_gain']:.1%}")
        lines.append(f"- Baseline Runs: {efficacy['baseline_runs']}")
        lines.append(f"- Skill Runs: {efficacy['skill_runs']}")

        # Domain context (if available)
        if summary.get("domain"):
            lines.append(f"\n## Domain Context")
            lines.append(f"- Domain: {summary['domain']}")
            if summary.get("domain_assessment"):
                lines.append(f"- Assessment: {summary['domain_assessment']}")

    lines.append("")

    if summary["failures"]:
        lines.append("## Failures")
        for f in summary["failures"]:
            lines.append(f"- {f}")
        lines.append("")

    lines.append("## Case Results")
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
            "efficacy_metrics": None,
            "domain": None,
            "domain_assessment": None,
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
        baseline_traces_list = []
        skill_traces_list = []
        domains_seen = set()

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

            # Collect traces for efficacy calculation
            if args.with_baseline:
                is_baseline = bool(trace.get("baseline_run", False))
                if is_baseline:
                    baseline_traces_list.append(trace)
                else:
                    skill_traces_list.append(trace)

            # Track domains
            domain = case.get("domain")
            if domain:
                domains_seen.add(domain)

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

        # Compute efficacy metrics if baseline traces are available
        if args.with_baseline and baseline_traces_list and skill_traces_list:
            efficacy = compute_efficacy_metrics(baseline_traces_list, skill_traces_list)
            skill_summary["efficacy_metrics"] = efficacy

            # Check efficacy thresholds
            if efficacy["efficacy_delta"] < args.efficacy_delta_min:
                skill_summary["status"] = "FAIL"
                skill_summary["failures"].append(
                    f"efficacy_delta < {args.efficacy_delta_min} ({efficacy['efficacy_delta']:.3f})"
                )

            if efficacy["normalized_gain"] < args.normalized_gain_min:
                skill_summary["status"] = "FAIL"
                skill_summary["failures"].append(
                    f"normalized_gain < {args.normalized_gain_min} ({efficacy['normalized_gain']:.3f})"
                )

            # Add domain context
            if domains_seen:
                skill_summary["domain"] = ", ".join(sorted(domains_seen))
                skill_summary["domain_assessment"] = _assess_domain_efficacy(
                    list(domains_seen)[0] if len(domains_seen) == 1 else "mixed",
                    efficacy["efficacy_delta"]
                )

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
                "baseline_success_rate": None,
                "with_skill_target": None,
                "domain": None,
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
                "baseline_success_rate": None,
                "with_skill_target": None,
                "domain": None,
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
                "baseline_success_rate": None,
                "with_skill_target": None,
                "domain": None,
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
                "baseline_success_rate": None,
                "with_skill_target": None,
                "domain": None,
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
                "baseline_success_rate": None,
                "with_skill_target": None,
                "domain": None,
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
                "baseline_success_rate": None,
                "with_skill_target": None,
                "domain": None,
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


def efficacy_validate(args: argparse.Namespace) -> int:
    """Validate a generated skill against efficacy benchmark tasks.

    This tests whether skills generated by the cogworks pipeline
    actually improve task performance versus baseline.
    """
    from pathlib import Path

    benchmark_path = Path(args.benchmark_task)
    if not benchmark_path.exists():
        print(f"Error: Benchmark task not found: {benchmark_path}", file=sys.stderr)
        return 2

    # Load metadata
    metadata_path = benchmark_path / "metadata.json"
    if not metadata_path.exists():
        print(f"Error: metadata.json not found in {benchmark_path}", file=sys.stderr)
        return 2

    with open(metadata_path, "r", encoding="utf-8") as f:
        metadata = json.load(f)

    task_id = metadata["task_id"]
    baseline_success_rate = metadata["baseline_success_rate"]
    target_success_rate = metadata.get("target_with_skill_rate", 0.85)
    domain = metadata.get("domain", "unknown")

    print(f"Validating skill against benchmark: {task_id}")
    print(f"Domain: {domain}")
    print(f"Baseline success rate: {baseline_success_rate:.1%}")
    print(f"Target with skill: {target_success_rate:.1%}")
    print()

    # Load baseline traces
    baseline_traces_dir = benchmark_path / "baseline-traces"
    if not baseline_traces_dir.exists():
        print(f"Error: baseline-traces/ not found in {benchmark_path}", file=sys.stderr)
        return 2

    baseline_traces = []
    for trace_file in sorted(baseline_traces_dir.glob("*.json")):
        with open(trace_file, "r", encoding="utf-8") as f:
            baseline_traces.append(json.load(f))

    if not baseline_traces:
        print(f"Error: No baseline traces found in {baseline_traces_dir}", file=sys.stderr)
        return 2

    baseline_completed = sum(1 for t in baseline_traces if t.get("task_completed", False))
    baseline_rate = baseline_completed / len(baseline_traces)

    print(f"Baseline traces loaded: {len(baseline_traces)}")
    print(f"Baseline completion rate: {baseline_rate:.1%}")
    print()

    # Check for with-skill traces
    skill_traces_dir = benchmark_path / "skill-traces"
    if not skill_traces_dir.exists():
        print("NOTE: No skill-traces/ directory found.")
        print("To complete validation:")
        print(f"1. Use the generated skill at: {args.generated_skill}")
        print(f"2. Run the task in: {benchmark_path / 'instruction.md'}")
        print(f"3. Capture traces to: {skill_traces_dir}/")
        print(f"4. Re-run this validation")
        return 0

    skill_traces = []
    for trace_file in sorted(skill_traces_dir.glob("*.json")):
        with open(trace_file, "r", encoding="utf-8") as f:
            skill_traces.append(json.load(f))

    if not skill_traces:
        print(f"NOTE: No traces found in {skill_traces_dir}")
        print("Capture with-skill traces and re-run validation.")
        return 0

    skill_completed = sum(1 for t in skill_traces if t.get("task_completed", False))
    skill_rate = skill_completed / len(skill_traces)

    print(f"With-skill traces loaded: {len(skill_traces)}")
    print(f"With-skill completion rate: {skill_rate:.1%}")
    print()

    # Compute efficacy metrics
    from behavioral_lib import compute_efficacy_delta, compute_normalized_gain

    delta = compute_efficacy_delta(baseline_rate, skill_rate)
    gain = compute_normalized_gain(baseline_rate, skill_rate)

    print("=== EFFICACY METRICS ===")
    print(f"Baseline Success Rate: {baseline_rate:.1%}")
    print(f"With Skill Success Rate: {skill_rate:.1%}")
    print(f"Absolute Delta: {delta:+.1%}")
    print(f"Normalized Gain: {gain:.1%}")
    print()

    # Domain assessment
    assessment = _assess_domain_efficacy(domain, delta)
    print(f"Domain: {domain}")
    print(f"Assessment: {assessment}")
    print()

    # Check thresholds
    failures = []
    if delta < args.efficacy_delta_min:
        failures.append(f"efficacy_delta < {args.efficacy_delta_min} ({delta:.3f})")

    if gain < args.normalized_gain_min:
        failures.append(f"normalized_gain < {args.normalized_gain_min} ({gain:.3f})")

    if failures:
        print("Status: FAIL")
        for f in failures:
            print(f"  - {f}")
        return 1

    print("Status: PASS")
    print(f"Skill exceeds efficacy thresholds for {task_id}")

    # Write results if output specified
    if args.output:
        result = {
            "task_id": task_id,
            "domain": domain,
            "baseline_success_rate": baseline_rate,
            "with_skill_success_rate": skill_rate,
            "efficacy_delta": delta,
            "normalized_gain": gain,
            "baseline_runs": len(baseline_traces),
            "skill_runs": len(skill_traces),
            "status": "PASS",
            "assessment": assessment,
        }
        os.makedirs(os.path.dirname(args.output), exist_ok=True)
        with open(args.output, "w", encoding="utf-8") as f:
            json.dump(result, f, indent=2)
        print(f"\nResults written to: {args.output}")

    return 0


def efficacy_run_benchmarks(args: argparse.Namespace) -> int:
    """Run efficacy validation across all benchmark tasks."""
    from pathlib import Path

    benchmarks_root = Path(args.benchmarks_root)
    if not benchmarks_root.exists():
        print(f"Error: Benchmarks root not found: {benchmarks_root}", file=sys.stderr)
        return 2

    # Find all benchmark tasks
    tasks = sorted([d for d in benchmarks_root.iterdir() if d.is_dir() and d.name.startswith("task-")])

    if not tasks:
        print(f"No benchmark tasks found in {benchmarks_root}", file=sys.stderr)
        return 2

    print(f"Running efficacy validation on {len(tasks)} benchmark tasks")
    print(f"Generated skill: {args.generated_skill}")
    print()

    results = []
    for task_path in tasks:
        print(f"=" * 60)
        print(f"Task: {task_path.name}")
        print(f"=" * 60)

        # Run validation for this task
        validate_args = argparse.Namespace(
            benchmark_task=str(task_path),
            generated_skill=args.generated_skill,
            efficacy_delta_min=args.efficacy_delta_min,
            normalized_gain_min=args.normalized_gain_min,
            output=None,
        )

        status = efficacy_validate(validate_args)
        results.append({
            "task": task_path.name,
            "status": "PASS" if status == 0 else "FAIL",
        })

        print()

    # Summary
    print("=" * 60)
    print("SUMMARY")
    print("=" * 60)

    passed = sum(1 for r in results if r["status"] == "PASS")
    total = len(results)

    for r in results:
        print(f"  {r['task']}: {r['status']}")

    print()
    print(f"Passed: {passed}/{total} ({passed/total:.1%})")

    if passed == total:
        print("\nAll benchmarks PASSED")
        return 0
    elif passed >= total * 0.7:
        print(f"\nMost benchmarks passed ({passed}/{total}), but some failed")
        return 1
    else:
        print(f"\nFailed too many benchmarks ({passed}/{total})")
        return 1


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
    run.add_argument("--with-baseline", action="store_true", help="Compute efficacy metrics from baseline traces")
    run.add_argument("--efficacy-delta-min", type=float, default=0.10, help="Minimum efficacy delta threshold (default: 0.10)")
    run.add_argument("--normalized-gain-min", type=float, default=0.15, help="Minimum normalized gain threshold (default: 0.15)")
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

    efficacy = sub.add_parser("efficacy", help="Efficacy validation (SkillsBench methodology)")
    efficacy_sub = efficacy.add_subparsers(dest="subcommand", required=True)

    validate = efficacy_sub.add_parser("validate", help="Validate generated skill against benchmark task")
    validate.add_argument("--generated-skill", required=True, help="Path to generated skill directory")
    validate.add_argument("--benchmark-task", required=True, help="Path to benchmark task directory")
    validate.add_argument("--efficacy-delta-min", type=float, default=0.10, help="Minimum efficacy delta (default: 0.10)")
    validate.add_argument("--normalized-gain-min", type=float, default=0.15, help="Minimum normalized gain (default: 0.15)")
    validate.add_argument("--output", default=None, help="Output JSON results file")
    validate.set_defaults(func=efficacy_validate)

    run_benchmarks = efficacy_sub.add_parser("run", help="Run all benchmark tasks for a generated skill")
    run_benchmarks.add_argument("--generated-skill", required=True, help="Path to generated skill directory")
    run_benchmarks.add_argument("--benchmarks-root", default="tests/datasets/efficacy-benchmark", help="Path to benchmarks root")
    run_benchmarks.add_argument("--efficacy-delta-min", type=float, default=0.10, help="Minimum efficacy delta (default: 0.10)")
    run_benchmarks.add_argument("--normalized-gain-min", type=float, default=0.15, help="Minimum normalized gain (default: 0.15)")
    run_benchmarks.set_defaults(func=efficacy_run_benchmarks)

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
