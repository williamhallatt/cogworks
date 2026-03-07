# Agentic V2 Simplify And 3-Case Eval

## Accepted direction

1. Simplify the agentic runtime before widening the benchmark surface.
2. Rerun quality comparison on a targeted 3-case synthesis set.
3. Do not kill the pivot without explicit user confirmation.

## Simplification goals

- reduce the agentic stage graph from 9 stages to 5
- make agentic selective (`agentic-short-path` vs `agentic-full-path`)
- reduce specialist fan-out and subagent overhead
- keep generated skills as the primary artifact
- keep run artifacts benchmarkable

## Runtime changes

### New 5-stage graph

1. `source-intake`
2. `synthesis`
3. `skill-packaging`
4. `deterministic-validation`
5. `final-review`

### New role model

- `coordinator`
- `intake-analyst`
- `synthesizer`
- `composer`
- `validator`

### Selective execution

- `agentic-short-path` for simple multi-source runs
- `agentic-full-path` only for contradiction, trust-boundary, derivative-source, or entity-boundary risk

## Eval changes

- replace the too-broad default 5-case set with a targeted 3-case synthesis set
- keep Claude as generator and Codex as judge
- allow only `continue` or `simplify` as automatic recommendations
- do not auto-recommend `kill`

## Outcome

- Simplified runtime contract implemented
- smoke validator and docs updated to the new 5-stage contract
- targeted 3-case quality rerun launched
- live rerun still bottlenecked on current legacy generation latency, so no new full comparison artifact was completed in the same turn
