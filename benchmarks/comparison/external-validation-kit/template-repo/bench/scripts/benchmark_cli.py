#!/usr/bin/env python3
import argparse
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

import pipeline_benchmark as pb  # noqa: E402


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Benchmark CLI")
    sub = parser.add_subparsers(dest="command", required=True)

    scaffold = sub.add_parser("scaffold", help="Scaffold benchmark layout")
    scaffold.add_argument("--manifest", default="bench/datasets/pipeline-benchmark/manifest.jsonl")
    scaffold.add_argument("--results-root", default="bench/results/pipeline-benchmark")
    scaffold.add_argument("--run-id", required=True)
    scaffold.add_argument("--repeats", type=int, default=1)
    scaffold.add_argument("--variant", action="append", default=[])
    scaffold.add_argument("--pipeline", action="append", default=[])
    scaffold.add_argument("--force", action="store_true")
    scaffold.set_defaults(func=pb.scaffold_layout)

    run = sub.add_parser("run", help="Execute benchmark commands")
    run.add_argument("--manifest", default="bench/datasets/pipeline-benchmark/manifest.jsonl")
    run.add_argument("--results-root", default="bench/results/pipeline-benchmark")
    run.add_argument("--run-id", required=True)
    run.add_argument("--repeats", type=int, default=1)
    run.add_argument("--variant", action="append", default=[])
    run.add_argument("--pipeline", action="append", default=[])
    run.add_argument("--command-template", action="append", default=[])
    run.add_argument("--cwd", default=None)
    run.add_argument("--dry-run", action="store_true")
    run.add_argument("--force", action="store_true")
    run.set_defaults(func=pb.run_benchmark)

    summarize = sub.add_parser("summarize", help="Summarize benchmark")
    summarize.add_argument("--manifest", default="bench/datasets/pipeline-benchmark/manifest.jsonl")
    summarize.add_argument("--results-root", default="bench/results/pipeline-benchmark")
    summarize.add_argument("--run-id", required=True)
    summarize.add_argument("--pipeline", action="append", default=[])
    summarize.add_argument("--output-json", default=None)
    summarize.add_argument("--output-md", default=None)
    summarize.set_defaults(func=pb.summarize_benchmark)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    if not args.pipeline:
        args.pipeline = ["cogworks", "generator-a", "generator-b"]
    if hasattr(args, "variant") and not args.variant:
        args.variant = ["clean"]
    if getattr(args, "output_json", None) is None:
        args.output_json = f"{args.results_root}/{args.run_id}/benchmark-summary.json"
    if getattr(args, "output_md", None) is None:
        args.output_md = f"{args.results_root}/{args.run_id}/benchmark-report.md"

    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
