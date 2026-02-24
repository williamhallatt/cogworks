# Transferable Patterns

These patterns generalize beyond prompt engineering and are intentionally concise.

## 1) Evaluate as a Loop, Not a Phase

**Use when** quality must improve over time.

**Pattern**
1. Analyze failures qualitatively.
2. Measure with automated checks.
3. Improve targeted components.
4. Repeat on fresh failures.

**Transfer**
- software QA
- policy/rubric tuning
- model behavior hardening

## 2) Autonomy by Risk Tier

**Use when** an agent can act without constant user confirmations.

**Pattern**
- Low risk: proceed automatically.
- Medium risk: proceed, but surface rationale.
- High risk: require explicit approval.

**Rule of thumb**
Destructive, irreversible, or production-impacting actions are high risk.

## 3) Contract-First Tooling

**Use when** a workflow depends on structured tool calls.

**Pattern**
- document exact request/response schema
- include one valid payload example
- reject custom variants

**Why it matters**
Most agent failures in production come from contract drift, not reasoning failure.

## 4) Parallelize Independent Work

**Use when** multiple reads/searches are independent.

**Pattern**
- identify dependency graph
- run independent leaves in parallel
- synchronize before dependent steps

**Anti-pattern**
Parallelizing operations where output of A determines B.

## 5) Compactness Scales with Change Size

**Use when** user-facing communication can become noisy.

**Pattern**
- tiny change: brief prose
- medium change: short bullets
- large change: grouped summaries + decisions

**Outcome**
Higher signal density and better review velocity.

## 6) Preserve State for Long Horizons

**Use when** work spans long sessions or context compaction.

**Pattern**
- persist key decisions and task status in durable artifacts
- checkpoint at milestone boundaries
- resume from explicit state, not memory alone

**Artifacts**
- task plan
- lightweight state file
- commit checkpoints

## 7) Defense in Depth for Agent Inputs

**Use when** agent consumes untrusted input.

**Pattern**
- input validation
- instruction/data separation
- least-privilege tool access
- output filtering/monitoring

**Outcome**
Single-control bypasses no longer fully compromise behavior.

## 8) Calibrate Judges Before Trusting Scores

**Use when** LLM judges gate quality.

**Pattern**
- 20/40/40 split (train/val/test)
- tune on validation only
- publish held-out test metrics

**Anti-pattern**
Iterating directly on test set and calling it progress.
