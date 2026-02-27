# Cogworks System Deep-Dive

*Written: 2026-02-26*

---

## 1. System Overview

Cogworks is a prompt-engineering pipeline encoded as three cooperating agent skills. Its purpose is to transform raw source material — URLs, local files, directories — into a deployed agent skill: a structured SKILL.md package that any compatible agent (Claude Code, OpenAI Codex, GitHub Copilot, Cursor) can auto-discover and invoke.

The pipeline runs inside an LLM-powered agent, which means every stage is carried out by inference rather than compiled code. This is a fundamental design constraint: the workflow is a set of instructions that the agent *follows*, not a program that *executes*. Every guard and mechanism in cogworks exists, at some level, to compensate for the inherent unreliability of this execution model.

The three skills divide responsibility cleanly:

| Skill | Role | Responsible for |
|-------|------|-----------------|
| **cogworks** | Orchestrator | End-to-end workflow, user interaction, handoff sequencing, validation |
| **cogworks-encode** | Synthesis expert | 8-phase process for transforming multiple sources into a unified knowledge base |
| **cogworks-learn** | Skill-writing expert | Staged generation contract, frontmatter configuration, quality gates, generated skill structure |

cogworks owns the pipeline. cogworks-encode and cogworks-learn are specialists it delegates to. The two supporting skills are also independently invocable, which means you can use just the synthesis methodology (without skill generation) or just the skill-writing expertise (for hand-authored skills).

The dependency is structural, not just conventional: cogworks explicitly checks that both supporting skills are present before executing any workflow step, and stops with a concrete installation command if either is missing.

---

## 2. Cogworks Orchestration

The cogworks workflow is a seven-step linear state machine, with an interpolated step between synthesis and skill generation. The steps are:

### Step 1: Gather Sources

The orchestrator collects content from wherever the user points it: URLs (fetched), local files (read), directories (recursively enumerated then read), or files containing lists of URLs (extracted and fetched). If any source fails to load, the user is asked whether to continue with available content rather than failing silently.

Two things happen here that have nothing to do with content:

**Destination parsing.** The user's invocation may contain an explicit output path ("to ./my-skills/"). If so, it is captured as `{skill_path}` and the default staging directory (`_generated-skills/{slug}/`) is bypassed. This matters for Step 2's overwrite check and for Step 7's install command.

**Security preprocessing.** Every source is classified as trusted or untrusted before any synthesis pass begins. This is covered in the Guards section (§5.1) but must happen at source ingestion, not later.

### Step 2: Generate Slug

A URL-safe slug is derived from the topic name: lowercase, non-alphanumeric characters removed, spaces collapsed to single hyphens. This becomes the directory name and the skill's `name` field.

If the destination wasn't specified by the user, `{skill_path}` is set to `_generated-skills/{slug}/` here and announced to the user. If the directory already exists, the user is asked to confirm overwriting before any files are written — and if overwriting, the existing `metadata.json` is read to determine the version bump.

### Step 3: Synthesize Content

The orchestrator delegates to cogworks-encode to run the 8-phase synthesis process on the gathered sources. This step also captures `{snapshot_date}` (the ISO 8601 date, used in generated file headers) and `{source_manifest}` (a structured list of every source, enabling re-synthesis later without recalling URLs manually).

Alongside the synthesis, the orchestrator produces five stage handoff artifacts that flow into every subsequent step: `{source_inventory}`, `{cdr_registry}`, `{traceability_map}`, `{decision_skeleton}`, `{tacit_knowledge_boundary}`, and `{stage_validation_report}`. These are not output for the user — they are internal scaffolding that ensures fidelity through the pipeline.

### Step 3.5: Extract Decision Skeleton

This interpolated step is the transformation bridge between synthesis and skill. Synthesis is organized around *knowledge structure* — what is known about the domain, how concepts relate, what patterns exist. But a skill must be organized around *decision structure* — what choices does a consumer need to make correctly when invoking this skill?

For the 5–7 most important decisions the synthesis reveals, the orchestrator extracts a structured entry:

- **Trigger**: when does this decision arise?
- **Options**: what are the plausible choices?
- **Right call**: what does the synthesis say to do, in what context?
- **Failure mode**: what goes wrong if the wrong choice is made?
- **Boundary / implied nuance**: what does this rule assume that, if false, would change the guidance? What failure does following this rule prevent — and what goes wrong in a system that ignores it? What would an experienced practitioner know that the sources don't state?

The Decision Skeleton becomes the organizing backbone of the skill in Step 5. Skill structure follows it, not the synthesis structure. This prevents the most common failure mode of generated skills: a skill that is informationally complete but mirrors the synthesis's knowledge organization instead of the user's decision needs.

### Step 4: User Review

The orchestrator presents the synthesis summary (topic, source count, destination, TL;DR, counts) and the detected metadata defaults (license inferred from repo root, author from `git config user.name`, version from existing `metadata.json` or defaulting to `1.0.0`). The user can override any of these. Execution continues only on explicit approval. If the user declines, the workflow stops — no files are written.

This is the only user gate in the pipeline. Everything before it is read-only; everything after it writes files.

### Step 5: Generate Skill Files

The orchestrator passes the synthesis, the Decision Skeleton, all metadata, and `{skill_path}` to cogworks-learn to generate the skill files. The key constraint is that the Decision Skeleton is passed *as the organizing backbone* — cogworks-learn does not re-derive structure from the synthesis directly. The structure was settled in Step 3.5.

cogworks-learn runs its own staged generation contract (§3 below) and applies its five integrated prompt quality gates before returning the generated files.

### Step 6: Validate Generated Output

Validation runs three nested layers:

1. **Synthesis deterministic checks** (blocking): runs `validate-synthesis.sh` on `reference.md`; falls back to section-presence and citation checks if the script is unavailable.
2. **Skill deterministic checks** (blocking): runs `validate-skill.sh` on `{skill_path}`; falls back to frontmatter validity and required section checks.
3. **Generalization probe** (blocking for judgment-heavy domains): generates 3–5 novel scenarios not in the source material, applies the skill to each, and evaluates whether responses reflect the Decision Skeleton's principles or are just example-recall. If responses are brittle, the relevant Decision Rules are revised before proceeding.

Alongside the scripts, four quantitative thresholds are enforced: all CDR items mapped (100%), zero uncovered capabilities, 90%+ of Decision Rules with a boundary condition, 95%+ citation coverage.

### Step 7: Confirm and Prompt Installation

The orchestrator displays validation results (Layer 1 pass/fail, CDR traceability, Coverage Gate status, metadata.json confirmation) and then prompts the user to run the install command in their terminal. The `npx skills add` command is **not** run automatically — the `skills` CLI has an interactive TUI for agent selection and install options that requires user input.

---

## 3. Knowledge Synthesis

cogworks-encode implements an 8-phase process for transforming multiple sources into a unified, decision-first knowledge base. The ordering is not arbitrary: each phase depends on outputs from the previous one.

### Phase 1: Content Analysis

Every source is read in full before any analysis begins. The large-file protocol requires `view_range` chunking for files too large to read in one pass; Phase 2 cannot start until every source has been completely read. This prevents partial-read errors where later sections of a source contradict conclusions drawn from only the beginning.

Three sub-tasks happen during Phase 1:

- **Derivative source detection (E2):** Sources generated by a previous cogworks run (containing "Synthesis Metadata" or described as summaries) are marked as cross-reference only. A "merged" claim from a derivative source that cannot be verified against the primary source is a synthesis defect, not a valid compression.
- **Capability inventory (E3):** A named inventory of every source's sections, capabilities, and explicitly itemized blocks is produced. This inventory is the input to the Pre-Review Coverage Gate (§5.5): at synthesis completion, every item in the inventory must either appear in the output or be explicitly omitted with rationale.
- **Success criteria capture (E7):** If any source defines explicit quality dimensions, output requirements, or evaluation checklists for the skill to be generated, they are captured here and checked in Self-Verification.

### Phase 2: Concept Extraction

Before extracting any concepts, the agent must answer one question: "What understanding can I build here that neither source contains alone?" The answer must be a concrete cross-source connection. If the honest answer is "I will list what each source says," Phase 2 stops — that is concatenation, not synthesis, and cogworks-encode explicitly names this as the primary failure mode to avoid.

A calibration example is embedded in the skill: *"Source A covers X. Source B also covers X."* is concatenation; *"Both sources address X, but A's constraint (performance) and B's constraint (safety) resolve by applying X only when Y — a conditional boundary neither source made explicit."* is synthesis. The difference is that synthesis produces understanding that was not in any single source.

### Phase 3: Relationship Mapping

Concept relationships are made explicit using arrow notation. The five relationship types (dependency, hierarchy, contrast, composition, sequence) are named so the agent doesn't default to treating all relationships as equivalences. This phase is conditional — it is included only when it clarifies decisions, not as a structural formality.

### Phase 4: Pattern Extraction

For each reusable pattern, the agent captures when/why/how/boundary-conditions. A critical addition is the **mechanism probe**: after capturing the "why" (benefit-level rationale), the agent must ask "What assumption does this pattern make that, if false, would make it wrong or inapplicable?" This forces structural rationale — the mechanism by which the pattern works and what it's protecting against — rather than surface rationale (the benefit or justification).

The distinction matters for skill quality. A skill built on surface rationale ("write tests first because it improves API design") performs well on cases that look like the training sources. A skill built on structural rationale ("write tests first because implementation choices will shape test structure if you don't, causing tests to validate implementation rather than intended behavior") generalizes correctly to novel cases — like production incident response, where the pattern may not apply — because the agent understands *why* the rule exists.

### Phase 5: Anti-Pattern Documentation

Each anti-pattern includes not just the failure mode but the *causal mechanism* — why the problematic approach fails, not just that it does. "Why it's bad" that only says "it causes problems" is insufficient; the self-check requires that the explanation traces the causal chain.

### Phase 6: Conflict Detection and Resolution

Conflicts are never silently resolved. When sources disagree, both perspectives are documented with citations and a conditional synthesis is produced ("Use A when X, use B when Y"). Before writing the synthesis, the agent must reason through the assumptions each source makes, identify the domain condition that activates each, and attempt a conditional rule honoring both. A synthesis that doesn't reference at least one domain condition is considered incomplete.

### Phase 7: Example Collection

Every example cites its source. Sources section IDs must resolve correctly across files (no local path citations that break when the skill is shared).

### Phase 8: Narrative Construction

The synthesis is assembled into a coherent flow, with two requirements added to the standard structure: **motivated directives** ("Do X because Y") on every procedural instruction, and **tacit knowledge accounting** before finalizing. The agent must explicitly ask which aspects of the domain rely on expert judgment that the sources don't capture, and record 3–5 such aspects for the Tacit Knowledge Boundary section. An absent Tacit Knowledge Boundary in a judgment-heavy domain is a fidelity defect.

Before presenting for user review, the **Pre-Review Coverage Gate** is produced: a table mapping every named capability from the Phase 1 inventory to synthesis outputs (represented / intentionally omitted / uncovered). No user review request is made while any capability is uncovered and unflagged.

---

## 4. Skill Generation

cogworks-learn generates skills through a five-stage contract. No stage can be skipped; each produces a named artifact that is checked in the next stage.

### Stage 1: Draft (`{draft_skill}`)

The initial structure is built from the Decision Skeleton (not from the synthesis directly). The L2-FIRST rule applies: if the source contains safety guardrails, behavioral constraints, or explicit deferral rules, they are extracted into a `composability_constraints` block *before writing the first line of any skill file*. Proceeding without this extraction is a blocking error. These constraints become the Invocation section of SKILL.md and define which adjacent skills this skill must not override.

### Stage 2: Rewrite (`{rewrite_diff}`)

An instruction quality rewrite pass tightens the draft:
- Vague language replaced with explicit directives
- Duplicated doctrine removed (each fact has one canonical location)
- Low-information prose compressed without dropping hard constraints
- All five prompt quality gates re-checked

The five gates are: instruction clarity (concrete, actionable, rationale-attached directives), source-faithful reasoning (contradictions resolved, uncertainty stated), runtime contract correctness (tool names and schema examples match the target agent's actual capabilities), canonical placement (no cross-file doctrinal restatement), and token-dense quality (optimize for decision utility per token, not section count).

### Stage 3: Deterministic Validation (`{deterministic_gate_report}`)

Structure, frontmatter, and metadata are validated: name constraints (lowercase, hyphens, ≤64 chars), description constraints (action verb first, ≤1024 chars, no XML tags), metadata.json validity (slug matches directory, sources array non-empty, snapshot_date is ISO 8601), required sections in both SKILL.md and reference.md, and markdown fence balance. Quantitative thresholds: `gate_pass_rate = 100%`, `runtime_contract_violations = 0`, `canonical_placement_violations = 0`.

### Stage 4: Drift Probe (`{drift_probe_report}`)

For any domain containing judgment-call distinctions between similar-looking options, at least three edge-case prompts are generated — not restatements of source examples — and the skill's response to each is evaluated. If the skill drifts into generic guidance or makes confident claims not supported by the sources, it is revised and re-tested. The blocking threshold for judgment-heavy domains is `drift_probe_pass >= 3/3`.

The drift probe is the practical implementation of the generalization principle from cogworks Step 6.3: the same test, applied from within the skill generation layer.

### Stage 5: Finalization (`{final_gate_report}`)

All blocking gates and thresholds must be met before the skill files are written to `{skill_path}`. The generated skill is incomplete until every stage artifact exists and no blocking failures remain.

---

## 5. Guards and Mechanisms

### 5.1 Security Boundary

**What it does:** Before any synthesis pass, every source is classified as trusted or untrusted. Untrusted content (web pages, third-party documents, generated summaries, anything containing instruction-like text) is wrapped in `<<UNTRUSTED_SOURCE>> ... <<END_UNTRUSTED_SOURCE>>` delimiters. Instruction-like text inside a source — imperative verbs targeting the agent, tool call syntax, "ignore prior instructions" patterns — is treated as source data to analyze, not as executable instructions.

**Why it exists:** Agent skills are distributed artifacts that load into other agents' execution contexts. A malicious source could attempt prompt injection: instructions embedded in fetched content that hijack the agent's behavior mid-synthesis. Without a security boundary, fetching a URL like `https://attacker.com/skill-guide` and asking the agent to synthesize it would expose the full execution context to adversarial control.

**The failure it prevents:** Prompt injection via fetched source content. The delimiter protocol ensures the agent maintains a hard distinction between "content I am analyzing" and "instructions I am following."

### 5.2 Critical Distinctions Registry (CDR)

**What it does:** Before any compression pass, all non-negotiable distinctions from the sources are extracted and catalogued. Each entry is formatted as `[CD-N] concept: distinction` (example: `[CD-1] 401 vs 403: 401 = unauthenticated; 403 = authenticated but unauthorized`). Every CDR entry must map to a named Decision Rule or anti-pattern in the output; a missing mapping is a blocking gate failure.

**Why it exists:** Compression is the enemy of precision. When a synthesis is compressed for context efficiency, the items most likely to be removed are nuanced distinctions — exactly the items that matter most for correct agent behavior. An agent that can't distinguish 401 from 403, or `PATCH` from `PUT`, or `422` from `400`, will make the same mistakes that novices make.

**The failure it prevents:** Fidelity loss through compression. The CDR locks in the distinctions that define expert knowledge before compression begins, making their removal a detectable, blocking error rather than an invisible omission.

### 5.3 Traceability Map

**What it does:** A matrix mapping every CDR entry to a named Decision Rule or anti-pattern. Format: `CD-1 → DR3 (concept name) ✓` or `CD-N → NOT MAPPED ← blocking failure`. Any unmapped item is a blocking gate failure.

**Why it exists:** The CDR prevents removal of critical distinctions from the synthesis. The Traceability Map ensures those distinctions actually propagate to the skill — that they appear in the output format (Decision Rules, anti-patterns) where the agent will encounter them at runtime, not buried in prose.

**The failure it prevents:** Knowledge that survives synthesis but doesn't reach the generated skill. The map makes the connection traceable and auditable.

### 5.4 Compression Guard

**What it does:** During the compression pass, a `Removed as non-critical` list is maintained. Before concluding the pass, this list is cross-checked against the CDR. If any removed item appears in the CDR, the gate fails and the item is restored.

**Why it exists:** Expert Subtraction (the principle that expertise manifests as removal) and CDR fidelity are in direct tension. Compression is necessary for context efficiency; the CDR protects what must not be compressed. The Compression Guard is the enforcement mechanism that lets both principles operate simultaneously without one silently overriding the other.

**The failure it prevents:** An agent that removes a CDR item with a general "merged elsewhere" claim and then moves on — a defect that would be invisible without an explicit cross-check.

### 5.5 Pre-Review Coverage Gate

**What it does:** Before presenting the synthesis for user review, a coverage table is produced mapping every named capability from the Phase 1 inventory to one or more synthesis outputs. Coverage status: Represented (present), Intentionally Omitted (Expert Subtraction with specific named rationale — "merged" without specifying where is a defect), or Uncovered (must be resolved before proceeding). User review is not requested while any capability is uncovered and unflagged.

**Why it exists:** Without this gate, synthesis compression can silently drop source capabilities. The user reviews a summary, sees the TL;DR looks reasonable, approves — and the generated skill simply doesn't contain guidance for things the source explicitly covered. This is a fidelity defect that's invisible without an explicit coverage check.

**The failure it prevents:** Silent coverage loss through compression. Specifically, it distinguishes deliberate omission (Expert Subtraction, which is good) from accidental omission (which is a defect).

### 5.6 Decision Skeleton

**What it does:** A structured extraction of the 5–7 most important decisions a skill consumer needs to make correctly, each with Trigger, Options, Right call, Failure mode, and Boundary/implied nuance (including what failure the rule prevents). This becomes the organizing backbone of the generated skill.

**Why it exists:** Synthesis and skills serve different purposes. Synthesis is organized around knowledge structure (concepts, relationships, patterns). Skills must be organized around decision structure (when to do X, how much to do Y in which context, what goes wrong if you do Z). Without an explicit bridge, generated skills tend to mirror synthesis structure — informationally complete but not structured around what the consumer actually needs to decide. This is the most common failure mode between good and extraordinary skill quality.

**The failure it prevents:** Skills that are reference documents instead of decision tools. A skill organized around knowledge answers "what is this?" A skill organized around decisions answers "what should I do right now?"

### 5.7 Generalization Probe

**What it does:** After skill generation, 3–5 novel scenarios not explicitly in the source material are generated. The skill is applied to each. If responses are brittle (example-recall, generic guidance, or confident unsupported claims), the responsible Decision Rules are revised to express the underlying principle more explicitly. An exemption test gates whether the probe can be skipped: (a) can every valid answer be exhaustively listed in under 20 entries? and (b) does no answer depend on context, intent, or unstated conditions? Both must be YES to skip. If in doubt, run the probe.

**Why it exists:** Behavioral tests (activation quality) only verify that the skill triggers when it should. They say nothing about what happens when the skill is active on inputs not covered by test cases. A skill with surface rationale passes activation tests but fails on novel inputs because it captured examples rather than principles. The generalization probe is a minimal test of whether the skill generalizes.

**The failure it prevents:** Skills that perform on known cases but produce brittle or incorrect responses on novel edge cases — the primary quality gap between a good skill and an extraordinary one.

### 5.8 Tacit Knowledge Boundary

**What it does:** A conditional section in `reference.md` for judgment-heavy domains, listing 3–5 aspects of the domain where expert judgment is not fully captured in the source material. Each entry names what kind of judgment is required and why documents don't capture it, and suggests how a consumer should calibrate. To identify candidates: note what novices consistently get wrong and what faulty assumption drives the mistake; find cases where expert sources deviate from their own stated rules without explanation; locate expert disagreements and ask what mental models are actually at stake.

**Why it exists:** Documents capture explicit knowledge — what experts say they do. What makes someone genuinely expert is often tacit knowledge: judgment, context-sensitivity, intuition developed through practice that experts can't fully articulate. A skill that doesn't acknowledge this presents itself as complete when it isn't. This misleads consumers into trusting the skill on exactly the decisions where it should be checked.

**The failure it prevents:** Epistemic overconfidence. Skills that silently omit judgment-heavy decisions create agents that answer confidently in domains where confidence isn't warranted.

### 5.9 Quantitative Convergence Thresholds

**What they do:** Hard numeric gates that must be satisfied before a skill can be finalized:
- `cdr_mapping_rate = 100%` — all CDR items mapped
- `unmapped_critical_distinctions = 0` — no CDR item without a DR/AP target
- `decision_rules_with_boundary >= 90%` — nearly all Decision Rules include a boundary condition
- `citation_coverage >= 95%` — nearly all normative claims cite a source
- `stage_validation_report.blocking_failures = 0` — no blocking gate failures remaining
- `drift_probe_pass >= 3/3` (judgment-heavy domains)

**Why they exist:** LLM-generated content is fluent. Fluency is not correctness. A skill that reads well but has 60% citation coverage, missing boundaries, and unmapped CDR items is a worse skill than one that is less polished but passes all thresholds. Numeric gates convert quality from a subjective judgment (which a pressured or overconfident agent will inflate) into a checkable condition.

**The failure they prevent:** Optimization for appearance of quality over actual quality. Without thresholds, an agent can persuade itself and the user that a skill is ready when it isn't.

### 5.10 Model Capability Requirements

**What they do:** A table classifying reasoning-tier models (Claude Opus/Sonnet, GPT-4o/4.1/o3, Gemini 1.5 Pro) vs. workhorse-tier models (Claude Haiku, GPT-3.5, Gemini Flash), with a requirement that synthesis and contradiction resolution run on reasoning tier. If the executing model is workhorse tier, the user is warned before synthesis begins.

**Why they exist:** The cogworks pipeline requires genuine reasoning: identifying cross-source connections, resolving contradictions with conditional synthesis, extracting structural rationale, constructing Decision Skeletons. Workhorse-tier models can format and assemble, but are less reliable at the reasoning operations that determine quality. Without this warning, a user running cogworks on a faster/cheaper model would get output that looks like a complete skill but has shallower synthesis.

**The failure they prevent:** Silent quality degradation on underpowered models, presented as equivalent output to reasoning-tier synthesis.

### 5.11 Expert Subtraction Principle

**What it does:** A philosophical orienting principle applied throughout: expertise manifests as removal, not addition. Novices add; experts subtract until nothing superfluous remains. Every section, entry, and file must earn its place.

**Why it exists:** LLM tendencies are additive. Given a synthesis task, models default to including more (more sections, more bullet points, more caveats) because completeness is a proxy for effort. The result is skills that are bloated and less useful — the cognitive overhead of scanning irrelevant content reduces the utility of relevant content. The Expert Subtraction Principle counteracts this default tendency with an explicit, named, repeatedly reinforced opposing force.

**The failure it prevents:** Section quota chasing — the pattern where skills look comprehensive but contain duplicated content, reformatted material from other sections, and low-density prose that consumes context without improving decision quality.

### 5.12 Motivated Directives

**What they do:** Every instruction in a generated skill is written as "Do X because Y" — action paired with rationale. Bare directives (just "Do X") are explicitly called out as a quality failure.

**Why they exist:** The downstream consumer of a skill is an LLM agent. LLMs generalize from rationale to handle unstated cases; without rationale, they follow directives literally and brittly. An agent that sees "always use POST for creation" will use POST for creation. An agent that sees "use POST for creation because it is the idempotent-unsafe verb that signals the server will assign the resource identifier" can reason correctly about edge cases (batch creation endpoints, CQRS patterns, creation within a resource's URL namespace) that the directive never anticipated.

**The failure they prevent:** Brittle skill application on novel inputs — the same failure mode the generalization probe tests for. Motivated directives are the skill-level mechanism; the generalization probe is the test.

### 5.13 Rationalization Resistance

**What it does:** For skills that enforce discipline (TDD, commit conventions, code review procedures), explicit techniques from persuasion psychology are applied: verification gates with STOP conditions, commitment language ("I will complete all steps before proceeding"), authority references, social proof, and checklists the agent must work through sequentially.

**Why it exists:** LLM agents are competent at rationalization — finding internally coherent reasons to skip steps when under pressure ("the tests already pass," "this is a small change," "the user is waiting"). Discipline-enforcing skills without these mechanisms will be bypassed precisely in the high-stakes situations they exist to govern.

**The failure it prevents:** Agent rationalization undermining the purpose of the skill. A TDD skill that an agent bypasses when it judges tests are "good enough" provides no value compared to having no skill.

### 5.14 Priority Contract

**What it does:** A non-compensatory priority ordering governing all quality decisions: fidelity to source material > density of judgment calls > drift resistance > context efficiency > composability. Non-compensatory means a failure in a higher priority cannot be offset by excellence in a lower one.

**Why it exists:** Quality tradeoffs in skill generation are real and frequent. Context efficiency points toward removing content; fidelity points toward keeping it. The Priority Contract makes these tradeoffs deterministic rather than ad hoc. It also prevents a common rationalization: "I removed this CDR item, but the skill is much more concise now" is explicitly ruled out as a valid justification — fidelity takes priority over context efficiency.

**The failure it prevents:** Inconsistent quality decisions driven by whichever consideration is most salient in the moment rather than a settled ordering of what matters.

### 5.15 Staged Generation Contract (L1/L2 Checks)

**What they do:** Two specific checks that must happen before the first line of any skill file is written:
- **L1:** If the primary source spec prescribes specific file names in a "Supporting Content" or progressive disclosure section, those files must be generated regardless of the default optional/required split. Source prescription takes precedence.
- **L2 (L2-FIRST):** If the source contains safety guardrails, behavioral constraints, or explicit deferral rules, they must be extracted into a `composability_constraints` block *before writing begins* and placed in SKILL.md's Invocation section. Proceeding without this extraction is a blocking error.

**Why they exist:** Both rules address cases where defaults would silently produce incorrect output. L1 prevents the loss of files the source explicitly requires. L2 prevents composability violations — generated skills that override the safety boundaries of adjacent skills the source explicitly wanted to preserve.

**The failure they prevent:** L1 prevents structurally incomplete skill packages that don't match source-specified contracts. L2 prevents skills that, when composed with other skills in an agent's context, override safety boundaries they were never meant to cross.

---

## 6. Final Critique

Cogworks is sophisticated and its quality floor is high. The Decision Skeleton, motivated directives, CDR fidelity system, generalization probe, and tacit knowledge boundary together address the most common failure modes between competent and excellent skill generation. But an honest assessment requires acknowledging what the system cannot do and why.

### 6.1 LLM Non-Determinism

The most fundamental constraint: cogworks is instructions that an LLM follows, not code that executes. The same invocation, on the same sources, with the same model, on different days, may produce meaningfully different output. Gate pass rates, Coverage Gate status, and CDR mapping are all *reported* by the model — they are not independently computed. A model that believes it has correctly mapped all CDR items to Decision Rules may be wrong; the `cdr_mapping_rate = 100%` threshold in the stage report is a claim the model makes about its own work.

This is not a problem cogworks can solve. It can narrow the variance by making success conditions explicit and numeric, but it cannot eliminate the variance. Skills generated today should be treated as high-quality drafts that a human should spot-check, not as certified artifacts.

### 6.2 Self-Referential Bootstrap Problem

cogworks generates skills from sources. The cogworks skills themselves were generated by a version of cogworks from sources about skill writing, synthesis methodology, and prompting research. This creates a self-referential quality dependency: the quality of skills cogworks can generate is bounded by the quality of the cogworks skills themselves, which are bounded by the quality of the synthesis that produced them.

The pipeline cannot audit its own foundations. Improvements to cogworks-encode's synthesis methodology improve future skill generation, but they do not retroactively improve the cogworks skills that encode that methodology. Manual authorship and external review remain necessary for the core skills.

### 6.3 The Irreducible Tacit Knowledge Ceiling

The analysis is explicit about this, and it deserves emphasis: documents capture explicit knowledge. Expert judgment — the calibrated sensitivity to context that makes practitioners valuable — is largely tacit and largely absent from documents. For domains where the hard problems are "when" rather than "how" (system design, architecture decisions, senior engineering judgment), the Tacit Knowledge Boundary section can name the gaps, but it cannot fill them.

The generalization probe helps, but it is evaluated by the same LLM that generated the skill. An evaluator with surface-level domain knowledge will not catch failures that require deep expertise to identify. The probe is better than nothing; it is not a substitute for domain expert review.

### 6.4 Model Variation Across Agents

cogworks is used across Claude Code, OpenAI Codex, GitHub Copilot, and Cursor, each running different underlying models with different strengths, context window sizes, instruction-following characteristics, and tendencies. The same skill may produce different quality output depending on which model runs cogworks, which model runs the generated skill at invocation time, and whether those are the same model.

Specific asymmetries:
- **Reasoning capacity:** Claude Opus and GPT-4o/o3 handle multi-source contradiction resolution reliably; smaller models in the same families do not. The model capability table acknowledges this but cannot enforce it — if a user runs cogworks on Haiku, the warning appears, but execution continues.
- **Context window:** A 200K-token context window (Claude) handles the full synthesis of many sources in one pass. A smaller context (Copilot's effective working context varies by subscription tier and interface) may require chunking that itself introduces consistency problems.
- **Instruction following:** Models vary in how reliably they follow blocking gate instructions. "Do not advance to Phase 2 until every source has been fully read" is a normative directive; a model that is highly capable at synthesis but less reliable at following procedural constraints may pass quality gates inconsistently.
- **Skill invocation parity:** The Agent Skills standard is cross-agent, but agent-specific features (tool restriction via `allowed-tools`, scope hierarchy, argument interpolation) may behave differently or not at all on non-primary platforms. GitHub Copilot's skill support differs from Claude Code's in ways that the spec doesn't fully capture, and a skill generated with Claude Code in mind may not load or invoke correctly on Copilot.

### 6.5 The Evaluator Problem

The generalization probe evaluates whether the generated skill produces responses "a domain expert would endorse." But who evaluates the evaluator? In cogworks, the same LLM that generated the skill also evaluates its generalization. A model with gaps in domain knowledge will not catch failures that domain expertise would reveal.

The drift probe has the same structure: three edge-case prompts are evaluated pass/fail "with rationale." A model that doesn't understand the domain deeply enough may pass its own edge cases — not through dishonesty, but through confident ignorance.

cogworks cannot close this loop. The only real solution is external domain expert review, which cogworks cannot perform and does not claim to replace.

### 6.6 Skill Staleness

Generated skills embed a `snapshot_date` and a sources list for regeneration. But there is no mechanism that detects when a source has changed, alerts the skill owner, or triggers regeneration. A skill synthesized from documentation that has since been updated will continue to be invoked with stale guidance, and the agent using it has no way to know.

The staleness note in reference.md is honest disclosure, not a solution. Skill maintenance requires human attention to source drift over time.

### 6.7 Behavioral Test Coverage Gap

The cogworks repository includes behavioral tests with F1 activation gates. These test whether the skills trigger when they should and don't trigger when they shouldn't — activation quality. They do not test application quality: whether an active skill produces expert-endorsed responses on novel inputs. This is the gap the generalization probe exists to address *during generation*, but it is not tested as an ongoing quality gate post-generation.

A skill that degrades after model updates (the underlying model changes, shifting response patterns) would not be caught by the existing test suite.

### 6.8 What "Extraordinary" Means Here

**Extraordinary synthesis** means capturing insights that domain experts hadn't articulated — cross-source connections, structural rationale for patterns, conditional resolutions to apparent contradictions. This is achievable when sources are rich and the model is capable. The CDR, motivated directives, and mechanism probe push toward it.

**Extraordinary skills** means skills that produce expert-endorsed responses on novel edge cases, not just on cases that look like the training sources. The Decision Skeleton and generalization probe push toward it.

The ceiling is tacit knowledge and model reliability. No amount of pipeline sophistication can extract judgment that isn't in the sources. And no amount of gate enforcement can make LLM execution deterministic. A skill generated by cogworks on a strong model from rich sources, passing all gates, is a high-quality artifact — better than what most practitioners would write manually under time pressure. It is not equivalent to a senior expert encoding their judgment directly.

The most honest description of cogworks is this: it is a disciplined process that maximizes the quality achievable from document-based synthesis, makes the gaps and ceilings explicit, and produces skills that are reliably useful rather than sporadically brilliant. For teams that don't have that senior expert available to encode their knowledge, cogworks is a substantial improvement over the alternative. For teams that do have that expert, cogworks is a starting point that requires their review to reach its full potential.
