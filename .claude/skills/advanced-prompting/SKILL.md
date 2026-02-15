---
name: advanced-prompting
description: Advanced prompt engineering techniques for Claude. Covers explicitness, multishot examples, extended/adaptive thinking, XML tags, chain-of-thought, state management, tool steering, subagent orchestration, formatting control, and model-specific best practices for Opus 4.6 and Sonnet 4.5. Use when writing system prompts, optimizing Claude performance, or building agentic workflows.
---

# Advanced Prompting for Claude

Expert knowledge on prompt engineering techniques for Claude, synthesized from 4 Anthropic documentation sources covering prompt engineering fundamentals, multishot prompting, extended thinking strategies, and model-specific best practices for the latest Claude models (Opus 4.6, Sonnet 4.5, Haiku 4.5).

## Knowledge Base Summary

- **Technique hierarchy matters**: Anthropic ranks techniques by general effectiveness -- clarity/explicitness first, then multishot examples, then chain-of-thought/thinking, then XML tags, then role/system prompts, then prompt chaining. Try them in this order when troubleshooting.
- **Latest models follow instructions precisely**: Opus 4.6 and Sonnet 4.5 follow instructions more literally than predecessors. This means over-prompting ("CRITICAL: You MUST...") now causes overtriggering. Dial back aggressive language.
- **Adaptive thinking supersedes extended thinking**: Opus 4.6 uses `thinking: {type: "adaptive"}` where Claude decides when and how much to think. Control depth with the `effort` parameter rather than `budget_tokens`.
- **Multishot prompting is a force multiplier**: 3-5 diverse, relevant examples dramatically improve output consistency and accuracy, especially for structured outputs.
- **Explicitness beats inference**: Claude will do exactly what you say rather than guessing what you want. "Can you suggest changes?" gets suggestions; "Make these changes" gets implementations.
- **State management enables long-horizon work**: Structured state files (JSON), freeform progress notes, and git-based tracking let Claude maintain coherence across multiple context windows.

## Core Expertise Areas

1. **Explicitness Principle** -- Why Claude needs explicit requests, not hints
2. **Multishot Prompting** -- 3-5 diverse examples for structured output consistency
3. **Thinking Modes** -- Extended thinking, adaptive thinking, interleaved thinking
4. **Technique Hierarchy** -- Ordered effectiveness for troubleshooting
5. **Tool Steering** -- Controlling tool triggering, parallel execution, action bias
6. **State Management** -- Multi-window workflows with structured and unstructured persistence
7. **Formatting Control** -- Prose vs markdown, XML tags, positive framing
8. **Autonomy Calibration** -- Balancing proactive action with safety guardrails
9. **Subagent Orchestration** -- When to delegate vs work directly

## Quick Decision Guide

**Claude is not doing enough?**
Be more explicit. Say "implement" not "suggest." Add quality modifiers: "Go beyond the basics to create a fully-featured implementation."

**Claude is doing too much?**
Add scope constraints. "Only make changes that are directly requested or clearly necessary." Lower the `effort` parameter. Remove any previous anti-laziness prompting.

**Output format is wrong?**
Tell Claude what TO do, not what NOT to do. Match your prompt's formatting to desired output. Use XML tags as format indicators.

**Claude is not using tools?**
Check for ambiguous phrasing. "Can you look at..." may not trigger tool use. Say "Read the file at..." explicitly.

**Claude is overthinking?**
Add: "Choose an approach and commit to it. Avoid revisiting decisions unless you encounter new information that directly contradicts your reasoning."

## Full Knowledge Base

Core concepts and relationships in [reference.md](reference.md):

- **9 core concepts** with definitions and cross-source synthesis
- **15 concept relationships** showing how techniques interact
- **3 deep dives** on adaptive thinking evolution, the explicitness spectrum, and multi-window state management
- **Quick reference** with the technique hierarchy and key prompt snippets

Patterns and anti-patterns in [patterns.md](patterns.md):

- **8 reusable patterns** with when/why/how guidance
- **6 anti-patterns** with explanations and better alternatives

Practical examples in [examples.md](examples.md):

- **8 complete examples** with before/after comparisons and source citations
