# Cogworks Testing Guide

This guide shows exactly how to test:

- The test framework itself
- The `cogworks-*` skills in this repository
- A newly generated skill created by the cogworks pipeline

It assumes no prior knowledge of this repo or toolkit.

**Separation of concerns**

- **Generated skill testing**: Use `/cogworks-test` and the unified CLI in `.claude/test-framework/scripts/cogworks-test-framework.py`.
- **Framework testing (meta-tests)**: Use `tests/run-black-box-tests.sh` and fixtures under `tests/test-data/`.

---

## Prerequisites

You need these installed locally:

- `python3`
- `jq`
- Python package `PyYAML`

Install on Ubuntu/Debian:

```bash
sudo apt-get install -y jq python3-pip
python3 -m pip install pyyaml
```

---

## Quick Start (Minimum Viable Check)

Run the framework’s black‑box meta tests:

```bash
bash tests/run-black-box-tests.sh
```

Run behavioral tests for repo skills:

```bash
python3 .claude/test-framework/scripts/cogworks-test-framework.py behavioral run \
  --skill-prefix cogworks-
```

---

## End‑to‑End: Test the Test Framework

This verifies that the framework is behaving as documented.

1. Run the black‑box test suite:

```bash
bash tests/run-black-box-tests.sh
```

2. Inspect the latest results if there are failures:

```bash
ls -t tests/results/ | head -1
```

3. Open a specific failure report:

```bash
cat tests/results/black-box-*/mvp-001-report.txt
```

---

## Assess the `cogworks-*` Skills in This Repo

Only `cogworks-*` skills are required to have behavioral tests in this repository.

### 1) Structural validation (Layer 1)

```bash
for s in .claude/skills/cogworks-*/; do
  bash .claude/test-framework/graders/deterministic-checks.sh "$s"
done
```

### 2) Semantic quality evaluation (Layer 2)

Run the skill validator for each:

```
/cogworks-test cogworks-encode
/cogworks-test cogworks-learn
/cogworks-test cogworks-test
```

Expected pass criteria:

- Weighted score >= 0.85
- No dimension score below 3

### 3) Behavioral activation tests (Layer 2.5)

Run the behavioral test runner:

```bash
python3 .claude/test-framework/scripts/cogworks-test-framework.py behavioral run \
  --skill-prefix cogworks-
```

Behavioral pass criteria:

- `activation_f1 >= 0.85`
- `false_positive_rate <= 0.05`
- `negative control ratio >= 0.25`
- no missing traces

### 4) Calibration gate (Layer 3 prerequisite)

If you have human + LLM grades:

```bash
python3 .claude/test-framework/scripts/cogworks-test-framework.py calibration run
```

If you do not have calibration data yet, skip the calibration checks until you have real human and LLM results.

---

## Test a Newly Generated Skill (User Workflow)

Assume the new skill slug is `my-skill`.

### 1) Generate the skill

Use the cogworks agent to build it.

### 2) Optional: Run Layer 1 and Layer 2 checks

```
/cogworks-test my-skill
```

### 3) Optional: Scaffold behavioral test cases

```bash
python3 .claude/test-framework/scripts/cogworks-test-framework.py behavioral scaffold --skill my-skill
```

This creates:

- `tests/behavioral/my-skill/test-cases.jsonl`

### 4) Optional: Capture traces

For each case ID in the JSONL, create a trace file (create the `traces/` directory if needed):

- `tests/behavioral/my-skill/traces/{case_id}.json`

Use the template:

- `.claude/test-framework/templates/behavioral-trace-template.json`

### 5) Optional: Run behavioral tests

```bash
python3 .claude/test-framework/scripts/cogworks-test-framework.py behavioral run --skill my-skill
```

### 6) Optional leakage audit (golden samples only)

If you promote the skill to a golden sample, run:

```bash
python3 .claude/test-framework/scripts/cogworks-test-framework.py leakage audit \
  --skill-dir tests/datasets/golden-samples/my-skill/expected-skill \
  --sources-dir tests/datasets/golden-samples/my-skill/sources
```

---

## Behavioral Test File Layout

Required structure:

```
tests/behavioral/
  {skill_slug}/
    test-cases.jsonl
    traces/
      {case_id}.json
```

Templates:

- `.claude/test-framework/templates/behavioral-test-case-template.jsonl`
- `.claude/test-framework/templates/behavioral-trace-template.json`

---

## Framework Meta‑Testing (Black‑Box Tests)

Run all framework tests:

```bash
bash tests/run-black-box-tests.sh
```

The suite reads:

- `tests/test-suite/mvp-test-cases.jsonl`

And uses fixtures in:

- `tests/test-data/`

Results are written to:

- `tests/results/black-box-YYYYMMDD-HHMMSS/`

---

## CI Behavior (Pre‑Release Validation)

CI runs:

- Structural checks for `cogworks-*` skills
- Behavioral tests for `cogworks-*` skills
- Calibration gate (skipped if calibration data is missing)

If you want CI to be strict, create real calibration data and remove the skip.

---

## Troubleshooting

Common issues and fixes:

- Deterministic checks fail due to missing `jq` or `PyYAML`.
  - Install prerequisites and re‑run.

- Behavioral tests fail due to missing traces.
  - Add traces for each case under `tests/behavioral/{skill}/traces/`.

- Calibration gate fails.
  - Generate human grades and LLM results, then re‑run summary and check.

- LLM quality scores are unexpectedly high or low.
  - Recalibrate using `tests/calibration/` and update rubrics if bias is detected.

---

## Where to Look for Details

- `.claude/test-framework/README.md`
- `.claude/skills/cogworks-test/SKILL.md`
- `tests/behavioral/README.md`
- `tests/run-black-box-tests.sh`

---

Last updated: 2026-02-19
