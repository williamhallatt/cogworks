For comparing multiple skill implementations from the same source material, here are the assessment criteria in priority order:

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

  8. Maintainability
  - Are source-derived facts that might change (thresholds, named entities, examples) isolated from
  structural instructions, or woven throughout?
  - Does the skill's structure make it clear which parts reflect the source and which are authoring-
  time judgment calls?
  - Could a reviewer identify what to update without re-reading the full source?

  9. Cross-model Portability
  - Does the skill use model-specific phrasing or rely on a specific runtime's behavioral
  assumptions?
  - Are instructions written in runtime-neutral imperative language?
  - Would the skill's description trigger correctly on a different runtime's implicit invocation
  logic?

  10. Security
  - Does the skill body contain instructions that could be leveraged for prompt injection if a user
  crafts a prompt to invoke the skill unexpectedly?
  - Do any scripts pass user inputs to shell commands or external APIs without sanitization?
  - Does the skill assume all inputs are trusted?

  Separated concerns (important but independent of implementation quality):
  - Invocation precision — trigger conditions, discoverability, frontmatter. This is metadata
  packaging, not the skill body itself. You can pair an excellent implementation with bad triggers or
  vice versa.

  The tiebreaker is fidelity, not actionability. A skill can be highly actionable and consistently
  produce bad outputs because it misunderstood the source. The more faithful implementation wins even
  if its instructions are slightly less crisp.

  Failure mode to watch for: A skill that degrades into confident wrongness is worse than one that
  produces no output at all.

  Scoring: Rate each criterion 1 (weak), 2 (adequate), or 3 (strong) using the anchors below.
  A skill is acceptable when all criteria score ≥ 2. Fidelity to Source must score 3 — it is a
  hard gate, not just a tiebreaker.

  Criterion anchors:

  1. Fidelity to Source
     1 — Key distinctions flattened; agent draws wrong conclusions in common cases
     2 — Core concepts present but specific perspective diluted into generic framing
     3 — All critical nuances preserved; specific where the source was specific

  2. Density of Judgment Calls
     1 — Restates source language; no "when X, do Y" translations
     2 — Some operational translations but majority is paraphrase
     3 — Most source concepts translated into conditional agent actions

  3. Resistance to Drift
     1 — Collapses to generic advice on any non-canonical input
     2 — Holds shape on close variants; drifts on adjacent-domain inputs
     3 — Maintains source-specific perspective across varied in-scope inputs

  4. Context Efficiency
     1 — Reference material front-loaded at activation; no deferred loading
     2 — Mostly lean but some avoidable content remains in the body
     3 — Body is activation-logic only; all reference material deferred

  5. Composability
     1 — Absolute imperatives that override agent defaults regardless of context
     2 — Mostly scoped but contains some global-override patterns
     3 — All instructions scoped to within-skill context; no assumption of sole control

  6. Testability
     1 — Cannot construct a realistic prompt that shows skill vs. no-skill difference
     2 — One differentiating prompt exists but is contrived or narrow
     3 — Multiple realistic prompts produce clearly different and correct outputs with skill active

  7. Scope Coherence
     1 — Addresses multiple unrelated jobs; no clear completion state
     2 — Primarily one job but with scope creep
     3 — Single clear job with an obvious done state

  8. Maintainability
     1 — Source-specific details woven throughout; full rewrite required on source change
     2 — Mostly principle-based but some brittle specifics mixed in
     3 — Structural instructions are principle-derived; source-specific details are isolated or absent

  9. Cross-model Portability
     1 — Contains model-specific references or relies on model-specific behavioral assumptions
     2 — Mostly generic but has phrasing that may misfire on a different runtime
     3 — Instructions are runtime-neutral; no model-specific dependencies

  10. Security
      1 — Contains patterns that would allow prompt injection or unsanitized script execution
      2 — No obvious injection paths but the skill makes implicit trust assumptions
      3 — Instructions are scoped; scripts (if any) sanitize inputs; no implicit trust assumptions
