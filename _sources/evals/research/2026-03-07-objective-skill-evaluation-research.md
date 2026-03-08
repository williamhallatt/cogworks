# Objective Evaluation Of Agent Skills

Date: 2026-03-07

## Thesis

The cleanest way to compare two agent skills is to treat a skill as an intervention on a fixed agent system. Hold the model, agent surface, tools, sandbox, and task constant; run the same task set with `skill_a` and `skill_b`; then compare observable outcomes, observable process quality, and efficiency. Anything that changes outside the skill turns the result into a system benchmark rather than a skill benchmark.

## What The Local Corpus Already Got Right

The local materials in [`_sources/evals`](../), [`tests/framework/QUALITY-SCHEMA.md`](../../../tests/framework/QUALITY-SCHEMA.md), and [`tests/framework/HARNESS-SPEC.md`](../../../tests/framework/HARNESS-SPEC.md) already establish four strong foundations:

1. Evaluation must be task-specific rather than benchmark-theater.
2. Observable behavior matters more than polished final prose.
3. Same-model self-grading is circular and should not be trusted.
4. Layered grading is better than a single expensive subjective judge.

Those foundations survive this research pass. The main changes are sharper attribution control, stronger emphasis on executable outcomes, and stricter separation of activation from efficacy.

## Findings From External Sources

### 1. Success criteria must be explicit and multidimensional

OpenAI and Anthropic both make the same core point: evaluation should start by defining measurable success criteria tied to the real task distribution, not by selecting a model and asking whether the outputs "feel better." In practice, skill comparisons need at least these dimensions:

- task outcome correctness
- process compliance
- safety/compliance violations
- efficiency and cost
- activation quality

Sources:
- OpenAI, Evaluation best practices: <https://platform.openai.com/docs/guides/evaluation-best-practices>
- Anthropic, Define your success criteria: <https://docs.anthropic.com/en/docs/test-and-evaluate/define-success>

### 2. Objective agent evaluation is strongest when the task has an executable or state-based oracle

The strongest agent benchmarks avoid free-form judgment as the primary truth source. SWE-bench uses repository-level issues with execution-based verification; WebArena-Verified emphasizes deterministic evaluators over LLM judging; AgentBench evaluates success in concrete environments rather than relying only on text quality. For skill evaluation, this implies the benchmark should prefer:

- command traces
- tool-call trajectories
- file/state diffs
- structured outputs
- executable checks

Sources:
- SWE-bench: <https://github.com/SWE-bench/SWE-bench>
- AgentBench: <https://github.com/THUDM/AgentBench>
- WebArena-Verified: <https://github.com/ServiceNow/webarena-verified>

### 3. Pairwise comparison is more reliable than open-ended scoring

OpenAI explicitly notes that models are stronger discriminators than open-ended graders. LLM-as-judge work from LMSYS reached similar conclusions, while also documenting position, verbosity, and self-enhancement bias. For skill-vs-skill work, the default comparison should therefore be:

- same case
- same environment
- two candidate skills
- paired winner or delta

not independent free-form grading with a later human interpretation layer.

Sources:
- OpenAI, Evaluation best practices: <https://platform.openai.com/docs/guides/evaluation-best-practices>
- Zheng et al., Judging LLM-as-a-Judge with MT-Bench and Chatbot Arena: <https://arxiv.org/abs/2306.05685>

### 4. Activation and efficacy are different failure modes and should not be collapsed

A skill can be well-written but hard to trigger, or easy to trigger but harmful once invoked. Mixing those into one scalar obscures what actually needs to be improved. The benchmark should therefore produce:

- a primary **efficacy scorecard** for tasks where the skill is in play
- a separate **activation scorecard** for false positives, false negatives, and ambiguous triggers

This separation is especially important for instruction artifacts such as `SKILL.md`, where both discovery and task execution matter but are driven by different mechanisms.

Inference from sources:
- This separation is not stated verbatim by a single source. It is a design inference from architecture-specific eval guidance, agent benchmark patterns, and the local repo's existing distinction between activation tests and quality tests.

### 5. Repeated trials are required because agent runs are noisy

HELM and later benchmark work emphasize standardization and variance control. Skill evaluation should not treat a single run as evidence. The benchmark should run each case multiple times per skill, then report:

- mean paired delta
- win rate
- 95% confidence interval
- category breakdown

Sources:
- HELM overview: <https://crfm.stanford.edu/2022/11/17/helm.html>
- HELM Instruct: <https://crfm.stanford.edu/2024/02/18/helm-instruct.html>

### 6. LLM judges are useful only after deterministic checks and calibration

OpenAI, Anthropic, and LMSYS all point to the same operating rule: use deterministic grading first, then use LLM judges only where code cannot resolve the question. When judges are used, they need:

- a structured output schema
- explicit rubrics
- pairwise or criterion-based evaluation
- calibration against human labels
- protection against same-family circularity

Sources:
- OpenAI, Graders: <https://platform.openai.com/docs/guides/graders/>
- Anthropic, Create strong empirical evaluations: <https://docs.anthropic.com/en/docs/test-and-evaluate/develop-tests>
- Zheng et al., Judging LLM-as-a-Judge with MT-Bench and Chatbot Arena: <https://arxiv.org/abs/2306.05685>

## Implications For Skill Benchmarks

### What To benchmark

The benchmark unit should be a **paired skill intervention**:

- fixed model
- fixed agent surface
- fixed tool set
- fixed sandbox/environment
- same task case
- `skill_a` vs `skill_b`

This keeps attribution honest.

### What Not To Benchmark In The Primary Score

Do not fold these into the primary skill score:

- changing the model
- changing the agent runtime
- changing the tool inventory
- changing the environment difficulty
- broad stylistic preference with no task impact

Those are valid experiments, but they are not skill-isolated comparisons.

### Minimum dataset shape

Each benchmark set should include:

- `invoked-task` cases where the skill is clearly or strongly relevant
- `hard-negative` cases where the skill should not activate or help
- `boundary` cases with ambiguity, conflicting context, or adversarial phrasing

The case mix matters as much as the grader quality. A benchmark made only of friendly positive cases will overstate both activation quality and real-world efficacy.

### Scorecard structure

The benchmark should report at least:

- `task_success_rate`
- `deterministic_process_score`
- `safety_violation_rate`
- `mean_runtime_ms`
- `mean_token_cost`
- `mean_paired_delta`
- `win_rate`
- `activation_precision`
- `activation_recall`
- `activation_false_positive_rate`

No single scalar should erase the tradeoff profile.

## Recommended Default Policy

1. Primary benchmark is fixed-model, fixed-agent, fixed-environment, skill-vs-skill.
2. Primary score is efficacy after invocation.
3. Activation is reported separately and can gate release, but does not contaminate the primary efficacy delta.
4. Deterministic trace/state grading runs before any LLM judge.
5. Same-family generator/judge pairings are disallowed.
6. Every benchmark result must include uncertainty, not just a point estimate.
7. Portability across models or agents is a separate benchmark track.

## Anti-Patterns

- Vibe-based comparison between two skills after one run each.
- Allowing model, environment, and skill to vary simultaneously.
- Using the same model family as both generator and judge.
- Treating a judge's prose as evidence without a structured schema.
- Benchmarking only positive-trigger cases.
- Using efficiency as a tie-breaker only after ignoring correctness.
- Publishing a single scalar with no category breakdown or confidence interval.

## What This Research Package Delivers

The benchmark package under [`evals/skill-benchmark`](../skill-benchmark) encodes these decisions as a reusable spec:

- benchmark doctrine
- run procedure
- case schema
- normalized observation schema
- judge output schema
- benchmark summary schema
- starter examples

That package is intended to be the implementation target for a future harness rather than a narrative-only memo.
