# Behavioral Delta Harness Spec

**Owner:** Parker (design + rubrics)  
**Implementor:** Hudson (execution + tooling)  
**Schema reference:** `tests/framework/QUALITY-SCHEMA.md`  
**Status:** Specification — not yet implemented

---

## 1. Purpose

This harness measures whether a skill improves agent behavior, by computing a behavioral delta:

```
behavioral_delta = mean(with_skill_scores) − mean(without_skill_scores)
```

Both score sets come from an independent judge model grading outputs from the same task, run twice — once with the skill active, once without. A positive delta is evidence the skill helps. A zero or negative delta is evidence it does not.

This is the only non-circular measurement available: the judge is never the model that generated the outputs it grades. See QUALITY-SCHEMA.md §2 and §5 for the rationale.

---

## 2. Inputs

The harness requires four inputs per evaluation run:

| Input | Source | Notes |
|---|---|---|
| `test_cases` | `tests/behavioral/<skill>/test-cases.jsonl` | Filter to `category: "quality"` or `category: "quality_gate"` |
| `skill_file` | `skills/<slug>/SKILL.md` | The skill being evaluated |
| `judge_prompt` | `tests/behavioral/<skill>/judge-prompt.md` | Rubric + scoring instructions |
| `judge_model` | Caller-supplied (CLI flag or config) | Must differ from generating model family |

### Test case fields used

From each JSONL record:
- `input` — the task description sent to the agent
- `ground_truth` — rubric text passed to the judge
- `evaluator_notes` — calibration guidance included in judge context

---

## 3. Startup Validation

Before running any cases, the harness must verify:

1. **Cross-model independence** — the judge model family must differ from the generating model family. Allowed pairings are defined in QUALITY-SCHEMA.md §5. If the constraint is violated, the harness must exit with a non-zero status and print the offending pairing. It must not record any `quality` object from a violating run.

2. **Minimum test cases** — at least 5 quality/quality_gate cases must be present. If fewer exist, exit with `insufficient_data` status; do not attempt to grade.

3. **Judge prompt present** — `tests/behavioral/<skill>/judge-prompt.md` must exist and be non-empty.

---

## 4. Step 1 — Baseline Run (Without Skill)

For each test case:

1. Configure the agent with the skill **not installed** (no SKILL.md in context).
2. Send `input` to the agent.
3. Capture the full output text as `baseline_output`.
4. `baseline_output` is ephemeral — it is **not** written back to the test case file or stored as ground truth.

---

## 5. Step 2 — With-Skill Run

For each test case:

1. Configure the agent with the skill installed (SKILL.md in context or via `npx skills add`).
2. Send the identical `input` to the agent.
3. Capture the full output text as `skill_output`.
4. `skill_output` is ephemeral — it is **not** written back to the test case file or stored as ground truth.

Both runs must use the same generating model, same temperature, and same system prompt (excluding the skill). Any difference in configuration other than skill presence is a confound.

---

## 6. Step 3 — Judge Both Outputs

For each test case, make two judge calls (can be parallelized):

**Judge call structure:**

```
System:    <system block from judge-prompt.md>
User:      Original request: <input>
           Ground truth rubric: <ground_truth>
           Evaluator notes: <evaluator_notes>
           Output to evaluate: <baseline_output | skill_output>
```

Each judge call returns a JSON object matching the judge output schema defined in the skill's `judge-prompt.md`:

```json
{
  "verdict": "pass | fail | uncertain",
  "confidence": 0.0–1.0,
  "dimension_scores": { "<dimension>": 0.0–1.0 },
  "reasoning": "string — must cite specific text from the output",
  "failure_mode": null | "string"
}
```

Store as `baseline_judgment` and `skill_judgment` for each case.

---

## 7. Step 4 — Compute Delta

Per case:
```
case_delta = skill_judgment.confidence − baseline_judgment.confidence
```

Across all cases:
```
behavioral_delta = mean(case_delta over all N cases)
judge_confidence  = mean(skill_judgment.confidence over all N cases)
```

Compute per-dimension scores:
```
dimension_scores[d] = mean(skill_judgment.dimension_scores[d]) − mean(baseline_judgment.dimension_scores[d])
```

Compute 95% confidence interval on `behavioral_delta`:
- Use bootstrap resampling (≥ 1000 resamples) when `sample_size < 30`.
- Use paired t-test CI when `sample_size ≥ 30`.
- Record the method used in the `notes` field of the quality object.

---

## 8. Step 5 — Store Result

Write one result JSON per evaluation run. The top-level structure is defined in QUALITY-SCHEMA.md §3.

**Required fields to populate:**

```json
{
  "quality_score": null,
  "quality": {
    "schema_version": "1.0",
    "judge_model": "<fully-qualified judge model identifier>",
    "judge_confidence": <mean skill_judgment.confidence>,
    "behavioral_delta": <computed delta>,
    "dimension_scores": { "<dimension>": <delta per dimension> },
    "sample_size": <N>,
    "confidence_interval_95": [<lower>, <upper>],
    "verdict": "pass | fail | insufficient_data",
    "graded_at": "<ISO 8601 UTC>",
    "cases_passed": <int>,
    "cases_failed": <int>,
    "notes": "<CI method + any anomalies>"
  }
}
```

`cases_passed` = cases where `case_delta > 0`.  
`cases_failed` = cases where `case_delta ≤ 0`.

**Suggested output path:** `tests/behavioral/<skill>/eval-result.json`

---

## 9. Pass / Fail Thresholds

All four conditions must hold for `verdict = "pass"`:

| Condition | Threshold |
|---|---|
| `behavioral_delta` | ≥ 0.20 |
| `judge_confidence` | ≥ 0.70 |
| `sample_size` | ≥ 5 |
| `confidence_interval_95` lower bound | > 0 |

If `sample_size < 5`: `verdict = "insufficient_data"` (not `fail`).  
If all four hold: `verdict = "pass"`.  
Otherwise: `verdict = "fail"`.

---

## 10. What NOT To Do

**Prohibited actions — any of these invalidates the result:**

- ❌ Do not write `baseline_output` or `skill_output` back to `test-cases.jsonl` as `ground_truth` or `expected_output`. This recreates the circular dependency that D-022 deleted.
- ❌ Do not use the same model family as both generator and judge. Same-family grading reintroduces the rationalization bias the harness is designed to eliminate.
- ❌ Do not populate `quality_score` — it is deprecated. Populate `quality` only.
- ❌ Do not record a `quality` object from a run where cross-model independence was violated.
- ❌ Do not substitute qualitative descriptions ("the output looks good") for judge JSON. All grading must go through the structured judge call.

---

## 11. Boundary: Hudson's Scope, Not Parker's

Parker's responsibilities (complete):
- Harness specification (this document)
- Quality schema (`tests/framework/QUALITY-SCHEMA.md`)
- Judge prompts (`tests/behavioral/<skill>/judge-prompt.md`)
- Test case rubrics (`ground_truth`, `evaluator_notes` in JSONL)
- Pass/fail thresholds

Hudson's responsibilities (to implement):
- CLI or script that executes Steps 1–5 above
- Agent runner that can toggle skill presence (with/without)
- Judge API caller with retry and timeout handling
- Bootstrap/t-test CI calculation
- Result serialization to `eval-result.json`
- Startup validation (cross-model check, minimum case count, judge prompt existence)
- CI integration (exit codes, summary output)

Parker does not implement the harness. Hudson does not modify judge prompts or rubrics without Parker's review.
