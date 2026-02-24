---
name: codex-prompt-engineering
description: Optimize Codex/GPT prompts for gpt-5.1, gpt-5.2, and gpt-5.2-codex with calibrated reasoning effort, autonomous execution patterns, correct tool contracts (apply_patch, exec_command, update_plan), compact outputs, evaluation flywheel loops, and production security controls.
---

# Codex Prompt Engineering

> **Knowledge snapshot:** 2026-02-20

## Purpose

Use this skill to design or review prompts for Codex/GPT coding agents with focus on:
- quality and reliability
- token efficiency
- correct tool usage
- safe autonomy

## Use When

- Writing or revising system prompts for coding agents
- Debugging weak agent behavior (stalling, verbosity, bad tool calls)
- Calibrating `reasoning_effort` (`none|low|medium|high|xhigh`)
- Defining tool orchestration and planning behaviors
- Building evaluation loops for prompt iteration

## Core Rules

1. **Calibrate reasoning effort**
- `none` or omit for trivial formatting/retrieval
- `medium` default for interactive coding
- `high`/`xhigh` for complex autonomous tasks

2. **Run end-to-end autonomously**
- gather context -> plan -> implement -> test -> refine
- ask only for ambiguity, destructive actions, or major architecture trade-offs

3. **Use correct tool contracts**
- file edits: `apply_patch`
- shell execution: `exec_command`
- task tracking: `update_plan` with `plan: [{step, status}]`
- batch independent calls with `multi_tool_use.parallel`

4. **Keep communication compact**
- tiny change: 2-5 sentences
- medium change: <=6 bullets
- large change: per-file summary + rationale

5. **Evaluate systematically**
- Analyze -> Measure -> Improve -> Repeat
- keep graders and representative datasets

6. **Apply security basics**
- validate/sanitize untrusted inputs
- defend against direct/indirect prompt injection
- enforce least privilege for tools/data

## Runtime Mapping Note

Some environments expose shell tools under different names. In this repository runtime:
- use `exec_command` (not `shell_command`)
- use `update_plan` schema: `plan` with `step/status`

## File Guide

- `reference.md`: compact canonical guidance and checklists
- `patterns.md`: reusable patterns beyond prompt engineering
- `examples.md`: concise before/after examples with correct contracts

## Invocation

```text
Use codex-prompt-engineering to review this prompt for quality and token efficiency.
```
