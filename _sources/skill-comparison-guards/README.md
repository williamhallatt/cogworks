# Comparing Skill Implementations

## Claude Code Opus 4.6's Answer to "How do you compare two skill implementations for the same source material?"

For comparing two skill implementations from the same source material, here are the assessment criteria in priority order:

  1. Fidelity to Source
  - Does it accurately represent the source's core concepts without distortion?
  - Are key distinctions preserved, or flattened into oversimplifications?
  - Does it omit critical nuance that would lead to wrong outputs?

  2. Density of Judgment Calls
  - Does it encode decisions the source material left implicit?
  - Does it translate concepts into operational rules — "when X, do Y in this context"?
  - A skill that paraphrases is a summary. A skill that adds useful operational judgment is an
  implementation. The gap between these two is the most reliable quality signal.

  3. Resistance to Drift
  - When applied to inputs slightly outside its sweet spot, does it hold the source material's
  specific perspective or collapse into generic advice?
  - The better implementation holds its shape under pressure.

  4. Context Efficiency
  - Does it include only what's needed at invocation time?
  - Is reference material separated from activation logic?
  - Does it avoid loading heavy content that could be deferred?

  5. Composability
  - Does the skill play well with other skills and the agent's existing behavior?
  - Does it fight for control, override sensible defaults, or assume it's the only thing running?

  6. Testability
  - Can you construct a prompt where you'd clearly see the difference between having the skill and
  not?
  - If both skills produce indistinguishable outputs on realistic inputs, the comparison is moot
  regardless of how they read on paper.

  7. Scope Coherence
  - Is the skill focused on one job, or does it try to do too many things?
  - Does it have a clear "done" state?

  Separated concerns (important but independent of implementation quality):
  - Invocation precision — trigger conditions, discoverability, frontmatter. This is metadata
  packaging, not the skill body itself. You can pair an excellent implementation with bad triggers or
  vice versa.

  The tiebreaker is fidelity, not actionability. A skill can be highly actionable and consistently
  produce bad outputs because it misunderstood the source. The more faithful implementation wins even
  if its instructions are slightly less crisp.

  Failure mode to watch for: A skill that degrades into confident wrongness is worse than one that
  produces no output at all.

## Skill Quality Guardrails

A skill generated via cogworks and Claude Code Opus 4.6, based on Claude Opus 4.6.'s answer to "How do you compare two skill implementations for the same source material?" above.

[skill-evaluation-rubric](./skill-evaluation-rubric/)

## OpenAI Codex 5.3 Skill Generation QA Checklist (Pre-Finalization) Based on Assessment Criteria after Reviewing its Generated Skill Implementation against a Sonnet 4.6 Implementation of the Same Source Material

  ### 1) Fidelity to Source

  - [ ] Core concepts from source are preserved without distortion.
  - [ ] Key distinctions are explicit (not collapsed into generic guidance).
  - [ ] Out-of-scope boundaries are stated clearly.
  - [ ] No critical nuance is omitted that could cause wrong outputs.

  ### 2) Invocation Precision

  - [ ] Positive triggers are concrete (terms, contexts, file signals).
  - [ ] Negative triggers are explicit (when not to invoke).
  - [ ] Trigger language avoids vague catch-alls (e.g. “best practices” alone).
  - [ ] Another agent could reliably decide invoke vs skip.

  ### 3) Context Efficiency

  - [ ] SKILL.md contains only activation-time guidance.
  - [ ] Deep doctrine/examples live in reference.md (or supporting files).
  - [ ] No duplicated doctrine across files.
  - [ ] Token budget is minimized without removing safety constraints.

  ### 4) Output Actionability

  - [ ] Instructions are imperative and specific (verbs + expected artifacts).
  - [ ] Workflow has clear ordered steps with completion criteria.
  - [ ] Quality gates are testable (lint/check commands, definition of pass/fail).
  - [ ] Handoff expectations are explicit (what this skill delivers vs defers).

  ### 5) Scope Coherence

  - [ ] Single primary job-to-be-done is clear.
  - [ ] Non-goals are explicit.
  - [ ] “Done state” is unambiguous.
  - [ ] Skill is not silently doing adjacent jobs better split elsewhere.

  ### 6) Failure Modes

  - [ ] Ambiguous/edge prompts have safe fallback behavior.
  - [ ] Partial applicability behavior is defined (what to do when only some fit).
  - [ ] Limits and deferrals are explicit.
  - [ ] Harmful defaults are prevented by guardrail language.

  ### 7) Practical Weight

  - [ ] Default behavior is safe under ambiguous real-world prompts.
  - [ ] Skill improves execution quality vs no skill, measurably.
  - [ ] If compared to existing sibling skill, this version is equal or better on:
      - [ ] Invocation precision
      - [ ] Failure-mode safety
      - [ ] Source fidelity

  ### 8) Metadata & Discovery

  - [ ] name is valid and stable.
  - [ ] description is trigger-rich, concrete, third-person, action-led.
  - [ ] Snapshot date and source citations are present.
  - [ ] Versioning is correct (new = 1.0.0, regen = patch bump).

  ### 9) Deterministic Validation

  - [ ] Required files exist (SKILL.md, reference.md, metadata.json).
  - [ ] Required sections present in each file.
  - [ ] Citation references resolve and are non-trivial.
  - [ ] Markdown fences and frontmatter parse cleanly.

  ### 10) Rewrite Gate (Mandatory)

  - [ ] Remove filler and weak modal language.
  - [ ] Keep all protective constraints (especially non-triggers).
  - [ ] Eliminate doctrinal duplication.
  - [ ] Re-check items 1, 2, and 6 after rewrite (hard gate).

## Quality Gate Suggestions

Generated by OpenAI Codex 5.3 to Implement in cogworks based on its Skill Generation QA Checklist above.

These files formalize a quality-control layer for cogworks skill generation, split by responsibility so each skill can apply gates independently and consistently.

  - cogworks/workflow-gates.md: End-to-end orchestration gates for cogworks itself (dependency checks, step order, approval-before-write, validation/rewrite expectations, completion outputs).
  - cogworks/core-quality-gates.md: Shared baseline constraints (truthfulness, scope discipline, traceability, compression without losing safety constraints).
  - cogworks-encode/synthesis-gates.md: Synthesis-specific gates (fidelity to sources, distinction preservation, contradiction handling, citation rigor, source-scope labeling, edge-case handling).
  - cogworks-encode/core-quality-gates.md: Same shared baseline, duplicated so cogworks-encode can be used independently.
  - cogworks-learn/authoring-gates.md: Authoring/runtime gates (invocation precision, context efficiency, actionability, failure-mode safety, metadata/runtime contract correctness, rewrite requirements).
  - cogworks-learn/core-quality-gates.md: Same shared baseline for independent cogworks-learn invocation.

  Why they exist:

  - To prevent quality drift between agents/runs.
  - To make quality expectations explicit and reviewable.
  - To separate concerns cleanly: orchestration vs synthesis vs authoring.
  - To support independent use of cogworks-encode and cogworks-learn without losing shared safety
    standards.

### Additional Notes

These gates are intended to be loaded by the relevant agents at the right stages of the workflow, for example:

 - cogworks/SKILL.md: “Load workflow-gates.md before Step 1.”
  - cogworks-encode/SKILL.md: “Load synthesis-gates.md before producing synthesis output.”
  - cogworks-learn/SKILL.md: “Load authoring-gates.md before finalizing generated files.”
