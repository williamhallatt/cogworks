# Repository Guidelines

## Project Structure & Module Organization
- `.claude/agents/` contains the Claude orchestration agent (`cogworks.md`).
- `.claude/skills/cogworks-*/` holds production skills; each skill must include `SKILL.md` plus supporting docs (`reference.md`, `patterns.md`, `examples.md` as needed).
- `.agents/skills/` contains Codex skill workflows.
- `tests/` contains validation assets:
  - `tests/run-black-box-tests.sh` for framework meta-tests.
  - `tests/behavioral/` for behavioral cases and traces.
  - `tests/datasets/` for golden samples, efficacy benchmarks, and controls.
- `_sources/` and `_plans/` are working materials and research artifacts.

## Build, Test, and Development Commands
- `./install.sh` runs interactive installation for Claude/Codex targets.
- `./install.sh --local` installs into project scope (`.claude/` by default).
- `./install.sh --target codex --local` installs Codex skills into `.agents/skills/`.
- `bash tests/run-black-box-tests.sh` runs black-box meta-tests for the test framework.
- `python3 .claude/test-framework/scripts/cogworks-test-framework.py behavioral run --skill-prefix cogworks-` runs behavioral gates for repo skills.

## Coding Style & Naming Conventions
- Prefer Markdown + Bash clarity: short sections, explicit headings, and executable examples.
- Shell scripts should use strict mode (`set -euo pipefail`) and descriptive function names (`print_success`, `validate_source_archive`).
- Skill directories and slugs use kebab-case (example: `cogworks-learn`, `deployment-workflow-benchmark`).
- Keep `SKILL.md` frontmatter valid YAML with required `name:` and `description:` fields.

## Testing Guidelines
- Treat Layer 1 deterministic checks as the minimum gate for all skill changes.
- For `cogworks-*` updates, run behavioral tests before opening a PR.
- Store traces and fixtures under `tests/behavioral/*/traces/` and test cases as `test-cases.jsonl`.

## Commit & Pull Request Guidelines
- Follow the observed commit format: `<type>/ <summary>` (examples: `add/ ...`, `refactor/ ...`, `docs/ ...`, `chore/ ...`).
- Keep commits focused by concern (agent, skills, tests, docs).
- PRs targeting `main` that touch `.claude/**`, `README.md`, `INSTALL.md`, or `LICENSE` should pass `.github/workflows/pre-release-validation.yml`.
- In PR descriptions, include: scope, affected paths, test commands run, and representative output snippets for failures/fixes.
