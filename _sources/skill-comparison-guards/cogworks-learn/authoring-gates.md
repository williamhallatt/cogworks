# Authoring Gates (Cogworks-Learn)

Use these gates when generating skill files and frontmatter.

## Invocation Precision Gates
- Include explicit positive triggers.
- Include explicit negative triggers where false positives are plausible.
- Avoid vague catch-all trigger language.

## Context Efficiency Gates
- Keep `SKILL.md` activation-focused and concise.
- Put deep doctrine/examples in supporting docs.
- Avoid doctrinal duplication across files.

## Actionability Gates
- Instructions must be imperative and specific.
- Include clear workflow steps and expected deliverables.
- Include explicit done state and handoff boundary.

## Scope & Safety Gates
- Define in-scope and out-of-scope behavior.
- Add failure-mode boundaries for ambiguous requests.
- Prefer safe defaults when intent is underspecified.

## Runtime Contract Gates
- Frontmatter fields valid and complete.
- Metadata manifest schema complete and consistent.
- Example/tooling guidance matches target runtime constraints.

## Rewrite Gates (Mandatory)
- Rewrite weak wording into direct instruction.
- Remove filler and duplicate doctrine.
- Re-check invocation precision and failure-mode safety after rewrite.
