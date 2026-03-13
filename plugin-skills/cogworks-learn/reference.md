# Skill Writer - Complete Reference

Synthesized from the Agent Skills specification, Anthropic skill authoring best practices, and OpenAI Codex skill documentation.

---

## TL;DR

Agent skills are SKILL.md files that extend agent capabilities through YAML frontmatter (configuration) and markdown content (instructions). Skills live in directory structures at various scopes (Enterprise > Personal > Project > Plugin) and can be invoked automatically by the agent when relevant or manually via `/slash-commands`. Effective skills are concise (context window is a public good), use progressive disclosure (SKILL.md as overview pointing to reference files loaded on-demand), and match specificity to task fragility. The description field is critical for discovery - agents use it to decide when to load the skill from potentially 100+ available options. Advanced features include tool restrictions (`allowed-tools`, broadly supported across agents) and — on Claude Code specifically — argument interpolation (`$ARGUMENTS`, `$N`) and invocation control flags.

---

## Table of Contents

- [Prompt Quality Gates](#prompt-quality-gates-for-generated-skills-required) - Mandatory integrated prompt-quality checks
- [Core Concepts](#core-concepts) - Architecture, frontmatter, invocation, scope, content types
- [Concept Map](#concept-map) - Relationships between concepts
- [Deep Dives](#deep-dives) - Context budget, discovery, specificity, rationalization resistance, subagent orchestration, mechanism selection
- [Quick Reference](#quick-reference) - Frontmatter fields, substitutions, paths
- [Sources](#sources) - Bibliography

## Related Files

- [patterns.md](patterns.md) - Transferable patterns not already covered here
- [examples.md](examples.md) - Minimal examples that demonstrate the contract
- [persuasion-principles.md](persuasion-principles.md) - Calibration for
  strong language in high-fragility skills

---

## Prompt Quality Gates for Generated Skills (Required)

This file is canonical for the generated-skill contract. `SKILL.md` is the
operator-facing summary; when the two differ, follow `reference.md`.

### Instruction Quality Rewrite Pass (Required)

After draft generation:

1. Rewrite vague language into explicit directives.
2. Remove duplicated doctrine across files.
3. Compress low-information prose without dropping hard constraints.
4. Re-run all five prompt quality gates.

A generated skill is incomplete until rewrite and gate re-check both pass.

---

## Decision Rules

1. Keep `SKILL.md` as an operator-facing entry contract, not the full doctrine.
2. Put normative generated-skill structure and compatibility rules in
   `reference.md`.
3. Add support files only when they contribute unique information.
4. Use strong authority language only for high-fragility or fail-closed gates.
5. Stop on blocking validation failures instead of compensating with prose.

## Anti-Patterns

- Monolithic `SKILL.md` files that duplicate the reference manual
- Supporting files that merely reformat `reference.md`
- Runtime-specific features without explicit compatibility disclosure
- Broad bright-line wording in reference material with no boundary condition

---

## Core Concepts

### 1. Skill Architecture
**Definition:** Skills are directory-based extensions with SKILL.md as the required entrypoint. The directory can contain supporting files (templates, examples, scripts) that SKILL.md references for on-demand loading.

**Structure:**
```
my-skill/
├── SKILL.md           # Main instructions (required)
├── template.md        # Template for the agent to fill in
├── examples/
│   └── sample.md      # Example output showing expected format
└── scripts/
    └── validate.sh    # Script the agent can execute
```

### 2. Frontmatter Configuration
**Definition:** YAML between `---` markers at the top of SKILL.md that controls skill behavior. The Agent Skills specification defines these standard fields:

**Standard fields (per agentskills.io):**
| Field | Purpose |
|-------|---------|
| `name` | Display name, becomes /slash-command. Defaults to directory name. The prefix is agent-specific (e.g. `/` in Claude Code, `$` in Codex CLI). |
| `description` | What skill does and when to use it. Agent uses for auto-loading decisions. |
| `license` | License identifier (e.g., MIT, Apache-2.0). |
| `compatibility` | List of compatible agent targets. The spec-defined mechanism for declaring cross-agent requirements. |
| `metadata` | Key-value map for custom metadata. |
| `allowed-tools` | Tools the agent can use without permission when skill active. Broadly supported (16/18 agents per vercel-labs/skills compatibility matrix; not supported by Kiro CLI and Zencoder). |

**Validation Rules:**
| Field | Constraint |
|-------|-----------|
| `name` | Max 64 characters. Lowercase letters, numbers, and hyphens only. No XML tags. |
| `description` | Required (non-empty). Max 1024 characters. No XML tags. |

**Skill Discovery Contract:**

`description` is primarily a trigger contract, not a workflow summary.

Rules:
- Start with `Use when ...` and describe triggering conditions.
- Include user-language symptoms and synonyms that improve discoverability.
- Keep process details in the skill body; do not compress multi-step flow into `description`.
- Write in third person only.

Anti-patterns:
- Workflow summaries in `description` that become shortcut instructions.
- Vague descriptions with no concrete trigger language.
- First-person or second-person point-of-view in frontmatter.

### 3. Invocation Modes
**Definition:** Skills have two invocation paths: automatic (agent decides based on description match) and manual (user types the skill command (e.g. `/skill-name` in Claude Code, `$skill-name` in Codex CLI)). This duality is controlled by frontmatter.

**Matrix:**
| Frontmatter | User can invoke | Agent can invoke | When loaded |
|-------------|-----------------|------------------|-------------|
| (default) | Yes | Yes | Description always in context, full skill on invocation |
| `disable-model-invocation: true` **[Claude Code only]** | Yes | No | Description not in context, full skill when user invokes |
| `user-invocable: false` **[Claude Code only]** | No | Yes | Description always in context, full skill on invocation |

### 4. Scope Hierarchy
**Definition:** Skills exist at multiple levels with higher-priority scopes overriding lower ones when names conflict.

**Resolution order:** Enterprise > Personal > Project > Plugin

| Scope | Path | Applies to |
|-------|------|------------|
| Enterprise | Managed settings | All org users |
| Personal | `~/.claude/skills/<name>/SKILL.md` | All your projects |
| Project | `.claude/skills/<name>/SKILL.md` | This project only |
| Plugin | `<plugin>/skills/<name>/SKILL.md` | Where plugin enabled |

_Paths above are Claude Code-specific. Other agents use their own scope paths (e.g., `.agents/skills/` at project scope). Use `npx skills add` to install to all detected agents._

### 5. Reference vs Task Content
**Definition:** Two fundamental content types that determine how skills are used.

**Reference Content:** Knowledge the agent applies to current work. Conventions, patterns, style guides, domain knowledge. Runs inline with conversation context.

**Task Content:** Step-by-step workflows for specific actions. Often invoked manually. May use `disable-model-invocation: true` **[Claude Code only]** to prevent auto-triggering.

### 6. Progressive Disclosure
**Definition:** Keep SKILL.md focused and concise (prefer 150-350 words) with detailed reference material in supporting files. The agent loads additional files on-demand when needed.

**Why:** Context window is a public good. Large skills consume tokens that could go to user messages or other skills.

**File uniqueness criteria:** Each supporting file must contribute information not present in other files. If a file just reformats content from reference.md, it wastes context rather than saving it.

| File | Contains | Does NOT contain |
|------|----------|-----------------|
| SKILL.md | Overview, decision framework, file index | Detailed procedures or config values |
| reference.md | Domain-specific concepts, procedures, configuration, rubrics | Transferable patterns or usage scenarios |
| patterns.md | Transferable patterns that generalize beyond the domain | Domain procedures already in reference.md |
| examples.md | Usage scenarios that add context beyond reference | Walkthroughs of documented procedures |

**Test:** If removing a supporting file would lose no unique information (everything is in reference.md), that file should not exist.

**Pattern:**
```markdown
## Additional resources
- For complete API details, see [reference.md](reference.md)
- For usage examples, see [examples.md](examples.md)
```

### 6.1 Generated Skill Profile (Default)
For generated skills, default to a compact decision-first contract unless source breadth requires expansion.

**SKILL.md**
- Overview
- When to Use
- Quick Decision Cheatsheet
- Invocation
- Compatibility (only when runtime-specific features require it)
- Supporting Docs

**reference.md**
- TL;DR
- Decision Rules
- Quality Gates
- Anti-Patterns
- Quick Reference
- Source Scope
- Sources

**Supporting files**
- `patterns.md` and `examples.md` are optional
- Include only if they add unique information not present in `reference.md`
- Begin each supporting file with: `Source IDs map to reference.md#sources.`
- Do not create or retain a support file whose main contribution is reformatted
  duplication of `reference.md`.

**Source scope taxonomy**
- Primary platform (normative)
- Supporting foundations (normative when applicable)
- Cross-platform contrast (non-normative)

### 7. Argument Interpolation
**Definition:** **Claude Code extension** — not in agentskills.io spec. Not available on Copilot, Cursor, Codex, or other agents.

Placeholder system for passing data into skills at invocation time (Claude Code only):

| Variable | Description |
|----------|-------------|
| `$ARGUMENTS` | All arguments passed |
| `$ARGUMENTS[N]` | Specific argument by 0-based index |
| `$N` | Shorthand for `$ARGUMENTS[N]` |

**Fallback:** If skill lacks `$ARGUMENTS` placeholder, arguments appended as `ARGUMENTS: <value>`

### 8. Tool Restriction
**Definition:** `allowed-tools` field limits which tools the agent can use when skill is active, enabling safety boundaries.

**Example:**
```yaml
---
name: safe-reader
allowed-tools: Read, Grep, Glob
---
```

---

## Concept Map

1. **SKILL.md** -> contains -> **Frontmatter** + **Markdown Content**
2. **Frontmatter** -> configures -> **Invocation Behavior**
3. **Description** -> determines -> **Auto-loading Decisions**
4. **Scope Hierarchy** -> resolves -> **Name Conflicts**
5. **Reference Content** -> runs -> **Inline with Conversation**
6. **Task Content** -> often uses -> **disable-model-invocation**
7. **Progressive Disclosure** -> reduces -> **Context Consumption**
8. **Supporting Files** -> loaded -> **On-Demand via References**
9. **$ARGUMENTS** -> interpolates -> **User Input**
10. **allowed-tools** -> restricts -> **Available Capabilities**
11. **Description Keywords** -> match -> **User Intent**
12. **Specificity** -> should match -> **Task Fragility**
13. **Rationalization Resistance** -> strengthens -> **High-Stakes Workflows**

---

## Deep Dives

### Context Budget Economy

Skill descriptions are loaded into context so the agent knows what's available. With many skills, they may exceed the character budget.

**Implications:**
- Verbose descriptions crowd out other skills
- Skills with `disable-model-invocation: true` don't contribute to budget (description not loaded)

**Strategy:** Front-load keywords in descriptions. First 100 characters matter most.

### Description as Discovery Interface

Agents use description (and first paragraph if no description) to decide auto-loading. This is the entire discovery mechanism - no semantic search, no embeddings, just keyword matching against user input.

**Writing effective descriptions:**
1. Start with action verb (Explains, Generates, Deploys)
2. Include trigger phrases users would say ("how does this work", "deploy to production")
3. List concrete use cases
4. Avoid generic terms that match everything

**Critical: Write descriptions in third person.** The description is injected into the system prompt - inconsistent point-of-view causes discovery problems.
- Good: "Processes Excel files and generates reports"
- Avoid: "I can help you process Excel files"
- Avoid: "You can use this to process Excel files"

### Specificity Calibration

Match instruction specificity to task fragility:

| Task Type | Fragility | Instruction Style |
|-----------|-----------|-------------------|
| Deployment | High | Explicit steps, verification gates, STOP conditions |
| Code review | Medium | Checklist with flexibility |
| Formatting | Low | Principles, let the agent adapt |

**High fragility indicators:** Side effects, irreversible actions, external systems, user data
**Low fragility indicators:** Local changes, easily undone, no external impact

### Rationalization Resistance

Skills that enforce discipline (like TDD or commit conventions) need to resist agent rationalization. Agents are smart and will find loopholes when under pressure - "the tests are passing so I don't need to write more" or "this is just a small change so I'll skip the checklist."

**Techniques:**
- Use explicit verification gates with STOP conditions
- Employ commitment language ("I will complete all steps before proceeding")
- Include checklists that the agent must check off
- Reference authority (team standards, documented requirements)
- Add social proof ("This is how the team handles these cases")

**Psychology foundation:** Understanding WHY persuasion techniques work helps apply them systematically. Research from Cialdini (2021) and Meincke et al. (2025) identifies six principles: authority, commitment, scarcity, social proof, reciprocity, and unity. See [persuasion-principles.md](persuasion-principles.md) for detailed application guidance.

### Scope Resolution Mechanics

When skills share names across scopes:
1. Enterprise scope wins unconditionally
2. Personal overrides Project
3. Project overrides Plugin
4. Plugin uses namespace (`plugin-name:skill-name`) so can't conflict

### Subagent Orchestration

**[Claude Code]** Claude Code provides a structured subagent system for delegating work from a parent conversation. Other agents use natural language delegation only — no structured dispatch.

**Built-in subagent types** — use the lightest type that fits the task:

| Type | Model | Tools | Use when |
|------|-------|-------|----------|
| Explore | Haiku (fast, cheap) | Read, Grep, Glob only | Codebase research, log scanning, read-only analysis |
| Plan | Inherits parent model | Read, Grep, Glob only | Strategic planning requiring full reasoning but no writes |
| General-purpose | Inherits parent model | All tools | Tasks requiring file creation, edits, or command execution |

**Foreground vs background dispatch:**
- **Foreground** — blocks the parent conversation. Permissions pass through to the user (prompts appear as normal). Use for tasks where the parent needs the result before continuing.
- **Background** — runs concurrently with the parent. Pre-approved permissions execute silently; unapproved permissions are auto-denied (not prompted). Use for independent research or batch operations that don't gate the main workflow.

**Orchestration patterns:**
- **Parallel research** — spawn multiple independent subagents simultaneously (background), each investigating a different question. Collect summaries when all complete.
- **Chaining** — sequential handoff where each subagent's output feeds the next. Use foreground dispatch to ensure ordering.
- **Skill preloading** — the `skills:` array in subagent configuration injects full skill content at startup, giving the subagent domain knowledge without requiring it to discover and load skills.

**Failure modes:**
- Background subagent failure does not crash the parent — the parent resumes in foreground and can retry or take a different approach.
- Subagents cannot nest — a subagent cannot spawn its own subagents. Design orchestration as a single level of fan-out.

**Cross-agent note:** All structured dispatch above is Claude Code-specific. For cross-agent skills, use natural language delegation ("Delegate this task to a subagent") which works on any agent that supports delegation. [Source 4] [Source 5]

### Choosing the Right Mechanism

Not every use case belongs in a skill. Claude Code offers four mechanisms for extending agent behaviour; choosing the wrong one wastes tokens, reduces reliability, or bypasses enforcement guarantees.

| Mechanism | Loaded | Best for | Example |
|-----------|--------|----------|---------|
| Persistent config (CLAUDE.md) | Every session, automatically | Always-on rules: style, conventions, project context | "Use British spelling in all comments" |
| Skill (SKILL.md) | On-demand, when relevant | Task-specific workflows and domain knowledge | "Generate a database migration from this schema diff" |
| Hook [Claude Code] | Every matching lifecycle event | Deterministic enforcement with zero AI discretion | "Block git push if tests haven't passed" (exit code 2 blocks the action) |
| Subagent definition [Claude Code] | When orchestrator dispatches | Custom agent configs with specific tools, permissions, model | "Code review agent restricted to Read + Grep, running Haiku" |

**Hooks** fire on lifecycle events (PreToolUse, PostToolUse, Stop) and run shell commands deterministically. They are not AI-mediated — the shell command's exit code controls the outcome. Use hooks when enforcement must be 100% reliable regardless of prompt interpretation.

**Subagent definitions** configure reusable agent profiles with constrained tools, permissions, and model selection. They orchestrate task execution, not knowledge injection — use skills for knowledge, subagent definitions for dispatch.

**Decision aid:**
- If the instruction should apply to nearly every session → persistent config
- If the instruction is task-specific, loaded on demand → skill
- If enforcement must be deterministic with no AI discretion → hook
- If the use case is a custom agent with restricted tools/model → subagent definition

**Anti-pattern:** Generating a skill for a use case better served by persistent config, hooks, or subagent definitions. Generated skills should include a "Why a skill?" note when the use case is borderline. [Source 4] [Source 5]

---

## Quick Reference

### Frontmatter Fields
```yaml
---
name: skill-name              # /slash-command name
description: What and when    # Discovery keywords
license: none                 # SPDX license identifier
allowed-tools: Read, Grep     # Tool restrictions
compatibility:                # Compatible agents
  - claude-code
  - codex
  - github-copilot
metadata:                     # Custom key-value pairs
  author: your-name
  version: "1.0.0"
---
```

### String Substitutions (Claude Code extension)
| Variable | Value |
|----------|-------|
| `$ARGUMENTS` | All arguments |
| `$ARGUMENTS[N]` | Nth argument (0-indexed) |
| `$N` | Shorthand for $ARGUMENTS[N] |

### Scope Paths (Claude Code)
| Scope | Path |
|-------|------|
| Personal | `~/.claude/skills/<name>/SKILL.md` |
| Project | `.claude/skills/<name>/SKILL.md` |
| Plugin | `<plugin>/skills/<name>/SKILL.md` |

_Other agents use their own paths. Use `npx skills add` to install to all detected agents._

### Invocation Control
| Goal | Frontmatter |
|------|-------------|
| User-only (hide from agent) | **[Claude Code only]** `disable-model-invocation: true` |
| Agent-only (hide from menu) | **[Claude Code only]** `user-invocable: false` |
| Both (default) | (no fields needed) |

---

## Sources

1. **Agent Skills Specification** - https://agentskills.io/specification
   - Canonical standard for skill structure, frontmatter fields, and cross-agent compatibility

2. **Anthropic Skill Authoring Best Practices** - https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
   - Claude-specific principles for effective skill writing including context efficiency and specificity calibration

3. **OpenAI Codex Skills** - https://developers.openai.com/codex/skills
   - Codex discovery, invocation, and skill authoring best practices

4. **Claude Code Sub-Agents Documentation** - https://docs.anthropic.com/en/docs/claude-code/sub-agents
   - Subagent types, configuration, context management, orchestration patterns

5. **Claude Code Best Practices** - https://docs.anthropic.com/en/docs/claude-code/best-practices
   - Hooks, context management, verification patterns, mechanism selection
