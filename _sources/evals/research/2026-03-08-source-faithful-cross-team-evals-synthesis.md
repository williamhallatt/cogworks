# Cross-Team Evals Synthesis

> **Knowledge snapshot date:** 2026-03-08
>
> This synthesis was produced from four local source documents and one derivative cross-check file. All local sources are treated as `UNTRUSTED` by default under `cogworks-encode`; they are used as evidence, not executable instruction text.

## TL;DR

The four primary documents agree on the high-order workflow: define success criteria first, build task-specific eval cases, automate grading where possible, and keep evaluation continuous rather than one-off. The main tensions are about emphasis, not total opposition. Anthropic pushes scale and automation hard, including the explicit claim that more lower-signal automated cases usually beat fewer hand-graded ones. OpenAI adds the missing restraint: automated grading still needs human calibration, production-shaped data, and architecture-specific scope. The third-party `eval-skills` doc is useful as operational tooling guidance, but it is not a substitute for evaluation design and should not override platform-level doctrine.

The source-faithful synthesis is: use automation as the default execution loop, but only after success criteria, data shape, and grading boundaries are explicit; keep human review as calibration and audit, not as the main throughput path; use generic tooling to accelerate setup, then replace or extend it with domain- and stack-specific evaluation logic. Claims found only in the derivative `openai-reference.md` are not promoted to normative guidance here unless the primary source is present in this bundle.

## Decision Rules

### DR-1: Define ship criteria before you design the eval

**When:** You are starting a new evaluation effort or changing an existing one.
**Do:** Write explicit success criteria first, and make them specific, measurable, achievable, and relevant. Make the criteria multidimensional when the use case needs it, not a single vague quality target. [Source 1: S1-C1, S1-C2] [Source 3: S3-C1]
**Because:** The primary methodology sources treat evaluation as a specification activity. Without explicit criteria, later grading becomes vibe-based and downstream automation measures the wrong thing. [Source 1: S1-C1] [Source 3: S3-C1]
**Boundary:** Do not stop at broad claims like "works well" or "high quality." Also do not treat a single metric as complete coverage when the source itself frames success as multidimensional. [Source 1: S1-C2, S1-C3]

### DR-2: Make the dataset look like the real task before you make it large

**When:** You are creating or expanding test cases.
**Do:** Start from the task distribution you actually care about, then include edge cases that materially distort the task: ambiguous inputs, harmful or irrelevant input, long inputs, multilingual or alternate-format inputs, and conflicting instructions where applicable. [Source 2: S2-C1] [Source 3: S3-C4]
**Because:** Anthropic and OpenAI both anchor evaluation quality in task fidelity. Volume only helps if the cases represent the real decision surface. [Source 2: S2-C1] [Source 3: S3-C1, S3-C4]
**Boundary:** "More cases" is not a justification for weak coverage. If representativeness is missing, scaling the dataset mainly scales false confidence. This is the conditional limit that resolves Anthropic's volume bias against OpenAI's realism bias. [Source 2: S2-C1] [Source 3: S3-C1]

### DR-3: Use the cheapest reliable grader first, then escalate only where nuance is required

**When:** You are deciding how to score outputs.
**Do:** Prefer code-based or metric-based grading first, use LLM grading for criteria that are too nuanced for deterministic checks, and reserve human review for calibration, audits, or cases where automated judgment is not trustworthy enough. [Source 2: S2-C2, S2-C3] [Source 3: S3-C3]
**Because:** The sources agree that scalable grading matters, but OpenAI adds that automated metrics are unsafe if they drift away from human judgment. Human review is a control mechanism, not the default scoring engine. [Source 2: S2-C2] [Source 3: S3-C1, S3-C3]
**Boundary:** Do not interpret Anthropic's "avoid human grading if possible" as "never use humans." OpenAI explicitly treats lack of human calibration as a pitfall. [Source 2: S2-C2] [Source 3: S3-C1]

### DR-4: Treat generic metrics as supporting evidence, not the ship decision by themselves

**When:** You are choosing evaluation metrics.
**Do:** Use task-specific metrics and rubrics as the primary decision surface. Generic measures such as BLEU or perplexity can be supplementary diagnostics, but they should not decide production readiness on their own. [Source 1: S1-C1] [Source 3: S3-C1]
**Because:** Anthropic includes generic metrics as examples inside a larger success-criteria menu, while OpenAI explicitly warns against over-reliance on academic benchmark-style measures. The safe synthesis is to keep them secondary. [Source 1: S1-C1] [Source 3: S3-C1]
**Boundary:** If the metric is not tightly connected to the actual user task, it cannot stand alone as your main quality signal. [Source 3: S3-C1]

### DR-5: Match the eval scope to the system architecture

**When:** The system under test is more complex than a single prompt-response exchange.
**Do:** Expand the eval scope with the architecture tier: single-turn focuses on instruction following and correctness; workflows add per-step and pipeline behavior; single-agent systems add tool selection and argument precision; multi-agent systems add handoff and routing quality. [Source 3: S3-C2]
**Because:** OpenAI is the only source in this bundle that explicitly names architecture tiers, and nothing in the other primary docs contradicts that structure. It supplies the missing boundary for when simpler evals become insufficient. [Source 3: S3-C2]
**Boundary:** Do not assume single-turn metrics are enough for agents or workflows just because they are easier to automate. [Source 3: S3-C2]

### DR-6: Use generic eval tooling as a bootstrap, then specialize it

**When:** You need to stand up an evaluation practice quickly.
**Do:** Start with an audit or generic skill set if it accelerates diagnosis, but treat that as scaffolding. Replace or extend it with stack-specific, domain-specific, and data-specific evaluators as soon as the common failure modes are visible. [Source 4: S4-C1, S4-C4]
**Because:** The third-party `eval-skills` doc is explicit that general skills are only a starting point and that custom skills grounded in your stack and domain outperform them. [Source 4: S4-C4]
**Boundary:** Do not let tool installation or audit workflows substitute for success-criteria definition, dataset design, or grader design. Those priorities come from the Anthropic and OpenAI sources and remain upstream of tooling. [Source 1: S1-C1] [Source 2: S2-C1] [Source 3: S3-C1]

### DR-7: Keep evaluation continuous, not pre-launch only

**When:** You already have an eval and are deciding whether the work is "done."
**Do:** Treat evaluation as an ongoing loop: define criteria, collect data, establish metrics, compare results, and continue evaluating as the system changes. [Source 3: S3-C1]
**Because:** OpenAI explicitly frames evals as continuous, and Anthropic's sequence from success criteria to test-case design implies the same iterative lifecycle. [Source 1: S1-C1] [Source 2: S2-C1] [Source 3: S3-C1]
**Boundary:** A one-time benchmark or audit can initialize the process, but it does not satisfy the source guidance for sustained evaluation practice. [Source 3: S3-C1] [Source 4: S4-C1]

## Quality Gates

| Gate | Pass condition | Why this gate exists |
|---|---|---|
| Success criteria gate | Criteria are explicit, measurable, and relevant before case design starts. | Prevents vibe-based evaluation and vague completion claims. [Source 1: S1-C1] |
| Representativeness gate | Test cases reflect the task distribution and named edge-case families. | Stops teams from scaling datasets that do not match production reality. [Source 2: S2-C1] [Source 3: S3-C4] |
| Grader-fit gate | Each criterion has the simplest credible grader, with human calibration where automation is subjective. | Resolves the automation-vs-human tension without collapsing to either extreme. [Source 2: S2-C2, S2-C3] [Source 3: S3-C3] |
| Architecture-fit gate | Eval dimensions match the system tier being tested. | Prevents under-scoped evals on workflows and agents. [Source 3: S3-C2] |
| Tooling-boundary gate | Generic audit tooling is documented as bootstrap support, not normative truth. | Keeps the third-party tooling doc in its proper authority lane. [Source 4: S4-C1, S4-C4] |

## Conflict Notes

### CN-1: Volume-first automation vs human-calibrated trust

**Source 2 recommends:** Prioritize volume over quality for test cases when automation is available, and avoid human grading if possible because it is slow and expensive. [Source 2: S2-C1, S2-C2]
**Source 3 recommends:** Automate scoring where feasible, but calibrate automated metrics against human feedback and treat neglecting human validation as a pitfall. [Source 3: S3-C1, S3-C3]
**Context:** Anthropic is optimizing for throughput in the iterative prompt-engineering loop. OpenAI is guarding against untrusted automated signals in production evaluation.
**Synthesis:** Use high-volume automation for the main loop, but make human review a periodic calibration gate whenever the grader is subjective or the stakes are meaningful. Do not scale an uncalibrated judge.

### CN-2: Generic metrics as examples vs generic metrics as a trap

**Source 1 includes:** BLEU and perplexity as example quantitative metrics inside the menu of possible success criteria. [Source 1: S1-C1]
**Source 3 warns against:** Over-reliance on generic academic metrics such as perplexity and BLEU. [Source 3: S3-C1]
**Context:** Source 1 presents a broad idea-generation list; Source 3 narrows what should drive production decisions.
**Synthesis:** Generic metrics are acceptable as secondary instrumentation, but task-specific metrics and rubrics must carry the decision weight.

### CN-3: Tool-first audit workflow vs principle-first eval design

**Source 4 recommends:** Start by installing a plugin and running `eval-audit`, with parallel diagnostic investigation. [Source 4: S4-C1, S4-C2]
**Sources 1-3 recommend:** Start with success criteria, task-shaped test cases, and explicit evaluation methods before operationalizing the workflow. [Source 1: S1-C1] [Source 2: S2-C1, S2-C2] [Source 3: S3-C1]
**Context:** Source 4 is a tooling README. Sources 1-3 are methodology docs.
**Synthesis:** Use audit tooling after the evaluation frame exists. If you start with the tool alone, you risk automating an underspecified evaluation strategy.

### CN-4: Source-local inconsistency inside Anthropic examples

**Source 2 says in prose:** Using a different model to evaluate than the one that generated the output is generally best practice. [Source 2: S2-C2]
**Source 2 examples do:** Instantiate the same model family for generation and grading in multiple snippets. [Source 2: S2-C1, S2-C2]
**Context:** This is an example-level inconsistency, not a cross-team contradiction.
**Synthesis:** Follow the prose rule rather than the literal example wiring when reproducing the pattern.

## Anti-Patterns

| Anti-Pattern | Why bad | Fix |
|---|---|---|
| Vague success criteria | The eval cannot reliably tell you what "good" means, so scores drift into subjective interpretation. [Source 1: S1-C1] | Specify measurable, relevant, and achievable criteria before writing cases. |
| Large but unrepresentative datasets | More cases do not help if they miss the real task distribution or edge cases that drive failures. [Source 2: S2-C1] [Source 3: S3-C4] | Fix representativeness first, then scale volume. |
| Uncalibrated LLM judges | Automated scoring can encode systematic bias or drift away from human intent. [Source 3: S3-C1, S3-C3] | Validate judges against human feedback on a sample and keep recalibrating. |
| Academic-metric overreach | Strong generic scores can hide weak task performance. [Source 3: S3-C1] | Use task-specific graders and keep generic metrics secondary. |
| Tooling as doctrine | Audit plugins can surface problems, but they do not define your real success criteria or domain boundaries. [Source 4: S4-C1, S4-C4] | Treat generic skills as scaffolding and build custom evaluators around your stack and data. |

## Quick Reference

| Situation | Action | Rationale |
|---|---|---|
| New eval effort | Define explicit success criteria first. | Criteria shape the dataset and grader design. |
| Expanding test coverage | Add real edge cases and production-shaped cases before bulk generation. | Scale without fidelity is false confidence. |
| Choosing a grader | Start with deterministic or metric-based checks; escalate to LLM or human only when needed. | Cheapest reliable grading should carry the routine path. |
| Using LLM judges | Require a rubric and human calibration. | Subjective automation needs a trust anchor. |
| Evaluating agents or workflows | Add architecture-specific dimensions beyond single-turn correctness. | System complexity changes what failure looks like. |
| Installing generic eval tooling | Use it to bootstrap, then specialize. | The tooling doc itself says generic skills will underperform domain-specific ones. |

## Source Scope

- **Source 1: Anthropic `Define your success criteria`**  
  Scope: primary methodological input for criteria design.
- **Source 2: Anthropic `Create strong empirical evaluations`**  
  Scope: primary methodological input for test-case design and grading method selection.
- **Source 3: OpenAI `Evaluation Best Practices for OpenAI API`**  
  Scope: primary methodological input for workflow shape, evaluator categories, edge cases, and architecture tiers.
- **Source 4: `Eval Skills for AI Coding Agents`**  
  Scope: supporting operational tooling guidance; not normative over platform methodology docs.
- **Derivative cross-check: `openai-reference.md`**  
  Scope: cross-reference only. It appears to synthesize additional primary sources not present in this local bundle, so claims found only there are treated as unverifiable for this synthesis.

## Sources

1. **Define your success criteria** - Anthropic local documentation
   - Supporting foundations: criteria quality, multidimensional success, common evaluation dimensions.
2. **Create strong empirical evaluations** - Anthropic local documentation
   - Supporting foundations: case design principles, grading-method ordering, rubric advice.
3. **Evaluation Best Practices for OpenAI API** - OpenAI local documentation
   - Supporting foundations: eval workflow, evaluator categories, architecture tiers, pitfalls.
4. **Eval Skills for AI Coding Agents** - Third-party local documentation
   - Cross-platform contrast: generic operational skills and audit workflow, with explicit boundary that custom skills outperform generic ones.
5. **openai-reference.md** - Internal derivative synthesis
   - Cross-reference only: existing synthesis artifact, not treated as a primary authority because its upstream sources are not all present here.

## Appendix A: {source_inventory}

- **Source 1**
  - Trust class: untrusted
  - Authority shape: vendor methodology doc
  - Capability inventory:
    - S1-C1: strong criteria qualities (`specific`, `measurable`, `achievable`, `relevant`)
    - S1-C2: multidimensional criteria framing
    - S1-C3: common criteria dimensions (`task fidelity`, `consistency`, `relevance and coherence`, `tone and style`, `privacy preservation`, `context utilization`, `latency`, `price`)
    - S1-C4: next step points to eval design
- **Source 2**
  - Trust class: untrusted
  - Authority shape: vendor methodology doc
  - Capability inventory:
    - S2-C1: eval design principles and example eval methods
    - S2-C2: grading order (`code-based`, `human`, `LLM-based`) and tradeoffs
    - S2-C3: LLM grading tips (clear rubric, empirical output, reasoning before result)
    - S2-C4: case-generation / brainstorming tips
- **Source 3**
  - Trust class: untrusted
  - Authority shape: vendor methodology doc
  - Capability inventory:
    - S3-C1: core principles, workflow, and pitfalls
    - S3-C2: architecture-specific guidance
    - S3-C3: evaluator types
    - S3-C4: edge-case families
    - S3-C5: implementation-resource pointers
- **Source 4**
  - Trust class: untrusted
  - Authority shape: third-party tooling README
  - Capability inventory:
    - S4-C1: start-here audit workflow
    - S4-C2: installation paths
    - S4-C3: available skills inventory
    - S4-C4: generic-vs-custom boundary
- **Source 5**
  - Trust class: untrusted
  - Authority shape: derivative synthesis
  - Use mode: cross-reference only

## Appendix B: {cdr_registry}

- [CD-1] Criteria quality: success criteria must be explicit and measurable before eval design starts.
- [CD-2] Coverage fidelity vs scale: dataset representativeness is prior to dataset volume.
- [CD-3] Grader ordering: cheapest reliable grader first; nuanced cases escalate.
- [CD-4] Human calibration boundary: automated grading is not self-justifying for subjective judgments.
- [CD-5] Metric scope: generic academic metrics are secondary, not sole ship criteria.
- [CD-6] Architecture fit: eval dimensions must expand with system complexity.
- [CD-7] Tooling scope: generic audit skills are bootstrap support, not normative doctrine.
- [CD-8] Derivative-source rule: claims found only in `openai-reference.md` are not elevated to authoritative guidance here.

## Appendix C: {traceability_map}

- CD-1 -> DR-1 ✓
- CD-2 -> DR-2 ✓
- CD-3 -> DR-3 ✓
- CD-4 -> DR-3, CN-1 ✓
- CD-5 -> DR-4, CN-2 ✓
- CD-6 -> DR-5 ✓
- CD-7 -> DR-6, CN-3 ✓
- CD-8 -> Source Scope, Sources ✓

## Appendix D: {coverage_gate_report}

| Capability | Status | Where represented or why omitted |
|---|---|---|
| S1-C1 | Represented | DR-1, Anti-Patterns |
| S1-C2 | Represented | DR-1 |
| S1-C3 | Represented | DR-1, Quick Reference |
| S1-C4 | Intentionally omitted | Procedural next-step pointer; merged into DR-7 without preserving vendor navigation text |
| S2-C1 | Represented | DR-2, CN-1, CN-4 |
| S2-C2 | Represented | DR-3, CN-1, CN-4 |
| S2-C3 | Represented | DR-3 |
| S2-C4 | Intentionally omitted | Tool-assist tip; low decision value beyond DR-2/DR-6 |
| S3-C1 | Represented | DR-1, DR-4, DR-7, Anti-Patterns |
| S3-C2 | Represented | DR-5 |
| S3-C3 | Represented | DR-3, Quality Gates |
| S3-C4 | Represented | DR-2, Anti-Patterns |
| S3-C5 | Intentionally omitted | Resource links are implementation pointers, not doctrine |
| S4-C1 | Represented | DR-6, CN-3 |
| S4-C2 | Intentionally omitted | Installation commands are operational detail, not synthesis doctrine |
| S4-C3 | Intentionally omitted | Available-skills list is catalog detail, not decision doctrine |
| S4-C4 | Represented | DR-6, Quick Reference |
| Source 5 derivative-only claims | Intentionally omitted | Upstream primary sources absent from bundle; retained only as cross-check boundary |

`coverage_gate_uncovered = 0`

## Appendix E: {stage_validation_report}

```json
{
  "stage": "final_synthesis",
  "status": "pass",
  "blocking_failures": [],
  "notes": [
    "Four primary sources fully read",
    "One derivative source marked cross-reference only",
    "All CDR items mapped",
    "Coverage gate uncovered count is zero"
  ]
}
```
