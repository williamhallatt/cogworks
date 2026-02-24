# Cogworks User Guide

Cogworks transforms URLs and files into invokable agent skills through systematic synthesis. You provide sources, cogworks analyses them through an 8-phase process, and outputs a skill package that any compatible agent can auto-discover and invoke.

## The Three Skills

Cogworks installs as three focused skills that work together:

| Skill | Purpose | Invocation |
|-------|---------|------------|
| **cogworks** | Orchestrator — runs the full end-to-end workflow | `/cogworks encode ...` |
| **cogworks-encode** | Synthesis expertise — the 8-phase process for analysing and combining sources | `/cogworks-encode ...` |
| **cogworks-learn** | Skill-writing expertise — SKILL.md structure, frontmatter, quality gates | `/cogworks-learn ...` |

**How they relate:** `/cogworks` orchestrates the complete pipeline and delegates to cogworks-encode (for synthesis) and cogworks-learn (for skill generation). The two supporting skills are also usable independently when you only need part of the pipeline.

## Quick Start

Start your agent in your project directory and run:

```
/cogworks encode <sources>
```

Where `<sources>` can be URLs, local files, directories, or files containing URLs.

### Example: encode from a URL

```
/cogworks encode https://example.com/some-guide
```

Cogworks will:
1. Fetch the URL content
2. Generate a slug from the topic (e.g. `some-guide`)
3. Run 8-phase synthesis on the content
4. Present a summary for your review
5. On approval, generate skill files to `_generated-skills/{slug}/`
6. Validate the output
7. Give you the install command

Then run the install command in your terminal:

```bash
npx skills add ./_generated-skills
```

The CLI walks you through agent selection and options interactively.

### Example: encode from local files

```
/cogworks encode my-topic from _sources/my-topic/
```

### Example: encode to a custom destination

```
/cogworks encode my-topic from _sources/my-topic/ to ./custom/path/
```

## Using Skills Independently

### `/cogworks-encode` — Synthesis without skill generation

Use when you want the 8-phase synthesis methodology applied to sources but don't need a full skill package. Good for creating reference documents, knowledge bases, or reconciling conflicting information.

```
/cogworks-encode I have three API docs open. Help me synthesise them into a unified reference.
/cogworks-encode product management best practices from _sources/pm/ and output results to _sources/pm/ as synthesis.md
```

### `/cogworks-learn` — Skill-writing expertise

Use when writing or reviewing skills manually, designing skill architecture, understanding invocation modes, or optimising discoverability.

```
/cogworks-learn I've written a deployment skill. Should it use disable-model-invocation?
/cogworks-learn Review this SKILL.md frontmatter and suggest improvements.
```

## Common Invocation Patterns

```bash
# Full pipeline from URL
/cogworks encode https://docs.example.com/api-reference

# Full pipeline from local directory
/cogworks encode my-topic from _sources/my-topic/

# Full pipeline with custom output path
/cogworks encode my-topic from _sources/my-topic/ to ./my-skills/

# Full pipeline with explicit skill name
/cogworks encode advanced-prompting from _sources/advanced-prompting/

# Synthesis only (no skill generation)
/cogworks-encode _sources/my-topic/ and output your synthesis to _sources/my-topic/ as synthesis.md

# Skill-writing advice
/cogworks-learn How should I structure a multi-file skill?
```

## Prerequisites

- **An agent that supports skills** — Claude Code, Codex, GitHub Copilot, Cursor, or any agent supporting the [Agent Skills standard](https://agentskills.io)
- **Node.js 18+** — required for the `skills` CLI that handles installation
- **A project repository** — cogworks generates skills into `_generated-skills/` by default

## Reinstalling or Updating

To update, or remove, please see [npx skills documentation](https://www.npmjs.com/package/skills) for available commands and run `npx skills <command>` in your terminal.
