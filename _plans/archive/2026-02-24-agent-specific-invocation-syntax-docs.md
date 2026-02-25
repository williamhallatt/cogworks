# Plan: Document Agent-Specific Skill Invocation Syntax

## Context

All user-facing documentation currently shows skill invocation using `/skill-name` syntax (e.g. `/cogworks encode ...`). This syntax is correct for Claude Code but not universal — OpenAI Codex CLI uses `$skill-name` instead. Other agents may differ further.

Users installing cogworks on Codex CLI currently have no documentation cue that the prefix changes; they must discover this themselves. The fix is to annotate code block examples with both variants and add a single explanatory note per document.

## Approach

Per user direction: **agent-annotated code blocks** for all invocation examples, plus a brief introductory note in each user-facing document. Only Claude Code (`/`) and Codex CLI (`$`) are shown as concrete examples; a note indicates that other agents may vary.

Inline prose backtick references (e.g. `` `/{slug}` ``) that appear outside code blocks are updated at the most prominent occurrences; incidental or repetitive mentions can be left with a trailing note.

Section headings that use `/cogworks-encode` as a label (not a runnable command) are left unchanged, since they function as identifiers rather than executable examples.

---

## Files Modified

### 1. `README.md` (root)

- Added agent-syntax callout (`> **Note:** ...`) just before the Quick Start code block.
- Converted every invocation code block to show both `# Claude Code` and `# Codex CLI` variants.
- Updated prose reference at line ~122 ("`/{slug}`") to note agent-specific prefix.

### 2. `skills/cogworks/README.md`

- Added the same agent-syntax callout before the Quick Start code block.
- Updated the **Invocation** column header in the Three Skills table to show `(Claude Code / Codex CLI)` format.
- Converted all Quick Start code blocks and the Common Invocation Patterns block to show both variants.
- Updated all `Using Skills Independently` code blocks.

### 3. `INSTALL.md`

- Added `## Invoking Skills` section after `## Verify Installation` with a table:
  | Agent | Prefix | Example |
  |-------|--------|---------|
  | Claude Code | `/` | `/cogworks encode ...` |
  | Codex CLI | `$` | `$cogworks encode ...` |
  | Other agents | varies | consult agent documentation |

### 4. `skills/cogworks-learn/reference.md`

- Line ~95 (`name | Display name, becomes /slash-command.`) — appended "The prefix is agent-specific (e.g. `/` in Claude Code, `$` in Codex CLI)."
- Invocation Modes definition — changed "user types /skill-name" to "user types the skill command (e.g. `/skill-name` in Claude Code, `$skill-name` in Codex CLI)".

---

## Status: IMPLEMENTED (2026-02-24)
