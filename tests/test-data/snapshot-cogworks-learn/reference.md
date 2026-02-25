# Reference

## TL;DR

Skills are SKILL.md files that extend Claude's knowledge or add slash commands. Keep them focused, keyword-rich in `description`, and under 500 lines. Push depth into supporting files loaded on demand.

## Core Concepts

- Skills are discoverable via description keywords. [Source 1]
- Keep SKILL.md concise and push depth into supporting files. [Source 2]
- Use explicit invocation for side-effectful workflows. [Source 3]

## Pattern Notes

- Use progressive disclosure to reduce context pressure. [Source 4]

## Quick Reference

- `disable-model-invocation: true` for side-effectful tasks. [Source 5]

## Decision Rules

- **Reference skill**: Knowledge Claude applies continuously without being asked.
- **Task skill**: Step-by-step workflow invoked explicitly by the user.
- **Auto-invoke** (default): When the skill's knowledge is relevant and low-risk.
- **Manual-only** (`disable-model-invocation: true`): Side effects, deployments, anything user-controlled.
- **Forked context** (`context: fork`): When the task is fully isolated and needs no conversation history.

## Anti-Patterns

- Description lists implementation steps instead of trigger conditions.
- SKILL.md exceeds 500 lines instead of delegating depth to reference.md.
- High-stakes steps lack explicit verification gates.
- `name` contains uppercase letters or spaces.
- Skill duplicates Claude's built-in knowledge without adding domain-specific value.

## Sources

> **Knowledge snapshot date:** 2026-02-19

1. Claude Code Skills Documentation
2. Best Practices for Skill Authoring
