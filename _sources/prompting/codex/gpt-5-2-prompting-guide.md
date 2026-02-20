# GPT-5.2 Prompting Guide - Summary

## Overview

This guide provides production-focused prompting strategies for GPT-5.2, OpenAI's flagship model designed for enterprise and agentic workloads. The document emphasizes that "GPT-5.2 is especially well-suited for production agents that prioritize reliability, evaluability, and consistent behavior."

## Key Behavioral Differences from Prior Models

GPT-5.2 exhibits several distinctive characteristics:

- **More deliberate scaffolding** with clearer intermediate structure
- **Lower verbosity** while remaining prompt-sensitive
- **Stronger instruction adherence** with improved formatting
- **Conservative grounding bias** favoring correctness and explicit reasoning

## Core Prompting Patterns

### 1. Verbosity Control
The guide recommends concrete length constraints, such as "3–6 sentences or ≤5 bullets for typical answers" with adjustments based on task complexity.

### 2. Scope Discipline
For frontend/design tasks, explicitly forbid extra features: "No extra features, no added components, no UX embellishments."

### 3. Long-Context Handling
For documents exceeding ~10k tokens, produce internal outlines and re-state constraints before answering to reduce "lost in the scroll" errors.

### 4. Ambiguity Mitigation
When uncertain about external facts or requirements, present 2-3 interpretations with labeled assumptions rather than fabricating details.

## Migration Guidance

The document provides mapping for transitioning from prior models:

- GPT-4o/4.1 → GPT-5.2 with `reasoning_effort: none`
- GPT-5 → GPT-5.2 preserving existing effort levels (except `minimal` → `none`)

Five-step migration process: switch models first, pin reasoning effort, run evals, tune prompts if needed, then re-evaluate.

## Specialized Workflows

**Web Research:** Emphasizes comprehensive searching with citations, resolving contradictions, and covering all plausible user intents without asking clarifying questions.

**Structured Extraction:** Always provide JSON schemas; distinguish required vs. optional fields; handle missing data explicitly with null values.

**Tool Calling:** Parallelize independent operations; restate changes after write operations; prefer tools for fresh data over internal knowledge.

## Compaction for Extended Context

The guide introduces response compaction via `/responses/compact` endpoint for long-running agent workflows, producing opaque encrypted items that preserve task-relevant information while reducing token usage.

---

## Source

https://developers.openai.com/cookbook/examples/gpt-5/gpt-5-2_prompting_guide
