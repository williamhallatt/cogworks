# AI Context Retrieval Risk Audit

*Date: 2026-03-07*
*Scope: all non-`.git` files present in the workspace, including ignored generated artifacts physically on disk*

## 1. Executive Summary

This repository contains several strong canonical surfaces, but they compete with many non-canonical surfaces that look equally authoritative to an AI agent. The main failure modes are:

- silent auto-loading of large instruction files
- duplicate decision records
- tracked generated artifacts that look like current truth
- large mixed-authority research corpora
- stale documents that still read like active runbooks
- production-shaped test fixtures that resemble live skills

The highest-risk files are:

- `.github/agents/squad.agent.md`
- `_plans/DECISIONS.md` and `.squad/decisions.md` together
- `.cogworks-runs/**`
- `tmp-agentic-output/**`
- `_sources/**`, especially `_sources/cc-docs/changelog.md`
- `TESTING.md` when read alongside `evals/**`
- `docs/testing-workflow-guide.md`

## 2. Coverage Summary By Directory Class

Audit coverage included every non-`.git` file visible in the workspace. The inventory was grouped into the following retrieval classes.

### Canonical or intended context surfaces

- `AGENTS.md`
- `CLAUDE.md`
- `README.md`
- `TESTING.md`
- `CONTRIBUTIONS.md`
- `INSTALL.md`
- `_plans/DECISIONS.md`
- active `_plans/*.md`
- `skills/**`
- `.claude/agents/**`
- `evals/**`

### High-risk non-canonical context surfaces

- `.github/agents/**`
- `.squad/**`
- `_sources/**`
- `_plans/archive/**`
- `.cogworks-runs/**`
- `tmp-agentic-output/**`
- `tests/results/**`
- `tests/test-data/**`
- `tests/datasets/golden-samples/**`
- `tests/behavioral/**/judge-prompt.md`

### File volume notes

- Total non-`.git` files scanned: about 907
- Largest directory classes:
  - `tests/`: about 590 files
  - `_sources/`: about 118 files
  - `.squad/`: about 75 files
  - `.cogworks-runs/`: 23 files
- Ignored but physically present:
  - `tests/results/`: about 496 files

## 3. Findings Ordered By Severity

### Critical: Auto-loaded alternative operating model

- Risk mechanism: silent auto-load hazard
- Files:
  - `.github/agents/squad.agent.md`
- Why this is risky:
  - GitHub Copilot auto-loads this file.
  - It is large enough to consume a meaningful share of context before the task even starts.
  - It defines a Squad-specific operating model that is not the default truth for normal cogworks work.
- Most affected: Copilot first, then any retrieval system indexing `.github/agents/`
- Recommendation:
  - Treat `.github/agents/` as scoped workspace material only.
  - Add a short sentinel at the top saying it is not default repo guidance for non-Squad work.
  - Keep the existing `AGENTS.md` warning, but make the non-default status explicit inside the file itself.

### Critical: Duplicate decision authority

- Risk mechanism: instruction conflict and wrong-authority retrieval
- Files:
  - `_plans/DECISIONS.md`
  - `.squad/decisions.md`
- Why this is risky:
  - `_plans/DECISIONS.md` explicitly says it is the context surface for settled decisions.
  - `.squad/decisions.md` is another consolidated decision log with authoritative language and synthesis recommendations.
  - An agent can retrieve the wrong decision ledger first and act on stale or Squad-local conclusions.
- Most affected: all agents
- Recommendation:
  - Keep `_plans/DECISIONS.md` as the only repo-wide decision surface.
  - Rename or clearly watermark `.squad/decisions.md` as Squad-local memory, not repo authority.

### Critical: Tracked generated run artifacts look canonical

- Risk mechanism: generated-artifact contamination
- Files:
  - `.cogworks-runs/api-auth-smoke-copilot-smoke/run-manifest.json`
  - `.cogworks-runs/api-auth-smoke-copilot-smoke/dispatch-manifest.json`
  - `.cogworks-runs/api-auth-smoke-copilot-smoke/stage-index.json`
  - `.cogworks-runs/api-auth-smoke-copilot-smoke/final-summary.md`
- Why this is risky:
  - These are tracked and use production contract names.
  - They read like current operational truth rather than disposable smoke evidence.
  - Retrieval systems can rank them above actual documentation because they are concrete and specific.
- Most affected: all agents
- Recommendation:
  - Move live run outputs to ignored scratch space by default.
  - If any example must remain tracked, add a clear "generated example artifact, not canonical guidance" marker at the directory root.

### Critical: Production-shaped generated skill outside `skills/`

- Risk mechanism: source-of-truth ambiguity
- Files:
  - `tmp-agentic-output/api-auth-smoke/SKILL.md`
  - `tmp-agentic-output/api-auth-smoke/reference.md`
  - `tmp-agentic-output/api-auth-smoke/metadata.json`
- Why this is risky:
  - This is a fully formed skill tree outside canonical `skills/`.
  - Its filenames and frontmatter make it indistinguishable from live instructions during naive retrieval.
  - `tests/agentic-smoke/README.md` normalizes generating into this path.
- Most affected: all agents
- Recommendation:
  - Ignore `tmp-agentic-output/` by default.
  - Move smoke outputs to an explicitly disposable directory.
  - Add a sentinel README saying the directory is generated scratch output, not a skill source of truth.

### Critical: Mixed-authority `_sources/` corpus

- Risk mechanism: research-corpus pollution
- Files:
  - `_sources/cc-docs/changelog.md`
  - `_sources/kane-synthesis-agent-skills.md`
  - `_sources/tdd/tdd-deep-research-report.md`
  - `_sources/tdd/tdd-deep-research-report-2.md`
  - `_sources/evals/openai-reference.md`
  - `_sources/skillsbench/skillsbench-paper.pdf`
  - `_sources/skillsbench/skillsbench-paper.docx`
- Why this is risky:
  - `_sources/` mixes primary source material, derivative syntheses, vendor doc dumps, and local notes under one authority-shaped namespace.
  - Very large files and highly polished syntheses are likely to outrank the underlying source materials.
  - `_sources/cc-docs/changelog.md` is especially bad: huge, vendor-derived, and stored as markdown-shaped content.
- Most affected: all agents
- Recommendation:
  - Split `_sources/` into at least `primary/`, `third-party-dumps/`, and `local-syntheses/`.
  - Add directory-level READMEs stating these files are reference material, not repo instructions.

### High: Testing authority conflict

- Risk mechanism: stale canonical guidance
- Files:
  - `TESTING.md`
  - `evals/README.md`
  - `evals/skill-benchmark/README.md`
- Why this is risky:
  - `TESTING.md` still says the benchmark implementation has been removed or is pending.
  - `evals/**` now documents a runnable pilot benchmark harness.
  - An agent can stop at `TESTING.md` and conclude the benchmark surface does not exist.
- Most affected: all agents
- Recommendation:
  - Reconcile `TESTING.md` with the current `evals/` state.
  - Make one file the canonical benchmark entry point and link to it from the other.

### High: Stale documents still read like active runbooks

- Risk mechanism: historical-memory pollution
- Files:
  - `docs/testing-workflow-guide.md`
  - `docs/cogworks-agent-risk-analysis.md`
  - `.squad/identity/now.md`
  - `_plans/2026-03-06-agentic-v2-next-session.md`
- Why this is risky:
  - These files use present-tense, current-state language while pointing to deleted commands, superseded plans, or already-resolved work.
  - `docs/testing-workflow-guide.md` references nonexistent `tests/behavioral/*/traces/` and `benchmarks/comparison/**` paths.
  - `.squad/identity/now.md` is named as if it is the current state but is stale.
  - `_plans/2026-03-06-agentic-v2-next-session.md` sits in the active plans root and still looks executable.
- Most affected: all agents
- Recommendation:
  - Either update these files or demote them with an archival banner.
  - Move completed session handoff files out of active `_plans/`.

### High: Live instruction fan-out and circular edit hazard

- Risk mechanism: auto-loaded instruction graph and context bloat
- Files:
  - `skills/cogworks/SKILL.md`
  - `skills/cogworks-encode/SKILL.md`
  - `skills/cogworks-learn/SKILL.md`
  - `.claude/agents/cogworks-*.md`
  - `skills/cogworks/copilot-adapter.md`
- Why this is risky:
  - The canonical skill stack is large and references many supporting files.
  - `AGENTS.md` already warns that editing these skills while they are loaded creates a circular state.
  - `skills/cogworks/copilot-adapter.md` also ties Copilot behavior to `.claude/agents/`, which hides a cross-surface dependency behind a Claude-shaped path.
- Most affected: Claude, Copilot, and any agent auto-loading skills
- Recommendation:
  - Keep `skills/**` canonical, but tighten the supporting-file graph.
  - Add explicit "load only when directly relevant" guidance to referenced adapter files, not just to `AGENTS.md`.

### High: Production-shaped test fixtures resemble live skills

- Risk mechanism: fixture/example ambiguity
- Files:
  - `tests/datasets/golden-samples/cogworks-learn/expected-skill/SKILL.md`
  - `tests/test-data/snapshot-cogworks-learn/SKILL.md`
  - `tests/test-data/snapshot-skill-evaluation/SKILL.md`
- Why this is risky:
  - These fixtures are realistic enough to be mistaken for the real skill source.
  - The filenames match live skill artifacts exactly.
  - During retrieval, `SKILL.md` often outranks the directory name that would have provided context.
- Most affected: all agents
- Recommendation:
  - Add sentinel READMEs in fixture roots.
  - Consider renaming fixture files where practical or prefixing fixture roots with a stronger non-canonical marker.

### High: Historical Squad logs and handoffs are easy to over-retrieve

- Risk mechanism: historical-memory pollution
- Files:
  - `.squad/agents/parker/history.md`
  - `.squad/log/2026-03-04T00:28Z-context-audit.md`
  - `.squad/orchestration-log/2026-03-05T00-58-00Z-parker-cogworks-judge-fix.md`
  - `.squad/team.md`
- Why this is risky:
  - These logs look like high-signal engineering evidence.
  - Some still reference deleted scripts or pre-remediation assumptions.
  - They are valuable to humans but dangerous as default retrieval material.
- Most affected: all agents
- Recommendation:
  - Add a `.squad/README.md` or top-level banner clarifying that `.squad/` is human coordination memory, not canonical runtime guidance.

### Medium: Duplicate end-user and install authority

- Risk mechanism: overlapping instructions
- Files:
  - `README.md`
  - `INSTALL.md`
  - `skills/cogworks/README.md`
  - `skills/cogworks/SKILL.md`
- Why this is risky:
  - Multiple files explain installation and usage from slightly different angles.
  - The live-edit and auto-load hazards are documented strongly in `AGENTS.md`, but not carried through all user-facing install surfaces.
- Most affected: all agents
- Recommendation:
  - Choose one end-user install surface and one contributor surface.
  - Link outward rather than restating behavior in multiple places.

### Medium: Archive and history naming still competes with active work

- Risk mechanism: directory-shape retrieval trap
- Files:
  - `_plans/archive/**`
  - `docs/cross-agent-compatibility.md`
  - `.squad/routing.md`
  - `.squad/ceremonies.md`
- Why this is risky:
  - Even when archived correctly, files with strong nouns like "compatibility", "routing", or "decisions" still look canonical.
  - Retrieval systems often score by filename and recency before subtle in-file caveats.
- Most affected: all agents
- Recommendation:
  - Add explicit archival or scope banners at the top of these files.
  - Prefer directory names that encode non-default status more strongly.

### Medium: Evaluator prompts and replay traces can bias implementation work

- Risk mechanism: test-only context pollution
- Files:
  - `tests/behavioral/cogworks/judge-prompt.md`
  - `tests/behavioral/cogworks-encode/judge-prompt.md`
  - `tests/test-data/behavioral-capture/claude-events-sample.jsonl`
  - `tests/test-data/behavioral-capture/codex-events-sample.jsonl`
  - `tests/test-data/skill-benchmark-codex-adapter/candidate-a-events.jsonl`
- Why this is risky:
  - These are legitimate test assets, but they contain evaluator language and realistic traces that can distort implementation reasoning if loaded out of context.
- Most affected: all agents
- Recommendation:
  - Add stronger "test-only; never load as runtime guidance" markers in `tests/behavioral/` and `tests/test-data/`.

### Low: Script output naming reinforces artifact authority

- Risk mechanism: generated naming patterns
- Files:
  - `scripts/run-engine-performance-compare.sh`
  - `scripts/run-recursive-round.sh`
  - `scripts/test-generated-skill.sh`
  - `scripts/run-skill-benchmark.py`
- Why this is risky:
  - These scripts emit highly authoritative artifact names such as `benchmark-summary.json`, `benchmark-report.md`, and `metrics.json`.
  - The main risk is not the scripts but the output trees they normalize.
- Most affected: all agents
- Recommendation:
  - Keep the scripts, but standardize artifact roots as disposable and clearly non-canonical.

## 4. Generated And Artifact Pollution

The repository already acknowledges one major artifact risk: `TESTING.md` explicitly warns that `tests/results/` can leak into AI context and recommends cleaning it before an AI session. That is good policy.

The problem is uneven application:

- `tests/results/` is ignored, documented, and recognized as risky.
- `.cogworks-runs/` is tracked and not marked as generated.
- `tmp-agentic-output/` is not ignored and contains production-shaped skill output.
- `tests/test-data/` and `tests/datasets/golden-samples/` contain realistic instruction-like fixtures without a stronger non-canonical marker.

This means the repo already knows the failure mode, but only one artifact class is consistently treated as dangerous.

## 5. Recommended Cleanup Plan

1. Define the default retrieval contract in one place.
   - Default-load only `AGENTS.md`, `_plans/DECISIONS.md`, active `_plans/*.md`, top-level product docs, and directly relevant canonical `skills/**` files.
2. Quarantine generated outputs.
   - Move `.cogworks-runs/` and `tmp-agentic-output/` to ignored scratch space or add unmistakable generated-content markers.
3. Split mixed-authority corpora.
   - Restructure `_sources/` so primary material, dumps, and local syntheses do not compete under one namespace.
4. Fix stale canonical docs first.
   - Reconcile `TESTING.md` with `evals/**`.
   - Either update or archive `docs/testing-workflow-guide.md`, `docs/cogworks-agent-risk-analysis.md`, and `_plans/2026-03-06-agentic-v2-next-session.md`.
5. Mark fixtures and logs aggressively.
   - Add top-level READMEs or banners to `.squad/`, `tests/test-data/`, `tests/datasets/golden-samples/`, `.cogworks-runs/`, and `tmp-agentic-output/`.
6. Reduce duplicate authority.
   - Demote `.squad/decisions.md` from repo-wide authority.
   - Collapse overlapping install and usage guidance to one canonical surface.

## 6. Residual Risks That Should Remain But Be Documented

Some risk is structural and acceptable if documented clearly:

- `skills/**` must remain a live instruction surface.
- `_sources/**` is useful for research and synthesis work.
- `tests/test-data/**` and `tests/datasets/**` are necessary for benchmark and harness development.
- `.squad/**` is useful as human coordination memory.

The key is not to delete these surfaces by default. The key is to stop them from competing with canonical instructions during ordinary agent retrieval.
