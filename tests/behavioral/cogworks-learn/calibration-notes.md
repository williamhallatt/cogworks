# Calibration Notes — cogworks-learn
**Date:** 2026-03-05
**Judge prompt version:** Five dimensions — parallel_instruction, subagent_delegation, cc_feature_labeling, allowed_tools_accuracy, compatibility_field
**Calibrated against:** cogworks-learn-parallel-001, cogworks-learn-subagent-001, cogworks-learn-subagent-002, cogworks-learn-persistent-001, cogworks-learn-arguments-001, cogworks-learn-compatibility-001, cogworks-learn-allowed-tools-001

**Note on calibration data schema:** cogworks-learn quality cases do not use the `evaluator_notes` / `ground_truth` fields used by quality_gate cases in cogworks and cogworks-encode. They use `notes`, `expected_content`, and `forbidden_content` instead. This is a schema divergence across the test suite. The calibration data is functionally equivalent — `expected_content` maps directly to rubric pass signals — but reviewers should be aware that the field names differ.

---

## Case-by-case analysis

### cogworks-learn-parallel-001
- **Expected behavior (from notes/expected_content):** A skill for analyzing code quality across multiple TypeScript files must instruct the agent to make all independent file reads in parallel. Expected content: `["Make all independent tool calls in parallel", "parallel"]`.
- **Rubric dimension(s) that cover this:** `parallel_instruction` — dimension 1 is purpose-built for this case. Pass signal "Skill explicitly states 'make all independent tool calls in parallel'" matches the expected_content exactly. Fail signal "Skill uses numbered steps for operations that have no ordering dependency" would catch a sequential-step implementation.
- **Gap identified:** No.
- **Calibration verdict:** covered

### cogworks-learn-subagent-001
- **Expected behavior (from notes/expected_content):** A skill for running test suites and summarizing failures must include subagent delegation guidance. Expected content: `["Delegate this task to a subagent", "subagent", "summary"]`.
- **Rubric dimension(s) that cover this:** `subagent_delegation` — dimension 2 pass signal "Skill explicitly states 'Delegate this task to a subagent'" matches the expected_content phrase exactly. Fail signal "No mention of subagent delegation for operations that produce large outputs" covers the omission case.
- **Gap identified:** No.
- **Calibration verdict:** covered

### cogworks-learn-subagent-002
- **Expected behavior (from notes/expected_content):** A Claude Code batch log analysis skill must reference subagent delegation and label `context: fork` as Claude Code-only. Expected content: `["subagent", "context: fork", "[Claude Code only]"]`.
- **Rubric dimension(s) that cover this:** `subagent_delegation` covers the delegation requirement and mentions `context:fork` in the CC-specific pass signal. `cc_feature_labeling` covers the requirement to annotate `context:fork` with "[Claude Code only]". Both dimensions apply and both pass signals map to the expected content.
- **Gap identified:** No.
- **Calibration verdict:** covered

### cogworks-learn-persistent-001
- **Expected behavior (from notes/expected_content):** A skill for enforcing code style rules that apply to every session should recommend persistent configuration (CLAUDE.md, copilot-instructions.md) rather than a skill. Expected content: `["CLAUDE.md", "copilot-instructions.md", "persistent configuration", "always-on"]`.
- **Rubric dimension(s) that cover this:** None of the five dimensions address whether a skill is the appropriate artifact for the request. `parallel_instruction`, `subagent_delegation`, `cc_feature_labeling`, `allowed_tools_accuracy`, and `compatibility_field` all evaluate the quality of a skill that was produced — none evaluate whether a skill should have been produced at all. The expected behavior is a meta-level routing decision (redirect to persistent config), not a skill authoring decision.
- **Gap identified:** Yes — no rubric dimension covers "scope appropriateness" or "skill vs. persistent-config routing." A cogworks-learn run that generates a well-structured SKILL.md with correct CC labels and parallel instruction for a task that should instead go to CLAUDE.md would pass all five dimensions with no penalty.
- **Calibration verdict:** gap

### cogworks-learn-arguments-001
- **Expected behavior (from notes/expected_content/forbidden_content):** A skill using `$ARGUMENTS` must label it as Claude Code-specific, note it is not in the agentskills.io spec, and include a compatibility field. Expected: `["Claude Code", "$ARGUMENTS", "compatibility", "not in agentskills.io spec"]`. Forbidden: `["universal", "standard"]`.
- **Rubric dimension(s) that cover this:** `cc_feature_labeling` — dimension 3 pass signal "skill notes that agentskills.io spec does not include $ARGUMENTS" matches the expected_content requirement exactly. Forbidden content ("universal", "standard") maps to the fail signal "Any of these described as 'standard', 'universal', or part of the agentskills.io spec." `compatibility_field` covers the frontmatter requirement. Both dimensions apply.
- **Gap identified:** No. The judge prompt calibration notes explicitly reference this case with matching expected signal language.
- **Calibration verdict:** covered

### cogworks-learn-compatibility-001
- **Expected behavior (from notes/expected_content):** A skill using `disable-model-invocation` and `$ARGUMENTS` must include a `compatibility:` field in YAML frontmatter listing both CC-specific features. Expected: `["compatibility:", "Claude Code", "disable-model-invocation", "$ARGUMENTS"]`.
- **Rubric dimension(s) that cover this:** `compatibility_field` — dimension 5 pass signal "compatibility: field lists each CC-specific feature used in the skill" and "Field format is valid YAML within the frontmatter block" map exactly. `cc_feature_labeling` covers inline labeling of both features in the skill body. The calibration note in the judge prompt explicitly states the compatibility field "must appear in frontmatter YAML, not just be mentioned in body prose."
- **Gap identified:** No.
- **Calibration verdict:** covered

### cogworks-learn-allowed-tools-001
- **Expected behavior (from notes/expected_content/forbidden_content):** A skill with restricted tool access must describe `allowed-tools` as broadly supported across 16/18 agents. Expected: `["allowed-tools", "broadly supported", "16/18"]`. Forbidden: `["experimental", "Claude Code-only"]`.
- **Rubric dimension(s) that cover this:** `allowed_tools_accuracy` — dimension 4 fail signals "allowed-tools described as 'experimental'" and "allowed-tools described as a Claude Code-only feature" map exactly to the forbidden content. Pass signal "allowed-tools described as 'broadly supported' with approximate support count (16/18 or equivalent)" matches the expected content. The judge prompt calibration note references this case with the same three expected tokens.
- **Gap identified:** No.
- **Calibration verdict:** covered

---

## Summary

- **Coverage:** 6/7 cases fully covered (parallel-001, subagent-001, subagent-002, arguments-001, compatibility-001, allowed-tools-001)
- **Gaps found:**
  1. **Scope appropriateness / skill vs. persistent-config routing** (persistent-001): No rubric dimension evaluates whether a skill is the right artifact for the request. Always-on rules that belong in persistent config (CLAUDE.md, copilot-instructions.md) cannot be caught by any of the five dimensions, which all assume a skill is being produced and evaluate its quality.
- **Judge prompt adjustments recommended (do not edit judge prompt — notes only):**
  1. Add a sixth dimension — `scope_appropriateness` — that evaluates whether cogworks-learn correctly identifies requests that should not produce a skill. The dimension should pass when the output explicitly recommends persistent configuration for always-on rules, and fail when a skill is generated for a use case that is better served by CLAUDE.md or equivalent persistent agent configuration.
  2. Consider adding a `not_applicable` score value for this dimension, since most requests (non-persistent-rule requests) would have scope_appropriateness genuinely not applicable — consistent with how the rubric already handles null dimensions for cc_feature_labeling and compatibility_field.
- **Note on schema divergence:** cogworks-learn quality cases use `notes` + `expected_content` + `forbidden_content` rather than `evaluator_notes` + `ground_truth`. For all seven cases, the `expected_content` tokens map cleanly to rubric pass signals and `forbidden_content` maps to fail signals, so calibration is functionally unambiguous. However, the schema inconsistency means any tooling that reads `evaluator_notes` or `ground_truth` to drive calibration automation would silently skip all cogworks-learn quality cases. Recommend standardizing the schema or adding a compatibility adapter.
- **Recommendation:** ready for harness — six of seven cases are fully covered, and the one gap (persistent-001) is a meta-routing case that the current five-dimension rubric was not designed to catch. The gap should be addressed by a rubric revision before the harness includes persistent-001 as a pass/fail criterion.
