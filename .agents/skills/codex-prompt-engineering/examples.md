# Practical Examples: Before/After

## Example 1: Reasoning Effort

### Before (Inefficient)
```text
Task: "Sort a list"
reasoning_effort: "high"
```

### After (Calibrated)
```text
Task: "Sort a list"
reasoning_effort: omitted (or "none")
```

```text
Task: "Design multi-region cache with failover"
reasoning_effort: "high" (or "xhigh" for strict constraints)
```

## Example 2: Autonomy

### Before (Stops Repeatedly)
```text
I found files. Continue?
I changed imports. Continue?
I wrote tests. Continue?
```

### After (End-to-End)
```text
Plan:
1. Extract auth module
2. Update imports
3. Add tests
4. Run suite

[executes all steps]
Final: refactor complete, tests passing.
```

## Example 3: File Editing Tool Choice

### Before (Fragile Shell Edit)
```bash
sed -i 's/timeout: 30/timeout: 60/' config.yaml
```

### After (Deterministic Patch)
```text
Use apply_patch to update config.yaml:
- timeout: 30 -> 60
```

## Example 4: Planning Payload (Correct Schema)

### Before (Invalid)
```json
{
  "tasks": [
    {"id": 1, "desc": "Implement auth", "status": "pending"}
  ]
}
```

### After (Valid)
```json
{
  "plan": [
    {"step": "Implement auth", "status": "in_progress"},
    {"step": "Add tests", "status": "pending"},
    {"step": "Run full suite", "status": "pending"}
  ]
}
```

## Example 5: Parallel Read Batch

### Before (Sequential)
```text
read file A
read file B
read file C
```

### After (Parallel)
```text
Use multi_tool_use.parallel with 3 independent exec_command reads.
```

## Example 6: Output Compactness

### Before (Too Verbose for Tiny Fix)
```text
15 paragraphs for a 3-line null-check fix.
```

### After (Right Sized)
```text
Added a null guard in auth validation to prevent runtime errors
(auth.py:45). Added one regression test.
```

## Example 7: Evaluation Flywheel

### Before (Random Prompt Tweaks)
```text
"Let me tweak wording and try again."
```

### After (Measured Iteration)
```text
Analyze: top failures = formatting (55%), stale facts (30%), tool misuse (15%)
Measure: baseline pass rate 0.62
Improve: add format rubric + freshness check + tool policy line
Measure: pass rate 0.86
```

## Example 8: Input Security

### Before (Single Control)
```python
def respond(q):
    if len(q) > 5000:
        raise ValueError
    return llm(q)
```

### After (Layered)
```python
def respond(q):
    validate_input(q)
    prompt = wrap_as_data(q)
    raw = llm(prompt)
    return filter_output(raw)
```

## Example 9: Runtime Tool Naming

### Before (Wrong Runtime Name)
```text
Use shell_command for all terminal work.
```

### After (Runtime-Mapped)
```text
In this runtime, use exec_command for terminal work.
```

## Example 10: Scope Discipline

### Before (Feature Creep)
```text
User asked for a basic login form.
Agent added animations, OAuth, forgot-password modal, password meter.
```

### After (Exact Scope)
```text
System rule: implement exactly requested scope; no extra features unless asked.
```
