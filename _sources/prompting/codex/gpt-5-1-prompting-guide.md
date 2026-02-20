# GPT-5.1 Prompting Guide - Documentation Extract

## Overview

This guide provides prompt patterns to maximize GPT-5.1 performance in production deployments. The model balances intelligence and speed for agentic and coding tasks while introducing a `none` reasoning mode for low-latency interactions.

## Key Migration Guidance from GPT-5

When transitioning to GPT-5.1:

1. **Persistence**: Emphasize importance of complete answers through prompting
2. **Output formatting**: Be explicit about desired detail levels
3. **Coding agents**: Use the new named `apply_patch` tool implementation
4. **Instruction following**: Leverage the model's improved adherence to clear instructions

## Agentic Steerability

### Personality Shaping

GPT-5.1 allows robust control over agent behavior, tone, and communication style. Define a clear agent persona, especially for customer-facing applications. The guide demonstrates balancing directness with warmth by:

- Using adaptive politeness based on user context
- Avoiding stock acknowledgments ("got it")
- Prioritizing efficiency and momentum
- Matching user conversational rhythm

### Output Compactness Rules

For coding agents, specify response length constraints:
- Tiny changes (≤10 lines): 2-5 sentences maximum
- Medium changes: ≤6 bullets or 6-10 sentences
- Large changes: Summarize per file; avoid large code blocks

### User Updates (Preambles)

GPT-5.1 excels at sharing upfront plans and progress updates. Configure along four axes:

- **Frequency**: 1-2 sentence updates every few tool calls (max 6-8 steps between updates)
- **Content**: Include meaningful discoveries, concrete outcomes, plan changes
- **Structure**: Initial plan, exploration updates, recap with status checklist
- **Immediacy**: Explain actions BEFORE analysis to improve perceived latency

## Optimizing Intelligence and Instruction-Following

### Encouraging Complete Solutions

Prompt the model to act as an autonomous senior developer:
- Gather context proactively
- Implement end-to-end without waiting for follow-ups
- Persist until tasks are fully handled
- Assume "yes" answers should be actioned

### Tool-Calling Format

Provide clear tool descriptions with:
- What the tool does
- When/how to use it
- Concrete examples of proper invocation
- Explicit rules for required parameters

### Parallel Tool Execution

Enable efficiency by prompting parallelization: "Batch reads and edits to speed up the process."

### Using "none" Reasoning Mode

GPT-5.1's new `none` mode eliminates reasoning tokens, similar to GPT-4.1. For improved accuracy:

- Plan extensively before function calls
- Reflect on previous outcomes
- Verify outputs meet all constraints before executing
- Keep queries completely resolved before ending

## Maximizing Coding Performance

### Planning Tool Usage

For medium+ tasks, create lightweight plans with:
- 2-5 milestone/outcome items (no micro-steps)
- Status tracking (one in_progress item at a time)
- Timely updates (never >8 tool calls without update)
- Zero pending/in_progress items before turn completion

### Design System Enforcement

When building frontends, constrain GPT-5.1 to match visual designs:
- Use token-based CSS variables instead of hard-coded colors
- Define tokens in globals.css
- Consume via Tailwind utilities wired to tokens
- Default to neutral palette unless explicitly requested otherwise

## New Tool Types in GPT-5.1

### apply_patch Tool

Creates, updates, and deletes files using structured diffs. Usage via Responses API:

```
response = client.responses.create(
    model="gpt-5.1",
    input=RESPONSE_INPUT,
    tools=[{"type": "apply_patch"}]
)
```

Responses include `apply_patch_call` with operation type and diff. Return execution results as:

```
{
    "type": "apply_patch_call_output",
    "call_id": call["call_id"],
    "status": "completed" or "failed",
    "output": log_output
}
```

### shell Tool

Allows controlled command-line interface interaction. Invoked as:

```
tools = [{"type": "shell"}]
```

Returns `shell_call` object with timeout, max output length, and commands. Output response includes stdout/stderr logs and exit codes.

## Metaprompting Effectively

Use GPT-5.1 to debug and improve your own prompts through two-step process:

**Step 1**: Request root-cause analysis of failure modes
- Provide system prompt and failure examples
- Ask model to identify distinct failure modes
- Quote specific prompt sections driving behavior

**Step 2**: Request surgical revisions
- Share analysis results
- Request targeted edits preserving structure
- Output patch notes and revised prompt

This iterative approach helps maintain discrete boundaries for tools and usage conditions as systems scale.

---

*For implementation details and latest updates, refer to the official [OpenAI documentation](https://platform.openai.com/docs/guides/latest-model) and [blog post](https://openai.com/index/gpt-5-1-for-developers/).*

---

## Source

https://developers.openai.com/cookbook/examples/gpt-5/gpt-5-1_prompting_guide
