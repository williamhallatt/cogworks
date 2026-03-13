# Skill Writer - Minimal Examples

Source IDs map to `reference.md#sources`.

These examples exist only to demonstrate the contract. They are intentionally
minimal and do not try to cover every configuration variant.

## Example 1: Compact Reference Skill

```yaml
---
name: api-conventions
description: Use when writing or reviewing API endpoints in this codebase, including route naming, error handling, and request validation.
license: MIT
metadata:
  author: team
  version: "1.0.0"
---
```

Body shape:
- Overview
- When to Use
- Quick Decision Cheatsheet
- Invocation
- Supporting Docs

Why this example exists: it shows the smallest useful auto-loadable reference
skill.

## Example 2: Runtime-Specific Skill

```yaml
---
name: fix-issue
description: Use when fixing a GitHub issue by issue number on Claude Code.
license: MIT
compatibility: Requires Claude Code for argument interpolation
disable-model-invocation: true
metadata:
  author: team
  version: "1.0.0"
---
```

Body requirement:
- include a Compatibility section between Invocation and Supporting Docs
- state that `disable-model-invocation: true` is Claude Code-specific

Why this example exists: it shows how compatibility must be declared when
runtime-specific features are present.

## Example 3: Fail-Closed Task Skill

Invocation excerpt:

```markdown
1. Run the documented verification command.
2. Stop immediately if the command fails.
3. Report the blocking failure instead of continuing with a best-effort result.
```

Why this example exists: it shows the expected wording shape for
high-fragility workflows without adding unnecessary authority language.
