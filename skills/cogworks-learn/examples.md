# Skill Writer - Practical Examples

Complete skill examples demonstrating various patterns and configurations.

---

## Table of Contents

- [Example 1](#example-1-api-conventions-reference-skill) - API Conventions (Reference Skill)
- [Example 2](#example-2-deploy-task-skill-with-side-effects) - Deploy (Task Skill with Side Effects)
- [Example 3](#example-3-code-explainer-auto-invokable) - Code Explainer (Auto-Invokable)
- [Example 4](#example-4-fix-github-issue) - Fix GitHub Issue
- [Example 5](#example-5-pr-summary-with-live-data) - PR Summary with Live Data
- [Example 6](#example-6-deep-research-forked-subagent) - Deep Research (Forked Subagent)
- [Example 7](#example-7-component-migration-multi-argument) - Component Migration (Multi-Argument)
- [Example 8](#example-8-session-logger) - Session Logger
- [Example 9](#example-9-safe-reader-tool-restriction) - Safe Reader (Tool Restriction)
- [Example 10](#example-10-legacy-system-context-background-knowledge) - Legacy System Context (Background Knowledge)
- [Example 11](#example-11-codebase-visualizer-visual-output) - Codebase Visualizer (Visual Output)
- [Example 12](#example-12-skill-with-overview--reference-split) - Skill with Overview + Reference Split

---

## Example 1: API Conventions (Reference Skill)
```yaml
---
name: api-conventions
description: API design patterns for this codebase. Use when writing endpoints, designing APIs, or reviewing API code.
---

When writing API endpoints:
- Use RESTful naming conventions
- Return consistent error formats
- Include request validation
```

## Example 2: Deploy (Task Skill with Side Effects)
```yaml
---
name: deploy
description: Deploy the application to production
context: fork
disable-model-invocation: true
---

Deploy the application:
1. Run the test suite
2. Build the application
3. Push to the deployment target
```

## Example 3: Code Explainer (Auto-Invokable)
```yaml
---
name: explain-code
description: Explains code with visual diagrams and analogies. Use when explaining how code works, teaching about a codebase, or when the user asks "how does this work?"
---

When explaining code, always include:
1. **Start with an analogy**: Compare to everyday life
2. **Draw a diagram**: ASCII art for flow/structure
3. **Walk through the code**: Step-by-step explanation
4. **Highlight a gotcha**: Common mistake or misconception
```

## Example 4: Fix GitHub Issue
```yaml
---
name: fix-issue
description: Fix a GitHub issue
disable-model-invocation: true
argument-hint: [issue-number]
---

Fix GitHub issue $ARGUMENTS following our coding standards.

1. Read the issue description
2. Understand the requirements
3. Implement the fix
4. Write tests
5. Create a commit
```

## Example 5: PR Summary with Live Data
```yaml
---
name: pr-summary
description: Summarize changes in a pull request
context: fork
agent: Explore
allowed-tools: Bash(gh *)
---

## Pull request context
- PR diff: !`gh pr diff`
- PR comments: !`gh pr view --comments`
- Changed files: !`gh pr diff --name-only`

## Your task
Summarize this pull request...
```

## Example 6: Deep Research (Forked Subagent)
```yaml
---
name: deep-research
description: Research a topic thoroughly
context: fork
agent: Explore
---

Research $ARGUMENTS thoroughly:

1. Find relevant files using Glob and Grep
2. Read and analyze the code
3. Summarize findings with specific file references
```

## Example 7: Component Migration (Multi-Argument)
```yaml
---
name: migrate-component
description: Migrate a component from one framework to another
argument-hint: [component] [from] [to]
---

Migrate the $0 component from $1 to $2.
Preserve all existing behavior and tests.
```

## Example 8: Session Logger
```yaml
---
name: session-logger
description: Log activity for this session
---

Log the following to logs/${CLAUDE_SESSION_ID}.log:

$ARGUMENTS
```

## Example 9: Safe Reader (Tool Restriction)
```yaml
---
name: safe-reader
description: Read files without making changes
allowed-tools: Read, Grep, Glob
---

Explore the codebase in read-only mode.
```

## Example 10: Legacy System Context (Background Knowledge)
```yaml
---
name: legacy-system-context
description: Context about the legacy billing system architecture
user-invocable: false
---

The legacy billing system uses...
[detailed architecture documentation]
```

## Example 11: Codebase Visualizer (Visual Output)
```yaml
---
name: codebase-visualizer
description: Generate an interactive collapsible tree visualization of your codebase. Use when exploring a new repo, understanding project structure, or identifying large files.
allowed-tools: Bash(python *)
---

# Codebase Visualizer

Run the visualization script from your project root:

```bash
python ~/.claude/skills/codebase-visualizer/scripts/visualize.py .
```

This creates `codebase-map.html` and opens it in your browser.
```

## Example 12: Skill with Overview + Reference Split
**SKILL.md:**
```yaml
---
name: api-design
description: API design expertise for RESTful services
---

# API Design Expert

Core principles for API design in this codebase.

## Quick Reference
- Use nouns for resources, verbs for actions
- Consistent error format across all endpoints
- Version in URL path (/v1/, /v2/)

## Full Documentation
See [reference.md](reference.md) for:
- Complete endpoint patterns
- Error code catalog
- Authentication flows
```

**reference.md:** [Full 500+ line API documentation]
