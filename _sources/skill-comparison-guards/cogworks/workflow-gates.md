# Workflow Gates (Cogworks Orchestration)

Use these gates for end-to-end `cogworks` execution.

## Dependency Gates
- Verify both supporting skills are accessible before workflow execution:
  - `../cogworks-encode/SKILL.md`
  - `../cogworks-learn/SKILL.md`
- If either is missing, stop and return install guidance.

## Source Intake Gates
- Record all source inputs in a source manifest with:
  - `type` (`file` or `url`)
  - `uri`
  - `original_uri` when applicable
- Report source load failures and request continuation decision.

## Workflow Integrity Gates
- Follow sequence strictly:
  1. Gather
  2. Slug + destination
  3. Synthesize
  4. Review/approval
  5. Generate files
  6. Validate + rewrite
  7. Install prompt
- Never generate files before user approval.

## Metadata Gates
- Detect defaults for `license`, `author`, `version`.
- If destination exists, apply version bump policy before generation.

## Validation Gates
- Run deterministic validation when available.
- If canonical validator is unavailable, run fallback deterministic checks:
  - required files
  - required sections
  - citations present
  - metadata schema keys
  - balanced markdown fences
- Run mandatory rewrite pass after validation to tighten normative language.

## Completion Gates
- Output must include:
  - topic + slug
  - generated skill path
  - validation status
  - metadata manifest status
  - install command for interactive user execution
