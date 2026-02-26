# Reference

## TL;DR

This reference.md has all required sections but no `> **Knowledge snapshot date:**` line in Sources.

## Quick Reference

- Check 15 verifies snapshot date in both SKILL.md and reference.md. [Source 1]
- This fixture has the date in SKILL.md but not in reference.md. [Source 2]

## Decision Rules

- If snapshot date is missing in one location, check 15 emits a warning. [Source 3]
- Status remains pass with zero critical failures.

## Anti-Patterns

- Including the snapshot date line defeats the purpose of this fixture.

## Sources

1. Deterministic checks documentation
2. Framework test specification
3. Check 15 behavioral definition
