# Use Role Prompting with Watsonx and Granite - Tutorial Summary

**Source:** https://www.ibm.com/think/tutorials/using-role-prompting-with-watsonx-and-granite
**Downloaded:** 2026-02-20

## Overview

This IBM tutorial demonstrates **role prompting**, a prompt engineering technique where AI models adopt specific personas to generate more tailored, contextually appropriate responses.

## Key Concepts

**What is Role Prompting?**

Role prompting instructs an LLM to assume a particular character or professional role, affecting the tone, style, and behavioral patterns of generated outputs. As the tutorial notes, "This technique can be used to guide the model's tone, style and behavior, which can lead to more engaging outputs."

**Why It Matters**

Foundation models like IBM's Granite series can leverage role assignments to produce more nuanced, business-appropriate responses. The technique proves particularly valuable for customer service applications, creative tasks, and multi-agent systems.

## Implementation Steps

### Prerequisites
- IBM Cloud account
- watsonx.ai project with API key and Project ID

### Setup Process

1. **Environment Configuration**: Access watsonx.ai Runtime via Jupyter Notebook
2. **Install Libraries**: Deploy langchain_ibm and ibm_watsonx_ai packages
3. **Model Selection**: Use Granite-3.1-8B-Instruct
4. **Parameter Configuration**: Set temperature, token limits, and penalty settings

### Code Example Structure

```python
# Model initialization with role-prompting parameters
model = WatsonxLLM(
    model_id="ibm/granite-3-8b-instruct",
    params={
        GenParams.MAX_NEW_TOKENS: 500,
        GenParams.TEMPERATURE: 0.7
    }
)

# Role assignment in prompt
prompt = "You are [specific role]. [Task description]"
response = model.generate([prompt])
```

## Practical Applications

**Customer Service Example**: When assigned the role of "compassionate, professional veterinarian," the model generated more empathetic, supportive responses compared to unguided outputs—demonstrating how personas improve user experience without sacrificing accuracy.

**Creative Tasks**: The tutorial demonstrates assigning historical figure personas to generate stylistically appropriate content.

## Key Takeaway

Role prompting bridges the gap between raw model capabilities and user-specific expectations by leveraging LLM adaptability to produce contextually relevant, professionally appropriate responses suitable for enterprise applications.
