# Advanced Prompting - Practical Examples

Concrete prompt examples with before/after comparisons demonstrating key techniques.

---

## Table of Contents

- [Example 1](#example-1-multishot-for-structured-classification) - Multishot for structured classification
- [Example 2](#example-2-adaptive-thinking-migration) - Adaptive thinking migration
- [Example 3](#example-3-proactive-action-system-prompt) - Proactive action system prompt
- [Example 4](#example-4-conservative-action-system-prompt) - Conservative action system prompt
- [Example 5](#example-5-anti-overengineering-guardrails) - Anti-overengineering guardrails
- [Example 6](#example-6-context-window-persistence) - Context window persistence
- [Example 7](#example-7-parallel-tool-calling-optimization) - Parallel tool calling optimization
- [Example 8](#example-8-anti-hallucination-for-agentic-coding) - Anti-hallucination for agentic coding

---

## Example 1: Multishot for Structured Classification

Demonstrates how a single well-formatted example constrains Claude's output to match the desired structure, eliminating verbose explanations and enforcing multi-label categorization.

**Without example (verbose, single-label per entry):**
```text
Analyze this customer feedback and categorize the issues.
Use these categories: UI/UX, Performance, Feature Request,
Integration, Pricing, and Other. Also rate the sentiment
(Positive/Neutral/Negative) and priority (High/Medium/Low).

Here is the feedback: {{FEEDBACK}}
```

**With example (concise, multi-label):**
```text
Our CS team is overwhelmed with unstructured feedback.
Your task is to analyze feedback and categorize issues for
our product and engineering teams. Use these categories:
UI/UX, Performance, Feature Request, Integration, Pricing,
and Other. Also rate the sentiment (Positive/Neutral/Negative)
and priority (High/Medium/Low). Here is an example:

<example>
Input: The new dashboard is a mess! It takes forever to load,
and I can't find the export button. Fix this ASAP!
Category: UI/UX, Performance
Sentiment: Negative
Priority: High
</example>

Now, analyze this feedback: {{FEEDBACK}}
```

_Why this matters:_ The example shows Claude the exact output format (multi-label categories on one line, no explanations) and Claude replicates it precisely for all subsequent entries. [Source: multishot-prompting.md]

---

## Example 2: Adaptive Thinking Migration

Shows the API-level migration from manual extended thinking to adaptive thinking for Opus 4.6.

**Before (extended thinking, older models):**
```python
client.messages.create(
    model="claude-sonnet-4-5-20250929",
    max_tokens=64000,
    thinking={"type": "enabled", "budget_tokens": 32000},
    messages=[{"role": "user", "content": "..."}],
)
```

**After (adaptive thinking, Opus 4.6):**
```python
client.messages.create(
    model="claude-opus-4-6",
    max_tokens=64000,
    thinking={"type": "adaptive"},
    output_config={"effort": "high"},  # or max, medium, low
    messages=[{"role": "user", "content": "..."}],
)
```

_Why this matters:_ Adaptive thinking removes the burden of estimating token budgets. Claude decides when and how much to think based on query complexity and the effort parameter. Anthropic evaluations show adaptive thinking reliably outperforms manual budgets. [Source: prompting-best-practice.md]

---

## Example 3: Proactive Action System Prompt

System prompt snippet that makes Claude default to implementing changes rather than describing them. Useful for coding assistants and agentic workflows.

```text
<default_to_action>
By default, implement changes rather than only suggesting them.
If the user's intent is unclear, infer the most useful likely
action and proceed, using tools to discover any missing details
instead of guessing. Try to infer the user's intent about
whether a tool call (e.g., file edit or read) is intended or
not, and act accordingly.
</default_to_action>
```

_Why this matters:_ Claude's precise instruction following means it distinguishes between "suggest" and "do." Without this system-level default, users must phrase every request as an imperative command. [Source: prompting-best-practice.md]

---

## Example 4: Conservative Action System Prompt

The opposite of Example 3 -- system prompt that makes Claude default to research and recommendations rather than taking action. Useful for advisory or review contexts.

```text
<do_not_act_before_instructions>
Do not jump into implementation or change files unless clearly
instructed to make changes. When the user's intent is ambiguous,
default to providing information, doing research, and providing
recommendations rather than taking action. Only proceed with
edits, modifications, or implementations when the user
explicitly requests them.
</do_not_act_before_instructions>
```

_Why this matters:_ Demonstrates the bidirectional steerability of Claude's action bias. The proactive/conservative spectrum is a design decision, not a fixed behavior. [Source: prompting-best-practice.md]

---

## Example 5: Anti-Overengineering Guardrails

Comprehensive system prompt that constrains Claude's tendency to add unrequested abstractions, documentation, and defensive code.

```text
Avoid over-engineering. Only make changes that are directly
requested or clearly necessary. Keep solutions simple and focused:

- Scope: Don't add features, refactor code, or make
  "improvements" beyond what was asked. A bug fix doesn't need
  surrounding code cleaned up. A simple feature doesn't need
  extra configurability.

- Documentation: Don't add docstrings, comments, or type
  annotations to code you didn't change. Only add comments
  where the logic isn't self-evident.

- Defensive coding: Don't add error handling, fallbacks, or
  validation for scenarios that can't happen. Trust internal
  code and framework guarantees. Only validate at system
  boundaries (user input, external APIs).

- Abstractions: Don't create helpers, utilities, or
  abstractions for one-time operations. Don't design for
  hypothetical future requirements. The right amount of
  complexity is the minimum needed for the current task.
```

_Why this matters:_ Opus 4.5 and 4.6 have a documented tendency to overengineer. This prompt addresses four specific dimensions (scope, documentation, defensive coding, abstractions) rather than relying on a vague "keep it simple." [Source: prompting-best-practice.md]

---

## Example 6: Context Window Persistence

System prompt that prevents Claude from prematurely wrapping up work as context fills, combined with state management guidance.

```text
Your context window will be automatically compacted as it
approaches its limit, allowing you to continue working
indefinitely from where you left off. Therefore, do not stop
tasks early due to token budget concerns. As you approach your
token budget limit, save your current progress and state to
memory before the context window refreshes. Always be as
persistent and autonomous as possible and complete tasks fully,
even if the end of your budget is approaching. Never
artificially stop any task early regardless of the context
remaining.
```

Paired with structured state tracking:
```json
// tests.json - structured state
{
  "tests": [
    {"id": 1, "name": "authentication_flow", "status": "passing"},
    {"id": 2, "name": "user_management", "status": "failing"},
    {"id": 3, "name": "api_endpoints", "status": "not_started"}
  ],
  "total": 200,
  "passing": 150,
  "failing": 25,
  "not_started": 25
}
```

_Why this matters:_ Context awareness in Claude 4.5/4.6 lets the model track its remaining budget, but without this guidance it may conservatively wrap up early. Structured state files provide durable checkpoints that survive context resets. [Source: prompting-best-practice.md]

---

## Example 7: Parallel Tool Calling Optimization

System prompt that maximizes Claude's parallel tool execution while maintaining correctness for dependent operations.

```text
<use_parallel_tool_calls>
If you intend to call multiple tools and there are no
dependencies between the tool calls, make all of the
independent tool calls in parallel. Prioritize calling tools
simultaneously whenever the actions can be done in parallel
rather than sequentially. For example, when reading 3 files,
run 3 tool calls in parallel to read all 3 files into context
at the same time. Maximize use of parallel tool calls where
possible to increase speed and efficiency. However, if some
tool calls depend on previous calls to inform dependent values
like the parameters, do NOT call these tools in parallel and
instead call them sequentially. Never use placeholders or
guess missing parameters in tool calls.
</use_parallel_tool_calls>
```

_Why this matters:_ Claude's latest models naturally parallelize tool calls but are not 100% consistent. This prompt pushes consistency to near-100% while maintaining the critical guard against parallelizing dependent operations. [Source: prompting-best-practice.md]

---

## Example 8: Anti-Hallucination for Agentic Coding

System prompt that forces Claude to investigate before making claims, preventing speculative answers about code it has not read.

```text
<investigate_before_answering>
Never speculate about code you have not opened. If the user
references a specific file, you MUST read the file before
answering. Make sure to investigate and read relevant files
BEFORE answering questions about the codebase. Never make any
claims about code before investigating unless you are certain
of the correct answer - give grounded and hallucination-free
answers.
</investigate_before_answering>
```

_Why this matters:_ Even though Claude's latest models are less hallucination-prone, agentic coding workflows where Claude has tool access should still enforce an "investigate first" discipline. This converts potential hallucinations into tool calls, trading latency for accuracy. [Source: prompting-best-practice.md]
