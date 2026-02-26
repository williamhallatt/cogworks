# Reference

## TL;DR

This reference.md is deliberately missing the `Quick Reference` section to trigger check 21 warnings.

## Decision Rules

- If `Quick Reference` is absent from reference.md, check 21 should emit a warning. [Source 1]
- The skill should still pass (status: pass) with zero critical failures. [Source 2]

## Anti-Patterns

- Including all required sections defeats the purpose of this fixture. [Source 3]

## Sources

> **Knowledge snapshot date:** 2026-01-01

1. Deterministic checks documentation
2. Framework test specification
3. Check 21 behavioral definition
