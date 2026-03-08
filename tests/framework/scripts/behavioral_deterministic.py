#!/usr/bin/env python3
"""Layer 5a — Deterministic behavioral test validation.

Validates behavioral test case definitions for structural correctness,
activation keyword consistency, and category coverage. No API key or
agent execution required.

Exit 0 = all checks pass. Exit 1 = failures found.
"""

import argparse
import json
import os
import re
import sys
from typing import Any, Dict, List


DETERMINISTIC_CATEGORIES = {"explicit", "implicit", "contextual", "negative_control"}
JUDGE_CATEGORIES = {"quality_gate", "edge_case", "quality"}
ALL_CATEGORIES = DETERMINISTIC_CATEGORIES | JUDGE_CATEGORIES

REQUIRED_FIELDS = {"id", "category", "user_request", "should_activate"}
QUALITY_GATE_FIELDS = {"ground_truth", "evaluator_notes"}
QUALITY_FIELDS = {"expected_content"}

MIN_NEGATIVE_RATIO = 0.15


def load_jsonl(path: str) -> List[Dict[str, Any]]:
    cases: List[Dict[str, Any]] = []
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line:
                cases.append(json.loads(line))
    return cases


def check_required_fields(case: Dict[str, Any]) -> List[str]:
    issues: List[str] = []
    for field in REQUIRED_FIELDS:
        if field not in case:
            issues.append(f"missing required field: {field}")

    category = case.get("category", "")

    if category in {"quality_gate", "edge_case"}:
        for field in QUALITY_GATE_FIELDS:
            if field not in case:
                issues.append(f"missing field for {category} category: {field}")

    if category == "quality":
        for field in QUALITY_FIELDS:
            if field not in case:
                issues.append(f"missing field for quality category: {field}")
            elif not isinstance(case.get(field), list):
                issues.append(f"{field} must be a list for quality category")

    return issues


def check_forbidden_commands_format(case: Dict[str, Any]) -> List[str]:
    issues: List[str] = []
    for pattern in case.get("forbidden_commands", []):
        if isinstance(pattern, str) and pattern.startswith("re:"):
            try:
                re.compile(pattern[3:])
            except re.error as e:
                issues.append(f"invalid regex in forbidden_commands: {pattern} ({e})")
    return issues


def check_explicit_activation(case: Dict[str, Any], skill_slug: str) -> List[str]:
    """For explicit cases, verify user_request mentions the skill name."""
    issues: List[str] = []
    request = case.get("user_request", "").lower()
    if case.get("should_activate"):
        if skill_slug not in request:
            issues.append(
                f"explicit case should_activate=true but skill slug "
                f"'{skill_slug}' not in user_request"
            )
    return issues


def check_negative_control(case: Dict[str, Any], skill_slug: str) -> List[str]:
    """For negative controls, verify user_request does NOT mention the skill name."""
    issues: List[str] = []
    request = case.get("user_request", "").lower()
    if not case.get("should_activate"):
        if skill_slug in request:
            issues.append(
                f"negative_control should_activate=false but skill slug "
                f"'{skill_slug}' found in user_request"
            )
    return issues


def check_implicit_boundary(case: Dict[str, Any], skill_slug: str) -> List[str]:
    """For implicit/contextual cases, verify they don't contain the explicit skill slug."""
    issues: List[str] = []
    request = case.get("user_request", "").lower()
    # Check for exact skill slug mention (e.g., "/cogworks-encode" or "cogworks-encode")
    # but allow parent slug mentions in child skill cases
    # e.g., cogworks-encode implicit case should not contain "cogworks-encode"
    #        but may contain "cogworks" as part of a different reference
    if skill_slug in request:
        issues.append(
            f"implicit/contextual case contains explicit skill slug "
            f"'{skill_slug}' — should be explicit category"
        )
    return issues


def check_quality_gate_activation(case: Dict[str, Any]) -> List[str]:
    """Quality gate and edge case tests should always have should_activate=true."""
    issues: List[str] = []
    if not case.get("should_activate"):
        issues.append(
            f"quality_gate/edge_case case has should_activate=false "
            f"— these cases require activation to test quality"
        )
    return issues


def validate_skill(skill_slug: str, cases_path: str) -> Dict[str, Any]:
    cases = load_jsonl(cases_path)

    result: Dict[str, Any] = {
        "skill": skill_slug,
        "cases_total": len(cases),
        "cases_checked": 0,
        "cases_skipped": 0,
        "pass": True,
        "issues": [],
        "case_results": [],
    }

    if not cases:
        result["pass"] = False
        result["issues"].append("no test cases found")
        return result

    # Check unique IDs
    ids = [c.get("id") for c in cases]
    seen = set()
    dupes = set()
    for i in ids:
        if i in seen:
            dupes.add(i)
        seen.add(i)
    if dupes:
        result["issues"].append(f"duplicate case IDs: {sorted(dupes)}")
        result["pass"] = False

    # Category coverage: require explicit + negative_control at minimum
    categories = {c.get("category") for c in cases}
    for req_cat in ["explicit", "negative_control"]:
        if req_cat not in categories:
            result["issues"].append(f"missing required category: {req_cat}")
            result["pass"] = False

    # Negative control ratio
    neg_count = sum(1 for c in cases if c.get("category") == "negative_control")
    ratio = neg_count / len(cases) if cases else 0
    if ratio < MIN_NEGATIVE_RATIO:
        result["issues"].append(
            f"negative control ratio {neg_count}/{len(cases)} "
            f"({ratio:.0%}) < {MIN_NEGATIVE_RATIO:.0%}"
        )
        result["pass"] = False

    # Unknown categories
    for case in cases:
        cat = case.get("category", "")
        if cat and cat not in ALL_CATEGORIES:
            result["issues"].append(f"unknown category '{cat}' in case {case.get('id')}")
            result["pass"] = False

    # Per-case validation
    for case in cases:
        case_id = case.get("id", "unknown")
        category = case.get("category", "")
        case_issues: List[str] = []

        # Structural checks (all categories)
        case_issues.extend(check_required_fields(case))
        case_issues.extend(check_forbidden_commands_format(case))

        # Category-specific checks
        if category == "explicit":
            case_issues.extend(check_explicit_activation(case, skill_slug))
            result["cases_checked"] += 1
        elif category == "negative_control":
            case_issues.extend(check_negative_control(case, skill_slug))
            result["cases_checked"] += 1
        elif category in {"implicit", "contextual"}:
            case_issues.extend(check_implicit_boundary(case, skill_slug))
            result["cases_checked"] += 1
        elif category in {"quality_gate", "edge_case"}:
            case_issues.extend(check_quality_gate_activation(case))
            result["cases_skipped"] += 1
        elif category == "quality":
            case_issues.extend(check_quality_gate_activation(case))
            result["cases_skipped"] += 1
        else:
            result["cases_skipped"] += 1

        case_pass = len(case_issues) == 0
        result["case_results"].append({
            "case_id": case_id,
            "category": category,
            "pass": case_pass,
            "issues": case_issues,
        })

        if not case_pass:
            result["pass"] = False

    return result


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Layer 5a — Deterministic behavioral test validation"
    )
    parser.add_argument("--tests-root", default="tests/behavioral")
    parser.add_argument("--json", action="store_true", help="Output JSON results")
    args = parser.parse_args()

    skills: List[tuple[str, str]] = []
    if os.path.isdir(args.tests_root):
        for name in sorted(os.listdir(args.tests_root)):
            cases_path = os.path.join(args.tests_root, name, "test-cases.jsonl")
            if os.path.exists(cases_path):
                skills.append((name, cases_path))

    if not skills:
        print("No behavioral test cases found", file=sys.stderr)
        return 1

    overall_pass = True
    results = []

    for skill_slug, cases_path in skills:
        result = validate_skill(skill_slug, cases_path)
        results.append(result)
        if not result["pass"]:
            overall_pass = False

    if args.json:
        print(json.dumps({"pass": overall_pass, "skills": results}, indent=2))
    else:
        print("=== Layer 5a — Deterministic Behavioral Validation ===\n")
        for result in results:
            status = "PASS" if result["pass"] else "FAIL"
            print(
                f"{status}  {result['skill']} — "
                f"{result['cases_checked']} checked, "
                f"{result['cases_skipped']} skipped (judge-required), "
                f"{result['cases_total']} total"
            )
            for issue in result.get("issues", []):
                print(f"  ⚠ {issue}")
            for cr in result["case_results"]:
                if not cr["pass"]:
                    print(f"  FAIL  {cr['case_id']}")
                    for issue in cr["issues"]:
                        print(f"    - {issue}")
            print()

        if overall_pass:
            print("Layer 5a behavioral deterministic validation passed.")
        else:
            print(
                "Layer 5a behavioral deterministic validation FAILED.",
                file=sys.stderr,
            )

    return 0 if overall_pass else 1


if __name__ == "__main__":
    raise SystemExit(main())
