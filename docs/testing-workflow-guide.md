# Cogworks Testing Workflow Guide

> Historical note: this document is no longer the canonical testing runbook. Load `TESTING.md`, `tests/framework/README.md`, and `evals/skill-benchmark/runbook.md` first. Some paths in this file describe superseded or deleted benchmark surfaces.

**Version:** 1.0
**Last Updated:** March 5, 2026
**Audience:** Engineering teams implementing TDD + multi-layer validation for AI skill generation pipelines

---

## Executive Summary

The cogworks testing process uses a three-layer validation pyramid combined with test-first development practices and trace-based behavioral evaluation. This guide documents the **concrete mechanics** of how testing works, when tests run, and how to replicate this workflow in your own projects.

**Core Principle:** Break self-verification circularity by keeping validation independent from the model under test.

---

## 1. The Three Test Layers

Tests are organized by cost and execution model:

| Layer | What It Checks | LLM Required? | Cost | Speed | When It Runs |
|-------|----------------|---------------|------|-------|--------------|
| **Layer 1: Deterministic** | Skill file structure, YAML frontmatter, section headings, citation format, metadata presence, minimum word counts | No | Free | <1 second | Every commit, pre-release CI |
| **Layer 2: Behavioral** | Skill activation on correct prompts, silence on negative controls, tool invocation patterns, false positive rate | No (evaluation only) | Low | ~10 seconds | Pre-release CI, on-demand validation |
| **Layer 2: Behavioral (live capture)** | Same as above, but generates fresh traces first | Yes | High | Minutes | When updating traces |
| **Layer 3: Pipeline Benchmark** | Full `cogworks encode` end-to-end, A/B comparison (Claude vs Codex), quality/cost/robustness scoring | Yes | Very high | 10-30 minutes | Major changes, pre-release |

### Layer 1: Deterministic Checks

**Purpose:** Structural validation without invoking any LLM. This is the **minimum gate** for all skill changes.

**What it validates:**
- YAML frontmatter starts with `---`
- Required fields present: `name:`, `description:`, `metadata: { version: }`
- At least one `##` section heading exists
- Body word count ≥ 200 words (excluding frontmatter)
- No injection markers (bare `<<UNTRUSTED_SOURCE>>` at line start)
- No circular self-validation (the validator itself makes zero LLM calls)

**Scripts:**
```bash
# Run against all generated skills
bash scripts/validate-quality-gates.sh

# Run against specific skill
bash scripts/validate-quality-gates.sh path/to/SKILL.md

# Test the framework itself (meta-tests)
bash tests/run-black-box-tests.sh

# Test a single generated skill (runs Layer 1)
bash scripts/test-generated-skill.sh --skill-path .claude/skills/my-skill
```

**Exit codes:**
- `0` = all checks passed
- `1` = critical failure
- `2` = warnings (not a hard failure, but indicates drift from best practices)

**Artifacts:** Terminal output only (stdout/stderr). No files written.

---

### Layer 2: Behavioral Tests

**Purpose:** Verify that skills activate on the right user prompts and stay silent on negative controls.

**Current Status:** ⚠️ **Pending reconstruction (D-022/D-023).** Previous traces were LLM-generated circular ground truth (quality_score: null on all core skill traces; task_completed: false in baseline runs). They validated consistency, not correctness. Parker (Benchmark & Evaluation Engineer) is defining replacement quality ground truth from first principles.

**What it validates:**
- **Activation F1 score** (≥ 0.85): Does the skill activate on explicit/implicit/contextual triggers?
- **False positive rate** (≤ 0.05): Does it stay silent when it shouldn't activate?
- **Negative control ratio** (≥ 0.25): Are enough negative test cases present?
- **Tool invocation patterns**: Did the skill use expected tools and avoid forbidden commands?

**Test case structure** (`tests/behavioral/*/test-cases.jsonl`):
```jsonl
{
  "id": "cogworks-exp-001",
  "category": "explicit",
  "user_request": "Use /cogworks encode on these sources.",
  "should_activate": true,
  "expected_tools": [],
  "expected_commands": [],
  "forbidden_commands": [],
  "expected_files_modified": [],
  "expected_files_created": [],
  "notes": "Explicit /cogworks encode invocation should activate"
}
```

**Test categories:**
- `explicit`: Direct skill invocation (e.g., "/cogworks encode")
- `implicit`: Intent-based activation without naming the skill
- `contextual`: Workflow-based activation from context clues
- `negative_control`: Should NOT activate (e.g., "summarize this document")

**Scripts:**
```bash
# Scaffold test cases for a new skill
python3 tests/framework/scripts/cogworks-eval.py behavioral scaffold --skill cogworks-newskill

# Run trigger smoke tests (fast, checks invocation only)
bash scripts/run-trigger-smoke-tests.sh claude
bash scripts/run-trigger-smoke-tests.sh codex

# (Blocked) Run full behavioral evaluation
# python3 tests/framework/scripts/cogworks-eval.py behavioral run --skill-prefix cogworks-
```

**Trace structure** (JSON, stored under `tests/behavioral/*/traces/`):
- `trace_id`: Unique identifier
- `test_case_id`: Links to originating test case
- `timestamp`: ISO 8601 UTC
- `agent`: "claude" or "codex"
- `model_version`: e.g., "claude-sonnet-4-20250514"
- `skill_activated`: boolean
- `tools_used`: array of tool names
- `commands_run`: array of shell commands
- `files_modified`: array of paths
- `files_created`: array of paths
- `task_completed`: boolean
- `quality_score`: float (0.0-1.0) or null
- `notes`: human-readable explanation

**Artifacts:**
- `tests/behavioral/*/test-cases.jsonl` (test definitions, retained)
- `tests/behavioral/*/traces/*.json` (execution traces, deleted pending D-022)
- `tests/results/behavioral/*/summary.json` (evaluation results)

---

### Layer 3: Pipeline Benchmark (A/B)

**Purpose:** Full end-to-end `cogworks encode` comparison between Claude and Codex pipelines.

**Two modes:**
- **Offline mode** (default): Plumbing verification only. Uses hardcoded deterministic metrics. No real encoding runs. Winner is meaningless. Fast.
- **Real mode**: Runs actual encode pipelines. Produces **decision-grade** results. Slow and expensive.

**Guardrails** (both pipelines must pass to be eligible for winner selection):
- `structural_pass_rate >= 0.95`
- `activation_f1 >= 0.85`
- `false_positive_rate <= 0.05`
- `negative_control_ratio >= 0.25`

**Scripts:**
```bash
# Offline mode (plumbing check)
bash benchmarks/comparison/scripts/test-cogworks-pipeline.sh \
  --mode offline \
  --run-id ab-20260305-smoke1

# Real mode (decision-grade)
export COGWORKS_BENCH_CLAUDE_CMD="your-claude-runner --sources '{sources_path}' --out '{out_dir}'"
export COGWORKS_BENCH_CODEX_CMD="your-codex-runner --sources '{sources_path}' --out '{out_dir}'"

bash benchmarks/comparison/scripts/test-cogworks-pipeline.sh \
  --mode real \
  --run-id ab-20260305-real1

# Re-run after partial failure (requires --force)
bash benchmarks/comparison/scripts/test-cogworks-pipeline.sh \
  --mode real \
  --run-id ab-20260305-real1 \
  --force
```

**Artifacts:**
- `benchmarks/comparison/results/pipeline-benchmark/{run_id}/benchmark-summary.json`
- `benchmarks/comparison/results/pipeline-benchmark/{run_id}/benchmark-report.md`
- `benchmarks/comparison/results/pipeline-benchmark/{run_id}/quality-first-ranking.md`

**Metrics contract** (each runner must write `<out_dir>/metrics.json`):
```json
{
  "layer1_pass": true,
  "quality_score": 0.92,
  "activation_f1": 0.88,
  "false_positive_rate": 0.03,
  "negative_control_ratio": 0.30,
  "perturbation_success": 0.85,
  "runtime_sec": 487.2,
  "usage": {
    "total_tokens": 45230,
    "context_tokens": 12400
  },
  "failed": false
}
```

---

## 2. Test-First Development (TDD Workflow)

**Core workflow:** Red → Green → Refactor

### Red Phase (Write Failing Tests First)

1. **Define the behavior** before writing any implementation
2. **Write test cases** in `tests/behavioral/*/test-cases.jsonl`
3. **Freeze test bundle hash** to lock test surface:
   ```bash
   bash scripts/pin-test-bundle-hash.sh \
     tests/datasets/recursive-round/round-manifest.local.json
   ```
4. **Run tests** → they should fail (red state):
   ```bash
   bash scripts/test-generated-skill.sh --skill-path .claude/skills/my-skill
   ```

### Green Phase (Make Tests Pass)

1. **Implement the minimum** to pass tests
2. **Run deterministic checks**:
   ```bash
   bash scripts/validate-quality-gates.sh path/to/SKILL.md
   ```
3. **Run behavioral smoke tests**:
   ```bash
   bash scripts/run-trigger-smoke-tests.sh claude
   ```
4. **Verify pass** → green state

### Refactor Phase (Improve Without Breaking)

1. **Improve code quality** while keeping tests green
2. **Re-run full test suite** after each change
3. **Commit only when green**

---

## 3. Trace Capture Process

**Current Status:** Trace capture scripts have been removed (D-023). The previous capture process was circular (LLM-generated ground truth). Parker is defining replacement quality ground truth.

### Previous Trace Capture Workflow (Historical)

1. **Scaffold test cases** for a new skill:
   ```bash
   python3 tests/framework/scripts/cogworks-eval.py behavioral scaffold --skill my-skill
   ```

2. **Edit test cases** manually to define activation intent

3. **Capture traces** by running live agent sessions (REMOVED - was circular)

4. **Validate traces** against expected behavior

5. **Store traces** under `tests/behavioral/*/traces/`

### Trace Validation Criteria (To Be Re-established)

- Trace must link to a valid `test_case_id`
- Timestamp must be ISO 8601 UTC
- `skill_activated` must match `should_activate` from test case
- `quality_score` must be non-null for positive cases
- `task_completed` must be true for successful executions

**Freshness policy (to be implemented in D8):**
- **Warn** if any trace is >90 days old
- **Block** if any trace is >180 days old
- Freshness check runs as part of `tests/ci-gate-check.sh`

---

## 4. CI Gates

### Pre-Release CI Gate

**Script:** `bash tests/ci-gate-check.sh`

**What it runs:**

1. **Step 1/3: Quality gates (deterministic checks)**
   - Runs: `bash scripts/validate-quality-gates.sh`
   - Validates: All generated skills in `_generated-skills/`
   - Exit 0 on pass, exit 1 on fail

2. **Step 2/3: Behavioral trace coverage**
   - Checks: At least one trace per skill in `tests/behavioral/*/traces/`
   - **Currently fails**: Traces deleted pending D-022/D-023
   - Exit 1 if any skill has zero traces

3. **Step 3/3: Behavioral evaluation**
   - Runs: `python3 tests/framework/scripts/cogworks-eval.py behavioral run --skill-prefix cogworks-`
   - **Currently skipped**: Blocked on Step 2 failure
   - Exit 0 on pass (all metrics meet thresholds), exit 1 on fail

**Exit codes:**
- `0` = all gates passed
- `1` = at least one gate failed

**When it runs:**
- Before any release
- On pull requests to `main` that touch `skills/**`, `.claude/**`, `README.md`, `INSTALL.md`, or `LICENSE`
- Manually via `bash tests/ci-gate-check.sh`

**Artifacts:**
- Terminal output (stdout/stderr)
- Behavioral evaluation summaries (if Step 3 runs)

---

## 5. Freshness Policy

**Status:** Implementation pending (D8 - Hudson's mandate)

**Policy:**
- **90-day warning threshold:** Traces older than 90 days trigger a warning (exit code 0, but message printed)
- **180-day blocking threshold:** Traces older than 180 days cause CI gate failure (exit code 1)
- **Rationale:** Models update continuously. Traces older than 90 days have unknown validity. Traces older than 180 days are stale.

**Implementation location:**
- Freshness check to be added to `tests/framework/scripts/cogworks-eval.py` (behavioral evaluation module)
- Policy documentation: `tests/behavioral/refresh-policy.md` (to be created)

**Metadata required in traces:**
- `timestamp` field (ISO 8601 UTC)
- `model_version` field (e.g., "claude-sonnet-4-20250514")

**Enforcement:**
- CI gate (`tests/ci-gate-check.sh`) calls behavioral evaluation
- Behavioral evaluation checks trace timestamps before running evaluation
- Freshness check runs in Step 2 of CI gate (trace coverage check)

---

## 6. Avoiding Circular Testing (Independence from Model Under Test)

**Problem:** If the same LLM that generates skills also validates them, the validation is circular and can be overconfident.

**Solution:** Break the circularity by making validation independent.

### Layer 1 Independence (Deterministic Checks)

**Script:** `scripts/validate-quality-gates.sh`

**How it's independent:**
- **Zero LLM calls:** Uses only bash, grep, awk, wc
- **Structural checks only:** YAML syntax, field presence, heading markers, word counts
- **No semantic evaluation:** Doesn't judge quality, only structure
- **Runs offline:** No external API calls, no network required

**What it catches:**
- Missing frontmatter
- Malformed YAML
- Missing required fields
- Injection markers (security check)
- Insufficient content (word count threshold)

**What it doesn't catch:**
- Poor quality content
- Incorrect information
- Weak skill activation logic

### Layer 2 Independence (Behavioral Evaluation)

**Current Status:** Traces were LLM-generated → circular. Parker is replacing with first-principles ground truth (D-022).

**How ground truth should be independent:**
- **Human-labeled test cases:** Activation intent defined by humans, not LLMs
- **Deterministic trace validation:** Expected tools, commands, file patterns checked mechanically
- **External quality scoring:** Quality scores derived from independent benchmarks, not self-assessment

**What makes a trace circular:**
- ❌ LLM generates skill → same LLM validates skill → circular
- ❌ quality_score computed by the skill under test
- ❌ task_completed determined by the agent being tested

**What makes a trace independent:**
- ✅ Test cases written by humans before implementation
- ✅ Traces captured from live runs (observed behavior, not predicted)
- ✅ Quality scores derived from external benchmarks (Layer 3)
- ✅ Task completion judged by deterministic criteria (files created, commands run)

### Layer 3 Independence (Pipeline Benchmark)

**How it's independent:**
- **A/B comparison:** Claude pipeline vs Codex pipeline (cross-validation)
- **Fixed datasets:** Benchmarks run against frozen manifests
- **Separate evaluation harness:** Metrics computed by test framework, not the pipelines themselves
- **External quality ground truth:** Quality scores anchored to gold-standard references (when available)

---

## 7. Recursive Improvement Round (TDD-First)

**Purpose:** Apply TDD at the meta-level — improve the skill generation pipeline itself using test-first cycles.

**Canonical runbook:** `tests/datasets/recursive-round/README.md`

### Phase Sequence

A recursive round executes:

1. **`pre_round`**: Setup (e.g., git clean, env check)
2. **`generate`**: Generate initial skill from sources
3. **`improve`**: Apply improvement pass
4. **`regenerate`**: Regenerate skill with improvements
5. **Invariant checks**: Runtime/artifact validation
6. **Behavioral checks**: Layer 2 evaluation
7. **Optional benchmark**: Layer 3 A/B comparison (deep mode only)
8. **`post_round`**: Cleanup and artifact finalization

### Modes

| Mode | Runs Benchmark? | Metrics | Decision-Grade? | Speed |
|------|----------------|---------|-----------------|-------|
| `fast` | No | Layer 1 only | No | ~1 minute |
| `deep` + `--smoke-only` | Yes (offline metrics) | Hardcoded | No | ~5 minutes |
| `deep` (real) | Yes (real backends) | Real encoding runs | **Yes** | ~30 minutes |

### Commands

**Fast round (Layer 1 only):**
```bash
cp tests/datasets/recursive-round/round-manifest.example.json \
  tests/datasets/recursive-round/round-manifest.local.json

bash scripts/pin-test-bundle-hash.sh \
  tests/datasets/recursive-round/round-manifest.local.json

source scripts/recursive-env.example.sh

bash scripts/run-recursive-round.sh \
  --round-manifest tests/datasets/recursive-round/round-manifest.local.json \
  --mode fast \
  --run-id rr-20260305-fast1
```

**Deep smoke round (offline metrics):**
```bash
bash scripts/run-recursive-round.sh \
  --round-manifest tests/datasets/recursive-round/round-manifest.local.json \
  --mode deep \
  --smoke-only \
  --run-id rr-20260305-deep-smoke1
```

**Decision-grade deep round (real backends):**
```bash
export COGWORKS_RECURSIVE_BENCH_CLAUDE_REAL_CMD="<real claude benchmark command with {sources_path} and {out_dir}>"
export COGWORKS_RECURSIVE_BENCH_CODEX_REAL_CMD="<real codex benchmark command with {sources_path} and {out_dir}>"

export COGWORKS_BENCH_CLAUDE_CMD="bash scripts/recursive-bench.sh claude '{sources_path}' '{out_dir}'"
export COGWORKS_BENCH_CODEX_CMD="bash scripts/recursive-bench.sh codex '{sources_path}' '{out_dir}'"

bash scripts/run-recursive-round.sh \
  --round-manifest tests/datasets/recursive-round/round-manifest.local.json \
  --mode deep \
  --run-id rr-20260305-deep-real1
```

### Hook Commands

Hooks are defined in `round-manifest.local.json` and executed by `scripts/run-recursive-hook.sh`.

**Environment variables:**
- `COGWORKS_RECURSIVE_PRE_ROUND_CMD`
- `COGWORKS_RECURSIVE_GENERATE_CMD`
- `COGWORKS_RECURSIVE_IMPROVE_CMD`
- `COGWORKS_RECURSIVE_REGENERATE_CMD`
- `COGWORKS_RECURSIVE_POST_ROUND_CMD`

If a variable is unset, the phase is skipped with an informational message.

### Artifacts

Per-run outputs under `tests/results/meta-loop/<run-id>/`:
- `manifest-state.json`
- `round-manifest.json` (snapshot)
- `invariants-clean.json`
- `invariants-negative.json`
- `behavioral-claude/<timestamp>/summary.json`
- `behavioral-codex/<timestamp>/summary.json`
- `round-summary.json`
- `round-report.md`

Deep mode adds:
- `benchmarks/comparison/results/pipeline-benchmark/<run-id>/benchmark-summary.json`
- `benchmarks/comparison/results/pipeline-benchmark/<run-id>/benchmark-report.md`

---

## 8. Quick Reference Command Matrix

| Task | Command | Layer | LLM? | Cost |
|------|---------|-------|------|------|
| Validate all generated skills (deterministic) | `bash scripts/validate-quality-gates.sh` | 1 | No | Free |
| Validate specific skill (deterministic) | `bash scripts/validate-quality-gates.sh path/to/SKILL.md` | 1 | No | Free |
| Test generated skill (Layer 1) | `bash scripts/test-generated-skill.sh --skill-path .claude/skills/my-skill` | 1 | No | Free |
| Test framework meta-tests | `bash tests/run-black-box-tests.sh` | 1 | No | Free |
| Pre-release CI gate | `bash tests/ci-gate-check.sh` | 1+2 | No | Free |
| Scaffold behavioral test cases | `python3 tests/framework/scripts/cogworks-eval.py behavioral scaffold --skill my-skill` | 2 | No | Free |
| Trigger smoke tests (Claude) | `bash scripts/run-trigger-smoke-tests.sh claude` | 2 | Yes | Low |
| Trigger smoke tests (Codex) | `bash scripts/run-trigger-smoke-tests.sh codex` | 2 | Yes | Low |
| Pipeline benchmark (offline) | `bash benchmarks/comparison/scripts/test-cogworks-pipeline.sh --mode offline --run-id ab-20260305-smoke1` | 3 | No | Free |
| Pipeline benchmark (real) | `bash benchmarks/comparison/scripts/test-cogworks-pipeline.sh --mode real --run-id ab-20260305-real1` | 3 | Yes | High |
| Recursive round (fast) | `bash scripts/run-recursive-round.sh --round-manifest tests/datasets/recursive-round/round-manifest.local.json --mode fast --run-id rr-20260305-fast1` | 1 | No | Free |
| Recursive round (deep smoke) | `bash scripts/run-recursive-round.sh --round-manifest tests/datasets/recursive-round/round-manifest.local.json --mode deep --smoke-only --run-id rr-20260305-deep-smoke1` | 1+3 | No | Free |
| Recursive round (deep real) | `bash scripts/run-recursive-round.sh --round-manifest tests/datasets/recursive-round/round-manifest.local.json --mode deep --run-id rr-20260305-deep-real1` | 1+2+3 | Yes | Very High |
| Validate recursive docs consistency | `bash scripts/validate-recursive-docs.sh` | N/A | No | Free |
| Pin test bundle hash | `bash scripts/pin-test-bundle-hash.sh tests/datasets/recursive-round/round-manifest.local.json` | N/A | No | Free |

---

## 9. Decision Tree: Which Test Should I Run?

```
1. Did I change a generated skill?
   → Yes: Run `bash scripts/validate-quality-gates.sh path/to/SKILL.md`
   → No: Continue

2. Did I change the skill generation pipeline (cogworks-encode, cogworks-learn)?
   → Yes: Run `bash scripts/test-generated-skill.sh --skill-path <test-skill>`
   → No: Continue

3. Am I about to open a PR or cut a release?
   → Yes: Run `bash tests/ci-gate-check.sh`
   → No: Continue

4. Do I need decision-grade comparison between Claude and Codex pipelines?
   → Yes: Run Layer 3 benchmark in real mode (expensive, ~30 min)
   → No: Run Layer 3 benchmark in offline mode (fast plumbing check)

5. Am I implementing a TDD improvement cycle on the pipeline itself?
   → Yes: Run recursive round (fast → deep smoke → deep real)
   → No: You're probably done
```

---

## 10. Common Gotchas

1. **"Behavioral evaluation failed — traces missing"**
   - **Cause:** Traces were deleted (D-022/D-023)
   - **Solution:** Wait for Parker to define replacement quality ground truth. Do not regenerate with `cogworks-eval.py` — that recreates the circular problem.

2. **"Hash mismatch in test bundle"**
   - **Cause:** Test files changed after hash was pinned
   - **Solution:** Re-pin with `bash scripts/pin-test-bundle-hash.sh tests/datasets/recursive-round/round-manifest.local.json`

3. **"Pipeline benchmark reports winner but metrics are meaningless"**
   - **Cause:** Ran in offline mode (default)
   - **Solution:** Set real backend env vars and run in real mode

4. **"Deep round is non-decision-grade even though I ran without --smoke-only"**
   - **Cause:** Real backend env vars not set, or wrappers writing hardcoded metrics
   - **Solution:** Verify `COGWORKS_RECURSIVE_BENCH_CLAUDE_REAL_CMD` and `COGWORKS_RECURSIVE_BENCH_CODEX_REAL_CMD` point to actual backends

5. **"CI gate passes but I know the skill is broken"**
   - **Cause:** Layer 1 only checks structure, not correctness
   - **Solution:** Run Layer 2 behavioral tests (pending D-022 reconstruction) or Layer 3 benchmark

6. **"I changed a skill but the test still passes"**
   - **Cause:** Test is too coarse or not actually validating the behavior
   - **Solution:** Add a targeted test case in `tests/behavioral/*/test-cases.jsonl`

---

## 11. File Locations (Quick Reference)

| Path | Purpose |
|------|---------|
| `tests/ci-gate-check.sh` | Pre-release CI gate (Layer 1 + Layer 2) |
| `scripts/validate-quality-gates.sh` | Layer 1 deterministic checks |
| `scripts/test-generated-skill.sh` | Test a single generated skill (Layer 1) |
| `scripts/run-trigger-smoke-tests.sh` | Behavioral trigger smoke tests (Layer 2) |
| `tests/run-black-box-tests.sh` | Framework meta-tests (validates test harness) |
| `tests/framework/graders/deterministic-checks.sh` | Core deterministic grader |
| `tests/framework/scripts/cogworks-eval.py` | Behavioral evaluation CLI (blocked pending D-022) |
| `tests/behavioral/*/test-cases.jsonl` | Behavioral test case definitions (retained) |
| `tests/behavioral/*/traces/` | Execution traces (deleted pending D-022) |
| `tests/datasets/recursive-round/README.md` | Canonical recursive round runbook |
| `scripts/run-recursive-round.sh` | Recursive TDD improvement workflow |
| `scripts/pin-test-bundle-hash.sh` | Freeze test bundle hash (lock test surface) |
| `benchmarks/comparison/scripts/test-cogworks-pipeline.sh` | Layer 3 A/B benchmark |
| `benchmarks/comparison/results/pipeline-benchmark/` | Benchmark artifacts |

---

## 12. Prompt Template for Other Teams

Copy-paste this prompt to your team's AI agent to replicate this workflow:

```
You are the Test Engineer for our project. Your mandate:

1. Implement a three-layer testing pyramid:
   - Layer 1 (Deterministic): No LLM, structural checks only. Must run in <1 second. Break self-verification circularity.
   - Layer 2 (Behavioral): Activation tests against stored traces. Evaluation only (no LLM). Live capture mode available but expensive.
   - Layer 3 (Pipeline): Full end-to-end benchmark with A/B comparison. Two modes: offline (plumbing check) and real (decision-grade).

2. Apply test-first development:
   - Red phase: Write failing tests first
   - Green phase: Implement minimum to pass
   - Refactor phase: Improve without breaking
   - Lock test surface before implementing (use hash pinning)

3. Maintain independence from model under test:
   - Layer 1: Zero LLM calls, deterministic only
   - Layer 2: Human-labeled test cases, external quality scoring
   - Layer 3: A/B cross-validation, fixed datasets

4. Implement trace freshness policy:
   - Warn at 90 days
   - Block at 180 days
   - Traces older than 90 days have unknown validity

5. Create CI gates:
   - Pre-release gate runs Layer 1 + Layer 2
   - Exit 0 on pass, exit 1 on fail
   - Block on missing traces (with clear error message)

6. Support recursive TDD rounds:
   - Fast mode (Layer 1 only, ~1 min)
   - Deep smoke mode (offline metrics, ~5 min)
   - Deep real mode (decision-grade, ~30 min)

Your tools:
- bash for deterministic checks (no Python for Layer 1 — keep it simple)
- Python for behavioral evaluation harness (when traces exist)
- jq for JSON manipulation
- pytest or similar for framework meta-tests

Your constraints:
- Never use the model under test to validate itself
- Always provide clear error messages (humans must understand what failed and why)
- Keep Layer 1 fast (<1 second per skill)
- Document what each layer catches and what it doesn't

Your deliverables:
1. `scripts/validate-quality-gates.sh` (Layer 1, deterministic)
2. `tests/ci-gate-check.sh` (pre-release gate)
3. `tests/behavioral/refresh-policy.md` (freshness policy doc)
4. `tests/framework/scripts/eval-harness.py` (Layer 2 evaluation)
5. `scripts/run-benchmark.sh` (Layer 3 A/B comparison)
6. `tests/framework/README.md` (testing guide)

When in doubt, read `cogworks` testing docs:
- tests/framework/README.md
- tests/datasets/recursive-round/README.md
- TESTING.md
```

---

## 13. References

- **Canonical recursive round runbook:** `tests/datasets/recursive-round/README.md`
- **Test framework overview:** `tests/framework/README.md`
- **Pipeline benchmark datasets:** `benchmarks/comparison/datasets/pipeline-benchmark/README.md`
- **Pre-release CI gate:** `tests/ci-gate-check.sh`
- **Quality gates validator:** `scripts/validate-quality-gates.sh`
- **Black-box meta-tests:** `tests/run-black-box-tests.sh`
- **Team decisions:** `.squad/decisions.md`
- **Hudson's mandate:** `.squad/agents/hudson/charter.md`
- **Parker's mandate:** `.squad/agents/parker/charter.md` (defines behavioral trace replacement ground truth)

---

**END OF GUIDE**
