# Repository Guidelines

## What this repo is

Two advisor skills for authoring agent skills:

- `skills/cogworks-encode/` — synthesis methodology: turn one or more sources on a topic into a decision-first knowledge base
- `skills/cogworks-learn/` — skill-authoring doctrine: structure, package, and validate an agent skill for its target runtime

Both work standalone. Install with `npx skills add williamhallatt/cogworks`. See [README.md](README.md).

## Project structure

- `skills/cogworks-encode/`, `skills/cogworks-learn/` — canonical skill sources; edit here directly
- `_sources/` — research material (Agent Skills spec + docs snapshot from agentskills.io); do not auto-load, consult only when a task explicitly calls for reference material

## Live-edit hazard

Editing a `SKILL.md` while operating under that skill's instructions puts the session in a circular / inconsistent state. When editing any `skills/cogworks-*/SKILL.md`, don't invoke that skill during the session. If you invoke a skill you're editing by accident, restart or verify the in-memory instructions still match the current file.

## Coding style

- Skill directories and slugs use kebab-case
- `SKILL.md` frontmatter is valid YAML with required `name:` and `description:` fields

## Git

- Commit format: `<type>/ <summary>` — `add/`, `fix/`, `refactor/`, `docs/`, `chore/`, `release/`
- Stage explicit paths, not `git add .`
- Never touch `.env`
- Never run destructive git operations (`git reset --hard`, `git push --force`, tag deletion of published tags, `git checkout` to an older commit) without an explicit written instruction from the user in the current conversation
- Never amend commits without explicit approval
