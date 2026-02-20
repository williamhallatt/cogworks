# Transferable Patterns

These patterns extend beyond prompt engineering and apply to software development, system design, and quality assurance domains.

---

## Pattern 1: Evaluation Flywheel

**When**: System quality requires continuous improvement and adaptation

**Why**: Enables systematic identification and resolution of failure modes

**How**: Implement three-phase cycle
1. **Analyze**: Qualitatively review failures (open/axial coding)
2. **Measure**: Quantify with automated graders and test datasets
3. **Improve**: Make targeted changes and measure impact
4. **Repeat**: Continuous cycle, not one-time exercise

**Example**:
```python
# CI/CD integration
def quality_gate(test_results):
    if test_results.pass_rate < 0.85:
        failure_modes = analyze_failures(test_results)
        print(f"Quality gate failed. Top issues: {failure_modes}")
        return False
    return True
```

**Applicable Beyond PE**: Software testing, machine learning model improvement, product development, customer support optimization

**Source**: [Source 3]

---

## Pattern 2: Explicit State Checkpoints

**When**: Long-running processes span multiple sessions or context windows

**Why**: Enables recovery, reduces rework, provides audit trail

**How**: Persist state at natural boundaries
1. Identify milestone boundaries (completed features, passing tests)
2. Serialize state to durable storage (files, git commits, databases)
3. Include metadata (timestamp, status, next actions)
4. Provide recovery mechanism

**Example**:
```json
// state.json persists across context windows
{
    "project": "auth-refactor",
    "completed": ["user-model", "login-endpoint"],
    "in_progress": "password-reset",
    "decisions": {"token_storage": "httpOnly-cookies"},
    "window": 2,
    "checkpoint_commit": "abc123"
}
```

**Applicable Beyond PE**: Database transactions, distributed systems, scientific simulations, creative projects, workflow automation

**Source**: [Source 1], [Source 4]

---

## Pattern 3: Calibrated Autonomy

**When**: System operates with varying levels of user supervision

**Why**: Balances efficiency with safety and user control

**How**: Define autonomy levels by reversibility and risk
1. **High autonomy**: Version-controlled code, test environments
2. **Moderate autonomy**: Confirm before production deployments
3. **Low autonomy**: Present options for ambiguous requirements
4. **No autonomy**: Require approval for destructive operations

**Example**:
```python
def execute_command(cmd, context):
    risk = assess_risk(cmd, context)
    if risk == "destructive":
        return {"status": "awaiting_approval", "command": cmd}
    elif risk == "production":
        return {"status": "confirm_first", "command": cmd, "impact": estimate_impact(cmd)}
    else:
        return execute(cmd)
```

**Applicable Beyond PE**: Robotics, autonomous vehicles, financial trading systems, medical devices, industrial automation

**Source**: [Source 1], [Source 2]

---

## Pattern 4: Parallel Execution with Dependency Management

**When**: Independent operations can run concurrently

**Why**: Reduces latency, improves throughput, enhances user experience

**How**: Identify independence and batch execution
1. Analyze operation dependencies
2. Group independent operations
3. Execute batches in parallel
4. Synchronize before dependent operations

**Example**:
```python
# Sequential (slow)
def gather_data_sequential(sources):
    results = []
    for source in sources:
        results.append(fetch(source))
    return results

# Parallel (fast)
import asyncio
async def gather_data_parallel(sources):
    tasks = [fetch_async(source) for source in sources]
    return await asyncio.gather(*tasks)
```

**Applicable Beyond PE**: Database queries, API calls, file I/O, data pipelines, distributed computing

**Source**: [Source 1], [Source 2]

---

## Pattern 5: Open/Axial Coding for Failure Analysis

**When**: Systems exhibit failures but patterns are unclear

**Why**: Reveals underlying structure in seemingly chaotic failures

**How**: Two-phase qualitative analysis
1. **Open Coding**: Review ~50 failures, apply descriptive labels freely
2. **Axial Coding**: Group labels into hierarchical taxonomy
3. **Quantify**: Count frequency of each category
4. **Prioritize**: Focus on top 3-5 categories

**Example**:
```
Open Coding (raw labels):
- "wrong timezone in booking"
- "tour time not available"
- "date format inconsistent"
- "suggested sold-out tour"

Axial Coding (taxonomy):
- Scheduling Issues (60%): timing conflicts, availability errors
- Formatting Problems (25%): date/time format inconsistencies
- Data Staleness (15%): sold-out tours suggested
```

**Applicable Beyond PE**: UX research, customer support analysis, incident post-mortems, medical diagnosis

**Source**: [Source 3]

---

## Pattern 6: Compactness by Context Size

**When**: Output verbosity should scale with change significance

**Why**: Prevents information overload, maintains focus on important details

**How**: Define verbosity rules by magnitude
1. **Tiny changes**: Brief summary (2-5 sentences)
2. **Medium changes**: Structured bullets (≤6 items)
3. **Large changes**: Per-component summaries
4. **Architecture changes**: Decision rationale + trade-offs

**Example**:
```
# Bad: Verbose for tiny change
"I've updated the timeout from 30 to 60 seconds. Previously, the timeout
was set to 30 seconds which sometimes caused issues with slow networks..."
[200 words]

# Good: Compact for tiny change
"Increased timeout from 30s to 60s to handle slow networks."
```

**Applicable Beyond PE**: Code reviews, status reports, executive summaries, documentation

**Source**: [Source 2], [Source 3]

---

## Pattern 7: Defense-in-Depth

**When**: Single-point failures carry unacceptable risk

**Why**: Multiple independent controls compensate for individual weaknesses

**How**: Layer security controls
1. **Layer 1**: Input validation at boundaries
2. **Layer 2**: Architectural separation (least privilege, parameterization)
3. **Layer 3**: Output filtering and monitoring
4. Ensure layer independence (bypass of one doesn't compromise all)

**Example**:
```python
# Layer 1: Input validation
def validate_input(user_input):
    if not is_safe(user_input):
        raise SecurityError("Invalid input")

# Layer 2: Parameterization
def query_database(user_id):  # Not string concatenation
    return db.execute("SELECT * FROM users WHERE id = ?", (user_id,))

# Layer 3: Output filtering
def filter_response(response):
    return remove_sensitive_data(response)
```

**Applicable Beyond PE**: Cybersecurity, safety-critical systems, financial controls, infrastructure protection

**Source**: [Source 7], [Source 8]

---

## Pattern 8: LLM Judge Calibration

**When**: Automated evaluation requires alignment with human judgment

**Why**: Ensures graders identify both failures and successes accurately

**How**: Three-dataset approach
1. **Train set (20%)**: Few-shot examples for judge
2. **Validation set (40%)**: Iterative improvement until TPR/TNR targets met
3. **Test set (40%)**: Final held-out evaluation
4. Track True Positive Rate and True Negative Rate

**Example**:
```python
def calibrate_judge(train, validation, test):
    # Train: Add few-shot examples to judge prompt
    judge = create_judge_with_examples(train)

    # Validation: Iterate until metrics acceptable
    while True:
        results = judge.evaluate(validation)
        if results.tpr > 0.9 and results.tnr > 0.9:
            break
        judge = refine_judge(judge, results.failures)

    # Test: Final evaluation
    final_metrics = judge.evaluate(test)
    return judge, final_metrics
```

**Applicable Beyond PE**: Machine learning evaluation, quality assurance, automated code review, content moderation

**Source**: [Source 3]

---

## Pattern 9: Synthetic Data Generation for Edge Coverage

**When**: Production data lacks diversity or edge case coverage

**Why**: Prevents overfitting to common cases, reveals hidden failures

**How**: Systematic generation across dimensions
1. Identify key dimensions (channel, intent, persona, edge conditions)
2. Generate combinations systematically
3. Include boundary conditions explicitly
4. Balance common cases with edge cases

**Example**:
```python
def generate_test_cases():
    channels = ["web", "mobile", "api"]
    intents = ["purchase", "support", "research"]
    personas = ["new_user", "power_user", "enterprise"]
    edge_cases = ["empty_input", "max_length", "unicode"]

    # Combinatorial generation
    test_cases = []
    for channel, intent, persona in product(channels, intents, personas):
        test_cases.append(create_test(channel, intent, persona))

    # Add edge cases
    for edge in edge_cases:
        test_cases.append(create_edge_test(edge))

    return test_cases
```

**Applicable Beyond PE**: Software testing, machine learning training, simulation, stress testing

**Source**: [Source 3]

---

## Pattern 10: Progressive Compaction

**When**: Long-running processes accumulate state that exceeds storage limits

**Why**: Enables indefinite continuation without hitting boundaries

**How**: Intelligent state reduction preserving critical information
1. Identify task-critical information (goals, decisions, task status)
2. Summarize historical details
3. Preserve recent context in full
4. Provide seamless continuation

**Example**:
```python
def compact_conversation(history, preserve_recent=10):
    critical_info = extract_decisions_and_todos(history)
    recent_turns = history[-preserve_recent:]
    historical_summary = summarize(history[:-preserve_recent])

    return {
        "critical": critical_info,
        "summary": historical_summary,
        "recent": recent_turns
    }
```

**Applicable Beyond PE**: Log aggregation, time-series databases, streaming systems, archive management

**Source**: [Source 1], [Source 4]

---

*These 10 patterns synthesize lessons from Codex/GPT prompt engineering, evaluation methodology, and system design. Each pattern has proven effective across multiple domains and scales from individual tasks to production systems.*
