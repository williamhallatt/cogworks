> **Triage verdict (2026-03-13):** ACCEPT WITH REVISIONS  
> Issue 1 (decision skeleton ownership) already landed in role-profiles.json — document as decided.  
> Issue 2 (Copilot adapter) HIGH PRIORITY — 4 missing sections needed (~6-8 hours).  
> Issue 3 (tool consolidation) MEDIUM PRIORITY — deprecate run-agentic-quality-compare.py (~3-4 hours).

# Dallas: Pipeline Solutions for Three Ownership Gaps

**Author:** Dallas (Pipeline Engineer)  
**Date:** 2026-03-05  
**Status:** Proposed Solutions  
**Scope:** Three specification ownership gaps in the agentic pipeline

---

## Issue 1: Decision Skeleton Ownership Gap

### Current State

The Decision Skeleton is arguably the most important intermediate artifact in the pipeline:
- **SKILL.md** (lines 165-173) specifies its extraction and format (5-7 entries with trigger, options, right call, failure mode, boundary).
- **role-profiles.json** does not assign it to any role.
- **agentic-runtime.md** does not specify when it happens or who owns it.
- **claude-adapter.md** does not include it in coordinator prompting guidance.
- The smoke run evidence shows `decision-skeleton.json` existing in the `skill-packaging` stage output, implying the composer creates it — but this is implicit, not specified.

This creates a specification gap: the artifact exists, but its ownership, creation trigger, and quality gate are ambiguous.

### Proposed Solution

**Assign ownership to `composer` role in `skill-packaging` stage.**

#### 1. Update `role-profiles.json`

Modify the `composer` profile's `required_outputs` to explicitly include:
```json
"required_outputs": [
  "skill-packaging/decision-skeleton.json",  // ADD THIS
  "skill-packaging/composition-notes.md",
  "skill-packaging/stage-status.json",
  "{skill_path}/SKILL.md",
  "{skill_path}/reference.md",
  "{skill_path}/metadata.json"
]
```

#### 2. Formalize Decision Skeleton Creation Trigger in `agentic-runtime.md`

Add explicit entry under "Stage ownership" table:

| Stage | Owner | Required inputs | Required outputs |
|---|---|---|---|
| `skill-packaging` | `composer` | synthesis, CDR, metadata defaults | **`decision-skeleton.json`** (5-7 entries), packaged skill files at `{skill_path}` |

Then add under the stage descriptions:

**Decision Skeleton Format (Required)**

Before packaging the final skill, the composer must extract and record the Decision Skeleton as `skill-packaging/decision-skeleton.json`:

- **Trigger:** Synthesized content is ready for packaging; identify the 5-7 most important design decisions the synthesis reveals.
- **Required fields per entry:**
  - `decision_id` — unique kebab-case identifier (e.g., "auth-model-choice")
  - `trigger` — what prompted this decision?
  - `options_considered` — array of at least 2 alternatives
  - `right_call` — which option the synthesis recommends and why
  - `failure_mode` — what goes wrong if the right call is ignored?
  - `boundary` — what nuance or qualification limits this decision's scope?
  - `source_citations` — array of source IDs or synthesis section references

- **Quality gate:** Require minimum 5 entries. If fewer than 5 distinct decision-level distinctions emerge, escalate to the coordinator as a blocking issue: the synthesis may be too sparse or the sources too similar to justify agentic path processing.

- **Placement:** Write to `skill-packaging/decision-skeleton.json` before writing final skill files. Make this a blocking pre-condition for `composer` status = `pass`.

#### 3. Update `SKILL.md` Step 2 (Extract The Decision Skeleton And Review)

Clarify responsibility:

**Before presenting synthesis for review, the composer extracts the Decision Skeleton.**

For each of the 5-7 most important decisions the synthesis reveals, capture:
- **Trigger**
- **Options**
- **Right call**
- **Failure mode**
- **Boundary / implied nuance**

**Quality gate:** If fewer than 5 decision entries emerge, the composer must stop and report this as a blocking issue to the coordinator. A thin skeleton signals either insufficient source diversity or scope that is too narrow for agentic pipeline investment.

#### 4. Update `claude-adapter.md` Coordinator Prompting

Add to the "Coordinator UI Discipline" section:

**Decision Skeleton Handoff**

Before handing off synthesis to the composer, the coordinator must confirm that the synthesizer's output contains enough distinct decision-level material to populate 5-7 skeleton entries. If the skeleton emerges as fewer than 5 entries after composition, the validator must flag this and recommend narrowing scope or adding richer sources before the run completes. The decision skeleton gates the final `pass` status for the `skill-packaging` stage.

#### 5. Update `copilot-adapter.md` Equivalent

Add to the "Summary Contract" section:

```text
Each agentic run must produce a non-empty decision-skeleton.json with 5-7 entries.
If the skeleton emerges sparse (<5 entries), the run is incomplete even if all other
gates pass. Escalate to the user as a blocking issue.
```

### Rationale

- **Single source of truth:** Role-profiles.json becomes the authoritative binding between stages and artifacts.
- **Clear trigger:** "Before packaging the final skill" is unambiguous; it happens after synthesis, before final skill file assembly.
- **Measurable quality gate:** "5-7 entries minimum" is concrete and deterministic — no subjective judgment needed.
- **Prevents degenerate synthesis:** A skeleton with <5 distinct decisions is a red flag for source problems, not a sign of success.

---

## Issue 2: Copilot Adapter Completion

### Current State

**copilot-adapter.md** is appropriately minimal but lacks implementation detail:
- Does not explain how to detect native subagent capability at runtime.
- Does not specify what happens if `inherit-session-model` fails or is unavailable.
- Does not clarify how inline bindings resolve (`skills/cogworks/role-profiles.json#composer` — what does this reference mean operationally?).
- Does not provide fallback behavior specification.

A contributor debugging a failed Copilot CLI agentic run would need to read smoke run artifacts to understand why a stage failed or fell back to single-agent mode.

### Proposed Solution

Add four new sections to `copilot-adapter.md`:

#### 1. Runtime Capability Detection

Add new section after "Adapter Defaults":

```markdown
## Capability Detection at Runtime

Before dispatching the first specialist stage, the coordinator must detect whether
Copilot CLI supports native subagents:

1. **Check for the `task` tool:** Attempt to dispatch a trivial test task (read a small file,
   report status) to confirm that `task` tool is available and responsive. This is the
   primary signal for native subagent support.

2. **Record the detection result:** Set `execution_adapter` to:
   - `native-subagents` if `task` tool succeeds
   - `single-agent-fallback` if `task` tool is unavailable or times out
   
   Record this decision in `run-manifest.json` under `execution_adapter` **before** any
   specialist dispatch.

3. **Never assume availability:** Copilot CLI surface capability is not guaranteed across all
   user instances. Always perform runtime detection; do not hard-code the assumption.

4. **Document the result:** In the coordinator's progress narration, briefly state which path
   was activated:
   - "Dispatching with native subagents (task tool detected)"
   - "Falling back to single-agent mode (task tool unavailable)"
   
   This makes the execution path transparent for debugging.
```

#### 2. `inherit-session-model` Behavior and Fallback

Add new section after "Model Policy":

```markdown
## Model Policy Fallback — `inherit-session-model`

Copilot CLI specialist prompts cannot pin specific models (unlike Claude with `pinned-haiku`
or `pinned-sonnet`). The `model_policy` for all specialist bindings on Copilot is always
`inherit-session-model`.

### What "inherit-session-model" means

The specialist agent receives the same model context as the current Copilot session. The user
may be running Claude 3.5 Sonnet, Claude 3 Opus, or another supported model. The specialist
does not override this choice; it inherits the session model.

### What happens if model inheritance fails

Fallback scenarios:

1. **Session has no model context:** Copilot CLI will use its platform default. Record this
   in `dispatch-manifest.json` under the specialist's `model_policy_actual` field (if the
   manifest schema supports it) or in `stage-status.json` under `warnings`.

2. **Specialist tool requests exceed session model's capability:** The specialist may emit
   an error if tool use or context size limits are exceeded. Route this back to the
   coordinator as a blocking issue. Do not silently degrade to fallback processing.

3. **Session model is unavailable mid-run:** Copilot CLI will halt the stage. Record the
   failure in `stage-status.json` and stop the run. This is a platform-level failure, not
   a pipeline failure; inform the user of the platform issue.

### Recording model policy decisions

In `dispatch-manifest.json`, for each specialist dispatch, record:
- `model_policy: "inherit-session-model"`
- `model_policy_actual: "<model name or 'unknown'>"` (optional; only if detected at runtime)
- `model_policy_fallback: "<reason if fallback occurred>"` (optional)

Example dispatch entry:
```json
{
  "stage": "synthesis",
  "role": "synthesizer",
  "model_policy": "inherit-session-model",
  "model_policy_actual": "claude-3-5-sonnet",
  "model_policy_fallback": null,
  "status": "pass"
}
```
```

#### 3. Inline Binding Resolution

Add new section after "Canonical Role Bindings":

```markdown
## Inline Binding Resolution — What `skills/cogworks/role-profiles.json#composer` Means

On Copilot CLI, specialist roles are bound to inline role definitions embedded in `role-profiles.json`.
The binding ref `skills/cogworks/role-profiles.json#composer` means:

1. **Load the role-profiles.json file** from the cogworks skill directory.
2. **Extract the object in `profiles[]` with `profile_id: "composer"`.**
3. **Use the `purpose`, `boundaries`, `context_discipline`, and `quality_bar` fields** from that
   profile as the specialist agent's inline prompt instructions.
4. **Append the stage-specific coordinator prompt** (which defines the actual work for this stage).

### How inline resolution happens at runtime

1. The coordinator reads `role-profiles.json` when the run starts.
2. For each specialist stage, the coordinator:
   - Locates the matching profile by `profile_id`
   - Reads the profile's `purpose` and `quality_bar`
   - Merges these with the stage-specific prompt into a combined specialist prompt
   - Dispatches that combined prompt to the specialist via the `task` tool
   - Records `binding_type: "copilot-inline-prompt"` and `binding_ref: "skills/cogworks/role-profiles.json#{profile_id}"` in `dispatch-manifest.json`

### Why inline binding instead of separate agent files?

- **Portability:** Copilot CLI does not support `.copilot/agents/` files (unlike Claude's `.claude/agents/`).
- **Single source of truth:** Both Claude and Copilot read the same `role-profiles.json` for role definitions.
- **No duplication:** No separate file needed; the profile object is the specification.

### Recording the resolution in dispatch-manifest

Each dispatch entry must record:
```json
{
  "stage": "skill-packaging",
  "role": "composer",
  "profile_id": "composer",
  "binding_type": "copilot-inline-prompt",
  "binding_ref": "skills/cogworks/role-profiles.json#composer",
  "model_policy": "inherit-session-model",
  ...
}
```

This makes it clear that the specialist was instantiated from the inline role definition, not from
a separate agent file.
```

#### 4. Fallback Behavior Specification

Add new section after "Dispatch Rules":

```markdown
## Fallback Behavior — Single-Agent Mode

If native subagent capability is not detected (or fails at runtime), the coordinator must
degrade to single-agent mode gracefully:

### Degraded Mode Behavior

1. **Continue in coordinator role:** The coordinator executes all five stages sequentially
   within a single Copilot CLI conversation.

2. **Stage boundaries become logical:** Each stage is represented as a clear prompt boundary
   and output section. The coordinator must:
   - State which stage is beginning (e.g., "Now entering: synthesis")
   - Request the stage output in the required format (`synthesis.md`, `cdr-registry.md`, etc.)
   - Verify the stage completed before moving to the next

3. **Artifact generation:** The coordinator is responsible for writing all `stage-status.json`
   files and intermediate artifacts, not specialist stages. Record this in `dispatch-manifest.json`:
   ```json
   {
     "stage": "synthesis",
     "role": "synthesizer",
     "binding_type": "degraded-inline-prompt",
     "binding_ref": "none",
     "execution_mode": "degraded-single-agent",
     "status": "pass"
   }
   ```

4. **Retry policy:** Single-agent mode uses the same retry policy as native subagent mode.
   If a stage fails, the coordinator may retry once. If the same stage fails twice, stop and
   surface the issue.

5. **Runtime documentation:** In `run-manifest.json`, explicitly record:
   ```json
   {
     "execution_adapter": "single-agent-fallback",
     "execution_mode": "degraded-single-agent",
     "specialist_profile_source": "inline-fallback"
   }
   ```

### When Fallback Occurs

Fallback is triggered when:
- Initial capability detection finds no `task` tool
- First specialist dispatch to `task` tool fails
- Platform explicitly rejects subagent dispatch

**Never silently use fallback.** Always record it explicitly in both the coordinator's narration
and in run artifacts so debugging is transparent.

### Recovery from Fallback

Once fallback is triggered, the run continues in degraded mode. There is no "switch back to
native subagents" in mid-run — consistency is more important than optimization. If the user
wants native subagent execution, they must restart on a Copilot CLI instance that supports it.
```

### Rationale

- **Runtime detection is explicit:** No black-box assumptions; the coordinator detects capability and records it.
- **Failure modes are clear:** Each section explains what happens when things break, not just the happy path.
- **Debugging transparency:** A future contributor can read these sections and understand why a fallback occurred without needing smoke run artifacts.
- **Inline binding semantics:** Clarifies that `#composer` is a reference into the JSON structure, not a magical symbol.

---

## Issue 3: Comparison Tooling Consolidation

### Current State

**Two parallel comparison systems with overlapping output:**

1. **`run-skill-benchmark.py`** (748 lines)
   - Paired candidate comparison harness
   - Supports arbitrary candidate commands
   - Generates `benchmark-summary.json`, `benchmark-report.md`, `benchmark-results.json`
   - Bootstrap confidence intervals, statistical significance, cost/safety metrics
   - Designed for surface-neutral benchmarking (any agent, any skill)
   - Production-ready code quality

2. **`run-agentic-quality-compare.py`** (636 lines)
   - Hardcodes 3 test cases from `tests/behavioral/cogworks-encode`
   - Hardcodes legacy vs agentic comparison
   - Requires Codex CLI for judging
   - Generates `benchmark-summary.json`, `benchmark-report.md` (same format as above)
   - Overlap: Both generate the same output files; same judgment schema
   - Was built while `run-skill-benchmark.py` was still in pilot — premature duplication

### Problem Statement

- **Maintenance burden:** Two scripts doing similar work with overlapping output formats.
- **Tool confusion:** Both are "benchmark" or "comparison" scripts; which should a user run?
- **Hardcoded specificity:** One script locks the comparison to exactly 3 cases and 2 engines; the other is general-purpose.
- **Counterintuitive design:** The general-purpose harness (`run-skill-benchmark.py`) is more complex (748 lines) than the specific case (`run-agentic-quality-compare.py` at 636 lines). This is backwards — specific cases should be configs on the general harness, not separate scripts.

### Proposed Solution

**Deprecate `run-agentic-quality-compare.py` and consolidate its use case into `run-skill-benchmark.py` as a benchmark dataset + configuration.**

#### 1. Create Benchmark Dataset for Agentic Quality Comparison

Create a new file: `tests/datasets/agentic-quality-comparison/benchmark-cases.jsonl`

This file defines the 3 hardcoded cases from `run-agentic-quality-compare.py` in the standard benchmark case format that `run-skill-benchmark.py` expects:

```json
{
  "case_id": "cogworks-encode-d8-001",
  "category": "multi-source-synthesis",
  "user_request": "...",
  "expected_output_type": "skill",
  "ground_truth": "...",
  "notes": "Baseline multi-source synthesis case"
}
```

This dataset is portable and can be updated independently from the harness.

#### 2. Extend `run-skill-benchmark.py` Configuration

Add optional CLI arguments to `run-skill-benchmark.py`:

```bash
python3 run-skill-benchmark.py \
  --candidate-a-cmd "python3 cogworks encode --engine legacy" \
  --candidate-b-cmd "python3 cogworks encode --engine agentic" \
  --cases tests/datasets/agentic-quality-comparison/benchmark-cases.jsonl \
  --judge-model codex \
  --out-dir tests/results/agentic-quality-20260305
```

This makes the agentic comparison a **dataset + configuration choice**, not a separate script.

#### 3. Deprecate `run-agentic-quality-compare.py`

Update the script header to mark it as deprecated:

```python
#!/usr/bin/env python3
"""[DEPRECATED] Run a minimal cross-model quality comparison for the agentic cogworks path.

⚠️  DEPRECATED: Use run-skill-benchmark.py with the agentic-quality-comparison dataset instead.

  python3 run-skill-benchmark.py \
    --candidate-a-cmd "python3 cogworks encode --engine legacy" \
    --candidate-b-cmd "python3 cogworks encode --engine agentic" \
    --cases tests/datasets/agentic-quality-comparison/benchmark-cases.jsonl \
    --judge-model codex \
    --out-dir <output-dir>

This script remains for backward compatibility but will be removed in cogworks v5.0.

---

[Original docstring below, kept for reference]
Generator: Claude Code for both legacy and agentic runs
Judge: Codex CLI with a structured JSON schema
Outputs: benchmark-summary.json, benchmark-report.md
"""
```

Add a prominent warning at startup:

```python
if __name__ == "__main__":
    import warnings
    warnings.warn(
        "run-agentic-quality-compare.py is deprecated. Use run-skill-benchmark.py "
        "with --cases tests/datasets/agentic-quality-comparison/benchmark-cases.jsonl instead.",
        DeprecationWarning,
        stacklevel=2
    )
    # ... rest of script
```

#### 4. Document the Transition in TESTING.md

Add a section to `TESTING.md`:

```markdown
### Agentic Engine Quality Comparison

To benchmark agentic vs legacy engines, use `run-skill-benchmark.py` with the agentic comparison dataset:

```bash
python3 scripts/run-skill-benchmark.py \
  --candidate-a-cmd "python3 cogworks encode --engine legacy" \
  --candidate-b-cmd "python3 cogworks encode --engine agentic" \
  --cases tests/datasets/agentic-quality-comparison/benchmark-cases.jsonl \
  --judge-model codex \
  --out-dir tests/results/agentic-quality-$(date +%Y%m%dT%H%M%SZ)
```

The output is `benchmark-summary.json` (machine-readable results) and `benchmark-report.md` (human-readable report).

**Note:** `run-agentic-quality-compare.py` is deprecated in favor of this dataset-driven approach. Both scripts currently produce identical output formats, but the consolidated approach reduces maintenance burden and supports arbitrary candidate comparisons.
```

#### 5. Update Comparison Tooling Manifest (if exists)

If there is any documentation or manifest listing comparison tools (e.g., a README in `scripts/`), add a note:

```markdown
## Benchmark and Comparison Tools

| Tool | Purpose | Status | Notes |
|------|---------|--------|-------|
| `run-skill-benchmark.py` | General-purpose paired candidate benchmarking | Active | Use for all skill comparisons; supports arbitrary candidates and judge models |
| `run-agentic-quality-compare.py` | Agentic vs legacy engine comparison (hardcoded 3 cases) | **Deprecated** | Use `run-skill-benchmark.py` with `tests/datasets/agentic-quality-comparison/benchmark-cases.jsonl` instead |
| `compare-engine-performance.py` | Extract metrics from legacy vs agentic run artifacts | Active | Post-run analysis tool; complements benchmark harness |
```

### Rationale

- **Single source of truth:** `run-skill-benchmark.py` is the canonical comparison harness; specific comparisons are datasets.
- **Reduces code duplication:** No need to maintain two scripts with overlapping logic.
- **Improves scalability:** New comparisons (e.g., "agentic on Codex" or "legacy on Claude 3 Haiku") are datasets, not new scripts.
- **Supports experimentation:** A researcher can easily test new case sets or judge models without modifying code.
- **Honest deprecation:** The old script remains available during a grace period but is marked as deprecated, not deleted. Users get a clear migration path.

---

## Implementation Priority

1. **Issue 1 (Decision Skeleton)** — Highest priority. It fixes the most important intermediate artifact's ownership gap. Changes are surgical and isolated to four files.

2. **Issue 2 (Copilot Adapter)** — High priority. It removes ambiguity for the next contributor trying to debug a failed Copilot run. Changes are additive (new sections); no existing text needs editing.

3. **Issue 3 (Comparison Tooling)** — Medium priority. It improves maintainability but does not block pipeline operation. Can be done incrementally: dataset first, then deprecation notice, then removal in a future release.

---

## Summary

| Issue | Root Cause | Proposed Solution | Effort |
|-------|-----------|-------------------|--------|
| 1. Decision Skeleton Ownership | Specification gap; no formal owner | Assign to composer; add to role-profiles.json and stage specs | 4 surgical edits |
| 2. Copilot Adapter Underspecified | Missing runtime detail; debugging requires smoke artifacts | Add 4 new sections (capability detection, model policy, inline binding, fallback) | ~200 lines of documentation |
| 3. Comparison Tool Duplication | Parallel scripts with overlapping output | Consolidate into `run-skill-benchmark.py` via dataset + config; deprecate the specific script | ~100 lines of changes + dataset file |

All three solutions preserve backward compatibility and add no new runtime dependencies.
