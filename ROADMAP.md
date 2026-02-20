# Cogworks Roadmap

This roadmap tracks outstanding work only. Completed items have been removed.

---

## 1. Platform Portability

**Limitation**: Cogworks assumes Linux (Ubuntu). Hardcoded paths exist throughout agent and skill definitions.

**Work**:

- Audit all agent definitions (`.claude/agents/*.md`) and skill definitions (`.claude/skills/`) for hardcoded paths
- Replace absolute paths with platform-relative or dynamically resolved paths
- Test on Windows, macOS and common Linux distributions
- Document any remaining platform-specific requirements

---

## 2. Agent Generation (`cogworks`)

**Limitation**: `cogworks` for generating sub-agents is planned but not yet available.

**Work**:

- Add a new skill for generating sub-agent definitions (`.claude/agents/*.md`)
- Upgrade `cogworks` to consider user needs and knowledge synthesised, and decide on the best tool for the task (skill or sub-agent)
- Define agent templates with proper structure (description, tools, workflow)
- Establish clear criteria for when a skill vs. an agent is the appropriate output
- Support both automatic recommendation (cogworks decides) and explicit user choice

---

## 3. Skill Distribution and Reuse

**Current gap**: Skills are portable as `SKILL.md`-based assets, but distribution workflows are still manual and inconsistent across teams.

**Work**:

- Define a first-class import/export workflow for skill packs
- Add versioned metadata for shared skill distribution
- Standardize sharing patterns across project-local and user-global installs
- Ensure packaged skills remain self-contained with no repo-specific coupling

---

## 4. Multi-Framework Support

**Current gap**: Generated skills are broadly portable, but orchestration behavior and validation tooling are still optimized for Claude/Codex pipelines.

**Work**:

- Define an intermediate representation for workflow-level portability
- Build adapter layers for at least one additional runtime beyond Claude/Codex
- Validate parity expectations between pipeline-specific variants
- Keep Claude/Codex as primary targets while formalizing export boundaries
