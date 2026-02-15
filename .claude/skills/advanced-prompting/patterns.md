# Advanced Prompting - Patterns & Anti-Patterns

Reusable prompting patterns and common pitfalls, synthesized from Anthropic documentation.

---

## Table of Contents

- [Patterns](#patterns) - 8 reusable patterns with when/why/how guidance
- [Anti-Patterns](#anti-patterns) - 6 documented pitfalls to avoid

---

## Patterns

### 1. Context-Before-Rule

**When:** Any instruction that could seem arbitrary without motivation.

**Why:** Claude generalizes from understanding the reason behind a rule, handling novel cases the rule itself does not cover. Rules constrain; context enables.

**How:** Provide the motivation BEFORE or alongside the instruction. State why the behavior matters, then state the behavior.

**Example from Source 4 (prompting-best-practice.md):**
```text
# Less effective (rule only)
NEVER use ellipses

# More effective (context + rule)
Your response will be read aloud by a text-to-speech engine,
so never use ellipses since the text-to-speech engine will not
know how to pronounce them.
```

### 2. Quality Modifier Escalation

**When:** Claude produces minimal or basic output and you want comprehensive results.

**Why:** Claude's precise instruction following means it will not exceed what is asked. Vague prompts produce vague outputs. Explicit quality modifiers unlock effort.

**How:** Append modifiers that request depth, breadth, or thoroughness. Phrases like "Go beyond the basics," "Include as many relevant features as possible," and "Create a fully-featured implementation" shift Claude from minimal compliance to ambitious execution.

**Example from Source 4 (prompting-best-practice.md):**
```text
# Minimal output
Create an analytics dashboard

# Comprehensive output
Create an analytics dashboard. Include as many relevant features
and interactions as possible. Go beyond the basics to create a
fully-featured implementation.
```

### 3. Generalize-Then-Specialize (Thinking Mode)

**When:** Using extended or adaptive thinking on complex tasks.

**Why:** Claude's creative problem-solving approach often exceeds a human's ability to prescribe the optimal reasoning path. Over-specifying thinking steps can constrain rather than help. Starting general gives Claude room to find its own approach, and you can add specificity by reviewing thinking output.

**How:**
1. Start with high-level instructions: "Think about this problem thoroughly and in great detail."
2. Review Claude's thinking output.
3. Add targeted steering only where thinking went off-track.
4. Iterate.

**Example from Source 3 (extended-thinking-tips.md):**
```text
# Over-specified (constrains thinking)
Think through this step by step:
1. First, identify the variables
2. Then, set up the equation
3. Next, solve for x

# Generalized (lets Claude find optimal approach)
Please think about this math problem thoroughly and in great detail.
Consider multiple approaches and show your complete reasoning.
Try different methods if your first approach doesn't work.
```

### 4. Self-Verification Gate

**When:** Tasks where correctness matters and Claude cannot rely on external tool feedback.

**Why:** Asking Claude to verify its own work before declaring completion catches errors that would otherwise require another round-trip. Extended thinking amplifies this pattern because verification reasoning happens in the thinking block.

**How:** Add explicit verification instructions at the end of the task prompt. Specify test cases, edge conditions, or validation criteria Claude should check before finishing.

**Example from Source 3 (extended-thinking-tips.md):**
```text
Write a function to calculate the factorial of a number.
Before you finish, please verify your solution with test cases for:
- n=0
- n=1
- n=5
- n=10
And fix any issues you find.
```

### 5. Reversibility-Based Autonomy Boundary

**When:** Building agentic systems where Claude acts autonomously.

**Why:** Claude Opus 4.6 is proactive by default and will take destructive actions without prompting. Rather than listing every prohibited action, the reversibility heuristic provides a generalizable decision boundary that scales to novel situations.

**How:** Frame the boundary in terms of reversibility and impact scope. Local, reversible actions proceed autonomously; irreversible or shared-system actions require confirmation. Provide concrete examples of each category.

**Example from Source 4 (prompting-best-practice.md):**
```text
Consider the reversibility and potential impact of your actions.
You are encouraged to take local, reversible actions like editing
files or running tests, but for actions that are hard to reverse,
affect shared systems, or could be destructive, ask the user
before proceeding.
```

### 6. Structured Research with Hypothesis Tracking

**When:** Complex information gathering tasks across large codebases or corpora.

**Why:** Unstructured research leads to Claude gathering context indefinitely without converging. Hypothesis tracking creates an explicit convergence mechanism and makes research progress visible.

**How:** Ask Claude to develop competing hypotheses, track confidence levels, regularly self-critique, and persist findings in a structured format.

**Example from Source 4 (prompting-best-practice.md):**
```text
Search for this information in a structured way. As you gather
data, develop several competing hypotheses. Track your confidence
levels in your progress notes to improve calibration. Regularly
self-critique your approach and plan. Update a hypothesis tree
or research notes file to persist information and provide
transparency.
```

### 7. Positive-Frame Format Steering

**When:** Controlling Claude's output format (prose vs markdown, list vs paragraph, etc.).

**Why:** Negative instructions ("Do not use markdown") are less effective than positive instructions describing the desired format. Claude responds more reliably to "write flowing prose" than to "avoid bullet points."

**How:**
1. Describe the desired format positively.
2. Optionally use XML tags as format indicators.
3. Match your prompt's own formatting to the desired output style.

**Example from Source 4 (prompting-best-practice.md):**
```text
# Less effective (negative framing)
Do not use markdown in your response

# More effective (positive framing)
Your response should be composed of smoothly flowing prose paragraphs.

# Also effective (XML format indicator)
Write the prose sections of your response in
<smoothly_flowing_prose_paragraphs> tags.
```

### 8. First-Window Bootstrap

**When:** Long-horizon tasks that will span multiple context windows.

**Why:** Using the first context window to establish infrastructure (tests, scripts, state formats) creates durable scaffolding that subsequent windows inherit. This amortizes setup cost and provides verification mechanisms for later sessions.

**How:**
1. First window: Write tests in structured format (e.g., `tests.json`), create setup scripts (`init.sh`), establish state tracking.
2. Subsequent windows: Start fresh (not compacted), review state files and git logs, run integration tests before continuing.
3. Each window: Save progress before context exhaustion.

**Example from Source 4 (prompting-best-practice.md):**
```text
# Starting a fresh context window after bootstrapping
Call pwd; you can only read and write files in this directory.
Review progress.txt, tests.json, and the git logs.
Manually run through a fundamental integration test before
moving on to implementing new features.
```

---

## Anti-Patterns

### 1. Aggressive Emphasis for Tool Triggering

**Problem:** Prompts use "CRITICAL:", "You MUST", "ALWAYS", or all-caps to force tool usage, inherited from prompts designed for older models.

**Why it fails:** Opus 4.6 and Sonnet 4.5 are significantly more responsive to system prompt instructions than predecessors. Language that compensated for undertriggering in older models now causes overtriggering -- Claude uses tools when they are not needed, inflating latency and cost.

**Better alternative:** Use natural language. Replace "CRITICAL: You MUST use this tool when..." with "Use this tool when..." Let the model's improved instruction following do the work. [Source: prompting-best-practice.md]

### 2. Prescriptive Thinking Steps

**Problem:** Providing step-by-step reasoning instructions when extended thinking is enabled, e.g., "Step 1: Identify variables. Step 2: Set up the equation."

**Why it fails:** Claude's creative approach to complex problems often exceeds what a human can prescribe. Overly prescriptive steps constrain the model's reasoning space. Note: Claude CAN follow complex structured steps effectively when needed -- the issue is making this the default rather than a fallback for troubleshooting.

**Better alternative:** Start with generalized instructions ("Think about this thoroughly, consider multiple approaches"). Review thinking output. Add specific steering only where Claude's reasoning went off-track. [Source: extended-thinking-tips.md]

### 3. Feeding Back Thinking Output

**Problem:** Passing Claude's extended thinking text back to it in subsequent user messages to "maintain context."

**Why it fails:** This does not improve performance and may actually degrade results. The thinking output is a byproduct of Claude's internal reasoning, not a format designed for re-ingestion.

**Better alternative:** Let thinking happen naturally within the model. If you need to persist state across turns, use structured state files or progress notes rather than thinking transcripts. [Source: extended-thinking-tips.md]

### 4. Blanket Tool Defaults

**Problem:** Instructions like "Default to using [tool]" or "If in doubt, use [tool]" designed to ensure Claude uses available tools.

**Why it fails:** Latest models trigger tools appropriately without encouragement. Blanket defaults cause excessive tool usage, including spawning subagents for tasks where a single grep would suffice.

**Better alternative:** Use targeted guidance: "Use [tool] when it would enhance your understanding of the problem." If overtriggering persists, lower the `effort` parameter. [Source: prompting-best-practice.md]

### 5. Ambiguous Action Phrasing

**Problem:** Using phrases like "Can you suggest some changes?" or "What do you think about improving this?" when you want Claude to actually make the changes.

**Why it fails:** Claude's precise instruction following means it takes these phrases literally as requests for suggestions or opinions, not as commands to act. It will provide text recommendations without touching any files.

**Better alternative:** Use imperative phrasing: "Change this function to improve its performance." "Make these edits to the authentication flow." If you want Claude to default to action, add system-level guidance: "By default, implement changes rather than only suggesting them." [Source: prompting-best-practice.md]

### 6. Pushing Token Output for Its Own Sake

**Problem:** Increasing thinking budget or requesting longer outputs without a quality-driven reason, under the assumption that more tokens equals better results.

**Why it fails:** More thinking tokens do not linearly improve quality. Anthropic explicitly recommends starting with the minimum thinking budget (1024 tokens) and increasing only as needed. Excessive budgets waste compute and can introduce noise into reasoning.

**Better alternative:** Start small. Increase thinking budget incrementally based on observed quality improvements. For long outputs, use structural scaffolding (detailed outlines with word counts per section) rather than raw budget increases. [Source: extended-thinking-tips.md]
