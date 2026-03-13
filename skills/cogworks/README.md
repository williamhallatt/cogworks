# Cogworks User Guide

Cogworks turns source material into trustworthy generated agent skills.

The intended product model is simple:
- users invoke `cogworks`
- users provide links, files, or source directories
- `cogworks` returns either a validated generated skill or a blocking trust
  report

This guide describes the product surface. Maintainer-only runtime details live
in the adapter and smoke docs.

## Support Boundaries

Keep these three ideas separate:

- `cogworks` is the normal product entry point
- generated skills are portable across agents that support skills
- the trust-first internal sub-agent build flow is currently supported only on
  Claude Code and GitHub Copilot CLI

Codex can consume generated skills, but it is not a supported surface for the
current trust-first internal build flow.

## The Three Shipped Skills

| Skill | Role |
|---|---|
| `cogworks` | Normal user-facing build entry point |
| `cogworks-encode` | Synthesis doctrine and source-fidelity expertise |
| `cogworks-learn` | Skill-authoring doctrine and validation expertise |

`cogworks-encode` and `cogworks-learn` are supporting skills. They remain
available as expert surfaces, but they are not the normal end-user entry point.

## Quick Start

> **Note:** Skill prefixes are agent-specific. Examples use `/` for Claude Code.
> Other agents may use a different prefix or natural-language invocation style.

Start your agent in your project directory and invoke `cogworks` naturally:

```text
/cogworks Turn these docs into a skill for handling API authentication errors.
/cogworks Build a skill from `_sources/oncall/` for triaging incident alerts.
/cogworks Use these sources to create a skill named `release-readiness-review`.
```

Cogworks will:
1. gather and normalize the sources
2. classify trust and provenance
3. synthesize the material into decision-ready guidance
4. package a generated skill under `_generated-skills/{slug}/`
5. validate the result before presenting it

## What Users Should Expect

### One stable entry point

Users should not need to choose between internal pipeline modes.
`cogworks` is one product surface with one job: produce a high-quality
generated skill from source material.

### Fail-closed trust model

If the source set is too weak, contradictory, or untrustworthy to support a
production-ready skill, `cogworks` stops and explains why. It should not ship a
final skill while a blocking trust gap remains.

### Concise guided flow

The normal flow should ask only when necessary:
- missing source information
- overwrite confirmation
- trust-sensitive clarification

Everything else should run with strong defaults.

### Support expectations by surface

- **Claude Code**: supported for the normal user flow and the internal
  trust-first build path
- **GitHub Copilot CLI**: supported for the normal user flow and the internal
  trust-first build path when its delegated-task behavior is locally validated
- **Codex**: supported as a destination for portable generated skills, not as a
  surface for the internal trust-first build path

## Supporting Skills As Expert Surfaces

### `cogworks-encode`

Use directly only when you want synthesis help without full skill generation.

```text
/cogworks-encode I have several conflicting docs. Synthesize them into one reference.
```

### `cogworks-learn`

Use directly only when you want help designing or reviewing a skill manually.

```text
/cogworks-learn Review this SKILL.md frontmatter and suggest improvements.
```

## Maintainer-Only Internal Build Path

Claude Code and GitHub Copilot may use specialist sub-agents internally for:
- source intake
- synthesis
- skill packaging
- deterministic validation

Those are implementation details used to improve quality and context isolation.
They are not a user-facing mode switch.

The recommended install path is native-first: bootstrap the three skills and
the matching native agent files together. `npx skills add` remains a manual
skill-only path, not the full product install.

If you are using Codex, treat generated-skill portability and benchmark support
as separate from this internal build path.

Maintainer-only references:
- [agentic-runtime.md](agentic-runtime.md)
- [claude-adapter.md](claude-adapter.md)
- [copilot-adapter.md](copilot-adapter.md)
- [../../tests/agentic-smoke/README.md](../../tests/agentic-smoke/README.md)

## Prerequisites

- an agent that supports skills
- Node.js 18+ and Python 3
- a project repository where generated skills can be written to
  `_generated-skills/`

## Reinstalling or Updating

See the `skills` CLI documentation:

```bash
npx skills --help
```
