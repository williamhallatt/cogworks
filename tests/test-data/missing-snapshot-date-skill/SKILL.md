---
name: missing-snapshot-date-skill
description: A minimal skill fixture for testing that a reference.md without a snapshot date line produces a warning. Use when testing check 15 of the deterministic validation suite.
---

# Missing Snapshot Date Fixture

This skill has a reference.md with all required sections but no `> **Knowledge snapshot date:**` line.

> **Knowledge snapshot from:** 2026-01-01

## When to Use

Use when testing check 15 (snapshot date presence).

## Quick Decision Cheatsheet

- If testing snapshot date detection → use this fixture.

## Invocation

Invoke via direct test runner reference only.
