audited_through: 2026-03-13
---

# Architectural Decisions

Settled decisions for the cogworks project. Agents load this file for context.
Archive plan files are deleted once their decision is extracted here; git history is the recovery path.

## [D-047] Session-derived maintenance lessons are now codified as working norms in `AGENTS.md`

- **Date:** 2026-03-13 | **By:** William (owner)
- **Status:** Accepted
- **Decision:** Four recurring lessons from the version-sync and documentation cleanup session are now captured as reusable working norms in `AGENTS.md`: classify repeated references before synchronizing them; prefer reducing editable sources over policing many hand-edited copies; enforce release-critical invariants at the remote boundary rather than only locally; and run a docs parity sweep immediately after behavior or release-contract changes.
- **Rationale:** The session repeatedly hit the same avoidable failure modes: ambiguous scope between live versus historical version references, drift caused by too many editable copies of the same value, local enforcement that still allowed bad remote release actions, and maintainer docs lagging behind code and workflow changes. Turning those into explicit norms is more useful than preserving a narrative retrospective.
- **Operational implication:** Future agents should treat these lessons as first-touch repository guidance via `AGENTS.md`, not as one-off release notes. `DECISIONS.md` keeps only the rationale for why the norms were added.
- **Builds on:** D-044 and D-046 by generalizing one release-specific fix and one documentation-maintenance rule into broader reusable doctrine.
- **Scope:** `AGENTS.md`, `_plans/DECISIONS.md`.

## [D-046] Documentation maintenance directive added to AGENTS.md

- **Date:** 2026-03-13 | **By:** Squad (Lambert research + Ripley audit)
- **Status:** Accepted
- **Context:** William repeatedly had to remind agents (Copilot, Claude Code, Codex) to update documentation after changes. Root cause: AGENTS.md had no explicit doc-update directive — agents only learned about doc requirements implicitly from CONTRIBUTIONS.md (which they often don't load).
- **Decision:** Added a `## Documentation Maintenance` section to AGENTS.md with a trigger → target mapping table (change domain → which doc to update) and a verification step. Positioned after Learned Working Norms so all agents encounter it early.
- **Rationale:** AGENTS.md is the master authority read by all three agent surfaces (Claude via CLAUDE.md redirect, Copilot via custom_instruction, Codex directly). One directive in the canonical file covers all surfaces without violating single-source-of-truth. No CI enforcement needed yet — the directive is the lowest-friction first step.
- **Commit:** `ae0a4da`

## [D-045] Copilot plugin compliance audit — learned norms for plugin surface work

- **Date:** 2026-03-13 | **By:** Copilot agent (session retrospective)
- **Status:** Accepted
- **Decision:** Five operational lessons from the Copilot plugin compliance audit are captured as norms for future agent work on plugin surfaces:
  1. **Research before recommending** — when encountering an unfamiliar file format or platform artifact (e.g., `agents/openai.yaml`), search authoritative docs FIRST. File content tells you WHAT it contains, not WHY it exists or WHO uses it.
  2. **`plugin/` is a shared surface** — `plugin/skills/` and `plugin/agents/` serve both the Copilot CLI plugin (via root `plugin.json`) and the Claude Code plugin (via `plugin/.claude-plugin/plugin.json`). Any change to render scripts or plugin structure must be validated against both consumers.
  3. **`render-plugin-skills.py` has two copy strategies** — `cogworks` uses `render_cogworks()` (selective copy with content patching); `cogworks-encode` and `cogworks-learn` use `copy_tree()` (verbatim full copy). Changes to one strategy don't affect the other.
  4. **`agents/openai.yaml` is Codex-specific** — per https://developers.openai.com/codex/skills, this file configures UI metadata, invocation policy, and tool dependencies for OpenAI Codex. Neither Copilot CLI nor Claude Code reads it. Current cogworks use: `policy: allow_implicit_invocation: false`.
  5. **Question hardcoded string replacements** — the render script uses string replacement to transform SKILL.md content. Hardcoded file references become stale when file layout changes. Flag these for review during any render pipeline modification.
- **Rationale:** The Copilot plugin compliance audit required three user corrections before converging on correct fixes. These norms prevent repeating the same mistakes.
- **Scope:** `scripts/render-plugin-skills.py`, `plugin/`, `agents/openai.yaml`, all plugin surface work.

## [D-044] `VERSION` is now the single editable release source, and mismatched pushed tags are auto-rejected

- **Date:** 2026-03-13 | **By:** William (owner)
- **Status:** Accepted
- **Decision:** The repo now uses a single committed `VERSION` file as the only editable release-version source. Live versioned release surfaces (`plugin.json`, `.claude-plugin/marketplace.json`, `.github/plugin/marketplace.json`, and canonical `skills/**` metadata/frontmatter) are rendered from `VERSION` by `scripts/render-release-version-files.py`. `scripts/create-release-tag.sh` now bumps `VERSION`, renders versioned files, re-renders plugin skills, verifies both renderers with `--check`, commits, and then tags. PR validation now runs `scripts/render-release-version-files.py --check`. The tag-push release workflow now rejects and deletes a pushed `v*` tag if the tag does not exactly match `VERSION` or if rendered versioned files are out of date.
- **Rationale:** Tag-derived validation alone detects drift after the fact, but it still allows maintainers or agents to create and push incorrect release tags. A single editable source plus generated duplicates shrinks the manual sync surface to one file. Auto-rejecting mismatched remote tags makes the release boundary fail closed instead of merely reporting drift.
- **Operational implication:** Maintainers should edit `VERSION` only through the release script in normal use. Live release surfaces are generated artifacts and should not be hand-edited for version bumps. If any actor pushes a `v*` tag that does not match the committed `VERSION` state, the release workflow will delete the remote tag and fail the release.
- **Builds on:** D-043 by replacing tag-derived synchronization alone with a stricter single-source render model and remote tag enforcement.
- **Scope:** `VERSION`, `scripts/resolve-release-version.py`, `scripts/render-release-version-files.py`, `scripts/create-release-tag.sh`, `scripts/test-agentic-contract.sh`, `.github/workflows/pre-release-validation.yml`, `.github/workflows/release.yml`, `CONTRIBUTIONS.md`, `_plans/DECISIONS.md`.
- **D-025 audit (Scribe, 2026-03-13):** Clean — owned contribution/release docs now describe `VERSION` as the editable source and the fail-closed tag rejection behavior.

## [D-043] Release version validation now resolves from git tags and covers both marketplace catalogs

- **Date:** 2026-03-13 | **By:** William (owner)
- **Status:** Accepted
- **Decision:** `git` release tags remain the canonical cogworks version authority, but repo validation and release bumping are now wired through one repo-owned resolver instead of hard-coded release literals. `scripts/resolve-release-version.py` normalizes an explicit version or the latest `v*` tag. `scripts/test-agentic-contract.sh` now compares versioned manifests against the resolved canonical version rather than hard-coded `4.1.0` assertions. `scripts/create-release-tag.sh` now updates `.github/plugin/marketplace.json` alongside `plugin.json`, `.claude-plugin/marketplace.json`, and the canonical `skills/**` metadata/frontmatter files. `.github/workflows/release.yml` now validates both the Claude and Copilot marketplace catalogs against the pushed tag version.
- **Rationale:** The previous state mixed two incompatible stories: docs said git tags were the sole source of truth, while several repo surfaces still required manual literal-version edits and one live Copilot marketplace catalog was omitted from the bump script. That made release drift easy and gave maintainers two partially overlapping version authorities. Resolving from tags everywhere keeps the authority model honest and shrinks the manual sync surface.
- **Operational implication:** Maintainers should treat `plugin/skills/**` as rendered outputs and historical smoke/example artifacts as preserved snapshots, not release metadata. Any future version-bearing live manifest or validator must resolve from the canonical tag-based helper or be generated from a surface that does.
- **Scope:** `scripts/resolve-release-version.py`, `scripts/create-release-tag.sh`, `scripts/test-agentic-contract.sh`, `.github/workflows/release.yml`, `CONTRIBUTIONS.md`, `_plans/DECISIONS.md`.
- **D-025 audit (Scribe, 2026-03-13):** Clean — owned release/contribution docs now include the Copilot marketplace catalog in the live packaging surface.

## [D-042] Dispatch manifests now record canonical stage scope, and release validation requires exact equality

- **Date:** 2026-03-09 | **By:** William (owner)
- **Status:** Accepted
- **Decision:** Claude-side dispatch-manifest production is now canonicalized through repo-owned helpers rather than inferred from live tool inventory strings. `scripts/render-dispatch-manifest.py` writes the maintained dispatch-manifest shape directly from `skills/cogworks/role-profiles.json`, and `scripts/resolve-role-profile.py` exposes per-profile canonical fields for coordinator use. `scripts/validate-agentic-run.sh` now requires exact per-stage `tool_scope` equality against the canonical role-profile contract for both Claude and Copilot artifact sets. The preserved Claude happy-path release evidence is refreshed to `tests/agentic-smoke/examples/claude-cli-release-api-auth-smoke-20260309-r5/`, and the earlier superseded Claude evidence sets are removed.
- **Rationale:** The previous Claude manifest serialized the raw Claude tool inventory into `dispatch-manifest.tool_scope`, which was useful metadata but not defensible provenance. That left one known gap between “the run happened” and “the saved manifest is an exact canonical record of stage scope.” Fixing the producer first and then tightening the validator closes that gap without confusing provenance rigor with downstream skill-quality evidence, which is still primarily earned through deterministic validation and benchmark evidence.
- **Operational implication:** Release-grade Claude and Copilot artifacts must now record canonical semantic `tool_scope` values, not adapter-native tool listings. Maintainers should treat preserved happy-path artifacts as the current canonical evidence only when they pass the exact-equality validator. Any future adapter change that touches dispatch-manifest production must preserve canonicalization through `role-profiles.json`.
- **Builds on:** D-038 and D-039 by making the maintained release bar more truthful and auditable rather than broader.
- **Scope:** `scripts/render-dispatch-manifest.py`, `scripts/resolve-role-profile.py`, `scripts/validate-agentic-run.sh`, `scripts/test-agentic-contract.sh`, `skills/cogworks/SKILL.md`, `skills/cogworks/claude-adapter.md`, `skills/cogworks/reference.md`, `TESTING.md`, `tests/agentic-smoke/README.md`, `tests/agentic-smoke/examples/claude-cli-release-api-auth-smoke-20260309-r5/**`, and deletion of `tests/agentic-smoke/examples/claude-cli-release-api-auth-smoke-20260309-r2/**`.
- **D-025 audit (Scribe, 2026-03-09):** Clean — owned docs now point only at the current preserved Claude artifact and no longer describe the old `tool_scope` provenance limitation.

## [D-041] Closed plans are retained as extracted decisions, not archived files

- **Date:** 2026-03-08 | **By:** William (owner)
- **Status:** Accepted
- **Decision:** The `_plans/` workflow now follows `Decision-Only` retention. Accepted plans may exist temporarily under `_plans/` while work is active. Once the work is complete, the canonical durable record is the extracted entry in `DECISIONS.md`; the closed plan file is deleted rather than preserved as a standalone historical artifact. The repository does not maintain a growing plan archive in the working tree.
- **Rationale:** Compact, scoped durable memory is easier for agents to retrieve correctly than narrative history. The prior archive model duplicated information already meant to live in `DECISIONS.md`, increased drift risk, and kept a historical surface around long after its decision-grade value had been extracted. Git history is sufficient for recovery when the original plan text is ever needed.
- **Operational implication:** `_plans/` is now an active-work surface plus `DECISIONS.md`, not a historical document store. Canonical docs and decision entries should no longer point readers at archived plan files as part of the normal workflow.
- **Builds on:** D-033, D-034, and D-040 by reducing durable memory to the smallest operational surface.
- **Scope:** `AGENTS.md`, `_plans/DECISIONS.md`.
- **D-025 audit (Scribe, 2026-03-08):** Clean — owned policy surfaces now agree on the deletion-based lifecycle.

## [D-040] `AGENTS.md` now defines staged retrieval, stop rules, and authority order at first touch

- **Date:** 2026-03-08 | **By:** William (owner)
- **Status:** Accepted
- **Decision:** `AGENTS.md` now defines a first-touch retrieval contract near the top of the file. Default retrieval is staged rather than broad: agents load `AGENTS.md`, then `_plans/DECISIONS.md`, then at most one matching active root plan, then one task-matched canonical doc or leaf file. Agents must not preload all top-level docs, must prefer named entrypoint files over directory scans, and must stop loading once they have enough context to act safely. `AGENTS.md` also now defines an explicit authority order for resolving conflicts between canonical surfaces.
- **Rationale:** The prior retrieval policy still encouraged unnecessary first-touch expansion by listing all top-level docs as default reads and by using broad wording like “directly relevant files under `skills/` and `evals/`”. It also contained a contradictory pull-through into `.squad/`, a surface explicitly marked non-default. Tightening the contract reduces context pollution and gives agents fewer opportunities to improvise authority or over-read.
- **Operational implication:** Agents should treat the top-level product docs as task-matched follow-on reads, not startup context. Non-default surfaces remain scoped references only. `AGENTS.md` should avoid routine references that send agents into non-default trees.
- **Builds on:** D-033 and D-034 by turning the allowlist into an explicit staged retrieval algorithm with stop conditions and precedence.
- **Scope:** `AGENTS.md`, `_plans/DECISIONS.md`.
- **D-025 audit (Scribe, 2026-03-08):** Clean — no stale refs remain in the owned files touched by this decision.

## [D-039] Public docs now state surface support boundaries explicitly at first touch

- **Date:** 2026-03-08 | **By:** William (owner)
- **Status:** Accepted
- **Decision:** Public/user-facing docs must distinguish artifact portability from build-surface support explicitly and early. `README.md`, `INSTALL.md`, `skills/cogworks/README.md`, `TESTING.md`, and `CONTRIBUTIONS.md` now teach one consistent support model: generated skills are portable across agents that support skills; the trust-first internal build flow is currently supported only on Claude Code and GitHub Copilot CLI; Codex may appear as a generated-skill destination or maintainer benchmark/trigger surface, but it must not be presented as a supported trust-first build surface.
- **Rationale:** The previous docs required readers to infer the Codex restriction by combining public and maintainer-only files. That made the product surface easy to misread and allowed installation or testing examples to imply parity that the runtime does not actually support. Explicit first-touch boundaries reduce user confusion and keep public docs aligned with the live product contract.
- **Operational implication:** Any future public doc change that mentions Codex, portability, or supported surfaces must preserve the portability-versus-build distinction. Maintainer testing docs may continue to reference Codex where trigger smoke or benchmark tooling genuinely uses it, but those references must remain visibly separate from product support claims.
- **Scope:** `README.md`, `INSTALL.md`, `skills/cogworks/README.md`, `TESTING.md`, `CONTRIBUTIONS.md`.

## [D-038] Test surface subtraction removes dead contracts and keeps only maintained validation paths

- **Date:** 2026-03-08 | **By:** William (owner)
- **Status:** Accepted
- **Decision:** The maintained test surface is reduced to the validation paths that still correspond to live product/runtime contracts. File-backed Claude specialist bindings under `.claude/agents/` are retired in favor of canonical role-profile bindings recorded directly from `skills/cogworks/role-profiles.json`. The dead `benchmarks/comparison/**` pipeline-benchmark surface is retired rather than restored. Recursive rounds remain maintained only in `--mode fast`; the local recursive manifest hash is re-pinned to the current frozen bundle. The stale pre-release CI gate script is deleted because it hard-failed on behavioral traces that D-022 intentionally removed. Trigger smoke remains active, but its runner execution and activation parsing must be runner-specific for current Claude and Codex CLIs.
- **Rationale:** Several failing tests were not exposing product regressions; they were enforcing contracts that the repository had already abandoned in practice. Restoring every removed surface would add complexity without improving trust. Subtracting dead paths leaves one coherent, documented test story.
- **Operational implication:** Maintainers should rely on deterministic checks, black-box tests, the live sub-agent contract smoke, the skill benchmark smoke, trigger smoke, and the fast recursive round. They should not expect `.claude/agents/**`, `tests/ci-gate-check.sh`, `tests/run-pipeline-benchmark-smoke.sh`, or recursive deep-mode benchmark wiring to exist.
- **Supersedes:** D-029 for the file-backed Claude binding detail, D-018 for the behavioral-trace CI gate, and any live docs/scripts still treating `benchmarks/comparison/**` as an active benchmark surface.
- **Scope:** `skills/cogworks/SKILL.md`, `skills/cogworks/claude-adapter.md`, `skills/cogworks/copilot-adapter.md`, `skills/cogworks/role-profiles.json`, `scripts/validate-agentic-run.sh`, `scripts/test-agentic-contract.sh`, `scripts/render-agentic-role-bindings.py`, `scripts/run-recursive-round.sh`, `scripts/recursive-env.example.sh`, `scripts/run-trigger-smoke-tests.sh`, `tests/framework/scripts/cogworks-eval.py`, `tests/datasets/recursive-round/README.md`, `tests/datasets/recursive-round/round-manifest.local.json`, `TESTING.md`, `AGENTS.md`, `tests/run-pipeline-benchmark-smoke.sh` (deleted), `tests/ci-gate-check.sh` (deleted).

## [D-037] Cogworks resets to one trust-first product entry point; sub-agent build path becomes internal maintainer machinery

- **Date:** 2026-03-08 | **By:** William (owner)
- **Status:** Accepted
- **Decision:** `cogworks` is reset around one stable user-facing skill entry point. Users invoke `cogworks` to turn source material into a generated skill; they no longer select between public engine modes such as `--engine agentic`. Claude Code and GitHub Copilot keep the internal sub-agent build path, but that path is now maintainer-facing implementation detail rather than product surface. Generated skills remain the only primary product artifact. The product is fail-closed: if source trust, contradiction handling, provenance, or deterministic validation is insufficient, `cogworks` must stop with a blocking trust report instead of presenting a production-ready skill.
- **Rationale:** The previous pivot drifted into a pseudo-CLI and runtime-contract product that exposed internal pipeline choices instead of improving the one thing users actually care about: the quality and trustworthiness of generated skills. Making sub-agents internal again preserves their benefits while removing user-facing complexity and context bloat.
- **Operational implication:** Public docs and the `cogworks` skill now teach one natural invocation surface. Maintainer smoke validation still verifies the Claude/Copilot sub-agent build path, but benchmarking and runtime evidence are explicitly separate from the normal user workflow. Runtime metadata no longer belongs in generated skill frontmatter or generated-skill metadata. Codex sub-agent support is deferred rather than simulated.
- **Supersedes:** D-027, D-028, and D-029 at the product-surface level. Their history remains valid background, but the active product contract is now the single-entry trust-first model described here.
- **Scope:** `skills/cogworks/SKILL.md`, `skills/cogworks/README.md`, `skills/cogworks/metadata.json`, `skills/cogworks/agentic-runtime.md`, `skills/cogworks/claude-adapter.md`, `skills/cogworks/copilot-adapter.md`, `README.md`, `INSTALL.md`, `TESTING.md`, `tests/agentic-smoke/README.md`, `tests/agentic-smoke/examples/copilot-native-subagents-api-auth-smoke/**`, `scripts/test-agentic-contract.sh`, `scripts/validate-agentic-run.sh`, `scripts/run-agentic-quality-compare.py` (deleted).

## [D-036] Benchmark evidence is fail-closed; preserved smoke proof lives in a canonical example surface

- **Date:** 2026-03-08 | **By:** William (owner)
- **Status:** Accepted
- **Decision:** The skill benchmark surface is now hardened to fail closed. `scripts/run-skill-benchmark.py` validates cases, observations, judge output, and summaries against the canonical schemas; requires `--judge-model` whenever a case uses `judge_only`; enforces cross-family judge/generator separation; reruns invalid trials instead of scoring them; and treats replay evidence as non-decision-grade even when the harness completes. Activation remains a separate scorecard, but a candidate with disqualifying false-positive regression on `must_not_activate` cases may not be declared the winner. The Codex adapter is restored as a replayable/live observation normalizer with explicit integrity metadata rather than a benchmark-fork surface. Preserved Copilot smoke proof artifacts now live under `tests/agentic-smoke/examples/copilot-native-subagents-api-auth-smoke/` instead of repo-root scratch paths.
- **Rationale:** The benchmark was the decision surface for whether agentic complexity earns its keep, but it was weaker than the runtime contract it was meant to judge. Scoring invalid trials, omitting judge provenance, and teaching one context-hygiene policy while embodying another made the repo easier to misread and easier to overclaim from. This decision makes benchmark results and preserved examples honest by construction.
- **Operational implication:** Benchmark claims should rely on `decision_eligible = true`, not just `verdict`. Replay artifacts remain useful for smoke coverage and offline normalization checks, but they do not support ranking claims. Preserved in-repo smoke evidence is now explicit example material, not ambient scratch state.
- **Scope:** `scripts/run-skill-benchmark.py`, `scripts/skill-benchmark-codex-adapter.py`, `evals/skill-benchmark/*.schema.json`, `evals/skill-benchmark/README.md`, `evals/skill-benchmark/runbook.md`, `evals/skill-benchmark/examples/benchmark-summary.example.json`, `evals/README.md`, `tests/test-data/skill-benchmark-pilot/*`, `tests/test-data/skill-benchmark-integrity/*`, `tests/test-data/skill-benchmark-codex-adapter/*`, `tests/run-skill-benchmark-smoke.sh`, `tests/framework/README.md`, `TESTING.md`, `tests/agentic-smoke/README.md`, `tests/agentic-smoke/examples/copilot-native-subagents-api-auth-smoke/`, `.cogworks-runs/README.md`, `tmp-agentic-output/README.md`.

## [D-035] Infrastructure debt cleanup and source-intake trust gate — *Partially superseded by D-036, D-037, and D-038*

- **Date:** 2026-03-08 | **By:** William (owner)
- **Status:** Partially superseded
- **Decision:** Removed interim comparison/tooling debt around the early agentic benchmark surface and introduced `source-intake/source-trust-gate.json` as a required blocking artifact before synthesis begins.
- **Rationale:** The interim engine and benchmark surfaces had accumulated tooling without the corresponding decision-grade experiment results. The trust gate addition closed a real security/runtime gap even though other parts of the cleanup were later revised.
- **Operational implication:** The lasting contract from this decision is the enforced `source-trust-gate.json` requirement now reflected in current runtime docs and validators. The deleted-adapter and deleted-comparison-script aspects were later overtaken by D-036 through D-038.
- **Scope:** `skills/cogworks/agentic-runtime.md`, `scripts/validate-agentic-run.sh`, `skills/cogworks/role-profiles.json`.

## [D-033] Default agent retrieval is restricted to canonical instruction surfaces; research, history, and generated artifacts are non-default

- **Date:** 2026-03-07 | **By:** William (owner)
- **Status:** Accepted
- **Decision:** Agents working in this repository must treat only the following as default retrieval surfaces unless the task explicitly calls for deeper context: `AGENTS.md`, top-level product docs (`README.md`, `TESTING.md`, `CONTRIBUTIONS.md`, `INSTALL.md`), `_plans/DECISIONS.md`, active `_plans/*.md`, and directly relevant canonical files under `skills/**`, `.claude/agents/**`, and `evals/**`. The following are non-default and must not be loaded opportunistically: `.github/agents/**`, `.squad/**`, `_sources/**`, `.cogworks-runs/**`, `tmp-agentic-output/**`, `tests/results/**`, `tests/test-data/**`, and `tests/datasets/golden-samples/**`. Closed plan files are deleted after extraction and therefore are not a retained retrieval surface.
- **Rationale:** The 2026-03-07 repository-wide context audit found that the repo has multiple high-authority but non-canonical surfaces: a large Copilot auto-loaded Squad instruction file, duplicate decision ledgers, tracked generated run artifacts, production-shaped generated skills outside `skills/`, and a mixed-authority research corpus under `_sources/`. Without a hard default retrieval boundary, agents can waste context budget or act on the wrong source of truth.
- **Operational implication:** Default retrieval now follows an allowlist model. Research corpora, Squad memory, run artifacts, and realistic fixtures remain valid repository assets, but only when a task explicitly requires them. When these surfaces are consulted, agents must treat them as scoped reference material rather than repo-wide policy.
- **Audit artifact:** `docs/ai-context-retrieval-risk-audit-2026-03-07.md`
- **Scope:** `AGENTS.md`, `_plans/DECISIONS.md`, `docs/ai-context-retrieval-risk-audit-2026-03-07.md`

## [D-034] Context-hygiene cleanup marks non-canonical surfaces and defaults live smoke output to disposable paths

- **Date:** 2026-03-07 | **By:** William (owner)
- **Status:** Accepted
- **Decision:** The repository now enforces the default retrieval policy in live docs, not just in the decision record. `AGENTS.md` now carries the canonical allowlist for default loading. `TESTING.md` now recognizes the current skill-benchmark pilot harness under `evals/` and distinguishes it from the still-reconstructing broader behavioral harness. Live smoke docs now prefer disposable output roots outside the repository. High-risk non-canonical surfaces (`.github/agents/`, `.squad/`, `_sources/`, `.cogworks-runs/`, `tmp-agentic-output/`, `tests/test-data/`, and `tests/datasets/golden-samples/`) now contain explicit warning markers or READMEs that tell humans and agents not to treat them as default instruction sources.
- **Rationale:** Policy that exists only in a decision file still leaves first-touch retrieval vulnerable. The audit showed that the repo's highest-risk surfaces were dangerous precisely because they looked canonical when opened directly. Marking those surfaces in place reduces wrong-authority retrieval without deleting useful historical evidence or test fixtures.
- **Operational implication:** Future smoke runs and benchmark runs should default to disposable output roots, and any preserved in-repo artifacts should be treated as deliberate examples, not ambient scratch state. Historical handoff material no longer belongs in active `_plans/`.
- **Scope:** `.gitignore`, `AGENTS.md`, `TESTING.md`, `tests/agentic-smoke/README.md`, `.github/agents/squad.agent.md`, `.squad/decisions.md`, `.squad/identity/now.md`, `.squad/README.md`, `_sources/README.md`, `.cogworks-runs/README.md`, `tmp-agentic-output/README.md`, `tests/test-data/README.md`, `tests/datasets/golden-samples/README.md`, `docs/testing-workflow-guide.md`, `docs/cogworks-agent-risk-analysis.md`

## [D-029] Generalised agentic runtime with adapters — *Superseded by D-037 and D-038*

## [D-030] Skill evaluation benchmark isolated to skill-vs-skill efficacy with separate activation diagnostics

- **Date:** 2026-03-07 | **By:** William (owner)
- **Status:** Accepted
- **Decision:** Objective comparison of agent skills is now defined as a paired benchmark where the model, agent surface, tools, sandbox, task cases, and graders are held constant and only the skill differs. The primary score is task efficacy after invocation; activation quality is measured separately as its own scorecard. The benchmark must prefer deterministic trace/state checks, use cross-model judges only for residual qualitative criteria, and report repeated-trial uncertainty rather than single-run point estimates.
- **Rationale:** Previous repo guidance correctly rejected circular self-grading, but it still left open a key attribution problem: if model, runtime, and skill all move at once, the result is not a skill benchmark. A clean intervention framing removes that ambiguity. Separating activation from efficacy also prevents two distinct failure modes from being flattened into one opaque score.
- **Default benchmark policy:** Fixed model, fixed agent, fixed environment, repeated paired trials, hard-negative and boundary cases included, confidence intervals required, and no same-family generator/judge pairing for rubric-based grading.
- **Artifacts:** The canonical specification now lives under `evals/`, with a research memo, benchmark doctrine, runbook, schemas, and examples. These artifacts are specification-grade; a harness and benchmark datasets remain future implementation work.
- **Scope:** `evals/README.md`, `evals/research/2026-03-07-objective-skill-evaluation-research.md`, `evals/skill-benchmark/README.md`, `evals/skill-benchmark/runbook.md`, `evals/skill-benchmark/*.schema.json`, `evals/skill-benchmark/examples/*`.
- **D-025 audit (Scribe, 2026-03-07):** Clean — no stale refs in owned files.

## [D-031] Pilot skill benchmark harness uses normalized observation artifacts and an env-var runner contract

- **Date:** 2026-03-07 | **By:** William (owner)
- **Status:** Accepted
- **Decision:** The first runnable skill benchmark harness is `scripts/run-skill-benchmark.py`. It does not embed agent-specific invocation logic. Instead, it executes two caller-supplied candidate commands and passes benchmark context through environment variables (`COGWORKS_BENCHMARK_*`). Each candidate command must write a normalized observation JSON to the supplied observation path and may write a judge JSON to the supplied judge path when a case uses `judge_only` checks.
- **Rationale:** The benchmark needs to run now, but agent surfaces do not share a uniform execution API. An env-var contract keeps the harness reusable while separating benchmark policy from surface-specific runner adapters. Normalized observation artifacts also preserve the repo's anti-circular stance: deterministic checks run on explicit evidence, and judge output is optional and scoped only to residual criteria.
- **Artifacts:** The harness emits `benchmark-summary.json`, `benchmark-report.md`, and `benchmark-results.json`. The summary remains the machine-readable ranking surface; results capture per-trial evidence for debugging and audit. A synthetic smoke fixture under `tests/test-data/skill-benchmark-pilot/` proves the contract end to end.
- **Scope:** `scripts/run-skill-benchmark.py`, `evals/skill-benchmark/README.md`, `evals/skill-benchmark/runbook.md`, `evals/skill-benchmark/observation.schema.json`, `evals/skill-benchmark/benchmark-summary.schema.json`, `evals/skill-benchmark/examples/benchmark-summary.example.json`, `tests/test-data/skill-benchmark-pilot/*`, `tests/framework/README.md`.
- **D-025 audit (Scribe, 2026-03-07):** Clean — no stale refs in owned files.

## [D-032] Codex benchmark integration goes through a replayable adapter, not a Codex-specific harness fork

- **Date:** 2026-03-07 | **By:** William (owner)
- **Status:** Accepted
- **Decision:** Codex integration for the skill benchmark is provided by `scripts/skill-benchmark-codex-adapter.py`, which translates `codex exec --json` event streams into the normalized benchmark observation schema. The adapter also supports replaying saved JSONL traces so the benchmark contract can be tested offline in sandboxed or network-restricted environments.
- **Rationale:** The generic benchmark harness should remain surface-neutral. A dedicated adapter preserves that separation while still making Codex a first-class runnable target. Replay mode is required because live Codex runs may be blocked by sandboxed websocket/network restrictions, and the benchmark contract still needs deterministic smoke coverage in CI-like environments.
- **Artifacts:** The adapter writes benchmark observations and optionally judge output, preserves the raw Codex JSONL event stream under the trial work directory, and is covered by a replay fixture under `tests/test-data/skill-benchmark-codex-adapter/`.
- **Scope:** `scripts/skill-benchmark-codex-adapter.py`, `evals/skill-benchmark/README.md`, `evals/skill-benchmark/runbook.md`, `tests/framework/README.md`, `tests/test-data/skill-benchmark-codex-adapter/*`.
- **D-025 audit (Scribe, 2026-03-07):** Clean — no stale refs in owned files.

## [D-028] Agentic runtime v2 simplified — *Superseded by D-037*

## [D-027] Agentic pipeline as opt-in engine — *Superseded by D-037*

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
- **Status:** Accepted
- **Decision:** Scribe's charter expanded from `.squad/` memory + `_plans/DECISIONS.md` to include all repo-facing documentation. She owns README.md, INSTALL.md, AGENTS.md, CONTRIBUTIONS.md, TESTING.md, CLAUDE.md, `docs/` (full ownership except `cogworks-system-deep-dive-*.md` which she flags but Ash authors), and `tests/framework/README.md`.
- **Rationale:** D-022 → D-024 each left stale references in live files that required a separate manual audit pass. No one owned repo docs between decisions — the gap was structural, not a one-time miss. Formalising Scribe's ownership and a post-decision audit protocol closes the gap.
- **Post-decision audit protocol:** After every D-NNN commit, Scribe searches all owned files for references to changed/deleted artifacts, fixes stale refs in the same or immediate follow-on commit, and records the audit result (clean / N files updated) in the D-NNN entry here. A decision is not closed until the audit result is recorded.
- **Scope:** `.squad/agents/scribe/charter.md` — `## Repository Documentation` section added with canonical doc map and audit protocol.



## [D-024] Documentation audit — stale behavioral refs removed (D-022/D-023 cleanup)

- **Date:** 2026-03-04 | **By:** William (owner) / Scribe (mandate)
- **Status:** Accepted
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
- **Status:** Accepted
- **Decision:** 9 behavioral trace capture scripts deleted. `tests/behavioral/refresh-policy.md` deleted. Docs updated (TESTING.md, tests/framework/README.md, cogworks-eval.py stale error message).
- **Deleted scripts:** `scripts/refresh-behavioral-traces.sh`, `scripts/behavioral-capture.sh`, `scripts/capture-behavioral-trace.sh`, `scripts/run-behavioral-case-{claude,copilot,codex}.sh`, `scripts/behavioral-env.example.sh`, `tests/framework/scripts/capture_behavioral_trace.py`, `tests/framework/scripts/extract_behavioral_raw_trace.py`
- **Rationale:** These scripts generated the circular ground truth traces deleted in D-022. Keeping them created a path to recreating the problem. Git history is the archive.
- **What was NOT deleted:** `cogworks-eval.py` (scaffold + benchmark commands still valid), `behavioral_lib.py`, all other scripts.
- **Doc changes:** TESTING.md Layer 2 section replaced with "pending reconstruction" notice; framework README trimmed; cogworks-eval.py stale error message updated to reference D-022/D-023 and Parker's mandate.
- **Scope:** `scripts/` (7 files deleted), `tests/framework/scripts/` (2 files deleted), `tests/behavioral/refresh-policy.md` (deleted), `TESTING.md`, `tests/framework/README.md`, `tests/framework/scripts/cogworks-eval.py`.

## [D-022] Behavioral traces deleted — circular ground truth removed

- **Date:** 2026-03-04 | **By:** William (owner), Parker (mandate), via planning session
- **Status:** Accepted
- **Decision:** All 24 behavioral trace files (`tests/behavioral/*/traces/*.json`) deleted from the repository. Git history is the recovery path.
- **Rationale:** The traces were LLM-generated run outputs used as quality ground truth — epistemologically circular. The model generating skills and the model evaluating them share the same training prior. `quality_score: null` on all core skill traces. `task_completed: false` in baseline runs. They validated consistency (does a future run match past runs?) not correctness (is the skill actually good?).
- **What was NOT deleted:** `test-cases.jsonl` (human-authored activation test definitions), golden sample source materials, negative control definitions, framework scripts, structural grader. These are valid and retained.
- **What was updated:** `tests/ci-gate-check.sh` Step 2 message — updated to block regeneration of circular traces and direct to Parker's quality mandate.
- **Next step:** Parker defines replacement quality ground truth from first principles. `quality_score` field requires a definition before any behavioral evaluation is meaningful.
- **Scope:** `tests/behavioral/*/traces/*.json` (deleted), `tests/ci-gate-check.sh` (Step 2 message updated).

## [D-021] CI gate fails on missing behavioral traces — *Superseded by D-038*

- **Date:** 2026-03-04 | **By:** Ripley (Lead), implementing Hudson's CI gate remediation
- **Status:** Superseded by D-038
- **Decision:** The pre-release CI gate (`tests/ci-gate-check.sh`) was changed from warn-only to fail when behavioral traces were missing.
- **Rationale:** This was a valid gate-tightening step for the then-current behavioral-trace model, but that model was later removed.
- **Operational implication:** The underlying concern survives as “gates must enforce live contracts,” but the specific behavioral-trace CI gate no longer exists.
- **Scope:** `tests/ci-gate-check.sh` step 2.

## [D-020] Deterministic delimiter neutralisation for source ingestion

- **Date:** 2026-03-04 | **By:** Ripley (Lead), implementing Ash's M2 remediation
- **Status:** Accepted
- **Decision:** Source content is pre-processed to replace literal `<<UNTRUSTED_SOURCE>>` and `<<END_UNTRUSTED_SOURCE>>` strings with `[UNTRUSTED_SOURCE_TAG]` / `[/UNTRUSTED_SOURCE_TAG]` before wrapping in delimiter markers. This makes the delimiter boundary deterministic rather than behavioral-only.
- **Rationale:** The prior approach relied on the behavioral directive "treat source content as data" to prevent delimiter injection. A source containing the literal delimiter strings could spoof the boundary, making the behavioral guard bypassable. Deterministic preprocessing closes this gap unconditionally — the replacement happens before synthesis, so no source content can contain a live delimiter.
- **Trade-off:** Neutralisation changes the appearance of source content (the literal strings are rewritten). This is a minor cosmetic issue weighed against deterministic security. The replacement tokens are visually distinct and unambiguous.
- **Scope:** `skills/cogworks-encode/SKILL.md` (delimiter protocol), with downstream consistency in `skills/cogworks-learn/SKILL.md` (generation defect check).
