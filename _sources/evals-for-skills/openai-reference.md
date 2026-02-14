## TL;DR

Evals are structured tests that measure model and agent performance through a repeatable cycle: define expected behavior, run prompts through the system, and grade outputs against criteria. The most effective approach is **eval-driven development** — writing evals before building, much like test-driven development. For agent skills specifically, ground all evaluation in **observable behavior** (commands run, files created, tool calls made) captured via execution traces, not subjective impressions. Layer grading from cheap deterministic checks up to expensive LLM-as-judge rubrics. Start with 10–20 targeted test cases, expand coverage from real production failures, and match your eval strategy to your system's architecture tier (single-turn through multi-agent).

---

## Table of Contents

- [Core Concepts](#core-concepts) - Fundamental building blocks
- [Concept Map](#concept-map) - Relationships between concepts
- [Patterns](#patterns) - Reusable approaches
- [Anti-Patterns](#anti-patterns) - What to avoid
- [Practical Examples](#practical-examples) - Concrete demonstrations
- [Deep Dives](#deep-dives) - Complex topics explained
- [Quick Reference](#quick-reference) - Cheat sheet
- [Sources](#sources) - Bibliography

---

## Core Concepts

1. **Eval**: A structured test that measures model or agent performance. Consists of three parts: input data (prompts/contexts), a system under test (model + prompt template), and graders that score outputs. Evals make AI quality measurable and repeatable rather than subjective. [Sources 2, 3]

2. **Grader**: A scoring mechanism that evaluates model output against expected criteria. Three types exist: **deterministic** (exact string match, regex, code-based checks), **human** (expert reviewers rating outputs), and **LLM-as-judge** (a model scoring another model's output via rubric). Graders can be layered — run cheap deterministic checks first, then expensive model-based scoring. [Sources 1, 2, 3]

3. **Eval-Driven Development**: The practice of defining expected behavior through evals before building or modifying a system — analogous to test-driven development. Write the eval first, observe failure, build to pass, then expand coverage. This grounds development in measurable outcomes rather than intuition. [Source 3]

4. **Skill**: An agent capability defined in a `SKILL.md` file with YAML frontmatter (name, description) and implementation instructions. The name and description determine when the agent invokes the skill. Skills are the unit of agent behavior being evaluated. [Source 1]

5. **Test Dataset**: A collection of input cases (typically JSONL format, one JSON object per line) that exercise the system under test. Effective datasets include four categories: explicit triggers (clear invocations), implicit triggers (indirect invocations), contextual triggers (environment-dependent), and negative controls (cases where the skill should NOT activate). [Sources 1, 2]

6. **Execution Trace**: A structured event log (JSONL) produced by running an agent task, capturing commands executed, files created, tool calls made, token usage, and timing. Generated via `codex exec --json`. Traces make agent behavior observable and gradable — the eval infrastructure operates on traces, not on subjective impressions. [Source 1]

7. **LLM-as-Judge**: A specific grader type where a model (e.g., GPT-4.1 or o3) evaluates another model's output using a rubric and structured output schema. Achieves over 80% agreement with human preferences while scaling cost-effectively. Requires calibration against human judgments to be trustworthy. [Sources 1, 3]

8. **Architecture-Specific Evaluation**: The principle that eval strategy must match system complexity. Four tiers: **single-turn** (test instruction following), **workflow** (evaluate each chained step independently), **single-agent** (add tool selection and data precision checks), **multi-agent** (include agent handoff accuracy). Each tier inherits the evaluation needs of simpler tiers and adds new dimensions. [Source 3]

## Concept Map

- Eval → composed of → Test Dataset + System Under Test + Grader
- Grader → scores → Model Output (deterministic, human, or LLM-as-judge)
- Eval-Driven Development → requires → Evals defined before implementation
- Eval-Driven Development → analogous to → Test-Driven Development
- Skill → defines → Agent capability (name, description, instructions)
- Skill → evaluated by → Eval (via execution traces)
- Test Dataset → feeds → Eval (as JSONL input)
- Test Dataset → should include → Negative Controls (false-positive detection)
- Execution Trace → captures → Observable Behavior (commands, files, tool calls)
- Execution Trace → consumed by → Grader (deterministic or LLM-based)
- LLM-as-Judge → requires → Structured Output Schema (consistent scoring)
- LLM-as-Judge → calibrated by → Human Evaluation (ground truth)
- Architecture-Specific Evaluation → determines → Which graders and metrics to apply
- Deterministic Grader → runs before → LLM-as-Judge (layered grading)
- Single-turn Eval → subset of → Workflow Eval → subset of → Agent Eval → subset of → Multi-Agent Eval

## Patterns

### Pattern 1: Layered Grading

**When to use:** Any eval where you need both correctness checks and quality assessment.

**How:**

1. Run deterministic graders first (exact match, regex, file existence, command verification)
2. Only if deterministic checks pass, run LLM-as-judge with a rubric
3. Use `--output-schema` to enforce structured JSON responses from the judge

**Why it works:** Deterministic checks are fast, cheap, and unambiguous. They catch hard failures immediately. LLM grading is expensive and variable — reserving it for qualitative assessment (style, conventions, approach quality) maximizes signal per dollar. [Sources 1, 2]

### Pattern 2: Start Small, Expand from Failures

**When to use:** Beginning any new eval effort.

**How:**

1. Create 10–20 test cases covering core scenarios
2. Include both positive triggers and negative controls
3. Run evals and analyze failures
4. Add new test cases derived from real failures, not hypothetical edge cases
5. Repeat — let production failures drive coverage expansion

**Why it works:** Speculative test cases often miss the failures that actually occur. Real failures reveal gaps in both the skill and the eval. This mirrors how mature software testing evolves. [Sources 1, 3]

### Pattern 3: Four-Category Test Dataset Design

**When to use:** Building test datasets for agent skill evaluation.

**How:**

1. **Explicit triggers** — Direct invocations ("run the deploy skill")
2. **Implicit triggers** — Indirect invocations ("push this to production")
3. **Contextual triggers** — Environment-dependent ("we're in the release branch")
4. **Negative controls** — Cases where the skill should NOT fire ("just review the code")

**Why it works:** Skills activate based on name and description matching. Testing only positive cases misses false-positive activations, which erode user trust. Negative controls catch over-triggering. [Source 1]

### Pattern 4: Observable Behavior Grounding

**When to use:** Evaluating agent task execution (not just text generation).

**How:**

1. Run the agent with `codex exec --json` to produce JSONL traces
2. Write graders that check trace events: commands run, files created, tool calls made
3. Verify step sequencing (did X happen before Y?)
4. Check token usage and command counts for efficiency

**Why it works:** Agent quality depends on what the agent _did_, not just what it _said_. Execution traces make behavior concrete and auditable. Grading traces prevents the eval from degenerating into "does the output text look nice." [Source 1]

### Pattern 5: Eval-First Workflow

**When to use:** Before building or modifying any agent skill.

**How:**

1. Define success categories (outcome, process, style, efficiency)
2. Write eval cases that encode those expectations
3. Run against current behavior — observe baseline
4. Build or modify the skill
5. Re-run evals — measure improvement
6. Continuously evaluate as the skill evolves

**Why it works:** Defining "done" before starting prevents scope creep and vibe-based assessment. The eval becomes the specification. [Sources 1, 3]

### Pattern 6: Architecture-Tier Matching

**When to use:** Choosing what to evaluate in a system.

**How:**

1. **Single-turn:** Evaluate instruction following and functional correctness
2. **Workflow:** Evaluate each chained step independently, plus end-to-end
3. **Single-agent:** Add tool selection accuracy and data precision
4. **Multi-agent:** Add handoff accuracy and coordination checks

**Why it works:** Under-evaluating misses failure modes; over-evaluating wastes resources. Each tier inherits lower-tier checks and adds tier-specific dimensions. [Source 3]

### Pattern 7: Structured Judge Output

**When to use:** Using LLM-as-judge grading for qualitative assessment.

**How:**

1. Define a JSON schema for the judge's response (e.g., `{ "score": 1-5, "reasoning": "...", "issues": [...] }`)
2. Use `--output-schema` to enforce the schema
3. Parse structured output programmatically for aggregation
4. Calibrate against human judgments on a sample

**Why it works:** Free-text judge responses are inconsistent and hard to aggregate. Structured output forces the judge to commit to specific scores and enumerated issues, making results comparable across runs. [Sources 1, 2]

## Anti-Patterns

### Anti-Pattern 1: Vibe-Based Evaluation

**Problem:** Assessing model/agent quality by subjective feel — "it seems better" or "the output looks good."

**Why it's problematic:** Subjective impressions are inconsistent, non-reproducible, and susceptible to anchoring bias. Teams cannot track improvement over time or detect regressions without quantifiable metrics. Different team members will disagree on what "good" means.

**Better alternative:** Define specific success criteria and encode them as graders. Even simple deterministic checks (does the output contain X? did the agent run command Y?) are more valuable than expert intuition. [Sources 1, 3]

### Anti-Pattern 2: Academic Benchmark Reliance

**Problem:** Using standard benchmarks (MMLU, perplexity, BLEU) as the primary evaluation for production applications.

**Why it's problematic:** Academic benchmarks measure general model capability, not task-specific performance. A model can score well on MMLU but fail at your specific skill's requirements. Benchmark scores don't predict production behavior.

**Better alternative:** Build custom evals that reflect your actual use cases, using production data distributions and task-specific graders. Use benchmarks only as a coarse filter for model selection. [Source 3]

### Anti-Pattern 3: Unrepresentative Test Data

**Problem:** Test datasets that don't match production traffic — too clean, too uniform, or missing common edge cases.

**Why it's problematic:** Evals pass in testing but fail in production. The eval gives false confidence because it tests a different distribution than reality.

**Better alternative:** Collect test data from production logs, domain experts, and historical failures. Include multilingual inputs, format variations, ambiguous cases, and adversarial inputs that reflect real usage. [Source 3]

### Anti-Pattern 4: Skipping Human Calibration

**Problem:** Deploying LLM-as-judge grading without validating against human judgments.

**Why it's problematic:** LLM judges have systematic biases (verbosity preference, position bias, self-preference). Without human calibration, you're optimizing for the judge's preferences, not actual quality. The over-80% agreement rate means ~20% of judgments diverge from humans.

**Better alternative:** Run human evaluation on a sample, measure agreement with the LLM judge, identify systematic disagreements, and adjust rubrics accordingly. Re-calibrate periodically. [Source 3]

### Anti-Pattern 5: Output-Only Evaluation

**Problem:** Evaluating only the agent's final output without checking the process — which tools were called, what commands ran, what intermediate steps occurred.

**Why it's problematic:** An agent can produce a correct final output through an incorrect process (lucky path), or use dangerous commands that happen to work. Process failures become production incidents even when outputs look correct.

**Better alternative:** Grade execution traces, not just final outputs. Verify tool selection, command sequencing, and intermediate state. Use deterministic graders on trace events before assessing output quality. [Source 1]

## Practical Examples

**Example from Source 1: Deterministic Trace Grading**

After running `codex exec --json`, the JSONL trace contains events like:

- `item.started` — agent begins a step
- `item.completed` — step finishes with command execution details
- `turn.completed` — turn ends with token usage counts

A deterministic grader checks: did the trace contain an `item.completed` event where the command matches `npm test`? Did a file creation event show `output.json` was written? This grounds the eval in what happened, not what was reported.

_Why this matters:_ Execution traces transform agent evaluation from "did it say the right thing" to "did it do the right thing." This is the fundamental shift from text evaluation to behavior evaluation.

**Example from Source 2: Eval API Configuration**

Creating an eval via the API:

1. POST to `/v1/evals` with `data_source_config` specifying JSON Schema for test data (e.g., `ticket_text` and `correct_label` properties)
2. Define testing criteria using graders — e.g., `string_check` type comparing `{{ sample.output_text }}` against `{{ item.correct_label }}`
3. Upload JSONL test data matching the schema
4. Create a run via `/v1/evals/{eval_id}/runs` with a templated prompt referencing `{{ item.ticket_text }}`

_Why this matters:_ The template syntax (`{{ item.* }}` for test data, `{{ sample.* }}` for model output) is the core mechanism connecting test cases to graders. Understanding this wiring is essential for building evals.

**Example from Source 1: Negative Control Test Cases**

A test dataset for a "deploy" skill includes:

- Positive: "Deploy the app to staging" (should trigger)
- Positive: "Push the latest build to production" (implicit trigger)
- **Negative:** "Review the deployment configuration" (should NOT trigger deploy)
- **Negative:** "What's our deployment history?" (informational, not actionable)

_Why this matters:_ Without negative controls, you only know the skill triggers when it should — not whether it stays silent when it shouldn't. False activations degrade trust faster than missed activations.

**Example from Source 3: Architecture-Tier Evaluation Matrix**

| Tier         | What to Evaluate                   | Example Metrics                               |
| ------------ | ---------------------------------- | --------------------------------------------- |
| Single-turn  | Instruction following, correctness | Exact match, ROUGE-L                          |
| Workflow     | Per-step correctness, end-to-end   | Step pass rate, pipeline completion           |
| Single-agent | Tool selection, data precision     | Tool accuracy, hallucination rate             |
| Multi-agent  | Handoff accuracy, coordination     | Routing precision, circular handoff detection |

_Why this matters:_ Applying single-turn evals to an agent system misses critical failure modes (wrong tool, bad handoff). Applying multi-agent evals to a single-turn system wastes effort. Match the eval to the architecture.

**Example from Source 2: Monitoring Eval Runs**

Subscribe to webhook events for async monitoring:

- `eval.run.succeeded` — run completed successfully
- `eval.run.failed` — run encountered errors
- `eval.run.canceled` — run was canceled

Results include `result_counts` (total, errored, failed, passed) and `per_testing_criteria_results` breaking down pass rates by grader. A `report_url` links to the dashboard.

_Why this matters:_ Production eval pipelines run asynchronously. Webhook integration enables CI/CD-style eval workflows where skill changes trigger eval runs and block deployment on regressions.

## Deep Dives

### The Eval-Driven Development Lifecycle

Eval-driven development (EDD) mirrors test-driven development but adapted for nondeterministic systems. The key difference: traditional TDD tests have binary pass/fail on deterministic code, while EDD tests have scored outcomes on probabilistic systems.

The lifecycle:

1. **Specify** — Define success categories before touching the skill. Source 1 identifies four categories: outcome goals (did the task complete?), process goals (were the right tools used?), style goals (does output match conventions?), and efficiency goals (minimal unnecessary steps). This categorization prevents the common failure of evaluating only outcomes while ignoring process.

2. **Encode** — Translate success categories into graders. Deterministic graders handle outcome and process goals (file exists, command ran, step order correct). LLM-as-judge handles style and nuanced quality assessment. The grader choice is driven by what's being measured, not convenience.

3. **Baseline** — Run evals against the current system state. This establishes the starting point and often reveals that the current system is worse than assumed — which is itself valuable information.

4. **Build** — Implement or modify the skill. The eval constrains the solution space: any implementation that passes is acceptable, any that fails isn't.

5. **Verify** — Re-run evals. Compare against baseline. Regressions in one area while improving another are immediately visible.

6. **Expand** — Add test cases from production failures, not from speculation. The eval grows organically to cover real-world edge cases.

This cycle is continuous. Source 3 emphasizes that evals are not a one-time gate but an ongoing practice — "continuously evaluate" is the fifth step in the workflow for a reason.

### Grader Selection and Layering

The three grader types form a hierarchy of cost, speed, and nuance:

**Deterministic graders** (cheapest, fastest, least nuanced): String matching (`string_check`), regex, code-based assertions. Use for binary facts: did this command run? Does the output contain this string? Is the JSON valid? These catch hard failures instantly. Source 2's template syntax (`{{ item.correct_label }}` eq `{{ sample.output_text }}`) enables parameterized deterministic checks across test cases.

**LLM-as-judge** (moderate cost, moderate speed, high nuance): A model evaluates another model's output against a rubric. Source 1 recommends enforcing structured JSON output via `--output-schema` so scores are parseable and comparable. Source 3 reports over 80% agreement with human judges — good enough for scaling but not for final authority.

**Human evaluation** (most expensive, slowest, highest nuance): Source 3 recommends multiple review rounds with consensus voting. Essential for calibrating LLM judges and for high-stakes evaluations where the ~20% disagreement rate of LLM judges is unacceptable.

The layering pattern: run all deterministic checks first. If a test case fails a deterministic check, don't waste money on LLM grading. Only escalate to LLM-as-judge for cases that pass deterministic filters but need qualitative assessment. Reserve human evaluation for calibration samples and disputed cases.

### Execution Traces as the Foundation of Agent Evals

Source 1 introduces a critical insight: for agents, the unit of evaluation is the **execution trace**, not the text output. Running `codex exec --json` produces a JSONL stream of events:

- `item.started` / `item.completed` — individual step lifecycle with command details
- `turn.completed` — full turn summary with token usage

This transforms agent evaluation. Instead of asking "did the agent produce good text?", you ask:
iew rounds with consensus voting. Essential for calibrating LLM judges and for high-stakes evaluations where the ~20% disagreement rate of LLM judges is unacceptable.

The layering pattern: run all deterministic checks first. If a test case fails a deterministic check, don't waste money on LLM grading. Only escalate to LLM-as-judge for cases that pass deterministic filters but need qualitative assessment. Reserve human evaluation for calibration samples and disputed cases.

### Execution Traces as the Foundation of Agent Evals

Source 1 introduces a critical insight: for agents, the unit of evaluation is the **execution trace**, not the text output. Running `codex exec --json` produces a JSONL stream of events:

- `item.started` / `item.completed` — individual step lifecycle with command details
- `turn.completed` — full turn summary with token usage

This transforms agent evaluation. Instead of asking "did the agent produce good text?", you ask:

- Did the agent run the correct commands? (deterministic check on trace)
- Did it run them in the right order? (sequence check on trace)
- Did it create the expected files? (existence check on trace)
- Did it use a reasonable number of tokens? (efficiency check on trace)
- Was the overall approach sound? (LLM-as-judge on trace)

The trace is the observable record of agent behavior. Without it, you're evaluating the agent's self-report of what it did — which is unreliable for the same reasons that testing a function by asking it "did you work correctly?" is unreliable.

## Quick Reference

**Create an eval:** POST to `/v1/evals` with `data_source_config` (JSON Schema) and testing criteria (graders)
**Upload test data:** JSONL file, one JSON object per line, matching your schema
**Run an eval:** POST to `/v1/evals/{eval_id}/runs` with templated prompt and model config
**Reference test data in templates:** `{{ item.field_name }}`
**Reference model output in graders:** `{{ sample.output_text }}`
**Capture agent traces:** `codex exec --json` produces JSONL event stream
**Enforce judge output format:** `--output-schema` with JSON schema
**Monitor async runs:** Subscribe to `eval.run.succeeded` / `eval.run.failed` webhooks
**Target test dataset size:** Start with 10–20 cases, expand from real failures
**Include negative controls:** ~25% of test cases should be "don't trigger" scenarios
**Layer grading order:** Deterministic first → LLM-as-judge second → Human for calibration
**Success categories for skills:** Outcome, process, style, efficiency
**Match eval to architecture:** Single-turn → workflow → agent → multi-agent
**Grader types available:** `string_check` (deterministic), LLM-as-judge (rubric-based), human (expert review)
**Trace events to check:** `item.started`, `item.completed`, `turn.completed`
**Result fields:** `result_counts` (total/errored/failed/passed), `per_testing_criteria_results`
**Dashboard access:** `report_url` field in completed run response
**Human-LLM agreement rate:** Over 80% — calibrate the remaining ~20% manually
**Eval-driven development cycle:** Specify → Encode → Baseline → Build → Verify → Expand
**Edge cases to cover:** Multilingual input, format variation, ambiguous intent, adversarial input

## Sources

1. **Testing Agent Skills Systematically with Evals** — <https://developers.openai.com/blog/eval-skills/>
   - Practical 8-step framework for evaluating Codex agent skills. Introduces execution traces, JSONL grading, skill structure, four-category test datasets, and layered grading. The most concrete and agent-specific source.

2. **Evals API Guide** — <https://developers.openai.com/api/docs/guides/evals>
   - API mechanics for the OpenAI Evals system. Covers data source configuration, JSON Schema, grader types, template syntax (`{{ item.* }}` / `{{ sample.* }}`), JSONL upload, run lifecycle, result analysis, and webhook monitoring.

3. **Evaluation Best Practices** — <https://developers.openai.com/api/docs/guides/evaluation-best-practices>
   - Strategic framework for AI evaluation. Covers eval-driven development, five-step workflow, architecture-specific evaluation tiers, evaluator type comparison (metric/human/LLM-as-judge), edge case taxonomy, and anti-patterns to avoid.
