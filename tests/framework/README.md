# Cogworks Test Framework

Unified testing framework for both Claude and Codex pipelines.

Canonical recursive round runbook: `tests/datasets/recursive-round/README.md`

## Scope

This framework supports two test tracks:

- Layer 1 deterministic checks for generated skills
- Behavioral activation tests

## Primary Commands

Generated skill tests:

```bash
bash scripts/test-generated-skill.sh --skill-path .claude/skills/my-skill
bash scripts/test-generated-skill.sh --skill-path .agents/skills/my-skill --with-behavioral
```

Recursive TDD round:

```bash
source scripts/recursive-env.example.sh
bash scripts/run-recursive-round.sh \
  --round-manifest tests/datasets/recursive-round/round-manifest.local.json \
  --mode fast \
  --run-id rr-20260220-fast1
```

## Advanced CLI

```bash
python3 tests/framework/scripts/cogworks-eval.py behavioral run --skill-prefix cogworks-
python3 tests/framework/scripts/cogworks-eval.py behavioral run --skill-prefix cogworks- --strict-provenance
bash scripts/run-trigger-smoke-tests.sh claude
bash scripts/run-trigger-smoke-tests.sh codex
```

## Framework Layout

```text
tests/framework/
├── graders/
│   └── deterministic-checks.sh
├── scripts/
│   ├── behavioral_lib.py
│   ├── capture_behavioral_trace.py
│   └── cogworks-eval.py
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

Key strict-mode fields:
- `activation_source` (`skill_tool` required for positive cases in strict provenance mode)
- `tool_events` (ordered tool timeline for `order_assertions`)

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
