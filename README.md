# Cogworks

A clockwork engine for AI agents: encode knowledge from sources and automate creation of high-quality skills.

## What it does

`cogworks` transforms URLs and files into invokable agent skills through systematic synthesis — extracting core concepts, mapping relationships between them, detecting conflicts across sources, and producing structured knowledge you can query and build on.

## How it works

Provide sources (URLs, files, directories) -> `cogworks` synthesises them via an 8-phase process (content analysis, concept extraction, relationship mapping, pattern extraction, anti-pattern documentation, conflict detection, example collection, narrative construction) -> outputs a multi-file skill package -> the skill becomes auto-discoverable and invokable via `/{slug}`.

## How I use it

`cogworks` is a personal workflow tool. It does what I need well, but it isn't fully productionised — see [ROADMAP.md](ROADMAP.md) for known limitations and planned work.

My typical workflow:

1. **Prepare sources** — I find authoritative content online and save it as markdown to `_sources/<topic>/` (e.g., `_sources/cc-docs/`). Some documentation hubs already publish markdown, which makes this straightforward. You can also pass URLs directly instead of local files.

2. **Encode** — I run the skill with something like:

   ```bash
   # Claude Code
   /cogworks encode advanced-prompting from _sources/advanced-prompting/

   # Codex CLI
   $cogworks encode advanced-prompting from _sources/advanced-prompting/
   ```

   This kicks off the full pipeline: source gathering through to skill generation and validation.

3. **Skills used alone** — If I want to, say, only run knowledge synthesis (skipping the full workflow), I invoke the encode skill directly:

   ```bash
   # Claude Code
   /cogworks-encode _sources/my-topic/ and output your synthesis to _sources/my-topic/ as synthesis.md

   # Codex CLI
   $cogworks-encode _sources/my-topic/ and output your synthesis to _sources/my-topic/ as synthesis.md
   ```

(The `_sources/` directory is local-only and excluded from releases.)

## Prerequisites

- **An agent that supports skills** — Claude Code, Codex, GitHub Copilot, Cursor, or any agent supporting the [Agent Skills standard](https://agentskills.io)
- **Node.js 18+** — required for the [`skills` CLI](https://github.com/vercel-labs/skills) that installs generated skills to agents
- **A project repository** — `cogworks` generates skills into `_generated-skills/` and installs them to detected agents via `npx skills add`

## Installation

```bash
npx skills add williamhallatt/cogworks
```

This installs all cogworks skills to detected agents. See [INSTALL.md](INSTALL.md) for options including specific skills, specific agents, global scope, and manual installation.

> **Tip:** A user guide ships with the installed skills. After installation, ask your agent "how does cogworks work?" or see [`skills/cogworks/README.md`](skills/cogworks/README.md) directly.

### Manual Installation

Clone the repository and copy the three required skills:

```bash
git clone https://github.com/williamhallatt/cogworks.git
cp -r cogworks/skills/cogworks your-project/.claude/skills/
cp -r cogworks/skills/cogworks-encode your-project/.claude/skills/
cp -r cogworks/skills/cogworks-learn your-project/.claude/skills/
```

## Quick Start

Start your agent in your project directory and invoke:

> **Note:** The skill prefix is agent-specific. Examples use `/` (Claude Code) and `$` (Codex CLI). Other agents may use a different prefix — consult your agent's documentation.

```bash
# Claude Code
/cogworks encode <sources> as <skill_name>

# Codex CLI
$cogworks encode <sources> as <skill_name>
```

Where `<sources>` can be a mix of URLs, local files, directories, and files containing URLs, and `as <skill_name>` is optional (if not provided, `cogworks` generates a slug from the source topic).

### Example: encoding knowledge from a URL

```bash
# Claude Code
/cogworks encode https://example.com/some-guide

# Codex CLI
$cogworks encode https://example.com/some-guide
```

Here's what happens step by step:

**1. Source gathering** — `cogworks` fetches the URL content. If any sources fail to load, it tells you and asks whether to continue with what it has.

**2. Slug generation** — if not provided, `cogworks` picks a URL-safe slug from the source topic (e.g., `eating-pizza`). Skill files are generated into the `_generated-skills/{slug}/` staging directory by default. You can specify a custom destination in your command (e.g., "to ./custom/path"). If the destination already exists, it asks you to confirm overwriting.

**3. Synthesis** — `cogworks` runs the 8-phase synthesis process on the gathered content:
content analysis -> concept extraction -> relationship mapping -> pattern extraction -> anti-pattern documentation -> conflict detection -> example collection -> narrative construction

**4. Review** — `cogworks` presents a summary for your review:

- Topic name and source count
- Destination path where the skill will be created
- A TL;DR of the synthesised knowledge
- Statistics (concept, pattern, and example counts)

You approve or decline. If you decline, `cogworks` stops.

**5. Skill generation** — On approval, `cogworks` writes the skill files to the staging directory (SKILL.md, reference.md, patterns.md, examples.md).

**6. Validation** — `cogworks` reviews the generated files for source fidelity, self-sufficiency, completeness, specificity, and overlap. It fixes any problems before finishing.

**7. Done** — `cogworks` confirms the skill location and gives you the install command. Run `npx skills add ./_generated-skills` in your terminal to install to your agents — the CLI walks you through agent selection and installation options interactively.

Your new skill is now available as `/{slug}` (prefix is agent-specific: `/` in Claude Code, `$` in Codex CLI) — the agent will auto-discover it whenever the topic comes up, or you can invoke it directly.

## Using cogworks

The `cogworks` skill orchestrates a full end-to-end workflow, but you can also use the supporting skills directly.

- **The orchestrator** (`/cogworks`) — runs the complete 7-step workflow (source gathering -> synthesis -> review -> skill generation -> validation -> install prompt). It references both supporting skills.
- **The skills** (`/cogworks-encode`, `/cogworks-learn`) — inject domain expertise into your conversation. You then direct the agent in natural language, applying that expertise however you need. They don't run workflows on their own.

### `/cogworks-encode` — Synthesis expertise

Loads the 8-phase synthesis methodology:

1. Content Analysis
2. Concept Extraction
3. Relationship Mapping
4. Pattern Extraction
5. Anti-Pattern Documentation
6. Conflict Detection
7. Example Collection
8. Narrative Construction

**When to use independently:** when you want synthesis expertise without the full skill-generation workflow — analysing multiple sources, creating a reference document, building a knowledge base outside the skill format, or reconciling conflicting information across documents.

**Example invocations:**

```bash
# Claude Code
/cogworks-encode I have three API docs open. Help me synthesise them into a unified reference.
/cogworks-encode product management best practices from <source_dir> and output results to <output_dir>.

# Codex CLI
$cogworks-encode I have three API docs open. Help me synthesise them into a unified reference.
$cogworks-encode product management best practices from <source_dir> and output results to <output_dir>.
```

### `/cogworks-learn` — Skill-writing expertise

Loads expertise on writing agent skills — SKILL.md files, frontmatter configuration, invocation modes, context management, and best practices.

**When to use independently:** when writing or reviewing skills manually, designing skill architecture, understanding invocation modes, or optimising skill discoverability and context efficiency.

**Example invocations:**

```bash
# Claude Code
/cogworks-learn I've written a deployment skill. Should it use disable-model-invocation?
/cogworks-learn Review this SKILL.md frontmatter and suggest improvements.

# Codex CLI
$cogworks-learn I've written a deployment skill. Should it use disable-model-invocation?
$cogworks-learn Review this SKILL.md frontmatter and suggest improvements.
```

### Testing Generated Skills

Testing is a separate step from encoding. After encoding a skill, run:

```bash
bash scripts/test-generated-skill.sh --skill-path .claude/skills/my-skill
bash scripts/test-generated-skill.sh --skill-path .claude/skills/my-skill --with-behavioral
```

### Running Recursive Improvement Rounds

Canonical runbook: `tests/datasets/recursive-round/README.md`

```bash
# 1) Create local manifest and pin frozen test hash
cp tests/datasets/recursive-round/round-manifest.example.json \
  tests/datasets/recursive-round/round-manifest.local.json
bash scripts/pin-test-bundle-hash.sh \
  tests/datasets/recursive-round/round-manifest.local.json

# 2) Load concrete defaults for hooks + benchmark wrappers
source scripts/recursive-env.example.sh

# 3) Fast round (invariant + behavioral)
bash scripts/run-recursive-round.sh \
  --round-manifest tests/datasets/recursive-round/round-manifest.local.json \
  --mode fast \
  --run-id rr-20260220-fast1
```

## Trunk Commit Docs Attestation

This repository enforces docs-impact attestation on commits pushed to `main`.

Install the local hook so validation happens before push:

```bash
bash scripts/install-git-hooks.sh
```

Required commit trailers:

```text
Docs-Impact: updated|none|required-followup
Docs-Updated: <csv-paths>|none
Docs-Why-None: <required when Docs-Impact is none or required-followup>
```

## Limitations

Related to this being a personal workflow tool (see [ROADMAP.md](ROADMAP.md) for planned work):

- **Not portable** — `cogworks` assumes Linux (Ubuntu), edit paths throughout skills accordingly
- **Neutral staging** — generated skills are written to `_generated-skills/` and installed to detected agents via `npx skills add`. You can override the staging path with a custom destination in your command.
- **Universal skills** — skills generated by cogworks follow the [Agent Skills standard](https://agentskills.io) and work across Claude Code, Codex, GitHub Copilot, Cursor, and other compatible agents

Limitations I'm not planning on addressing:

- **No authenticated sources** — WebFetch cannot access anything behind a login
- **Context window ceiling** — all sources must fit in the agent's context during synthesis
- **Snapshot knowledge** — synthesis captures sources at a point in time; no automated updates if the source changes

## License

MIT
