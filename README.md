# Cogworks

A clockwork engine for AI agents: encode knowledge from sources, automate the creation of skills and sub-agents.

## What it does

`cogworks` transforms URLs and files into invokable Claude `skills` through systematic synthesis — extracting core concepts, mapping relationships between them, detecting conflicts across sources, and producing structured knowledge you can query and build on.

## How it works

Provide sources (URLs, files, directories) → `cogworks` synthesises them via an 8-phase process (content analysis, concept extraction, relationship mapping, pattern extraction, anti-pattern documentation, conflict detection, example collection, narrative construction) → outputs a multi-file skill package → the skill becomes auto-discoverable and invokable via `/{slug}`.

## How I use it

`cogworks` is a personal workflow tool. It does what I need well, but it isn't fully productionised — see [ROADMAP.md](ROADMAP.md) for known limitations and planned work.

My typical workflow:

1. **Prepare sources** — I find authoritative content online and save it as markdown to `_sources/<topic>/` (e.g., `_sources/cc-docs/`, `_sources/advanced-prompting/`). Some documentation hubs already publish markdown, which makes this straightforward. You can also pass URLs directly instead of local files.

2. **Encode** — I run the agent with something like:

   ```bash
   @cogworks encode advanced-prompting from _sources/advanced-prompting/
   ```

   This kicks off the full pipeline: source gathering through to skill generation and validation.

3. **Skills used alone** — If I want to, say, only run knowledge synthesis (skipping the full agent workflow), I invoke the encode skill directly:

   ```bash
   /cogworks-encode _sources/my-topic/ and output your synthesis to _sources/my-topic/ as synthesis.md
   ```

(The `_sources/` directory is local-only and excluded from releases.)

## Prerequisites

- **Claude Code** — installed and working ([docs](https://docs.anthropic.com/en/docs/claude-code))
- **A project repository** — `cogworks` creates skills inside `.claude/skills/` within whichever repo you run it in

## Installation

The packaged release includes the `cogworks` agent, its two required supporting skills (`cogworks-encode` and `cogworks-learn`), and the optional, but useful testing skill (`cogworks-test`) with associated testing infrastructure (`.claude/test-framework/`). The testing skill is not required for using `cogworks`, but is recommended if you want to validate generated skills.

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

Alternatively, copy the `cogworks` agent and its dependencies (`cogworks-encode` and `cogworks-learn`) directly from this repository. All three are required — the agent orchestrates the workflow, and the two skills provide the synthesis and skill-writing (`cogworks-test` is not required, but recommended if you want to validate generated skills. If you do want to use it, you'll also need the testing infrastructure in `.claude/test-framework/`)

```bash
your-project/
└── .claude/
    ├── agents/
    │   └── cogworks.md              # Orchestrating agent
    ├── skills/
    │   ├── cogworks-encode/         # Synthesis methodology
    │   │   ├── SKILL.md
    │   │   └── reference.md
    │   ├── cogworks-learn/          # Skill-writing expertise
    │   │   ├── SKILL.md
    │   │   ├── reference.md
    │   │   ├── patterns.md
    │   │   ├── persuasion-principles.md
    │   │   └── examples.md
    │   └── cogworks-test/           # Testing and validation
    │       ├── SKILL.md
    │       ├── reference.md
    │       ├── patterns.md
    │       └── examples.md
    └── test-framework/              # Testing infrastructure
        ├── config/
        ├── graders/
        ├── templates/
        └── scripts/
```

## Quick Start

Start Claude Code in your project directory and run some version of the following command in the chat interface:

```bash
@cogworks <command> <sources> as <skill_name>
```

Where `<command>` could be `encode`, `learn`, or `automate`, `<sources>` can be a mix of URLs, local files, directories, and files containing URLs, and `as <skill_name>` is optional (if not provided, `cogworks` generates a slug from the source topic).

> Note: Claude Code doesn't let you prevent sub-agents from firing on their own. The `cogworks` agent prompt tries to soft-block this, but it's not foolproof. If `cogworks` fires when you don't want it to, open an issue so I can tighten the prompt.

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
- A TL;DR of the synthesised knowledge
- Statistics (concept, pattern, and example counts)

You approve or decline. If you decline, `cogworks` stops.

**5. Skill generation** — On approval, `cogworks` writes the skill files to `.claude/skills/{slug}/` (SKILL.md, reference.md, patterns.md, examples.md).

**6. Validation** — `cogworks` reviews the generated files for source fidelity, self-sufficiency, completeness, specificity, and overlap. It fixes any problems before finishing.

**7. Done** — `cogworks` confirms the skill location and how to invoke it.

Your new skill is now available as `/{slug}` — Claude will auto-discover it whenever the topic comes up, or you can invoke it directly.

## Using `@cogworks`

The `cogworks` agent orchestrates a full end-to-end workflow, but you can also direct `cogworks-*` skills manually through direct invocation.

- **The agent** (`@cogworks`) — runs the complete 7-step workflow (source gathering → synthesis → review → skill generation → validation). It automatically loads both skills.
- **The skills** (`/cogworks-encode`, `/cogworks-learn`, `/cogworks-test`) — inject domain expertise into your conversation. You then direct Claude in natural language, applying that expertise however you need. They don't run workflows on their own.

### The cogworks agent

Invoke by typing a `@cogworks` command in natural language:

```bash
@cogworks encode <sources> as <skill_name>
@cogworks automate <description of what to automate> from <sources>
```

This is what I need and use 99% of the time, but the agent is basically a fancy wrapper for the skills, so if you want to do something more custom or run the synthesis without generating a skill (or create a skill without the need to synthesise any information) you can invoke the skills directly.

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

**When to use independently:** when you want synthesis expertise without the full skill-generation workflow — analysing multiple sources, creating a reference document, building a knowledge base outside the skill format, or reconciling conflicting information across documents.

**Example invocations:**

```bash
/cogworks-encode I have three API docs open. Help me synthesise them into a unified reference.
/cogworks-encode product management best practices from <source_dir> and output results to <output_dir>.
```

### `/cogworks-learn` — Skill-writing expertise

Loads expertise on writing Claude Code skills — SKILL.md files, frontmatter configuration, invocation modes, context management, and best practices.

**When to use independently:** when writing or reviewing skills manually, designing skill architecture, understanding invocation modes, or optimising skill discoverability and context efficiency.

**Example invocations:**

```bash
/cogworks-learn I've written a deployment skill. Should it use disable-model-invocation?
/cogworks-learn Review this SKILL.md frontmatter and suggest improvements.
/cogworks-learn prompt-optimisation from <reference_doc>
```

### `/cogworks-test` — Testing and validation

Validates generated skills through layered grading (deterministic checks, LLM-as-judge, optional human review). Tests synthesis quality, skill structure, source fidelity, and observable behaviour.

Testing is a separate step from encoding. After encoding a skill, run tests independently:

```bash
# Test a skill after encoding it
/cogworks-test my-skill

# Other examples
/cogworks-test my-skill --json
/cogworks-test my-skill --compare-against tests/datasets/golden-samples/my-skill/
```

Testing runs two validation layers:

- **Layer 1**: Deterministic checks (structure, syntax, citations)
- **Layer 2**: LLM-as-judge evaluation (5 quality dimensions)

Generates a detailed validation report with scores and recommendations. Cost: ~$1.50 per skill.

**When to use:** after encoding a new skill, after manual edits to an existing skill, for regression testing golden samples, or to check quality before production use.

See `.claude/test-framework/README.md` for complete testing documentation.

## Limitations

Related to this being a personal workflow tool (see [ROADMAP.md](ROADMAP.md) for planned work):

- **Claude Code only [FOR NOW]** — output formats specifically target Claude Code structures, may not work well for other agent frameworks without modification
- **Not portable** — `cogworks` assumes Linux (Ubuntu), edit paths throughout agent and associated skills definitions accordingly
- **Local creation** — encoded skills are created in `.claude/skills/` within the repo where `cogworks` is used
- **Agent generation not yet implemented** — `cogworks` for generating sub-agents is planned but not available

Limitations I'm not planning on addressing:

- **No authenticated sources** — WebFetch cannot access anything behind a login
- **Context window ceiling** — all sources must fit in Claude's context during synthesis
- **Snapshot knowledge** — synthesis captures sources at a point in time; no automated updates if the source changes

## License

MIT
