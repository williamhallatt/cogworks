# Cogworks Protocol Runbook

## Goal
Generate a skill from a benchmark task source bundle using cogworks and write output to a deterministic path for scoring.

## Inputs
- `task_id`
- `sources_path`
- `out_dir`
- `skill_out_dir` (default: `{out_dir}/generated-skill`)

## Required Output
- Generated skill rooted at `skill_out_dir` with `SKILL.md`

## Real-Mode Command Contract
Provide a generation command template that accepts placeholders:
- `{task_id}`
- `{sources_path}`
- `{out_dir}`
- `{skill_out_dir}`

Example shape:
```bash
bash benchmarks/comparison/scripts/your-cogworks-runner.sh '{task_id}' '{sources_path}' '{skill_out_dir}'
```

## Notes
- The protocol runner handles scoring and metrics emission after generation.
- If generation fails or no `SKILL.md` is produced, the run is marked invalid.
