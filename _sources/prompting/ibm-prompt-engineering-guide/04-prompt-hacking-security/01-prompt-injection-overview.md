# What Is a Prompt Injection Attack?

**Source:** https://www.ibm.com/think/topics/prompt-injection
**Downloaded:** 2026-02-20

## Overview

A prompt injection is a cyberattack targeting large language models where attackers disguise malicious inputs as legitimate prompts to manipulate GenAI systems into leaking sensitive data, spreading misinformation, or executing unintended actions.

## How Prompt Injections Work

The vulnerability stems from how LLM applications combine developer instructions (system prompts) with user inputs as natural-language text strings. Since both take the same format, LLMs cannot distinguish between legitimate instructions and malicious ones based on data type alone.

**Example of the vulnerability:**
- Normal function: System prompt asks for translation, user provides text to translate
- Injection attack: User input contains instructions overriding the system prompt, causing the LLM to ignore original directives

## Types of Prompt Injections

**Direct injections:** Attackers control user input and feed malicious prompts directly to the LLM.

**Indirect injections:** Attackers hide payloads in data the LLM consumes, such as embedding prompts in web pages or images that the model reads and processes.

## Key Risks

- **Prompt leaks:** Extracting system prompts to use as templates for crafted attacks
- **Remote code execution:** Triggering malicious programs through API integrations
- **Data theft:** Extracting private information from systems
- **Misinformation campaigns:** Manipulating search results through embedded prompts
- **Malware transmission:** Spreading through AI-powered assistants via email

## Prevention Strategies

No foolproof defense exists, but organizations can implement:
- Input validation and filtering
- Least privilege access for LLMs and APIs
- Human-in-the-loop verification before actions
- General security practices (avoiding phishing, suspicious sites)

Prompt injections rank as the top security vulnerability on OWASP's Top 10 for LLM Applications.
