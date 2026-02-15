# Advanced Prompting - Complete Reference

Synthesized from Anthropic documentation on prompt engineering, multishot prompting, extended thinking, and model-specific best practices.

---

## TL;DR

Advanced prompting for Claude is built on a hierarchy of techniques ordered by general effectiveness: explicitness first, then multishot examples, chain-of-thought/extended thinking, XML structural tags, role assignment, and prompt chaining. The latest Claude models (Opus 4.6, Sonnet 4.5) follow instructions far more precisely than predecessors, which means previous over-prompting now causes overtriggering and should be dialed back. Extended thinking has been superseded by adaptive thinking, where Claude dynamically decides when and how deeply to reason based on query complexity and the `effort` parameter. Multishot prompting with 3-5 diverse examples dramatically improves structured output consistency. For long-horizon agentic work, structured state files combined with git-based tracking enable coherence across multiple context windows.

---

## Table of Contents

- [Core Concepts](#core-concepts) - 9 fundamental building blocks
- [Concept Map](#concept-map) - 15 relationships between techniques
- [Deep Dives](#deep-dives) - Adaptive thinking evolution, explicitness spectrum, multi-window state
- [Quick Reference](#quick-reference) - Technique hierarchy, key prompt snippets
- [Sources](#sources) - Bibliography

## Related Files

- [patterns.md](patterns.md) - 8 reusable patterns + 6 anti-patterns
- [examples.md](examples.md) - 8 practical examples with citations

---

## Core Concepts

### 1. Technique Hierarchy

Anthropic explicitly orders prompt engineering techniques from most broadly effective to most specialized. When troubleshooting performance, try them in this order:

1. **Be clear and direct** -- Eliminate ambiguity
2. **Use examples (multishot)** -- Show desired output format
3. **Let Claude think (chain of thought)** -- Enable reasoning steps
4. **Use XML tags** -- Provide structural scaffolding
5. **Give Claude a role (system prompts)** -- Set behavioral context
6. **Chain complex prompts** -- Decompose into subtasks
7. **Long context tips** -- Manage large inputs

This ordering means clarity problems should be solved with clearer instructions before reaching for techniques like role prompting or prompt chaining. [Source: prompt-engineering.md]

### 2. Explicitness Principle

Claude's latest models follow instructions precisely and literally. This is a double-edged capability: Claude will do exactly what you ask, but it will not infer unstated intentions. "Can you suggest changes?" produces suggestions. "Make these changes" produces implementations. If you want above-and-beyond behavior, you must explicitly request it.

The principle extends to context: explaining WHY a behavior matters (not just WHAT to do) helps Claude generalize. "Never use ellipses" is less effective than "Your response will be read by a text-to-speech engine, so never use ellipses since TTS cannot pronounce them." [Source: prompting-best-practice.md]

### 3. Multishot Prompting

Providing 3-5 well-crafted examples in the prompt dramatically improves accuracy, consistency, and quality. This technique is particularly effective for structured outputs where format adherence matters.

Effective examples must be:
- **Relevant** -- Mirror the actual use case
- **Diverse** -- Cover edge cases and variations to prevent unintended pattern matching
- **Clear** -- Wrapped in `<example>` tags (nested in `<examples>` if multiple)

Multishot prompting also works with extended thinking: use `<thinking>` or `<scratchpad>` XML tags in examples to demonstrate reasoning patterns that Claude will generalize to its formal thinking process. [Sources: multishot-prompting.md, extended-thinking-tips.md]

### 4. Thinking Modes

Claude supports three thinking configurations, each suited to different complexity levels:

**Standard mode (thinking off):** Default when `thinking` parameter is omitted. Suitable for straightforward tasks. Note: Opus 4.5 is sensitive to the word "think" even with thinking disabled -- use "consider," "evaluate," or "believe" instead.

**Extended thinking (legacy):** Uses `thinking: {type: "enabled", budget_tokens: N}` with explicit token budgets. Minimum budget is 1024 tokens. Best for complex STEM problems, constraint optimization, and structured frameworks. Start with minimum budget and increase as needed. For budgets above 32K tokens, use batch processing to avoid timeouts. Performs best in English.

**Adaptive thinking (current, Opus 4.6):** Uses `thinking: {type: "adaptive"}` where Claude dynamically decides when and how much to think. Depth is controlled by the `effort` parameter (`low`, `medium`, `high`, `max`) rather than explicit token budgets. Anthropic's internal evaluations show adaptive thinking reliably outperforms extended thinking. [Sources: extended-thinking-tips.md, prompting-best-practice.md]

### 5. Tool Steering

Claude's latest models are highly responsive to system prompt guidance about tool usage. This responsiveness creates both an opportunity (precise control) and a risk (overtriggering from aggressive language).

**Key behaviors:**
- Parallel tool execution is natural -- Claude will read multiple files, run multiple searches, and execute bash commands simultaneously without prompting
- Tool triggering thresholds have lowered -- instructions like "If in doubt, use [tool]" that prevented undertriggering in older models now cause overtriggering
- Action vs suggestion depends on phrasing -- "Can you suggest?" gets text; imperative phrasing gets tool calls

**Calibration:** Replace blanket defaults ("Default to using [tool]") with targeted guidance ("Use [tool] when it would enhance your understanding of the problem"). [Source: prompting-best-practice.md]

### 6. State Management

For tasks spanning multiple context windows, Claude maintains coherence through explicit state persistence:

**Structured state** (JSON, etc.): Use for test results, task status, and anything with schema requirements. Example: `tests.json` tracking pass/fail/not_started across sessions.

**Unstructured state** (text): Use for progress notes, session summaries, and general context. Example: `progress.txt` documenting what was done, what failed, and what comes next.

**Git-based state**: Git commits and logs provide natural checkpoints and history. Claude's latest models are particularly effective at using git to track and recover state across sessions.

**Context awareness**: Opus 4.6 and 4.5 models can track their remaining context window. If using an agent harness with compaction, tell Claude about it so it does not prematurely wrap up work. [Source: prompting-best-practice.md]

### 7. Formatting Control

Four techniques for steering Claude's output format, in order of effectiveness:

1. **Positive framing**: Tell Claude what to do, not what to avoid. "Write in flowing prose paragraphs" beats "Do not use markdown."
2. **XML format indicators**: Wrap output expectations in descriptive tags like `<smoothly_flowing_prose_paragraphs>`.
3. **Style mirroring**: Claude's response style is influenced by the prompt's formatting. A prompt without markdown produces less markdown in output.
4. **Detailed format specifications**: For fine-grained control, provide explicit guidance on heading levels, list usage, and emphasis conventions.

For Opus 4.6 specifically: it defaults to LaTeX for math expressions. If you prefer plain text, explicitly instruct it to use standard text characters. [Source: prompting-best-practice.md]

### 8. Autonomy Calibration

Claude Opus 4.6 is significantly more proactive than predecessors, which creates a spectrum from conservative to aggressive behavior that must be explicitly calibrated:

**Proactive (default)**: Without guardrails, Claude may delete files, force-push, or post to external services. It may also overengineer by adding abstractions, features, or flexibility that was not requested.

**Conservative (prompted)**: Add guidance to confirm before irreversible actions, minimize scope to only what was requested, and avoid defensive coding for scenarios that cannot happen.

The reversibility heuristic provides a useful decision boundary: local, reversible actions (editing files, running tests) can proceed autonomously, while irreversible or shared-system actions (force-push, database drops, PR comments) should require confirmation. [Source: prompting-best-practice.md]

### 9. Subagent Orchestration

Claude's latest models naturally recognize when tasks benefit from delegation to subagents and will spawn them proactively. However, Opus 4.6 has a strong tendency to over-use subagents, spawning them for tasks where a direct approach (like a single grep) would be faster and sufficient.

**When subagents add value**: Parallel independent tasks, isolated contexts, independent workstreams that do not share state.

**When to work directly**: Simple tasks, sequential operations, single-file edits, tasks requiring shared context across steps. [Source: prompting-best-practice.md]

---

## Concept Map

1. **Technique Hierarchy** -> orders -> **All Other Techniques** (try in sequence)
2. **Explicitness Principle** -> amplifies -> **Tool Steering** (imperative phrasing triggers tools)
3. **Multishot Prompting** -> combines with -> **Thinking Modes** (examples guide thinking patterns)
4. **Extended Thinking** -> superseded by -> **Adaptive Thinking** (Opus 4.6 migration)
5. **Adaptive Thinking** -> controlled by -> **Effort Parameter** (not budget_tokens)
6. **Tool Steering** -> requires -> **Explicitness Principle** (ambiguous phrasing prevents action)
7. **State Management** -> enables -> **Multi-Window Workflows** (persistence across context resets)
8. **Formatting Control** -> uses -> **Positive Framing** (tell what to do, not what to avoid)
9. **Formatting Control** -> uses -> **XML Tags** (structural indicators for output)
10. **Autonomy Calibration** -> balances -> **Proactive Action** vs **Safety Guardrails**
11. **Subagent Orchestration** -> constrained by -> **Autonomy Calibration** (prevent over-spawning)
12. **Multishot Prompting** -> improves -> **Formatting Control** (examples enforce consistent structure)
13. **State Management** -> uses -> **Structured State** + **Unstructured State** + **Git**
14. **Overthinking** -> mitigated by -> **Effort Parameter** + **Commitment Prompting**
15. **Context Awareness** -> enables -> **State Management** (Claude knows remaining budget)

---

## Deep Dives

### The Adaptive Thinking Evolution

Extended thinking (manual budget_tokens) and adaptive thinking (dynamic, effort-controlled) represent a fundamental shift in how Claude reasons about complex problems.

**Extended thinking** works best with high-level instructions rather than prescriptive step-by-step guidance. Claude's creativity in approaching problems may exceed a human's ability to prescribe the optimal thinking process. The recommendation is to start with generalized instructions, then read Claude's thinking output and iterate with more specific steering only where needed. That said, Claude can still follow complex structured execution steps effectively when the task demands it -- the point is to start general and add specificity only when troubleshooting.

**Adaptive thinking** removes the budget management burden entirely. Claude calibrates thinking depth based on two factors: the `effort` parameter setting and query complexity. On easy queries, Claude responds directly without thinking. On hard queries, it thinks deeply. This is promptable: if Claude thinks too often (common with complex system prompts), add guidance like "Extended thinking adds latency and should only be used when it will meaningfully improve answer quality -- typically for problems that require multi-step reasoning."

**Migration path**: Replace `thinking: {type: "enabled", budget_tokens: N}` with `thinking: {type: "adaptive"}` and move depth control to `output_config: {effort: "high"}`. If not currently using thinking, no changes needed -- thinking is off by default.

**Interleaved thinking** is particularly valuable for agentic workflows where Claude needs to reflect after receiving tool results. Prompt it explicitly: "After receiving tool results, carefully reflect on their quality and determine optimal next steps before proceeding." [Sources: extended-thinking-tips.md, prompting-best-practice.md]

### The Explicitness Spectrum

Claude's precise instruction following creates a spectrum from under-specification to over-specification, and the optimal position depends on the task.

**Under-specification** leads to minimal output. "Create an analytics dashboard" produces a basic dashboard. Claude will not add features it thinks you might want unless told to. The fix is quality modifiers: "Include as many relevant features and interactions as possible. Go beyond the basics."

**Over-specification** for current models leads to overtriggering. Prompts designed for older models that said "CRITICAL: You MUST use this tool when..." now cause Claude to trigger tools unnecessarily. The fix is natural language: "Use this tool when..." without emphasis markers.

**Optimal explicitness** varies by task fragility. High-stakes tasks (deployments, data mutations) need explicit steps with verification gates. Low-stakes tasks (formatting, style) need principles that Claude can adapt to context. The key insight is that context (explaining why) is more durable than rules (stating what), because Claude can generalize from context to novel situations while rules only cover anticipated ones. [Sources: prompting-best-practice.md, prompt-engineering.md]

### Multi-Window State Management

Long-horizon agentic tasks that span multiple context windows require a deliberate approach to state persistence. The latest Claude models are unusually effective at discovering state from the filesystem, which opens strategies beyond simple compaction.

**First-window bootstrapping**: Use the initial context window to establish infrastructure -- write tests, create setup scripts (e.g., `init.sh`), define a structured state format. Subsequent windows iterate on a todo-list rather than re-establishing the environment.

**Fresh start vs compaction**: Starting with a clean context window and pointing Claude at state files (`progress.txt`, `tests.json`, git logs) can outperform compaction, because Claude discovers state naturally and avoids carrying forward noise from earlier context. Be prescriptive about the fresh-start process: "Review progress.txt, tests.json, and the git logs."

**Verification without human feedback**: As autonomous task length grows, Claude needs tools to verify its own correctness. Playwright MCP for UI testing, test suites, linters, and type checkers serve as "verification oracles" that substitute for human review.

**Context exhaustion**: Claude may prematurely wrap up work as it approaches context limits. Prompt it to persist: "Your context window will be automatically compacted. Do not stop tasks early due to token budget concerns. Save progress to memory before the context window refreshes." [Source: prompting-best-practice.md]

---

## Quick Reference

### Technique Hierarchy (try in this order)
1. Be clear and direct
2. Use examples (multishot, 3-5 diverse)
3. Let Claude think (chain of thought / extended thinking)
4. Use XML tags for structure
5. Give Claude a role (system prompts)
6. Chain complex prompts
7. Long context tips

### Adaptive Thinking API Migration
```python
# Before (extended thinking)
thinking={"type": "enabled", "budget_tokens": 32000}

# After (adaptive thinking)
thinking={"type": "adaptive"}
output_config={"effort": "high"}  # low, medium, high, max
```

### Key Prompt Snippets

**Prevent premature stopping:**
"Do not stop tasks early due to token budget concerns. Save your current progress and state to memory before the context window refreshes."

**Steer action vs suggestion:**
"By default, implement changes rather than only suggesting them. If the user's intent is unclear, infer the most useful likely action and proceed."

**Control overthinking:**
"Choose an approach and commit to it. Avoid revisiting decisions unless you encounter new information that directly contradicts your reasoning."

**Minimize hallucinations:**
"Never speculate about code you have not opened. Read relevant files BEFORE answering questions about the codebase."

**Calibrate subagent usage:**
"Use subagents when tasks can run in parallel or require isolated context. For simple tasks, single-file edits, or tasks needing shared context, work directly."

**Reduce overengineering:**
"Only make changes that are directly requested or clearly necessary. Keep solutions simple and focused."

### Prefill Migration (Opus 4.6)

Prefilled responses on the last assistant turn are no longer supported. Alternatives:
- **Format control**: Use Structured Outputs or direct instructions
- **Skip preamble**: "Respond directly without preamble"
- **Avoid refusals**: Clear prompting is now sufficient
- **Continuations**: "Your previous response was interrupted and ended with [text]. Continue from where you left off."
- **Context hydration**: Inject reminders in user turns or via tools

---

## Sources

1. **Prompt Engineering Overview** - Anthropic documentation
   - Technique hierarchy and ordered troubleshooting approach

2. **Multishot Prompting** - Anthropic documentation
   - Few-shot example strategies for structured output consistency

3. **Extended Thinking Tips** - Anthropic documentation
   - Strategies for extended thinking mode: budgets, general-vs-specific instructions, debugging

4. **Prompting Best Practices** - Anthropic documentation
   - Comprehensive guide for Claude 4.6/4.5 models: explicitness, tools, state, formatting, autonomy, subagents, migration
