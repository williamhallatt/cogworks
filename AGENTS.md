# Repository Guidelines

## Related Documentation

- [README.md](README.md) - Project overview and quick start
- [TESTING.md](TESTING.md) - Testing guidelines and framework
- [CONTRIBUTIONS.md](CONTRIBUTIONS.md) - Development setup, conventions, and release process
- [INSTALL.md](INSTALL.md) - End-user installation instructions

## Collaboration Principles

- **Save ACCEPTED Plans** - whenever a plan is *accepted*, save it in [_plans/](./_plans/) with a descriptive name and date. This creates a living archive of strategic thinking and decision-making.
- **Archive plans on close** - when a plan is accepted and its work completed, extract its core decision into `_plans/DECISIONS.md`, move the plan to `_plans/archive/`, and update the `audited_through` date. These three steps are atomic — archiving without extracting is not a close.

## The Expert Subtraction Principle

**Core Philosophy:** Experts are systems thinkers who leverage their extensive knowledge and deep understanding to reduce complexity. Novices add. Experts subtract until nothing superfluous remains.

**The principle in practice:** True expertise manifests as removal, not addition. The expert's value is knowing what to leave out. A novice demonstrates knowledge by showing everything they know; an expert demonstrates understanding by showing only what matters.

## Terminology

- **cogworks** - orchestration workflow for encoding knowledge from multiple sources and encoding it into skills. Distributed via `npx skills add williamhallatt/cogworks`.
- **agents** - refers to Claude Code, OpenAI Codex, GitHub Copilot, Cursor, or any agent supporting the Agent Skills standard.
- **generated skills** - skills created by the cogworks workflow, deployable to any compatible agent.
- **testing cogworks** - the process of validating that the `cogworks` toolchain works correctly.
- **testing skills** - the process of validating that a `generated skill` (the product of the `cogworks` pipeline) works as intended, which may include both deterministic checks and behavioral tests.

## Learned Working Norms

- **Verify provenance claims with artifacts** - when asked whether a workflow/toolchain was used, validate with local evidence first (for example run outputs, timestamps) before concluding.
- **Use evidence-backed comparisons** - for comparisons, provide concrete diffs/metrics and severity-ranked omissions in both directions.
- **Require reproducible evals for quality claims** - claims like "more robust", "cheaper", or "higher quality" must be backed by benchmark runs and saved artifacts, not single samples.
- **Standardize benchmark artifacts** - keep machine-readable summaries and human-readable reports for comparisons (for example `benchmark-summary.json` and `benchmark-report.md`).
- **Report done vs outstanding** - after implementing an accepted plan, explicitly list what was completed and what remains.
- **`DECISIONS.md` is the agent context surface for `_plans/`** — load `_plans/DECISIONS.md` for settled decisions; check `_plans/*.md` (root only) for active in-flight plans; treat `_plans/archive/` as human-readable history only.
- **Enforce prompt-engineering quality through `cogworks-learn`** - keep `*-prompt-engineering` skills as canonical references, and apply their doctrine via integrated gates in `cogworks-learn` during generation.
- **Use one canonical recursive runbook** - for recursive TDD rounds, treat `tests/datasets/recursive-round/README.md` as the source of truth for commands and artifact expectations.

## Project Structure & Module Organization
- `skills/` at repo root contains all skills — the canonical source discovered by `npx skills add`.
- `.claude/skills/` and `.agents/skills/` contains symlinks to `skills/` for local Claude Code development.
- `tests/` contains validation assets:
  - `tests/run-black-box-tests.sh` for framework meta-tests.
  - `tests/framework/` for shared deterministic + behavioral + benchmark tooling.
  - `tests/behavioral/` for behavioral cases and traces.
  - `tests/datasets/` for benchmark manifests and golden/control fixtures.
- `_generated-skills/` is the neutral staging directory for skills produced by `cogworks encode`, installed to agents via `npx skills add`.
- `_sources/` and `_plans/` are working materials and research artifacts.

### ⚠️ Auto-Loading & Live-Edit Hazard
- `.claude/skills/` and `.agents/skills/` contains symlinks to `skills/cogworks/SKILL.md`, `skills/cogworks-encode/SKILL.md`, and `skills/cogworks-learn/SKILL.md` — any agent that auto-loads these skills is running under live instructions from those files.
- Editing a `skills/cogworks*/SKILL.md` file immediately changes the instructions for every session currently reading it via the symlink — there is no staging buffer.
- An agent that is both operating under a skill's instructions and editing that skill's `SKILL.md` is in circular/inconsistent state.
- **Convention:** when editing any `skills/cogworks*/SKILL.md`, note it at the top of your session and do not invoke the skill you are editing during that session.
- **Convention:** if you accidentally invoke a skill while editing it, treat the session as potentially corrupted — restart, or carefully verify that the instructions in memory still match the file on disk.
- **`.github/agents/squad.agent.md` is auto-loaded by GitHub Copilot** — this file is 1,000+ lines and will consume a significant portion of your context window on every Copilot session. For non-Squad work, run `/clear` after session start or use a scoped workspace that excludes `.github/agents/`.

## Build, Test, and Development Commands
- `npx skills add williamhallatt/cogworks` installs skills to detected agents.
- `npx skills add . -a claude-code -y` installs from local repo for development.
- `bash tests/run-black-box-tests.sh` runs black-box meta-tests for the test framework.
- `python3 tests/framework/scripts/cogworks-eval.py behavioral scaffold --skill <slug>` scaffolds behavioral test cases for new skills. *(Behavioral evaluation pending reconstruction — D-022/D-023)*
- `bash scripts/run-recursive-round.sh --round-manifest tests/datasets/recursive-round/round-manifest.local.json --mode fast` runs a fast recursive round.
- `bash scripts/validate-recursive-docs.sh` validates recursive workflow docs consistency.

## Coding Style & Naming Conventions
- Prefer Markdown + Bash clarity: short sections, explicit headings, and executable examples.
- Shell scripts should use strict mode (`set -euo pipefail`) and descriptive function names (`print_success`, `validate_source_archive`).
- Skill directories and slugs use kebab-case (example: `cogworks-learn`, `deployment-workflow-benchmark`).
- Keep `SKILL.md` frontmatter valid YAML with required `name:` and `description:` fields.

## Testing Guidelines
- Treat Layer 1 deterministic checks as the minimum gate for all skill changes.
- For `cogworks-*` updates, run Layer 1 checks before opening a PR. *(Layer 2 behavioral evaluation pending reconstruction — D-022/D-023. See `.squad/agents/parker/charter.md`.)*
- Store behavioral test cases under `tests/behavioral/*/test-cases.jsonl` and new skill source materials under `_sources/`.

## Git Rules
- Follow the observed commit format: `<type>/ <summary>` (examples: `add/ ...`, `refactor/ ...`, `docs/ ...`, `chore/ ...`).
- Keep commits focused by concern (skills, tests, docs).
- PRs targeting `main` that touch `skills/**`, `.claude/**`, `README.md`, `INSTALL.md`, or `LICENSE` should pass `.github/workflows/pre-release-validation.yml`.
- In PR descriptions, include: scope, affected paths, test commands run, and representative output snippets for failures/fixes.
- Delete unused or obsolete files when your changes make them irrelevant (refactors, feature removals, etc.), and revert files only when the change is yours or explicitly requested. If a git operation leaves you unsure about other agents' in-flight work, stop and coordinate instead of deleting.
- **Before attempting to delete a file to resolve a local type/lint failure, stop and ask the user.** Other agents are often editing adjacent files; deleting their work to silence an error is never acceptable without explicit approval.
- NEVER edit `.env` or any environment variable files—only the user may change them.
- Coordinate with other agents before removing their in-progress edits—don't revert or delete work you didn't author unless everyone agrees.
- Moving/renaming and restoring files is allowed.
- ABSOLUTELY NEVER run destructive git operations (e.g., `git reset --hard`, `rm`, `git checkout`/`git restore` to an older commit) unless the user gives an explicit, written instruction in this conversation. Treat these commands as catastrophic; if you are even slightly unsure, stop and ask before touching them. *(When working within Cursor or Codex Web, these git limitations do not apply; use the tooling's capabilities as needed.)*
- Never use `git restore` (or similar commands) to revert files you didn't author—coordinate with other agents instead so their in-progress work stays intact.
- Always double-check git status before any commit
- Keep commits atomic: commit only the files you touched and list each path explicitly. For tracked files run `git commit -m "<scoped message>" -- path/to/file1 path/to/file2`. For brand-new files, use the one-liner `git restore --staged :/ && git add "path/to/file1" "path/to/file2" && git commit -m "<scoped message>" -- path/to/file1 path/to/file2`.
- Quote any git paths containing brackets or parentheses (e.g., `src/app/[candidate]/**`) when staging or committing so the shell does not treat them as globs or subshells.
- When running `git rebase`, avoid opening editors—export `GIT_EDITOR=:` and `GIT_SEQUENCE_EDITOR=:` (or pass `--no-edit`) so the default messages are used automatically.
- Never amend commits unless you have explicit written approval in the task thread.
