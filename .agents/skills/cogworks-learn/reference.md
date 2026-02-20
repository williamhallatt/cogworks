# Skill Authoring Reference (Codex-First)

## TL;DR

High-quality Codex skills are compact at the entrypoint, canonical in one reference file, runtime-correct in tool contracts, and free of cross-file duplication.

## Core Concepts

1. **Router Entrypoint**
`SKILL.md` should route intent, define constraints, and point to canonical material.

2. **Canonical Reference**
`reference.md` holds detailed doctrine, rules, and checklists.

3. **Contract Correctness**
Normative examples must match the actual runtime contract.

4. **Dedup Discipline**
Each file must add unique information.

5. **Adaptive Structure**
File set grows only when additional files provide real decision value.

## Codex Runtime Contract (Normative)

For this repository runtime:
- shell execution: `exec_command`
- patching: `apply_patch`
- planning: `update_plan` with
```json
{"plan":[{"step":"...","status":"pending|in_progress|completed"}]}
```
- batching: `multi_tool_use.parallel`

Invalid in normative guidance for this runtime:
- `shell_command` as the required shell tool name
- `{"tasks": [...]}` as the planning schema

## Skill Structure Policy

Required:
- `SKILL.md`
- `reference.md`

Optional (conditional):
- `patterns.md`
- `examples.md`

Create optional files only when each contributes unique, non-redundant content.

## Token Efficiency Architecture

1. Keep entrypoint short and directive.
2. Store deep detail in one canonical file.
3. Cross-link, do not restate.
4. Remove sections that add format but no new information.
5. Prefer checklists over long narrative repetition.

## Authoring QA Rubric (Pass/Fail)

### A. Runtime Contract Correctness
- [ ] Tool names match runtime
- [ ] Planning schema examples use `plan[{step,status}]`
- [ ] No invalid normative payloads

### B. Source Fidelity
- [ ] Normative claims are source-backed
- [ ] Contradictions are surfaced and resolved
- [ ] Uncertainty is explicit where needed

### C. Compactness
- [ ] `SKILL.md` is router-style
- [ ] No mandatory filler sections
- [ ] Supporting files are justified by unique value

### D. Deduplication
- [ ] No reformatted duplication across files
- [ ] `reference.md` remains canonical

### E. Hygiene
- [ ] No unresolved placeholders
- [ ] Snapshot markers included for generated-from-sources skills

## Prompt Quality Gates for Generated Skills (Required)

These gates are mandatory when `cogworks` uses `cogworks-learn` to generate a skill.

### Gate 1: Instruction Clarity
- Use direct, actionable wording for required behavior.
- Replace vague language ("consider", "maybe", "if relevant") in normative steps.
- State non-optional constraints explicitly.

### Gate 2: Source-Faithful Reasoning
- Every normative claim must be source-backed.
- Conflicts between sources must be called out and resolved with rationale.
- Unknowns must be left explicit; do not infer unsupported facts.

### Gate 3: Runtime Contract Correctness
- Tool names and payload schemas must match runtime exactly.
- Planning payloads use `{"plan":[{"step":"...","status":"..."}]}` only.
- Remove runtime-invalid examples from normative guidance.

### Gate 4: Canonical Placement
- Each rule appears once in one canonical location.
- `reference.md` remains source of truth for doctrine.
- Supporting files may add context, but cannot restate canonical rules.

### Gate 5: Token-Dense Quality
- Keep decision-relevant constraints; remove ornamental narrative.
- Preserve critical safety and correctness requirements while compressing.
- Avoid fixed section quotas that add filler.

## Instruction Quality Rewrite Pass (Required)

After draft generation and before completion:

1. Rewrite weak or ambiguous directives into concrete actions.
2. Remove duplicate doctrine and cross-file repetition.
3. Compress low-value prose while preserving hard constraints.
4. Re-run all five prompt quality gates.

A generated skill is not complete until the rewrite pass and gate re-check both succeed.

## Generated-From-Sources Freshness Markers

In `SKILL.md`:
```markdown
> **Knowledge snapshot from:** YYYY-MM-DD
```

In `reference.md` Sources section:
```markdown
> **Knowledge snapshot date:** YYYY-MM-DD
>
> These sources were fetched and synthesized on the date shown above.
> Information may have changed since then.
```

## Anti-Patterns

1. Monolithic entrypoint that duplicates full reference material.
2. Runtime-incompatible normative examples.
3. Forcing large fixed templates regardless of content density.
4. Duplicating the same rules across all supporting files.
5. Ignoring contradictions between sources.

## Sources

1. Codex prompting guidance and tool usage docs.
2. Cogworks synthesis workflow and validation practices.
3. Prompt quality/evaluation flywheel references.
4. `../codex-prompt-engineering/reference.md` (canonical prompt-engineering doctrine for gate maintenance).
