# Skill Authoring Patterns (Codex-First)

## Patterns

### 1) Router + Canonical Reference

**When:** almost always.

**Why:** minimizes load cost while preserving full guidance.

**How:**
- keep `SKILL.md` short
- place full rules in `reference.md`
- link directly from `SKILL.md`

### 2) Contract-First Examples

**When:** writing tool instructions.

**Why:** most failure modes are schema drift, not reasoning.

**How:**
- include one valid canonical payload per tool contract
- reject pseudo-schemas in normative guidance

### 3) Adaptive Supporting Files

**When:** deciding whether to generate `patterns.md` / `examples.md`.

**Why:** avoids context bloat.

**How:**
- create file only if >=3 unique entries
- otherwise fold into `reference.md`

### 4) Conflict-Resolution Notes

**When:** source references disagree.

**Why:** improves trust and portability.

**How:**
- document both claims
- choose interpretation
- justify with authority/recency

### 5) Compactness by Information Value

**When:** writing generated sections.

**Why:** reduce tokens without losing decisions.

**How:**
- prefer checklists and concise rules
- remove ornamental sectioning
- avoid re-explaining established rules

### 6) Deterministic Gate Pass Before Finalization

**When:** always before completion.

**Why:** catches contract and quality regressions early.

**How:**
- contract gate
- dedup gate
- compactness gate
- source-fidelity gate
- placeholder gate

## Anti-Patterns

### 1) Runtime Drift

**Problem:** normative guidance uses tool names not valid in target runtime.

**Fix:** map tool names to runtime and enforce via gate.

### 2) Invalid Planning Schema

**Problem:** `{"tasks":[...]}` shown as canonical plan payload.

**Fix:** use `{"plan":[{"step":"...","status":"..."}]}` only.

### 3) Reformatted Duplication

**Problem:** same rule repeated across `reference.md`, `patterns.md`, and `examples.md`.

**Fix:** keep canonical rule in one location; cross-reference elsewhere.

### 4) Template Inflation

**Problem:** forcing all sections even when they add no value.

**Fix:** conditional sections based on unique information.

### 5) Silent Conflict Selection

**Problem:** picking one conflicting source without noting trade-off.

**Fix:** include explicit conflict note and chosen rationale.

### 6) Placeholder Leakage

**Problem:** unresolved placeholders survive into final generated files.

**Fix:** add placeholder hygiene gate before publish.
