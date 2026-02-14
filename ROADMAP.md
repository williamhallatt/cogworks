# Cogworks Roadmap

This roadmap tracks planned work to address current known limitations in no particular order

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

## 3. Automated Testing

**Limitation**: No automated testing of new skills. Relies entirely on manual user feedback to identify issues.

**Work**:

- Design a testing strategy for validating synthesis output quality
- Build a test harness that can verify skill structure and correctness
- Add regression tests for known-good synthesis scenarios
- Consider snapshot-style testing for reference.md output stability

---

## 4. Skill Portability Across Repos

**Limitation**: Encoded skills are created in `.claude/skills/` within the repo where cogworks is used. No mechanism for sharing or reusing across projects.

**Work**:

- Define a portable skill format that can be copied between repos
- Explore a shared/global skill location outside individual repos
- Consider an import/export mechanism for skill distribution
- Ensure skills remain self-contained and don't rely on repo-specific context

---

## 5. Multi-Framework Support

**Limitation**: Output formats specifically target Claude Code structures. Skills may not work for other agent frameworks without modification.

**Work**:

- Define an intermediate representation that captures skill knowledge independent of framework
- Build adapter layer to export skills in formats for other frameworks (GitHub Copilot, etc.)
- Start with one additional framework to validate the adapter approach before expanding
- Keep Claude Code as the primary target; treat other frameworks as export targets
