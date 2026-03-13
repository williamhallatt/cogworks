---
name: product-gaps-cogworks
description: Product gaps in cogworks pipeline identified through agent skills synthesis—what's missing, why it matters, and what done looks like for roadmap prioritization
last_reviewed: "2026-03-13"
staleness_note: "Several gaps partially addressed by D-030 through D-042 and new test layers. Status annotations added 2026-03-13."
---

# Product Gaps in Cogworks Pipeline

This skill encodes the 10 gaps and 5 priority recommendations from Kane's agent skills synthesis (2026-03-05). Use this for roadmap planning, backlog grooming, and product coherence review.

> **Staleness note (2026-03-13):** Gaps 1, 2, 6, 7, and 9 have been partially addressed by decisions D-030 through D-042 and the expanded testing framework. Status annotations added inline below.

---

## Gap 1: No Activation Testing for Generated Skills

> **Status (2026-03-13):** PARTIALLY ADDRESSED. Layer 2 trigger smoke tests validate activation keyword parsing. Layer 5a has 47 behavioral test cases including explicit/implicit/negative activation scenarios. Full CI gate not yet wired.

**What's missing:**
- Test cases confirming skill triggers when it should
- Test cases confirming skill doesn't trigger when it shouldn't  
- Validation that `description` field aligns with intended activation scenarios

**Why it matters:**
Skills with excellent content but poor `description` fields may never be discovered by agents. Activation precision is a core quality dimension—a skill that never triggers is useless.

**Source:** Skill quality guidance (testability criterion), Claude Code skills docs (description is critical for auto-invocation discovery).

**What done looks like:**
- Behavioral eval extended with activation test suite
- Each generated skill has 2-4 activation test cases (positive and negative scenarios)
- CI gate blocks deployment if activation tests fail

---

## Gap 2: No Cross-Agent Compatibility Validation

> **Status (2026-03-13):** PARTIALLY ADDRESSED. D-039 made platform boundaries explicit (Claude ✅, Copilot ✅, Codex portable-only). Copilot adapter exists. Live cross-platform testing still limited.

**What's missing:**
- Testing of generated skills across Claude Code, GitHub Copilot, Cursor, Codex
- Validation that `$ARGUMENTS` interpolation works on target agent
- Confirmation that `allowed-tools` enforcement behaves as expected across platforms

**Why it matters:**
Skills generated for Claude Code may not work (or behave unexpectedly) on other agents. Compatibility matrix shows Copilot `$ARGUMENTS` support is undefined—highest priority unknowns need testing.

**Source:** TD-010 (Lambert's cross-agent compatibility doc), Claude Code vs. Copilot vs. Codex feature parity analysis.

**What done looks like:**
- Generated skills include "Compatibility" section with agent-specific notes
- Live testing on Copilot, Cursor, Codex with representative skills
- Compatibility matrix updated with ✅/🟡/❓/❌ status for each feature×agent combination

---

## Gap 3: No Parallel Tool Use Guidance

**What's missing:**
- Skills that encourage agents to parallelize file reads, searches
- Generated prompts that include "make all independent tool calls in parallel"
- Knowledge that parallel execution is 3-5x faster for file-heavy operations

**Why it matters:**
Both Claude Opus 4.6 and Codex best practices emphasize parallel tool calling as high-impact optimization. Generated skills that don't prompt for parallelization leave 3-5x performance on the table.

**Source:** Claude Opus 4.6 best practices (parallel tool calls section), Codex prompting guide (tool use efficiency).

**What done looks like:**
- `cogworks-encode` extracts parallel execution patterns from agent workflow sources
- `cogworks-learn` templates include parallel tool use guidance: "When you intend to call multiple tools with no dependencies, make all independent tool calls in parallel"
- Generated skills for file-heavy tasks (research, batch processing) include parallel execution instructions

---

## Gap 4: No Subagent Orchestration Patterns

**What's missing:**
- Guidance on using `context: fork` in generated skills
- Patterns for delegating research/verification to subagents to preserve parent context
- Skills that know to isolate high-volume operations (test runs, log parsing)

**Why it matters:**
Subagents preserve parent context by isolating verbose output—only summaries return. Without this, generated skills bloat parent context with test logs, search results, and command outputs.

**Source:** Claude Code sub-agents docs (context isolation best practices), how-claude-works (context window as fundamental constraint).

**What done looks like:**
- `cogworks-learn` includes decision rule: if skill involves research/testing/log parsing → use `context: fork`
- Template guidance for when/how to specify `agent: Explore` or `agent: general-purpose`
- Example skills demonstrating subagent delegation with summaries-only return contracts

---

## Gap 5: No Multi-Context Window State Management

**What's missing:**
- Instructions to persist state to files (tests.json, progress.txt)
- Guidance on using git for state tracking across context windows
- Setup scripts (init.sh) for graceful restarts after context compaction

**Why it matters:**
Generated skills for long-running tasks may prematurely terminate as context fills—or lose state across context transitions. Claude 4.x and Codex both support multi-context workflows but require explicit state persistence.

**Source:** Claude long-horizon reasoning best practices, Codex compaction support (Responses API `/compact` endpoint).

**What done looks like:**
- `cogworks-learn` templates include state management patterns: JSON for structured data, plain text for notes, git for checkpoints
- Generated skills for multi-step workflows include "save progress before compaction" instructions
- Skills that set up init.sh or equivalent for graceful context window transitions

---

## Gap 6: No Evaluation Flywheel Integration

> **Status (2026-03-13):** PARTIALLY ADDRESSED. Recursive round system now exists (`scripts/run-recursive-round.sh`) with manifests, hooks (5 phases), and selection weights. Not yet fully automated CI.

**What's missing:**
- Skills that self-improve through eval-driven iteration
- Workflow where generated skills undergo eval → failure analysis → revision → re-eval
- Integration of behavioral traces as quality gates before skill deployment

**Why it matters:**
One-shot generation produces skills that fail on real-world edge cases. Eval-driven refinement (draft → eval → analyze → revise → re-eval) creates resilient skills through empirical feedback.

**Source:** Codex evaluation flywheel (building resilient prompts via continuous iteration), IBM prompt optimization guides.

**What done looks like:**
- Post-generation: auto-run behavioral tests on generated skill
- On failure: analyze root cause, categorize failure mode, surgical revision
- Re-eval confirms fix without regression
- Iterate until behavioral coverage ≥ 90% before deployment

---

## Gap 7: Codex-Specific Patterns Not Encoded

> **Status (2026-03-13):** PARTIALLY ADDRESSED. D-032 added Codex benchmark integration via replayable adapter. D-039 classifies Codex as portable-only (no trust-first build path). Full Codex template generation still unimplemented.

**What's missing:**
- `apply_patch` tool usage patterns (structured diffs for create/update/delete)
- `update_plan` tool for TODO tracking (statuses: pending, in_progress, completed)
- `shell_command` preference over ad-hoc bash
- Compaction via `/compact` endpoint
- AGENTS.md file discovery (Codex-cli)

**Why it matters:**
Synthesis sources include Codex/GPT-5.x prompting guides, but cogworks pipeline focuses on Claude. Skills generated for Codex agents don't leverage platform-specific affordances, reducing effectiveness.

**Source:** Codex prompting guide (tool implementations, autonomy principle), GPT-5.1 guide (reasoning effort configuration).

**What done looks like:**
- `cogworks-encode` recognizes Codex-specific tool patterns in sources
- `cogworks-learn` templates include conditional guidance: "If target agent is Codex, prefer `apply_patch` over direct file edits"
- Generated skills for Codex include `update_plan` guidance (2-5 milestones, one in_progress at a time, zero pending before turn ends)

---

## Gap 8: No Prompt Caching Optimization

**What's missing:**
- Structure skills to maximize cacheable prefix (static system prompt, long context)
- Guidance on separating static from dynamic content
- Skills that leverage caching for repeated invocations

**Why it matters:**
Generated skills with poor caching structure have worse latency/cost profile when invoked repeatedly. Claude prompt caching and IBM caching patterns both emphasize prefix optimization.

**Source:** Claude prompt caching docs, IBM caching overview (cache static prompt prefix, reuse on subsequent calls).

**What done looks like:**
- `cogworks-learn` templates separate static preamble from dynamic `$ARGUMENTS`-dependent sections
- Generated skills with long reference material structure for cache-friendly invocation
- Documentation on caching behavior and optimization strategies for skill authors

---

## Gap 9: No Security Injection Scanning for Skill Content

> **Status (2026-03-13):** OPEN — Ash's inbox proposal addresses this. Awaiting user triage.

**What's missing:**
- Post-generation scan for prompt-override phrases ("ignore prior instructions")
- Scan for standalone imperative directives ("you must always")
- Scan for tool call syntax not belonging to skill delimiters
- Scan for delimiter leakage

**Why it matters:**
Generated skill content could contain patterns that allow prompt injection if user crafts malicious invocation arguments. TD-002 added guards to orchestration but not to generated skill bodies.

**Source:** TD-002 (Ash's M2 delimiter escape, M9 post-generation injection scan).

**What done looks like:**
- `cogworks-learn` runs four pattern scans before writing generated SKILL.md
- Patterns: (1) prompt-override phrases, (2) imperative directives, (3) tool call syntax, (4) delimiter leakage
- User confirmation required if any pattern detected
- CI gate blocks deployment if injection patterns found

---

## Gap 10: No Guidance on When NOT to Use Skills

**What's missing:**
- Guidance on when CLAUDE.md is better (persistent instructions)
- Guidance on when hooks are better (deterministic enforcement)
- Guidance on when subagents are better (task orchestration)
- Trade-off matrix: skills vs. CLAUDE.md vs. hooks vs. subagents

**Why it matters:**
Generated skills may duplicate or conflict with CLAUDE.md or hooks, creating maintenance burden and steerability issues. Skills are one tool in the agent configuration toolkit—not always the right one.

**Source:** Claude Code features-overview (matching features to goals), best practices (hooks for zero-exception enforcement).

**What done looks like:**
- `cogworks-learn` includes decision tree: persistent rules → CLAUDE.md; deterministic enforcement → hooks; task workflows → skills; orchestration → subagents
- Generated skills include "Why a skill?" section justifying skill abstraction over alternatives
- Documentation artifact: trade-off matrix comparing skills/CLAUDE.md/hooks/subagents across criteria (scope, persistence, enforcement, discoverability)

---

## Priority Recommendations

### P0: Activation Testing (Gap 1)
**Impact:** Critical. Skills with poor invocation never trigger—content quality is irrelevant.  
**Effort:** Medium. Extend existing behavioral eval framework with activation test suite.  
**Dependencies:** None. Can proceed immediately.

### P1: Parallel Tool Use (Gap 3)
**Impact:** High. 3-5x performance improvement for free; appears in both Claude and Codex best practices.  
**Effort:** Low. Template guidance in `cogworks-learn`, pattern extraction in `cogworks-encode`.  
**Dependencies:** None. Can proceed immediately.

### P1: Evaluation Flywheel (Gap 6)
**Impact:** High. Eval-driven refinement creates resilient skills; one-shot generation produces brittle ones.  
**Effort:** Medium-High. Requires orchestration logic (eval → analyze → revise → re-eval loop).  
**Dependencies:** Activation testing (Gap 1) for complete eval coverage.

### P2: Cross-Agent Compatibility (Gap 2)
**Impact:** Medium. Affects multi-agent deployment scenarios; critical unknowns need empirical testing.  
**Effort:** Medium. Live testing on Copilot/Cursor/Codex, template guidance in `cogworks-learn`.  
**Dependencies:** None, but benefits from activation testing baseline.

### P2: Subagent Orchestration (Gap 4)
**Impact:** Medium. Context management at scale requires isolation patterns; critical for long-running tasks.  
**Effort:** Low-Medium. Decision rule + template guidance in `cogworks-learn`.  
**Dependencies:** None. Can proceed immediately.

---

## Roadmap Considerations

**Quick wins (can ship in days):**
- Gap 3 (parallel tool use): template guidance only
- Gap 4 (subagent orchestration): decision rule + templates
- Gap 10 (when NOT to use skills): decision tree + trade-off matrix

**Medium investment (1-2 weeks):**
- Gap 1 (activation testing): extend behavioral eval framework
- Gap 2 (cross-agent compatibility): live testing + matrix updates
- Gap 8 (prompt caching): structural guidance for generated skills

**Heavy lift (multi-week or needs research):**
- Gap 6 (evaluation flywheel): orchestration logic for iterative refinement
- Gap 7 (Codex-specific patterns): conditional templates per target agent
- Gap 5 (multi-context state): comprehensive state persistence patterns

**Security-critical (coordinate with Ash):**
- Gap 9 (injection scanning): pattern detection + CI gate integration
