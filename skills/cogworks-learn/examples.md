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
- [Example 13](#example-13-complete-generated-skill-reference) - Complete Generated Skill (Reference)

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

## Example 13: Complete Generated Skill (Reference)

A minimal well-formed generated skill produced by the cogworks pipeline. Use as a structural anchor — any model can pattern-match against this regardless of provider.

**Directory structure:**
```
git-commit-conventions/
  SKILL.md
  reference.md
  metadata.json
```

**SKILL.md:**
```yaml
---
# name: lowercase + hyphens only, matches directory name
name: git-commit-conventions
# description: action verb, third-person, trigger-rich, ≤ 1024 chars
description: Enforces git commit message conventions including Conventional Commits format, scope rules, and body structure. Use when writing commit messages, reviewing commit history, setting up commit hooks, or configuring CI lint rules for commit format.
license: MIT
metadata:
  author: cogworks
  version: '1.0.0'
---

# Git Commit Conventions

> **Knowledge snapshot from:** 2025-06-15

<!-- Overview: concise mission statement for the agent -->
Provides authoritative guidance on structuring git commit messages for consistency, tooling compatibility, and changelog automation.

## When to Use This Skill

- Writing or reviewing commit messages
- Configuring commitlint or commit-msg hooks
- Setting up changelog generation from commit history
- Choosing between commit message conventions for a new project

**Not for:** branch naming, PR descriptions, release tagging

## Quick Decision Cheatsheet

| Situation | Do this |
|-----------|---------|
| Single logical change | One commit, type + scope + summary |
| Breaking change | `feat!:` prefix or `BREAKING CHANGE:` footer |
| Multiple unrelated changes | Separate commits, one type each |
| Fixing a typo in docs | `docs(readme): fix typo` |

## Supporting Docs

- [reference.md](reference.md) — Decision rules, anti-patterns, quality gates, full source citations

## Invocation

This skill auto-loads when the agent detects commit-related context. No manual invocation required.
```

**reference.md:**
```markdown
# Git Commit Conventions — Reference

## TL;DR

Use Conventional Commits format (`type(scope): summary`). Keep the subject line ≤ 72 chars. One logical change per commit. Breaking changes use `!` suffix or `BREAKING CHANGE:` footer.

## Decision Rules

1. **Subject line format** — use `type(scope): summary` where type is one of: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert. [Source 1]
2. **Subject length** — keep ≤ 72 characters; hard limit at 100. Shorter subjects are read in more tooling contexts (GitHub, git log --oneline). [Source 1]
3. **Scope is optional but consistent** — if used, scope must match a project-defined list (e.g. module names). Do not invent ad-hoc scopes. [Source 2]
4. **Body wraps at 72 characters** — explain *why*, not *what*. The diff shows what changed; the body explains the reasoning. [Source 1]
5. **Breaking changes require explicit marking** — use `feat!:` or `fix!:` for subject-line marking, or add a `BREAKING CHANGE:` footer. Both are valid; pick one convention per project. [Source 1]
6. **One logical change per commit** — atomic commits enable bisect, revert, and cherry-pick. If you need "and" in the summary, split the commit. [Source 2]

## Quality Gates

- Subject matches `type(scope)?: .+` regex
- No subject line exceeds 100 characters
- Body paragraphs wrap at 72 characters
- Breaking changes have `!` or `BREAKING CHANGE:` marker

## Anti-Patterns

1. **Kitchen-sink commits** — "fix stuff and add feature and update docs" defeats bisect and revert. Split into atomic commits. [Source 2]
2. **Meaningless scopes** — `fix(misc): update` adds noise. Omit scope rather than use a vague one. [Source 1]
3. **Imperative tense violations** — "Fixed bug" or "Fixes bug" instead of "fix bug". The subject completes the sentence "This commit will ___". [Source 1]
4. **Body restating the diff** — "Changed line 42 from X to Y" adds nothing. Explain *why* the change was necessary. [Source 2]

## Quick Reference

```
type(scope): summary       ← subject line (≤ 72 chars)
                            ← blank line
Body paragraph explaining   ← body (wrap at 72)
why this change was needed.

BREAKING CHANGE: old API    ← footer (optional)
removed in favour of new.

Refs: #123                  ← issue reference (optional)
```

**Types:** feat | fix | docs | style | refactor | perf | test | build | ci | chore | revert

## Source Scope

- **Primary platform (normative):** Conventional Commits specification
- **Supporting foundations (normative when applicable):** Git project guidelines
- **Cross-platform contrast (non-normative):** Angular commit conventions (contrast only)

## Sources

> **Knowledge snapshot date:** 2025-06-15 — rules reflect spec versions current at this date.

1. Conventional Commits v1.0.0 — https://www.conventionalcommits.org/en/v1.0.0/
2. Git Project Commit Guidelines — https://git-scm.com/book/en/v2/Distributed-Git-Contributing-to-a-Project
3. Angular Commit Message Format — https://github.com/angular/angular/blob/main/CONTRIBUTING.md#commit (contrast only)
```

**metadata.json:**
```json
{
  "slug": "git-commit-conventions",
  "version": "1.0.0",
  "snapshot_date": "2025-06-15",
  "cogworks_version": "1.0.0",
  "topic": "git commit conventions",
  "author": "cogworks",
  "license": "MIT",
  "sources": [
    { "type": "url", "uri": "https://www.conventionalcommits.org/en/v1.0.0/" },
    { "type": "url", "uri": "https://git-scm.com/book/en/v2/Distributed-Git-Contributing-to-a-Project" },
    { "type": "url", "uri": "https://github.com/angular/angular/blob/main/CONTRIBUTING.md#commit" }
  ]
}
```

**Why this example works:**
- SKILL.md stays concise (~40 lines) with depth delegated to reference.md
- Description uses action verb ("Enforces"), lists concrete triggers, avoids workflow step language
- Every Decision Rule and Anti-Pattern carries a `[Source N]` citation (6 + 4 = 10 total, well above the 3 minimum)
- Each fact lives in one canonical location — no duplication between SKILL.md and reference.md
- metadata.json slug matches directory name, sources array is non-empty, snapshot_date is ISO 8601
- Passes both `validate-skill.sh` and the full `deterministic-checks.sh`
