# ReAct Prompting Tutorial Summary

**Source:** https://www.ibm.com/think/tutorials/react-prompting-classification-summarization-granite
**Downloaded:** 2026-02-20

## Overview

This IBM tutorial demonstrates building a financial analysis agent using the ReAct (Reasoning and Acting) framework combined with IBM's Granite 4.0 Nano language model. The approach integrates reasoning chains with external tool use to analyze financial news articles.

## Key Concepts

**ReAct Framework Components:**
- **Thought**: Model generates reasoning traces breaking down tasks
- **Action**: Model executes tool commands (like web lookups)
- **Observation**: External data retrieved after action execution

As stated in the tutorial, the framework "grounds the model in verified external data rather than internal training memory, improving transparency."

## Core Implementation Steps

1. **Install dependencies** (torch, transformers, accelerate)
2. **Load Granite 4.0 Nano model** from Hugging Face
3. **Define simulated financial news data** (5 case studies)
4. **Create tool function** (`web_browser()`) for retrieving article text
5. **Design ReAct prompt template** specifying thought→action→observation pattern
6. **Implement agent function** to execute model generation
7. **Test single URL** before batch processing
8. **Batch analysis** across all articles

## Output Structure

The agent classifies articles by:
- **Sentiment**: Positive/Negative/Mixed/Neutral
- **Topic**: Earnings, Regulatory, Operations, HR, Supply Chain, etc.
- **Summary**: 3-5 key takeaways with fact verification

## Key Advantage

The tutorial emphasizes that ReAct reduces hallucination "by grounding each decision in retrieved information rather than relying only on internal memory."

## Resources Provided

The tutorial links to watsonx.ai workshops, DSPy prompt optimization, and IBM Developer Hub materials for extending the implementation.
