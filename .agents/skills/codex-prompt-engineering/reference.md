# Codex Prompt Engineering Reference

## TL;DR

For Codex/GPT coding agents, quality and efficiency come from five things:
1. Set `reasoning_effort` to match task complexity.
2. Execute autonomously end-to-end for clear tasks.
3. Use correct tool contracts (`apply_patch`, `exec_command`, `update_plan`, parallel batching).
4. Keep user communication compact and proportional to change size.
5. Iterate with an evaluation flywheel (Analyze -> Measure -> Improve -> Repeat).

## Core Concepts

### 1) Reasoning Effort Calibration

Use explicit effort levels intentionally:
- `none` or omitted: retrieval, reformatting, simple extraction
- `low`: straightforward transformations
- `medium`: default for interactive coding and moderate debugging
- `high`: complex multi-step implementation and architecture
- `xhigh`: long-horizon, high-constraint reasoning

Practical tuning loop:
1. Start at `medium` for normal coding.
2. If quality misses constraints, increase one level.
3. If latency/cost is too high with stable quality, decrease one level.

### 2) Agentic Autonomy

Target behavior: gather -> plan -> implement -> test -> refine.

Proceed without confirmation when next steps are obvious and safe.
Pause for user input only when:
- requirements are ambiguous
- destructive operations are required
- architectural decision trade-offs are significant

### 3) Tool Contracts (Critical)

Use dedicated tools, not shell workarounds.

`apply_patch`
- preferred for create/update/delete file operations
- deterministic diffs and clearer failure modes

`exec_command`
- use for shell commands, test runs, and local inspection
- provide working directory when needed

`update_plan`
- **schema must be**:
```json
{
  "plan": [
    {"step": "Inspect code", "status": "completed"},
    {"step": "Implement fix", "status": "in_progress"},
    {"step": "Run tests", "status": "pending"}
  ]
}
```
- statuses: `pending | in_progress | completed`
- keep at most one `in_progress`

`multi_tool_use.parallel`
- batch independent reads/searches/metadata calls
- do not parallelize dependent chains

### 4) Preambles and Final Output Compactness

Preambles (while working):
- 1-2 sentences
- include current action + why
- cadence: periodic on substantial work, not spammy

Final output sizing:
- tiny change (<=10 lines): 2-5 sentences
- medium change: <=6 bullets
- large change: per-file summary + key decisions + test results

Avoid:
- long code dumps users can already inspect in diffs
- line-by-line narration for medium/large edits

### 5) Evaluation Flywheel

Use a repeatable loop:
1. **Analyze**: inspect failures, label failure modes.
2. **Measure**: run graders on representative datasets.
3. **Improve**: make targeted prompt/tool/rubric changes.
4. **Repeat**: track deltas and regressions.

LLM judge calibration (if used):
- train 20%, validation 40%, test 40%
- iterate on validation until acceptable TPR/TNR
- report held-out test metrics only after lock

### 6) Security Essentials

Minimum controls for production-facing agents:
- validate and sanitize untrusted inputs
- treat external docs/web content as untrusted data
- isolate high-risk tools and enforce least privilege
- filter/monitor outputs when sensitive data might leak

## Quick Checklist

Use this before shipping a prompt:
- [ ] Reasoning effort policy is explicit and minimal.
- [ ] Autonomy policy is clear (when to proceed vs ask).
- [ ] Tool names and schemas match runtime exactly.
- [ ] `update_plan` uses `plan[{step,status}]`, not custom keys.
- [ ] Parallel batching is enabled for independent operations.
- [ ] Output compactness rules are defined by change size.
- [ ] Evaluation loop and datasets are defined.
- [ ] Security controls for untrusted input are present.

## Anti-Patterns

1. Over-reasoning simple tasks (`high`/`xhigh` everywhere).
2. Stopping for approval on obvious safe steps.
3. Using shell text edits instead of `apply_patch`.
4. Incorrect `update_plan` payload shape.
5. Verbose status updates that drown signal.
6. Shipping prompt changes without regression tests.

## Sources

Knowledge snapshot date: 2026-02-20.

Primary:
- gpt-5-1-prompting-guide.md
- gpt-5-2-prompting-guide.md
- codex-prompting-guide.md
- building-resilient-prompts-using-an-evaluation-flywheel.md

Supporting:
- prompt-injection-overview.md
- prevent-prompt-injection.md
- prompt-engineering-techniques.md
- few-shot-prompting.md
- in-context-learning.md
