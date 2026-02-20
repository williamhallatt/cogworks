# Codex Prompt Engineering Reference

## TL;DR

Codex/GPT prompt engineering for interactive and autonomous coding tasks requires calibrating reasoning effort ("medium" for interactive coding, "high" or "xhigh" for autonomous multi-hour tasks, "low" or "none" for speed-sensitive operations), embracing agentic autonomy through the "discerning engineer" pattern (gather context → plan → implement → test → refine without waiting for intermediate approvals), and implementing canonical tool architectures (apply_patch with context-free grammar for code changes, shell_command with string-type commands, update_plan for task management). Effective prompting includes user preambles every 6-8 tool calls (1-2 sentences summarizing progress), output compactness rules (2-5 sentences for tiny changes, ≤6 bullets for medium), and parallel tool calling via multi_tool_use.parallel for batching file reads and searches. The evaluation flywheel provides systematic resilience building: analyze failures through open/axial coding, measure with automated graders, improve with targeted changes, then repeat. Context compaction via /compact endpoint enables multi-hour agent trajectories by retaining key prior state with fewer tokens. Security essentials focus on input validation at system boundaries and prompt injection basics for production deployments. Universal PE fundamentals (few-shot, CoT, in-context learning) integrate with GPT-specific features like reasoning effort parameters and tool architectures, contrasting with Claude's adaptive thinking and subagent orchestration patterns.

---

## Core Concepts

### 1. Reasoning Effort Calibration

**Definition**: Selection of reasoning depth for gpt-5.1 and gpt-5.2 models using effort parameters: none, low, medium, high, xhigh.

**Key Guidelines**:
- **Interactive coding**: "medium" (default recommendation)
- **Autonomous multi-hour tasks**: "high" or "xhigh"
- **Speed-sensitive operations**: "low" or "none"
- **Simple retrieval/formatting**: omit reasoning parameter or use "none"

**Platform Evolution**: gpt-5.2-codex uses fewer thinking tokens than predecessors, making "medium" more efficient for typical interactive coding.

**Contrast with Claude**: GPT's explicit effort levels differ from Claude Opus 4.6's adaptive thinking (which adjusts dynamically) and Claude Sonnet 4.5's extended thinking (which uses fixed token budgets).

**Sources**: [Source 1], [Source 2], [Source 10] (Claude contrast)

---

### 2. Agentic Autonomy

**Definition**: The "discerning engineer" pattern where the model operates autonomously through gather→plan→implement→test→refine cycles without waiting for intermediate approvals.

**Core Behaviors**:
- Gather sufficient context before starting implementation
- Create lightweight plans (2-5 milestone items, not micro-steps)
- Implement end-to-end without stopping for "what next?" questions
- Test implementations and iterate on failures
- Persist until tasks are fully handled

**Autonomy Calibration**:
- **High autonomy**: Appropriate for clearly defined tasks, test environments, version-controlled code
- **Moderate autonomy**: Request confirmation before production deployments, destructive operations
- **Low autonomy**: Present options when multiple valid approaches exist

**When to Wait**:
- Ambiguous requirements requiring clarification
- Architectural decisions with significant trade-offs
- Destructive operations (rm, DROP TABLE, force push to main)

**Sources**: [Source 1], [Source 2], [Source 4]

---

### 3. Tool Use Architecture

**Definition**: Canonical implementations of core tools for code manipulation, shell execution, and task tracking.

**apply_patch Tool**:
- Creates, updates, and deletes files using structured diffs
- Context-free grammar approach preferred over search/replace
- Returns execution results with "completed" or "failed" status
- Canonical implementation in OpenAI cookbook

**shell_command Tool**:
- String-type commands perform better than command arrays
- Supports working directory specification
- Configurable timeout parameters
- Default shell tool recommendation

**update_plan Tool**:
- Task management with statuses: pending, in_progress, completed
- Keeps one item in_progress at a time
- Updates after significant milestones (never >8 tool calls without update)
- Zero pending/in_progress items before turn completion

**Tool Selection Principle**: Prefer dedicated tools over shell commands when available (e.g., use apply_patch instead of shell sed/awk).

**Sources**: [Source 1], [Source 4]

---

### 4. Preamble Design

**Definition**: User-facing progress updates (also called "preambles") provided by the model during long-running tasks.

**Four Configuration Axes**:

**Frequency**: 1-2 sentence updates every 6-8 tool calls maximum

**Content**:
- Meaningful discoveries during exploration
- Concrete outcomes from completed actions
- Plan changes or approach pivots
- Status checklist before completion

**Structure**:
- Initial plan upfront
- Exploration updates mid-task
- Recap with status before completion

**Immediacy**: Explain actions BEFORE deep analysis to improve perceived latency

**Anti-Pattern**: Removing preamble prompting entirely may cause premature termination in gpt-5.2-codex.

**Sources**: [Source 2], [Source 1]

---

### 5. Output Compactness

**Definition**: Deliberate response length control to match change size and avoid overwhelming users.

**Compactness Rules by Change Size**:

**Tiny changes** (≤10 lines):
- 2-5 sentences maximum
- Brief explanation of what changed and why

**Medium changes**:
- ≤6 bullets or 6-10 sentences
- File-level summaries, not line-by-line narration

**Large changes**:
- Summarize per file
- Avoid large code blocks (users can see diffs)
- Focus on architectural decisions and rationale

**Scope Discipline**: For frontend/design tasks, explicitly forbid extra features: "No extra features, no added components, no UX embellishments."

**Long-Context Handling**: For documents >10k tokens, produce internal outlines and re-state constraints before answering to reduce "lost in the scroll" errors.

**Sources**: [Source 2], [Source 3]

---

### 6. Parallel Tool Calling

**Definition**: Batching independent tool invocations using multi_tool_use.parallel to maximize efficiency.

**Enabled Patterns**:
- Batch file reads together
- Parallelize semantic/code searches
- Group independent operations in single API call

**Configuration**: Enable parallel tool calling in API requests for automatic batching.

**Prompt Guidance**: "Batch reads and edits to speed up the process" encourages parallelization.

**Efficiency Gains**: Reduces latency by executing independent operations concurrently rather than sequentially.

**When NOT to Parallelize**: Operations with dependencies where one output informs the next input.

**Sources**: [Source 1], [Source 2]

---

### 7. Evaluation Flywheel

**Definition**: Systematic methodology for building prompt resilience through continuous analyze→measure→improve cycles.

**Three Phases**:

**Analyze (Qualitative)**:
- **Open Coding**: Manually review ~50 failing traces, apply descriptive labels without perfection pressure
- **Axial Coding**: Group labels into higher-level categories to build structured understanding
- Outcome: Taxonomy of failure modes revealing where to focus improvement

**Measure (Quantitative)**:
- Create test datasets covering key dimensions (channel, intent, persona)
- Implement automated graders (Python-based and LLM-based)
- Track baseline performance metrics (formatting accuracy, ground truth alignment)
- Establish True Positive Rate and True Negative Rate for LLM judges

**Improve (Iterative)**:
- Make targeted changes (rewrite prompts, add examples, adjust components)
- Immediately measure impact through graders
- Iterate until metrics improve
- Integrate graders into CI/CD pipelines

**LLM Judge Alignment**:
- Train set (~20%): Few-shot examples for the judge
- Validation set (~40%): Iterative improvement
- Test set (~40%): Final held-out evaluation

**Sources**: [Source 3], [Source 6]

---

### 8. Context Compaction

**Definition**: First-class compaction support via /compact endpoint enabling multi-hour agent trajectories without context window degradation.

**Key Benefits**:
- Multi-turn conversations exceeding typical context limits
- Long-running agent trajectories (multiple hours)
- Retention of key prior state with fewer tokens

**When to Use**:
- Autonomous tasks expected to exceed single context window
- Multi-hour coding sessions
- Complex refactoring spanning many files

**Integration Pattern**: Responses API provides compaction automatically; prompt the model not to stop tasks early due to token budget concerns.

**Contrast with Claude**: Claude Code uses automatic context compaction through summarization; GPT provides explicit /compact endpoint for controlled compaction.

**Sources**: [Source 1], [Source 10] (Claude contrast)

---

### 9. Security Essentials

**Definition**: Core security controls for production deployments focusing on input validation and prompt injection prevention.

**Input Validation at System Boundaries**:
- Validate format, length, and content at user input layer
- Sanitize suspicious patterns before sending to LLM
- Use parameterization for API/database integrations

**Prompt Injection Basics**:
- Direct injection: User inputs override system instructions
- Indirect injection: Malicious payloads in consumed data (web pages, documents)
- Mitigation: Input filtering, delimiters, least privilege access

**When to Prioritize Security**:
- Production deployments with untrusted users
- Systems with sensitive data access
- Multi-tenant applications
- Public-facing chatbots

**When Security is Lower Priority**:
- Internal development tools
- Single-user personal assistants
- Sandboxed test environments

**Defense-in-Depth**: Layer multiple controls (input validation + architectural separation + output filtering) rather than relying on single control.

**Sources**: [Source 7], [Source 8], [Source 9]

---

### 10. Universal PE Fundamentals (Contextualized)

**Definition**: Core prompt engineering techniques adapted for GPT-specific features and tool architectures.

**Few-Shot Prompting**:
- Provide 3-5 diverse examples demonstrating desired behavior
- Structure examples with clear input/output pairs
- Include edge cases in examples
- GPT-specific: Show tool calling patterns in examples

**Chain-of-Thought**:
- Encourage step-by-step reasoning for complex tasks
- GPT-specific: Integrated with reasoning effort parameters
- Higher effort levels naturally produce more detailed reasoning

**In-Context Learning**:
- Leverage context window for task adaptation
- Provide examples and relevant documentation in prompt
- GPT-specific: Works within context limits (compaction extends for longer tasks)

**Prompt Optimization**:
- Define success criteria empirically
- Test against diverse inputs
- Iterate based on failure analysis (use evaluation flywheel)
- Track metrics over time

**Sources**: [Source 5], [Source 6], [Source 9]

---

## Concept Map

### Hierarchical Relationships
1. **Agentic Autonomy** implements **Reasoning Effort** selection (autonomy level determines effort)
2. **Evaluation Flywheel** contains **Analyze**, **Measure**, **Improve** phases (composition)
3. **Tool Use Architecture** includes **apply_patch**, **shell_command**, **update_plan** (specialization)

### Dependencies
4. **Parallel Tool Calling** requires tool architecture support (multi_tool_use.parallel)
5. **Context Compaction** enables long **Agentic Autonomy** cycles
6. **Preamble Design** depends on **Agentic Autonomy** pattern (updates during autonomous work)
7. **Output Compactness** pairs with **Preamble Design** (consistent communication style)

### Contrasts
8. **Reasoning Effort** (GPT explicit levels) vs **Adaptive Thinking** (Claude dynamic adjustment)
9. **Context Compaction** (/compact endpoint) vs **Automatic Summarization** (Claude behavior)
10. **Tool Architecture** (canonical implementations) vs **Subagent Orchestration** (Claude delegation patterns)

### Sequences
11. **Evaluation Flywheel**: Analyze → Measure → Improve → Repeat (iterative cycle)
12. **Agentic Autonomy**: Gather → Plan → Implement → Test → Refine (workflow sequence)

### Compositions
13. **Effective Prompting** = **Reasoning Effort** + **Agentic Autonomy** + **Tool Architecture** + **Output Compactness**
14. **Production Readiness** = **Evaluation Flywheel** + **Security Essentials** + **Context Compaction**

---

## Deep Dives

### Deep Dive 1: Reasoning Effort Calibration

**Overview**: GPT-5.1 and 5.2 models expose explicit reasoning effort parameters allowing fine-grained control over computational depth. Proper calibration balances quality, latency, and cost.

**Effort Level Semantics**:

**none**: Zero reasoning overhead, fastest responses
- Use for: Simple formatting, retrieval, template filling
- Equivalent to: GPT-4.1 behavior
- Latency: Minimal
- Quality: Suitable only for straightforward tasks

**low**: Minimal reasoning, quick responses
- Use for: Basic code completion, simple queries
- Latency: Low
- Quality: Adequate for well-defined simple tasks

**medium** (recommended default for interactive coding):
- Use for: Interactive coding, debugging, moderate complexity tasks
- Latency: Moderate
- Quality: Balanced intelligence and efficiency
- Note: gpt-5.2-codex optimized to use fewer thinking tokens at this level

**high**: Extended reasoning for complex problems
- Use for: Autonomous multi-step tasks, architectural design, complex debugging
- Latency: Higher
- Quality: Significantly improved for challenging tasks

**xhigh**: Maximum reasoning depth
- Use for: Multi-hour autonomous agents, research tasks, constraint optimization
- Latency: Highest
- Quality: Best for extremely complex reasoning

**Migration Guidance from Prior Models**:
- GPT-4o/4.1 → gpt-5.2 with `reasoning_effort: none`
- GPT-5 → gpt-5.2 preserving existing effort levels (except `minimal` → `none`)

**Configuration Example**:
```python
response = client.responses.create(
    model="gpt-5.2-codex",
    reasoning_effort="medium",  # Interactive coding default
    messages=[...]
)
```

**Debugging Strategy**: If quality is insufficient, increment effort level and re-test. If latency is too high, decrement effort level and assess quality trade-off.

**Contrast with Claude**:
- GPT: Explicit 5-level effort parameter set per request
- Claude Opus 4.6: Adaptive thinking adjusts dynamically based on task complexity
- Claude Sonnet 4.5: Extended thinking uses fixed token budgets (minimum 1024)

**Sources**: [Source 1], [Source 2], [Source 10]

---

### Deep Dive 2: Canonical Tool Implementations

**Overview**: Tool architecture significantly impacts agent reliability and efficiency. Codex models work best with specific tool patterns validated through production use.

**apply_patch Tool Deep Dive**:

**Purpose**: Create, update, and delete files using structured diffs

**Context-Free Grammar Approach**:
```
operation: create | update | delete
file_path: absolute or relative path
diff: structured representation of changes
```

**Why Context-Free Grammar Beats Search/Replace**:
- No ambiguity from multiple matches
- Handles creation and deletion uniformly
- Clearer error messages when patches fail
- Scales to large files without loading entire content

**Response API Integration**:
```python
response = client.responses.create(
    model="gpt-5.2-codex",
    tools=[{"type": "apply_patch"}],
    messages=[...]
)

# Model returns apply_patch_call with operation and diff
# Return execution results:
{
    "type": "apply_patch_call_output",
    "call_id": call["call_id"],
    "status": "completed",  # or "failed"
    "output": log_output
}
```

**shell_command Tool Deep Dive**:

**String vs Array Commands**:
- **String type** (recommended): `"ls -la /tmp"`
- **Array type**: `["ls", "-la", "/tmp"]`
- Performance: String commands perform better in practice

**Configuration Parameters**:
- `working_directory`: Execute command in specified directory
- `timeout`: Maximum execution time in seconds
- `max_output_length`: Truncate long outputs

**Best Practices**:
- Prefer dedicated tools over shell when available (use apply_patch instead of `sed`)
- Quote paths with spaces properly
- Set reasonable timeouts (avoid indefinite hanging)

**update_plan Tool Deep Dive**:

**Task Management Pattern**:
```json
{
    "tasks": [
        {"id": 1, "description": "Implement auth", "status": "completed"},
        {"id": 2, "description": "Add tests", "status": "in_progress"},
        {"id": 3, "description": "Deploy", "status": "pending"}
    ]
}
```

**Status Workflow**:
- `pending`: Not yet started
- `in_progress`: Currently working (only one task should have this status)
- `completed`: Finished successfully

**Update Frequency**: After every significant milestone, never >8 tool calls without update.

**Completion Criteria**: Zero pending/in_progress items before declaring task complete.

**Sources**: [Source 1], [Source 4]

---

### Deep Dive 3: Evaluation Flywheel Methodology

**Overview**: Building resilient prompts requires systematic evaluation beyond manual testing. The evaluation flywheel provides a structured approach to identifying, measuring, and fixing failure modes.

**Phase 1: Analyze (Qualitative)**

**Open Coding Process**:
1. Collect ~50 failing traces from production or test datasets
2. Read through each trace manually
3. Apply descriptive labels without worrying about taxonomy perfection
4. Examples of good labels:
   - "bot suggested unavailable tour time"
   - "output formatting incorrect (missing JSON brackets)"
   - "hallucinated product feature not in docs"

**Axial Coding Process**:
1. Group initial labels into higher-level categories
2. Build structured taxonomy:
   - **Scheduling Issues**: Timing conflicts, availability errors
   - **Formatting Problems**: JSON structure, markdown issues
   - **Factual Errors**: Hallucinations, outdated information
3. Quantify category frequency
4. Identify top 3-5 categories for focused improvement

**Phase 2: Measure (Quantitative)**

**Test Dataset Creation**:
- Cover key dimensions systematically (not randomly):
  - Channel: Web, mobile, API
  - Intent: Purchase, support, research
  - Persona: New user, power user, enterprise
- Target: 100-500 test cases depending on complexity
- Include edge cases explicitly

**Automated Grader Types**:

**Python-based graders**:
```python
def format_grader(output: str) -> dict:
    """Check if output is valid JSON with required fields."""
    try:
        data = json.loads(output)
        required = ["status", "result", "metadata"]
        missing = [f for f in required if f not in data]
        return {
            "pass": len(missing) == 0,
            "score": 1.0 - (len(missing) / len(required)),
            "details": f"Missing fields: {missing}" if missing else "OK"
        }
    except json.JSONDecodeError as e:
        return {"pass": False, "score": 0.0, "details": str(e)}
```

**LLM-based graders**:
```python
def accuracy_grader(output: str, ground_truth: str) -> dict:
    """Use LLM to judge semantic correctness."""
    judge_prompt = f"""
    Compare the model output against ground truth.
    Output: {output}
    Ground Truth: {ground_truth}

    Does the output match ground truth semantically? Answer YES or NO with brief justification.
    """
    judgment = llm.generate(judge_prompt)
    return parse_judgment(judgment)
```

**LLM Judge Calibration**:
1. **Train set (20%)**: Provide as few-shot examples to judge
2. **Validation set (40%)**: Iterate judge prompt until TPR/TNR targets met
3. **Test set (40%)**: Final held-out evaluation
4. Target metrics: TPR >0.9, TNR >0.9

**Phase 3: Improve (Iterative)**

**Targeted Changes**:
- Rewrite ambiguous instructions
- Add few-shot examples covering failure modes
- Adjust tool descriptions or constraints
- Modify output formatting requirements

**Immediate Measurement**:
- Run full test suite after each change
- Track delta in pass rate and score
- Iterate if improvement insufficient

**CI/CD Integration**:
```bash
# In .github/workflows/eval.yml
- name: Run Evaluation Suite
  run: |
    python eval_runner.py --test-set production_cases.json --grader all
    if [ $PASS_RATE -lt 0.85 ]; then exit 1; fi
```

**Continuous Monitoring**: Evaluation flywheel operates ongoing, not one-time. Monitor production for emerging failure modes and add to test suite.

**Sources**: [Source 3], [Source 6]

---

### Deep Dive 4: Output Design and Compactness

**Overview**: Output design significantly impacts user experience in coding assistants. Codex models require explicit guidance on verbosity, structure, and style.

**Compactness by Change Size**:

**Tiny Changes (≤10 lines)**:
```
Bad (verbose):
I've updated the function to add error handling. Previously, the function
didn't check for null values, which could cause runtime errors. Now I've
added a check at the beginning of the function that returns early if the
input is null. Here's what changed:

[20 lines of explanation]

Good (compact):
Added null check to prevent runtime errors. Returns early if input is null.
```

**Medium Changes**:
```
Bad (line-by-line):
Line 1: Changed import statement
Line 5: Added type annotation
Line 12: Updated function signature
...

Good (file-level):
- auth.py: Added type annotations, updated login function signature
- tests.py: New test cases for edge conditions
- config.py: Increased timeout from 30s to 60s
```

**Large Changes**:
```
Bad (code dumps):
Here's the complete refactored file:
[500 lines of code]

Good (architectural summary):
Refactored authentication system into three modules:
- auth/core.py: Token generation and validation (150 lines)
- auth/middleware.py: Request interceptors (80 lines)
- auth/storage.py: Session persistence (120 lines)

Key changes: Switched from JWT to session-based auth for better
security in our multi-tenant environment. See commit abc123 for full diff.
```

**Scope Discipline**:

For frontend tasks, prevent feature creep:
```
System prompt addition:
"No extra features, no added components, no UX embellishments unless
explicitly requested. Implement exactly what was asked, nothing more."
```

**Long-Context Handling**:

For documents >10k tokens:
1. Produce internal outline before answering
2. Re-state key constraints from early in document
3. Reference specific sections by outline number

Example:
```
[After reading 50-page requirements doc]

Internal outline:
1. System architecture (pages 1-10)
2. API specifications (pages 11-30)
3. Security requirements (pages 31-40)
4. Deployment (pages 41-50)

[Now answer question with references:]
Per section 3.2 (page 35), authentication must use OAuth 2.0...
```

**Preamble Integration**:

Preambles and final outputs should maintain consistent style:
- Both use plain text with natural language headings
- Both reference files with inline code formatting
- Both maintain collaborative, concise, factual tone

**Sources**: [Source 1], [Source 2], [Source 3]

---

### Deep Dive 5: Context Compaction for Long-Running Agents

**Overview**: The /compact endpoint enables multi-hour agent trajectories by intelligently reducing context size while preserving task-critical information.

**How Compaction Works**:

**Automatic Trigger**: When conversation approaches context window limits

**Compaction Process**:
1. Identify task-critical information (current goals, architectural decisions, task status)
2. Summarize historical conversation turns
3. Preserve recent interactions in full
4. Generate compact representation

**Result**: Conversation continues seamlessly with reduced token count but preserved task context

**API Integration**:
```python
response = client.responses.create(
    model="gpt-5.2-codex",
    messages=conversation_history,
    # Compaction happens automatically when needed
)

# Explicit compaction via /compact endpoint:
compacted = client.responses.compact(
    conversation_id=conv_id,
    preserve_turns=10  # Keep last 10 turns in full
)
```

**Prompting for Compaction Awareness**:
```
Your context window will be automatically compacted as it approaches its
limit, allowing you to continue working indefinitely. Therefore:
- Do not stop tasks early due to token budget concerns
- Before compaction, save critical state (architecture decisions, task lists)
- Complete tasks fully even if context limit approaching
```

**State Preservation Strategies**:

**Structured Files**:
```json
// state.json - persists across compaction
{
    "project": "authentication-refactor",
    "completed": ["user-model", "login-endpoint"],
    "in_progress": "password-reset",
    "decisions": {
        "token_storage": "httpOnly-cookies",
        "session_duration": "24-hours"
    }
}
```

**Code Comments**:
```python
# Architecture Decision: Using Redis for session storage
# Rationale: Need distributed sessions for multi-instance deployment
# Decided: 2026-02-20 (context window 3)
class SessionStore:
    ...
```

**Git Commits**:
```bash
git commit -m "Window 1 complete: User model refactor [CHECKPOINT]"
# Commit messages serve as persistent state even after compaction
```

**Multi-Hour Task Patterns**:

**Window 1** (Initial setup):
- Write tests defining success criteria
- Create setup scripts (init.sh, run_tests.sh)
- Establish architecture and patterns

**Windows 2-N** (Implementation):
- Work through task list incrementally
- Update state.json after each milestone
- Create git checkpoints at natural breakpoints

**Final Window** (Completion):
- Integration tests
- Documentation updates
- Cleanup and final commit

**Contrast with Claude**:
- **GPT**: Explicit /compact endpoint, prompted awareness
- **Claude**: Automatic context compaction via summarization, memory tool integration

**Sources**: [Source 1], [Source 10]

---

## Quick Reference

### Reasoning Effort
1. **Interactive coding default**: "medium"
2. **Autonomous multi-hour tasks**: "high" or "xhigh"
3. **Speed-sensitive operations**: "low" or "none"
4. **Simple retrieval**: Omit reasoning parameter

### Agentic Autonomy
5. **Core pattern**: Gather → Plan → Implement → Test → Refine
6. **Assume "yes" answers**: Proceed autonomously unless explicitly told to wait
7. **Confirm before**: Destructive operations, production deployments, ambiguous requirements
8. **Lightweight plans**: 2-5 milestone items, not micro-steps

### Tool Architecture
9. **apply_patch**: Context-free grammar approach for all code changes
10. **shell_command**: String-type commands, specify working directory
11. **update_plan**: One in_progress item at a time, update every <8 tool calls
12. **Tool preference**: Use dedicated tools over shell when available

### Preambles & Output
13. **Preamble frequency**: Every 6-8 tool calls maximum
14. **Preamble length**: 1-2 sentences summarizing progress
15. **Tiny changes**: 2-5 sentences total output
16. **Medium changes**: ≤6 bullets or 6-10 sentences
17. **Large changes**: Summarize per file, avoid code dumps

### Parallel Tools
18. **Enable batching**: Set parallel tool calling in API configuration
19. **Batch pattern**: Read all potentially relevant files together
20. **When NOT to parallelize**: Operations with dependencies

### Evaluation
21. **Flywheel phases**: Analyze → Measure → Improve → Repeat
22. **Open coding**: Review ~50 failures, apply descriptive labels
23. **Axial coding**: Group labels into taxonomy of failure modes
24. **LLM judge split**: 20% train, 40% validation, 40% test

### Compaction
25. **Long tasks**: Use /compact endpoint for multi-hour agents
26. **State preservation**: Structured JSON + git commits + code comments
27. **Prompt awareness**: Tell model context will compact, don't stop early

### Security
28. **Input validation**: Check format, length, suspicious patterns at boundaries
29. **Prompt injection**: Filter "ignore all previous" patterns
30. **Production priority**: Layer multiple controls (defense-in-depth)

---

## Anti-Patterns

### 1. Over-Reasoning Simple Tasks
**Problem**: Using "high" or "xhigh" effort for straightforward operations
**Impact**: Unnecessary latency, wasted compute, no quality gain
**Fix**: Use "medium" for interactive coding, "low" or "none" for simple tasks

### 2. Waiting for Approval on Obvious Steps
**Problem**: Stopping to ask "Should I continue?" when next step is clear
**Impact**: Breaks agentic flow, frustrates users, requires excessive back-and-forth
**Fix**: Embrace "discerning engineer" pattern, proceed autonomously for non-destructive ops

### 3. Verbose Output for Small Changes
**Problem**: Writing paragraphs of explanation for 3-line code changes
**Impact**: User fatigue, reduced efficiency, obscures important information
**Fix**: 2-5 sentences maximum for tiny changes

### 4. Poor Tool Selection
**Problem**: Using shell commands when dedicated tools exist (shell sed instead of apply_patch)
**Impact**: Fragile implementations, harder to debug, less reliable
**Fix**: Prefer dedicated tools; reserve shell for operations without tool alternatives

### 5. No Evaluation Strategy
**Problem**: Deploying prompts without systematic testing or failure analysis
**Impact**: Silent regressions, edge case failures, unreliable behavior
**Fix**: Implement evaluation flywheel (analyze→measure→improve)

---

## Sources

> **Knowledge snapshot date:** 2026-02-20
>
> These sources were fetched and synthesized on the date shown above.
> Information may have changed since then.

**[Source 1]** gpt-5-1-prompting-guide.md - Migration guidance, agentic steerability, reasoning effort (none/low/medium/high), tool implementations (apply_patch, shell), preamble design, output compactness, metaprompting

**[Source 2]** gpt-5-2-prompting-guide.md - Behavioral differences from GPT-5, verbosity control, scope discipline, long-context handling, ambiguity mitigation, structured extraction, tool calling, compaction via /responses/compact

**[Source 3]** building-resilient-prompts-using-an-evaluation-flywheel.md - Evaluation flywheel framework (analyze→measure→improve), open/axial coding, automated graders (Python and LLM-based), synthetic data generation, LLM judge alignment, CI/CD integration

**[Source 4]** codex-prompting-guide.md - Codex-tuned model best practices, autonomy as "discerning engineer", code quality emphasis, tool implementations (apply_patch with CFG, shell_command, update_plan), compaction for long contexts, parallel tool calling, AGENTS.md discovery

**[Source 5]** prompt-engineering-techniques.md - Comprehensive taxonomy of PE techniques including zero-shot, few-shot, CoT, meta-prompting, self-consistency, tree of thoughts, ReAct

**[Source 6]** few-shot-prompting.md - Example-based learning with vector store retrieval, advantages (reduced data requirements), limitations (prompt quality dependency)

**[Source 7]** prompt-injection-overview.md - Attack mechanisms (direct vs indirect injection), risks (prompt leaks, RCE, data theft), OWASP #1 vulnerability ranking

**[Source 8]** prevent-prompt-injection.md - Mitigation strategies: input validation, structured queries, parameterization, delimiters, prompt strengthening, access controls, defense-in-depth

**[Source 9]** in-context-learning.md - Task adaptation via examples in prompts, Bayesian inference framework, optimization strategies (structured pretraining, demonstration selection)

**[Source 10]** extended-thinking-tips.md (Claude contrast) - Extended thinking mechanism with token budgets (min 1024), general vs prescriptive instructions, multishot prompting with thinking blocks

**[Source 11]** prompting-best-practice.md (Claude contrast) - Subagent orchestration patterns, context awareness, multi-window workflows, adaptive thinking integration

**[Source 12]** chain-of-thoughts.md - Step-by-step reasoning prompts, emergent ability scaling, variants (zero-shot, auto-CoT, multimodal)

**[Source 13]** prompt-optimization-overview.md - Iterative refinement strategies: templates, few-shot + CoT, metaprompting, evaluation cycles

**[Source 14]** react-prompting-tutorial.md - ReAct framework (Reasoning and Acting), thought→action→observation pattern, external tool integration

---

*This reference synthesizes 14 sources (4 Codex/GPT + 8 IBM + 2 Claude contrast) to provide comprehensive Codex/GPT prompt engineering guidance for gpt-5.1, gpt-5.2, and gpt-5.2-codex.*
