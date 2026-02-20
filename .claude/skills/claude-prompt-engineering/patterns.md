# Transferable Patterns

These patterns extend beyond prompt engineering and apply to software architecture, system design, and complex problem-solving domains.

---

## Pattern 1: Progressive Disclosure

**When**: Information complexity exceeds immediate cognitive capacity or token budgets

**Why**: Reduces overwhelm, enables focused attention, improves retention

**How**: Structure information hierarchically with increasing detail depth
1. Start with high-level overview (TL;DR, executive summary)
2. Provide mid-level structure (core concepts, key relationships)
3. Offer deep dives for specialized topics
4. Include quick reference for rapid lookup

**Example**:
```
# Poor: Information dump
Here's everything about authentication: JWT tokens use HMAC-SHA256 signatures with
secret keys stored in environment variables. Token expiration is 15 minutes for access
tokens and 7 days for refresh tokens. CORS must be configured to allow credentials...

# Good: Progressive disclosure
Authentication System Overview
- Token-based (JWT)
- 15-min access / 7-day refresh
- HMAC-SHA256 signing
[See Deep Dive: Token Architecture for implementation details]
```

**Applicable Beyond PE**: API documentation, technical onboarding, educational content, user interfaces

**Source**: [Source 2], [Source 13]

---

## Pattern 2: Feedback Loops

**When**: System behavior requires continuous refinement and quality improvement

**Why**: Enables self-correction, surfaces hidden issues, drives iterative improvement

**How**: Implement structured observation → evaluation → adjustment cycles
1. Define measurable success criteria
2. Observe system outputs systematically
3. Evaluate against criteria with quantitative/qualitative metrics
4. Adjust inputs based on evaluation results
5. Repeat cycle

**Example**:
```python
# Prompt engineering feedback loop
def optimize_prompt(initial_prompt, test_cases):
    prompt = initial_prompt
    for iteration in range(MAX_ITERATIONS):
        # Observe
        outputs = [evaluate(prompt, test_case) for test_case in test_cases]

        # Evaluate
        score = compute_accuracy(outputs)
        if score > THRESHOLD:
            break

        # Adjust
        failure_modes = analyze_failures(outputs)
        prompt = refine_prompt(prompt, failure_modes)

    return prompt
```

**Applicable Beyond PE**: Software testing, machine learning training, product development, continuous improvement processes

**Source**: [Source 13]

---

## Pattern 3: State Checkpoints

**When**: Long-running processes risk data loss from interruptions or errors

**Why**: Enables recovery, reduces rework, provides audit trails

**How**: Persist intermediate state at natural boundaries
1. Identify natural breakpoints (completed subtasks, milestones)
2. Serialize state to durable storage (git commits, database, files)
3. Include metadata (timestamp, version, dependencies)
4. Provide rollback mechanism

**Example**:
```bash
# Multi-window workflow with git checkpoints
git commit -m "Window 1 complete: User model schema [CHECKPOINT]"
# ... work continues ...
git commit -m "Window 2 complete: Login endpoint [CHECKPOINT]"
# ... interruption occurs ...
# Recovery: git log --grep="CHECKPOINT" to find last good state
```

**Applicable Beyond PE**: Database transactions, distributed systems, scientific simulations, creative projects

**Source**: [Source 6]

---

## Pattern 4: Parallel Execution

**When**: Independent operations can run concurrently without dependencies

**Why**: Reduces latency, improves throughput, enhances responsiveness

**How**: Identify independence, execute concurrently, synchronize on completion
1. Analyze task dependency graph
2. Identify operations with no shared state or ordering requirements
3. Execute in parallel (threads, processes, async/await)
4. Synchronize results before dependent operations

**Example**:
```python
# Sequential (slow)
def fetch_data_sequential(urls):
    results = []
    for url in urls:
        results.append(fetch(url))
    return results

# Parallel (fast)
import asyncio
async def fetch_data_parallel(urls):
    tasks = [fetch_async(url) for url in urls]
    results = await asyncio.gather(*tasks)
    return results
```

**Applicable Beyond PE**: Database queries, API calls, file I/O, UI rendering, data processing pipelines

**Source**: [Source 1], [Source 18]

---

## Pattern 5: Defense-in-Depth

**When**: Single-point failures carry unacceptable risk

**Why**: Compensates for individual control weaknesses, increases attack cost

**How**: Layer multiple independent security controls
1. Identify threat model and attack surfaces
2. Implement controls at multiple layers (network, application, data)
3. Ensure layer independence (single bypass doesn't compromise all)
4. Monitor and log at each layer

**Example**:
```
Web Application Security Layers:
Layer 1: Network firewall (block malicious IPs)
Layer 2: WAF (SQL injection, XSS filtering)
Layer 3: Application input validation
Layer 4: Parameterized queries (SQLi prevention)
Layer 5: Output encoding (XSS prevention)
Layer 6: Access control checks
Layer 7: Audit logging
```

**Applicable Beyond PE**: Cybersecurity, safety-critical systems, financial controls, quality assurance

**Source**: [Source 11], [Source 12]

---

## Pattern 6: Explicit State Management

**When**: System behavior depends on accumulated context or history

**Why**: Prevents state drift, enables debugging, facilitates recovery

**How**: Make state explicit, serializable, and inspectable
1. Define state schema explicitly (JSON, protobuf, typed dataclasses)
2. Centralize state storage (avoid scattered implicit state)
3. Version state changes (enable time-travel debugging)
4. Validate state transitions (enforce invariants)

**Example**:
```python
# Implicit state (hard to debug)
def process_request(data):
    global user, session, cache  # scattered state
    # ... complex logic ...

# Explicit state (clear and testable)
@dataclass
class AppState:
    user: User
    session: Session
    cache: Dict[str, Any]
    version: int

def process_request(state: AppState, data: Request) -> Tuple[AppState, Response]:
    new_state = evolve(state, ...)  # immutable update
    response = compute_response(new_state, data)
    return new_state, response
```

**Applicable Beyond PE**: State machines, Redux/Vuex architecture, game engines, workflow systems

**Source**: [Source 6], [Source 17]

---

## Pattern 7: Hypothesis-Driven Investigation

**When**: Root cause is unclear and multiple explanations are plausible

**Why**: Prevents premature conclusions, ensures systematic exploration, builds confidence

**How**: Formulate testable hypotheses, gather evidence systematically, update beliefs
1. State problem clearly
2. Generate 2-4 candidate hypotheses
3. Predict what evidence would support/refute each
4. Gather evidence systematically
5. Evaluate hypothesis fit
6. Refine or reject based on evidence

**Example**:
```
Problem: API latency increased from 50ms to 500ms

Hypothesis 1: Database connection pool exhausted
  Prediction: Connection wait times should be high
  Test: Check DB connection metrics
  Result: Wait times <1ms [REFUTED]

Hypothesis 2: N+1 query pattern introduced
  Prediction: Query count per request increased
  Test: Count queries in application logs
  Result: 1 query → 50 queries after recent change [CONFIRMED]
```

**Applicable Beyond PE**: Scientific research, debugging, medical diagnosis, incident response

**Source**: [Source 7], [Source 15]

---

## Pattern 8: Separation of Concerns

**When**: System complexity requires clear boundaries between responsibilities

**Why**: Improves maintainability, enables independent evolution, reduces coupling

**How**: Decompose system into components with single, well-defined responsibilities
1. Identify natural boundaries (by data, functionality, lifecycle)
2. Define clear interfaces between components
3. Minimize cross-component dependencies
4. Encapsulate implementation details

**Example**:
```
# Mixed concerns (hard to maintain)
def handle_user_request(request):
    # Validation + business logic + data access + presentation mixed
    if not request.email or '@' not in request.email:
        return "Invalid email"
    user = db.query("SELECT * FROM users WHERE email=?", request.email)
    if user:
        return f"<html><body>Welcome {user.name}</body></html>"
    ...

# Separated concerns (clear responsibilities)
class RequestValidator:
    def validate(self, request): ...

class UserService:
    def find_by_email(self, email): ...

class ResponseRenderer:
    def render_welcome(self, user): ...
```

**Applicable Beyond PE**: Software architecture, organizational design, supply chain management

**Source**: [Source 5]

---

## Pattern 9: Graceful Degradation

**When**: System operates in environments with variable resource availability

**Why**: Maintains partial functionality under constraints, improves user experience

**How**: Implement tiered functionality based on available resources
1. Define core vs enhanced functionality
2. Detect resource constraints (time, memory, API quotas)
3. Fall back to simpler approaches when constrained
4. Communicate degradation to users transparently

**Example**:
```python
def generate_response(query, time_budget):
    if time_budget > 10.0:
        # Enhanced: Deep research with multiple sources
        return deep_research(query, max_sources=10)
    elif time_budget > 3.0:
        # Standard: Quick research with key sources
        return quick_research(query, max_sources=3)
    else:
        # Degraded: Use cached knowledge only
        return cached_response(query)
```

**Applicable Beyond PE**: Mobile applications, distributed systems, content delivery networks, accessibility

**Source**: [Source 1], [Source 19]

---

## Pattern 10: Confident Humility

**When**: Expressing uncertainty is as important as expressing knowledge

**Why**: Builds trust, prevents overconfidence errors, guides further investigation

**How**: Calibrate confidence levels and communicate them explicitly
1. Distinguish facts from inferences
2. Quantify uncertainty (low/medium/high confidence or probabilities)
3. Cite evidence supporting confidence level
4. Acknowledge limitations and assumptions

**Example**:
```
# Overconfident (misleading)
"The bug is caused by a race condition in the payment processor."

# Confident humility (trustworthy)
"The bug is likely caused by a race condition in the payment processor (HIGH
confidence: 3 independent reproducers show timing-dependent failures; code review
reveals unprotected shared state). However, we haven't ruled out database deadlocks
(MEDIUM confidence: some error logs suggest lock timeouts). Recommend: thread-safety
audit followed by DB profiling if issue persists."
```

**Applicable Beyond PE**: Scientific communication, risk assessment, forecasting, decision support systems

**Source**: [Source 15], [Source 17]

---

## Pattern 11: Context Window Sharding

**When**: Data volume exceeds processing capacity in single operation

**Why**: Enables handling of arbitrarily large datasets within fixed constraints

**How**: Decompose large inputs into manageable chunks with state carryover
1. Identify natural chunk boundaries (files, sections, time windows)
2. Process chunks sequentially or in parallel
3. Maintain state across chunks (counters, context, summaries)
4. Aggregate results coherently

**Example**:
```python
# Single-pass (fails on large files)
def analyze_logs(log_file):
    logs = read_entire_file(log_file)  # OOM for large files
    return analyze(logs)

# Chunked with state carryover
def analyze_logs_chunked(log_file, chunk_size=1000):
    state = AnalysisState()
    for chunk in read_in_chunks(log_file, chunk_size):
        state = update_analysis(state, chunk)
    return finalize_analysis(state)
```

**Applicable Beyond PE**: Data processing, streaming systems, memory-constrained environments

**Source**: [Source 1], [Source 14]

---

## Pattern 12: Metaprogramming for Maintainability

**When**: Repetitive patterns emerge that resist traditional abstraction

**Why**: Reduces boilerplate, ensures consistency, simplifies maintenance

**How**: Generate code/prompts programmatically from high-level specifications
1. Identify repetitive patterns
2. Extract parameterizable template
3. Create generator from specifications
4. Maintain generator instead of individual instances

**Example**:
```python
# Manual repetition (error-prone)
prompt_1 = "Analyze sentiment of: {text}"
prompt_2 = "Classify topic of: {text}"
prompt_3 = "Summarize content of: {text}"

# Metaprogramming (maintainable)
TASKS = ["sentiment analysis", "topic classification", "summarization"]
TEMPLATE = "Perform {task} on the following text:\n\n{text}\n\nProvide detailed results."

prompts = {task: TEMPLATE.format(task=task, text="{text}") for task in TASKS}
```

**Applicable Beyond PE**: Code generation, configuration management, template systems, DSL design

**Source**: [Source 8], [Source 13]

---

*These 12 patterns synthesize lessons from prompt engineering, software architecture, security, and systems design. Each pattern has proven effective across multiple domains and scales from individual tasks to enterprise systems.*
