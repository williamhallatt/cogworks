# Prompt Engineering with DSPy - Tutorial Summary

**Source:** https://www.ibm.com/think/tutorials/prompt-engineering-with-dspy
**Downloaded:** 2026-02-20

## Overview

This IBM tutorial demonstrates how to build a retrieval-augmented generation (RAG) question-answering application using DSPy, a Python framework for optimizing large language model (LLM) applications through code-based prompt engineering rather than manual techniques.

## Key Concepts

**DSPy** enables developers to construct self-improving AI systems by automatically generating and testing prompts. As the tutorial notes, it "uses generative AI to generate natural language and then test the results to create the most effective prompts."

The framework supports various architectures including chain-of-thought reasoning, RAG implementations, and summarization tasks, with compatibility for both local models (Ollama, Hugging Face) and API-based services (OpenAI, watsonx).

## Implementation Architecture

The tutorial walks through a complete workflow using:
- **Language Model**: Meta's Llama 3 via IBM watsonx
- **Retrieval System**: ColBERT with Wikipedia 2017 abstracts
- **Dataset**: HotPotQA (multi-hop question answering benchmark)

## Core Implementation Steps

1. **Environment Setup**: Create watsonx.ai project and Jupyter Notebook
2. **Credentials Configuration**: Obtain Watson Machine Learning API key and project ID
3. **Library Installation**: Install DSPy and python-dotenv packages
4. **Model Configuration**: Configure LM instance pointing to watsonx endpoints
5. **Retrieval Integration**: Load ColBERT retrieval model
6. **Signature Definition**: Create input/output specifications for tasks
7. **RAG Module Development**: Build module combining retrieval and generation
8. **Dataset Preparation**: Split HotPotQA into training and evaluation sets
9. **Prompt Optimization**: Use BootstrapFewShot optimizer to compile and test prompts

## Example Scenario

The tutorial demonstrates improvement on a complex question: "What country was the winner of the Nobel Prize in Literature in 2006 from and what was their name?"

Without optimization, the model initially provided an inaccurate response. After DSPy compilation with the HotPotQA training dataset, it correctly returned "Turkey, Orhan Pamuk" with proper context retrieval.

## Learning Resources

The tutorial links to additional materials including the DSPy GitHub repository, watsonx Developer Hub, and IBM's prompt engineering fundamentals course for extended learning.
