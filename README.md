# cogworks

Encode knowledge from diverse sources and automate creation of high-quality agent skills.

## Installation

```bash
npx skills add williamhallatt/cogworks
```

Requires Node.js 18+. See [INSTALL.md](INSTALL.md) for options including specific skills, specific agents, global scope, and manual installation.

## Quick Start

Start your agent in your project directory and invoke:

> **Note:** The skill prefix is agent-specific. Examples use `/` (Claude Code) and `$` (Codex CLI). Other agents may use a different prefix — consult your agent's documentation.

```bash
# Claude Code
/cogworks encode <sources> as <skill_name>

# Codex CLI
$cogworks encode <sources> as <skill_name>
```

`<sources>` can be a mix of URLs, local files, directories, and files containing URLs. `as <skill_name>` is optional — if omitted, `cogworks` generates a slug from the source topic.

## How it Works

Provide sources -> choose an execution engine -> `cogworks` synthesises them via an 8-phase process -> outputs a multi-file skill package -> the skill becomes auto-discoverable and invokable via `/{slug}`.

**Execution engines:**
- **Legacy** — default prompt-orchestrated pipeline
- **Agentic** — opt-in stage-driven pipeline using a coordinator plus specialist roles, canonical role profiles, surface-specific bindings, and honest fallback when a surface cannot provide native subagents

**Synthesis phases:**

1. Content Analysis
2. Concept Extraction
3. Relationship Mapping
4. Pattern Extraction
5. Anti-Pattern Documentation
6. Conflict Detection
7. Example Collection
8. Narrative Construction

For a full system deep dive, see [this](./docs/cogworks-system-deep-dive-2026-02-26.md)

## Using `cogworks`

The `cogworks` skill orchestrates a full end-to-end workflow, but you can also use the supporting skills directly.

- **The orchestrator** (`/cogworks`) — runs the complete workflow (source gathering -> synthesis -> review -> skill generation -> validation -> install prompt). It references both supporting skills. Add `--engine agentic` to opt into the new stage-driven runtime while keeping generated skills as the output artifact.
- **The skills** (`/cogworks-encode`, `/cogworks-learn`) — inject domain expertise into your conversation. You then direct the agent in natural language, applying that expertise however you need. They don't run workflows on their own.

### `/cogworks-encode` — Synthesis Expertise

Loads the 8-phase synthesis methodology.

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

### `/cogworks-learn` — Skill-Writing Expertise

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

## Agentic Mode

Use the opt-in agentic engine when you want the pipeline itself to behave like a coordinated team rather than one monolithic prompt-following run.

```bash
# Claude Code
/cogworks encode --engine agentic <sources> as <skill_name>

# Codex CLI
$cogworks encode --engine agentic <sources> as <skill_name>
```

Agentic mode keeps the product contract intact:
- the primary artifact is still a generated skill
- the default staging path is still `_generated-skills/`
- installation is still done with `npx skills add`

What changes is the execution model:
- coordinator + specialist roles
- explicit stage graph
- per-stage artifacts and summaries under `_generated-skills/.cogworks-runs/`
- `dispatch-manifest.json` recording canonical role profiles, surface bindings, model policy, and actual dispatch modes
- surface-specific adapters for Claude Code and GitHub Copilot CLI, with explicit degraded single-agent fallback when native subagents are unavailable

What does not change:
- the generated skill is still the product artifact
- `SKILL.md`, `reference.md`, and `metadata.json` still need to pass the same deterministic validators used by the legacy path
- run artifacts supplement those gates; they do not replace them

## Quality Across Agents and Models

Skill quality varies depending on which agent runs the workflow and which model powers it. The root cause is structural: synthesis and contradiction resolution are reasoning-heavy tasks, and models differ in how reliably they follow abstract quality instructions.

**Model capability requirements:**

| Provider | Reasoning tier (recommended for synthesis) | Workhorse tier (format assembly only) |
|----------|---------------------------------------------|---------------------------------------|
| Claude | Opus, Sonnet | Haiku |
| OpenAI | GPT-4o, GPT-4.1, o3 | GPT-3.5, o1-mini |
| Gemini | 1.5 Pro, 2.0 Flash Thinking | 1.5 Flash |

If your agent is running a workhorse-tier model, expect reduced synthesis depth — the structural output will be correct, but cross-source connections, contradiction resolution, and operational density in decision rules may be thinner.

**Mitigations built into the workflow:**

- Each skill carries an explicit self-verification checklist that the agent must evaluate against its own output before presenting results (embedded in `cogworks-encode` and `cogworks-learn` SKILL.md files)
- Portable validation scripts (`scripts/validate-synthesis.sh` in cogworks-encode, `scripts/validate-skill.sh` in cogworks-learn) provide mechanical enforcement of section presence, citation counts, and structural integrity — these ship with the skills and require only standard unix tools
- The orchestrator (`cogworks`) delegates verification to these per-skill gates rather than relying on a single vague rewrite pass
- In agentic mode, the simplified runtime keeps only source intake, synthesis, packaging, validation, and final review as explicit stage boundaries

These mitigations narrow the gap but do not eliminate it. For best results, use a reasoning-tier model.

## Limitations

Related to this being a personal workflow tool:

- **Not portable** — `cogworks` assumes Linux (Ubuntu), edit paths throughout skills accordingly
- **Neutral staging** — generated skills are written to `_generated-skills/` and installed to detected agents via `npx skills add`. You can override the staging path with a custom destination in your command.
- **Universal skills** — skills generated by cogworks follow the [Agent Skills standard](https://agentskills.io) and work across Claude Code, Codex, GitHub Copilot, Cursor, and other compatible agents
- **Surface capabilities differ** — Claude Code has repo-local role agent bindings under `.claude/agents/`; GitHub Copilot CLI uses the same canonical role profiles through adapter-rendered inline bindings and may honestly fall back to degraded single-agent execution if native subagents are unavailable

Limitations I'm not planning on addressing:

- **No authenticated sources** — WebFetch cannot access anything behind a login
- **Context window ceiling** — all sources must fit in the agent's context during synthesis, even when the agentic engine isolates some stage-local verbosity
- **Snapshot knowledge** — synthesis captures sources at a point in time; no automated updates if the source changes

## Contributing

See [CONTRIBUTIONS.md](CONTRIBUTIONS.md) for development setup, coding conventions, and the release process.

## License

[MIT](LICENSE)
