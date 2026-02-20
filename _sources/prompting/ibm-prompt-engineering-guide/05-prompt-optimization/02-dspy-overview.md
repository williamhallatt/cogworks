# DSPy: Programmatic Prompt Optimization

**Source:** https://www.ibm.com/think/topics/dspy
**Downloaded:** 2026-02-20

## Overview

DSPy is a toolkit that replaces manual prompt engineering with Python-based configuration. Rather than tediously tweaking text prompts, developers use DSPy's modules to automate prompt optimization through algorithmic methods.

## Core Concept

The framework harnesses LLMs' generative capabilities differently than traditional approaches. As the article notes, DSPy "harnesses the idea generation power of LLMs to generate their own prompts," then tests variations against evaluation metrics—similar to evolutionary algorithms selecting for fitness.

## Key Use Cases

- **Chain of Thought prompting**: Decomposing complex tasks into logical steps
- **Retrieval-Augmented Generation**: Optimizing RAG pipelines with labeled or bootstrapped examples
- **Multihop Question Answering**: Handling queries requiring multiple retrieval steps
- **Summarization**: Tuning summarization quality through labeled training data

## Essential Terminology

**Compiling**: Translating Python programs into language model-executable instructions

**Signatures**: Classes defining input/output types for modules

**Optimizers**: Components fine-tuning programs for specific models; they adjust LM weights, instructions, and demonstrations using multistage algorithms

**Pipeline**: Connected module sequences accomplishing complex tasks

**Metrics**: Performance measurement tools; customizable beyond built-in options like Semantic F1

## Getting Started

Installation is straightforward: `pip install dspy-ai`. The framework runs locally or on hosted environments without special hardware requirements.

## Resources

The open-source project includes comprehensive documentation and tutorials at StanfordNLP's GitHub repository.
