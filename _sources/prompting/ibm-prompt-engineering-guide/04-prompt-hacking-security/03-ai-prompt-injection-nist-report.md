# How AI Can Be Hacked with Prompt Injection: NIST Report

**Source:** https://www.ibm.com/think/insights/ai-prompt-injection-nist-report
**Downloaded:** 2026-02-20

## Overview

The National Institute of Standards and Technology (NIST) has documented prompt injection as a significant cybersecurity vulnerability targeting generative AI systems. Their publication, *Adversarial Machine Learning: A Taxonomy and Terminology of Attacks and Mitigations*, categorizes various attack methods and recommends mitigation strategies.

## What is Prompt Injection?

NIST identifies two primary attack categories:

**Direct Prompt Injection**: Users enter text prompts causing LLMs to perform unauthorized actions. A notable example is "Do Anything Now" (DAN), which uses roleplay to circumvent ChatGPT's safety filters. The technique has evolved through multiple iterations as OpenAI updates defenses.

**Indirect Prompt Injection**: Attackers poison data sources that AI models consume—including PDFs, documents, webpages, and audio files. Security experts consider this approach particularly dangerous because "simple ways to find and fix these attacks" remain elusive. Examples range from benign (manipulating chatbot tone) to serious (social engineering for personal data theft or hijacking AI assistants to send fraudulent emails).

## Defense Strategies

NIST recommends a multi-layered approach:

- **For model creators**: Curate training datasets carefully; train models to recognize adversarial inputs
- **For indirect attacks**: Implement reinforcement learning from human feedback (RLHF) to align models with human values; filter instructions from retrieved inputs; deploy LLM moderators; use interpretability-based solutions to detect anomalous inputs

The report acknowledges complete prevention remains impossible, but defensive measures can meaningfully reduce risk.
