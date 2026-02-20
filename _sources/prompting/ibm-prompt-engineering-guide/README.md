# IBM Prompt Engineering Guide - Local Reference

**Source:** IBM Think (https://www.ibm.com/think/prompt-engineering)
**Downloaded:** 2026-02-20
**Total Pages:** 28

This is a personal reference collection of summaries from IBM's publicly available Prompt Engineering Guide. All content is attributed to IBM and sourced from their Think platform.

---

## 01. Introduction (3 pages)

### [01-prompt-engineering-overview.md](01-introduction/01-prompt-engineering-overview.md)
Introduction to prompt engineering fundamentals, why it matters, core techniques, required skills, and real-world applications.

### [02-prompt-engineering-techniques.md](01-introduction/02-prompt-engineering-techniques.md)
Comprehensive overview of prompt engineering techniques including zero-shot, few-shot, chain-of-thought, meta prompting, RAG, and more.

### [03-rag-vs-fine-tuning-vs-prompt-engineering.md](01-introduction/03-rag-vs-fine-tuning-vs-prompt-engineering.md)
Comparison of three main techniques for optimizing LLMs: prompt engineering, RAG, and fine-tuning, with guidance on when to use each approach.

---

## 02. Agentic Prompting (6 pages)

### [01-prompt-chaining-overview.md](02-agentic-prompting/01-prompt-chaining-overview.md)
Introduction to prompt chaining - linking multiple prompts sequentially for complex task decomposition.

### [02-prompt-chaining-langchain-tutorial.md](02-agentic-prompting/02-prompt-chaining-langchain-tutorial.md)
Hands-on tutorial for implementing prompt chaining with LangChain, covering nine chaining patterns and practical examples.

### [03-tree-of-thoughts.md](02-agentic-prompting/03-tree-of-thoughts.md)
Deep dive into Tree of Thoughts (ToT) framework for hierarchical problem-solving with multiple solution paths and backtracking.

### [04-meta-prompting.md](02-agentic-prompting/04-meta-prompting.md)
Advanced technique for creating reusable, step-by-step prompt templates that work across entire problem categories.

### [05-iterative-prompting.md](02-agentic-prompting/05-iterative-prompting.md)
Structured approach to refining prompts through feedback loops for continuous improvement of AI responses.

### [06-react-prompting-tutorial.md](02-agentic-prompting/06-react-prompting-tutorial.md)
Tutorial on ReAct framework combining reasoning and action, with financial analysis example using IBM Granite models.

---

## 03. Example-Based Prompting (3 pages)

### [01-zero-shot-prompting.md](03-example-based-prompting/01-zero-shot-prompting.md)
Technique where LLMs perform tasks without examples, relying entirely on pretrained knowledge.

### [02-one-shot-prompting.md](03-example-based-prompting/02-one-shot-prompting.md)
Using a single well-crafted example to guide model behavior and task performance.

### [03-few-shot-prompting.md](03-example-based-prompting/03-few-shot-prompting.md)
Providing limited examples to guide AI model performance when extensive training data is unavailable.

---

## 04. Prompt Hacking & Security (5 pages)

### [01-prompt-injection-overview.md](04-prompt-hacking-security/01-prompt-injection-overview.md)
Overview of prompt injection attacks - how attackers manipulate LLM systems through malicious inputs.

### [02-prevent-prompt-injection.md](04-prompt-hacking-security/02-prevent-prompt-injection.md)
Comprehensive mitigation strategies including input validation, architectural approaches, and defense-in-depth methods.

### [03-ai-prompt-injection-nist-report.md](04-prompt-hacking-security/03-ai-prompt-injection-nist-report.md)
NIST's documentation of prompt injection vulnerabilities, attack categories, and recommended defense strategies.

### [04-ai-jailbreak.md](04-prompt-hacking-security/04-ai-jailbreak.md)
Examination of AI jailbreaking techniques, risks, prevalence, and mitigation strategies for bypassing safety guidelines.

### [05-llm-skeleton-key.md](04-prompt-hacking-security/05-llm-skeleton-key.md)
Analysis of the "Skeleton Key" multi-step jailbreak technique and comparisons to SQL injection vulnerabilities.

---

## 05. Prompt Optimization (5 pages)

### [01-prompt-optimization-overview.md](05-prompt-optimization/01-prompt-optimization-overview.md)
Refining input prompts to enhance LLM output quality through iterative testing and evaluation metrics.

### [02-dspy-overview.md](05-prompt-optimization/02-dspy-overview.md)
Introduction to DSPy - a Python framework for programmatic, automated prompt optimization.

### [03-dspy-tutorial.md](05-prompt-optimization/03-dspy-tutorial.md)
Hands-on tutorial building a RAG question-answering application using DSPy with IBM Granite models.

### [04-prompt-caching-overview.md](05-prompt-optimization/04-prompt-caching-overview.md)
Technique for storing and reusing prompt components to reduce costs and latency in LLM applications.

### [05-prompt-caching-langchain-tutorial.md](05-prompt-optimization/05-prompt-caching-langchain-tutorial.md)
Implementation guide for prompt caching using LangChain with IBM Granite models and SQLite storage.

---

## 06. Prompt Reasoning Enhancement (4 pages)

### [01-chain-of-thoughts.md](06-prompt-reasoning-enhancement/01-chain-of-thoughts.md)
Guiding LLMs through step-by-step reasoning processes to improve accuracy on complex, multistep problems.

### [02-directional-stimulus-prompting.md](06-prompt-reasoning-enhancement/02-directional-stimulus-prompting.md)
Providing structured guidance to generate desired outputs through pseudo-stimuli and reinforcement learning.

### [03-role-prompting-tutorial.md](06-prompt-reasoning-enhancement/03-role-prompting-tutorial.md)
Tutorial on having AI models adopt specific personas for more tailored, contextually appropriate responses.

### [04-in-context-learning.md](06-prompt-reasoning-enhancement/04-in-context-learning.md)
Comprehensive guide to in-context learning - enabling LLMs to adapt to tasks instantly through examples in prompts.

---

## 07. Prompt Tuning (2 pages)

### [01-prompt-tuning-overview.md](07-prompt-tuning/01-prompt-tuning-overview.md)
Parameter-efficient technique for adapting pretrained models using trainable soft prompt vectors.

### [02-prompt-tune-granite-tutorial.md](07-prompt-tuning/02-prompt-tune-granite-tutorial.md)
Step-by-step tutorial for implementing prompt tuning on IBM Granite models using watsonx.ai.

---

## Usage Notes

- All content summarized from IBM Think articles and tutorials
- Each file includes source URL and download date
- Files contain key concepts, examples, and implementation guidance
- Organized by topic for easy reference
- Suitable for personal study and educational purposes

## Related IBM Resources

- IBM watsonx.ai: https://www.ibm.com/watsonx
- IBM Developer Hub: https://developer.ibm.com
- IBM Granite Models: https://www.ibm.com/granite

---

**Note:** This is a personal reference collection created for educational purposes. All content is attributed to IBM and sourced from their publicly available Think platform. For the most current and complete information, please visit the original IBM Think articles.
