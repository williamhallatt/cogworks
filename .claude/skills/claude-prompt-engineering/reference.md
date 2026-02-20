# Claude Prompt Engineering Reference

## TL;DR

Use model-aware defaults, not one-size-fits-all prompting. For Opus 4.6, start with adaptive thinking at `medium` only when complexity warrants it. For Sonnet 4.5 compatibility, use extended thinking with at least 1024 tokens. Keep long tasks recoverable with explicit state and checkpoints. Batch independent tool calls in parallel. Treat security as layered controls (input, architecture, output). Keep responses concise by default and scale detail to task complexity.

## Decision Rules

1. **Reasoning mode selection**
- Opus 4.6: adaptive thinking is primary.
- Sonnet 4.5: extended thinking remains valid for legacy paths.
- Haiku 4.5: prefer explicit instructions, examples, and compact output constraints.

2. **Reasoning effort calibration**
- `low`: formatting, simple retrieval, straightforward edits.
- `medium`: default for interactive coding and moderate analysis.
- `high`: architecture, multi-constraint debugging, deep trade-offs.
- `max`: rare; use for research-heavy, ambiguity-rich synthesis.

3. **Extended thinking guardrails (Sonnet 4.5)**
- Minimum budget: 1024 tokens.
- Prefer broad goals before rigid step lists.
- Use batch mode for very large budgets (>32K) when latency/timeouts are a concern.

4. **Context management for long tasks**
- Persist state externally (`state.json`, checklist files, ADR notes).
- Add git checkpoints at meaningful milestones.
- Re-state critical decisions after context compaction risk.

5. **Autonomy and reversibility**
- Proceed autonomously for safe, reversible changes in versioned code.
- Confirm before destructive, production, or high-cost actions.
- If ambiguity affects behavior materially, present options first.

6. **Tool orchestration**
- Parallelize independent reads/searches.
- Serialize only when outputs are strict inputs to the next step.
- Avoid speculative over-fetching that inflates token usage.

7. **Output control**
- Default concise.
- Ask for prose-first communication unless structured output is required.
- Define strict format contracts when machine parsing is needed.

## Core Concepts (Compact)

### Adaptive Thinking (Opus 4.6)
Integrated reasoning that can interleave with tool use. Prefer effort tuning over manual chain-of-thought scaffolding.

### Extended Thinking (Sonnet 4.5)
Legacy explicit budgeted reasoning. Useful for compatibility and controlled reasoning spend.

### Context Compaction Awareness
Assume some old details may disappear in long sessions. Preserve decisions externally and re-anchor key facts.

### Subagent Orchestration
Delegate only when decomposition materially reduces latency or complexity. Keep depth shallow and scope explicit.

### Defense-in-Depth for Prompt Security
Use layered controls:
- Input controls: validation, delimiters, suspicious pattern handling.
- Architectural controls: least privilege, command/data separation, approvals.
- Output controls: leakage filtering and policy checks.

## Quality Gates

A prompt/workflow is acceptable when it meets all gates:

1. **Correctness gate**: Instructions are explicit, non-conflicting, and testable.
2. **Efficiency gate**: No unnecessary reasoning level, no avoidable sequential tool calls.
3. **Safety gate**: Confirmation points exist for irreversible/high-risk actions.
4. **Robustness gate**: Handles edge cases and context-loss scenarios.
5. **Traceability gate**: Claims tie back to source guidance or repository evidence.

## Anti-Patterns

1. **Over-reasoning trivial tasks**
- Symptom: high/max effort used for simple edits.
- Fix: omit explicit reasoning or use `low`.

2. **Excessive delegation**
- Symptom: subagents for tasks solvable inline in a few calls.
- Fix: set thresholds and keep orchestration shallow.

3. **Safety bypass**
- Symptom: destructive/prod changes without confirmation.
- Fix: enforce reversibility rule and approval boundaries.

4. **Single-layer security**
- Symptom: only input filtering, no architectural/output controls.
- Fix: implement all three layers for production-facing systems.

5. **Format bloat**
- Symptom: verbose markdown hierarchy with low information density.
- Fix: prose-first summaries and bounded detail.

## Quick Reference

- Opus 4.6: adaptive thinking first.
- Sonnet 4.5: extended thinking min 1024.
- Simple tasks: minimal reasoning.
- Long tasks: external state + checkpoints.
- Independent operations: parallel tools.
- Risky actions: explicit confirmation.
- Production security: layered controls.
- Output style: concise by default; expand only when needed.

## Source Scope

- **Claude-native**: direct guidance for Claude models and Claude Code behavior.
- **Cross-model contrast**: external patterns used only to sharpen trade-offs; never override Claude-native guidance.

## Sources

> **Knowledge snapshot date:** 2026-02-20

### Claude-native

- **[Source 1]** `prompting-best-practice.md` - Opus 4.6 / Sonnet 4.5 / Haiku 4.5 best practices
- **[Source 2]** `extended-thinking-tips.md` - Extended thinking usage and budgets
- **[Source 3]** `prompt-engineering.md` - Prompt engineering foundations
- **[Source 4]** `multishot-prompting.md` - Few-shot selection and structure

### Supporting PE/Security Foundations

- **[Source 5]** `prompt-engineering-techniques.md`
- **[Source 6]** `prompt-chaining-overview.md`
- **[Source 7]** `tree-of-thoughts.md`
- **[Source 8]** `meta-prompting.md`
- **[Source 10]** `prompt-injection-overview.md`
- **[Source 11]** `prevent-prompt-injection.md`
- **[Source 12]** `ai-prompt-injection-nist-report.md`
- **[Source 13]** `prompt-optimization-overview.md`
- **[Source 14]** `prompt-caching-overview.md`
- **[Source 15]** `chain-of-thoughts.md`
- **[Source 17]** `in-context-learning.md`

### Cross-model contrast (non-normative)

- **[Source 18]** `gpt-5-1-prompting-guide.md`
- **[Source 19]** `gpt-5-2-prompting-guide.md`

Use [Source 18-19] only as contrast patterns when Claude-native docs are silent.
