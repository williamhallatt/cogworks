# Transferable Patterns

These patterns are reusable outside prompt engineering. Source IDs map to `reference.md#sources`.

## 1. Progressive Disclosure

**Use when** complexity is high or token budget is tight.

**Pattern**
1. Start with a one-paragraph summary.
2. Provide a compact decision list.
3. Expand only the section needed for execution.

**Template**
```text
Summary:
Key decisions:
- D1
- D2
Deep dive on request:
- ...
```

**Sources**: [Source 2], [Source 13]

## 2. Feedback Loop Optimization

**Use when** quality must improve across iterations.

**Pattern**
1. Define measurable acceptance criteria.
2. Run on representative cases.
3. Classify failures.
4. Apply targeted revisions.

**Template**
```text
Criteria: ...
Failures: ...
Revision plan: ...
Re-test: ...
```

**Sources**: [Source 13]

## 3. State Checkpointing

**Use when** work spans long sessions/windows.

**Pattern**
1. Persist task state in files.
2. Commit checkpoints at milestones.
3. Resume from explicit state, not memory.

**Template**
```json
{
  "task": "...",
  "done": ["..."],
  "next": ["..."],
  "decisions": {"...": "..."},
  "checkpoint": "git_sha"
}
```

**Sources**: [Source 6], [Source 14]

## 4. Parallel-First Tooling

**Use when** operations are independent.

**Pattern**
1. Build dependency graph.
2. Batch independent reads/searches.
3. Serialize only true dependencies.

**Template**
```text
Parallel: read A, read B, read C
Then: synthesize findings
Then: edit dependent file
```

**Sources**: [Source 1], [Source 18] (contrast)

## 5. Defense-in-Depth

**Use when** untrusted input can influence model behavior.

**Pattern**
1. Input controls.
2. Architectural controls.
3. Output controls.

**Template**
```text
<input_validation>...</input_validation>
<policy>trusted instructions</policy>
<untrusted>{{USER_INPUT}}</untrusted>
<output_filter>...</output_filter>
```

**Sources**: [Source 10], [Source 11], [Source 12]

## 6. Hypothesis-Driven Investigation

**Use when** root cause is ambiguous.

**Pattern**
1. Enumerate 2-4 hypotheses.
2. Collect confirming and disconfirming evidence.
3. Assign confidence and next action.

**Template**
```text
H1: ... (confidence: low/med/high)
Evidence for: ...
Evidence against: ...
Decision: ...
```

**Sources**: [Source 7], [Source 15]

## 7. Separation of Concerns in Prompts

**Use when** prompts blend policy, data, and output constraints.

**Pattern**
1. Isolate system policy.
2. Delimit untrusted input.
3. Specify output contract separately.

**Template**
```text
<System policy>
<Untrusted input>
<Output format rules>
```

**Sources**: [Source 5], [Source 11]

## 8. Graceful Degradation

**Use when** latency or budget varies.

**Pattern**
1. Define full/standard/minimal modes.
2. Downgrade depth before dropping correctness checks.
3. State degradation explicitly.

**Template**
```text
If budget >= X: full analysis
Else if budget >= Y: concise analysis
Else: minimal answer + known gaps
```

**Sources**: [Source 1], [Source 19] (contrast)
