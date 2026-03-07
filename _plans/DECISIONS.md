---
audited_through: 2026-03-07
---

# Architectural Decisions

Settled decisions for the cogworks project. Agents load this file for context;
see `_plans/archive/` for historical plans.

## [D-033] Default agent retrieval is restricted to canonical instruction surfaces; research, history, and generated artifacts are non-default

- **Date:** 2026-03-07 | **By:** William (owner)
- **Status:** Accepted
- **Decision:** Agents working in this repository must treat only the following as default retrieval surfaces unless the task explicitly calls for deeper context: `AGENTS.md`, top-level product docs (`README.md`, `TESTING.md`, `CONTRIBUTIONS.md`, `INSTALL.md`), `_plans/DECISIONS.md`, active `_plans/*.md`, and directly relevant canonical files under `skills/**`, `.claude/agents/**`, and `evals/**`. The following are non-default and must not be loaded opportunistically: `.github/agents/**`, `.squad/**`, `_plans/archive/**`, `_sources/**`, `.cogworks-runs/**`, `tmp-agentic-output/**`, `tests/results/**`, `tests/test-data/**`, and `tests/datasets/golden-samples/**`.
- **Rationale:** The 2026-03-07 repository-wide context audit found that the repo has multiple high-authority but non-canonical surfaces: a large Copilot auto-loaded Squad instruction file, duplicate decision ledgers, tracked generated run artifacts, production-shaped generated skills outside `skills/`, and a mixed-authority research corpus under `_sources/`. Without a hard default retrieval boundary, agents can waste context budget or act on the wrong source of truth.
- **Operational implication:** Default retrieval now follows an allowlist model. Research corpora, Squad memory, archived plans, run artifacts, and realistic fixtures remain valid repository assets, but only when a task explicitly requires them. When these surfaces are consulted, agents must treat them as scoped reference material rather than repo-wide policy.
- **Audit artifact:** `docs/ai-context-retrieval-risk-audit-2026-03-07.md`
- **Scope:** `AGENTS.md`, `_plans/DECISIONS.md`, `docs/ai-context-retrieval-risk-audit-2026-03-07.md`, `_plans/archive/2026-03-07-ai-context-retrieval-risk-audit.md`

## [D-034] Context-hygiene cleanup marks non-canonical surfaces and defaults live smoke output to disposable paths

- **Date:** 2026-03-07 | **By:** William (owner)
- **Status:** Accepted
- **Decision:** The repository now enforces the default retrieval policy in live docs, not just in the decision record. `AGENTS.md` now carries the canonical allowlist for default loading. `TESTING.md` now recognizes the current skill-benchmark pilot harness under `evals/` and distinguishes it from the still-reconstructing broader behavioral harness. Live smoke docs now prefer disposable output roots outside the repository. High-risk non-canonical surfaces (`.github/agents/`, `.squad/`, `_sources/`, `.cogworks-runs/`, `tmp-agentic-output/`, `tests/test-data/`, and `tests/datasets/golden-samples/`) now contain explicit warning markers or READMEs that tell humans and agents not to treat them as default instruction sources.
- **Rationale:** Policy that exists only in a decision file still leaves first-touch retrieval vulnerable. The audit showed that the repo's highest-risk surfaces were dangerous precisely because they looked canonical when opened directly. Marking those surfaces in place reduces wrong-authority retrieval without deleting useful historical evidence or test fixtures.
- **Operational implication:** Future smoke runs and benchmark runs should default to disposable output roots, and any preserved in-repo artifacts should be treated as deliberate examples, not ambient scratch state. Historical handoff material no longer belongs in active `_plans/`.
- **Scope:** `.gitignore`, `AGENTS.md`, `TESTING.md`, `tests/agentic-smoke/README.md`, `.github/agents/squad.agent.md`, `.squad/decisions.md`, `.squad/identity/now.md`, `.squad/README.md`, `_sources/README.md`, `.cogworks-runs/README.md`, `tmp-agentic-output/README.md`, `tests/test-data/README.md`, `tests/datasets/golden-samples/README.md`, `docs/testing-workflow-guide.md`, `docs/cogworks-agent-risk-analysis.md`, `_plans/archive/2026-03-06-agentic-v2-next-session.md`, `_plans/archive/2026-03-07-context-hygiene-cleanup.md`

## [D-029] Agentic runtime generalized to canonical role specs with Claude and Copilot CLI adapters

- **Date:** 2026-03-07 | **By:** William (owner)
- **Status:** Accepted
- **Decision:** The agentic runtime contract is generalized from a Claude-specific schema to a surface-neutral model with `execution_surface`, `execution_adapter`, `execution_mode`, and `specialist_profile_source`. Canonical role definitions now live in `skills/cogworks/role-profiles.json`, Claude role-agent files under `.claude/agents/` are derived bindings rather than the source of truth, and GitHub Copilot CLI is added as a first-class adapter using inline bindings from the same canonical role specs. Native-subagent runs must emit a generalized `dispatch-manifest.json` recording `profile_id`, `binding_type`, `binding_ref`, `model_policy`, dispatch modes, tool scope, and status for each specialist stage.
- **Rationale:** The earlier runtime borrowed Squad-style control-plane ideas but still encoded too much Claude-specific execution detail in the core contract. That made Copilot support look like an afterthought and left the repo without a single authoritative definition of role ownership, model policy, and dispatch evidence. Canonical role specs plus adapter-specific bindings keep the shared stage graph intact while making capability differences explicit instead of implicit.
- **Surface policy:** Claude Code may pin cheaper or deeper specialist models through generated agent files when native subagents are available. Copilot CLI must not claim per-role model pinning unless the surface proves it; its default native binding policy is `inherit-session-model`, and it must honestly fall back to `single-agent-fallback` when no real spawn primitive exists.
- **Live proof (Copilot CLI):** Squad validated a Copilot CLI agentic smoke run on 2026-03-07 — run root `.cogworks-runs/api-auth-smoke-copilot-smoke/`, 50/50 validator checks passed, `execution_adapter = native-subagents`, `model_policy = inherit-session-model`. `.claude/agents/` confirmed as shared agent registration source for both surfaces.
- **Scope:** `skills/cogworks/SKILL.md`, `skills/cogworks/agentic-runtime.md`, `skills/cogworks/claude-adapter.md`, `skills/cogworks/copilot-adapter.md`, `skills/cogworks/role-profiles.json`, `.claude/agents/cogworks-*.md`, `scripts/render-agentic-role-bindings.py`, `scripts/validate-agentic-run.sh`, `scripts/run-agentic-quality-compare.py`, `scripts/compare-engine-performance.py`, `scripts/test-agentic-contract.sh`, `README.md`, `skills/cogworks/README.md`, `TESTING.md`, `tests/agentic-smoke/README.md`, `_plans/archive/2026-03-07-copilot-cli-agentic-adapter.md`.

## [D-030] Skill evaluation benchmark isolated to skill-vs-skill efficacy with separate activation diagnostics

- **Date:** 2026-03-07 | **By:** William (owner)
- **Status:** Accepted
- **Decision:** Objective comparison of agent skills is now defined as a paired benchmark where the model, agent surface, tools, sandbox, task cases, and graders are held constant and only the skill differs. The primary score is task efficacy after invocation; activation quality is measured separately as its own scorecard. The benchmark must prefer deterministic trace/state checks, use cross-model judges only for residual qualitative criteria, and report repeated-trial uncertainty rather than single-run point estimates.
- **Rationale:** Previous repo guidance correctly rejected circular self-grading, but it still left open a key attribution problem: if model, runtime, and skill all move at once, the result is not a skill benchmark. A clean intervention framing removes that ambiguity. Separating activation from efficacy also prevents two distinct failure modes from being flattened into one opaque score.
- **Default benchmark policy:** Fixed model, fixed agent, fixed environment, repeated paired trials, hard-negative and boundary cases included, confidence intervals required, and no same-family generator/judge pairing for rubric-based grading.
- **Artifacts:** The canonical specification now lives under `evals/`, with a research memo, benchmark doctrine, runbook, schemas, and examples. These artifacts are specification-grade; a harness and benchmark datasets remain future implementation work.
- **Scope:** `evals/README.md`, `evals/research/2026-03-07-objective-skill-evaluation-research.md`, `evals/skill-benchmark/README.md`, `evals/skill-benchmark/runbook.md`, `evals/skill-benchmark/*.schema.json`, `evals/skill-benchmark/examples/*`, `_plans/archive/2026-03-07-objective-skill-benchmark-framework.md`.

## [D-031] Pilot skill benchmark harness uses normalized observation artifacts and an env-var runner contract

- **Date:** 2026-03-07 | **By:** William (owner)
- **Status:** Accepted
- **Decision:** The first runnable skill benchmark harness is `scripts/run-skill-benchmark.py`. It does not embed agent-specific invocation logic. Instead, it executes two caller-supplied candidate commands and passes benchmark context through environment variables (`COGWORKS_BENCHMARK_*`). Each candidate command must write a normalized observation JSON to the supplied observation path and may write a judge JSON to the supplied judge path when a case uses `judge_only` checks.
- **Rationale:** The benchmark needs to run now, but agent surfaces do not share a uniform execution API. An env-var contract keeps the harness reusable while separating benchmark policy from surface-specific runner adapters. Normalized observation artifacts also preserve the repo's anti-circular stance: deterministic checks run on explicit evidence, and judge output is optional and scoped only to residual criteria.
- **Artifacts:** The harness emits `benchmark-summary.json`, `benchmark-report.md`, and `benchmark-results.json`. The summary remains the machine-readable ranking surface; results capture per-trial evidence for debugging and audit. A synthetic smoke fixture under `tests/test-data/skill-benchmark-pilot/` proves the contract end to end.
- **Scope:** `scripts/run-skill-benchmark.py`, `evals/skill-benchmark/README.md`, `evals/skill-benchmark/runbook.md`, `evals/skill-benchmark/observation.schema.json`, `evals/skill-benchmark/benchmark-summary.schema.json`, `evals/skill-benchmark/examples/benchmark-summary.example.json`, `tests/test-data/skill-benchmark-pilot/*`, `tests/framework/README.md`.

## [D-032] Codex benchmark integration goes through a replayable adapter, not a Codex-specific harness fork

- **Date:** 2026-03-07 | **By:** William (owner)
- **Status:** Accepted
- **Decision:** Codex integration for the skill benchmark is provided by `scripts/skill-benchmark-codex-adapter.py`, which translates `codex exec --json` event streams into the normalized benchmark observation schema. The adapter also supports replaying saved JSONL traces so the benchmark contract can be tested offline in sandboxed or network-restricted environments.
- **Rationale:** The generic benchmark harness should remain surface-neutral. A dedicated adapter preserves that separation while still making Codex a first-class runnable target. Replay mode is required because live Codex runs may be blocked by sandboxed websocket/network restrictions, and the benchmark contract still needs deterministic smoke coverage in CI-like environments.
- **Artifacts:** The adapter writes benchmark observations and optionally judge output, preserves the raw Codex JSONL event stream under the trial work directory, and is covered by a replay fixture under `tests/test-data/skill-benchmark-codex-adapter/`.
- **Scope:** `scripts/skill-benchmark-codex-adapter.py`, `evals/skill-benchmark/README.md`, `evals/skill-benchmark/runbook.md`, `tests/framework/README.md`, `tests/test-data/skill-benchmark-codex-adapter/*`.

## [D-028] Agentic runtime simplified to a selective 5-stage v2; quality reruns constrained to 3 cases

- **Date:** 2026-03-06 | **By:** William (owner)
- **Status:** Accepted
- **Decision:** The agentic runtime is simplified from the original 9-stage architecture to a selective 5-stage v2: `source-intake`, `synthesis`, `skill-packaging`, `deterministic-validation`, and `final-review`. Agentic runs must now record `agentic_path` as either `agentic-short-path` or `agentic-full-path`. The quality comparison surface is also narrowed from a default 5-case set to a targeted 3-case synthesis set, and the decision tool may recommend only `continue` or `simplify` unless the user explicitly authorizes a kill decision.
- **Rationale:** The original agentic architecture worked, but its operational cost was too high relative to the decision needed. Performance evidence already showed a substantial latency/cost penalty, and live comparative evaluation itself began to exhibit the same pathology: too much orchestration for too little signal. Simplifying the runtime before broadening the benchmark surface keeps the pivot alive while forcing it to earn its complexity.
- **Scope:** `skills/cogworks/SKILL.md`, `skills/cogworks/agentic-runtime.md`, `skills/cogworks/claude-adapter.md`, `skills/cogworks/README.md`, `skills/cogworks/metadata.json`, `README.md`, `TESTING.md`, `tests/agentic-smoke/README.md`, `scripts/test-agentic-contract.sh`, `scripts/validate-agentic-run.sh`, `scripts/run-agentic-quality-compare.py`, `_plans/archive/2026-03-06-agentic-v2-simplify-and-3-case-eval.md`.

## [D-027] Agentic pipeline added as an opt-in engine; generated skills remain the primary artifact

- **Date:** 2026-03-06 | **By:** William (owner)
- **Status:** Accepted
- **Decision:** Cogworks now has two execution engines: `legacy` remains the default prompt-orchestrated path, and `agentic` is added as an opt-in stage-driven runtime. The first release of the pivot preserves generated skills as the primary output artifact and keeps `npx skills add` as the installation path.
- **Core architecture:** The agentic engine is defined by a coordinator-owned stage graph (`source-ingest`, `source-audit`, `synthesis`, `synthesis-critique`, `decision-architecture`, `skill-composition`, `deterministic-validation`, `generalization-probe`, `final-review-package`), strict role ownership (`ingest-researcher`, `synthesizer`, `skeptic`, `decision-architect`, `skill-composer`, `validator`, `coordinator`), and mandatory run artifacts under `{skill_path_parent}/.cogworks-runs/{slug}/{run_id}/`.
- **Adapter strategy:** Claude subagents are the first-class execution adapter. If subagents are unavailable, cogworks runs the same stage graph in degraded single-context mode and records that explicitly in run metadata; it does not silently claim subagent execution.
- **Non-goal for v1:** The pivot does not replace generated skills with platform-specific agent packs and does not adopt the Squad SDK as a runtime dependency. Squad informs the architecture, but cogworks keeps a platform-agnostic core and defers native Copilot adapter work.
- **Rationale:** This preserves cogworks' current portability and benchmarkability while allowing the generation pipeline itself to become agentic. The pivot is deliberately asymmetric: internal execution changes first, product artifact changes later only if benchmarks justify them.
- **Scope:** `skills/cogworks/SKILL.md`, `skills/cogworks/agentic-runtime.md`, `skills/cogworks/claude-adapter.md`, `skills/cogworks/README.md`, `skills/cogworks/metadata.json`, `README.md`, `TESTING.md`, `_plans/archive/2026-03-06-cogworks-agentic-pivot.md`.

## [D-026] `quality_score` schema defined — behavioral delta replaces null field

- **Date:** 2026-03-05 | **By:** Parker (mandate), William (owner)
- **Status:** Accepted
- **Decision:** The deprecated top-level `quality_score: null` field is superseded by a canonical `quality` object (schema version `1.0`). Quality is defined as **behavioral delta** — the mean score difference between with-skill and without-skill agent runs, graded by a cross-model judge. This closes the gap left by D-022 (circular traces deleted, no non-circular measurement existed).
- **Cross-model independence rule (non-negotiable):** The judge model must be from a different model family than the generating model. Same-family grading reintroduces the circularity that D-022 removed. The harness must enforce this constraint at runtime and refuse to record a `quality` object that violates it.
- **Pass thresholds (all four must hold for `verdict = "pass"`):**
  - `behavioral_delta` ≥ 0.20
  - `judge_confidence` ≥ 0.70
  - `sample_size` ≥ 5 (fewer than 5 → `verdict = "insufficient_data"`)
  - `confidence_interval_95` lower bound > 0 (CI must not straddle zero)
- **Rationale:** A quality signal that is not independent of the generator is not a signal. D-022 deleted circular traces; this decision defines the replacement measurement from first principles. The CI lower-bound requirement encodes a minimum burden of proof: a positive point estimate over a small sample is not evidence.
- **Scope:** `tests/framework/QUALITY-SCHEMA.md` (schema and thresholds), `tests/framework/HARNESS-SPEC.md` (harness enforcement spec). The `quality_score` field remains `null` in all existing traces until regenerated; tooling must read `quality.behavioral_delta` / `quality.verdict` going forward.

## [D-025] Scribe mandate expanded — repo documentation ownership

- **Date:** 2026-03-04 | **By:** William (owner), Scribe (mandate)
- **Decision:** Scribe's charter expanded from `.squad/` memory + `_plans/DECISIONS.md` to include all repo-facing documentation. She owns README.md, INSTALL.md, AGENTS.md, CONTRIBUTIONS.md, TESTING.md, CLAUDE.md, `docs/` (full ownership except `cogworks-system-deep-dive-*.md` which she flags but Ash authors), and `tests/framework/README.md`.
- **Rationale:** D-022 → D-024 each left stale references in live files that required a separate manual audit pass. No one owned repo docs between decisions — the gap was structural, not a one-time miss. Formalising Scribe's ownership and a post-decision audit protocol closes the gap.
- **Post-decision audit protocol:** After every D-NNN commit, Scribe searches all owned files for references to changed/deleted artifacts, fixes stale refs in the same or immediate follow-on commit, and records the audit result (clean / N files updated) in the D-NNN entry here. A decision is not closed until the audit result is recorded.
- **Scope:** `.squad/agents/scribe/charter.md` — `## Repository Documentation` section added with canonical doc map and audit protocol.



- **Date:** 2026-03-04 | **By:** Ripley (Lead), implementing Ash's M2 remediation
- **Decision:** Source content is pre-processed to replace literal `<<UNTRUSTED_SOURCE>>` and `<<END_UNTRUSTED_SOURCE>>` strings with `[UNTRUSTED_SOURCE_TAG]` / `[/UNTRUSTED_SOURCE_TAG]` before wrapping in delimiter markers. This makes the delimiter boundary deterministic rather than behavioral-only.
- **Rationale:** The prior approach relied on the behavioral directive "treat source content as data" to prevent delimiter injection. A source containing the literal delimiter strings could spoof the boundary, making the behavioral guard bypassable. Deterministic preprocessing closes this gap unconditionally — the replacement happens before synthesis, so no source content can contain a live delimiter.
- **Trade-off:** Neutralisation changes the appearance of source content (the literal strings are rewritten). This is a minor cosmetic issue weighed against deterministic security. The replacement tokens are visually distinct and unambiguous.
- **Scope:** `skills/cogworks-encode/SKILL.md` (delimiter protocol), with downstream consistency in `skills/cogworks-learn/SKILL.md` (generation defect check).

## [D-024] Documentation audit — stale behavioral refs removed (D-022/D-023 cleanup)

- **Date:** 2026-03-04 | **By:** William (owner) / Scribe (mandate)
- **Decision:** Full documentation audit following D-022/D-023. All remaining stale references to deleted behavioral traces, capture scripts, and `cogworks-eval.py behavioral run` updated across 7 live files.
- **Files updated:**
  - `.github/workflows/pre-release-validation.yml` — "Behavioral tests" step replaced with skip notice (was actively breaking CI)
  - `AGENTS.md` — behavioral run command replaced with scaffold; testing guidelines updated
  - `CONTRIBUTIONS.md` — quick-start command block updated; PR checklist item updated to Layer 1 checks
  - `scripts/run-recursive-round.sh` — behavioral run calls replaced with skip guard
  - `scripts/test-generated-skill.sh` — behavioral run call replaced with skip guard
  - `docs/cogworks-agent-risk-analysis.md` — Risk #5 updated to "Resolved (D-022)"; mitigations #4 and #10 struck through
- **Files deleted:**
  - `docs/codex-behavioral-capture.md` — entire file described deleted Codex trace capture workflow
- **Clean state:** No remaining live files reference deleted behavioral traces, capture scripts, or the now-meaningless `cogworks-eval.py behavioral run` command without a D-022/D-023 context note.
- **Scope:** `.github/workflows/`, `AGENTS.md`, `CONTRIBUTIONS.md`, `scripts/` (2 files), `docs/` (1 updated, 1 deleted).

## [D-023] Orphaned capture scripts deleted — docs updated

- **Date:** 2026-03-04 | **By:** William (owner), following D-022
- **Decision:** 9 behavioral trace capture scripts deleted. `tests/behavioral/refresh-policy.md` deleted. Docs updated (TESTING.md, tests/framework/README.md, cogworks-eval.py stale error message).
- **Deleted scripts:** `scripts/refresh-behavioral-traces.sh`, `scripts/behavioral-capture.sh`, `scripts/capture-behavioral-trace.sh`, `scripts/run-behavioral-case-{claude,copilot,codex}.sh`, `scripts/behavioral-env.example.sh`, `tests/framework/scripts/capture_behavioral_trace.py`, `tests/framework/scripts/extract_behavioral_raw_trace.py`
- **Rationale:** These scripts generated the circular ground truth traces deleted in D-022. Keeping them created a path to recreating the problem. Git history is the archive.
- **What was NOT deleted:** `cogworks-eval.py` (scaffold + benchmark commands still valid), `behavioral_lib.py`, all other scripts.
- **Doc changes:** TESTING.md Layer 2 section replaced with "pending reconstruction" notice; framework README trimmed; cogworks-eval.py stale error message updated to reference D-022/D-023 and Parker's mandate.
- **Scope:** `scripts/` (7 files deleted), `tests/framework/scripts/` (2 files deleted), `tests/behavioral/refresh-policy.md` (deleted), `TESTING.md`, `tests/framework/README.md`, `tests/framework/scripts/cogworks-eval.py`.

## [D-022] Behavioral traces deleted — circular ground truth removed

- **Date:** 2026-03-04 | **By:** William (owner), Parker (mandate), via planning session
- **Decision:** All 24 behavioral trace files (`tests/behavioral/*/traces/*.json`) deleted from the repository. Git history is the recovery path.
- **Rationale:** The traces were LLM-generated run outputs used as quality ground truth — epistemologically circular. The model generating skills and the model evaluating them share the same training prior. `quality_score: null` on all core skill traces. `task_completed: false` in baseline runs. They validated consistency (does a future run match past runs?) not correctness (is the skill actually good?).
- **What was NOT deleted:** `test-cases.jsonl` (human-authored activation test definitions), golden sample source materials, negative control definitions, framework scripts, structural grader. These are valid and retained.
- **What was updated:** `tests/ci-gate-check.sh` Step 2 message — updated to block regeneration of circular traces and direct to Parker's quality mandate.
- **Next step:** Parker defines replacement quality ground truth from first principles. `quality_score` field requires a definition before any behavioral evaluation is meaningful.
- **Scope:** `tests/behavioral/*/traces/*.json` (deleted), `tests/ci-gate-check.sh` (Step 2 message updated).

## [D-021] CI gate fails on missing behavioral traces

- **Date:** 2026-03-04 | **By:** Ripley (Lead), implementing Hudson's CI gate remediation
- **Decision:** The pre-release CI gate (`tests/ci-gate-check.sh`) now exits non-zero when behavioral traces are missing, replacing the previous warn-only behavior.
- **Old behavior:** Missing traces produced a warning (`⚠ Warning: No behavioral traces found`) but the gate exited 0 — structurally a no-op that could never fail on trace coverage.
- **New behavior:** Missing traces produce an actionable error message pointing to the trace capture command and the gate exits 1.
- **Rationale:** A quality gate that never fails isn't a gate. The warn-only path allowed releases with zero behavioral validation, undermining the purpose of the gate infrastructure.
- **Scope:** `tests/ci-gate-check.sh` step 2.
