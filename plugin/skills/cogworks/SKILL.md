---
name: cogworks
description: "Start here — turn source material into a validated agent skill. Orchestrates cogworks-encode (synthesis) and cogworks-learn (skill generation)."
disable-model-invocation: true
license: MIT
metadata:
  author: cogworks
  version: 4.1.2
---

# Cogworks

## Overview

You are the single product entry point for turning source material into a
trustworthy generated agent skill.

Optimize for:

- skill quality
- source trustworthiness
- concise user-facing flow
- minimal context pollution

The generated skill is the product artifact. Runtime machinery exists only to
improve that artifact.

## When to Use

Use this skill only when the user explicitly invokes `cogworks` and wants skill
generation as the outcome.

If the request is analysis-only, manual skill-writing help, or does not clearly
ask for generation, clarify before creating files.

If the user asks what cogworks is, how to use it, or what support boundaries
exist, read [README.md](README.md).

## Quick Decision Cheatsheet

- explicit `cogworks` invocation means generation intent is already established
- verify `cogworks-encode` and `cogworks-learn` before running
- trust classification happens before synthesis, never after
- unsupported surfaces fail closed rather than degrading silently
- fail closed when trust, provenance, contradiction handling, or validation is
  insufficient.
- only the generated skill is a user-facing product artifact
- deterministic validation is a hard gate before final output
- runtime details such as execution surface, run root, or sub-agent metadata do
  not belong in generated skill frontmatter or metadata

## Invocation

Use `cogworks` to:

- verify both dependency skills are present and readable
- resolve topic, sources, destination, and metadata defaults
- preserve truthful runtime artifacts when the supported surface uses the internal sub-agent build path
- classify trust before synthesis using `cogworks-encode`
- run the fixed internal build through packaging and deterministic validation
- apply `cogworks-learn` packaging rules to the final skill
- keep user-facing narration to one short progress line per stage

Do not invoke this skill for general documentation Q&A or manual skill-writing
advice unless the user explicitly wants generation.

For the stable operator checklist, failure conditions, and stage contract, use
[reference.md](reference.md).

## Compatibility

Claude Code enforces the manual-only posture for this skill via
`disable-model-invocation: true`.

Codex enforces the same posture via
[agents/openai.yaml](agents/openai.yaml), with implicit invocation disabled.

Other runtimes may ignore these platform-specific controls. Keep treating
explicit user invocation as the policy boundary for any run that can create
files or directories.

## Supporting Docs

- [README.md](README.md): user-facing product overview and support boundaries
- [reference.md](reference.md): stable product contract and operator checklist
- [metadata.json](metadata.json): repo-local release metadata for this skill

The frontmatter `metadata` block is a repo-local convention. Other platforms
may ignore it; canonical package metadata for tooling lives in
[metadata.json](metadata.json).
