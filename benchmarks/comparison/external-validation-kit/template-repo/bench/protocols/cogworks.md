# Cogworks Protocol Runbook

## Goal
Generate a skill from a benchmark task source bundle using the **installed cogworks skill** and write output to a deterministic path for scoring.

## Inputs
- `task_id`
- `sources_path`
- `out_dir`
- `skill_out_dir` (default: `{out_dir}/generated-skill`)

## Execution Mode
- `skill_installed`

## Required Install Contract
- Install via: `npx skills add vendors/cogworks -a codex -y`
- Required installed skill slug: `cogworks`

## Required Output
- Generated skill rooted at `skill_out_dir` with `SKILL.md` and `reference.md`
- Benchmark evidence token in generated output:
  - `skill_used: cogworks`

## Notes
- The protocol runner handles scoring and metrics emission after generation.
- If installation fails or usage evidence is missing, the case is failed.
