# Skill Evaluation Patterns

Transferable patterns and anti-patterns for evaluating Claude Code skills.

---

## Pattern Index

- [Patterns](#patterns) - 7 reusable patterns with when/why/how
- [Anti-Patterns](#anti-patterns) - 5 documented pitfalls to avoid

---

## Patterns

### Pattern 1: Eval-First Workflow

**When to use**: Before building any new skill or modifying an existing one.

**How**:

1. Define success criteria using SMART framework (specific metric + threshold for each dimension)
2. Write 10-20 test cases covering all 4 trigger categories + 2-3 edge cases per relevant taxonomy category
3. Run against current behavior to establish baseline (for modifications: current performance; for new skills: Claude without the skill)
4. Build or modify the skill -- the eval constrains the solution space
5. Re-run evals and compare against baseline -- regressions in one dimension while improving another are immediately visible
6. Expand from production failures, not speculation

**Why it works**: Defining "done" before starting prevents scope creep and vibe-based assessment. The eval becomes the specification. Changes that improve one dimension while regressing another are caught immediately rather than discovered in production.

**Source**: Anthropic eval-driven development, OpenAI eval-first workflow

---

### Pattern 2: Four-Category Test Dataset

**When to use**: Building test datasets for any skill that can be activated automatically.

**How**:

1. **Explicit triggers** (~50-60%): Direct invocations ("run the deploy skill", "use /deploy")
2. **Implicit triggers** (~15-20%): Indirect invocations where intent implies the skill ("push this to production", "ship it")
3. **Contextual triggers** (~10-15%): Environment-dependent cases (user is in release branch, deploy.sh is open)
4. **Negative controls** (~25%): Cases where skill MUST NOT fire ("review the deployment config", "what's our deployment history?")

Format as JSONL with `request`, `should_activate`, and `category` fields.

**Why it works**: Testing only positive cases measures recall but not precision. False activations erode user trust faster than missed activations. The four categories provide balanced coverage of the activation surface.

**Source**: OpenAI four-category framework

---

### Pattern 3: Layered Grading

**When to use**: Any eval requiring both correctness checks and quality assessment.

**How**:

1. **Layer 1 -- Deterministic** (always run): Exact string matching, required substring presence, regex, JSON schema validation, file existence, command verification. Cost: essentially free.
2. **Layer 2 -- LLM-as-Judge** (only if Layer 1 passes): Style, clarity, tone, convention adherence via rubric with structured JSON output schema. Cost: $0.01-0.10 per case.
3. **Layer 3 -- Human** (only for calibration/disputes): 10-20 cases for LLM judge calibration. Cost: $5-50 per case.

**Why it works**: If a test case fails exact-match checks, spending $0.05 on LLM grading wastes money. If deterministic and LLM checks both pass, spending $20 on human review wastes money. Layering reserves expensive grading for cases that need nuanced judgment, maximising signal per dollar.

**Source**: Anthropic grading hierarchy, OpenAI layered grading pattern

---

### Pattern 4: Start Small, Expand from Failures

**When to use**: Beginning any new eval effort, especially when tempted to create comprehensive coverage upfront.

**How**:

1. **Initial**: 10-20 cases covering core positive scenarios, negative controls, and 1-2 edge cases per relevant category (1-2 hours investment)
2. **First production run**: Deploy, monitor, collect failures (skill activated wrongly or missed activation)
3. **Failure-driven expansion**: For each production failure, add the exact failure case + 2-3 variations (+3-5 cases per failure)
4. **Iterate**: Repeat steps 2-3 continuously; test suite grows organically from real-world failures

**Why it works**: Speculative test cases miss actual failure modes. Real failures reveal gaps in both skill design and eval coverage. 90% of hypothetical edges don't occur in production; 10% of actual failures aren't represented in hypothetical edges.

**Source**: OpenAI start-small guidance, Anthropic iterative refinement

---

### Pattern 5: Multidimensional Success Criteria

**When to use**: Defining production-readiness for any skill.

**How**:

Define thresholds across four dimensions:
1. **Task fidelity**: Accuracy, F1, task completion rate (e.g., F1 >= 0.85)
2. **Safety**: Toxicity rate, error severity distribution, dangerous command rate (e.g., 99.5% non-toxic, 90% of errors are inconvenience-level)
3. **Latency**: Response time percentiles (e.g., p95 < 2000ms)
4. **Cost**: Tokens per task, API cost per use (e.g., < 2000 tokens, < $0.10 per task)

Specify as structured YAML with `threshold`, `definition`, and `measured_on` for each metric.

**Why it works**: Single-dimension optimisation creates pathological edge cases. A skill that is 99% accurate but takes 30 seconds or costs $5 per use is not production-ready. Explicit multidimensional targets surface hidden tradeoffs immediately.

**Source**: Anthropic multidimensional criteria guidance

---

### Pattern 6: Edge Case Taxonomy Application

**When to use**: Ensuring test dataset completeness before production deployment.

**How**:

1. Review the 6 edge case categories (irrelevant input, excessive length, harmful/adversarial, ambiguous, sarcasm/mixed sentiment, multilingual/format)
2. Select categories relevant to the specific skill (not all apply -- sarcasm edges don't apply to deployment skills)
3. Add 2-3 test cases per relevant category
4. Run eval and observe which categories cause the most failures
5. Prioritise fixing the highest-failure categories

**Why it works**: Edge cases are predictable categories, not random surprises. Systematically covering the taxonomy catches 80%+ of real-world production failures that clean test cases miss. Without them, baseline accuracy might be 95% but edge case accuracy might be 60%.

**Source**: Anthropic edge case taxonomy

---

### Pattern 7: Observable Behavior Grounding

**When to use**: Evaluating any skill that directs Claude to take actions (not pure text generation).

**How**:

1. Define expected observable behaviors (tools to invoke, commands to suggest, files to check/modify, execution sequence, forbidden operations)
2. Write deterministic graders checking trace events: command presence, command sequence, file existence, forbidden operation absence
3. Grade behaviors first (deterministic checks on execution traces)
4. Grade text quality second (LLM-as-judge, only if behaviors pass)

**Why it works**: Skills are behavior directors, not text generators. Text can be eloquent while being wrong about process. A deployment skill producing beautiful prose while suggesting `git push --force` is failing. Grading the trace prevents the eval from degenerating into "does the output text look nice?"

**Source**: OpenAI execution trace emphasis, observable behavior paradigm

---

## Anti-Patterns

### Anti-Pattern 1: Vague Success Criteria

**What it looks like**: "The skill should work well", "good performance on typical tasks", "be helpful to users."

**Why it fails**: Unmeasurable, subjective, no stopping condition, no regression detection. Different team members interpret "works well" differently, leading to endless debate with no shared objective criteria.

**Better alternative**: Apply SMART framework to every criterion. Define specific metrics with thresholds: `task_completion_rate: 0.90`, `false_positive_rate: 0.05`, `response_latency_p95: 2000`. If you cannot measure it objectively, refine the definition until you can.

**Source**: Anthropic SMART criteria guidance

---

### Anti-Pattern 2: Unrepresentative Test Data

**What it looks like**: All test cases are perfectly formatted, grammatically correct, hand-crafted by developers. No typos, no ambiguity, no multilingual content. Only "happy path" scenarios.

**Why it fails**: Production distribution mismatch. Real users make typos ("deploi to prod"), use unfamiliar phrasing ("ship it to production"), write in other languages ("Deployer sur production"), and provide ambiguous input ("maybe we should consider deploying"). Evals pass in testing but fail in production.

**Better alternative**: Collect test data from production logs (anonymised), include examples from domain experts showing real phrasing variations, deliberately add edge cases from the taxonomy, and sample from historical failures.

**Source**: Anthropic representative data guidance, OpenAI production distribution emphasis

---

### Anti-Pattern 3: Skipping Negative Controls

**What it looks like**: Test dataset contains only cases where skill should activate. 100% positive triggers. No "skill should NOT activate" scenarios.

**Why it fails**: Only measures recall, not precision. A skill might have 100% recall (activates on every positive case) but 50% false positive rate (activates on half the negative cases too). Without negative controls, you ship a skill that constantly activates inappropriately. Users lose trust and disable it.

**Better alternative**: Include ~25% negative controls -- semantically related requests where the skill should stay silent. "Review the deployment config" is related to deploy but should NOT trigger deployment. Grade with precision and F1, not just recall. Test FAILS if skill activates on any negative control case.

**Source**: OpenAI four-category framework

---

### Anti-Pattern 4: Output-Only Evaluation

**What it looks like**: Grading only the final text output. Not checking which tools were invoked, which commands were suggested, which files were modified, or what execution sequence occurred.

**Why it fails**: A skill can produce correct final output through an incorrect process (lucky path), or use dangerous commands that happen to work. Text saying "Successfully deployed" while the actual commands include `rm -rf` and `--force` passes output-only evaluation but causes production incidents.

**Better alternative**: Define expected observable behaviors (tools, commands, files, sequence, forbidden operations). Grade behaviors first with deterministic checks on execution traces. Grade text quality second, only if behaviors pass. Behavior failures are gating -- text quality is secondary.

**Source**: OpenAI observable behavior paradigm

---

### Anti-Pattern 5: Uncalibrated LLM-as-Judge

**What it looks like**: Using LLM-based grading without validating against human judgments. Deploying LLM judge with default/generic rubrics. Never measuring human-LLM agreement rate. Not checking for systematic biases.

**Why it fails**: LLM judges have systematic biases: verbosity preference (scores long answers higher), position bias (favours first/last options), self-preference (grades own outputs higher). The 80%+ agreement rate means ~20% systematic disagreement. Without calibration, you optimise for the judge's preferences rather than actual quality. Bias compounds: judge prefers verbose -> skill learns to be verbose -> users get unnecessarily long responses.

**Better alternative**: Select 20-50 representative cases, have 2-3 humans grade with the same rubric, measure agreement, identify systematic disagreements (not random variation), adjust rubric to penalise identified biases, re-run targeting 90%+ agreement. Recalibrate quarterly or after major changes.

**Source**: Anthropic calibration guidance, OpenAI judge validation
