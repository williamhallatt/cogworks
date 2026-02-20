---
name: cogworks-learn
description: "Codex-first guidance for writing high-quality SKILL.md based skills with compact router entrypoints, canonical references, runtime-correct tool contracts, and strong deduplication discipline."
---

# Skill Writer Expert (Codex-First)

When invoked, produce or review skills to this quality standard:
- source-fidelity
- runtime correctness
- decision completeness
- token efficiency

## Generated Skill Quality Standard

1. `SKILL.md` is a router entrypoint, not a full knowledge dump.
2. `reference.md` is the canonical source of truth.
3. `patterns.md` and `examples.md` are optional and only allowed when unique.
4. Runtime tool names and schemas must match target runtime.
5. Duplicate restatements across files are not allowed.

## Runtime Correctness Baseline

In this repository runtime:
- use `exec_command` for shell operations
- use `apply_patch` for deterministic file edits
- use `update_plan` with `plan: [{step, status}]`
- use `multi_tool_use.parallel` for independent batched calls

## Token Efficiency Baseline

- Keep SKILL entrypoint compact and directive.
- Put detailed doctrine in one canonical reference.
- Add optional files only if they add net-new decision value.
- Prefer cross-reference to restatement.

## File Map

- `reference.md`: canonical authoring doctrine and QA rubric
- `patterns.md`: transferable patterns and anti-patterns
- `examples.md`: concise, runtime-correct before/after examples
- `persuasion-principles.md`: optional compatibility reading

## Checklist Before Finalizing

- Are all normative examples runtime-valid?
- Is `SKILL.md` a compact router?
- Is `reference.md` canonical and complete?
- Are supporting files unique and necessary?
- Are sources and freshness markers present for generated-from-sources skills?

See `reference.md` for full standards and acceptance gates.
