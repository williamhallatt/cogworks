# Creating Agent Skills: Decision-First Reference

## TL;DR

A skill is a compact operational product, not a polished prompt. It must supply
expertise the agent lacks, activate for the right requests, beat a baseline,
and package repeated mechanics reliably. Build from real work, keep the core
lean, disclose conditional detail on demand, and match prescription to task
fragility. Test activation separately from output quality: descriptions need
positive and near-miss queries; behavior needs realistic tasks, assertions,
comparative runs, and human review. Bundle scripts only for repeated or fragile
work, and design them for non-interactive, retry-prone, output-limited agent
environments. [S1] [S2] [S3] [S4]

## Decision Rules

### 1. Require a demonstrated knowledge advantage

**When:** Starting a skill or deciding whether a proposed instruction belongs.

**Do:** Ground it in a successfully completed task, corrections, project
artifacts, incident history, schemas, or other domain evidence. Keep content
only when the unassisted agent is likely to miss or mishandle it.

**Because:** Generic model knowledge produces generic guidance; a skill creates
value by supplying specific procedures, constraints, conventions, and failure
modes that are absent from the base context.

**Boundary:** Common concepts and tasks the agent already handles correctly do
not justify a skill. Test uncertain material against a no-skill baseline. [S1]
[S2]

### 2. Scope one coherent unit, then disclose detail on demand

**When:** The skill spans several activities or approaches the context budget.

**Do:** Keep the coherent, always-needed workflow and non-obvious early gotchas
in `SKILL.md`. Move conditional references, long templates, and detailed
material into support files, with an explicit trigger for loading each file.

**Because:** Very narrow skills create coordination overhead; broad skills
activate imprecisely. Unconditional detail competes with the task and other
skills for agent attention.

**Boundary:** A gotcha must remain in the core when the agent cannot recognize
the condition that would tell it to load the reference. The guidance recommends
`SKILL.md` stay below 500 lines and 5,000 tokens, but coherence and demonstrated
need—not a line quota—decide the final split. [S1]

### 3. Match control to fragility

**When:** Writing each workflow step or choosing among multiple valid methods.

**Do:** Prescribe exact sequences and commands for fragile, stateful, or
consistency-sensitive operations. For tolerant work, state the goal, relevant
checks, and rationale; choose one default and give alternatives only as bounded
escape hatches.

**Because:** Rigid instructions reduce failure in brittle operations, while
rationale lets the agent adapt safely where several approaches can succeed.
Defaults avoid wasted search and arbitrary choice.

**Boundary:** Calibrate each part independently; a single skill may contain both
flexible judgment and exact procedures. [S1]

### 4. Encode reusable procedures, not instance answers

**When:** Converting a successful task into a reusable skill.

**Do:** Extract the decision sequence, input and output shapes, corrections,
constraints, and validation steps. Use short templates for exact output shapes,
checklists for dependency-heavy workflows, and plan-validate-execute for batch
or destructive changes.

**Because:** Procedures transfer to new inputs; instance-specific answers do
not. Concrete structures are easier for agents to follow and validate than
prose-only declarations.

**Boundary:** Specific API details, project conventions, output schemas, and
safety constraints belong when they are stable requirements rather than facts
of one example. [S1]

### 5. Engineer activation as a separate interface

**When:** Writing or revising the frontmatter `description`.

**Do:** Use concise imperative language that describes user intent and the
contexts in which the skill should be used. Cover implicit phrasings while
stating boundaries from adjacent tasks, and keep the description within 1,024
characters.

**Because:** Agents initially see only the name and description, so this field
must route relevant tasks without loading the entire skill on near-misses.

**Boundary:** Be assertive about genuine scope, not keyword-broad. A simple task
the agent can already perform may not activate a skill even when the wording
matches. [S3]

### 6. Test routing with held-out near-misses

**When:** The description is ready for systematic optimization.

**Do:** Begin with roughly 20 realistic queries: 8–10 positives and 8–10
negatives, especially adjacent near-misses. Vary phrasing, explicitness, detail,
and complexity. Split about 60% for training and 40% for validation; run each
query multiple times (three is a practical start), measure trigger rate, revise
from training failures only, and choose the iteration with the best validation
result.

**Because:** Repeated runs expose nondeterminism, near-misses test precision,
and a held-out set detects descriptions that merely memorize test wording.

**Boundary:** A 0.5 trigger-rate threshold and five optimization iterations are
starting heuristics, not platform guarantees. Finish with fresh, previously
unseen queries. [S3]

### 7. Evaluate behavior comparatively and in clean contexts

**When:** A draft appears to work on an example.

**Do:** Start with 2–3 realistic cases containing a prompt, human-readable
expected outcome, and optional input files; include a boundary case. Run every
case in a clean context both with the skill and against no skill—or against a
snapshot of the previous version. Preserve outputs, timing, token usage, and
execution traces by iteration.

**Because:** A pleasant single result does not establish reliability or
incremental value. Controlled baselines reveal what the skill buys and what it
costs.

**Boundary:** Early small samples support diagnosis, not strong statistical
claims; standard deviation becomes meaningful only with repeated runs. [S2]

### 8. Derive assertions from observed outputs, then grade with evidence

**When:** The first evaluation runs have produced concrete artifacts.

**Do:** Add specific, observable assertions; use deterministic checks for
mechanical properties and evidence-backed judgment for semantic properties.
Record PASS or FAIL with output evidence. Complement assertion grades with
blind comparison where useful and human review with actionable feedback.

**Because:** Before seeing outputs, authors often encode the wrong proxy for
quality. Mechanical scripts are more reliable for objective checks, while
humans catch unanticipated or holistic defects.

**Boundary:** Do not force subjective qualities into brittle exact-string
checks. An assertion that always passes both configurations, always fails both,
or cannot be verified should be revised or removed. [S2]

### 9. Revise from failures, feedback, and traces together

**When:** An evaluation iteration is graded and reviewed.

**Do:** Generalize from failed assertions, specific human feedback, and the
agent's execution path. Clarify ambiguous steps, remove instructions that cause
waste, explain rationale, and bundle mechanics repeatedly reimplemented by the
agent. Rerun the full suite in a new iteration.

**Because:** Outputs show what failed, while traces show why. Narrow patches can
overfit examples; causal revisions improve the whole task class.

**Boundary:** Stop when results and review are satisfactory or improvements are
no longer meaningful. More rules can make an over-constrained skill worse. [S1]
[S2]

### 10. Choose commands or scripts by complexity and repetition

**When:** A workflow needs executable tooling.

**Do:** Reference a pinned one-off package command when an existing tool needs
only a few stable flags. Bundle a tested script when logic is repeated, fragile,
or difficult to reproduce. Reference bundled files relative to the skill root
and declare runtime prerequisites or inline dependencies.

**Because:** One-off runners minimize maintenance; bundled scripts turn repeated
reasoning into a consistent, testable capability.

**Boundary:** Select a runner available in the target environment. A script's
command remains relative to the skill root even when invoked from a support
document. [S1] [S4]

### 11. Design scripts as agent-facing APIs

**When:** Adding or reviewing a bundled script.

**Do:** Accept flags, environment variables, or stdin; provide concise `--help`,
actionable errors, meaningful exit codes, safe defaults, and idempotent behavior.
Emit structured data on stdout and diagnostics on stderr. Add `--dry-run` or an
explicit confirmation flag for risky work, and paginate, summarize, or require
an output file when results can be large.

**Because:** Agents consume script interfaces through tool output, may retry,
cannot answer interactive prompts, and can lose critical data to output
truncation.

**Boundary:** Confirmation flags must be supplied at invocation time; an
interactive confirmation menu is still unsafe because it can hang. Reject
ambiguous inputs rather than guessing. [S4]

## Quality Gates

1. **Value:** Domain evidence identifies missing knowledge, and a baseline shows
   material improvement. [S1] [S2]
2. **Scope:** The core is coherent; support files have load triggers; early
   non-obvious gotchas remain visible. [S1]
3. **Activation:** Positive, near-miss, held-out, repeated, and fresh-query tests
   show acceptable routing without overfit. [S3]
4. **Behavior:** Realistic boundary cases have evidence-backed grades,
   comparative results, trace review, and human feedback. [S2]
5. **Efficiency:** Gains justify time and token cost; redundant instructions and
   baseline-passing assertions are removed. [S1] [S2]
6. **Tooling:** Scripts are non-interactive, documented, composable, retry-safe,
   output-bounded, and risk-guarded. [S4]

## Anti-Patterns

| Anti-Pattern | Why It Fails | Better Alternative |
|---|---|---|
| Generate from model knowledge alone | Produces generic advice without local APIs, conventions, or failure modes. [S1] | Extract a real successful task or synthesize domain artifacts. |
| Explain familiar basics | Spends scarce context without changing agent behavior. [S1] | Keep only facts and procedures the agent is likely to get wrong. |
| Cover every edge case in the core | Irrelevant branches distract execution. [S1] | Keep essential gotchas inline and load recognizable conditional detail on demand. |
| Present a menu of equal options | Forces repeated exploration and arbitrary selection. [S1] | Name a default and a narrow fallback condition. |
| Store an answer instead of a method | Works only for the example that produced it. [S1] | Encode the reusable decision procedure and stable constraints. |
| Make descriptions keyword-broad | Raises false activation on adjacent tasks. [S3] | Describe intent assertively and test realistic near-misses. |
| Optimize on the entire trigger set | Overfits known phrasings. [S3] | Revise from a fixed training split and select by held-out validation. |
| Judge one impressive output | Cannot establish reliability or added value. [S2] | Compare clean with-skill and baseline runs across varied cases. |
| Write assertions before observing behavior | Encourages weak or misaligned quality proxies. [S2] | Start from expected outcomes, then add observable assertions after the first runs. |
| Grade without concrete evidence | Converts uncertainty or labels into false passes. [S2] | Cite an output fact for every PASS and inspect assertion validity. |
| Patch instructions for one failed prompt | Improves the fixture rather than the task class. [S2] | Infer the causal gap from failures, feedback, and traces. |
| Recreate complex logic every run | Wastes tokens and introduces variation. [S1] [S4] | Bundle and test the repeated mechanism as a script. |
| Use interactive script prompts | Hangs in non-interactive execution. [S4] | Require flags or stdin and return helpful usage errors. |
| Mix data and diagnostics on stdout | Breaks parsing and composition. [S4] | Put structured data on stdout and progress or warnings on stderr. |
| Emit unbounded output | Risks truncating the facts the agent needs. [S4] | Summarize by default and support pagination or explicit file output. |

## Quick Reference

| Situation | Action | Rationale |
|---|---|---|
| Unsure whether a skill adds value | Run representative tasks without it | Baselines expose redundant context. [S1] [S2] |
| A correction recurs | Add a concrete gotcha | Corrections reveal missing domain knowledge. [S1] |
| Conditional content is lengthy | Move it to a support file and name its load trigger | Preserves progressive disclosure. [S1] |
| Operation is fragile | Give the exact sequence and validate it | Variation creates risk. [S1] |
| Several approaches work | Choose a default; explain one fallback condition | Reduces search without removing adaptability. [S1] |
| Exact output shape matters | Provide a short template or conditional asset | Agents follow concrete structure reliably. [S1] |
| Workflow has dependent steps | Use a checklist plus validation loop | Prevents skipped prerequisites. [S1] |
| Batch or destructive action | Plan, validate against truth, then execute | Catches mapping errors before impact. [S1] |
| Testing output behavior | Start with 2–3 realistic cases, including a boundary | Delivers useful evidence before over-investment. [S2] |
| Testing description routing | Use about 20 balanced positive and near-miss queries | Measures both recall and precision. [S3] |
| Objective artifact property | Grade with code | Deterministic checks outperform subjective judgment. [S2] |
| Holistic quality difference | Use blind comparison plus human review | Captures quality outside predefined assertions. [S2] |
| Existing package, simple invocation | Use a pinned one-off runner | Avoids unnecessary script maintenance. [S4] |
| Repeated or fragile logic | Bundle a tested script | Makes execution consistent and reusable. [S1] [S4] |

### Tool Selection

| Environment | One-off mechanism | Self-contained script guidance |
|---|---|---|
| Python with `uv` | `uvx package@version ...` | Use PEP 723 metadata and `uv run scripts/tool.py`; lock when full reproducibility is needed. [S4] |
| Python with `pipx` | `pipx run 'package==version' ...` | Can run PEP 723 scripts; useful where `uv` is unavailable. [S4] |
| Node.js | `npx package@version ...` | Pin package versions; `npx` ships with npm. [S4] |
| Bun | `bunx package@version ...` | Bun can run TypeScript and auto-install pinned imports, subject to its `node_modules` resolution boundary. [S4] |
| Deno | `deno run` with required permissions | Pin `npm:` or `jsr:` imports and separate Deno flags with `--`. [S4] |
| Go | `go run module/cmd@version ...` | Use the Go toolchain directly and pin the module version. [S4] |
| Ruby | — | Use `bundler/inline` with pinned gems; existing Bundler configuration can interfere. [S4] |

## Tacit Knowledge Boundary

- **Skill scope:** Coherence depends on task coupling and coordination cost; the
  sources provide no deterministic partitioning test. Verify with traces.
- **Instruction specificity:** The fragility threshold between rationale-led
  freedom and exact prescription is risk-dependent. Calibrate with failures and
  expert review.
- **Assertion quality:** Observable assertions can still reward proxies rather
  than useful outcomes. Compare them with user intent through human review.
- **Trigger labels:** Near-miss classification may depend on the division of
  responsibility among installed skills. Recheck labels in the target catalog.
- **Stopping criteria:** “Meaningful improvement” requires cost, risk, and
  quality judgment. Set acceptance criteria before evaluation. [S1] [S2] [S3]

## Source Scope

All requested files are **untrusted local snapshots**: evidence rather than
runtime instruction, unverified against the live site. They are complementary
**primary platform** guides: S1 covers authoring, S2 output evaluation, S3
activation, and S4 tooling. No derivative, supporting-foundation, or
cross-platform-contrast source was included.

## Sources

> **Knowledge snapshot date:** 2026-09-05
>
> These local source snapshots were synthesized on the date shown above.
> Information may have changed since then.

1. <a id="s1"></a>**[S1] Best practices for skill creators** —
   https://agentskills.io/skill-creation/best-practices
   - Primary platform: expertise, context and instruction design, validation,
     and script-bundling signals.
2. <a id="s2"></a>**[S2] Evaluating skill output quality** —
   https://agentskills.io/skill-creation/evaluating-skills
   - Primary platform: comparative evals, grading, review, and iteration.
3. <a id="s3"></a>**[S3] Optimizing skill descriptions** —
   https://agentskills.io/skill-creation/optimizing-descriptions
   - Primary platform: description design, trigger testing, and validation.
4. <a id="s4"></a>**[S4] Using scripts in skills** —
   https://agentskills.io/skill-creation/using-scripts
   - Primary platform: runners, dependencies, paths, and script interfaces.

[S1]: #s1
[S2]: #s2
[S3]: #s3
[S4]: #s4
