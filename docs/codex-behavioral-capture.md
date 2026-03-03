# Capturing Behavioral Traces from OpenAI Codex

## What is a Behavioral Trace?

A behavioral trace is a recorded snapshot of a single skill invocation that captures:
- **Input:** The user's prompt or explicit skill activation
- **Skill invocation:** Which skill was called and with what parameters
- **Output:** The agent's response, tools used, files modified, and final state

Traces serve as regression and parity tests across agents — they verify that the same skill produces consistent (or similarly high-quality) behavior when invoked across Claude, Copilot, Codex, and other agents.

## How Codex Differs from Claude

**Claude (auto-load behavior):**
- Claude Code auto-loads all available skills from `.claude/skills/` symlinks
- Skills are automatically discovered and invoked when their trigger conditions are met
- Skill instructions are live-read from SKILL.md files on each invocation

**Codex/OpenAI (explicit-only load):**
- Codex does NOT auto-load skills from the file system
- Skills must be explicitly passed in the system context or prompt
- The skill's SKILL.md instructions must be manually inserted into the conversation
- No automatic discovery or live-edit behavior

**Implication for testing:** Codex behavioral traces must record which skill instructions were provided and in what form, since reproduction requires exact replication of that context.

## Manually Capturing a Codex Trace

### 1. Prepare the skill instructions
- Locate the skill's `SKILL.md` file (e.g., `skills/cogworks-encode/SKILL.md`)
- Copy the full SKILL.md content including frontmatter
- Record the skill name and version from the frontmatter

### 2. Craft the prompt
- Write a user prompt that would naturally trigger the skill or clearly request it
- Note: Be explicit about what you want (Codex requires direct requests, not implicit discovery)
- Keep the prompt representative of real usage

### 3. Run the invocation
- Paste skill instructions + prompt into Codex
- Capture the complete exchange: prompt → instructions → response
- Note the exact model version used (`gpt-5.2-codex`, `gpt-5.1-codex`, etc.)
- Record any tools Codex invoked, files it mentioned creating/modifying, or commands it suggested

### 4. Document what to record
For each trace, capture:
- `skill_slug` — the skill's identifier (e.g., "cogworks-encode")
- `case_id` — unique identifier for this test case (format: `{skill_slug}-{type}-{number}`, e.g., `cogworks-encode-exp-001`)
- `activated` — boolean; was the skill successfully invoked? (true for most captures)
- `activation_source` — how it was invoked ("explicit_request" for Codex, since requests are manual)
- `tools_used` — list of tool names Codex mentioned or called
- `tool_events` — detailed tool invocation events (if available)
- `commands` — shell/code commands Codex generated
- `files_modified` — paths of files Codex said it would modify
- `files_created` — paths of files Codex said it would create
- `task_completed` — did Codex complete the requested task?
- `quality_score` — optional subjective score (1–5) of the response quality
- `baseline_run` — boolean; is this a baseline/golden trace?
- `model` — model identifier (e.g., "gpt-5.2-codex")
- `trace_source` — always "captured" for manual records
- `captured_at` — ISO 8601 timestamp when the trace was recorded
- `notes` — any relevant context (e.g., "Tested with explicit instruction injection")

### 5. JSONL format
Save traces as JSON objects in `tests/behavioral/{skill-name}/traces/{case_id}.json`:

```json
{
  "skill_slug": "cogworks-encode",
  "case_id": "cogworks-encode-exp-001",
  "activated": true,
  "activation_source": "explicit_request",
  "tools_used": ["curl", "git"],
  "tool_events": [
    {"tool": "curl", "arguments": {"url": "https://example.com"}, "status": "success"}
  ],
  "commands": ["git clone https://example.com/repo"],
  "files_modified": ["data.json"],
  "files_created": ["output.md"],
  "task_completed": true,
  "quality_score": 4,
  "baseline_run": false,
  "model": "gpt-5.2-codex",
  "trace_source": "captured",
  "captured_at": "2026-03-10T14:22:30Z",
  "notes": "Codex successfully encoded multi-source knowledge; minor hallucination on tool output"
}
```

## Adding a Captured Trace to the Test Suite

1. **Create the trace file:**
   - Path: `tests/behavioral/{skill-slug}/traces/{case_id}.json`
   - Ensure JSON is valid (no trailing commas, proper escaping)

2. **Register the test case:**
   - Add a matching entry to `tests/behavioral/{skill-slug}/test-cases.jsonl`
   - Each line is a JSON object with `case_id`, `description`, and `expected_behavior`
   - Example:
     ```jsonl
     {"case_id": "cogworks-encode-exp-001", "description": "Encode from URL + GitHub repo", "expected_behavior": "produces valid SKILL.md frontmatter"}
     ```

3. **Run behavioral evaluation:**
   - Execute: `python3 tests/framework/scripts/cogworks-eval.py behavioral run --skill-prefix cogworks-encode`
   - The evaluator loads `.json` traces and compares them against live runs
   - See `tests/framework/README.md` for grading criteria and gates

## Known Limitations: Non-Deterministic Replay

**Why Codex cannot be re-run against exact traces:**

Codex (and all generative models) are non-deterministic. Given the same instructions and prompt:
- The model may produce slightly different wording or structure
- Token sampling introduces randomness even at temperature 0.1
- The model's internal state and training snapshot affect outputs
- Over-fitting test cases to exact string matches defeats the purpose

**How the evaluator handles this:**

The behavioral test framework does NOT expect byte-for-byte reproduction. Instead:
- **Structural checks:** Does the output contain the expected artifacts? (files created, commands suggested, etc.)
- **Semantic checks:** Does the response address the requested task?
- **Quality gates:** Is the response above a quality threshold (BLEU/ROUGE scores, manual grading)?
- **Consistency checks:** Do multiple runs from different models show broadly similar outcomes?

**Best practice:**
- Capture traces to establish baselines and parity between agents
- Use traces as regression anchors ("this worked in the past"), not exact templates
- Grade quality subjectively and document why a trace is a good/bad baseline
- When Codex behavior diverges, evaluate if the change is harmful or acceptable

## Related Documentation

- `tests/behavioral/README.md` — trace storage and structure
- `tests/framework/README.md` — evaluation pipeline and grading
- `tests/behavioral/refresh-policy.md` — when and how to refresh traces
