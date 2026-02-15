# Plan: Apply Prompting Principles to Improve Cogworks Toolchain

## Context

The cogworks toolchain produces Claude Code skills from source material through a pipeline: cogworks agent -> cogworks-encode (synthesis) -> cogworks-learn (skill generation) -> cogworks-test (validation). The advanced-prompting skill contains authoritative prompting principles that the toolchain itself does not yet consistently follow. This plan applies those principles to improve both the toolchain definitions and the quality of artefacts they produce.

The audit identified 20 specific findings, each traceable to a named prompting principle. This plan groups them by file for implementation efficiency, ordered by cascading impact (orchestration layer first, then synthesis, then generation, then validation).

---

## File 1: `.claude/agents/cogworks.md` (5 findings — highest cascade impact)

Changes here propagate through the entire pipeline.

**F4 + F12: Add quality modifiers and imperative phrasing to Steps 3 and 5**

Step 3 currently says "Apply the cogworks-encode methodology to create integrated knowledge." Replace with direct imperative + quality modifier:
- "Synthesise all gathered source material into a unified knowledge base following the cogworks-encode 8-phase process. Find non-obvious connections between sources, resolve contradictions with nuanced analysis, and extract patterns that would not be apparent from reading any single source alone. The synthesis must produce all required output sections: TL;DR, Core Concepts, Concept Map, Patterns, Anti-Patterns, Practical Examples, Deep Dives, Quick Reference, and Sources."

Step 5 currently says "Apply cogworks-learn expertise to create the skill files." Replace with:
- "Generate skill files in `.claude/skills/{slug}/` from the synthesis output. Create SKILL.md with frontmatter and overview, reference.md with the full knowledge base, and supporting files (patterns.md, examples.md) only when they contain substantive unique content (3+ distinct entries each)."

Principles: Quality Modifier Escalation, Explicitness, Anti-Pattern 5 (Ambiguous Action Phrasing)

**F5: Add explicit self-verification gate to Step 6**

Step 6 currently says "Apply cogworks-learn validation expertise to review the generated skill files before confirming success. Fix any issues found." Replace with a concrete checklist:
1. Description is keyword-rich, starts with action verb, includes trigger phrases, written in third person
2. SKILL.md is under 500 lines with depth in supporting files
3. Every pattern has when/why/how context and cites its source
4. No content duplicated across supporting files
5. TL;DR captures actual key insights, not topic introduction
6. All technical terms defined within the skill
7. `name` uses only lowercase, numbers, hyphens (max 64 chars)
8. Re-read fixed content after corrections to confirm the fix

Principle: Self-Verification Gate

**F13: Add description optimisation guidance to Step 5**

Add explicit instruction: "Pay particular attention to the SKILL.md description field: it must be keyword-rich, start with an action verb, include trigger phrases users would naturally say, list concrete use cases, and be written in third person. This single field determines whether the skill will be discovered and auto-loaded."

Principle: Explicitness

**F7: Reframe agent description from negative to positive with context**

Current: "Do NOT invoke automatically. Only invoke when the user explicitly types a 'cogworks' command..."
Reframe to: "Encodes topic knowledge into invokable skills from URLs and files. Creates directories and files as side effects, so invoke only when the user explicitly types a 'cogworks' command (e.g. 'cogworks encode', 'cogworks learn'). Generic words like 'learn', 'encode', or 'automate' alone do not indicate user intent to create skill files."

Principles: Positive-Frame Steering, Context-Before-Rule. Also addresses the documented known issue in CLAUDE.md.

---

## File 2: `.claude/skills/cogworks-encode/reference.md` (6 findings)

These changes improve synthesis quality.

**F2: Add context-before-rule to Overriding Principles**

Add a preamble explaining WHY fabrication is dangerous: "Generated skills become part of Claude's operational context -- fabricated claims will be treated as ground truth during all future invocations, with no mechanism for the user to distinguish fabricated from accurate claims." Also clarify that cross-source synthesis (inferring connections) is encouraged; only unsupported invention is prohibited. Explain precision-over-coverage in terms of context budget: "Every line must earn its context budget."

Principle: Context-Before-Rule

**F3: Convert DON'T list to positive framing**

Fold unique content from the 9-item DON'T section into the DO section using positive framing:
- "Integrate ideas across sources" (replaces "Don't concatenate")
- "Verify each section contributes unique information" (replaces "Don't restate across sections")
- "Follow the required output format exactly" (replaces "Don't ignore structure")

Eliminate or reduce the DON'T section to a brief "Common mistakes" cross-reference.

Principle: Positive-Frame Format Steering

**F8 + F15: Add exemplar reference for synthesis quality**

After the output format template, add a reference to the advanced-prompting skill as a concrete quality exemplar with specific attributes to match:
- reference.md: 9 concepts with cross-source synthesis, 15-relationship concept map, 3 deep dives
- patterns.md: 8 patterns each with when/why/how/example, 6 anti-patterns
- examples.md: 8 before/after comparisons with source citations

Also add a Quality Anchor section calling out specific quality attributes (concept depth, relationship density, pattern specificity, deep dive nuance, deduplication).

Principle: Multishot Prompting

**F17: Make TL;DR requirements explicit**

Replace the vague "{3-5 key insights}" placeholder with a definition and test: insights are statements that would change how someone approaches the topic — surprising, actionable, or counter-intuitive. Include a concrete contrast: "'This skill covers advanced prompting techniques' is an introduction. 'Extended thinking has been superseded by adaptive thinking' is an insight."

Principle: Explicitness

**F18: Improve pattern "When to use" template**

Expand the placeholder to model expected specificity: "Describe the specific situation, trigger condition, or decision point. Good: 'When X is true and Y is needed'. Avoid: 'When relevant' or 'In appropriate contexts'."

Principle: Explicitness

**F6: Soften prescriptive phase substeps (low priority)**

Convert numbered substeps from prescribed sequence to outcome-oriented goals. E.g., Phase 1's 4 numbered steps become: "For each source, build a mental model of what it contributes — its main topics, key concepts, tone and authority level, and potential conflicts." Apply only where the substeps prescribe approach rather than define output structure.

Principle: Anti-Pattern 2 (Prescriptive Thinking Steps). Low priority — apply only if synthesis appears formulaic.

---

## File 3: `.claude/skills/cogworks-encode/SKILL.md`

**F2 (continued): Update the "Critical" mission statement**

Current: "This is NOT copy-paste. This is NOT summarization." (triple negation)
Replace with context-first positive framing: "The downstream consumer is an LLM that treats skill content as authoritative instructions. True synthesis creates new understanding that Claude cannot derive on its own — connections between sources, resolved contradictions, and actionable patterns with when/why/how context."

Principle: Context-Before-Rule, Positive-Frame Steering

---

## File 4: `.claude/skills/cogworks-learn/SKILL.md` (1 finding)

**F9: Add quality modifiers to core mission statement**

Add after the expertise declaration: "Your goal is to produce skills that score 4+ on every quality dimension: source fidelity, self-sufficiency, completeness, specificity, and no overlap with Claude's built-in knowledge. Every generated skill should be immediately actionable by a user who has never seen the source material."

Principle: Quality Modifier Escalation, Explicitness

---

## File 5: `.claude/skills/cogworks-learn/reference.md` or `patterns.md` (3 findings)

**F14: Add guidance for embedding verification gates in generated skills**

Add section on when generated skills should include self-verification steps, scaled by fragility:
- High-fragility workflows: explicit STOP conditions
- Medium-fragility workflows: verification checklist
- Low-fragility reference: no verification needed

Principle: Self-Verification Gate

**F16: Add guidance for embedding quality modifiers in generated skills**

Add section mapping topic types to appropriate quality modifiers:
- Analytical tasks: "Analyse thoroughly — identify all relevant..."
- Generative tasks: "Create comprehensive..."
- Diagnostic tasks: "Investigate all possible causes..."

Principle: Quality Modifier Escalation

**F20: Add persuasion level decision framework**

Add a classification gate that maps source material characteristics to persuasion intensity:
- High fragility (side effects, irreversible) -> Authority + Commitment + verification gates
- Medium fragility (best practices) -> moderate Authority + Unity
- Low fragility (reference, conventions) -> clarity only, no persuasion

Principle: Autonomy Calibration, Anti-Overengineering

---

## File 6: `.claude/skills/cogworks-learn/persuasion-principles.md` (2 findings)

**F1: Reconcile aggressive emphasis with advanced-prompting guidance**

Add a reconciliation section acknowledging the model-specific tension: Authority language ("YOU MUST", "No exceptions") is effective for high-fragility discipline enforcement but causes overtriggering in reference/guidance skills on Opus 4.6+. Update examples to include a natural-language alternative for reference and guidance skills. Tie to the existing "Principle Combinations by Skill Type" table.

Principle: Anti-Pattern 1 (Aggressive Emphasis)

**F11: Add context-before-rule to Liking section**

Explain WHY Liking creates sycophancy (approval-seeking vs shared purpose) and how it differs from Unity. Reframe from "DON'T USE for compliance" to positive guidance on when other principles achieve the same goal without the trade-off.

Principle: Context-Before-Rule, Positive-Frame Steering

---

## File 7: `.claude/skills/cogworks-test/reference.md` (2 findings)

**F10: Add self-consistency check to LLM judge**

After dimension scoring, add a step: "Review scores as a set. Check for internal inconsistencies — can this skill score 5 on source fidelity but 2 on self-sufficiency? If scores seem contradictory, re-evaluate the anomalous dimension with the other scores as context. Report adjustments and reasoning."

Principle: Self-Verification Gate

**F19: Add prompt engineering quality evaluation**

Add either as a 6th quality dimension (weight 0.10) or as sub-checks within Specificity. Evaluate:
- Positive framing (DO guidance vs DON'T lists)
- Appropriate emphasis (Authority matched to fragility)
- Verification gates (present for high-fragility workflows)
- Action clarity (imperative phrasing, not suggestions)
- Context-before-rule (non-obvious instructions explain WHY)

Principle: Advanced-prompting (holistic)

---

## Implementation Order

Priority is by cascade impact — changes to the orchestrator affect every run; changes to encode affect every synthesis; changes to learn affect every generated skill.

1. **cogworks.md** — F4, F5, F7, F12, F13
2. **cogworks-encode reference.md + SKILL.md** — F2, F3, F8, F15, F17, F18
3. **cogworks-learn SKILL.md + reference.md/patterns.md** — F9, F14, F16, F20
4. **persuasion-principles.md** — F1, F11
5. **cogworks-test reference.md** — F10, F19
6. **cogworks-encode reference.md** — F6 (low priority, apply only if synthesis appears formulaic)

---

## Verification

After implementation:

1. **Structural check**: Run `cogworks-test` against an existing golden sample skill (e.g. advanced-prompting) to confirm the test framework still passes — no regressions from F10/F19 changes
2. **End-to-end test**: Run the full cogworks pipeline on a new topic to generate a skill, then validate with cogworks-test. Compare the generated skill quality against one generated before these changes
3. **Spot-check key improvements**: Verify the agent description no longer triggers on generic words like "learn" or "encode" (F7). Verify Step 6 validation produces specific checklist output rather than generic "looks good" (F5). Verify synthesis TL;DR contains insights rather than introductions (F17)
