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

## Integrated Prompt Quality Gates (Required)

For generated skills, all five gates must pass:

1. **Instruction clarity**: directives are explicit and actionable; avoid vague suggestions.
2. **Source-faithful reasoning**: normative guidance is source-backed and contradictions are resolved explicitly.
3. **Runtime contract correctness**: tools and schemas match runtime requirements.
4. **Canonical placement**: each rule is documented once; no cross-file restatement.
5. **Token-dense quality**: content is concise without dropping critical constraints.

After drafting, run an **instruction quality rewrite pass**:
- tighten weak phrasing into concrete directives
- remove duplicate doctrine
- preserve all hard constraints while compressing
- re-check gates after rewrite

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
- `../codex-prompt-engineering/reference.md`: canonical Codex prompt-engineering reference used to maintain these gates

## Checklist Before Finalizing

- Are all normative examples runtime-valid?
- Is `SKILL.md` a compact router?
- Is `reference.md` canonical and complete?
- Are supporting files unique and necessary?
- Are sources and freshness markers present for generated-from-sources skills?
- Did all integrated prompt quality gates pass after rewrite?

See `reference.md` for full standards and acceptance gates.
