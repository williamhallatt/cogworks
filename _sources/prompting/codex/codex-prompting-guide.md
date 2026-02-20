# Codex Prompting Guide - Documentation Summary

## Overview
This guide provides best practices for using OpenAI's Codex-tuned model (`gpt-5.2-codex`) via the API. The documentation emphasizes that Codex models represent "the frontier of intelligence and efficiency" for agentic coding tasks, with improvements in speed, token efficiency, and autonomous long-running capabilities.

## Key Model Improvements
- **Efficiency**: Uses fewer thinking tokens; "medium" reasoning effort recommended for interactive coding
- **Intelligence**: Capable of autonomous multi-hour tasks with "high" or "xhigh" reasoning effort
- **Context Management**: First-class compaction support enables multi-hour reasoning without hitting context limits
- **Platform Support**: Enhanced PowerShell and Windows environment compatibility

## Getting Started Strategy

To migrate existing implementations, the guide recommends:

1. Update prompts starting with the standard Codex-Max prompt as a base
2. Focus on autonomy, persistence, codebase exploration, and tool use sections
3. Remove prompting for upfront plans or status updates that may cause premature termination
4. Update tools, especially `apply_patch` implementation

## Core Prompting Principles

**Autonomy**: The model should operate as "a discerning engineer" that gathers context, plans, implements, tests, and refines without waiting for intermediate approvals.

**Code Quality**: Emphasis on correctness over speed, adherence to codebase conventions, comprehensive coverage, and tight error handling—avoiding broad try-catch blocks or silent failures.

**Tool Use**: Prefer dedicated tools over shell commands when available; parallelize tool calls to maximize efficiency.

## Tool Implementations

### Apply_patch
The guide provides sample implementations using both the Responses API's built-in tool and a custom context-free grammar approach, with links to canonical implementations in the OpenAI cookbook.

### Shell_command
Recommended as the default shell tool, with string-type commands performing better than command lists. The tool supports working directory specification and timeout parameters.

### Update_plan
A TODO management tool for tracking task progress with statuses: pending, in_progress, or completed.

### Additional Tools
Other tools (web search, semantic search, memory) work but require more tuning. The guide recommends making tool names semantically clear and providing explicit prompting about when and how to use them.

## Compaction for Long Contexts

The Responses API offers first-class compaction via the `/compact` endpoint, enabling:
- Multi-turn conversations without context window degradation
- Long-running agent trajectories exceeding typical context limits
- Retention of key prior state with fewer tokens

## Advanced Features

**Parallel Tool Calling**: When enabled, the model batches file reads and searches together using `multi_tool_use.parallel`, maximizing efficiency.

**AGENTS.md Files**: Codex-cli automatically discovers and injects instructions from `AGENTS.md` files in repository directories, with later directories overriding earlier ones.

**Mid-Rollout Updates**: The model provides reasoning summaries as intermediate communications, generated separately and not subject to prompting instructions.

## Output Guidelines

Final responses should follow these principles:
- Use plain text with natural language headings
- Lead code changes with quick explanations
- Reference file paths using inline code formatting
- Suggest logical next steps rather than dumping large code blocks
- Maintain a collaborative, concise, factual tone

---

## Source

https://developers.openai.com/cookbook/examples/gpt-5/codex_prompting_guide
