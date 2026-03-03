# Cogworks Deep Dive: Agent Risk Analysis

**Requested by:** William Hallatt
**Date:** 2026-03-03
**Purpose:** Expert solution architect analysis of cogworks repository to understand
how it works and identify what might adversely affect AI agents (GitHub Copilot,
OpenAI Codex, Claude Code) both *working on* and *using* cogworks tools.

---

## Problem Statement

cogworks is an LLM-as-executor pipeline. Every stage is carried out by inference
rather than compiled code. This creates a unique class of risk: the same agents
that *build and maintain* the toolchain are also *consumers* of it, and the toolchain
itself encodes instructions that guide agent behaviour. Understanding failure modes,
brittleness, and adversarial surface requires reading the repo as both a contributor
and a user simultaneously.

The analysis must cover two distinct modes:

1. **Working on cogworks** — agents contributing to, testing, or maintaining the repo
2. **Using cogworks** — agents invoking `/cogworks encode`, `/cogworks-encode`, or
   `/cogworks-learn` to produce skills

---

## Approach

Spawn a solution architect sub-agent with deep LLM/agent knowledge to conduct the
deep dive. The architect will read the full codebase, synthesize findings across
dimensions, and produce a structured risk analysis document saved to
`docs/cogworks-agent-risk-analysis.md`.

---

## Analysis Dimensions

The architect will investigate each dimension independently, then synthesize:

### D1 — Skill Activation Risks
- What prompts accidentally trigger cogworks (false positives in auto-load)
- What prompts fail to trigger it when expected (false negatives)
- The description field's keyword precision and its failure modes
- `disable-model-invocation` patterns and where they're absent

### D2 — Security Boundary Analysis
- Prompt injection via source content (URLs, files, directories)
- Trust classification protocol completeness — what's classified, what isn't
- `<<UNTRUSTED_SOURCE>>` delimiter protocol and bypass conditions
- Data-only execution rule: what breaks it, what enforces it
- Untrusted source escalation paths

### D3 — Pipeline State Machine Reliability
- The 7-step linear workflow's failure modes at each step
- Internal scaffolding artifacts (handoff variables) — what breaks if they're absent
- Step 3.5 (decision skeleton extraction) as a fragile bridge
- Overwrite logic and slug collision behaviour

### D4 — Model Capability Dependencies
- What happens when a weak model (Haiku, GPT-3.5) runs the full pipeline
- The warning gate: does it stop or just warn?
- Which phases are most sensitive to capability degradation
- Phase 2 calibration check (concatenation vs synthesis)

### D5 — Context Window Pressure
- The 8-phase synthesis is context-heavy; where does it overflow?
- Progressive disclosure architecture: does it actually reduce pressure?
- Large-file protocol (view_range chunking) — completeness vs truncation risk
- How cogworks-learn's staged generation contract handles context limits

### D6 — Cross-Agent Compatibility
- Differences in how Claude Code, Codex, and Copilot handle SKILL.md loading
- Invocation syntax differences (`/` vs `$` vs other prefixes) — coverage gaps
- Tool restriction (`allowed-tools`) semantics across agents
- Argument interpolation (`$ARGUMENTS`, `$N`) — which agents support it
- The dependency check (step 1) — which agents surface missing skill errors well

### D7 — Self-Referential / Circular Dependency Risks
- Agents *using* cogworks to improve cogworks (the recursive improvement round)
- The cogworks-learn skill itself enforcing quality gates on generated cogworks skills
- An agent editing `cogworks/SKILL.md` while running under its instructions
- What happens to in-flight workflows when skills are updated mid-session

### D8 — Testing Framework Gaps
- What the three test layers don't cover
- Behavioral tests relying on stored traces — staleness risk
- Layer 1 structural checks vs semantic correctness
- Offline vs real mode: what CI actually validates

### D9 — File System Side Effect Risks
- `_generated-skills/` directory creation and write behaviour
- Overwrite prompt — agents that auto-confirm without user input
- Version bump logic (reads existing metadata.json) — what if it's malformed
- Multiple agents writing to same skill directory concurrently

### D10 — Working ON the Codebase (Contributor Risks)
- Agents auto-loading cogworks skills while editing them (instructions change mid-edit)
- The `.claude/skills/` symlinks — agents reading stale vs live content
- Commit conventions and what breaks CI (`pre-release-validation.yml`)
- The `skills-lock.json` — what it governs and risks of drift

---

## Deliverable

A structured document at `docs/cogworks-agent-risk-analysis.md` containing:

1. **Executive Summary** — top 5 risks with severity/likelihood ratings
2. **Finding per dimension** — D1–D10, each with: observation, risk, severity, mitigation
3. **Agent-specific notes** — per-agent (Copilot, Codex, Claude Code) summary of unique risks
4. **Working ON vs Using** — separate risk tables for contributors vs consumers
5. **Recommended mitigations** — prioritised, actionable list

---

## Todos

| ID | Title |
|----|-------|
| `explore-codebase` | Read all skill files, tests, scripts, and security-relevant code |
| `analyze-dimensions` | Analyze D1–D10, producing findings per dimension |
| `synthesize-report` | Synthesize into the risk analysis document |
| `save-plan` | Archive this plan to `_plans/` on completion |
