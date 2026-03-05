# Quality Score Schema

## 1. Why `quality_score` Was Null

Every behavioral trace contains a top-level `quality_score` field that has always been `null`. This was not an oversight in the schema but an artefact of the original trace-generation approach: traces were produced by having the LLM grade its own outputs, creating a circular dependency where the generator and the judge were the same model. Decision D-022 deleted those traces entirely. Because no non-circular measurement existed, `quality_score` was never defined. This document closes that gap.

---

## 2. The New Definition — Behavioral Delta

**Quality = behavioral delta.**

Specifically:

```
behavioral_delta = mean(with_skill_scores) − mean(without_skill_scores)
```

where scores are produced by running **identical tasks** against two agent configurations — one with the skill active, one without — and grading both sets of outputs with a **different model** (the judge). A positive delta means the skill improves agent performance. A negative or near-zero delta means it does not.

This is the only signal that cannot be circular: the judge is never the model that generated the outputs being graded.

---

## 3. Schema

The `quality_score` top-level field is deprecated (see §6). The canonical field is `quality`:

```json
{
  "quality_score": null,
  "quality": {
    "schema_version": "1.0",
    "judge_model": "string — model used to grade outputs (must differ from generating model)",
    "judge_confidence": "float 0-1 — average confidence across graded cases",
    "behavioral_delta": "float -1 to 1 — mean(with_skill_scores) - mean(without_skill_scores). Positive = skill helps.",
    "dimension_scores": {
      "<dimension_name>": "float 0-1 — per-rubric-criterion score, averaged across cases"
    },
    "sample_size": "int — number of test cases graded",
    "confidence_interval_95": "[float, float] — 95% CI on behavioral_delta",
    "verdict": "pass|fail|insufficient_data",
    "graded_at": "ISO 8601 UTC timestamp",
    "cases_passed": "int",
    "cases_failed": "int",
    "notes": "string or null"
  }
}
```

### Field definitions

| Field | Type | Description |
|---|---|---|
| `schema_version` | string | Schema version; currently `"1.0"` |
| `judge_model` | string | Fully-qualified model identifier used as judge (e.g. `"gpt-4o-2024-11-20"`) |
| `judge_confidence` | float 0–1 | Mean confidence the judge reported across all graded cases |
| `behavioral_delta` | float −1–1 | Primary quality signal: with-skill minus without-skill mean score |
| `dimension_scores` | object | Per-rubric-criterion scores (0–1), averaged across cases |
| `sample_size` | int | Number of test cases graded |
| `confidence_interval_95` | [float, float] | 95% bootstrap or analytic CI on `behavioral_delta` |
| `verdict` | enum | `pass`, `fail`, or `insufficient_data` |
| `graded_at` | string | ISO 8601 UTC timestamp of grading run |
| `cases_passed` | int | Cases where with-skill score exceeded without-skill score |
| `cases_failed` | int | Cases where with-skill score did not exceed without-skill score |
| `notes` | string \| null | Optional free-text annotation |

---

## 4. Pass / Fail Thresholds

All four conditions must hold for a `pass` verdict:

| Condition | Threshold | Rationale |
|---|---|---|
| `behavioral_delta` | ≥ 0.20 | Skill must improve agent performance by at least 20 percentage points |
| `judge_confidence` | ≥ 0.70 | Low-confidence verdicts are not reliable enough to count |
| `sample_size` | ≥ 5 | Fewer than 5 cases → `insufficient_data`, not `fail` |
| `confidence_interval_95` lower bound | > 0 | CI must not straddle zero — see §7 |

If `sample_size < 5`, set `verdict = "insufficient_data"` regardless of other values.

If all four conditions hold → `verdict = "pass"`.

Otherwise → `verdict = "fail"`.

---

## 5. Cross-Model Independence Rule

The judge model **must** be from a different model family than the generating model. Same-family grading reintroduces circularity.

| Generating model family | Allowed judge families |
|---|---|
| Claude (Anthropic) | GPT (OpenAI), Gemini (Google) |
| GPT (OpenAI) | Claude (Anthropic), Gemini (Google) |
| Gemini (Google) | Claude (Anthropic), GPT (OpenAI) |

**Prohibited pairings** (examples):
- Generator `claude-3-5-sonnet` → Judge `claude-3-opus` ❌
- Generator `gpt-4o` → Judge `gpt-4-turbo` ❌
- Generator `gemini-1.5-pro` → Judge `gemini-flash` ❌

The harness must enforce this constraint at runtime and refuse to record a `quality` object that violates it.

---

## 6. Migration Note

The top-level `quality_score` field is **deprecated**. It will remain `null` in all existing traces until those traces are regenerated with the new evaluation harness. Do not populate `quality_score`; populate the `quality` object instead. Tooling that reads `quality_score` should be updated to read `quality.behavioral_delta` or `quality.verdict`.

---

## 7. Statistical Validity Note

A pass/fail verdict without uncertainty quantification is not a result.

`behavioral_delta` is a mean over a small sample. Without a confidence interval, a delta of 0.22 over 5 cases and a delta of 0.22 over 500 cases are indistinguishable — but only one of them is evidence. The 95% CI lower bound requirement (`> 0`) encodes the minimum burden of proof: the improvement must be distinguishable from zero at the 95% confidence level. If the CI includes zero, the measurement is consistent with the skill having no effect, and `pass` is not warranted regardless of the point estimate.

Use bootstrapping (≥ 1000 resamples) or a paired t-test CI depending on sample size and score distribution. Document the method used in `notes`.
