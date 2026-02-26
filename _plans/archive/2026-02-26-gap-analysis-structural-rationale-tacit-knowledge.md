# Gap Analysis: Structural Rationale Probe and Tacit Knowledge Accounting

**Date:** 2026-02-26
**Scope:** cogworks/SKILL.md, cogworks-encode/SKILL.md (reference.md), cogworks-learn/SKILL.md

---

## Summary

Gap analysis against prior implementation identified two outstanding items after Gaps 2 and 3 were closed:

1. **Structural rationale probe in synthesis phase** — cogworks-encode Phase 4 ("Pattern Extraction") lacked an explicit directive to probe mechanism-level rationale for each pattern. The "why it works" field tended to surface benefit-level rationale; the question "what assumption does this pattern make that, if false, makes it wrong?" was not asked explicitly.

2. **Tacit knowledge / epistemic accounting** — No phase produced an explicit list of aspects likely to involve tacit expert judgment not captured in sources, leaving skill consumers without calibration signals for where to trust vs. verify.

---

## Decisions

### Gap 1: Structural rationale probe

Added a **Mechanism probe** as step 5 in Phase 4 of `cogworks-encode/reference.md`, after "Why it works". The step directs the synthesizer to ask explicitly: "What assumption does this pattern make that, if false, would make it wrong or inapplicable?" and records the answer as primary content for the Boundary conditions field. An unanswered mechanism probe is a boundary conditions defect.

This complements the existing Boundary conditions field in the pattern template, which already asked "What assumption does it make?" — the new step ensures this question is actively asked during synthesis rather than left implicit.

### Gap 4: Tacit knowledge epistemic accounting

Three coordinated changes:

1. **Phase 8 directive** in `cogworks-encode/reference.md` — explicit "Tacit knowledge accounting" step before narrative finalization, prompting the synthesizer to enumerate 3-5 aspects where sources have a tacit knowledge ceiling. Framed as a fidelity defect if absent for judgment-heavy domains.

2. **Conditional section specification** in `cogworks-encode/reference.md` — "Tacit Knowledge Boundary" entry strengthened from a brief label to a structured content requirement: 3-5 items in format `[Domain/decision area]: [judgment type] — documents likely do not capture [ceiling]. Verify by [calibration method]`. Skip criteria explicitly restricted to purely formal/definitional domains.

3. **Stage artifact** in `cogworks/SKILL.md` — `{tacit_knowledge_boundary}` added to stage handoff artifacts, variable naming convention, and Success Criteria list, making it a required output alongside `{decision_skeleton}`.

---

## Files Changed

- `skills/cogworks-encode/reference.md` — Phase 4 mechanism probe step; Phase 8 tacit knowledge accounting directive; Conditional sections Tacit Knowledge Boundary specification
- `skills/cogworks/SKILL.md` — `{tacit_knowledge_boundary}` in stage artifacts, variable convention, and success criteria
