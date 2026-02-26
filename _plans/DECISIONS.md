audited_through: 2026-02-26

## [D-015] Structural rationale probe and tacit knowledge accounting
- **Date**: 2026-02-26 | **Source**: [2026-02-26-gap-analysis-structural-rationale-tacit-knowledge.md](archive/2026-02-26-gap-analysis-structural-rationale-tacit-knowledge.md) | **Status**: implemented
- Added a Phase 4 mechanism probe step to `cogworks-encode/reference.md` and a Phase 8 tacit knowledge accounting directive; strengthened the Tacit Knowledge Boundary conditional section with explicit content requirements; added `{tacit_knowledge_boundary}` as a required stage artifact in `cogworks/SKILL.md`.
- Synthesis phase was probing boundary conditions structurally (via the pattern template) but not explicitly directing the synthesizer to ask the mechanism question ("what assumption, if false, makes this wrong?"). No phase produced explicit epistemic accounting of tacit knowledge gaps, leaving skill consumers without calibration signals for where to verify rather than trust.
- The mechanism probe is a named step, not optional: an unanswered probe is a boundary conditions defect. The Tacit Knowledge Boundary section is required (not optional) for judgment-heavy domains; absence is a fidelity defect.

# Decision Log

This file is the agent context surface for `_plans/`. Load this for settled decisions.
Check `_plans/*.md` (root only) for active in-flight plans. Treat `_plans/archive/` as
human-readable history only.

---

## [D-001] Layered testing framework for cogworks skills
- **Date**: 2026-02-14 | **Source**: [14-02-2026-eval-based-skill-evaluation-impl-summary.md](archive/14-02-2026-eval-based-skill-evaluation-impl-summary.md) | **Status**: implemented
- Adopted a three-layer testing framework (deterministic → LLM-as-judge → human review) for validating generated skills, with an 85% weighted pass threshold.
- Layered approach was chosen to minimize cost: structural failures caught by cheap bash checks before expensive LLM evaluation.
- The `cogworks-test` skill and supporting infrastructure under `tests/` are the current implementation; the `cogworks-test` skill is not an active baseline dependency in the default workflow.

## [D-002] Agent-specific invocation syntax in all user-facing docs
- **Date**: 2026-02-24 | **Source**: [2026-02-24-agent-specific-invocation-syntax-docs.md](archive/2026-02-24-agent-specific-invocation-syntax-docs.md) | **Status**: implemented
- All user-facing invocation examples now show both Claude Code (`/`) and Codex CLI (`$`) prefixes; section headings used as identifiers were left unchanged.
- Different agents use different slash-command prefixes; documenting both prevents silent failures for Codex CLI users.
- Files affected: `README.md`, `skills/cogworks/README.md`, `INSTALL.md`, `skills/cogworks-learn/reference.md`.

## [D-003] Docs and roadmap realignment
- **Date**: 2026-02-20 | **Source**: [20-02-2026-docs-roadmap-realignment-plan.md](archive/20-02-2026-docs-roadmap-realignment-plan.md) | **Status**: implemented
- Removed completed roadmap items; aligned docs to deterministic-checks-first baseline; removed stale `cogworks-test` and Layer 2/3 baseline claims from active docs.
- Roadmap should only carry outstanding work; completed items create false authority for agents reading the file.
- Constraints still in force: `_plans/` and `_sources/` historical artifacts are left untouched.

## [D-004] Decision log + plan archive structure (this file)
- **Date**: 2026-02-25 | **Source**: (plan accepted 2026-02-25, not yet filed in archive) | **Status**: implemented
- `_plans/DECISIONS.md` is the agent context surface; completed plans move to `_plans/archive/`; active plans stay at `_plans/` root. The close ritual is atomic: extract decision → move file → update `audited_through`.
- An append-only `_plans/` with no closure mechanism caused completed plans to sit alongside active ones, giving fresh agent sessions false authority over stale implementation steps.
- Any plan with a date later than `audited_through` is implicitly unreviewed; agents must not treat it as settled.

## [D-005] Apply prompt-engineering principles to the cogworks toolchain
- **Date**: 2026-02-15 | **Source**: [15-02-2026-advanced-prompt-improvements-to-toolchain.md](archive/15-02-2026-advanced-prompt-improvements-to-toolchain.md) | **Status**: implemented
- Applied 20 audit findings across cogworks.md, cogworks-encode, cogworks-learn, cogworks-test: positive framing, quality modifiers, self-verification gates, context-before-rule, and exemplar anchors.
- The toolchain was not following the prompting principles it encodes; inconsistency degrades the quality of every generated skill.
- Implementation cascade order is orchestrator → encode → learn → test; changes to cogworks.md propagate through the entire pipeline.

## [D-006] Behavioral capture via per-pipeline adapter scripts
- **Date**: 2026-02-20 | **Source**: [20-02-2026-behavioral-capture-command-implementation.md](archive/20-02-2026-behavioral-capture-command-implementation.md) | **Status**: implemented
- Capture commands are explicit env config (`COGWORKS_BEHAVIORAL_CLAUDE_CAPTURE_CMD`, `COGWORKS_BEHAVIORAL_CODEX_CAPTURE_CMD`), not hardcoded defaults; per-pipeline adapter scripts handle the wrapper contract.
- No canonical end-to-end harness existed that could reliably execute a case and emit raw JSON to `{raw_trace_path}` across environments.
- Raw trace contract requires `activated`, `tools_used`, `commands`, `files_modified`, `files_created`; additional fields optional.

## [D-007] A/B pipeline reproducibility hardening
- **Date**: 2026-02-20 | **Source**: [20-02-2026-ab-pipeline-reproducibility-plan.md](archive/20-02-2026-ab-pipeline-reproducibility-plan.md) | **Status**: implemented
- Added `run-claude-benchmark.sh`, `run-codex-benchmark.sh`, and `run-pipeline-benchmark.sh` orchestrator; default mode is `--mode offline` with deterministic fixture metrics.
- Previously referenced scripts didn't exist, blocking reproducible A/B workflow execution for users and CI.
- Real mode requires `COGWORKS_BENCH_CLAUDE_CMD` / `COGWORKS_BENCH_CODEX_CMD`; standardized outputs are `benchmark-summary.json` and `benchmark-report.md`.

## [D-008] Superpowers-informed test infrastructure improvements
- **Date**: 2026-02-20 | **Source**: [20-02-2026-superpowers-test-infra-incorporation-plan.md](archive/20-02-2026-superpowers-test-infra-incorporation-plan.md) | **Status**: implemented
- Added strict provenance mode (`--strict-provenance`), dual-pipeline capture scaffolding, and no-premature-execution behavioral scenarios; existing normalized JSON trace contract preserved.
- Superpowers research surfaced high-signal gaps in behavioral evidence quality; changes adopt lessons without replacing existing architecture.
- Provider-specific grep/parsing is not adopted as primary evaluator logic.

## [D-009] Testing infrastructure improvements (Layer 1 hardening + Layer 2 LLM-as-judge)
- **Date**: 2026-02-15 | **Source**: [15-02-206-test-improvement-plan.md](archive/15-02-206-test-improvement-plan.md) | **Status**: implemented
- Added 4 new Layer 1 checks (heading deduplication, name format, substantiveness, citation format); slimmed meta-tests from 16 to 8; implemented Layer 2 LLM-as-judge in cogworks-test; wired automated validation into cogworks.md workflow.
- Layer 1 was the only implemented layer; testing needed to catch semantic failures, not just structural ones.

## [D-010] Update checker packaging
- **Date**: 2026-02-20 | **Source**: [2026-02-20-cogworks-update-checker-packaging-plan.md](archive/2026-02-20-cogworks-update-checker-packaging-plan.md) | **Status**: implemented
- Added `scripts/check-cogworks-updates.sh` as a convenience utility packaged in release artifacts with a post-install hint; update checking is separate from installer core behavior.
- Users had no built-in mechanism to check for updates after installation.

## [D-011] Superpowers-informed skill authoring and behavioral hardening
- **Date**: 2026-02-21 | **Source**: [2026-02-21-superpowers-hardening-plan.md](archive/2026-02-21-superpowers-hardening-plan.md) | **Status**: implemented
- Hardened behavioral contracts with `activation_source`, `tool_events`, `order_assertions`; added multi-turn/isolated harness support; added trigger smoke suite; added deterministic warning for workflow-summary leakage in `description`.
- High-signal practices from superpowers research revealed gaps in activation provenance, trigger robustness, and skill description discipline.
- CSO (clear, specific, outcome-oriented) description discipline is now a codified standard in cogworks-learn.

## [D-012] Recursive TDD round automation
- **Date**: 2026-02-20 | **Source**: [20-02-2026-recursive-tdd-round-automation-plan.md](archive/20-02-2026-recursive-tdd-round-automation-plan.md) | **Status**: implemented
- Added `scripts/run-recursive-round.sh` orchestrator and `scripts/hash-test-bundle.sh`; immutable core limited to runtime/tool-contract correctness and artifact schema; test bundles frozen at round boundaries via manifest + hash.
- Cogworks self-improvement needed automation with evolution freedom in pipeline/skill content while gating promotion on outcome metrics, without template-enforced structural constraints.
- Benchmark offline mode is smoke signal only; rounds become decision-grade only when `ranking_eligible=true` in manifest.

## [D-013] Behavioral capture open decision resolved
- **Date**: 2026-02-20 | **Source**: [20-02-2026-behavioral-capture-open-decision.md](archive/20-02-2026-behavioral-capture-open-decision.md) | **Status**: implemented
- Concrete capture command implementations for both pipelines provided; commands remain per-user env config, not in-repo defaults.
- The framework contract and refresh runner existed but no canonical harness could emit raw JSON to `{raw_trace_path}` reliably across environments.
- Each capture command template must support `{skill_slug}`, `{case_id}`, `{case_json_path}`, `{raw_trace_path}` placeholders.

## [D-014] IBM-guided hardening for core cogworks skill prompts
- **Date**: 2026-02-26 | **Source**: [2026-02-26-ibm-guided-hardening-cogworks-skills.md](archive/2026-02-26-ibm-guided-hardening-cogworks-skills.md) | **Status**: implemented
- Added explicit untrusted-source security boundaries, staged handoff contracts, calibration mini-examples, and quantitative convergence thresholds to `skills/cogworks/SKILL.md`, `skills/cogworks-encode/SKILL.md`, and `skills/cogworks-learn/SKILL.md`.
- The core pipeline prompts were strong on fidelity gates but under-specified on injection-safe ingestion semantics and measurable convergence criteria, creating avoidable drift/security risk in judgment-heavy flows.
- New required artifacts now include trust/sanitization and stage validation reports (`{source_trust_report}`, `{sanitized_source_blocks}`, `{stage_validation_report}`), with blocking thresholds codified for mapping/citation/boundary coverage.
