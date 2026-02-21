# Cogworks Test Framework

Unified testing framework for both Claude and Codex pipelines.

Canonical recursive round runbook: `tests/datasets/recursive-round/README.md`

## Scope

This framework supports three test tracks:

- Layer 1 deterministic checks for generated skills
- Behavioral activation tests
- Cross-pipeline A/B benchmark (Claude vs Codex)

Removed from baseline:

- `cogworks-test` skill abstraction
- LLM-judge conversational grading
- Calibration CLI and leakage CLI
- Efficacy benchmark CLI

## Primary Commands

Generated skill tests:

```bash
bash scripts/test-generated-skill.sh --skill-path .claude/skills/my-skill
bash scripts/test-generated-skill.sh --skill-path .agents/skills/my-skill --with-behavioral
```

Pipeline benchmark:

```bash
bash scripts/test-cogworks-pipeline.sh --mode offline --run-id 20260220-ab1
```

Recursive TDD round:

```bash
source scripts/recursive-env.example.sh
bash scripts/run-recursive-round.sh \
  --round-manifest tests/datasets/recursive-round/round-manifest.local.json \
  --mode fast \
  --run-id rr-20260220-fast1
```

Real benchmark mode:

```bash
export COGWORKS_BENCH_CLAUDE_CMD="your-claude-runner --sources '{sources_path}' --out '{out_dir}'"
export COGWORKS_BENCH_CODEX_CMD="your-codex-runner --sources '{sources_path}' --out '{out_dir}'"
bash scripts/test-cogworks-pipeline.sh --mode real --run-id 20260220-ab1
```

## Advanced CLI

```bash
python3 tests/framework/scripts/cogworks-eval.py behavioral run --skill-prefix cogworks-
python3 tests/framework/scripts/cogworks-eval.py behavioral run --skill-prefix cogworks- --strict-provenance
python3 tests/framework/scripts/cogworks-eval.py pipeline-benchmark scaffold --run-id 20260220-ab1
python3 tests/framework/scripts/cogworks-eval.py pipeline-benchmark run --run-id 20260220-ab1 \
  --command-template "claude::./scripts/run-claude-benchmark.sh '{sources_path}' '{out_dir}'" \
  --command-template "codex::./scripts/run-codex-benchmark.sh '{sources_path}' '{out_dir}'"
python3 tests/framework/scripts/cogworks-eval.py pipeline-benchmark summarize --run-id 20260220-ab1
```

## Framework Layout

```text
tests/framework/
├── graders/
│   └── deterministic-checks.sh
├── scripts/
│   ├── behavioral_lib.py
│   ├── capture_behavioral_trace.py
│   ├── cogworks-eval.py
│   └── pipeline_benchmark.py
└── templates/
    ├── behavioral-test-case-template.jsonl
    └── behavioral-trace-template.json
```

## Trace Capture

Normalize raw harness output to the behavioral trace contract:

```bash
bash scripts/capture-behavioral-trace-claude.sh <case_id> <skill_slug> <raw_trace.json> <out_trace.json>
bash scripts/capture-behavioral-trace-codex.sh <case_id> <skill_slug> <raw_trace.json> <out_trace.json>
```

Refresh + strict-validate all behavioral traces:

```bash
export COGWORKS_BEHAVIORAL_CLAUDE_REAL_CMD="bash scripts/run-behavioral-case-claude.sh '{skill_slug}' '{case_id}' '{case_json_path}' '{raw_trace_path}'"
export COGWORKS_BEHAVIORAL_CODEX_REAL_CMD="bash scripts/run-behavioral-case-codex.sh '{skill_slug}' '{case_id}' '{case_json_path}' '{raw_trace_path}'"
export COGWORKS_BEHAVIORAL_CLAUDE_CAPTURE_CMD="bash scripts/behavioral-capture-claude.sh '{skill_slug}' '{case_id}' '{case_json_path}' '{raw_trace_path}'"
export COGWORKS_BEHAVIORAL_CODEX_CAPTURE_CMD="bash scripts/behavioral-capture-codex.sh '{skill_slug}' '{case_id}' '{case_json_path}' '{raw_trace_path}'"
bash scripts/refresh-behavioral-traces.sh --mode all
```

Or load defaults:

```bash
source scripts/behavioral-env.example.sh
```

Prerequisites:
- authenticated `claude` and `codex` CLIs
- backend network connectivity during capture

Troubleshooting:
- check raw event streams in `/tmp/cogworks-behavioral-raw/<skill_slug>/`
- if either pipeline exits non-zero, refresh stops before trace normalization
