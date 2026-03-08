# Skill Writer - Transferable Patterns

Source IDs map to `reference.md#sources`.

This file is intentionally narrow. Use it only when you need reusable patterns
that are not already obvious from [reference.md](reference.md).

## Patterns

### 1. Entry Contract + Reference Split

Use when a skill needs both fast loading and deeper doctrine.

Pattern:
- keep `SKILL.md` focused on role, trigger, execution posture, and file index
- move detailed rules and edge cases into `reference.md`
- link every support file directly from `SKILL.md`

Why it matters: this preserves context budget without hiding critical rules two
hops away.

### 2. Conditional Compatibility Disclosure

Use when a skill relies on runtime-specific features such as Claude-only
frontmatter or placeholders.

Pattern:
- add `compatibility:` in frontmatter
- add a short Compatibility section in the body
- name the exact feature that is runtime-specific

Why it matters: the user and the model both need one canonical place to learn
what will not port.

### 3. Fail-Closed Verification Gates

Use for skills with side effects, trust boundaries, or brittle outputs.

Pattern:
- include explicit verification steps
- name the blocking condition
- tell the agent to stop instead of hand-waving around a failed gate

Why it matters: this prevents polished but unsafe outputs from looking done.

### 4. Canonical Doctrine Placement

Use when a skill family grows beyond one file.

Pattern:
- `SKILL.md` for operator-facing execution rules
- `reference.md` for normative doctrine
- `patterns.md` for transferable patterns only
- `examples.md` for non-redundant examples only

Why it matters: the same rule stated three ways becomes drift, not clarity.

## Anti-Patterns

### 1. Monolithic Entry Prompt

Problem: `SKILL.md` tries to be the workflow, the validator, and the reference
manual at once.

Fix: compress the entry contract and defer detail to linked support files.

### 2. Reformatted Duplication

Problem: support files mostly restate `reference.md` in different shapes.

Fix: delete or absorb any support file that does not add unique information.

### 3. Broad Bright-Line Language In Reference Skills

Problem: heavy `YOU MUST` style wording in reference material makes newer
models overtrigger and apply rigid rules outside their intended boundary.

Fix: reserve strong authority for high-fragility gates; use conditional
natural-language directives elsewhere.
