# Prompt Tune a Granite Model in Python Using watsonx

**Source:** https://www.ibm.com/think/tutorials/prompt-tune-a-granite-model-using-watsonx
**Downloaded:** 2026-02-20

## Overview

This tutorial demonstrates how to implement prompt tuning on IBM Granite models using watsonx.ai. As described in the source material, prompt tuning is "an efficient, low-cost way of adapting an artificial intelligence (AI) foundation model to new downstream tasks without retraining the entire model."

## Key Concepts

**Prompt Tuning vs. Related Approaches:**

The tutorial contrasts prompt tuning with other optimization methods:

- **Prompt Engineering**: Optimizes responses through well-designed prompts without introducing new data or modifying the model
- **Fine-tuning**: Adjusts model weights using labeled datasets, requiring substantial computational resources
- **Prompt Tuning**: Adjusts soft prompt parameters (AI-generated numerical vectors) rather than model weights, making it parameter-efficient
- **Prefix-tuning**: Similar to prompt tuning but includes task-specific vectors injected into deep learning layers

**Soft vs. Hard Prompts:**

Hard prompts are user-written natural language instructions. Soft prompts are "not written in natural language. Instead, prompts are initialized as AI-generated, numerical vectors appended to the start of each input."

## Implementation Steps

### 1. Environment Setup
- Create an IBM Cloud account and watsonx.ai project
- Generate an API key and obtain your project ID
- Set up a Jupyter Notebook in watsonx.ai

### 2. Install Required Libraries
Install ibm-watsonx-ai, pandas, wget, scikit-learn, and matplotlib packages

### 3. Configure Credentials
Set up API client with credentials and project ID

### 4. Load Training Data
The tutorial uses a synthetic dataset of dog grooming business reviews

### 5. Configure Tuning Experiment
Set up prompt tuner with task configuration, base model selection, hyperparameters, and initialization text

### 6. Run Tuning
Execute the tuning process with training data references

### 7. Evaluate Results
Check tuning status, review summary, and plot learning curves

### 8. Deploy Tuned Model
Create deployment configuration and deploy the tuned model

### 9. Test Performance
Compare tuned model against base Granite model on test dataset

## Results

The tutorial reports that the tuned model achieved approximately 98.3% accuracy compared to the base model's 93.1% accuracy—roughly a 5% improvement on the customer satisfaction classification task.

## Key Takeaways

Prompt tuning provides an efficient alternative to full model fine-tuning while maintaining competitive performance. This approach is particularly useful when working with limited computational resources or datasets.
