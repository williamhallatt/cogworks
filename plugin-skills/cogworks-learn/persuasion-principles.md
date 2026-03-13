# Persuasion Calibration For Skill Design

Use this file only when choosing wording strength for a fragile workflow.

Default rule:
- reference and guidance skills should use conditional natural-language
  directives
- strong authority language is reserved for fail-closed gates and genuinely
  high-fragility workflows

## Use Strong Authority When

All of these are true:
- the action is destructive, irreversible, or trust-critical
- rationalization would create real user risk
- the workflow has a clear verification gate or stop condition

Recommended shape:

```markdown
Run the verification command before proceeding. If it fails, stop and report
the blocking issue rather than continuing with a best-effort result.
```

## Avoid Strong Authority When

Any of these are true:
- the skill is primarily reference material
- the task benefits from local adaptation
- the guidance is advisory rather than fail-closed

Avoid:
- `YOU MUST`
- `No exceptions`
- broad `always` / `never` phrasing with no boundary condition

Why: newer models overtrigger on bright-line wording in reference contexts and
become rigid where judgment is required.

## Preferred Calibration Ladder

1. Plain directive: use for normal operator guidance
2. Conditional directive: use when boundary conditions matter
3. Fail-closed directive: use when the model must stop on a blocking issue

If two levels would work, use the weaker one.
