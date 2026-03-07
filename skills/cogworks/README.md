# Cogworks User Guide

Cogworks transforms URLs and files into invokable agent skills through systematic synthesis. You provide sources, choose either the default legacy engine or the opt-in agentic engine, and cogworks outputs a skill package that compatible agents can auto-discover and invoke.

## The Three Skills

Cogworks installs as three focused skills that work together:

| Skill | Purpose | Invocation (Claude Code / Codex CLI) |
|-------|---------|--------------------------------------|
| **cogworks** | Orchestrator — runs the full end-to-end workflow | `/cogworks encode ...` / `$cogworks encode ...` |
| **cogworks-encode** | Synthesis expertise — the 8-phase process for analysing and combining sources | `/cogworks-encode ...` / `$cogworks-encode ...` |
| **cogworks-learn** | Skill-writing expertise — SKILL.md structure, frontmatter, quality gates | `/cogworks-learn ...` / `$cogworks-learn ...` |

**How they relate:** `/cogworks` (or `$cogworks` on Codex CLI) orchestrates the complete pipeline and delegates to cogworks-encode (for synthesis) and cogworks-learn (for skill generation). The two supporting skills are also usable independently when you only need part of the pipeline.

## Execution Engines

Cogworks supports two execution engines:

- **Legacy** — the existing prompt-orchestrated pipeline. This remains the default.
- **Agentic** — an opt-in simplified stage-driven pipeline that uses a coordinator and selective specialist roles. The runtime uses canonical role profiles plus surface-specific bindings: Claude Code binds them to repo-local agent files under `.claude/agents/`, while GitHub Copilot CLI uses inline bindings derived from the same canonical role specs. Surfaces without native subagents fall back honestly to degraded single-agent execution while preserving the same five-stage graph.

Both engines still generate portable skills into `_generated-skills/` by default.

## Quick Start

> **Note:** The skill prefix is agent-specific. Examples use `/` (Claude Code) and `$` (Codex CLI). Other agents may use a different prefix — consult your agent's documentation.

Start your agent in your project directory and run:

```text
# Claude Code
/cogworks encode <sources>

# Codex CLI
$cogworks encode <sources>
```

Where `<sources>` can be URLs, local files, directories, or files containing URLs.

### Example: encode from a URL

```text
# Claude Code
/cogworks encode https://example.com/some-guide

# Codex CLI
$cogworks encode https://example.com/some-guide
```

Cogworks will:
1. fetch or read the source material
2. generate a slug from the topic
3. synthesize the content
4. present a summary for your review
5. on approval, generate skill files to `_generated-skills/{slug}/`
6. validate the output
7. give you the install command

Then run the install command in your terminal:

```bash
npx skills add ./_generated-skills
```

### Example: opt into the agentic engine

```text
# Claude Code
/cogworks encode --engine agentic https://example.com/some-guide

# Codex CLI
$cogworks encode --engine agentic https://example.com/some-guide
```

In agentic mode, cogworks also writes a run directory under `_generated-skills/.cogworks-runs/` with per-stage artifacts, `agentic_path`, and a `dispatch-manifest.json` that records the canonical role profiles, surface bindings, model policy, and actual dispatch modes used for specialist stages.
Those runtime artifacts do not replace the normal generated-skill contract: the final `SKILL.md`, `reference.md`, and `metadata.json` still need to pass the same deterministic validators as the legacy engine.

### Example: encode from local files

```text
# Claude Code
/cogworks encode my-topic from _sources/my-topic/

# Codex CLI
$cogworks encode my-topic from _sources/my-topic/
```

### Example: encode to a custom destination

```text
# Claude Code
/cogworks encode my-topic from _sources/my-topic/ to ./custom/path/

# Codex CLI
$cogworks encode my-topic from _sources/my-topic/ to ./custom/path/
```

## Using Skills Independently

### `/cogworks-encode` — Synthesis without skill generation

Use when you want the 8-phase synthesis methodology applied to sources but don't need a full skill package.

```text
# Claude Code
/cogworks-encode I have three API docs open. Help me synthesise them into a unified reference.

# Codex CLI
$cogworks-encode I have three API docs open. Help me synthesise them into a unified reference.
```

### `/cogworks-learn` — Skill-writing expertise

Use when writing or reviewing skills manually, designing skill architecture, understanding invocation modes, or optimising discoverability.

```text
# Claude Code
/cogworks-learn Review this SKILL.md frontmatter and suggest improvements.

# Codex CLI
$cogworks-learn Review this SKILL.md frontmatter and suggest improvements.
```

## Common Invocation Patterns

```bash
# Claude Code
/cogworks encode https://docs.example.com/api-reference
/cogworks encode --engine agentic https://docs.example.com/api-reference
/cogworks encode my-topic from _sources/my-topic/
/cogworks encode my-topic from _sources/my-topic/ to ./my-skills/
/cogworks-encode _sources/my-topic/ and output your synthesis to _sources/my-topic/ as synthesis.md
/cogworks-learn How should I structure a multi-file skill?

# Codex CLI
$cogworks encode https://docs.example.com/api-reference
$cogworks encode --engine agentic https://docs.example.com/api-reference
$cogworks encode my-topic from _sources/my-topic/
$cogworks encode my-topic from _sources/my-topic/ to ./my-skills/
$cogworks-encode _sources/my-topic/ and output your synthesis to _sources/my-topic/ as synthesis.md
$cogworks-learn How should I structure a multi-file skill?
```

## Prerequisites

- **An agent that supports skills** — Claude Code, Codex, GitHub Copilot, Cursor, or any agent supporting the [Agent Skills standard](https://agentskills.io)
- **Node.js 18+** — required for the `skills` CLI that handles installation
- **A project repository** — cogworks generates skills into `_generated-skills/` by default

## Reinstalling or Updating

To update, or remove, please see [npx skills documentation](https://www.npmjs.com/package/skills) for available commands and run `npx skills <command>` in your terminal.
