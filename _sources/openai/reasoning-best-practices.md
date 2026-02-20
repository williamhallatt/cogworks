# Reasoning Best Practices - Documentation Extract

## Overview
This guide covers OpenAI's reasoning models (o3, o4-mini) versus GPT models, explaining when to use each and how to prompt them effectively.

## Reasoning vs. GPT Models

**Key Differences:**
- **Reasoning models ("planners")**: Excel at complex problem-solving, strategy development, and high-accuracy tasks requiring deep analysis
- **GPT models ("workhorses")**: Optimized for speed, cost-efficiency, and straightforward task execution

**Selection criteria:**
- Choose GPT for speed/cost with well-defined tasks
- Choose reasoning models for accuracy, reliability, and complex problem-solving
- Most workflows benefit from combining both approaches

## When to Use Reasoning Models

### Primary Use Cases:
1. **Ambiguous tasks** - Handle limited or disparate information with minimal guidance
2. **Information extraction** - Find relevant details within large unstructured datasets
3. **Complex document analysis** - Reason across hundreds of pages to identify relationships and nuance
4. **Agentic planning** - Orchestrate multi-step solutions and delegate execution tasks
5. **Visual reasoning** - Interpret challenging visuals like ambiguous charts or poor-quality images
6. **Code review** - Detect subtle changes and quality issues across multiple files
7. **Evaluation/benchmarking** - Validate and assess other model responses with nuanced judgment

## Prompting Best Practices

**Effective techniques:**
- Use developer messages (not system messages) for o1-2024-12-17+
- Keep prompts simple and direct
- Avoid "think step by step" instructions
- Use delimiters (markdown, XML tags) for clarity
- Start with zero-shot; add few-shot examples only if needed
- Specify explicit constraints and success criteria
- Include `Formatting re-enabled` on first line of developer message if markdown formatting desired

**What to avoid:**
- Over-engineering prompts with chain-of-thought techniques
- Complex multi-part instructions when simple ones suffice

## Cost Optimization

When using Responses API with o3/o4-mini:
- Set `store` parameter to `true`
- Pass reasoning items from previous requests
- OpenAI automatically includes relevant context while minimizing token usage
- Chat Completions API doesn't preserve reasoning items between calls

---

**Note:** This extraction preserves the document's educational structure while avoiding reproduction of extensive customer quotes or code examples present in the original.

---

## Source

https://developers.openai.com/api/docs/guides/reasoning-best-practices
