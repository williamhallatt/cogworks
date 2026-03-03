# Pipeline Benchmark Dataset

Manifest: `bench/datasets/pipeline-benchmark/manifest.jsonl`

Each row defines:
- `task_id`
- `sources_path`
- `expected_skill_intent`
- `domain`
- `difficulty`
- `risk_tier`

Use:
- `bench/protocols/protocol-pilot.json` for pilot runs
- `bench/protocols/protocol-hard-v2.json` for full hard-suite runs

Authoritative execution is documented in `RUNBOOK.md`.
