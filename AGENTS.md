# Repository Guidelines

## Related Documentation

- [README.md](README.md) - Project overview and quick start
- [TESTING.md](TESTING.md) - Testing guidelines and framework
- [RELEASES.md](RELEASES.md) - Release process and troubleshooting
- [INSTALL.md](INSTALL.md) - End-user installation instructions
- [ROADMAP.md](ROADMAP.md) - Future feature planning

## Collaboration Principles

- **Save ACCEPTED Plans** - whenever a plan is *accepted*, save it in [_plans/](./_plans/) with a descriptive name and date. This creates a living archive of strategic thinking and decision-making.

## Terminology

- **cogworks** - orchestration workflow for encoding knowledge from multiple sources and encoding it into skills. The workflow supports both Claude and Codex skill generation.
- **agents vs sub-agents** - whenever I use the term `agent` or `agents`, it refers to Claude Code or OpenAI Codex. a `sub-agent` or `sub-agents` refer to a type of specialised tool that Claude Code supports, but that is not available for OpenAI Codex.
- **generated skills** - skills created by the cogworks workflow, which may be deployed to either Claude or Codex.
- **testing cogworks** - the process of validating that the `cogworks` toolchain works for both the Claude Code and Codex pipelines
- **testing skills** - the process of validating that a `generated skill` (the product of the `cogworks` pipelines) works as intended, which may include both deterministic checks and behavioral tests.

## Learned Working Norms

- **Verify provenance claims with artifacts** - when asked whether a workflow/toolchain was used, validate with local evidence first (for example `~/.codex/history.jsonl`, `~/.codex/sessions/...`, run outputs, timestamps) before concluding.
- **Use evidence-backed comparisons** - for Claude-vs-Codex or plan-vs-plan comparisons, provide concrete diffs/metrics and severity-ranked omissions in both directions.
- **Treat cross-pipeline parity as explicit scope** - when the same skill exists under `.claude/skills` and `.agents/skills`, state whether differences are expected platform specialization or likely pipeline drift.
- **Require reproducible evals for quality claims** - claims like “more robust”, “cheaper”, or “higher quality” must be backed by benchmark runs and saved artifacts, not single samples.
- **Standardize benchmark artifacts** - keep machine-readable summaries and human-readable reports for pipeline comparisons (for example `benchmark-summary.json` and `benchmark-report.md`).
- **Report done vs outstanding** - after implementing an accepted plan, explicitly list what was completed and what remains.
- **Treat `_plans/` as historical context, not authority** - derive implementation decisions from current repo artifacts and accepted in-thread decisions, not prior plan files.
- **Enforce prompt-engineering quality through `cogworks-learn`** - keep `*-prompt-engineering` skills as canonical references, and apply their doctrine via integrated gates in `cogworks-learn` during generation.

## Project Structure & Module Organization
- `.claude/agents/` contains the Claude orchestration agent (`cogworks.md`).
- `.claude/skills/cogworks-*/` holds production skills; each skill must include `SKILL.md` plus supporting docs (`reference.md`, `patterns.md`, `examples.md` as needed).
- `.agents/skills/` contains Codex skill workflows.
- `tests/` contains validation assets:
  - `tests/run-black-box-tests.sh` for framework meta-tests.
  - `tests/framework/` for shared deterministic + behavioral + benchmark tooling.
  - `tests/behavioral/` for behavioral cases and traces.
  - `tests/datasets/` for benchmark manifests and golden/control fixtures.
- `_sources/` and `_plans/` are working materials and research artifacts.

## Build, Test, and Development Commands
- `./install.sh` runs interactive installation for Claude/Codex targets.
- `./install.sh --local` installs into project scope (`.claude/` by default).
- `./install.sh --target codex --local` installs Codex skills into `.agents/skills/`.
- `bash tests/run-black-box-tests.sh` runs black-box meta-tests for the test framework.
- `python3 tests/framework/scripts/cogworks-eval.py behavioral run --skill-prefix cogworks-` runs behavioral gates for repo skills.
- `bash scripts/install-git-hooks.sh` installs local git hooks (including docs attestation `commit-msg` validation).
- `bash scripts/validate-docs-attestation.sh --commit HEAD` validates docs attestation trailers on the latest commit.

## Coding Style & Naming Conventions
- Prefer Markdown + Bash clarity: short sections, explicit headings, and executable examples.
- Shell scripts should use strict mode (`set -euo pipefail`) and descriptive function names (`print_success`, `validate_source_archive`).
- Skill directories and slugs use kebab-case (example: `cogworks-learn`, `deployment-workflow-benchmark`).
- Keep `SKILL.md` frontmatter valid YAML with required `name:` and `description:` fields.

## Testing Guidelines
- Treat Layer 1 deterministic checks as the minimum gate for all skill changes.
- For `cogworks-*` updates, run behavioral tests before opening a PR.
- Store traces and fixtures under `tests/behavioral/*/traces/` and test cases as `test-cases.jsonl`.

## Git Rules
- Follow the observed commit format: `<type>/ <summary>` (examples: `add/ ...`, `refactor/ ...`, `docs/ ...`, `chore/ ...`).
- Every commit message must include docs attestation trailers:
  - `Docs-Impact: updated|none|required-followup`
  - `Docs-Updated: <csv-paths>|none`
  - `Docs-Why-None: <text>` (required when `Docs-Impact` is `none` or `required-followup`)
- `Docs-Impact: updated` requires `Docs-Updated` to list one or more docs files.
- `Docs-Impact: none` requires `Docs-Updated: none` and a non-empty `Docs-Why-None`.
- `Docs-Impact: required-followup` requires `Docs-Updated: none` and `Docs-Why-None` must include a follow-up date (`YYYY-MM-DD`) and owner handle (`@name`).
- Keep commits focused by concern (agent, skills, tests, docs).
- PRs targeting `main` that touch `.claude/**`, `README.md`, `INSTALL.md`, or `LICENSE` should pass `.github/workflows/pre-release-validation.yml`.
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
