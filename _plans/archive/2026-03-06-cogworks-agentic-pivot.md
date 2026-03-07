# Cogworks Agentic Pivot Plan

## Summary
Refactor cogworks from a prompt-only skill-orchestrated pipeline into a platform-agnostic agentic pipeline core with a Claude-first orchestration adapter, while preserving generated skills as the primary output artifact.

The first release should:
- keep `/cogworks encode` semantics intact for the legacy path
- add an explicit opt-in agentic mode
- use sub-agents internally for synthesis, critique, composition, and validation
- continue producing portable generated skills in `_generated-skills/`
- preserve benchmarkability, machine-readable artifacts, and evidence-backed quality claims

The plan treats Squad as a design reference only. It does not adopt the Squad SDK as a runtime dependency because Squad is Copilot-specific and cogworks needs a portable orchestration core.

## Architecture Changes
### 1. Introduce a new core runtime
Create a new internal subsystem, conceptually `cogworks-agentic`, with three layers:

- `pipeline core`
  - canonical stage graph for encode flow
  - stage contracts, artifact schemas, failure semantics, retry policy
  - no Claude/Copilot-specific assumptions
- `role model`
  - fixed specialist roles for the generation workflow
  - role prompts derived from current `cogworks`, `cogworks-encode`, and `cogworks-learn` doctrine
- `platform adapters`
  - Claude adapter first
  - Copilot adapter later
  - fallback single-agent executor for environments without subagents

The pipeline core owns artifact flow and acceptance gates. Adapters only execute stages and return typed outputs.

### 2. Define the agent roles and responsibilities
The agentic pipeline should use these roles:

- `ingest-researcher`
  - source loading, provenance classification, capability inventory, derivative-source detection
- `synthesizer`
  - 8-phase synthesis execution and production of synthesis artifacts
- `skeptic`
  - contradiction audit, authority ranking, omission detection, superficiality checks
- `decision-architect`
  - Decision Skeleton extraction and skill-oriented restructuring
- `skill-composer`
  - SKILL.md, `reference.md`, `metadata.json`, packaging
- `validator`
  - deterministic gates, drift/generalization probes, artifact completeness checks
- `coordinator`
  - stage sequencing, retries, artifact assembly, final user-facing summary

Defaults:
- no recursive sub-agent spawning
- coordinator is the only role allowed to dispatch other roles
- each specialist returns structured artifacts plus a compact summary
- verbose reads, scratch reasoning, and probe output stay isolated in sub-agent context where supported

### 3. Define the stage graph
Replace the current implicit workflow with an explicit stage machine:

1. `source-ingest`
2. `source-audit`
3. `synthesis`
4. `synthesis-critique`
5. `decision-architecture`
6. `skill-composition`
7. `deterministic-validation`
8. `generalization-probe`
9. `final-review-package`

Each stage must emit:
- `stage-status.json`
- typed artifact payloads
- blocking failures
- provenance links to upstream artifacts

Blocking rule:
- downstream stages may not run on missing or empty required artifacts
- critique/validation failures loop back only to the owning upstream stage
- user approval remains between synthesis summary and final file write, matching current expectations

### 4. Preserve and reframe existing cogworks assets
Do not discard current skills. Reuse them as doctrine sources for role prompts and validation criteria.

Map existing assets as follows:
- `cogworks` becomes the product-facing orchestrator contract and migration shell
- `cogworks-encode` becomes the synthesis doctrine for `synthesizer` and `skeptic`
- `cogworks-learn` becomes the composition doctrine for `decision-architect`, `skill-composer`, and `validator`

Current deterministic scripts and benchmark harnesses remain authoritative for quality gating. New agentic stages must emit machine-readable artifacts consumable by the existing benchmark/report stack with minimal adapter glue.

### 5. Claude-first adapter
Build the first working adapter around Claude subagents.

Adapter requirements:
- generate project-scoped subagent definitions or equivalent invocation payloads
- assign tools per role
- isolate verbose stages in subagent contexts
- enforce no-subagent-spawns-subagents
- capture stage summaries and normalized artifact outputs back to coordinator

Tool defaults by role:
- `ingest-researcher`, `skeptic`, `validator`: read-heavy, minimal write
- `skill-composer`: write access only to staging/output paths
- `coordinator`: no broad write authority beyond orchestration state and final output assembly

The Claude adapter is the first production target. Copilot support is a planned second adapter, not a blocker for v1.

## Public Interfaces And User Experience
Keep the current command contract intact, but add an opt-in engine selector.

### User-facing behavior
- existing path remains default: `/cogworks encode ...`
- add agentic opt-in:
  - command flag or explicit mode phrase, for example `--engine agentic`
  - equivalent natural-language invocation accepted by the orchestrator skill
- generated skills remain the primary artifact and installation path remains `npx skills add`

### New internal/public interfaces
Define stable internal contracts for:
- `PipelineStageResult`
- `ArtifactRef`
- `BlockingFailure`
- `RoleTaskSpec`
- `ExecutionAdapter`
- `RunManifest`
- `BenchmarkMetrics`

The agentic engine must write a run directory with:
- stage artifacts
- summaries
- timing and model metadata
- quality gate results
- benchmark-consumable summary JSON

This is required so quality claims remain reproducible and comparable to the legacy pipeline.

## Testing And Acceptance
### Test plan
Add or adapt tests in four groups:

- `core contract tests`
  - stage dependency enforcement
  - missing-artifact blocking
  - retry and failure routing
  - coordinator non-recursive dispatch rules
- `Claude adapter tests`
  - role-to-tool policy mapping
  - artifact normalization from subagent summaries
  - background/isolated execution constraints
- `parity tests`
  - same input through legacy and agentic pipelines
  - compare structural outputs and gate artifacts
  - report omissions in both directions
- `benchmark tests`
  - extend Layer 3 benchmark to include `legacy` vs `agentic`
  - require machine-readable `benchmark-summary.json` and human-readable `benchmark-report.md`
  - no “better” claims without saved benchmark artifacts

### Acceptance criteria
The pivot is ready to promote from opt-in when:
- agentic runs preserve all current Layer 1 deterministic guarantees
- required artifact schemas are emitted for every run
- benchmark protocol shows non-regressive structural quality
- agentic pipeline demonstrates equal or better behavioral delta once the behavioral harness is fully operational
- installation and final output remain portable skills by default
- docs clearly distinguish `legacy` engine, `agentic` engine, and future platform-specific outputs

## Assumptions And Defaults
- First release is `skills + agentic runtime`, not agent-pack-only.
- Claude subagents are the first execution target; Copilot custom-agent support follows after core stabilization.
- Rollout is opt-in first; legacy remains default until benchmark evidence justifies promotion.
- Squad SDK is not adopted as a dependency; only its architectural patterns inform the design.
- Existing `_generated-skills/` staging and `npx skills add` flow remain unchanged in v1.
- Existing skills remain in repo and continue serving both users and internal doctrine extraction.
