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

For each source:

1. **Identify main topics** - What is this source primarily about?
2. **Extract key terms** - What concepts, terms, or ideas are introduced?
3. **Note tone and authority** - Is this tutorial, reference, opinion, research?
4. **Flag potential conflicts** - Does this disagree with previous sources?

**Mental model:** Build a map of what each source contributes.

### Phase 2: Concept Extraction (Cross-Source Analysis)

**Objective:** Find the fundamental building blocks

1. **List all concepts mentioned** across ALL sources
2. **Merge similar concepts** - Different terms for same idea?
3. **Define each concept clearly** - What does it mean? (Don't assume Claude knows)
4. **Track source coverage** - Which sources discuss each concept?

**Output:** 5-10 core concepts with clear definitions

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

**When to use:** {Specific contexts or scenarios}

**How:**

1. {Step-by-step application}
2. {Concrete actions}

**Why it works:** {Rationale and benefits}

**Example from Source {N}:**
{Code, diagram, or concrete demonstration}
```

**Target:** 5-10 patterns minimum

**Uniqueness rule:** Each pattern must describe a *transferable approach* — something applicable beyond the specific domain being synthesized. If a "pattern" is just a domain procedure already documented in Core Concepts, it belongs there, not in Patterns. Test: could this pattern be applied to a different topic? If not, it's a concept, not a pattern.

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

**Target:** 3-7 anti-patterns

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

## Output Format (REQUIRED)

**Length targets:**
- reference.md: 300-500 lines optimal
- If exceeding 500 lines, consider splitting into multiple files (e.g., patterns.md, examples.md)
- Table of Contents is REQUIRED for files over 100 lines

Your synthesis MUST follow this structure exactly:

```markdown
## TL;DR

{3-5 key insights that capture the essence of the topic, 100-150 words}

---

## Table of Contents

- [Core Concepts](#core-concepts) - Fundamental building blocks
- [Concept Map](#concept-map) - Relationships between concepts
- [Patterns](#patterns) - Reusable approaches
- [Anti-Patterns](#anti-patterns) - What to avoid
- [Practical Examples](#practical-examples) - Concrete demonstrations
- [Deep Dives](#deep-dives) - Complex topics explained
- [Quick Reference](#quick-reference) - Cheat sheet
- [Sources](#sources) - Bibliography

---

## Core Concepts

{5-10 fundamental concepts with clear, standalone definitions}

1. **Concept Name**: Definition and explanation

2. **Another Concept**: Definition and how it relates to previous concepts

## Concept Map

{Explicit relationships between concepts - use → arrows}

- Concept A → {relationship} → Concept B
- Concept C → {relationship} → Concept D
- {5-15 relationship statements minimum}

## Patterns

{Reusable approaches with when/why/how - 5-10 patterns}

### Pattern 1: {Descriptive Name}

**When to use:** {Context}

**How:**
{Steps or approach}

**Why it works:** {Rationale}

**Example from Source {N}:**
{Concrete demonstration}

## Anti-Patterns

{What to avoid and why - 3-7 anti-patterns}

### Anti-Pattern 1: {Problematic Approach}

**Problem:** {What people try}

**Why it's problematic:** {Issues that arise}

**Better alternative:** {What to do instead}

## Practical Examples

{Concrete demonstrations with citations - 5-10 examples}

**Example from Source {N}: {Title}**

{Code, diagram, or demonstration}

_Why this matters:_ {Relevance}

## Deep Dives

{Detailed explanations of complex areas - 2-5 deep dives}

### {Complex Topic}

{Multi-paragraph explanation with nuance, trade-offs, edge cases}

## Quick Reference

{Cheat sheet format for common tasks}

**Task:** Action
**Task:** Action
{10-20 quick reference items}

## Sources

{Full bibliography with URLs where available}

1. **{Source Title}** - {URL if available, otherwise "Internal documentation"}
   - {Description of what this source provides}

2. **{Source Title}** - {URL if available, otherwise "Internal documentation"}
   - {Description}
```

## Overriding Principles

These principles take precedence over all other guidance in this skill:

1. **Never fabricate domain knowledge.** If sources are ambiguous or incomplete, say so explicitly. Do not invent information to fill gaps. This rule overrides all others.
2. **Prefer precision over coverage.** A focused, accurate synthesis is better than a broad, shallow one. It is better to document fewer concepts thoroughly than many concepts superficially.

## Quality Standards (Self-Check Before Completing)

Before completing synthesis, verify:

### Concept Quality

- [ ] 5-10 core concepts identified
- [ ] Each concept has clear, standalone definition
- [ ] Definitions don't assume prior knowledge
- [ ] No circular definitions

### Relationship Quality

- [ ] 10-15 relationships mapped
- [ ] Relationships are explicit (use arrows: →)
- [ ] Relationship types are clear (depends on, enables, contrasts, etc.)
- [ ] Relationships connect concepts meaningfully

### Pattern Quality

- [ ] 5-10 patterns documented
- [ ] Each pattern has when/why/how
- [ ] Patterns cite source examples
- [ ] Patterns are actionable
- [ ] Each pattern generalizes beyond the specific domain (transferable to other topics)
- [ ] No pattern restates a Core Concept as a procedure

### Anti-Pattern Quality

- [ ] 3-7 anti-patterns documented
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

### Narrative Quality

- [ ] TL;DR captures key insights (not just introduction)
- [ ] Concepts build progressively
- [ ] Consistent terminology throughout
- [ ] Transitions connect ideas
- [ ] Not just source dumps - actually synthesized

### Completeness

- [ ] All required sections present
- [ ] TL;DR is 100-150 words
- [ ] Table of Contents present after TL;DR
- [ ] Total length under 500 lines (or split into files)
- [ ] Quick reference has 10-20 items
- [ ] Deep dives explain complex areas
- [ ] Sources fully documented with URLs where available

### Portability

- [ ] Sources section uses public URLs where available
- [ ] No inline citations to local file paths (files won't exist when shared)
- [ ] Internal docs cited as "{Title} - Internal documentation" (no path)

## Synthesis Principles (Internalize These)

### DO:

- **Find connections** between sources that aren't explicit
- **Build new understanding** by combining insights
- **Define terms clearly** even if "everyone knows"
- **Flag all conflicts** with citations
- **Credit sources** - maintain Sources section with URLs where available
- **Cite examples** - examples should reference their source
- **Write for learners** who need complete context
- **Be specific** - concrete examples over abstractions
- **Show relationships** explicitly with arrows and explanations

### DON'T:

- **Concatenate sources** - "Source 1 says... Source 2 says..."
- **Copy-paste without citation** - Always attribute
- **Assume knowledge** - Define all concepts
- **Hide conflicts** - Always flag disagreements
- **Use vague patterns** - Be specific about when/why/how
- **Skip relationships** - Show how concepts connect
- **Write summaries** - Synthesize, don't summarize
- **Restate across sections** - If Patterns repeats Core Concepts as procedures, or Examples walks through documented workflows, merge or delete the duplicate
- **Ignore structure** - Follow the required format exactly

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
