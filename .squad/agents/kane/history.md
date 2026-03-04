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

### 2026-03-05: Agent Skills & Prompt Engineering Source Audit

**Task:** Synthesized 13 Tier 1 sources on agent skills, sub-agents, and prompt engineering into `_sources/kane-synthesis-agent-skills.md`.

**Most useful files:**
1. `_sources/cc-docs/skills.md` — Definitive skills architecture (discovery, frontmatter, composition)
2. `_sources/cc-docs/sub-agents.md` — Subagent patterns, context isolation, configuration
3. `_sources/prompting/claude/prompting-best-practice.md` — Claude 4.x specific guidance (Opus 4.6, adaptive thinking)
4. `_sources/prompting/codex/codex-prompting-guide.md` — Codex autonomy patterns, tool implementations
5. `_sources/cc-docs/best-practices.md` — Context management as fundamental constraint

**High-confidence cross-source patterns (appeared in 2+ sources):**
- Context window as fundamental constraint → subagents for isolation
- Parallel tool execution (3-5x speedup for file-heavy operations)
- Explicit > implicit (clear instructions outperform vague hints)
- Examples shape behavior (few-shot learning across all models)
- Verification > trust (self-verification dramatically improves accuracy)
- State management for long tasks (JSON for structure, text for notes, git for history)

**Key gaps identified in cogworks:**
1. **No activation testing** — skills may have great content but poor invocation precision
2. **No cross-agent compatibility validation** — skills generated for Claude Code untested on Copilot/Cursor/Codex
3. **No parallel tool use guidance** — generated skills don't leverage 3-5x speedup from parallelization
4. **No subagent orchestration** — pipeline doesn't encode context isolation patterns
5. **No multi-context window state management** — skills don't teach persistence across context transitions
6. **No evaluation flywheel** — one-shot generation, no iterative refinement
7. **Codex-specific patterns not encoded** — `apply_patch`, `update_plan`, compaction patterns missing
8. **No prompt caching optimization** — generated skills have poor latency/cost profile
9. **No security injection scanning** — skill bodies not scanned for injection vulnerabilities
10. **No guidance on when NOT to use skills** — missing trade-off matrix (skills vs. CLAUDE.md vs. hooks)

**Top 3 product gaps (priority order):**
1. **Activation testing** — without it, we're shipping skills that may never trigger correctly
2. **Parallel tool use** — 3-5x performance improvement for free; appears in both Claude and Codex best practices
3. **Evaluation flywheel integration** — one-shot generation produces brittle skills; eval-driven refinement creates resilient ones
