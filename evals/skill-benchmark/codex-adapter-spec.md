# Codex Benchmark Adapter — Design Spec

**Status:** Design spec only. Implementation deferred until Codex exposes native subagent primitives with a stable CLI contract.

**Decision:** D-035 — `scripts/skill-benchmark-codex-adapter.py` was removed as premature implementation. This document captures the design intent so the adapter can be rebuilt once the integration point stabilises.

---

## Purpose

Translate Codex CLI run output into the normalised benchmark observation schema defined in `evals/skill-benchmark/observation.schema.json`.

This adapter sits between the generic `run-skill-benchmark.py` harness and the Codex surface. The harness stays surface-neutral; the adapter handles all Codex-specific event stream parsing.

---

## Integration Contract

The adapter is invoked as a candidate command by `run-skill-benchmark.py`. It receives benchmark context through environment variables and writes a normalised observation JSON on completion.

### Required inputs (environment variables)

| Variable | Description |
|---|---|
| `COGWORKS_BENCHMARK_ID` | Benchmark run identifier |
| `COGWORKS_BENCHMARK_CASE_PATH` | Path to the benchmark case JSON |
| `COGWORKS_BENCHMARK_CANDIDATE_ID` | Which candidate is being tested |
| `COGWORKS_BENCHMARK_TRIAL_ID` | Trial number within this run |
| `COGWORKS_BENCHMARK_OBSERVATION_PATH` | Where to write the observation JSON |
| `COGWORKS_BENCHMARK_WORK_DIR` | Trial-scoped scratch directory |

### Optional inputs

| Variable | Description |
|---|---|
| `COGWORKS_BENCHMARK_JUDGE_OUTPUT_PATH` | Where to write judge JSON when the case uses `judge_only` checks |
| `COGWORKS_BENCHMARK_REPLAY_TRACE` | Path to a saved JSONL event stream for offline replay |

---

## Execution Modes

### Live mode

Runs `codex exec --json <prompt>` and captures the event stream.

Requires:
- `codex` CLI available in PATH
- `COGWORKS_BENCHMARK_REPLAY_TRACE` not set

### Replay mode

Replays a saved JSONL event stream from `COGWORKS_BENCHMARK_REPLAY_TRACE` without making any live Codex calls. Enables offline testing of the benchmark contract and CI smoke coverage in sandboxed environments.

---

## Event Stream Normalisation

The Codex `--json` output is a JSONL event stream. The adapter maps these events to the benchmark observation schema:

| Observation field | Codex source |
|---|---|
| `skill_invoked` | `response_item` event with `name == "Skill"` |
| `tool_calls` | `response_item` events with `payload.type == "function_call"` |
| `files_written` | `apply_patch` tool calls — paths extracted from the patch header |
| `commands_executed` | `exec_command` or `Bash` tool calls |
| `input_tokens` | `turn.completed` event `usage.input_tokens` |
| `output_tokens` | `turn.completed` event `usage.output_tokens` |
| `estimated_cost_usd` | `turn.completed` event `estimated_usd` |
| `wall_clock_ms` | `turn.completed` event `elapsed_ms` |

The adapter preserves the raw JSONL event stream alongside the normalised observation under the trial work directory as `codex-trace.jsonl`.

---

## Outputs

| File | Description |
|---|---|
| `$COGWORKS_BENCHMARK_OBSERVATION_PATH` | Normalised observation JSON (observation.schema.json) |
| `$COGWORKS_BENCHMARK_JUDGE_OUTPUT_PATH` | Optional judge output JSON for `judge_only` cases |
| `$COGWORKS_BENCHMARK_WORK_DIR/codex-trace.jsonl` | Raw Codex event stream (debugging and audit) |

---

## Known Gap

The adapter was designed for `codex exec --json`. If Codex ships a subagent primitive with a different event schema, the normalisation logic will need revision. Build only once the target CLI contract is stable.

---

## Test Fixture Contract

A replay fixture should exist under `tests/test-data/skill-benchmark-codex-adapter/` with:
- `trace.jsonl` — a saved Codex event stream
- `expected-observation.json` — the normalised observation that the adapter should produce
- `expected-judge.json` — optional, for `judge_only` cases

A smoke test should run the adapter in replay mode against the fixture and diff the output against the expected observation.
