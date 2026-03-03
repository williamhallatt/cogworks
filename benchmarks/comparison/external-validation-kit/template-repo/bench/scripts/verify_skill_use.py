#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


def read_json(path: Path) -> dict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return ""


def main() -> int:
    parser = argparse.ArgumentParser(description="Verify installed-skill usage evidence")
    parser.add_argument("--protocol", required=True)
    parser.add_argument("--pipeline", required=True)
    parser.add_argument("--out-dir", required=True)
    parser.add_argument("--skill-root", required=True)
    parser.add_argument("--mode", default="real")
    args = parser.parse_args()

    out_dir = Path(args.out_dir)
    skill_root = Path(args.skill_root)
    cfg = read_json(Path(args.protocol))
    pl = cfg.get("pipelines", {}).get(args.pipeline, {})

    execution_mode = pl.get("execution_mode", "protocol_prompt")
    skill_invocation = pl.get("skill_invocation", {}) if isinstance(pl.get("skill_invocation"), dict) else {}
    required_slug = str(skill_invocation.get("required_skill_slug", "")).strip()
    markers = [str(x) for x in skill_invocation.get("evidence_markers", [])]

    install_report = read_json(out_dir / "skill-install-report.json")

    payload = {
        "pipeline": args.pipeline,
        "execution_mode": execution_mode,
        "mode": args.mode,
        "required_skill_slug": required_slug,
        "evidence_markers": markers,
        "matched_markers": [],
        "install_success": bool(install_report.get("success", False)),
        "proof_token_present": False,
        "status": "skipped",
        "reason": "pipeline is not skill_installed",
        "pass": True,
    }

    if args.mode == "offline":
        payload.update({"status": "skipped-offline", "reason": "offline mode smoke run", "pass": True})
        (out_dir / "skill-use-evidence.json").write_text(json.dumps(payload, indent=2), encoding="utf-8")
        return 0

    if execution_mode != "skill_installed":
        (out_dir / "skill-use-evidence.json").write_text(json.dumps(payload, indent=2), encoding="utf-8")
        return 0

    log_blob = "\n".join(
        [
            read_text(out_dir / "logs" / "generation.stdout.log"),
            read_text(out_dir / "logs" / "generation.stderr.log"),
            read_text(out_dir / "skill-install.stdout.log"),
            read_text(out_dir / "skill-install.stderr.log"),
        ]
    )

    for marker in markers:
        if marker and marker in log_blob:
            payload["matched_markers"].append(marker)

    combined_skill = "\n".join(
        [
            read_text(skill_root / "SKILL.md"),
            read_text(skill_root / "reference.md"),
            read_text(skill_root / "examples.md"),
            read_text(skill_root / "patterns.md"),
        ]
    )

    proof_token = f"skill_used: {required_slug}" if required_slug else ""
    payload["proof_token_present"] = bool(proof_token and proof_token in combined_skill)

    if not payload["install_success"]:
        payload.update({"status": "fail", "reason": "skill install failed", "pass": False})
    elif markers and len(payload["matched_markers"]) < len(markers):
        payload.update({"status": "fail", "reason": "missing required evidence markers", "pass": False})
    elif required_slug and not payload["proof_token_present"]:
        payload.update({"status": "fail", "reason": "missing required skill proof token in generated artifact", "pass": False})
    else:
        payload.update({"status": "pass", "reason": "evidence requirements satisfied", "pass": True})

    (out_dir / "skill-use-evidence.json").write_text(json.dumps(payload, indent=2), encoding="utf-8")
    return 0 if payload["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
