# IBM-Guided Hardening for `cogworks*` Skills

## Scope
- `skills/cogworks/SKILL.md`
- `skills/cogworks-encode/SKILL.md`
- `skills/cogworks-learn/SKILL.md`

## Summary
Apply IBM prompt-engineering best practices to the three core cogworks skill prompts by adding explicit prompt-security boundaries, staged handoff contracts, few-shot calibration examples for brittle judgment calls, and quantitative convergence criteria for validation loops.

## Decision-Complete Implementation

### 1) `skills/cogworks/SKILL.md`
- Normalize frontmatter description to trigger-first wording (`Use when ...`) while preserving explicit side-effect and invocation constraints.
- Add a required `Security Boundary` section defining:
  - trusted vs untrusted source classes,
  - delimiter protocol for untrusted text,
  - source-embedded instructions treated as data,
  - explicit user confirmation for high-risk/irreversible actions.
- Expand Workflow Step 1 (Gather Sources) with security preprocessing:
  - source trust classification,
  - `source_trust_report`,
  - `sanitized_source_blocks`.
- Add staged handoff artifacts to the workflow:
  - `source_inventory`, `cdr_registry`, `traceability_map`, `decision_skeleton`, `stage_validation_report`.
- Add short few-shot calibration exemplars for contradiction resolution and decision-rule boundaries.
- Add quantitative thresholds to validation/gates:
  - `cdr_mapping_rate=100%`, `unmapped_critical_distinctions=0`,
  - `decision_rules_with_boundary>=90%`, `citation_coverage>=95%`.
- Update success criteria to include security contract and artifact/metric compliance.

### 2) `skills/cogworks-encode/SKILL.md`
- Add explicit prompt-security section for source ingestion, using trusted/untrusted delimiting and data-only treatment of instruction-like source content.
- Require security outputs in Phase 1:
  - `source_trust_report`, `sanitized_source_blocks`.
- Add a `Stage Contracts` section with compact I/O schemas and blocking failure format.
- Add few-shot mini-calibration examples for:
  - conflict synthesis,
  - boundary conditions,
  - omission rationale quality.
- Add quantitative thresholds to self-verification:
  - `all_cdr_items_mapped=true`, `coverage_gate_uncovered=0`,
  - `decision_rules_with_trigger_action_boundary>=90%`,
  - `citation_minimum>=3`, `citation_coverage>=95%`.

### 3) `skills/cogworks-learn/SKILL.md`
- Normalize frontmatter description to trigger-first wording (`Use when ...`) while preserving current keyword coverage.
- Add `Security & Composability Boundary` section:
  - untrusted-content handling,
  - prohibition on tool-authority expansion from source text,
  - explicit deferral boundaries for adjacent skills.
- Add `Staged Generation Contract` section:
  - draft -> rewrite -> deterministic validation -> drift probe -> finalization,
  - required artifact output for each stage.
- Add few-shot examples showing:
  - vague -> explicit directive rewrite,
  - runtime-invalid -> runtime-safe contract example,
  - duplicated doctrine -> canonical placement.
- Add quantitative convergence thresholds:
  - `gate_pass_rate=100%`, `runtime_contract_violations=0`,
  - `canonical_placement_violations=0`, `drift_probe_pass>=3/3` for judgment-heavy domains.

## Validation
- Run deterministic validation scripts where available and summarize results.
- Run targeted grep checks for newly required sections/keywords to ensure edits landed.

## Assumptions
- No changes outside the three SKILL files and plan artifact.
- Keep existing intent; apply additive hardening and contract clarity.
