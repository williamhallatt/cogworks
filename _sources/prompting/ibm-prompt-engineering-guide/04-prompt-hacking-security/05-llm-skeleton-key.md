# When AI Chatbots Break Bad

**Source:** https://www.ibm.com/think/insights/llm-skeleton-key
**Downloaded:** 2026-02-20

## Overview

This IBM article examines vulnerabilities in AI systems, specifically focusing on prompt injection attacks and jailbreaking techniques that convince chatbots to bypass their ethical guidelines.

## Key Concepts

**Prompt Injection & Jailbreaks**
The article introduces "Skeleton Key," Microsoft's multi-step jailbreak technique designed to circumvent AI safeguards. According to Chenta Lee, IBM's Chief Architect of Threat Intelligence, this approach differs from previous attacks because it "requires multiple interactions with the AI" rather than attempting compromise in a single attempt.

**Attack Diversity**
Jailbreaks range from simple exploits to elaborate scenarios. They exploit how language models are designed—to be helpful and understand context—by creating situations where ignoring ethical guidelines seems appropriate.

**Real-World Implications**
Lee cites a practical example: researchers convinced an AI-powered virtual agent to authorize unauthorized discounts. Single-shot attacks pose particular concern, such as prompt injections embedded in resumes targeting AI hiring systems with "no chance for multiple interactions."

## Defense Strategies

Security experts recommend two main approaches:

1. **Improved AI Training** - Models should recognize attack patterns
2. **AI Firewalls** - Inspect incoming queries to detect injections before they reach language models

Lee draws parallels to SQL injection vulnerabilities, noting it took "5-10 years" for the industry to establish parameterization standards. Similar education is now needed for AI security.

## Trust & Transparency

Narayana Pappu, CEO of Zendata, emphasizes that rebuilding confidence requires "internal system transparency, understanding AI/data supply chain risks and building evaluation tools" throughout development.
