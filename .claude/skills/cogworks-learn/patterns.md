# Skill Writer - Patterns & Anti-Patterns

Reusable patterns and common pitfalls for writing Claude Code skills.

---

## Table of Contents

- [Patterns](#patterns) - 10 reusable patterns with when/why/how guidance
- [Anti-Patterns](#anti-patterns) - 8 documented pitfalls to avoid

---

## Patterns

### 1. Overview + Reference Split
**When:** Skill has substantial reference material
**Why:** Minimize auto-load token cost while preserving depth
**How:**
```
my-skill/
├── SKILL.md        # Overview (~100-200 lines)
└── reference.md    # Full details (loaded on-demand)
```
SKILL.md includes: "See [reference.md](reference.md) for complete details"

### 2. Explicit Steps for High-Stakes Workflows
**When:** Deployments, commits, destructive operations
**Why:** Fragile tasks need explicit verification gates
**How:**
```yaml
---
name: deploy
disable-model-invocation: true
---
Deploy to production:
1. Run test suite - STOP if failures
2. Build application
3. Push to deployment target
4. Verify deployment succeeded
5. Report status
```

### 3. Keyword-Rich Description
**When:** Always
**Why:** Claude uses description to decide auto-loading from 100+ skills
**How:**
```yaml
description: Explains code with visual diagrams and analogies. Use when explaining how code works, teaching about a codebase, or when the user asks "how does this work?"
```
Include: action verbs, trigger phrases, use cases

### 4. Background Knowledge Skill
**When:** Context Claude should know but isn't actionable as command
**Why:** `/legacy-system-context` isn't meaningful for users to type
**How:**
```yaml
---
name: legacy-system-context
user-invocable: false
---
```

### 5. Safe Exploration Mode
**When:** Read-only analysis without modification risk
**Why:** Prevents accidental changes during exploration
**How:**
```yaml
---
name: safe-reader
allowed-tools: Read, Grep, Glob
---
```

### 6. Isolated Research Task
**When:** Self-contained analysis not needing conversation context
**Why:** Clean execution without conversation history pollution
**How:**
```yaml
---
name: deep-research
context: fork
agent: Explore
---
Research $ARGUMENTS thoroughly:
1. Find relevant files
2. Read and analyze
3. Summarize findings
```

### 7. Live Data Integration
**When:** Skill needs current state (PR info, git status, etc.)
**Why:** Static instructions can't capture dynamic context
**How:**
```yaml
---
name: pr-summary
context: fork
---
## Current PR
- Diff: !`gh pr diff`
- Files changed: !`gh pr diff --name-only`

Summarize this pull request...
```

### 8. Multi-Argument Command
**When:** Skill needs multiple distinct inputs
**Why:** Structured input more reliable than parsing free text
**How:**
```yaml
---
name: migrate-component
argument-hint: [component] [from-framework] [to-framework]
---
Migrate the $0 component from $1 to $2.
```
Invoked: `/migrate-component SearchBar React Vue`

### 9. Visual Output Generation
**When:** Data exploration, reports, visualizations
**Why:** Browser-based output exceeds terminal capabilities
**How:** Bundle Python/Node script in `scripts/`, SKILL.md instructs Claude to run it, script generates and opens HTML

### 10. Monorepo Package Skills
**When:** Different packages need different conventions
**Why:** Automatic discovery from nested directories
**How:**
```
packages/
├── frontend/.claude/skills/    # Frontend-specific skills
├── backend/.claude/skills/     # Backend-specific skills
└── shared/.claude/skills/      # Shared utilities
```

---

## Anti-Patterns

### 1. Vague Description
**Problem:** "Helps with code" - Claude can't distinguish from other skills
**Why it fails:** No keywords to match user intent
**Alternative:** "Refactors Python functions to reduce cyclomatic complexity. Use when functions are too complex, have too many branches, or need simplification."

### 2. Monolithic SKILL.md
**Problem:** 2000-line SKILL.md with all documentation inline
**Why it fails:** Consumes context budget on every load, crowds out other skills
**Alternative:** Overview in SKILL.md, details in reference.md loaded on-demand

### 3. Auto-Invoke for Side Effects
**Problem:** Deploy skill without `disable-model-invocation`
**Why it fails:** Claude might deploy because code "looks ready"
**Alternative:** Always use `disable-model-invocation: true` for deployments, commits, external API calls

### 4. Guidelines in Forked Context
**Problem:** `context: fork` with "use these API conventions" (no task)
**Why it fails:** Subagent receives guidelines but no actionable prompt, returns nothing
**Alternative:** Only use `context: fork` for skills with explicit task instructions

### 5. Over-Specific Steps for Low-Stakes Tasks
**Problem:** 20-step checklist for writing a log message
**Why it fails:** Excessive rigidity for tasks that don't need it
**Alternative:** Principles-based guidance, let Claude adapt to context

### 6. Under-Specific Steps for High-Stakes Tasks
**Problem:** "Deploy the application" without verification gates
**Why it fails:** No checkpoints to catch failures before they cascade
**Alternative:** Explicit steps with STOP conditions and verification

### 7. Hiding User-Actionable Commands
**Problem:** `user-invocable: false` on a deploy skill
**Why it fails:** Users can't invoke when they need to
**Alternative:** Use `disable-model-invocation: true` instead to hide from Claude while keeping user access

### 8. Overly Broad Triggering
**Problem:** Description matches too many user requests
**Why it fails:** Skill activates when unwanted, pollutes responses
**Alternative:** Narrow description, add `disable-model-invocation: true` if needed
