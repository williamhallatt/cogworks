# Cogworks

A clockwork engine for AI agents: encode knowledge from sources, automate the creation of skills and sub-agents.

## What it does

`cogworks` transforms URLs and files into invokable Claude `skills` through systematic synthesis. It performs deep integration that extracts core concepts, maps relationships between them, detects conflicts across sources, and produces structured knowledge you can query and build on.

## How it works

Provide sources (URLs, files, directories) → `cogworks` synthesizes them via an 8-phase process (content analysis, concept extraction, relationship mapping, pattern extraction, anti-pattern documentation, conflict detection, example collection, narrative construction) → outputs a multi-file skill package → the skill becomes auto-discoverable and invokable via `/{slug}`.

## Prerequisites

- **Claude Code** — installed and working ([docs](https://docs.anthropic.com/en/docs/claude-code))
- **A project repository** — `cogworks` creates skills inside `.claude/skills/` within whichever repo you run it in

## Installation

### From Release (Recommended)

Download the latest release from [GitHub Releases](https://github.com/williamhallatt/cogworks/releases):

```bash
# Extract release
tar -xzf cogworks-{version}.tar.gz

# Copy to your project
cp -r cogworks-{version}/.claude/* your-project/.claude/
```

See [INSTALL.md](INSTALL.md) for detailed installation instructions.

### Manual Installation

Alternatively, copy the `cogworks` agent and its supporting skills directly from this repository. All three are required — the agent (`cogworks`) orchestrates the workflow, and the two skills provide the synthesis (`cogworks-encode`) and skill-writing (`cogworks-learn`) methodologies it depends on:

```bash
your-project/
└── .claude/
    ├── agents/
    │   └── cogworks.md              # Orchestrating agent
    └── skills/
        ├── cogworks-encode/         # Synthesis methodology
        │   ├── SKILL.md
        │   └── reference.md
        └── cogworks-learn/          # Skill-writing expertise
            ├── SKILL.md
            ├── reference.md
            ├── patterns.md
            ├── persuasion-principles.md
            └── examples.md
```

## Quick Start

Start Claude Code in your project directory and run some version of the following command in the chat interface:

```bash
@cogworks <command> <sources> as <skill_name>
```

Where `<command>` could be `encode`, `learn`, or `automate`, `<sources>` can be a mix of URLs, local files, directories, and files containing URLs, and `as <skill_name>` is optional (if not provided, `cogworks` generates a slug from the source topic).

> Note: There is no mechanism for disallowing implicit invocation of Claude sub-agents, but the `cogworks` agent description does attempt a "soft block" by asking the user to explicitly invoke it for encoding tasks. If you find that `cogworks` is being invoked when you don't want it to be, please open an issue with details so I can improve the prompt instructions.

### Example: encoding knowledge from a URL

```bash
@cogworks encode https://example.com/some-guide
```

Here's what happens step by step:

**1. Source gathering** — `cogworks` fetches the URL content. If any sources fail to load, it tells you and asks whether to continue with what it has.

**2. Slug generation** — if not provided, `cogworks` picks a URL-safe slug from the source topic (e.g., `eating-pizza`). If `.claude/skills/eating-pizza/` already exists, it asks you to confirm overwriting.

**3. Synthesis** — `cogworks` runs the 8-phase synthesis process on the gathered content:
content analysis → concept extraction → relationship mapping → pattern extraction → anti-pattern documentation → conflict detection → example collection → narrative construction

**4. Review** — `cogworks` presents a summary for your review:

- Topic name and source count
- A TL;DR of the synthesized knowledge
- Statistics (concept, pattern, and example counts)

You approve or decline. If you decline, `cogworks` stops.

**5. Skill generation** — On approval, `cogworks` writes the skill files to `.claude/skills/{slug}/` (SKILL.md, reference.md, patterns.md, examples.md).

**6. Validation** — `cogworks` reviews the generated files for source fidelity, self-sufficiency, completeness, specificity, and overlap. It fixes any problems before finishing.

**7. Done** — `cogworks` confirms the skill location and how to invoke it.

Your new skill is now available as `/{slug}` — Claude will auto-discover it whenever the topic comes up, or you can invoke it directly.

## Using `@cogworks`

The `cogworks` agent and its two skills can be used together or independently. The agent orchestrates a full end-to-end workflow; the skills load specialized expertise into Claude's context for you to direct manually.

- **The agent** (`@cogworks`) — runs the complete 7-step workflow (source gathering → synthesis → review → skill generation → validation). It automatically loads both skills.
- **The skills** (`/cogworks-encode`, `/cogworks-learn`) — inject domain expertise into your conversation. You then direct Claude in natural language, applying that expertise however you need. They don't run workflows on their own.

### The cogworks agent

Invoke by typing a `@cogworks` command in natural language:

```bash
@cogworks encode <sources> as <skill_name>
@cogworks automate <description of what to automate> from <sources>
```

This is what I need and use 99% of the time, but the agent is basically a fancy wrapper for the skills, so if you want to do something more custom or run the synthesis without generating a skill, or create a skill without the need to synthesise any information you can invoke the skills directly.

### `/cogworks-encode` — Synthesis expertise

Loads the 8-phase synthesis methodology into Claude's context:

1. Content Analysis
2. Concept Extraction
3. Relationship Mapping
4. Pattern Extraction
5. Anti-Pattern Documentation
6. Conflict Detection
7. Example Collection
8. Narrative Construction

**When to use independently:** when you want synthesis expertise without the full skill-generation workflow — analyzing multiple sources, creating a reference document, building a knowledge base outside the skill format, or reconciling conflicting information across documents.

**Example invocations:**

```bash
/cogworks-encode I have three API docs open. Help me synthesize them into a unified reference.
/cogworks-encode product management best practices from <source_dir> and output results to <output_dir>.
```

### `/cogworks-learn` — Skill-writing expertise

Loads expertise on writing Claude Code skills — SKILL.md files, frontmatter configuration, invocation modes, context management, and best practices.

**When to use independently:** when writing or reviewing skills manually, designing skill architecture, understanding invocation modes, or optimizing skill discoverability and context efficiency.

**Example invocations:**

```bash
/cogworks-learn I've written a deployment skill. Should it use disable-model-invocation?
/cogworks-learn Review this SKILL.md frontmatter and suggest improvements.
/cogworks-learn prompt-optimisation from <reference_doc>
```

## Limitations

Related to my setup that will likely be improved over time:

- **Claude Code only [FOR NOW]** — output formats specifically target Claude Code structures, may not work well for other agent frameworks without modification
- **Not portable** — `cogworks` assumes Linux (Ubuntu), edit paths throughout agent and associated skills definitions accordingly
- **Local creation** — encoded skills are created in `.claude/skills/` within the repo where `cogworks` is used
- **Manual testing only** — no automated testing of new skills yet, rely on user feedback to identify issues
- **Agent generation not yet implemented** — `cogworks` for generating sub-agents is planned but not available

Limitations I'm not planning on addressing:

- **No authenticated sources** — WebFetch cannot access anything behind a login
- **Context window ceiling** — all sources must fit in Claude's context during synthesis
- **Snapshot knowledge** — synthesis captures sources at a point in time; no automated updates if the source changes

## License

MIT
