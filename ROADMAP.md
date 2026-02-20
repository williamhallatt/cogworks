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

## 3. OpenAI Codex Support ✅ COMPLETED (2026-02-19)

**Delivered**:

- Codex-native workflow via `.agents/skills/cogworks`
- Codex-compatible skill copies for `cogworks-encode`, `cogworks-learn`, and `cogworks-test`
- Installer support via `./install.sh --target codex --local|--global` (installs to `./.agents/skills` or `~/.agents/skills`)

**Limitations**:

- The Claude `@cogworks` agent remains Claude Code-specific
- The Claude test framework is optional for Codex users

---

## 4. Automated Testing ✅ COMPLETED (2026-02-14)

**Previous Limitation**: No automated testing of new skills. Relied entirely on manual user feedback to identify issues.

**Implemented Solution**:

A comprehensive testing framework using layered grading methodology from the skill-evaluation skill:

- **Layer 1: Deterministic checks** - Bash script for fast structural validation (structure, syntax, citations, line counts)
- **Layer 2: LLM-as-judge** - Claude Opus 4.6 evaluates content quality across 5 dimensions with weighted scoring
- **Layer 3: Human review** - Optional calibration and dispute resolution

**Components Created**:

1. **cogworks-test skill** (`.claude/skills/cogworks-test/`) - Testing orchestration
2. **Test infrastructure** (`.claude/test-framework/`) - Graders, rubrics, configuration, templates
3. **Golden samples** (`tests/datasets/golden-samples/`) - Known-good skills for regression testing
4. **Negative controls** (`tests/datasets/negative-controls/`) - Intentionally flawed scenarios
5. **Integration** - Added Step 6.5 to cogworks workflow for opt-in testing via `--test` flag

**Quality Dimensions** (from CLAUDE.md requirements):

- Source Fidelity (30%) - Traceability, no fabrication
- Self-Sufficiency (25%) - Standalone understanding
- Completeness (20%) - Scope coverage
- Specificity (15%) - Actionable patterns
- No Overlap (10%) - Novel value

**Success Threshold**: Overall score ≥0.85 with zero critical failures

**Usage**:

```bash
# Test generated skill
/cogworks-test deployment-skill

# Generate with testing
@cogworks encode sources/ --test

# Regression test suite
for sample in tests/datasets/golden-samples/*/; do
    /cogworks-test $(basename $sample) --compare-against $sample
done
```

**Cost & Performance**: ~$1.50 and <1 minute per skill (Layer 1 + Layer 2)

See `.claude/test-framework/README.md` for complete documentation.

---

## 5. Skill Portability Across Repos

**Limitation**: Encoded skills are created in `.claude/skills/` within the repo where cogworks is used. No mechanism for sharing or reusing across projects.

**Work**:

- Define a portable skill format that can be copied between repos
- Explore a shared/global skill location outside individual repos
- Consider an import/export mechanism for skill distribution
- Ensure skills remain self-contained and don't rely on repo-specific context

---

## 6. Multi-Framework Support

**Limitation**: Output formats specifically target Claude Code structures. Skills may not work for other agent frameworks without modification.

**Work**:

- Define an intermediate representation that captures skill knowledge independent of framework
- Build adapter layer to export skills in formats for other frameworks (GitHub Copilot, etc.)
- Start with one additional framework to validate the adapter approach before expanding
- Keep Claude Code as the primary target; treat other frameworks as export targets
