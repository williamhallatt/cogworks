# Generator-B Protocol Runbook

## Deep-Dive Summary
`generator-b` (`skill-factory`) is a process/documentation framework for creating skills into `output_skills/`, not a standardized benchmark CLI.

## Goal
Execute generator-b process via Codex protocol and produce one generated skill at `skill_out_dir`.

## Inputs
- `task_id`
- `sources_path`
- `out_dir`
- `skill_out_dir`

## Required Output
- Generated skill at `skill_out_dir` with `SKILL.md`

## Real-Mode Command Contract
Provide a command template with placeholders:
- `{task_id}` `{sources_path}` `{out_dir}` `{skill_out_dir}`

Example shape:
```bash
bash benchmarks/comparison/comparators/generator-b/skill-factory/scripts/your-runner.sh '{task_id}' '{sources_path}' '{skill_out_dir}'
```

## Notes
- Existing `skills` and `update-docs` scripts are management/fetch helpers, not task benchmark runners.
- Benchmark fairness is enforced by protocol manifest model/budget settings.
