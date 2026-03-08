# Calibration Notes — cogworks-learn
**Date:** 2026-03-08
**Judge prompt version:** Six dimensions — parallel_instruction, subagent_delegation, cc_feature_labeling, allowed_tools_accuracy, compatibility_field, scope_appropriateness
**Calibrated against:** cogworks-learn-parallel-001, cogworks-learn-subagent-001, cogworks-learn-subagent-002, cogworks-learn-persistent-001, cogworks-learn-arguments-001, cogworks-learn-compatibility-001, cogworks-learn-allowed-tools-001, cogworks-learn-hook-001, cogworks-learn-subagent-def-001, cogworks-learn-subagent-type-001, cogworks-learn-subagent-dispatch-001

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
- **Rubric dimension(s) that cover this:** `scope_appropriateness` — dimension 6 pass signal "Explicit redirect to the appropriate mechanism with rationale" covers the expected redirect to persistent config. Fail signal "Skill generated for always-on rules without recommending persistent config" catches the omission case.
- **Gap identified:** No. Previously identified gap (no dimension for skill vs. persistent-config routing) is now **CLOSED** by dimension 6.
- **Calibration verdict:** covered

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

### cogworks-learn-hook-001
- **Expected behavior (from notes/expected_content):** A request to block git push without running tests is deterministic enforcement — should recommend a hook, not a skill. Expected content: `["hook", "deterministic"]`.
- **Rubric dimension(s) that cover this:** `scope_appropriateness` — dimension 6 fail signal "Skill generated for deterministic enforcement without recommending hooks" directly covers this case. Pass signal "Explicit redirect to the appropriate mechanism with rationale" matches the expected redirect to hooks.
- **Gap identified:** No.
- **Calibration verdict:** covered

### cogworks-learn-subagent-def-001
- **Expected behavior (from notes/expected_content):** A request for a custom code review agent with restricted tools and model is a subagent definition, not a skill. Expected content: `["subagent", "definition", "tools", "model"]`.
- **Rubric dimension(s) that cover this:** `scope_appropriateness` — dimension 6 fail signal "Skill generated for task orchestration with restricted tools/model without recommending subagent definitions" directly covers this case. Pass signal "Explicit redirect to the appropriate mechanism with rationale" matches the expected redirect.
- **Gap identified:** No.
- **Calibration verdict:** covered

### cogworks-learn-subagent-type-001
- **Expected behavior (from notes/expected_content):** A Claude Code batch log analysis skill should select the Explore subagent type (read-only, Haiku) and label `context: fork` as CC-specific. Expected content: `["Explore", "read-only", "subagent", "context: fork"]`.
- **Rubric dimension(s) that cover this:** `subagent_delegation` — dimension 2 covers both the delegation requirement and the CC-specific `context:fork` pass signal. The enriched SKILL.md subagent type table now provides the knowledge to select Explore for read-only tasks, which the generated skill should reflect. `cc_feature_labeling` covers the `context: fork` annotation requirement.
- **Gap identified:** No.
- **Calibration verdict:** covered

### cogworks-learn-subagent-dispatch-001
- **Expected behavior (from notes/expected_content):** Three independent research tasks should use background dispatch for concurrent subagent execution. Expected content: `["parallel", "subagent", "background", "concurrent"]`.
- **Rubric dimension(s) that cover this:** `subagent_delegation` — dimension 2 pass signal "Subagent receives the high-volume operation; only summary returns to main context" covers delegation. The enriched SKILL.md orchestration patterns section now covers parallel research via background dispatch, which the generated skill should reference.
- **Gap identified:** No.
- **Calibration verdict:** covered

---

## Summary

- **Coverage:** 11/11 cases fully covered (parallel-001, subagent-001, subagent-002, persistent-001, arguments-001, compatibility-001, allowed-tools-001, hook-001, subagent-def-001, subagent-type-001, subagent-dispatch-001)
- **Gaps found:** None. The previously identified scope_appropriateness gap is now **CLOSED** — dimension 6 covers persistent-config routing (persistent-001), hook routing (hook-001), and subagent definition routing (subagent-def-001).
- **Note on schema divergence:** cogworks-learn quality cases use `notes` + `expected_content` + `forbidden_content` rather than `evaluator_notes` + `ground_truth`. For all eleven cases, the `expected_content` tokens map cleanly to rubric pass signals and `forbidden_content` maps to fail signals, so calibration is functionally unambiguous. However, the schema inconsistency means any tooling that reads `evaluator_notes` or `ground_truth` to drive calibration automation would silently skip all cogworks-learn quality cases. Recommend standardizing the schema or adding a compatibility adapter.
- **Recommendation:** ready for harness — all eleven cases are fully covered with no remaining gaps.
