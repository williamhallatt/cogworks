# Skill Evaluation Rubric - Reference

## TL;DR

Seven criteria, priority-ordered, for comparing skill implementations from the same source material. Fidelity is the tiebreaker. Invocation precision is separated as metadata. Confident wrongness is the worst failure mode.

## Decision Rules

1. **Fidelity trumps actionability.** A skill can be highly actionable and consistently produce bad outputs because it misunderstood the source. The more faithful implementation wins even if its instructions are slightly less crisp. [Source 1]
2. **Separate packaging from substance.** Invocation precision (trigger conditions, frontmatter, discoverability) is metadata. You can pair an excellent skill body with bad triggers or vice versa. Evaluate these independently. [Source 1]
3. **If outputs are indistinguishable, the comparison is moot.** Construct a realistic prompt where having the skill would produce visibly different behavior. If both candidates produce the same output, differences on paper do not matter. [Source 1]

## Evaluation Criteria (Priority Order)

### 1. Fidelity to Source (Highest)

- Does it accurately represent the source's core concepts without distortion?
- Are key distinctions preserved, or flattened into oversimplifications?
- Does it omit critical nuance that would lead to wrong outputs?

**Test:** Take three specific claims from the source. Can you trace each to a corresponding instruction in the skill? If a claim is absent or contradicted, fidelity has failed.

### 2. Density of Judgment Calls (High)

- Does it encode decisions the source material left implicit?
- Does it translate concepts into operational rules — "when X, do Y in this context"?
- A skill that paraphrases is a summary. A skill that adds useful operational judgment is an implementation.

**Test:** Count the conditional instructions (if/when/unless patterns). A skill with fewer than the source's ambiguity count is under-specified.

### 3. Resistance to Drift (High)

- When applied to inputs slightly outside its sweet spot, does it hold the source material's specific perspective?
- Or does it collapse into generic advice the agent already knows?

**Test:** Give the skill an input at the boundary of its domain. Does the output still reflect the source's distinctive viewpoint, or could any general-purpose agent have produced it?

### 4. Context Efficiency (Medium)

- Does it include only what's needed at invocation time?
- Is reference material separated from activation logic?
- Does it avoid loading heavy content that could be deferred?

**Test:** Read the SKILL.md. Could you remove any section without changing the skill's behavior on typical inputs? If yes, it's overloaded.

### 5. Composability (Medium)

- Does the skill play well with other skills and the agent's existing behavior?
- Does it fight for control, override sensible defaults, or assume it's the only thing running?

**Test:** Imagine the skill loaded alongside two others in the same domain. Would it conflict, duplicate, or complement?

### 6. Testability (Medium)

- Can you construct a prompt where you'd clearly see the difference between having the skill and not?
- If both skills produce indistinguishable outputs on realistic inputs, the comparison is moot regardless of how they read on paper.

**Test:** Write one prompt. Run it with each skill. If outputs are materially different, the skill is testable.

### 7. Scope Coherence (Standard)

- Is the skill focused on one job, or does it try to do too many things?
- Does it have a clear "done" state?

**Test:** Can you describe what the skill does in one sentence without using "and"? If not, it may need decomposition.

## Quality Gates

When using this rubric, apply these gates in order:

1. **Fidelity gate** — Does the skill pass the three-claim trace test? If not, stop. No other criteria matter for a skill that misrepresents its source.
2. **Judgment gate** — Does it contain operational judgment beyond paraphrase? A summary masquerading as a skill fails here.
3. **Drift gate** — Does it hold shape on boundary inputs? Generic collapse indicates the source material wasn't deeply encoded.
4. **Efficiency gate** — Is every section load-bearing? Bloat taxes the context window for all other skills.

## Anti-Patterns

### Confident Wrongness

A skill that degrades into confident wrongness is worse than one that produces no output at all. If a skill misunderstands the source and applies that misunderstanding assertively, it actively damages the agent's output quality. Silence is preferable to misguidance. [Source 1]

### Paraphrase Masquerading as Implementation

A skill that restates the source material in imperative voice without adding operational judgment provides no value beyond what the agent could derive from reading the source directly. The gap between paraphrase and implementation is the most reliable quality signal. [Source 1]

## Quick Reference

| Aspect | Better Skill | Worse Skill |
|---|---|---|
| Source claims | Traceable to instructions | Missing or contradicted |
| Ambiguous areas | Resolved with judgment calls | Left as vague guidance |
| Edge cases | Holds source perspective | Collapses to generic advice |
| Context load | Minimal, deferred depth | Everything in SKILL.md |
| Multi-skill env | Complements others | Conflicts or duplicates |
| Distinguishing test | Produces unique output | Indistinguishable from baseline |
| Scope | One sentence, no "and" | Tries to cover too much |

## Source Scope

- **Primary**: Expert assessment derived from evaluating agent skill systems [Source 1] (normative)

## Sources

> Sources current as of 2026-02-24. Re-evaluate if skill ecosystem conventions have changed significantly.

- **[Source 1]** Conversation-derived expert assessment — Opus 4.6 analysis of skill evaluation criteria, incorporating critique and consolidation of Sonnet 4.6's initial framework (2026-02-24)
