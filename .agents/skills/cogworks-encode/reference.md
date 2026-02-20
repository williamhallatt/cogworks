# Topic Synthesis Reference (Codex-Compact)

## Purpose

Define how to synthesize multiple sources into a high-quality Codex skill output without verbosity inflation.

## Canonical Output Template

Use this structure by default for generated `reference.md`:

1. `## TL;DR`
2. `## Core Concepts`
3. `## Implementation Rules`
4. `## Quick Checklist`
5. `## Anti-Patterns`
6. `## Sources`

Optional sections only when they add unique information:
- `## Concept Map`
- `## Deep Dives`
- `## Practical Examples`

If optional sections would restate existing material, do not create them.

## Synthesis Procedure

### Phase 1: Analyze Sources

For each source, identify:
- authority level (official docs, primary spec, tutorial, opinion)
- key claims and constraints
- overlap and conflicts with other sources

### Phase 2: Extract Concepts

Identify 5-10 core concepts when available.
For sparse material, use fewer concepts with deeper precision.

### Phase 3: Resolve Contradictions

For each conflict:
1. state Source A claim
2. state Source B claim
3. explain likely cause (version/scope/context)
4. choose recommended interpretation
5. justify recommendation with source authority and recency

### Phase 4: Build Implementation Rules

Translate concepts into actionable rules the generated skill can execute.
Rules must be specific, testable, and source-backed.

### Phase 5: Add Optional Sections Conditionally

Add concept map, deep dives, or examples only if they introduce new decision-relevant information.

### Phase 6: Final Gate Review

Run all deterministic quality gates before output.

## Deterministic Quality Gates

### Gate A: Contract Correctness

- Runtime tool names are valid for target runtime.
- Planning examples use:
```json
{"plan":[{"step":"...","status":"pending|in_progress|completed"}]}
```
- No normative `"tasks": [...]` payloads.

### Gate B: Deduplication

- Each section contributes unique information.
- No reformatted repetition of rules across files.

### Gate C: Compactness

- `SKILL.md` stays router-style.
- `reference.md` is canonical.
- Optional files only when uniquely valuable.

### Gate D: Source Fidelity

- Normative claims are backed by sources.
- Uncertainty is explicit.
- Conflicts are surfaced and resolved, not hidden.

### Gate E: Placeholder Hygiene

- No unresolved placeholders like `{topic_name}` or `{...}` in final generated files.

## Generated File Policy

### `SKILL.md`

Required content:
- frontmatter (`name`, `description`)
- purpose/use-when
- core rules
- runtime mapping note (if runtime-specific)
- file guide and invocation line

Must include snapshot marker after H1:

```markdown
# Skill Title

> **Knowledge snapshot from:** YYYY-MM-DD
```

### `reference.md`

Canonical source of truth. Keep all details here first.

### `patterns.md` and `examples.md`

Create only if each has 3+ unique entries that are not restatements of `reference.md`.
Otherwise fold into `reference.md`.

## Review Summary Template (Before Write)

Use this short review payload:
- topic and source count
- destination path
- chosen file layout (`reference-only` or `reference+supporting`)
- detected contradictions and chosen interpretation
- gate status (A-E)

## Anti-Patterns

1. Mandatory mega-template output regardless of source density.
2. Treating illustrative contrasts as normative runtime contracts.
3. Repeating same guidance across `reference.md`, `patterns.md`, and `examples.md`.
4. Hiding contradictions by silently selecting one source.
5. Overwriting compactness with arbitrary minimum section quotas.

## Sources

> **Knowledge snapshot date:** YYYY-MM-DD
>
> These sources were fetched and synthesized on the date shown above.
> Information may have changed since then.

List all sources used for synthesis with stable identifiers and URLs/paths where available.
