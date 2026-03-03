#!/usr/bin/env python3
import argparse
import json
import re
from pathlib import Path


def read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except Exception:
        return ""


def tokenize(text: str):
    return re.findall(r"[a-zA-Z][a-zA-Z0-9_-]{2,}", text.lower())


def jaccard(a: set[str], b: set[str]) -> float:
    if not a or not b:
        return 0.0
    return len(a & b) / len(a | b)


def score(args):
    sources_root = Path(args.sources_path)
    skill_root = Path(args.skill_root)
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    source_text = "\n".join(read(p) for p in sorted(sources_root.rglob("*")) if p.is_file())
    skill_md = read(skill_root / "SKILL.md")
    ref_md = read(skill_root / "reference.md")
    skill_text = f"{skill_md}\n{ref_md}".strip()

    if not skill_text:
        payload = {
            "pipeline": args.pipeline,
            "task_id": args.task_id,
            "status": "fail",
            "reason": "missing skill content",
            "weighted_quality_score": 0.0,
            "rubric": {},
        }
        (out_dir / "quality-eval-v2.json").write_text(json.dumps(payload, indent=2), encoding="utf-8")
        return

    src_tokens = set(tokenize(source_text))
    skill_tokens = set(tokenize(skill_text))
    overlap = jaccard(src_tokens, skill_tokens)

    has_boundary = any(x in skill_text.lower() for x in ["do not", "when not", "avoid", "unless"])
    has_decisions = any(x in skill_text.lower() for x in ["if", "when", "decision", "checklist", "steps"])
    has_frontmatter = skill_md.startswith("---") and "description:" in skill_md
    has_refs = "source" in skill_text.lower() or "reference" in skill_text.lower()

    source_alignment = min(1.0, overlap * 4.0)
    actionability = 1.0 if has_decisions else 0.4
    boundary_rigor = 1.0 if has_boundary else 0.3
    structure = 1.0 if has_frontmatter else 0.2
    evidence = 1.0 if has_refs else 0.4

    weighted = (
        source_alignment * 0.35
        + actionability * 0.25
        + boundary_rigor * 0.20
        + structure * 0.10
        + evidence * 0.10
    )

    payload = {
        "pipeline": args.pipeline,
        "task_id": args.task_id,
        "status": "pass" if has_frontmatter else "fail",
        "weighted_quality_score": round(weighted, 4),
        "rubric": {
            "source_alignment": round(source_alignment * 5.0, 4),
            "actionability": round(actionability * 5.0, 4),
            "boundary_rigor": round(boundary_rigor * 5.0, 4),
            "structure": round(structure * 5.0, 4),
            "evidence": round(evidence * 5.0, 4),
        },
        "evidence": {
            "token_overlap_jaccard": round(overlap, 4),
            "frontmatter": has_frontmatter,
            "boundary_markers": has_boundary,
            "decision_markers": has_decisions,
        },
    }
    (out_dir / "quality-eval-v2.json").write_text(json.dumps(payload, indent=2), encoding="utf-8")


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--pipeline", required=True)
    p.add_argument("--task-id", required=True)
    p.add_argument("--sources-path", required=True)
    p.add_argument("--skill-root", required=True)
    p.add_argument("--out-dir", required=True)
    score(p.parse_args())
