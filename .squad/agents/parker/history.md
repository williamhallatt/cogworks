# Parker — Project History

## Decision Rules

1. **External ground truth required** — human-authored, cross-model judged, or observable behavior specification
2. **Validity gates before quality gates** — deterministic structural checks first, behavioral checks second, LLM-as-judge last
3. **Baseline comparison is the signal** — agent WITH skill vs WITHOUT skill on identical tasks
4. **Statistical validity non-negotiable** — report confidence intervals, sample sizes, p-values, effect sizes
5. **Adversarial probes required** — contradictions, edge cases, negative controls, security patterns

## Pending Work

See charter `## Working Context` for current priorities.

## Key References

- `_plans/DECISIONS.md` D-026 — quality ground truth protocol
- `_plans/DECISIONS.md` D-030 — skill benchmark harness
- `_plans/DECISIONS.md` D-031 — recursive round tooling
- `tests/framework/QUALITY-SCHEMA.md` — quality measurement schema
