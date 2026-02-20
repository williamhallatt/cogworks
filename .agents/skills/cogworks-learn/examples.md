# Skill Authoring Examples (Codex-First)

## Example 1: Entrypoint Scope

### Before (Bloated)
```markdown
SKILL.md includes full doctrine, long examples, and repeated checklists.
```

### After (Router)
```markdown
SKILL.md includes purpose, use-when, core rules, file guide, invocation.
reference.md holds complete doctrine.
```

## Example 2: Planning Schema

### Before (Invalid)
```json
{"tasks":[{"id":1,"desc":"Implement","status":"pending"}]}
```

### After (Valid)
```json
{"plan":[{"step":"Implement","status":"in_progress"}]}
```

## Example 3: Shell Tool Naming

### Before (Runtime Drift)
```text
Use shell_command for terminal commands.
```

### After (Runtime-Correct)
```text
In this runtime, use exec_command for terminal commands.
```

## Example 4: Supporting File Decision

### Before (Forced)
```text
Always generate patterns.md and examples.md.
```

### After (Adaptive)
```text
Generate optional files only when they provide >=3 unique entries each.
Otherwise fold into reference.md.
```

## Example 5: Dedup

### Before
```text
Same compactness and tool rules repeated in all files.
```

### After
```text
Canonical rule lives in reference.md.
patterns/examples reference it and add only net-new context.
```

## Example 6: Contradiction Handling

### Before
```text
Source A and B disagree; output silently follows B.
```

### After
```text
Conflict note:
- A says X
- B says Y
- Choose Y for runtime v2 constraints and newer publication date
```

## Example 7: Placeholder Hygiene

### Before
```markdown
> **Knowledge snapshot from:** {YYYY-MM-DD}
```

### After
```markdown
> **Knowledge snapshot from:** 2026-02-20
```

## Example 8: Compact Review Payload

### Before
```text
Long review with repeated narrative and no gate status.
```

### After
```text
Review summary:
- topic, source count, destination
- selected file layout
- contradictions + chosen interpretation
- gate status: contract/dedup/compactness/fidelity/placeholders
```
