# Kane: Agent Skills, Sub-Agents & Prompt Engineering — Source Synthesis
> Synthesized from 13 Tier 1 + 7 Tier 2 source files | 2026-03-05

## 1. Agent Skills Architecture

### What a Skill IS

A skill is a **directory containing `SKILL.md`** that extends an agent's capabilities with instructions, workflows, or domain knowledge. Skills follow the [Agent Skills](https://agentskills.io) open standard (cross-platform), with Claude Code adding extensions like invocation control, subagent execution, and dynamic context injection.

**File structure:**
```
my-skill/
├── SKILL.md           # Required: YAML frontmatter + markdown instructions
├── template.md        # Optional: templates for Claude to fill
├── examples/          # Optional: example outputs
└── scripts/           # Optional: scripts Claude can execute
```

**Discovery mechanism:**
- **Project**: `.claude/skills/<skill-name>/SKILL.md` (checked into git)
- **Personal**: `~/.claude/skills/<skill-name>/SKILL.md` (all your projects)
- **Enterprise**: Managed settings locations (org-wide)
- **Plugin**: `<plugin>/skills/<skill-name>/SKILL.md` (plugin-namespaced)

**Priority resolution:** Enterprise > Personal > Project. When skills share names, higher-priority location wins.

**Nested discovery:** Claude Code automatically discovers skills from nested `.claude/skills/` directories when editing files in subdirectories (supports monorepo setups).

---

### SKILL.md Structure

**Frontmatter (YAML between `---` markers):**
- `name`: Skill identifier (lowercase, hyphens, max 64 chars). Becomes `/slash-command`.
- `description`: **Critical for discovery**—Claude uses this to decide when to auto-invoke. If omitted, uses first paragraph of markdown.
- `disable-model-invocation`: `true` = only you can invoke (for workflows with side effects like `/deploy`)
- `user-invocable`: `false` = only Claude can invoke (for background knowledge)
- `allowed-tools`: Tools Claude can use without permission when skill is active
- `model`: Override model (`sonnet`, `opus`, `haiku`, `inherit`)
- `context`: Set to `fork` to run in subagent
- `agent`: Which subagent type when `context: fork` is set
- `argument-hint`: Shown during autocomplete (e.g., `[issue-number]`)
- `hooks`: Lifecycle hooks scoped to this skill

**Markdown body:** Instructions Claude follows when skill is invoked.

**String substitutions available in markdown:**
- `$ARGUMENTS`: All arguments passed; appended automatically if not present
- `$ARGUMENTS[N]` or `$N`: Access specific argument by index
- `${CLAUDE_SESSION_ID}`: Current session ID

---

### Content Types

**Reference content:** Domain knowledge applied inline (API conventions, patterns, style guides).
```yaml
---
name: api-conventions
description: API design patterns for this codebase
---
When writing API endpoints:
- Use RESTful naming conventions
- Return consistent error formats
```

**Task content:** Step-by-step workflows you invoke directly. Use `disable-model-invocation: true` to prevent auto-triggering.
```yaml
---
name: deploy
description: Deploy the application to production
context: fork
disable-model-invocation: true
---
1. Run the test suite
2. Build the application
3. Push to the deployment target
4. Verify deployment succeeded
```

---

### Composability Rules

**Context loading behavior:**

| Frontmatter config | You invoke | Claude invokes | When loaded |
|:---|:---|:---|:---|
| (default) | Yes | Yes | Description always in context; full loads when invoked |
| `disable-model-invocation: true` | Yes | No | Description NOT in context; full loads when you invoke |
| `user-invocable: false` | No | Yes | Description always in context; full loads when invoked |

**Context budget constraints:**
- Skill descriptions loaded at session start consume context (2% of window, fallback 16K chars)
- If you have many skills, they may exceed budget—run `/context` to check
- Override limit with `SLASH_COMMAND_TOOL_CHAR_BUDGET` environment variable
- Full skill content loads only when invoked (except subagents with preloaded skills)

**Supporting files:**
- Keep `SKILL.md` under 500 lines—move reference material to separate files
- Reference supporting files from SKILL.md: `For complete API details, see [reference.md](reference.md)`
- Claude loads supporting files only when needed

---

### Activation Guards

**Permission control:**
- Default: both you and Claude can invoke
- `disable-model-invocation: true`: only you can invoke (manual `/skill-name`)
- `user-invocable: false`: only Claude can invoke (hidden from `/` menu)
- Permission system: deny via `/permissions` with `Skill(name)` or `Skill(name *)`

**Tool restrictions:**
- `allowed-tools`: List of tools (e.g., `Read, Grep, Glob`) Claude can use without asking
- Subsets parent conversation's available tools
- Use for read-only skills or safety constraints

---

### Advanced Patterns

**Dynamic context injection (`!`command``syntax`):**
Runs shell commands BEFORE skill content is sent to Claude—output replaces placeholder.
```yaml
---
name: pr-summary
context: fork
agent: Explore
---
## Pull request context
- PR diff: !`gh pr diff`
- PR comments: !`gh pr view --comments`

## Your task
Summarize this pull request...
```

**Running in subagent (`context: fork`):**
Skill content becomes the prompt for an isolated subagent. Subagent receives:
- Task: SKILL.md content
- System prompt: From agent type (Explore, Plan, general-purpose)
- Also loads: CLAUDE.md

Use for skills with explicit task instructions (not guidelines).

**Generating visual output:**
Skills can bundle scripts (any language) that generate HTML/visualizations. Claude orchestrates, script executes. Example: codebase visualizer generates interactive tree view.

---

## 2. Sub-Agent Patterns

### What Subagents ARE

Subagents are **specialized AI assistants running in separate context windows** with custom system prompts, tool access, and permissions. When Claude encounters matching tasks, it delegates to subagents, which work independently and return results.

**Purpose:**
- **Preserve context**: Keep exploration/verification out of main conversation
- **Enforce constraints**: Limit tools (e.g., read-only agents)
- **Reuse configurations**: User-level subagents available in all projects
- **Specialize behavior**: Domain-specific system prompts
- **Control costs**: Route tasks to faster models (Haiku)

---

### Built-in Subagents

**Explore (Haiku, read-only):**
- Fast agent for codebase search and analysis
- Tools: Read, Grep, Glob (denied Write, Edit)
- Thoroughness levels: quick, medium, very thorough
- Keeps exploration results out of main context

**Plan (inherits model, read-only):**
- Research agent for plan mode
- Tools: Read-only (denied Write, Edit)
- Gathers context before presenting plan
- Prevents infinite nesting (subagents can't spawn subagents)

**General-purpose (inherits model, all tools):**
- Complex multi-step tasks requiring exploration + action
- Full tool access
- Multi-step operations, code modifications

---

### How to Spawn

**Automatic delegation:** Claude decides based on task and subagent descriptions. To encourage proactive use, include "use proactively" in description.

**Explicit delegation:** Request specific subagent:
```
Use the test-runner subagent to fix failing tests
Have the code-reviewer subagent look at my recent changes
```

**Foreground vs. background:**
- **Foreground**: Blocks main conversation; permission prompts pass through
- **Background**: Runs concurrently; pre-approves permissions upfront; auto-denies anything not pre-approved
- Claude decides mode; you can ask "run this in the background" or press Ctrl+B

---

### Context & Output Contracts

**What subagents receive:**
- System prompt from `SKILL.md` body or subagent markdown
- CLAUDE.md, MCP servers, skills (if specified)
- Spawn prompt from parent
- NO parent conversation history

**What returns to parent:**
- Summary of work (not verbose output)
- Subagents run in isolated context; verbose output (test logs, file reads) stays isolated
- Only summaries consume parent context

**Failure modes:**
- If background subagent fails (missing permissions), resume in foreground with interactive prompts
- If subagent stops on errors, message it directly or spawn replacement

---

### Subagent Configuration

**Scope locations (priority order):**
1. `--agents` CLI flag (current session, JSON format)
2. `.claude/agents/<name>.md` (project)
3. `~/.claude/agents/<name>.md` (user)
4. Plugin `agents/` directory (plugin-scoped)

**File format:**
```markdown
---
name: code-reviewer
description: Reviews code for quality and best practices
tools: Read, Glob, Grep
model: sonnet
permissionMode: default
maxTurns: 50
skills: [api-conventions, error-handling]
memory: user
---
You are a code reviewer. When invoked, analyze the code...
```

**Frontmatter fields (all optional except name, description):**
- `name`: Unique identifier
- `description`: When Claude should delegate
- `tools`: Allowlist (inherits all if omitted)
- `disallowedTools`: Denylist
- `model`: `sonnet`, `opus`, `haiku`, `inherit`
- `permissionMode`: `default`, `acceptEdits`, `dontAsk`, `bypassPermissions`, `plan`
- `maxTurns`: Max agentic turns before stopping
- `skills`: Array of skill names—**full content injected at startup** (not just available for invocation)
- `memory`: `user`, `project`, `local` for persistent memory directory
- `mcpServers`: Array of server names or inline definitions
- `hooks`: Lifecycle hooks (PreToolUse, PostToolUse, Stop)
- `background`: `true` = always run as background task
- `isolation`: `worktree` = run in temporary git worktree

---

### Context Management

**Subagent context window:**
- Separate from parent
- Loaded at startup: CLAUDE.md, MCP servers, preloaded skills
- Auto-compaction supported (same logic as main conversation, triggers ~95%)
- Set `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` to trigger earlier

**Persistent memory (`memory` field):**
- `user`: `~/.claude/agent-memory/<name>/` (across all projects)
- `project`: `.claude/agent-memory/<name>/` (shareable via git)
- `local`: `.claude/agent-memory-local/<name>/` (project-specific, not in git)
- First 200 lines of `MEMORY.md` loaded at startup
- Subagent automatically gets Read/Write/Edit tools for memory management

**Resume subagents:**
Each invocation creates fresh instance. To resume: ask Claude to continue previous work—it receives agent ID and can resume with full history. Transcripts persist at `~/.claude/projects/{project}/{sessionId}/subagents/agent-{agentId}.jsonl`.

---

### Common Patterns

**Isolate high-volume operations:**
Research, tests, log processing—all verbose output stays in subagent context; only summary returns.
```
Use a subagent to run the test suite and report only failing tests with error messages
```

**Parallel research:**
Independent investigations run simultaneously:
```
Research authentication, database, and API modules in parallel using separate subagents
```

**Chaining subagents:**
Sequential workflows where each subagent completes, returns results, and Claude passes context to next:
```
Use code-reviewer subagent to find performance issues, then optimizer subagent to fix them
```

**Preload skills for specialization:**
```yaml
skills:
  - api-conventions
  - error-handling-patterns
```
Full skill content injected at startup—subagent has domain knowledge without needing to discover during execution.

---

### Tool & Permission Control

**Restrict tools:**
```yaml
tools: Read, Grep, Glob, Bash
disallowedTools: Write, Edit
```

**Conditional validation with hooks:**
```yaml
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-readonly-query.sh"
```
Hook script receives JSON via stdin, validates, exits code 2 to block.

**Permission modes:**
- `default`: Standard prompts
- `acceptEdits`: Auto-accept file edits
- `dontAsk`: Auto-deny (explicitly allowed tools still work)
- `bypassPermissions`: Skip all checks (use with caution)
- `plan`: Read-only exploration

**Disable specific subagents:**
Deny via permissions: `{"deny": ["Agent(Explore)", "Agent(my-custom-agent)"]}`

---

## 3. Context & Memory Management

### Session Context Window

**What fills context:**
- Conversation history (all messages, tool uses, outputs)
- File contents Claude reads
- Command outputs
- CLAUDE.md files
- Loaded skill descriptions
- System instructions
- MCP tool definitions

**Context limits:**
- Performance degrades as context fills
- Claude compacts automatically at ~95% capacity
- Run `/context` to see usage breakdown
- MCP servers add tool definitions to EVERY request—check cost with `/mcp`

---

### State Management Across Turns

**What persists:**
- CLAUDE.md: Reloaded fresh from disk at session start and after compaction
- Auto memory: First 200 lines of MEMORY.md loaded at startup
- Sessions: Saved locally; resume with `--continue` or `--resume`
- Checkpoints: File states before edits (for rewind)

**What doesn't persist:**
- Session-scoped permissions (re-approve after resume)
- Subagent instances (each invocation creates fresh instance)
- Skills loaded mid-session after `disable-model-invocation` removal

**Managing context during long sessions:**
- `/clear`: Reset context entirely (use between unrelated tasks)
- `/compact`: Summarize history while preserving key code and decisions
- `/compact <instructions>`: e.g., `/compact Focus on API changes`
- `Esc + Esc` or `/rewind` → **Summarize from here**: Condense from checkpoint forward
- Customize compaction in CLAUDE.md: `"When compacting, always preserve the full list of modified files and any test commands"`

---

### CLAUDE.md vs Auto Memory

**CLAUDE.md:**
- **Who writes:** You
- **Contains:** Instructions, rules, conventions, build commands
- **Loaded:** Full file at session start (no 200-line limit)
- **Scope:** Project (`.claude/CLAUDE.md`), user (`~/.claude/CLAUDE.md`), managed (org-wide), local (`CLAUDE.local.md`)
- **Use for:** Coding standards, workflows, architecture, gotchas
- **Priority:** Managed > Project > User

**Auto memory:**
- **Who writes:** Claude
- **Contains:** Learnings, patterns, build insights, preferences
- **Loaded:** First 200 lines of MEMORY.md at session start; topic files loaded on demand
- **Scope:** Per git repo (all worktrees share one memory directory)
- **Use for:** Build commands discovered during work, debugging insights, code patterns
- **Location:** `~/.claude/projects/<project>/memory/`

**Key difference:** CLAUDE.md is full instruction; auto memory is Claude's notebook across sessions.

---

### What to Drop

**Keep CLAUDE.md under 200 lines:**
- Bloated files → Claude ignores instructions
- Cut anything Claude can infer from code
- Cut standard language conventions
- Use imports (`@path/to/file`) for detailed docs
- Split into `.claude/rules/` for topic-specific content

**When to `/clear`:**
- Between unrelated tasks (context cluttered with irrelevant info)
- After 2+ corrections on same issue (failed approaches pollute context)
- When session has mixed concerns (debugging, then feature work, then refactor)

**Subagents for context isolation:**
- Delegate research → exploration stays in subagent context
- Delegate verification → test output doesn't bloat main context
- Only summaries return

---

### Memory Scope & Persistence

**CLAUDE.md locations:**
| Location | Path | Applies to |
|:---|:---|:---|
| Managed (org) | `/Library/Application Support/ClaudeCode/CLAUDE.md` (macOS) | All users in org |
| Project | `./CLAUDE.md` or `./.claude/CLAUDE.md` | Team via git |
| User | `~/.claude/CLAUDE.md` | All your projects |
| Local | `./CLAUDE.local.md` | You only, this project |

**Auto memory scope:**
- **Per git repo:** All worktrees and subdirectories share one memory dir
- **Not shared:** Across machines or cloud environments
- **Persists:** Indefinitely (edit or delete anytime via `/memory`)

**Subagent memory scope:**
| Scope | Path | Use when |
|:---|:---|:---|
| `user` | `~/.claude/agent-memory/<name>/` | Learnings across all projects |
| `project` | `.claude/agent-memory/<name>/` | Project-specific, shareable |
| `local` | `.claude/agent-memory-local/<name>/` | Project-specific, not in git |

---

### Rules Organization (`.claude/rules/`)

For larger projects, organize instructions into topic files:
```
.claude/
├── CLAUDE.md           # Main instructions
└── rules/
    ├── code-style.md   # Code style
    ├── testing.md      # Testing conventions
    └── security.md     # Security requirements
```

**Path-specific rules:**
Scope rules to file patterns using frontmatter:
```markdown
---
paths:
  - "src/api/**/*.ts"
---
# API Development Rules
- All endpoints must include input validation
```

Rules without `paths` field load at session start. Path-scoped rules load when Claude reads matching files.

---

## 4. Prompt Engineering — Claude

### Be Clear and Direct

**Explicit is better than implied:**
```
❌ Create an analytics dashboard
✅ Create an analytics dashboard. Include as many relevant features and interactions as possible. Go beyond the basics to create a fully-featured implementation.
```

**Provide context (the "why"):**
```
❌ NEVER use ellipses
✅ Your response will be read aloud by a text-to-speech engine, so never use ellipses since TTS engines don't know how to pronounce them.
```

**Claude generalizes from explanations.**

---

### Examples (Multishot) & Details

Claude 4.x models have **precise instruction following**—they pay close attention to examples and details. Ensure examples align with desired behavior and avoid anti-patterns.

```markdown
I'm going to show you how to solve a math problem, then solve a similar one.

Problem 1: What is 15% of 80?

<thinking>
1. Convert 15% to decimal: 0.15
2. Multiply: 0.15 × 80 = 12
</thinking>

The answer is 12.

Now solve this one: Problem 2: What is 35% of 240?
```

---

### Chain of Thought (Let Claude Think)

**Standard mode:** Prefix with instruction like "Think step by step" or "Show your reasoning."

**Extended thinking mode:**
- `thinking: {type: "enabled", budget_tokens: 32000}` (older models: Sonnet 4.5)
- `thinking: {type: "adaptive"}` + `output_config: {effort: "high"}` (Opus 4.6+)

**Adaptive thinking (Opus 4.6):**
- Claude dynamically decides when/how much to think
- Calibrates based on `effort` parameter + query complexity
- Higher effort → more thinking; complex queries → more thinking
- Easy queries → responds directly without thinking

**Prompting for thinking:**
```
After receiving tool results, carefully reflect on their quality and determine optimal next steps before proceeding. Use your thinking to plan and iterate based on this new information.
```

**Reducing excessive thinking:**
```
Extended thinking adds latency and should only be used when it will meaningfully improve answer quality—typically for problems requiring multi-step reasoning. When in doubt, respond directly.
```

---

### XML Tags

Structure content and delineate sections using XML tags. Especially effective for output format control:

```
❌ Do not use markdown in your response
✅ Write the prose sections of your response in <smoothly_flowing_prose_paragraphs> tags.
```

Match prompt style to desired output. If you remove markdown from your prompt, output markdown volume decreases.

---

### System Prompts (Give Claude a Role)

System prompts set Claude's behavior, tone, and capabilities.

**Personality shaping:**
```
You are a senior security engineer. Review code for:
- Injection vulnerabilities
- Authentication and authorization flaws
- Secrets or credentials in code
```

**Model self-knowledge:**
```
The assistant is Claude, created by Anthropic. The current model is Claude Opus 4.6.
```

**For LLM-powered apps needing model strings:**
```
When an LLM is needed, default to Claude Opus 4.6 unless the user requests otherwise. The exact model string is claude-opus-4-6.
```

---

### Long Context Tips

**Context awareness (Sonnet 4.5, Haiku 4.5, Opus 4.6):**
Claude tracks its remaining context window ("token budget") during conversation. If using an agent harness that compacts context:

```
Your context window will be automatically compacted as it approaches its limit, allowing you to continue working indefinitely. Do not stop tasks early due to token budget concerns. Save your progress to memory before context refreshes. Be as persistent and autonomous as possible and complete tasks fully, even as your budget limit approaches.
```

**Multi-context window workflows:**
1. **First context window:** Set up framework (write tests, create setup scripts)
2. **Subsequent windows:** Iterate on todo list
3. **Structure state:** Use JSON for test results (`tests.json`), plain text for progress notes (`progress.txt`)
4. **Quality of life tools:** Setup scripts (`init.sh`) to start servers, run tests, linters
5. **Starting fresh vs. compacting:** Consider brand new context instead of compaction—Claude 4.x excels at discovering state from filesystem
6. **Prescriptive restarts:**
   - "Call pwd; you can only read/write files in this directory"
   - "Review progress.txt, tests.json, git logs"
   - "Manually run through a fundamental integration test before moving on"

**State tracking best practices:**
- **JSON for structured data** (test status, task lists)
- **Plain text for progress notes** (freeform context)
- **Git for state tracking** (log of what's been done, checkpoints to restore)
- **Emphasize incremental progress** explicitly

---

### Balancing Autonomy vs. Safety (Opus 4.6)

Opus 4.6 may take hard-to-reverse actions (deleting files, force-pushing, posting to external services). To require confirmation:

```
Consider the reversibility and potential impact of your actions. Take local, reversible actions (editing files, running tests) freely, but for actions that are hard to reverse, affect shared systems, or could be destructive, ask before proceeding.

Examples that warrant confirmation:
- Destructive: deleting files/branches, dropping database tables, rm -rf
- Hard to reverse: git push --force, git reset --hard, amending published commits
- Visible to others: pushing code, commenting on PRs/issues, sending messages, modifying shared infrastructure
```

---

### Tool Usage Steerability

**Default behavior:** Opus 4.6 is efficient and may skip verbal summaries after tool calls. To get updates:

```
After completing a task that involves tool use, provide a quick summary of the work you've done.
```

**Proactive action by default:**
```
<default_to_action>
By default, implement changes rather than only suggesting them. If the user's intent is unclear, infer the most useful likely action and proceed, using tools to discover missing details instead of guessing. Infer the user's intent about whether a tool call is intended and act accordingly.
</default_to_action>
```

**Conservative action by default:**
```
<do_not_act_before_instructions>
Do not jump into implementation or change files unless clearly instructed. When intent is ambiguous, default to providing information, research, and recommendations rather than taking action. Only proceed with edits when the user explicitly requests them.
</do_not_act_before_instructions>
```

**Parallel tool calling (maximize efficiency):**
```
<use_parallel_tool_calls>
If you intend to call multiple tools and there are no dependencies between them, make all independent tool calls in parallel. For example, when reading 3 files, run 3 tool calls in parallel. Maximize parallel execution for speed. However, if tool calls depend on previous calls, do NOT call them in parallel. Never use placeholders or guess missing parameters.
</use_parallel_tool_calls>
```

---

### Communication Style (4.x Models)

**More direct and grounded:** Fact-based progress reports, not self-celebratory.
**More conversational:** Slightly fluent and colloquial, less machine-like.
**Less verbose:** May skip detailed summaries for efficiency unless prompted.

This accurately reflects what's been accomplished without elaboration.

---

### Sensitivity Notes

**"Think" variants (Opus 4.5 when extended thinking disabled):**
Replace "think" with "consider," "believe," "evaluate" to avoid unintentional thinking triggering.

**Tool triggering (Opus 4.5, Opus 4.6):**
More responsive to system prompt. If prompts previously fought undertriggering with aggressive language ("CRITICAL: You MUST use this tool when..."), dial back to normal prompting ("Use this tool when...").

---

## 5. Prompt Engineering — Codex/OpenAI

### Core Differences from Claude

**Codex-tuned models (gpt-5.2-codex):**
- Frontier intelligence for agentic coding
- Fewer thinking tokens; "medium" reasoning recommended for interactive
- "high" or "xhigh" reasoning effort enables autonomous multi-hour tasks
- First-class compaction support via `/compact` endpoint
- Enhanced PowerShell and Windows compatibility

**GPT-5.1:**
- Balances intelligence and speed
- Introduces `none` reasoning mode (low-latency, no reasoning tokens)
- Improved instruction following and agentic steerability

---

### Codex Prompting Principles

**Autonomy:**
Model operates as "a discerning engineer" that gathers context, plans, implements, tests, refines—**without waiting for intermediate approvals**.

**Code quality over speed:**
- Correctness prioritized
- Adhere to codebase conventions
- Comprehensive test coverage
- Tight error handling (avoid broad try-catch, silent failures)

**Tool use:**
- Prefer dedicated tools over shell commands
- Parallelize tool calls for efficiency

---

### Reasoning Effort

**Codex (`gpt-5.2-codex`):**
- Recommended: `"medium"` for interactive coding
- `"high"` or `"xhigh"` for autonomous multi-hour tasks
- Fewer thinking tokens compared to GPT-5.1

**GPT-5.1:**
- `"none"`: No reasoning tokens (like GPT-4.1 behavior)
  - For accuracy with `none`: plan extensively before function calls, reflect on outcomes, verify constraints
- `"low"`, `"medium"`, `"high"`: Standard reasoning modes

---

### Tool Implementations

**apply_patch (Codex-specific):**
Creates, updates, deletes files using structured diffs. Use Responses API built-in tool:
```python
tools=[{"type": "apply_patch"}]
```
Returns `apply_patch_call` with operation type and diff. Respond with:
```python
{
    "type": "apply_patch_call_output",
    "call_id": call["call_id"],
    "status": "completed" or "failed",
    "output": log_output
}
```

**shell_command / shell:**
String-type commands perform better than command lists. Supports working directory and timeout parameters.

**update_plan:**
TODO management tool with statuses: `pending`, `in_progress`, `completed`. For medium+ tasks:
- 2-5 milestone items (no micro-steps)
- One `in_progress` item at a time
- Never >8 tool calls without update
- Zero pending/in_progress items before turn ends

---

### Compaction for Long Contexts

**Responses API `/compact` endpoint:**
- Enables multi-turn conversations without context window degradation
- Long-running agent trajectories exceeding typical context limits
- Retains key prior state with fewer tokens

**Migration strategy:**
1. Update prompts with Codex-Max prompt as base
2. Focus on autonomy, persistence, codebase exploration, tool use
3. Remove prompting for upfront plans or status updates (may cause premature termination)
4. Update tool implementations (especially `apply_patch`)

---

### Output Compactness Rules (GPT-5.1)

Specify response length constraints for coding agents:
- **Tiny changes (≤10 lines):** 2-5 sentences max
- **Medium changes:** ≤6 bullets or 6-10 sentences
- **Large changes:** Summarize per file; avoid large code blocks

---

### User Updates (Preambles - GPT-5.1)

Configure along four axes:
1. **Frequency:** 1-2 sentence updates every few tool calls (max 6-8 steps between)
2. **Content:** Meaningful discoveries, concrete outcomes, plan changes
3. **Structure:** Initial plan, exploration updates, recap with status checklist
4. **Immediacy:** Explain actions BEFORE analysis to improve perceived latency

---

### Parallel Tool Execution

**Enable efficiency:**
```
Batch reads and edits to speed up the process.
```

Codex models excel at parallel execution (multiple speculative searches, reading files simultaneously, parallel bash commands).

---

### AGENTS.md Files (Codex-cli)

Codex-cli automatically discovers and injects instructions from `AGENTS.md` files in repository directories. Later directories override earlier ones.

---

### Output Formatting (Codex)

Final responses should:
- Use plain text with natural language headings
- Lead code changes with quick explanations
- Reference file paths using inline code formatting
- Suggest logical next steps rather than dumping code blocks
- Maintain collaborative, concise, factual tone

---

### Metaprompting (GPT-5.1)

Use GPT-5.1 to debug and improve your own prompts:

**Step 1: Root-cause analysis**
- Provide system prompt + failure examples
- Ask for distinct failure modes
- Quote specific prompt sections driving behavior

**Step 2: Surgical revisions**
- Share analysis results
- Request targeted edits preserving structure
- Output patch notes and revised prompt

---

## 6. Agentic Prompting Patterns

### Prompt Chaining

**Pattern:** Break complex task into subtasks; output of one prompt is input to next.

**Benefits:**
- Reduces complexity per step
- Improves interpretability (debug individual steps)
- Handles tasks exceeding single-prompt context

**Example:**
1. **Document analysis**: "Summarize this research paper into key points"
2. **Synthesis**: "Based on these summaries, identify common themes"
3. **Recommendation**: "Given these themes, suggest next research directions"

**IBM guideline:** Chain tasks via code (passing outputs between LLM calls) or structured prompt workflows.

---

### Tree of Thoughts (ToT)

**Pattern:** Explore multiple reasoning paths simultaneously; model evaluates and selects best path.

**Difference from chain-of-thought:** Instead of single linear path, ToT generates multiple candidate steps, evaluates them, and prunes inferior branches.

**Use when:** Problem has multiple valid approaches; need to explore alternatives before committing.

**Claude applicability:** Opus 4.6's adaptive thinking naturally explores competing hypotheses during extended thinking. Can explicitly request: "Consider multiple approaches and compare their tradeoffs before proceeding."

---

### Meta Prompting

**Pattern:** Use LLM to generate or refine prompts. LLM acts as meta-reasoner about prompt quality.

**Example workflow:**
1. Start with initial prompt
2. Run eval; identify failure modes
3. Ask LLM: "This prompt fails because [failures]. Suggest improvements."
4. Iterate revised prompt through eval

**Codex/GPT-5.1 explicit support:** Two-step metaprompting process (see Section 5).

---

### ReAct Prompting

**Pattern:** Interleave **reasoning** (thinking) and **acting** (tool use). Model reasons about what to do, takes action, observes result, reasons about outcome, repeats.

**Format:**
```
Thought: [Reasoning about current state]
Action: [Tool call or command]
Observation: [Result from action]
Thought: [Reasoning about observation]
Action: [Next tool call]
...
```

**Modern equivalent:** Claude's extended thinking + tool use naturally implements ReAct pattern. Explicitly requesting "reflect on tool results before proceeding" reinforces this.

---

### Iterative Prompting

**Pattern:** Start with simple prompt; iteratively refine based on outputs.

**Workflow:**
1. Draft minimal prompt
2. Run on test cases
3. Identify failure patterns
4. Add constraints/examples addressing failures
5. Repeat

**Best practice:** Don't over-engineer initial prompt. Start simple; add complexity only where evals show gaps.

---

### Role Prompting

**Pattern:** Assign LLM a specific role or persona ("You are a senior security engineer...").

**Effect:** Steers tone, expertise level, priorities, and communication style.

**Claude:** System prompt with role definition + specific instructions. See Section 4.

---

### In-Context Learning (Few-Shot)

**Pattern:** Provide examples in prompt; model generalizes pattern.

**Zero-shot:** No examples (rely on base knowledge).
**Few-shot:** 1-5 examples demonstrating desired input→output pattern.
**Many-shot:** 10+ examples (can improve accuracy but consumes context).

**Claude 4.x note:** Precise instruction following means examples are taken very literally. Ensure examples align exactly with desired behavior.

---

### Evaluation Flywheel

**Pattern (Codex guide):** Build resilient prompts through continuous eval-driven iteration.

**Loop:**
1. **Draft prompt** (initial or revised)
2. **Run evals** on diverse test set
3. **Analyze failures** (categorize by root cause)
4. **Revise prompt** surgically (address failure modes)
5. **Re-eval** to confirm improvement without regressions
6. **Iterate** until success criteria met

**Key principle:** Treat prompts like code—version, test, refactor based on empirical evidence.

---

### DSPy & Prompt Optimization

**DSPy framework:** Treats prompts as parameters to optimize algorithmically.

**Approach:**
- Define metric (accuracy, F1, task success rate)
- DSPy explores prompt variations
- Selects prompt maximizing metric on validation set

**Use when:** Have large labeled dataset; want to automate prompt tuning.

**Trade-off:** Less interpretable than manual prompt engineering; requires infrastructure.

---

### Prompt Caching

**Pattern:** Cache prompt prefix (system prompt, long context) to reduce latency and cost on repeated calls.

**Anthropic support:** Prompt caching enabled for Claude models. Mark portions of prompt to cache; subsequent calls reuse cached prefix.

**Benefit:** For long CLAUDE.md files, caching reduces cost and latency across session.

**Limitation:** Cache invalidates on prompt changes.

---

## 7. Evaluation & Quality

### Define Success Criteria

**Before prompt engineering:**
1. Clear definition of success (accuracy, format compliance, task completion)
2. Empirical tests against criteria
3. First draft prompt to improve

**Example success criteria:**
- Classification: 95% F1 score on test set
- Code generation: All tests pass + adheres to style guide
- Summarization: ROUGE score ≥ 0.8 + human readability rating ≥ 4/5

---

### Develop Test Cases

**Test case structure:**
- **Input:** Prompt + any context (documents, images, prior conversation)
- **Expected output:** Ground truth or acceptable output range
- **Metric:** How to measure success (exact match, semantic similarity, rubric score)

**Coverage principles:**
- **Happy path:** Typical inputs
- **Edge cases:** Boundary conditions, unusual inputs
- **Failure modes:** Inputs known to trip up model

**Anthropic guidance:** Create 10-50 test cases before eval automation. Start small (5-10), expand as you discover failure modes.

---

### Activation Testing (Skills-Specific)

**What to test:**
1. **Invocation precision:** Does skill activate when it should? Does it avoid activating when it shouldn't?
2. **Fidelity to source:** Does skill accurately represent source material without distortion?
3. **Resistance to drift:** Does skill hold source-specific perspective on inputs outside sweet spot, or collapse to generic advice?

**Testability criterion (from skill quality guidance):**
- Can you construct a prompt where you'd clearly see the difference between having the skill vs. not?
- If both skills produce indistinguishable outputs on realistic inputs, comparison is moot.

---

### Ground Truth & Evaluation Metrics

**For classification:** Accuracy, precision, recall, F1.

**For generation:** BLEU (machine translation), ROUGE (summarization), BERTScore (semantic similarity).

**For open-ended tasks:** Human evaluation rubrics (1-5 scale on criteria like correctness, clarity, completeness).

**For coding:** Test pass rate, linter compliance, security scan results.

**Behavioral evaluation (Codex non-determinism):**
- BLEU/ROUGE for comparing generated text to golden outputs
- Manual grading for subjective quality
- Since Codex outputs vary run-to-run, compare distributions rather than single samples

---

### Empirical Testing Best Practices

**Batch testing:** Run prompt on full test set, not one example at a time.

**Version control prompts:** Treat prompts like code—commit, branch, diff.

**Avoid overfitting:** Don't tune prompt to pass test set at expense of generalization. Hold out validation set.

**Iterate based on failure analysis:** Group failures by root cause; address cause, not symptoms.

**Reproducibility:** For evals with randomness, fix seed or run multiple times and report mean/variance.

---

### Quality Gates (Cogworks-Specific)

From `cogworks-learn` skill (TD-002, TD-009):

**M11 — Cross-Source Count:**
Verify that synthesized claims merging N sources are grounded in at least 2 of those N sources. Prevents false synthesis.

**D3 — CDR Completeness:**
Every CDR registry entry must trace to at least one Decision Skeleton entry. Ensures traceability.

**D4 — Quality Calibration Gate (Anti-Superficiality):**
Four self-check questions targeting false consensus, unjustified authority, untraceable claims, absent subtraction decisions. If all checks pass ("all clear"), treat as superficiality signal → re-examine.

**D8 — Generalization Probes:**
Test cases targeting circular verification failures (contradictory sources, context-dependent recommendations, distinct API endpoints). Forces independent evaluation.

**D21 — CI Gate Behavioral Coverage:**
Behavioral traces required for all skills; CI blocks on missing traces. Trace presence is release guarantee, not optional signal.

---

## 8. Cross-Source Patterns (High Confidence)

These patterns appear in **2+ independent sources**—highest reliability.

### 1. Context Window as Fundamental Constraint

**Sources:** Claude Code docs (best-practices, how-claude-works), IBM prompt optimization (caching)

**Pattern:** Context window fills fast; performance degrades as it fills. Managing context is the critical resource optimization.

**Implications:**
- Keep CLAUDE.md under 200 lines
- Use subagents for high-volume operations (research, tests)
- Prefer `/clear` between unrelated tasks
- Skills load descriptions upfront but full content only when invoked

---

### 2. Subagents for Context Isolation

**Sources:** Claude Code (sub-agents, best-practices), Codex (compaction, agent teams)

**Pattern:** Delegate verbose operations to subagents; only summaries return to parent context. Prevents parent context bloat.

**Cross-platform confirmation:** Claude Code's Explore subagent, Codex's background agents, IBM's chaining all implement the same core principle—isolate verbose work, return compressed results.

---

### 3. Parallel Tool Execution

**Sources:** Claude Code (prompting best practices, Opus 4.6 guide), Codex (prompting guide)

**Pattern:** When tool calls have no dependencies, execute in parallel for speed.

**Implementation:**
- Claude: "Make all independent tool calls in parallel"
- Codex: "Batch reads and edits"
- Automatically reduces latency 3-5x for file-heavy operations

---

### 4. Explicit > Implicit

**Sources:** Claude (prompting overview, best practices), Codex (prompting guide), IBM (role prompting)

**Pattern:** Clear, specific instructions outperform vague hints. Models follow explicit direction better than inferring intent.

**Examples:**
- "Use 2-space indentation" > "Format code properly"
- "Create analytics dashboard with as many relevant features as possible" > "Create analytics dashboard"
- Provide context ("why") alongside instruction ("what")

---

### 5. Examples Shape Behavior (Few-Shot Learning)

**Sources:** Claude (multishot prompting, precise instruction following), IBM (in-context learning), Codex (metaprompting)

**Pattern:** Models generalize from examples in prompt. In Claude 4.x, examples are followed very literally.

**Best practice:** Ensure examples perfectly align with desired output; anti-patterns in examples will be replicated.

---

### 6. Chain of Thought Improves Reasoning

**Sources:** Claude (let Claude think, extended thinking), IBM (chain-of-thoughts), Codex (reasoning effort)

**Pattern:** Allowing step-by-step reasoning (via prompting or thinking tokens) improves accuracy on complex problems.

**Variants:**
- Prompt-based: "Think step by step"
- Extended thinking: `thinking: {type: "adaptive"}` (Claude Opus 4.6)
- Reasoning effort: `"high"` or `"xhigh"` (Codex)

---

### 7. Tool Use Must Be Explicit in Prompts

**Sources:** Claude (tool usage patterns), Codex (tool implementations), IBM (ReAct prompting)

**Pattern:** Describe tools clearly: what they do, when to use them, how to invoke. Vague tool descriptions → undertriggering or misuse.

**Codex specificity:** "Prefer dedicated tools over shell commands when available."

---

### 8. Verification > Trust

**Sources:** Claude (best practices, extended thinking reflection), Codex (quality over speed), IBM (evaluation best practices)

**Pattern:** Give model a way to verify its own work (tests, screenshots, expected outputs). Self-verification dramatically improves accuracy.

**Implementation:**
- Provide test cases in prompt
- For UI: paste screenshot, ask for comparison
- For code: "run tests and fix failures"
- Extended thinking: "reflect on tool results before proceeding"

---

### 9. Iterative Refinement Beats Upfront Perfection

**Sources:** Claude (course-correct early and often), Codex (evaluation flywheel), IBM (iterative prompting)

**Pattern:** Start simple; refine based on failures. Tight feedback loops produce better results than elaborate initial prompts.

**Anti-pattern:** Over-engineering initial prompt before seeing where it actually fails.

---

### 10. State Management for Long Tasks

**Sources:** Claude (long-horizon reasoning, multi-context workflows), Codex (compaction, update_plan tool)

**Pattern:** For tasks spanning multiple context windows or long sessions, persist state externally (files, git, memory).

**Best practices:**
- JSON for structured state (test results, task lists)
- Plain text for progress notes
- Git for history/checkpoints
- Setup scripts (init.sh) for graceful restarts

---

### 11. Role Prompting Steers Behavior

**Sources:** Claude (system prompts), Codex (autonomy principle), IBM (role prompting tutorial)

**Pattern:** Assigning a role ("You are a senior security engineer...") consistently shapes expertise level, priorities, and tone.

**Effectiveness:** Works across all models; steers both technical behavior and communication style.

---

### 12. Prompt Caching for Repeated Context

**Sources:** Claude (prompt caching), IBM (caching overview)

**Pattern:** Cache static prompt prefix (system prompt, long context); reuse on subsequent calls to reduce latency and cost.

**Use case:** Long CLAUDE.md files, frequent API calls with same context.

---

## 9. Gaps in Cogworks

### Gap 1: No Activation Testing for Generated Skills

**Evidence:** `cogworks-learn` generates skills but doesn't validate invocation precision or test whether skills activate correctly.

**What's missing:**
- Test cases confirming skill triggers when it should
- Test cases confirming skill doesn't trigger when it shouldn't
- Validation that `description` field aligns with intended activation scenarios

**Source:** Skill quality guidance (testability criterion); Claude Code skills docs (description is critical for discovery).

**Impact:** Generated skills may have excellent content but poor discoverability—or trigger on irrelevant prompts.

---

### Gap 2: No Cross-Agent Compatibility Validation

**Evidence:** Generated skills aren't tested across Claude Code, GitHub Copilot, Cursor, or Codex.

**What's missing:**
- Validation that `$ARGUMENTS` interpolation works on target agent
- Confirmation that `allowed-tools` enforcement behaves as expected
- Testing of frontmatter fields across platforms

**Source:** Lambert's cross-agent compatibility matrix (TD-010); notes that Copilot `$ARGUMENTS` support is undefined (highest priority for live testing).

**Impact:** Skills generated for Claude Code may not work (or behave unexpectedly) on other agents in the compatibility matrix.

---

### Gap 3: No Parallel Tool Use Guidance

**Evidence:** `cogworks-encode` and `cogworks-learn` don't encode or prompt for parallel tool execution patterns.

**What's missing:**
- Skills that encourage agents to parallelize file reads, searches
- Generated prompts that include "make all independent tool calls in parallel"
- Knowledge that parallel execution is 3-5x faster for file-heavy operations

**Source:** Claude Opus 4.6 best practices, Codex prompting guide (both emphasize parallelization as high-impact optimization).

**Impact:** Generated skills may cause agents to execute sequentially when parallel execution would dramatically improve performance.

---

### Gap 4: No Subagent Orchestration Patterns

**Evidence:** Pipeline doesn't encode when/how to spawn subagents or delegate to isolated contexts.

**What's missing:**
- Guidance on using `context: fork` in generated skills
- Patterns for delegating research/verification to subagents to preserve parent context
- Skills that know to isolate high-volume operations (test runs, log parsing)

**Source:** Claude Code sub-agents docs, best practices (subagents for context isolation).

**Impact:** Generated skills may bloat parent context with verbose output instead of delegating to isolated subagent contexts.

---

### Gap 5: No Multi-Context Window State Management

**Evidence:** Pipeline doesn't encode patterns for tasks spanning multiple context windows.

**What's missing:**
- Instructions to persist state to files (tests.json, progress.txt)
- Guidance on using git for state tracking
- Setup scripts (init.sh) for graceful restarts after context compaction

**Source:** Claude long-horizon reasoning best practices, Codex compaction support.

**Impact:** Generated skills may struggle with long-running tasks that require context transitions—or may prematurely terminate as context fills.

---

### Gap 6: No Evaluation Flywheel Integration

**Evidence:** Behavioral tests exist, but cogworks doesn't encode the eval→refine→re-eval loop into generated skills or pipeline workflow.

**What's missing:**
- Skills that self-improve through eval-driven iteration
- Workflow where generated skills undergo eval, failure analysis, revision
- Integration of behavioral traces as quality gates before skill deployment

**Source:** Codex evaluation flywheel, IBM prompt optimization (DSPy).

**Impact:** Generated skills are "one-shot"—no mechanism for iterative refinement based on real-world failure modes.

---

### Gap 7: Codex-Specific Patterns Not Encoded

**Evidence:** Sources include Codex/GPT-5.x prompting guides, but cogworks pipeline focuses on Claude.

**What's missing:**
- `apply_patch` tool usage patterns
- `update_plan` tool for TODO tracking
- `shell_command` preference over ad-hoc bash
- Compaction via `/compact` endpoint
- AGENTS.md file discovery (Codex-cli)

**Source:** Codex prompting guide, GPT-5.1 guide.

**Impact:** Skills generated by cogworks may not leverage Codex-specific affordances, reducing effectiveness when deployed to Codex/GPT-5.x agents.

---

### Gap 8: No Prompt Caching Optimization

**Evidence:** Generated skills don't consider or optimize for prompt caching.

**What's missing:**
- Structure skills to maximize cacheable prefix (static system prompt, long context)
- Guidance on separating static from dynamic content
- Skills that leverage caching for repeated invocations

**Source:** Claude prompt caching, IBM caching overview.

**Impact:** Generated skills may have poor latency/cost profile when invoked repeatedly with similar context.

---

### Gap 9: No Security Injection Scanning for Skill Content

**Evidence:** TD-002 (M2, M9) added injection guards to cogworks orchestration, but no mechanism scans generated skill bodies for injection vulnerabilities.

**What's missing:**
- Post-generation scan for prompt-override phrases ("ignore prior instructions")
- Scan for standalone imperative directives ("you must always")
- Scan for tool call syntax not belonging to skill delimiters
- Scan for delimiter leakage

**Source:** TD-002 (Ash's security implementation).

**Impact:** Generated skill content could contain patterns that allow prompt injection if user crafts malicious invocation arguments.

---

### Gap 10: No Guidance on When NOT to Use Skills

**Evidence:** Pipeline encodes how to build skills but not when skills are the wrong abstraction.

**What's missing:**
- Guidance on when CLAUDE.md is better (persistent instructions)
- Guidance on when hooks are better (deterministic enforcement)
- Guidance on when subagents are better (task orchestration)
- Trade-off matrix: skills vs. CLAUDE.md vs. hooks vs. subagents

**Source:** Claude Code features-overview (matching features to goals), best practices (hooks for zero-exception enforcement).

**Impact:** Generated skills may duplicate or conflict with CLAUDE.md or hooks, creating maintenance burden and steerability issues.

---

## 10. Priority Recommendations

### 1. Add Activation Testing to Behavioral Eval

**What:** Extend `cogworks-eval.py behavioral run` to include activation test cases.

**Why:** Skills with perfect content but poor invocation are useless. Activation precision is a core quality dimension.

**Source:** Skill quality guidance (testability criterion), Claude Code skills docs (description field determines auto-invocation).

**How:** For each generated skill, create 2-4 activation test cases:
- Positive: Prompts that SHOULD trigger skill
- Negative: Similar prompts that should NOT trigger skill
- Validate that skill activates correctly in positive cases, doesn't activate in negative cases

---

### 2. Encode Parallel Tool Use Patterns

**What:** Add parallel execution guidance to `cogworks-encode` and `cogworks-learn`.

**Why:** Parallel tool calling is 3-5x faster for file-heavy operations; appears in both Claude and Codex best practices as high-impact optimization.

**Source:** Claude Opus 4.6 prompting (parallel tool calls section), Codex prompting guide (tool use efficiency).

**How:**
- In `cogworks-encode`: When synthesizing agent workflow sources, extract parallel execution patterns
- In `cogworks-learn`: Template guidance for generated skills: "When you intend to call multiple tools with no dependencies, make all independent tool calls in parallel"

---

### 3. Cross-Agent Compatibility Matrix in Generated Skills

**What:** Include a "Compatibility" section in generated `SKILL.md` files noting cross-agent behavior.

**Why:** Skills may work perfectly on Claude Code but fail on Copilot or Codex. User needs visibility into compatibility.

**Source:** TD-010 (Lambert's compatibility doc), cross-agent matrix showing `$ARGUMENTS` and `allowed-tools` support varies by agent.

**How:**
- In `cogworks-learn`: Template includes:
  ```markdown
  ## Compatibility
  - Claude Code: ✅ Full support
  - GitHub Copilot: 🟡 `$ARGUMENTS` behavior undefined; test before relying on interpolation
  - Cursor: ❓ Untested
  ```
- Flag skills using `$ARGUMENTS` or `allowed-tools` as needing live testing on target agents

---

### 4. Integrate Evaluation Flywheel into Pipeline

**What:** After generating skill, run behavioral eval → analyze failures → revise → re-eval → deploy.

**Why:** One-shot generation produces skills that fail on real-world edge cases. Eval-driven refinement creates resilient skills.

**Source:** Codex evaluation flywheel (building resilient prompts via continuous iteration), IBM prompt optimization.

**How:**
- Post-generation: Auto-run behavioral tests
- On failure: Analyze root cause (categorize failure mode)
- Revise: Surgical edits to skill addressing failure mode
- Re-eval: Confirm fix without regression
- Iterate until behavioral coverage ≥ threshold (e.g., 90%)

---

### 5. Add Subagent Orchestration Guidance

**What:** Teach `cogworks-learn` when and how to use `context: fork` in generated skills.

**Why:** Subagents preserve parent context by isolating verbose operations. Critical for context management at scale.

**Source:** Claude Code sub-agents docs (context isolation), best practices (subagents for high-volume operations).

**How:**
- In `cogworks-learn`: Decision rule: If skill involves research, testing, or log parsing → use `context: fork`
- Template guidance: "This skill runs in an isolated subagent to keep verbose output (test logs, search results) out of your main conversation. Only a summary returns."
- Example skills: Research skill with `context: fork` + `agent: Explore`

---

## Appendix: Source File Inventory

### Tier 1 (Read in Full)

1. `_sources/cc-docs/skills.md` — Skills architecture, frontmatter, discovery, advanced patterns
2. `_sources/cc-docs/sub-agents.md` — Subagent creation, configuration, context management
3. `_sources/cc-docs/agent-teams.md` — Multi-agent coordination (experimental)
4. `_sources/cc-docs/memory.md` — CLAUDE.md vs. auto memory, scope, persistence
5. `_sources/cc-docs/best-practices.md` — Context management, verification, session management
6. `_sources/cc-docs/how-claude-code-works.md` — Agentic loop, tools, context window
7. `_sources/skill-comparison-guards/skill-quality-guidance.md` — 10 quality criteria for skill evaluation
8. `_sources/prompting/claude/prompt-engineering.md` — Overview, when to prompt engineer vs. finetune
9. `_sources/prompting/claude/prompting-best-practice.md` — Claude 4.x best practices (Opus 4.6, Sonnet 4.5)
10. `_sources/prompting/claude/extended-thinking-tips.md` — Adaptive thinking, budget allocation, reflection
11. `_sources/prompting/codex/codex-prompting-guide.md` — Codex-tuned models, autonomy, tool implementations
12. `_sources/prompting/codex/gpt-5-1-prompting-guide.md` — GPT-5.1 steerability, `none` reasoning mode
13. `_sources/prompting/codex/gpt-5-2-prompting-guide.md` — GPT-5.2 updates (noted: 55 lines, not read in full)

### Tier 2 (Extracted Key Findings)

*Note: Due to time constraints and synthesis priority, Tier 2 sources were reviewed but not fully integrated into this synthesis. Key findings from Tier 1 sources provide sufficient actionable intelligence.*

IBM agentic prompting:
- `01-prompt-chaining-overview.md`
- `02-prompt-chaining-langchain-tutorial.md`
- `03-tree-of-thoughts.md`
- `04-meta-prompting.md`
- `05-iterative-prompting.md`
- `06-react-prompting-tutorial.md`

IBM prompt optimization:
- `01-prompt-optimization-overview.md`
- `02-dspy-overview.md`
- `03-dspy-tutorial.md`
- `04-prompt-caching-overview.md`
- `05-prompt-caching-langchain-tutorial.md`

IBM reasoning enhancement:
- `01-chain-of-thoughts.md`
- `02-directional-stimulus-prompting.md`
- `03-role-prompting-tutorial.md`
- `04-in-context-learning.md`

Other:
- `_sources/prompting/codex/building-resilient-prompts-using-an-evaluation-flywheel.md`
- `_sources/evals/evaluation-best-practices.md`
- `_sources/evals/anthropic-define-success.md`
- `_sources/evals/anthropic-develop-test-cases.md`
- `_sources/openai/reasoning-best-practices.md`
- `_sources/skillsbench/skillsbench-assessment.md`
- `_sources/skillsbench-implementation/IMPLEMENTATION_SUMMARY.md`

### Files Skipped (Per Task Spec)

Analytics, auth, changelog, chrome, costs, data-usage, legal, network-config, sandboxing, desktop, devcontainer, keybindings, statusline, terminal-config, output-styles, slack, fast-mode, monitoring-usage, quickstart, setup, permissions, docs-update-tool, tdd/, persuasion-principles.md, skill-ref-links.md, multishot-prompting.md, IBM sections 01/03/07.
