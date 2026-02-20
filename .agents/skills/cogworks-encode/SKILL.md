---
name: cogworks-encode
description: "Synthesize multiple sources into a coherent, source-faithful Codex skill knowledge base with contradiction handling, runtime-correct tool contracts, and token-efficient structure."
---

# Topic Synthesis Expertise (Codex-First)

Produce true synthesis, not concatenation.

## Mission

Transform source material into a usable skill knowledge base that is:
- source-faithful
- contradiction-aware
- runtime-correct for Codex
- compact by default

## Non-Negotiable Rules

1. Never fabricate domain knowledge.
2. Prefer precision over breadth.
3. Separate normative guidance from illustrative contrast.
4. Avoid template inflation when sections do not add unique information.

## Synthesis Process

1. Content analysis
2. Concept extraction
3. Relationship mapping (only when meaningful)
4. Pattern extraction (transferable only)
5. Anti-pattern extraction
6. Conflict detection and synthesis decision
7. Example selection (only high-signal)
8. Canonical narrative construction

## Output Policy

Required files:
- `SKILL.md` router
- `reference.md` canonical details

Optional files:
- `patterns.md` only if >=3 transferable, non-duplicative patterns
- `examples.md` only if >=3 non-duplicative, high-signal examples

If optional content duplicates `reference.md`, merge into `reference.md`.

## Runtime Contract Policy

Normative guidance must match target runtime contracts.
For this repository runtime:
- shell execution tool: `exec_command`
- planning schema:
```json
{"plan":[{"step":"...","status":"pending|in_progress|completed"}]}
```

Do not emit non-normative payloads as if valid contracts.

## Conflict Resolution Policy

For each source conflict:
- document both positions
- identify context/version causes
- choose recommended interpretation
- justify recommendation
- keep an explicit conflict note

## Source and Freshness Policy

- Include snapshot date in `SKILL.md` and `reference.md`
- Keep a complete Sources section
- Mark uncertainty where source support is weak

## Quality Checklist

Before finalizing, confirm:
- no fabricated claims
- no unresolved placeholders
- no runtime-contract mismatches
- no duplicate sections across files
- concise router entrypoint
- canonical reference exists

See `reference.md` for the compact canonical template and gates.
