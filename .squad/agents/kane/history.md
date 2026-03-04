# Kane — History & Learnings

## Project Context

**Project:** cogworks — knowledge encoding pipeline for AI agent skills  
**Repo:** `/home/williamh/code/cogworks`  
**User:** William Hallatt  
**Mission:** Maintain and harden the cogworks knowledge encoding pipeline — a toolchain
that encodes knowledge from multiple sources into deployable skill artifacts for AI agents.

**Tech stack:**
- Skill format: Markdown/YAML (`SKILL.md` with frontmatter)
- Pipeline orchestration: Bash scripts (`scripts/`)
- Test harness: Python (`tests/framework/scripts/cogworks-eval.py`)
- Distribution: Node.js / `npx skills add williamhallatt/cogworks`
- Agent targets: Claude Code, GitHub Copilot, Cursor, OpenAI Codex

**Key files:**
- `skills/cogworks/SKILL.md` — orchestration skill
- `skills/cogworks-encode/SKILL.md` — multi-source encoding skill
- `skills/cogworks-learn/SKILL.md` — skill creation/revision skill
- `tests/behavioral/` — behavioral test cases and traces
- `tests/framework/` — shared deterministic + behavioral + benchmark tooling
- `tests/datasets/recursive-round/` — recursive round runbook and manifests
- `_generated-skills/` — staging directory for generated skill artifacts
- `docs/cogworks-agent-risk-analysis.md` — risk analysis reference
- `AGENTS.md`, `CLAUDE.md`, `TESTING.md` — contributor guidance

**Current team:** Ripley (Lead), Ash (Security), Dallas (Pipeline), Hudson (Test),
Lambert (Compatibility), Scribe, Ralph

## Learnings

<!-- Kane appends learnings here as work progresses -->
