---
name: cogworks-learn
description: Expert knowledge on writing Claude Code skills - SKILL.md files, frontmatter configuration, invocation modes, context management, and best practices. Use when creating skills, designing slash commands, writing SKILL.md files, or optimizing skill discoverability and context efficiency.
---

# Skill Writer Expert

When invoked, you operate with specialized knowledge in **writing Claude Code skills**.

This expertise has been synthesized from 2 authoritative sources:

1. Official Claude Code Skills Documentation
2. Anthropic Best Practices for Skill Authoring

## Knowledge Base Summary

- **Skills are SKILL.md files** with YAML frontmatter (configuration) and markdown content (instructions), living in directory structures that support additional files
- **Two content types serve different purposes**: Reference skills add knowledge Claude applies continuously; Task skills provide step-by-step workflows for explicit invocation
- **Context window is a public good**: Keep SKILL.md under 500 lines, use progressive disclosure with supporting files loaded on-demand
- **Description is your discovery contract**: Claude uses this single field to decide when to auto-load from potentially 100+ skills - keyword precision determines triggering
- **Match specificity to task fragility**: High-stakes workflows need explicit steps, verification gates, and rationalization resistance; low-stakes guidelines can be principles-based

## Core Expertise Areas

1. **Skill Architecture** - Directory-based system with SKILL.md entrypoint and supporting files
2. **Frontmatter Configuration** - name, description, disable-model-invocation, allowed-tools, context, agent
3. **Invocation Duality** - Auto-loading (Claude decides) vs manual /slash-command (user decides)
4. **Scope Hierarchy** - Enterprise > Personal (~/.claude/skills/) > Project (.claude/skills/) > Plugin
5. **Reference vs Task Content** - Guidelines for continuous application vs workflows for explicit execution
6. **Progressive Disclosure** - SKILL.md as overview, reference.md for depth, loaded on-demand
7. **Dynamic Context Injection** - Real-time data via `!command` syntax
8. **Subagent Execution** - Isolated contexts with `context: fork` and agent types
9. **Argument Interpolation** - $ARGUMENTS, $ARGUMENTS[N], $N placeholders
10. **Tool Restriction** - allowed-tools for safety boundaries

## Quick Decision Framework

**Should Claude auto-invoke this skill?**

- Yes (default): Knowledge Claude should apply when relevant
- No (`disable-model-invocation: true`): Side effects, deployments, user-controlled timing

**Should users see this in the / menu?**

- Yes (default): Actionable commands users would invoke
- No (`user-invocable: false`): Background knowledge, not a meaningful action

**Where should it run?**

- Inline (default): Needs conversation context, applies knowledge to current work
- Forked (`context: fork`): Isolated task, no conversation history needed

## Full Knowledge Base

Core knowledge in [reference.md](reference.md):

- **Core Concepts** - 10 detailed definitions with source citations
- **Concept Map** - 15 explicit relationships between concepts
- **Deep Dives** - Context budget economy, description as discovery interface, specificity calibration
- **Quick Reference** - Frontmatter fields, string substitutions, scope locations

Patterns and examples in separate files (loaded on-demand):

- [patterns.md](patterns.md) - 10 reusable patterns + 9 anti-patterns to avoid
- [examples.md](examples.md) - 12 complete practical examples with citations

## Writing Checklist

Before finalizing any skill:

1. Is description keyword-rich for discovery?
2. Is SKILL.md under 500 lines with depth in supporting files?
3. Does invocation mode match the task's risk profile?
4. Are high-stakes steps explicit with verification gates?
5. Does scope match the intended audience?
