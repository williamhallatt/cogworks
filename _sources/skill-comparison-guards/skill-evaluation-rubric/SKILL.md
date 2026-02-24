---
name: skill-evaluation-rubric
description: Evaluate and compare agent skill implementations using a priority-ordered rubric. Use when reviewing skill quality, comparing two skills from the same source, auditing generated skills, running skill quality assessments, or deciding which implementation to keep. Covers fidelity, judgment density, drift resistance, context efficiency, composability, testability, and scope coherence.
license: none
metadata:
  author: William Hallatt
  version: '1.0.0'
---

# Skill Evaluation Rubric

> **Knowledge snapshot from:** 2026-02-24

A priority-ordered rubric for comparing two skill implementations built from the same source material.

## When to Use This Skill

- Comparing two candidate skill implementations from the same sources
- Auditing a generated skill before installation
- Reviewing a skill after regeneration to assess improvement
- Deciding whether a skill rewrite is worth keeping

## Quick Decision Cheatsheet

| Criterion | Weight | Core Question |
|---|---|---|
| Fidelity | Highest | Does it accurately represent the source? |
| Judgment density | High | Does it encode decisions the source left implicit? |
| Drift resistance | High | Does it hold shape on edge-case inputs? |
| Context efficiency | Medium | Does it load only what's needed? |
| Composability | Medium | Does it play well with other skills? |
| Testability | Medium | Can you construct a distinguishing prompt? |
| Scope coherence | Standard | Is it focused on one job? |

**Tiebreaker:** Fidelity always wins. A faithful implementation with less crisp instructions beats an actionable one that misunderstood the source.

**Separated concern:** Invocation precision (triggers, frontmatter) is metadata packaging — evaluate it independently from implementation quality.

## Supporting Docs

- [reference.md](reference.md) - Full rubric with decision rules, quality gates, and anti-patterns
