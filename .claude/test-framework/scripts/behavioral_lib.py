#!/usr/bin/env python3
import json
import re
from typing import Any, Dict, List, Tuple


def load_json(path: str) -> Dict[str, Any]:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def load_jsonl(path: str) -> List[Dict[str, Any]]:
    cases = []
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            cases.append(json.loads(line))
    return cases


def _cmd_matches(expected: str, actual: str) -> bool:
    if expected.startswith("re:"):
        pattern = expected[len("re:"):]
        return re.search(pattern, actual) is not None
    return actual.startswith(expected)


def _check_ordered_subsequence(expected_cmds: List[str], actual_cmds: List[str]) -> Tuple[bool, List[str]]:
    issues = []
    idx = 0
    for expected in expected_cmds:
        found = False
        while idx < len(actual_cmds):
            if _cmd_matches(expected, actual_cmds[idx]):
                found = True
                idx += 1
                break
            idx += 1
        if not found:
            issues.append(f"Expected command not found in order: {expected}")
    return (len(issues) == 0, issues)


def validate_case(case: Dict[str, Any], trace: Dict[str, Any]) -> Dict[str, Any]:
    issues = []
    case_id = case.get("id")
    trace_id = trace.get("case_id")
    if case_id and trace_id and case_id != trace_id:
        issues.append(f"case_id mismatch (case={case_id}, trace={trace_id})")

    should_activate = bool(case.get("should_activate"))
    activated = bool(trace.get("activated"))
    if should_activate != activated:
        issues.append(f"activation mismatch (should_activate={should_activate}, activated={activated})")

    expected_tools = case.get("expected_tools") or []
    tools_used = trace.get("tools_used") or []
    for tool in expected_tools:
        if tool not in tools_used:
            issues.append(f"expected tool missing: {tool}")

    expected_commands = case.get("expected_commands") or []
    if expected_commands:
        commands = [c.get("cmd", "") if isinstance(c, dict) else str(c) for c in (trace.get("commands") or [])]
        ok, cmd_issues = _check_ordered_subsequence(expected_commands, commands)
        if not ok:
            issues.extend(cmd_issues)

    forbidden_commands = case.get("forbidden_commands") or []
    if forbidden_commands:
        commands = [c.get("cmd", "") if isinstance(c, dict) else str(c) for c in (trace.get("commands") or [])]
        for pattern in forbidden_commands:
            regex = pattern
            if pattern.startswith("re:"):
                regex = pattern[len("re:"):]
            for cmd in commands:
                if re.search(regex, cmd):
                    issues.append(f"forbidden command observed: pattern={pattern}, cmd={cmd}")
                    break

    expected_files_modified = case.get("expected_files_modified") or []
    files_modified = trace.get("files_modified") or []
    for path in expected_files_modified:
        if path not in files_modified:
            issues.append(f"expected modified file missing: {path}")

    expected_files_created = case.get("expected_files_created") or []
    files_created = trace.get("files_created") or []
    for path in expected_files_created:
        if path not in files_created:
            issues.append(f"expected created file missing: {path}")

    return {
        "case_id": case_id,
        "pass": len(issues) == 0,
        "issues": issues,
    }


def compute_f1(tp: int, fp: int, fn: int) -> float:
    precision = tp / (tp + fp) if (tp + fp) > 0 else 0.0
    recall = tp / (tp + fn) if (tp + fn) > 0 else 0.0
    if precision + recall == 0:
        return 0.0
    return 2 * precision * recall / (precision + recall)


def compute_efficacy_delta(baseline_success: float, with_skill_success: float) -> float:
    """Compute absolute efficacy delta: success_with_skill - success_without_skill"""
    return with_skill_success - baseline_success


def compute_normalized_gain(baseline_success: float, with_skill_success: float) -> float:
    """Compute normalized gain: delta / (1 - baseline_success)

    This measures proportional improvement toward perfect performance.
    Returns 0.0 if baseline is already at 1.0 or if gain is negative.
    """
    if baseline_success >= 1.0:
        return 0.0
    delta = with_skill_success - baseline_success
    if delta <= 0:
        return 0.0
    return delta / (1.0 - baseline_success)


def compute_efficacy_metrics(baseline_traces: List[Dict[str, Any]],
                             skill_traces: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Compute efficacy metrics from baseline and with-skill traces.

    Args:
        baseline_traces: List of traces from baseline runs (no skill)
        skill_traces: List of traces from runs with skill

    Returns:
        Dictionary with efficacy metrics including:
        - baseline_success_rate
        - with_skill_success_rate
        - efficacy_delta
        - normalized_gain
    """
    baseline_completed = sum(1 for t in baseline_traces if t.get("task_completed", False))
    skill_completed = sum(1 for t in skill_traces if t.get("task_completed", False))

    baseline_success = baseline_completed / len(baseline_traces) if baseline_traces else 0.0
    skill_success = skill_completed / len(skill_traces) if skill_traces else 0.0

    delta = compute_efficacy_delta(baseline_success, skill_success)
    norm_gain = compute_normalized_gain(baseline_success, skill_success)

    return {
        "baseline_success_rate": baseline_success,
        "with_skill_success_rate": skill_success,
        "efficacy_delta": delta,
        "normalized_gain": norm_gain,
        "baseline_runs": len(baseline_traces),
        "skill_runs": len(skill_traces),
    }

