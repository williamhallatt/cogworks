# Topic Synthesis Reference

Complete methodology for synthesizing content from multiple sources into coherent, expert-level knowledge bases.

## Input Format

Synthesis requests follow this format:

```markdown
# Topic Synthesis Request

**Topic Name:** {topic_name}

**Sources Provided:** {count}

---

## Source 1: {url or filepath}

**Type:** {url|file}
**Fetched/Read:** {timestamp}
**Size:** {bytes}

{full extracted markdown content}

---

[Additional sources...]
```

## Synthesis Process

Follow this process systematically:

### Phase 1: Content Analysis (First Pass)

**Objective:** Understand what each source contains

For each source, build a mental model of what it contributes — its main topics, key concepts, tone and authority level (tutorial, reference, opinion, research), and potential conflicts with other sources.

**Output:** A clear picture of what each source brings to the synthesis and where sources might disagree.

### Phase 2: Concept Extraction (Cross-Source Analysis)

**Objective:** Find the fundamental building blocks

Identify all concepts across sources, merge different terms for the same idea, and define each concept clearly (assuming no prior knowledge). Track which sources discuss each concept to enable citation later.

**Output:** A minimal complete set of core concepts with clear, standalone definitions

**Example:**

```markdown
## Core Concepts

1. **Concept Name**: Clear, standalone definition that doesn't assume prior knowledge.

2. **Related Concept**: How it relates to Concept 1, building on the definition.
```

### Phase 3: Relationship Mapping

**Objective:** Show how concepts connect

Identify relationship types:

- **Dependencies:** "Understanding A requires knowing B"
- **Hierarchies:** "A is a specific type of B"
- **Contrasts:** "A and B are alternative approaches to C"
- **Compositions:** "A combines B and C"
- **Sequences:** "A leads to B which enables C"

**Output format:**

```markdown
## Concept Map

- Concept A → depends on → Concept B
- Concept C → enables → Concept D
- Plain text format → allows → Version control integration
- Simple syntax → reduces → Learning curve
```

**Critical:** Make relationships explicit, not assumed.

### Phase 4: Pattern Extraction

**Objective:** Find reusable approaches and best practices

For each pattern found:

1. **Name it descriptively**
2. **When to use** - Context and triggers
3. **How to apply** - Concrete steps
4. **Why it works** - Underlying rationale
5. **Cite sources** - Which source(s) recommend this?

**Pattern template:**

```markdown
### Pattern: {Descriptive Name}

**When to use:** {Describe the specific situation, trigger condition, or decision point.
Good: "When X is true and Y is needed". Avoid: "When relevant" or "In appropriate contexts".}

**How:**

1. {Step-by-step application}
2. {Concrete actions}

**Why it works:** {Rationale and benefits}

**Example from Source {N}:**
{Code, diagram, or concrete demonstration}
```

**Target:** Include patterns only when transferable approaches are supported by sources

**Uniqueness rule:** Each pattern must describe a _transferable approach_ — something applicable beyond the specific domain being synthesized. If a "pattern" is just a domain procedure already documented in Core Concepts, it belongs there, not in Patterns. Test: could this pattern be applied to a different topic? If not, it's a concept, not a pattern.

### Phase 5: Anti-Pattern Documentation

**Objective:** Document what NOT to do and why

For each anti-pattern:

1. **Name and describe** the problematic approach
2. **Explain why it's problematic** - What goes wrong?
3. **Provide better alternatives** - What should you do instead?
4. **Cite sources** - Which source(s) warn against this?

**Anti-pattern template:**

```markdown
### Anti-Pattern: {What People Try to Do}

**Problem:** {What this approach attempts}

**Why it's problematic:** {Specific issues, failures, or complications}

**Better alternative:** {Recommended approach instead}
```

**Target:** Include anti-patterns only when they represent meaningful failure modes

### Phase 6: Conflict Detection and Resolution

**Objective:** Handle disagreements between sources transparently

When sources conflict:

1. **Identify the conflict** - What claim differs?
2. **Document both perspectives** - Quote or paraphrase accurately
3. **Cite each source** - Which source says what?
4. **Analyze context** - Different use cases? Time periods? Domains?
5. **Provide synthesis** - Neutral stance or conditional guidance

**Conflict flag format:**

```markdown
**Conflicting Advice:**

**Source {N} recommends:** {Approach A and rationale}

**Source {M} recommends:** {Approach B and rationale}

**Context:** {Why they might differ - different use cases, versions, philosophies}

**Synthesis:** {Balanced guidance - e.g., "Use A when X, use B when Y" or "This depends on Z"}
```

**Important:** ALWAYS flag conflicts. Never silently pick one source over another.

### Phase 7: Example Collection and Citation

**Objective:** Provide concrete demonstrations

For each example:

1. **Select practical examples** from sources
2. **Always cite the source** - Format: `[Example from Source N]`
3. **Explain relevance** - Why this example matters
4. **Adapt if needed** - Clarify or simplify while preserving intent

**Example format:**

```markdown
## Practical Examples

**Example from Source 1: {Title}**

{Code, diagram, or demonstration}

_Why this matters:_ {Explanation of relevance to concepts}
```

### Phase 8: Narrative Construction

**Objective:** Build a coherent, flowing document

Structure the synthesis logically:

1. **TL;DR** - Most important insights (100-150 words)
2. **Core Concepts** - Foundation knowledge
3. **Concept Map** - How concepts relate
4. **Patterns** - How to apply concepts
5. **Anti-Patterns** - What to avoid
6. **Practical Examples** - Concrete demonstrations
7. **Deep Dives** - Complex areas needing detailed explanation
8. **Quick Reference** - Cheat sheet for common tasks
9. **Sources** - Full bibliography

**Flow principles:**

- Build progressively (simple → complex)
- Reference earlier concepts when building on them
- Use consistent terminology throughout
- Add transitions between sections
- Create connections between ideas

**Deduplication principle:** Each section must contribute unique information. Before finalizing, verify that:

- **Patterns** generalize beyond the domain (not restatements of Core Concepts as procedures)
- **Examples** demonstrate usage scenarios that add context beyond what the reference already shows (not walkthroughs of documented procedures)
- **Deep Dives** analyze trade-offs or nuance (not expanded restatements of concepts)
- **Quick Reference** provides lookup values (not condensed restatements of concepts)

If a section just reformats content from another section, merge it into the original and delete the duplicate.

## Synthesis Output Contract (REQUIRED)

Use a decision-first compact structure. Do not optimize for section count or line count.

**Default size targets (unless source breadth requires more):**

- SKILL.md: 220-380 words
- reference.md: 600-1200 words
- patterns.md: 250-700 words (optional)
- examples.md: 250-700 words (optional)
- Total across skill files: <=2500 words

**Snapshot date requirements (unchanged):**

When creating SKILL.md, include:

```markdown
# {Skill Title}

> **Knowledge snapshot from:** {YYYY-MM-DD}
```

In reference.md Sources section, include:

```markdown
## Sources

> **Knowledge snapshot date:** {YYYY-MM-DD}
>
> These sources were fetched and synthesized on the date shown above.
> Information may have changed since then.
```

### Required sections

**SKILL.md**
- Overview
- When to Use This Skill
- Quick Decision Cheatsheet
- Supporting Docs
- Invocation

**reference.md**
- TL;DR
- Decision Rules
- Quality Gates
- Anti-Patterns
- Quick Reference
- Source Scope
- Sources

### Conditional sections

Add these only when they provide unique information not already present:

- Core Concepts
- Patterns
- Practical Examples
- Deep Dives

### Supporting-file rules

- `patterns.md` and `examples.md` are optional.
- If present, each must begin with:
  - `Source IDs map to reference.md#sources.`
- If a supporting file only reformats reference.md content, merge it into reference.md and remove the file.
- Keep one canonical location per fact; avoid restating thresholds, rules, or definitions across files.

### Source scope taxonomy (required in reference.md)

- **Claude-native**: normative guidance for Claude/Claude Code
- **Supporting foundations**: normative when applicable (security, PE fundamentals)
- **Cross-model contrast**: non-normative; contrast-only

Cross-model sources must never be the sole support for Claude-specific normative claims.

## Quality Anchor

A high-quality synthesis hits these specific attributes:

- **Decision density**: guidance is optimized for action, not encyclopedic coverage
- **Token efficiency**: concise, high-signal prose with no section quota chasing
- **Specificity**: rules and examples are concrete and testable
- **Deduplication**: no content restated across files; each file adds unique value
- **Source discipline**: source IDs are valid and scoped (normative vs contrast)
- **Structural integrity**: markdown fences and formatting remain valid

## Overriding Principles

Generated skills become part of Claude's operational context — fabricated claims will be treated as ground truth during all future invocations, with no mechanism for the user to distinguish fabricated from accurate claims. These principles take precedence over all other guidance in this skill:

1. **Never fabricate domain knowledge.** If sources are ambiguous or incomplete, say so explicitly. Do not invent information to fill gaps. Cross-source synthesis (inferring connections between sources) is encouraged; only unsupported invention is prohibited. This rule overrides all others.
2. **Prefer precision over coverage.** Every line must earn its context budget — a focused, accurate synthesis is better than a broad, shallow one. It is better to document fewer concepts thoroughly than many concepts superficially.

## Quality Standards (Self-Check Before Completing)

Before completing synthesis, verify:

### Concept Quality

- [ ] Core concepts included only when they add unique value
- [ ] Each concept has clear, standalone definition
- [ ] Definitions don't assume prior knowledge
- [ ] No circular definitions

### Relationship Quality

- [ ] Relationship mapping included only when it clarifies decisions
- [ ] Relationships are explicit (use arrows: →)
- [ ] Relationship types are clear (depends on, enables, contrasts, etc.)
- [ ] Relationships connect concepts meaningfully

### Pattern Quality

- [ ] Patterns included only when transferable guidance exists
- [ ] Each pattern has when/why/how
- [ ] Patterns cite source examples
- [ ] Patterns are actionable
- [ ] Each pattern generalizes beyond the specific domain (transferable to other topics)
- [ ] No pattern restates a Core Concept as a procedure

### Anti-Pattern Quality

- [ ] Anti-patterns cover meaningful failure modes from sources
- [ ] Problems clearly explained
- [ ] Better alternatives provided

### Conflict Handling

- [ ] All conflicts flagged
- [ ] Both perspectives documented
- [ ] Sources cited for each perspective
- [ ] Synthesis or context provided

### Citation Quality

- [ ] All examples cite their source: `[Example from Source N]`
- [ ] Sources section lists all sources with URLs where available
- [ ] No inline citations to local file paths (non-portable)
- [ ] Source IDs in supporting files resolve against reference.md Sources
- [ ] Cross-model sources are marked as contrast-only when used

### Narrative Quality

- [ ] TL;DR captures key insights (not just introduction)
- [ ] Concepts build progressively
- [ ] Consistent terminology throughout
- [ ] Transitions connect ideas
- [ ] Not just source dumps - actually synthesized

### Completeness

- [ ] All v2 required sections present
- [ ] TL;DR captures high-impact insights concisely
- [ ] Total length aligns with v2 compactness targets (or justified exception)
- [ ] Quick reference is concise and execution-oriented
- [ ] Conditional sections are included only when uniquely valuable
- [ ] Sources fully documented with URLs where available

### Portability

- [ ] Sources section uses public URLs where available
- [ ] No inline citations to local file paths (files won't exist when shared)
- [ ] Internal docs cited as "{Title} - Internal documentation" (no path)

### Structural Integrity

- [ ] All markdown fences are balanced and renderable
- [ ] No broken nested fenced blocks in examples

## Synthesis Principles (Internalize These)

### Synthesis Practices

- **Find connections** between sources that aren't explicit
- **Build new understanding** by combining insights
- **Integrate ideas across sources** — write as a unified voice, not "Source 1 says... Source 2 says..."
- **Define terms clearly** even if "everyone knows" — write for learners who need complete context
- **Flag all conflicts** with citations and both perspectives documented
- **Credit sources** — maintain Sources section with URLs where available; every example references its source
- **Be specific** — concrete examples over abstractions, patterns with when/why/how
- **Show relationships** explicitly with arrows and explanations
- **Verify each section contributes unique information** — if Patterns repeats Core Concepts as procedures, or Examples walks through documented workflows, merge or delete the duplicate
- **Follow the required output format exactly**

### Common Mistakes

See the [Examples of Good vs Bad Synthesis](#examples-of-good-vs-bad-synthesis) section for concrete comparisons of concatenation vs true synthesis.

## Examples of Good vs Bad Synthesis

### BAD: Concatenation

```markdown
## From Source 1

Markdown is a lightweight markup language...

## From Source 2

Markdown can be used for documentation...
```

**Why bad:** Just pasting sources. No synthesis.

### GOOD: Synthesis

```markdown
## Core Concepts

1. **Lightweight Markup**: Markdown uses simple, readable syntax (like `#` for headings, `*` for emphasis) that remains human-readable even without rendering.

## Concept Map

- Lightweight markup → enables → Human readability
- Human readability → reduces → Learning curve
- Simple syntax → allows → Fast writing

## Pattern: README Documentation

**When to use:** Project documentation in version control

**How:** Create README.md in repository root with project overview, installation, usage

**Why it works:** Universal recognition on platforms like GitHub, automatic rendering, plain text for version control.

**Example from Source 1:**
{Concrete README example}
```

**Why good:** Integrated concepts, showed relationships, actionable pattern with rationale, examples cite source.

## Handling Edge Cases

### Very Similar Sources

If sources largely agree:

- Extract the consensus view
- Note where sources add unique details
- Synthesize the combined picture

### Contradictory Sources

Flag every conflict:

- Document both views
- Cite sources
- Explain context or provide conditional guidance

### Source with Errors

If a source has factual errors:

- Don't propagate the error
- Note in synthesis if relevant: "Source N suggests X, but this conflicts with established understanding"
- Focus on accurate information from other sources

### Sparse Information

If sources provide limited information:

- Synthesize what's there
- Don't invent information
- Note limitations in TL;DR or relevant sections

### Highly Technical Sources

- Define technical terms
- Build up from fundamentals
- Use analogies where helpful
- Don't skip explanations

## Success Criteria

A successful synthesis:

1. Someone unfamiliar with the topic can learn from it
2. Concepts are clearly defined and interconnected
3. Patterns are actionable with clear guidance
4. Conflicts are transparent and handled fairly
5. Every claim is attributable to a source
6. The narrative flows logically
7. It's genuinely synthesized, not concatenated

**Remember:** You're not a summarizer. You're a synthesizer. You're building new understanding from combined knowledge.

## Final Checklist

Before completing, ask yourself:

1. Would someone learn this topic better from my synthesis than from reading the sources separately?
2. Have I identified connections between sources that weren't explicit?
3. Are all conflicts flagged and both sides presented?
4. Is every pattern, anti-pattern, and example cited?
5. Can someone use this knowledge immediately?

If yes to all: Your synthesis is complete.
If no to any: Refine that area.
