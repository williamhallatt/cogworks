audited_through: 2026-03-04

# Decision Log

This file is the agent context surface for `_plans/`. Load this for settled decisions.
Check `_plans/*.md` (root only) for active in-flight plans.

Stop reading at `## Historical Record` — entries below that heading are implementation
archives with no ongoing behavioral implication; do not load them.

---

## [D-001] Layered testing framework for cogworks skills
- **Date**: 2026-02-14 | **Status**: implemented
- Adopted a three-layer testing framework (deterministic → LLM-as-judge → human review) for validating generated skills, with an 85% weighted pass threshold.
- Layered approach was chosen to minimize cost: structural failures caught by cheap bash checks before expensive LLM evaluation.
- The `cogworks-test` skill and supporting infrastructure under `tests/` are the current implementation; the `cogworks-test` skill is not an active baseline dependency in the default workflow.

## [D-002] Agent-specific invocation syntax in all user-facing docs
- **Date**: 2026-02-24 | **Status**: implemented
- All user-facing invocation examples show both Claude Code (`/`) and Codex CLI (`$`) prefixes; section headings used as identifiers were left unchanged.
- Different agents use different slash-command prefixes; documenting both prevents silent failures for Codex CLI users.
- Files affected: `README.md`, `skills/cogworks/README.md`, `INSTALL.md`, `skills/cogworks-learn/reference.md`.

## [D-004] Decision log structure (this file)
- **Date**: 2026-02-25 | **Status**: implemented, updated 2026-03-04
- `_plans/DECISIONS.md` is the agent context surface; active plans stay at `_plans/` root; completed plans are deleted after the close ritual. The close ritual is atomic: extract decision → delete plan file → update `audited_through`. The `_plans/archive/` directory was removed 2026-03-04 — it carried no agent behavioral value and was pure context overhead.
- An append-only `_plans/` with no closure mechanism caused completed plans to sit alongside active ones, giving fresh agent sessions false authority over stale implementation steps.
- Any plan with a date later than `audited_through` is implicitly unreviewed; agents must not treat it as settled.

## [D-005] Apply prompt-engineering principles to the cogworks toolchain
- **Date**: 2026-02-15 | **Status**: implemented
- Applied 20 audit findings across cogworks.md, cogworks-encode, cogworks-learn, cogworks-test: positive framing, quality modifiers, self-verification gates, context-before-rule, and exemplar anchors.
- The toolchain was not following the prompting principles it encodes; inconsistency degrades the quality of every generated skill.
- Implementation cascade order is orchestrator → encode → learn → test; changes to cogworks.md propagate through the entire pipeline.

## [D-009] Testing infrastructure: Layer 1 hardening + Layer 2 LLM-as-judge
- **Date**: 2026-02-15 | **Status**: implemented
- Added 4 Layer 1 checks (heading deduplication, name format, substantiveness, citation format); meta-tests slimmed to 8; Layer 2 LLM-as-judge implemented in cogworks-test; automated validation wired into cogworks.md workflow.
- Layer 1 was the only implemented layer; testing needed to catch semantic failures, not just structural ones.

## [D-011] Skill authoring and behavioral hardening
- **Date**: 2026-02-21 | **Status**: implemented
- Hardened behavioral contracts with `activation_source`, `tool_events`, `order_assertions`; added multi-turn/isolated harness support; added trigger smoke suite; added deterministic warning for workflow-summary leakage in `description`.
- CSO (clear, specific, outcome-oriented) description discipline is now a codified standard in cogworks-learn.

## [D-012] Recursive TDD round automation
- **Date**: 2026-02-20 | **Status**: implemented
- Added `scripts/run-recursive-round.sh` orchestrator and `scripts/hash-test-bundle.sh`; immutable core limited to runtime/tool-contract correctness and artifact schema; test bundles frozen at round boundaries via manifest + hash.
- Benchmark offline mode is smoke signal only; rounds become decision-grade only when `ranking_eligible=true` in manifest.

## [D-014] IBM-guided security hardening for core cogworks skill prompts
- **Date**: 2026-02-26 | **Status**: implemented
- Added explicit untrusted-source security boundaries, staged handoff contracts, calibration mini-examples, and quantitative convergence thresholds to `skills/cogworks/SKILL.md`, `skills/cogworks-encode/SKILL.md`, and `skills/cogworks-learn/SKILL.md`.
- Required artifacts: `{source_trust_report}`, `{sanitized_source_blocks}`, `{stage_validation_report}`; blocking thresholds codified for mapping/citation/boundary coverage.

## [D-015] Structural rationale probe and tacit knowledge accounting
- **Date**: 2026-02-26 | **Status**: implemented
- Added a Phase 4 mechanism probe step to `cogworks-encode/reference.md` and a Phase 8 tacit knowledge accounting directive; added `{tacit_knowledge_boundary}` as a required stage artifact in `cogworks/SKILL.md`.
- The mechanism probe is a named step, not optional: an unanswered probe is a boundary conditions defect. The Tacit Knowledge Boundary section is required for judgment-heavy domains; absence is a fidelity defect.

## [D-019] Agent risk analysis of cogworks
- **Date**: 2026-03-03 | **Status**: implemented
- Conducted a 10-dimension agent risk analysis of the cogworks repo; findings documented in `docs/cogworks-agent-risk-analysis.md`.
- Key risk surfaces: self-referential circular edits (agents editing skills they're running under), prompt injection via untrusted source content, context overflow during 8-phase synthesis, and cross-agent invocation syntax gaps (D1–D10 covered).

---

## Historical Record

*Agents: stop here. Entries below are implementation records with no ongoing behavioral implication.*

## [D-003] Docs and roadmap realignment
- **Date**: 2026-02-20 | **Status**: implemented
- Removed completed roadmap items; aligned docs to deterministic-checks-first baseline; removed stale `cogworks-test` and Layer 2/3 baseline claims from active docs.

## [D-006] Behavioral capture via per-pipeline adapter scripts
- **Date**: 2026-02-20 | **Status**: implemented
- Capture commands are explicit env config (`COGWORKS_BEHAVIORAL_CLAUDE_CAPTURE_CMD`, `COGWORKS_BEHAVIORAL_CODEX_CAPTURE_CMD`), not hardcoded defaults; raw trace contract requires `activated`, `tools_used`, `commands`, `files_modified`, `files_created`.

## [D-007] A/B pipeline reproducibility hardening
- **Date**: 2026-02-20 | **Status**: implemented
- Added `run-claude-benchmark.sh`, `run-codex-benchmark.sh`, `run-pipeline-benchmark.sh`; default mode `--mode offline`; real mode requires `COGWORKS_BENCH_CLAUDE_CMD` / `COGWORKS_BENCH_CODEX_CMD`.

## [D-008] Superpowers-informed test infrastructure improvements
- **Date**: 2026-02-20 | **Status**: implemented
- Added strict provenance mode (`--strict-provenance`), dual-pipeline capture scaffolding, no-premature-execution behavioral scenarios.

## [D-010] Update checker packaging
- **Date**: 2026-02-20 | **Status**: implemented
- Added `scripts/check-cogworks-updates.sh` as a convenience utility; update checking is separate from installer core behavior.

## [D-013] Behavioral capture open decision resolved
- **Date**: 2026-02-20 | **Status**: implemented
- Capture command templates must support `{skill_slug}`, `{case_id}`, `{case_json_path}`, `{raw_trace_path}` placeholders; commands remain per-user env config.

## [D-016] Comparator benchmark harness
- **Date**: 2026-03-03 | **Status**: implemented
- Added comparator-aware benchmark scaffolding under `benchmarks/comparison/`; shared model/budget fairness controls; `quality-first-ranking.md` report generation.

## [D-017] Protocol-run benchmark for workflow-style comparator toolkits
- **Date**: 2026-03-03 | **Status**: implemented
- Added `run-protocol-benchmark.sh`, `run-protocol-case.sh`, `score-generated-skill.py`, `summarize-protocol-benchmark.py`; protocol-run is the authoritative comparator path for workflow-style generators.

## [D-018] Isolated comparison benchmark workspace
- **Date**: 2026-03-03 | **Status**: implemented
- Relocated comparison benchmarking assets to `benchmarks/comparison/`; updated all integrations; expanded dataset with `pb-005` through `pb-010` and `protocol-hard-v2.json`.
