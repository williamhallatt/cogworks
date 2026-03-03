# Generator-A Protocol Runbook

## Goal
Execute generator-a in true installed-skill mode and produce one generated skill at `skill_out_dir`.

## Inputs
- `task_id`
- `sources_path`
- `out_dir`
- `skill_out_dir`

## Execution Mode
- `skill_installed`

## Required Install Contract
- Install via: `npx skills add vendors/generator-a/skill-creator -a codex -y`
- Required installed skill slug: `skill-creator`

## Required Output
- Generated skill at `skill_out_dir` with `SKILL.md` and `reference.md`
- Benchmark evidence token in generated output:
  - `skill_used: skill-creator`

## Notes
- Primary benchmark signal remains downstream quality of generated artifacts.
- If installation fails or usage evidence is missing, the case is failed.
