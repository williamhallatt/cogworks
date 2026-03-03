# Generator-A Protocol Runbook

## Deep-Dive Summary
`generator-a` (`skill-creator`) is a workflow toolkit for skill authoring and trigger optimization, not a one-shot source-to-skill CLI.

Relevant components include:
- `scripts/run_eval.py` (trigger eval)
- `scripts/run_loop.py` (description optimization loop)
- `scripts/quick_validate.py` and `scripts/package_skill.py`

## Goal
Execute generator-a workflow via Codex protocol steps and materialize one generated skill at `skill_out_dir`.

## Inputs
- `task_id`
- `sources_path`
- `out_dir`
- `skill_out_dir`

## Required Output
- Generated skill at `skill_out_dir` with `SKILL.md`

## Real-Mode Command Contract
Provide a command template that can run non-interactively:
- `{task_id}` `{sources_path}` `{out_dir}` `{skill_out_dir}`

Example shape:
```bash
bash benchmarks/comparison/comparators/generator-a/skill-creator/scripts/your-runner.sh '{task_id}' '{sources_path}' '{skill_out_dir}'
```

## Notes
- Internal trigger metrics are not treated as primary benchmark signal.
- Primary signal is downstream task-output quality from the generated skill.
