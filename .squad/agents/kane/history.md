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

### 2026-03-05: Charter Upskill from Synthesis Findings

**Task:** Internalized agent skills synthesis findings into Kane's charter and encoded 10 gaps + 5 priority recommendations as reusable skill.

**What changed:**
- **Charter update:** Expanded `## AI & Agent Expertise` section with specific, actionable knowledge from synthesis — replaced vague bullet points with concrete patterns (activation guards, subagent configuration, tool contracts, context budget numbers, parallel execution rules, quality gates)
- **Skill creation:** `.squad/skills/product-gaps-cogworks/SKILL.md` created to encode product gaps as decision-support for roadmap work — includes what's missing, why it matters, what done looks like, priority recommendations, and roadmap considerations

**Key additions to charter:**
- Skills Architecture: frontmatter fields, discovery priority, context budget (2% window/16K fallback), activation guards, dynamic injection syntax
- Sub-Agent Patterns: built-in types (Explore/Plan/General-purpose), context isolation contracts, foreground vs background modes, memory scope paths, preloaded skills behavior
- Context Management: CLAUDE.md vs Auto Memory (full file vs first 200 lines), multi-context workflows (JSON/text/git/init.sh), when to `/clear`
- Prompt Engineering (Claude): explicit > implicit, examples taken literally in 4.x, extended thinking (adaptive), parallel tool execution (3-5x speedup), reversibility guardrails
- Prompt Engineering (Codex): autonomy principle, reasoning effort calibration, tool contracts (`apply_patch`, `update_plan`), output compactness rules
- Cross-Agent Compatibility: invocation syntax, `$ARGUMENTS` interpolation status (Claude ✅, Copilot 🟡 undefined, others ❓), compatibility labeling system
- Evaluation: activation testing criteria, ground truth metrics, behavioral eval for non-determinism, evaluation flywheel pattern, cogworks quality gates (M11/D3/D4/D8/D21)
- cogworks Pipeline: security guards (M2/M9), pipeline guards (M5/M11/D3/D7/D9), quality calibration (D4 inversion gate)

**Product knowledge now operationalized:** Kane can reference specific context budget numbers, exact tool contracts, concrete activation guard patterns, priority-ranked gaps with effort estimates—senior practitioner working knowledge, not job description abstractions.
