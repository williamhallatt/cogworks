# API Auth Release Benchmark

This dataset captures the repeatable decision-grade benchmark shape used during
the March 8, 2026 release-validation work.

## What It Measures

The benchmark compares:

- `candidate_a`: a fully generated API-auth skill reference from a validated
  live Copilot sub-agent build
- `candidate_b`: a weaker single-source baseline context

Both candidates run through the same live Copilot CLI adapter under fixed
conditions. The adapter forbids outside knowledge and asks the model to mark
unsupported policies explicitly, so the measured difference comes from encoded
skill content rather than hidden background knowledge.

## Files

- `cases.jsonl`: maintained benchmark cases
- `baseline-context.md`: the weaker single-source comparison context
- `../../scripts/skill-benchmark-copilot-context-runner.py`: live Copilot CLI
  adapter for these cases
- `examples/benchmark-summary.20260308.json`: preserved decision-grade summary
- `examples/benchmark-report.20260308.md`: preserved human-readable report

## Candidate A Context

Use a validated generated-skill reference, for example the preserved live
artifact at:

```text
tests/agentic-smoke/examples/copilot-cli-release-api-auth-smoke-20260308/skill-output/reference.md
```

You can also substitute a fresh validated live run as long as the generator
model, Copilot surface, and dataset stay fixed.

## Example Command

```bash
python3 scripts/run-skill-benchmark.py \
  --benchmark-id api-auth-skill-release-20260308 \
  --cases-file tests/test-data/skill-benchmark-api-auth-release/cases.jsonl \
  --candidate-a generated-skill \
  --candidate-a-command "python3 scripts/skill-benchmark-copilot-context-runner.py --context-file tests/agentic-smoke/examples/copilot-cli-release-api-auth-smoke-20260308/skill-output/reference.md" \
  --candidate-b single-source-baseline \
  --candidate-b-command "python3 scripts/skill-benchmark-copilot-context-runner.py --context-file tests/test-data/skill-benchmark-api-auth-release/baseline-context.md" \
  --model claude-opus-4.6 \
  --judge-model claude-opus-4.6 \
  --agent-surface copilot-cli \
  --trials 5 \
  --work-root /tmp/cogworks-skill-benchmark \
  --out-dir /tmp/cogworks-skill-benchmark/out
```

## Notes

- The current release validator expects `judge_model` to be non-empty even for
  deterministic-only case sets, so the example command passes one explicitly.
- A release-grade claim still requires a positive lower bound on the 95%
  bootstrap CI, not just `decision_eligible = true`.
