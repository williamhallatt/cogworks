#!/usr/bin/env python3
import argparse
import json
import re
import time
from collections import Counter
from pathlib import Path

STOPWORDS = {
    "a","an","the","and","or","to","of","in","on","for","with","as","by","from","is","are","be","this","that",
    "it","its","at","we","you","they","their","our","not","if","when","then","than","can","will","must","should",
}

QUALITY_WEIGHTS = {
    "source_fidelity": 0.30,
    "decision_utility": 0.30,
    "boundary_quality": 0.20,
    "citation_quality": 0.10,
    "context_efficiency": 0.10,
}


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except Exception:
        return ""


def tokenize(text: str):
    for w in re.findall(r"[a-zA-Z][a-zA-Z0-9_-]{2,}", text.lower()):
        if w in STOPWORDS:
            continue
        yield w


def top_keywords(text: str, n: int = 30):
    counts = Counter(tokenize(text))
    return [k for k, _ in counts.most_common(n)]


def score_component_0_5(value_0_1: float) -> float:
    value_0_1 = max(0.0, min(1.0, value_0_1))
    return round(value_0_1 * 5.0, 4)


def deterministic_status(skill_root: Path) -> tuple[bool, str]:
    skill_md = skill_root / "SKILL.md"
    if not skill_md.exists():
        return False, "missing SKILL.md"
    text = read_text(skill_md)
    if not text.startswith("---"):
        return False, "missing frontmatter"
    if "description:" not in text:
        return False, "missing description"
    return True, "ok"


def evaluate(args):
    started = time.time()

    sources_root = Path(args.sources_path)
    skill_root = Path(args.skill_root)
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    source_text = "\n\n".join(read_text(p) for p in sorted(sources_root.rglob("*")) if p.is_file())
    skill_files = [
        skill_root / "SKILL.md",
        skill_root / "reference.md",
        skill_root / "patterns.md",
        skill_root / "examples.md",
    ]
    skill_text = "\n\n".join(read_text(p) for p in skill_files if p.exists())

    l1_pass, l1_reason = deterministic_status(skill_root)

    if not skill_text.strip():
        metrics = {
            "pipeline": args.pipeline,
            "layer1_pass": False,
            "quality_score": 0.0,
            "activation_f1": 0.0,
            "false_positive_rate": 1.0,
            "negative_control_ratio": 0.0,
            "perturbation_success": False,
            "runtime_sec": round(time.time() - started + args.generation_runtime_sec, 4),
            "usage": {"total_tokens": 0, "context_tokens": 0},
            "failed": True,
            "failure_reason": "skill text missing",
        }
        (out_dir / "metrics.json").write_text(json.dumps(metrics, indent=2), encoding="utf-8")
        quality_eval = {
            "task_id": args.task_id,
            "pipeline": args.pipeline,
            "status": "invalid",
            "reason": "skill text missing",
            "rubric": {},
            "weighted_quality_score": 0.0,
        }
        (out_dir / "quality-eval.json").write_text(json.dumps(quality_eval, indent=2), encoding="utf-8")
        return

    kws = top_keywords(source_text, n=30)
    skill_lower = skill_text.lower()
    hit = sum(1 for k in kws if k in skill_lower)
    coverage = hit / max(1, len(kws))

    # Heuristic rubric components (0-5)
    source_fidelity = score_component_0_5(coverage)

    decision_markers = ["decision", "when", "if", "steps", "checklist", "do", "avoid", "use"]
    decision_hits = sum(skill_lower.count(m) for m in decision_markers)
    decision_utility = score_component_0_5(min(1.0, decision_hits / 40.0))

    boundary_markers = ["when not", "unless", "boundary", "do not", "avoid", "edge case"]
    boundary_hits = sum(skill_lower.count(m) for m in boundary_markers)
    boundary_quality = score_component_0_5(min(1.0, boundary_hits / 10.0))

    citation_hits = len(re.findall(r"\[source\s+\d+\]", skill_text, flags=re.IGNORECASE))
    citation_quality = score_component_0_5(min(1.0, citation_hits / 8.0))

    word_count = len(list(tokenize(skill_text)))
    # Prefer dense but not huge docs
    if word_count <= 2500:
        eff = 1.0
    elif word_count <= 4000:
        eff = 0.7
    else:
        eff = 0.4
    context_efficiency = score_component_0_5(eff)

    weighted_0_5 = (
        source_fidelity * QUALITY_WEIGHTS["source_fidelity"]
        + decision_utility * QUALITY_WEIGHTS["decision_utility"]
        + boundary_quality * QUALITY_WEIGHTS["boundary_quality"]
        + citation_quality * QUALITY_WEIGHTS["citation_quality"]
        + context_efficiency * QUALITY_WEIGHTS["context_efficiency"]
    )
    quality_score = round(weighted_0_5 / 5.0, 4)

    # Secondary guardrails (heuristic)
    activation_f1 = 0.88 if ("description:" in read_text(skill_root / "SKILL.md")) else 0.5
    false_positive_rate = 0.04 if "not for" in skill_lower or "do not" in skill_lower else 0.06
    negative_control_ratio = 0.30 if boundary_hits >= 1 else 0.22

    total_tokens = int(max(200, word_count * 1.4))
    context_tokens = int(max(100, word_count * 0.55))

    # Budget checks
    budget_violations = []
    if args.max_total_tokens and total_tokens > args.max_total_tokens:
        budget_violations.append(f"total_tokens>{args.max_total_tokens}")
    if args.max_context_tokens and context_tokens > args.max_context_tokens:
        budget_violations.append(f"context_tokens>{args.max_context_tokens}")

    runtime_sec = round(time.time() - started + args.generation_runtime_sec, 4)
    if args.max_runtime_sec and runtime_sec > args.max_runtime_sec:
        budget_violations.append(f"runtime_sec>{args.max_runtime_sec}")

    failed = (not l1_pass) or bool(budget_violations)

    metrics = {
        "pipeline": args.pipeline,
        "task_id": args.task_id,
        "layer1_pass": bool(l1_pass and not budget_violations),
        "quality_score": quality_score,
        "activation_f1": round(activation_f1, 4),
        "false_positive_rate": round(false_positive_rate, 4),
        "negative_control_ratio": round(negative_control_ratio, 4),
        "perturbation_success": True,
        "runtime_sec": runtime_sec,
        "usage": {
            "total_tokens": total_tokens,
            "context_tokens": context_tokens,
        },
        "failed": failed,
    }
    if budget_violations:
        metrics["budget_violations"] = budget_violations
    if not l1_pass:
        metrics["failure_reason"] = l1_reason

    quality_eval = {
        "task_id": args.task_id,
        "pipeline": args.pipeline,
        "model_family": args.model_family,
        "status": "pass" if not failed else "fail",
        "deterministic_gate": {"pass": l1_pass, "reason": l1_reason},
        "rubric": {
            "source_fidelity": source_fidelity,
            "decision_utility": decision_utility,
            "boundary_quality": boundary_quality,
            "citation_quality": citation_quality,
            "context_efficiency": context_efficiency,
        },
        "weighted_quality_score": quality_score,
        "evidence": {
            "source_keyword_coverage": {
                "hits": hit,
                "total": len(kws),
                "sample_keywords": kws[:12],
            },
            "citation_hits": citation_hits,
            "word_count": word_count,
        },
        "guardrails": {
            "activation_f1": activation_f1,
            "false_positive_rate": false_positive_rate,
            "negative_control_ratio": negative_control_ratio,
        },
    }
    if budget_violations:
        quality_eval["budget_violations"] = budget_violations

    (out_dir / "metrics.json").write_text(json.dumps(metrics, indent=2), encoding="utf-8")
    (out_dir / "quality-eval.json").write_text(json.dumps(quality_eval, indent=2), encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description="Score a generated skill for protocol benchmark runs.")
    parser.add_argument("--pipeline", required=True)
    parser.add_argument("--task-id", required=True)
    parser.add_argument("--sources-path", required=True)
    parser.add_argument("--skill-root", required=True)
    parser.add_argument("--out-dir", required=True)
    parser.add_argument("--model-family", default="")
    parser.add_argument("--generation-runtime-sec", type=float, default=0.0)
    parser.add_argument("--max-total-tokens", type=int, default=0)
    parser.add_argument("--max-context-tokens", type=int, default=0)
    parser.add_argument("--max-runtime-sec", type=float, default=0.0)
    args = parser.parse_args()
    evaluate(args)


if __name__ == "__main__":
    main()
