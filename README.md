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
- **OpenAI Codex (optional)** — use the Codex skill workflow instead of the Claude agent (see below)
- **A project repository** — `cogworks` creates skills in your chosen location (project scope `.claude/skills/`, personal scope `~/.claude/skills/`, or a custom path)

## Installation

The packaged release includes the `cogworks` agent, its two required supporting skills (`cogworks-encode` and `cogworks-learn`), and the optional testing skill (`cogworks-test`) with associated testing infrastructure (`.claude/test-framework/`). The testing skill is not required for using `cogworks`, and it is **user‑initiated**: if you want to validate generated skills, you explicitly run `cogworks-test` and the test framework yourself.

### Quick Install (Recommended)

Download the latest release from [GitHub Releases](https://github.com/williamhallatt/cogworks/releases) and run the installation script:

```bash
# Extract and install
tar -xzf cogworks-{version}.tar.gz
cd cogworks-{version}
./install.sh
```

The script provides an interactive menu to choose between local (project) or global (personal) installation, handles directory creation, and validates the installation.

For non-interactive installation:

```bash
# Install to current project
./install.sh --local

# Install to personal directory
./install.sh --global
```

See [INSTALL.md](INSTALL.md) for detailed instructions and manual installation options.

### Manual Installation

Alternatively, copy the `cogworks` agent and its dependencies (`cogworks-encode` and `cogworks-learn`) directly from this repository. All three are required — the agent orchestrates the workflow, and the two skills provide the synthesis and skill-writing (`cogworks-test` is optional and only runs when you invoke it. If you want testing, also include `.claude/test-framework/`.)

For OpenAI Codex users, install the Codex skills instead of the Claude agent:

```
./install.sh --target codex --local
./install.sh --target codex --global
# Legacy shorthand (global):
./install.sh --codex
```

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

**2. Slug generation and destination selection** — if not provided, `cogworks` picks a URL-safe slug from the source topic (e.g., `eating-pizza`). You can specify a destination in your command (e.g., "to personal" or "to project"), or `cogworks` will ask where to create the skill (project, personal, or custom path). If the destination already exists, it asks you to confirm overwriting.

**3. Synthesis** — `cogworks` runs the 8-phase synthesis process on the gathered content:
content analysis → concept extraction → relationship mapping → pattern extraction → anti-pattern documentation → conflict detection → example collection → narrative construction

**4. Review** — `cogworks` presents a summary for your review:

- Topic name and source count
- Destination path where the skill will be created
- A TL;DR of the synthesised knowledge
- Statistics (concept, pattern, and example counts)

You approve or decline. If you decline, `cogworks` stops.

**5. Skill generation** — On approval, `cogworks` writes the skill files to your chosen destination (SKILL.md, reference.md, patterns.md, examples.md).

**6. Validation** — `cogworks` reviews the generated files for source fidelity, self-sufficiency, completeness, specificity, and overlap. It fixes any problems before finishing. If you want additional or repeatable validation later, run `cogworks-test` yourself (see `TESTING.md`).

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

## OpenAI Codex Usage

Codex does not support Claude sub-agents, so the workflow is provided as a Codex skill instead. Codex discovers skills in `.agents/skills/` under your repo (local scope) or in `~/.agents/skills` (user scope).

1. Install Codex skills:

```
./install.sh --target codex --local
./install.sh --target codex --global
# Legacy shorthand (global):
./install.sh --codex
```

2. Invoke the Codex skill orchestrator:

```
cogworks encode <sources> as <skill_name>
```

3. Or use the skills directly:

- `cogworks-encode`
- `cogworks-learn`
- `cogworks-test` (optional, Layer 1 by default)

### Codex Testing (Recommended: Layer 1)

For Codex users, the deterministic checks (Layer 1) are the supported default. Layer 2 and behavioral gates require Claude-specific tooling.

```
/cogworks-test my-skill --layer1-only
```
```

Testing runs three validation layers:

- **Layer 1**: Deterministic checks (structure, syntax, citations)
- **Layer 2**: LLM-as-judge evaluation (5 quality dimensions)
- **Layer 2.5**: Efficacy measurement (task performance with/without skill using SkillsBench methodology)

Generates a detailed validation report with scores and recommendations. Cost: ~$1.50 per skill.

**Efficacy Validation**: The cogworks pipeline has been empirically validated to produce highly effective skills:
- **4/4 benchmark tasks** passed with 100% success rate (20/20 runs)
- **Average improvement**: +54.2pp over baseline (task completion without skill)
- **3.3x more effective** than SkillsBench curated skills benchmark (+54.2pp vs +16.2pp)
- Skills validated across software-engineering and devops-infrastructure domains

See `_sources/skillsbench-implementation/ALL_BENCHMARKS_COMPLETE.md` for complete efficacy validation results (archived validation report).

**When to use:** after encoding a new skill, after manual edits to an existing skill, for regression testing golden samples, or to check quality before production use.

See `.claude/test-framework/README.md` for complete testing documentation.

## Limitations

Related to this being a personal workflow tool (see [ROADMAP.md](ROADMAP.md) for planned work):

- **Claude agent is Claude Code-specific** — The `@cogworks` agent relies on Claude Code features (subagent orchestration, Task tool, specific invocation patterns). For Codex, use the Codex skill orchestrator in `codex/skills/cogworks`, installed via `./install.sh --target codex --local|--global` (or legacy `./install.sh --codex`). Codex discovers skills in `.agents/skills/` (repo) or `~/.agents/skills` (user). **The skills cogworks generates ARE portable** — they follow the universal AgentSkills standard (SKILL.md format with minimal frontmatter) and work across Claude Code, GitHub Copilot, Cursor, and other tools supporting the standard.
- **Not portable** — `cogworks` assumes Linux (Ubuntu), edit paths throughout agent and associated skills definitions accordingly
- **Flexible destination** — encoded skills can be created in project scope (`.claude/skills/`), personal scope (`~/.claude/skills/`), or custom paths
- **Agent generation not yet implemented** — `cogworks` for generating sub-agents is planned but not available

Limitations I'm not planning on addressing:

- **No authenticated sources** — WebFetch cannot access anything behind a login
- **Context window ceiling** — all sources must fit in Claude's context during synthesis
- **Snapshot knowledge** — synthesis captures sources at a point in time; no automated updates if the source changes

## License

MIT
