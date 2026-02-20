---
name: cogworks
description: "Encode topic knowledge into Codex-invokable skills from URLs and files, creating skill directories under .agents/skills (repo) or ~/.agents/skills (user). Use only when the user explicitly asks to create a new skill (for example: cogworks encode, cogworks learn, cogworks automate)."
---

# Cogworks (Codex Orchestrator)

## Role

Create high-quality Codex skills from source material with a codex-first, token-efficient output standard.

## Default Generation Profile

- Profile: `codex-compact` (default)
- Priority order:
1. Runtime-correct contracts
2. Source fidelity and contradiction handling
3. Deduplication across files
4. Token efficiency

## Workflow

### 1) Gather Sources

Supported invocations:
- `cogworks encode <sources> as <skill_name>`
- `cogworks encode <sources> to <path>`
- `cogworks encode <sources> as <skill_name> to <path>`
- `cogworks encode <sources> --test`

Source ingestion:
- files: read content directly
- directories: enumerate with `rg --files` then read relevant files
- URLs: fetch content via web tools
- URL lists in files: extract and fetch each URL

If any source fails, report failures and ask whether to continue.

### 2) Compute Destination

- Default base path: `./.agents/skills`
- Global install only if explicitly requested: `~/.agents/skills`
- If `to <path>` exists, use it as base

Set `{skill_path}` to `<base_path>/{slug}/`.
If target exists, ask for overwrite confirmation.

### 3) Synthesize with `cogworks-encode`

Capture `{snapshot_date}` with `date +%F`.

Use the `cogworks-encode` methodology, but output must follow adaptive structure, not fixed bloat.

Required minimum structure:
- `SKILL.md` (router entrypoint)
- `reference.md` (canonical source of truth)

Optional structure (only if unique information exists):
- `patterns.md`
- `examples.md`

If optional files would duplicate `reference.md`, fold content into `reference.md` and do not create them.

### 4) Pre-Write Quality Gates (Required)

All gates must pass before writing files.

1. Runtime contract gate
- shell tool naming is runtime-correct (`exec_command` in this repo runtime)
- planning schema examples use `update_plan` with:
```json
{"plan":[{"step":"...","status":"pending|in_progress|completed"}]}
```
- no normative `"tasks": [...]` planning payloads

2. Dedup gate
- each file must add unique information
- no reformatted restatements across files

3. Compactness gate
- `SKILL.md` is a router, not full reference
- avoid mandatory sections that add no information

4. Citation/fidelity gate
- normative claims are source-backed
- contradictions are explicitly resolved
- unresolved uncertainty is explicitly stated

### 5) User Review

Before writing, present:
- topic, source count, destination
- concise synthesis summary
- file layout decision (`reference-only` vs `reference + optional files`)
- gate status summary

Ask for approval.

### 6) Write Files

Generate:
- `SKILL.md` with valid frontmatter (`name`, `description` only)
- `reference.md` canonical guidance
- optional supporting files only if unique

Snapshot date placement:
- `SKILL.md`: immediately after H1 title
- `reference.md`: at start of Sources section

### 7) Post-Write Lint and Repair (Required)

Run a static lint pass on generated files:
- invalid runtime tool names in normative guidance
- invalid planning schema examples
- unresolved placeholders
- obvious duplication markers

If lint fails, auto-repair once and re-lint.
If still failing, report failure clearly.

### 8) Optional Validation

Run only when user passed `--test`.

Layer 1 deterministic checks:
```bash
bash .claude/test-framework/graders/deterministic-checks.sh {skill_path} --json
```

If critical failures occur, fix and retry once.

### 9) Report Completion

Return:
- topic and slug
- skill location
- produced file layout
- gate/lint results
- validation status (if run)

## Variable Naming

- `{skill_path}`: destination directory
- `{slug}`: generated skill identifier
- `{topic_name}`: human-readable topic
- `{snapshot_date}`: synthesis date (`YYYY-MM-DD`)

## Edge Cases

- Insufficient sources: explain thin coverage and ask whether to continue.
- Contradictory sources: resolve explicitly and document rationale.
- Overlapping domains: propose split vs merge with trade-off.
- Generic content: recommend against new skill if not adding unique value.
