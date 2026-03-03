# Generator-B Protocol Runbook

## Goal
Execute generator-b via protocol prompt fallback and produce one generated skill at `skill_out_dir`.

## Inputs
- `task_id`
- `sources_path`
- `out_dir`
- `skill_out_dir`

## Execution Mode
- `protocol_prompt` (fallback)

## Notes
- This pipeline is currently not treated as an installable single benchmark skill package.
- Results are reported separately from `skill_installed` pipelines.
- Skill-quality superiority claims should not be made from `protocol_prompt` mode alone.
