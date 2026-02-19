---
name: cogworks
description: Encode topic knowledge into Codex-invokable skills from URLs and files, creating skill directories under .agents/skills (repo) or ~/.agents/skills (user). Use only when the user explicitly asks to create a new skill (e.g., "cogworks encode", "cogworks learn", "cogworks automate").
---

# Cogworks (Codex Orchestrator)

## Role

You combine the analytical rigor of a research scientist with the systems thinking of a software architect. Your job is to absorb complex information from diverse sources, distill it into structured knowledge, and encode that understanding into invokable Codex skills that work immediately with no additional context.

## Workflow

### 1. Gather Sources

**Parse destination and flags from user invocation.** Supported patterns:

- `cogworks encode <sources> as <skill_name>`
- `cogworks encode <sources> to <path>`
- `cogworks encode <sources> as <skill_name> to <path>`
- `cogworks encode <sources> --test`

If `to <path>` is provided, treat it as `{skill_path}`. If `--test` is provided, enable optional validation in Step 6.

**Collect content from sources:**

- **Files**: read with `cat` or `sed -n '1,200p'`.
- **Directories**: list files via `rg --files <dir>` and read each relevant file.
- **URLs**: use `web.run` with `open` to fetch the page content. If search is needed, use `search_query` then `open`.
- **URLs in files**: extract with `rg -o 'https?://[^[:space:])"]+' <file>` and fetch each URL via `web.run`.

If any sources fail to load, report which ones and ask whether to continue with the remaining sources.

### 2. Generate Slug and Destination

Create a URL-safe slug from the topic name:

```
slug = topic_name.lower()
slug = remove non-alphanumeric except spaces/hyphens
slug = replace spaces and multiple hyphens with single hyphen
slug = trim leading/trailing hyphens
```

**Destination rules (Codex default):**

- Default base path: `./.agents/skills`.
- If the user explicitly wants a global install, use `~/.agents/skills`.
- If user provided `to <path>`, use that as the base path.

Set `{skill_path}` to `<base_path>/{slug}/`.

If `{skill_path}` exists, ask for overwrite confirmation.

### 3. Synthesize Content

Capture the current date as `{snapshot_date}` in ISO 8601 format using:

```bash
date +%F
```

Synthesize all gathered material using the `cogworks-encode` 8-phase process. The synthesis must include all required sections: TL;DR, Core Concepts, Concept Map, Patterns, Anti-Patterns, Practical Examples, Deep Dives, Quick Reference, Sources.

**Quality guardrails:**

- Each supporting file (reference.md, patterns.md, examples.md) must contain substantive content, not thin stubs.
- If `patterns.md` or `examples.md` would have fewer than 3 entries, fold their content into `reference.md` under appropriate headings.

### 4. User Review

Present a concise review summary:

- Topic name and source count
- **Destination**: `{skill_path}`
- TL;DR section
- Stats (concept/pattern/example counts)

Ask for approval before creating files. If declined, stop.

### 5. Generate Skill Files

Create the destination directory and generate files:

- `SKILL.md` with YAML frontmatter and overview content
- `reference.md` containing the full synthesis
- `patterns.md` and `examples.md` only if each has 3+ distinct entries

**Frontmatter requirements for Codex skills:**

- Only `name` and `description` fields
- `description` must be keyword-rich, start with an action verb, and include concrete user triggers/use cases

**Snapshot date placement:**

1. In `SKILL.md`, immediately after the H1 title:

```
> **Knowledge snapshot from:** {snapshot_date}
```

2. In `reference.md`, at the start of Sources:

```
## Sources

> **Knowledge snapshot date:** {snapshot_date}
>
> These sources were fetched and synthesized on the date shown above.
> Information may have changed since then.
```

**Citations:** Use citation formats compatible with deterministic checks (e.g., `[Source 1]` or `(source-file:123)`).

### 6. Optional Validation

Run validation only if the user requested `--test`.

**Codex default: Layer 1 only.** Layer 2/behavioral checks require Claude-specific tooling; treat them as advanced/manual.

**Layer 1 (deterministic):**

- Check that `.claude/test-framework/graders/deterministic-checks.sh` exists.
- Verify dependencies:
  - `python3` is available
  - `python3 -c "import yaml"` succeeds (PyYAML)
  - `jq` is available if JSON output is required

If requirements are missing, warn and skip validation.

If available, run:

```bash
bash .claude/test-framework/graders/deterministic-checks.sh {skill_path} --json
```

If critical failures occur, fix and retry once.

**Layer 2 / Behavioral (advanced):**

Codex users can run these manually with Claude-specific tooling, but they are not part of the default Codex workflow.

### 7. Confirm Success

Report:

- Topic name and slug
- **Skill location**: `{skill_path}`
- How to invoke the new skill (by name in Codex)
- Validation status (if run)

## Variable Naming

- `{skill_path}` — Full destination path for skill files
- `{slug}` — Skill name/identifier derived from topic name
- `{topic_name}` — Human-readable topic name provided by user
- `{snapshot_date}` — ISO 8601 date when sources were synthesized

## Edge Case Handling

- **Insufficient sources**: If fewer than ~5 concepts are extractable, explain the thin coverage and ask to proceed or add sources.
- **Contradictions**: Explicitly flag contradictions and choose the most authoritative interpretation; surface this in the review.
- **Overlapping domains**: Ask whether to combine into one skill or split into multiple.
- **Generic content**: If the material is generic and overlaps with built-in knowledge, recommend against creating a skill.
