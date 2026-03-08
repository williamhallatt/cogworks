# Rebuild Cogworks for Trust, Quality, and One World-Class User Flow

## Summary

Rebuild `cogworks` around a single principle: maximize the quality of generated
skills while minimizing user and context burden.

Target product:

- one user-facing `cogworks` skill entry point
- user provides source material in natural language
- `cogworks` returns either a production-ready generated skill or a blocking
  trust report
- Claude Code and GitHub Copilot use internal specialist sub-agents where that
  genuinely improves quality
- Codex is deferred from the sub-agent architecture for now
- validation and benchmarking become maintainer surfaces, not part of the
  normal user experience

This reset removes pseudo-CLI behavior, engine flags, exposed runtime jargon,
and architecture that exists mainly to describe itself.

## Architecture

### 1. Product surface

- Keep exactly one end-user skill: `cogworks`.
- Remove user-facing pipeline-selection concepts such as `--engine agentic`,
  `legacy`, `adapter`, and similar internal language.
- Invocation model:
  - user invokes `cogworks`
  - user provides links, files, directories, or topic/source requests in
    natural language
  - `cogworks` chooses the internal execution strategy automatically
- The user experience must be concise and guided:
  - ask only for missing required inputs
  - ask only when a trust decision or destination decision is unavoidable
  - otherwise proceed with strong defaults

### 2. Agent skills vs sub-agents

- `Agent skills` remain the reusable doctrine layer:
  - `cogworks` is the only normal product entry point
  - `cogworks-encode` remains reusable synthesis doctrine
  - `cogworks-learn` remains reusable skill-authoring doctrine
- `Sub-agents` are internal execution workers only:
  - source intake
  - synthesis
  - skill packaging
  - deterministic validation
- Support skills should not behave like separate user-facing pipeline stages in
  normal usage.
- Specialist sub-agents should be thin wrappers around doctrine plus
  stage-specific boundaries, not parallel long-form knowledge systems.

### 3. Surface strategy

- Claude Code:
  - first-class implementation
  - use real sub-agents internally
- GitHub Copilot CLI:
  - first-class only if native sub-agent/task delegation is proven locally and
    kept honest
  - use the same conceptual stages, but avoid extra abstraction if Copilot
    needs a different execution binding
- Codex:
  - explicitly deferred from sub-agent support
  - do not let Codex limitations distort Claude/Copilot architecture in this
    phase
- Do not claim parity across agents unless the implementation and tests prove
  it.

### 4. Trust model

- Default behavior is fail-closed.
- If source trust, contradiction handling, provenance, or synthesis confidence
  is insufficient, do not emit a production-ready skill.
- In those cases, emit a concise user-facing trust report describing:
  - what blocked generation
  - what evidence was missing or conflicting
  - what the user must provide or clarify
- Do not produce "best effort" final skills under uncertainty.
- The final product contract is binary:
  - production-ready generated skill
  - or no generated skill, with a blocking trust report

## Implementation Changes

### 1. Simplify the `cogworks` skill contract

- Rewrite `skills/cogworks/SKILL.md` so it reads like a native skill, not a
  command parser.
- Remove the pseudo-CLI framing from top-level docs and examples.
- Present `cogworks` as a single capability: turn source material into a
  trustworthy generated skill.
- Keep examples natural and surface-native, without exposing internal engine
  choice.

### 2. Internal execution flow

- Coordinator responsibilities:
  - collect inputs
  - classify source set risk
  - dispatch specialists
  - enforce trust gates
  - decide ready vs blocked
  - present concise final result
- Specialist stages:
  - `source-intake`: inventory, provenance, trust classification
  - `synthesis`: produce structured synthesis with contradiction handling and
    traceability
  - `skill-packaging`: convert synthesis into skill files
  - `deterministic-validation`: enforce structural and policy gates
- Final review stays with the coordinator and should be small.
- No nested specialist spawning.
- No exposed "runtime contract" vocabulary in user-facing surfaces.

### 3. Minimize duplication

- Keep one canonical synthesis doctrine and one canonical skill-authoring
  doctrine.
- If role profiles remain, they must be short and execution-oriented.
- Remove or collapse any docs whose main purpose is to restate the same flow in
  different words.
- Prefer fewer surfaces with stronger contracts over many descriptive files.

### 4. Move evaluation out of the product path

- Normal user runs perform deterministic validation only.
- Benchmarking, comparative evaluation, quality experiments, and smoke proofs
  live under maintainer-only tooling.
- Maintainer tooling may validate:
  - sub-agent orchestration quality
  - surface parity claims
  - generated-skill quality benchmarks
- None of that should distort the normal `cogworks` user flow or output
  structure.

### 5. Repository/context hygiene

- Default retrieval surfaces should center on the current product contract, not
  historical runtime experiments.
- Keep maintainer evidence and smoke artifacts in clearly marked non-default
  locations.
- Remove references that teach users or future agents to think of `cogworks` as
  a fake CLI or runtime product.

## Public Interfaces

- End-user:
  - one `cogworks` skill
  - one stable invocation model
  - no public engine selection
  - no public adapter selection
- Maintainer:
  - explicit benchmark and smoke tooling under `scripts/` and `evals/`
  - explicit surface-specific smoke tests for Claude and Copilot
- Output contract:
  - success: generated skill package that passes deterministic validation
  - failure: no final skill package; instead a blocking trust report

## Test Plan

- User-flow tests:
  - invoke `cogworks` with clean sources and confirm it produces a valid skill
    without unnecessary prompts
  - invoke `cogworks` with conflicting/untrusted/insufficient sources and
    confirm it fails closed with a clear trust report
- Claude tests:
  - end-to-end sub-agent build succeeds
  - specialist boundaries are respected
  - deterministic validation gates final output
- Copilot tests:
  - prove real delegated execution if claimed
  - otherwise fail closed and mark the surface unsupported for this phase
- Deterministic product tests:
  - generated `SKILL.md`, `reference.md`, and `metadata.json` pass existing
    structural validators
- Repo hygiene tests:
  - no user-facing docs mention `--engine agentic` or equivalent internal
    runtime controls
  - benchmark and smoke artifacts remain outside normal product surfaces

## Assumptions and Defaults

- Quality and trust outrank architecture purity or backward compatibility.
- The generated skill is the only primary product artifact.
- The build system should be invisible to users except where trust requires
  explanation.
- Sub-agents are internal implementation machinery, used only where they
  improve quality or context isolation.
- Claude and Copilot are the target execution surfaces for this reset.
- Codex sub-agent support is deferred rather than simulated.
- Default product behavior is fail-closed with concise guided UX.
