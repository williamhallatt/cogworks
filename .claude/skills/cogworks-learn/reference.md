# Skill Writer - Complete Reference

Synthesized from Official Claude Code Documentation and Anthropic Best Practices.

---

## TL;DR

Claude Code Skills are SKILL.md files that extend Claude's capabilities through YAML frontmatter (configuration) and markdown content (instructions). Skills live in directory structures at various scopes (Enterprise > Personal > Project > Plugin) and can be invoked automatically by Claude when relevant or manually via `/slash-commands`. Effective skills are concise (context window is a public good), use progressive disclosure (SKILL.md as overview pointing to reference files loaded on-demand), and match specificity to task fragility. The description field is critical for discovery - Claude uses it to decide when to load the skill from potentially 100+ available options. Advanced features include dynamic context injection (`!`command``), subagent execution (`context: fork`), argument interpolation (`$ARGUMENTS`, `$N`), and tool restrictions (`allowed-tools`).

---

## Table of Contents

- [Core Concepts](#core-concepts) - Architecture, frontmatter, invocation, scope, content types
- [Concept Map](#concept-map) - 15 relationships between concepts
- [Deep Dives](#deep-dives) - Context budget, discovery, specificity, rationalization resistance
- [Quick Reference](#quick-reference) - Frontmatter fields, substitutions, paths
- [Sources](#sources) - Bibliography

## Related Files

- [patterns.md](patterns.md) - 10 reusable patterns + 8 anti-patterns
- [examples.md](examples.md) - 12 complete practical examples

---

## Core Concepts

### 1. Skill Architecture
**Definition:** Skills are directory-based extensions with SKILL.md as the required entrypoint. The directory can contain supporting files (templates, examples, scripts) that SKILL.md references for on-demand loading.

**Structure:**
```
my-skill/
├── SKILL.md           # Main instructions (required)
├── template.md        # Template for Claude to fill in
├── examples/
│   └── sample.md      # Example output showing expected format
└── scripts/
    └── validate.sh    # Script Claude can execute
```

### 2. Frontmatter Configuration
**Definition:** YAML between `---` markers at the top of SKILL.md that controls skill behavior. All fields are optional except description (recommended).

**Fields:**
| Field | Purpose |
|-------|---------|
| `name` | Display name, becomes /slash-command. Defaults to directory name. |
| `description` | What skill does and when to use it. Claude uses for auto-loading decisions. |
| `argument-hint` | Hint shown during autocomplete, e.g., `[issue-number]` |
| `disable-model-invocation` | `true` prevents Claude auto-loading. For user-controlled workflows. |
| `user-invocable` | `false` hides from / menu. For background knowledge. |
| `allowed-tools` | Tools Claude can use without permission when skill active. |
| `model` | Model to use when skill active. |
| `context` | `fork` runs in isolated subagent. |
| `agent` | Subagent type when `context: fork` set. |
| `hooks` | Lifecycle hooks scoped to this skill. |

### 3. Invocation Duality
**Definition:** Skills have two invocation paths: automatic (Claude decides based on description match) and manual (user types /skill-name). This duality is controlled by frontmatter.

**Matrix:**
| Frontmatter | User can invoke | Claude can invoke | When loaded |
|-------------|-----------------|-------------------|-------------|
| (default) | Yes | Yes | Description always in context, full skill on invocation |
| `disable-model-invocation: true` | Yes | No | Description not in context, full skill when user invokes |
| `user-invocable: false` | No | Yes | Description always in context, full skill on invocation |

### 4. Scope Hierarchy
**Definition:** Skills exist at four levels with higher-priority scopes overriding lower ones when names conflict.

**Resolution order:** Enterprise > Personal > Project > Plugin

| Scope | Path | Applies to |
|-------|------|------------|
| Enterprise | Managed settings | All org users |
| Personal | `~/.claude/skills/<name>/SKILL.md` | All your projects |
| Project | `.claude/skills/<name>/SKILL.md` | This project only |
| Plugin | `<plugin>/skills/<name>/SKILL.md` | Where plugin enabled |

### 5. Reference vs Task Content
**Definition:** Two fundamental content types that determine how skills are used.

**Reference Content:** Knowledge Claude applies to current work. Conventions, patterns, style guides, domain knowledge. Runs inline with conversation context.

**Task Content:** Step-by-step workflows for specific actions. Often invoked manually. May use `disable-model-invocation: true` to prevent auto-triggering.

### 6. Progressive Disclosure
**Definition:** Keep SKILL.md focused (~100-500 lines) with detailed reference material in supporting files. Claude loads additional files on-demand when needed.

**Why:** Context window is a public good. Large skills consume tokens that could go to user messages or other skills.

**Pattern:**
```markdown
## Additional resources
- For complete API details, see [reference.md](reference.md)
- For usage examples, see [examples.md](examples.md)
```

### 7. Dynamic Context Injection
**Definition:** The `!`command`` syntax runs shell commands before skill content reaches Claude. Output replaces the placeholder.

**Example:**
```yaml
---
name: pr-summary
context: fork
---
## Pull request context
- PR diff: !`gh pr diff`
- PR comments: !`gh pr view --comments`
```

**Execution:** Commands run immediately (preprocessing), Claude only sees final rendered output.

### 8. Subagent Execution
**Definition:** `context: fork` runs skills in isolated contexts without conversation history. Skill content becomes the subagent's task.

**Warning:** Only makes sense for skills with explicit instructions. Guidelines without a task produce no meaningful output.

**Agent types:** `Explore` (read-only), `Plan`, `general-purpose`, or custom from `.claude/agents/`

### 9. Argument Interpolation
**Definition:** Placeholder system for passing data into skills at invocation time.

| Variable | Description |
|----------|-------------|
| `$ARGUMENTS` | All arguments passed |
| `$ARGUMENTS[N]` | Specific argument by 0-based index |
| `$N` | Shorthand for `$ARGUMENTS[N]` |
| `${CLAUDE_SESSION_ID}` | Current session ID |

**Fallback:** If skill lacks `$ARGUMENTS` placeholder, arguments appended as `ARGUMENTS: <value>`

### 10. Tool Restriction
**Definition:** `allowed-tools` field limits which tools Claude can use when skill is active, enabling safety boundaries.

**Example:**
```yaml
---
name: safe-reader
allowed-tools: Read, Grep, Glob
---
```

---

## Concept Map

1. **SKILL.md** → contains → **Frontmatter** + **Markdown Content**
2. **Frontmatter** → configures → **Invocation Behavior**
3. **Description** → determines → **Auto-loading Decisions**
4. **Scope Hierarchy** → resolves → **Name Conflicts**
5. **Reference Content** → runs → **Inline with Conversation**
6. **Task Content** → often uses → **disable-model-invocation**
7. **Progressive Disclosure** → reduces → **Context Consumption**
8. **Supporting Files** → loaded → **On-Demand via References**
9. **context: fork** → creates → **Isolated Subagent**
10. **agent field** → selects → **Subagent Type**
11. **$ARGUMENTS** → interpolates → **User Input**
12. **allowed-tools** → restricts → **Available Capabilities**
13. **Dynamic Context** → preprocesses → **Shell Commands**
14. **Description Keywords** → match → **User Intent**
15. **Specificity** → should match → **Task Fragility**
16. **Rationalization Resistance** → strengthens → **High-Stakes Workflows**

---

## Deep Dives

### Context Budget Economy

Skill descriptions are loaded into context so Claude knows what's available. With many skills, they may exceed the character budget (2% of context window, fallback 16,000 characters).

**Implications:**
- Verbose descriptions crowd out other skills
- Skills with `disable-model-invocation: true` don't contribute to budget (description not loaded)
- Run `/context` to check for excluded skills warning
- Override limit with `SLASH_COMMAND_TOOL_CHAR_BUDGET` environment variable

**Strategy:** Front-load keywords in descriptions. First 100 characters matter most.

### Description as Discovery Interface

Claude uses description (and first paragraph if no description) to decide auto-loading. This is the entire discovery mechanism - no semantic search, no embeddings, just keyword matching against user input.

**Writing effective descriptions:**
1. Start with action verb (Explains, Generates, Deploys)
2. Include trigger phrases users would say ("how does this work", "deploy to production")
3. List concrete use cases
4. Avoid generic terms that match everything

### Specificity Calibration

Match instruction specificity to task fragility:

| Task Type | Fragility | Instruction Style |
|-----------|-----------|-------------------|
| Deployment | High | Explicit steps, verification gates, STOP conditions |
| Code review | Medium | Checklist with flexibility |
| Formatting | Low | Principles, let Claude adapt |

**High fragility indicators:** Side effects, irreversible actions, external systems, user data
**Low fragility indicators:** Local changes, easily undone, no external impact

### Rationalization Resistance

Skills that enforce discipline (like TDD or commit conventions) need to resist agent rationalization. Agents are smart and will find loopholes when under pressure—"the tests are passing so I don't need to write more" or "this is just a small change so I'll skip the checklist."

**Techniques:**
- Use explicit verification gates with STOP conditions
- Employ commitment language ("I will complete all steps before proceeding")
- Include checklists that Claude must check off
- Reference authority (team standards, documented requirements)
- Add social proof ("This is how the team handles these cases")

**Psychology foundation:** Understanding WHY persuasion techniques work helps apply them systematically. Research from Cialdini (2021) and Meincke et al. (2025) identifies six principles: authority, commitment, scarcity, social proof, reciprocity, and unity. See [persuasion-principles.md](persuasion-principles.md) for detailed application guidance.

### Subagent Execution Model

When `context: fork` is set:
1. New isolated context created (no conversation history)
2. Skill content becomes the subagent's task prompt
3. Agent type (Explore, Plan, etc.) provides system prompt and tool configuration
4. CLAUDE.md loaded into subagent context
5. Results summarized and returned to main conversation

**Key insight:** The skill IS the task. Don't write guidelines for a forked skill - write explicit instructions for what you want done.

### Scope Resolution Mechanics

When skills share names across scopes:
1. Enterprise scope wins unconditionally
2. Personal overrides Project
3. Project overrides Plugin
4. Plugin uses namespace (`plugin-name:skill-name`) so can't conflict

Nested directory discovery adds complexity: editing `packages/frontend/src/App.tsx` also searches `packages/frontend/.claude/skills/`.

---

## Quick Reference

### Frontmatter Fields
```yaml
---
name: skill-name              # /slash-command name
description: What and when    # Discovery keywords
argument-hint: [arg1] [arg2]  # Autocomplete hint
disable-model-invocation: true # User-only invocation
user-invocable: false         # Claude-only invocation
allowed-tools: Read, Grep     # Tool restrictions
model: claude-3-opus          # Model override
context: fork                 # Subagent execution
agent: Explore                # Subagent type
hooks: {}                     # Lifecycle hooks
---
```

### String Substitutions
| Variable | Value |
|----------|-------|
| `$ARGUMENTS` | All arguments |
| `$ARGUMENTS[N]` | Nth argument (0-indexed) |
| `$N` | Shorthand for $ARGUMENTS[N] |
| `${CLAUDE_SESSION_ID}` | Current session ID |
| `!`command`` | Shell command output |

### Scope Paths
| Scope | Path |
|-------|------|
| Personal | `~/.claude/skills/<name>/SKILL.md` |
| Project | `.claude/skills/<name>/SKILL.md` |
| Plugin | `<plugin>/skills/<name>/SKILL.md` |

### Invocation Control
| Goal | Frontmatter |
|------|-------------|
| User-only (hide from Claude) | `disable-model-invocation: true` |
| Claude-only (hide from menu) | `user-invocable: false` |
| Both (default) | (no fields needed) |

### Agent Types for `context: fork`
- `Explore` - Read-only, codebase exploration
- `Plan` - Planning and analysis
- `general-purpose` - Default, full capabilities
- Custom: any `.claude/agents/*.md` file

---

## Sources

1. **Claude Code Skills Documentation** - https://docs.anthropic.com/en/docs/claude-code/skills
   - Official reference for skill creation, configuration, and advanced patterns

2. **Skill Authoring Best Practices** - Anthropic internal documentation
   - Principles for effective skill writing including context efficiency and specificity calibration
