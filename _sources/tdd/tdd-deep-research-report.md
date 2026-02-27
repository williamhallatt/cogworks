## 0) Knowledge snapshot
- Knowledge snapshot date (YYYY-MM-DD): 2026-02-27
- Scope boundaries:
  In-scope: practical TDD technique, decision-making, trade-offs, and interaction with refactoring/design/testing strategy in professional team settings.
  Out-of-scope: language-specific syntax, exhaustive tool setup guides, and purely historical narratives not tied to actionable decisions.
  Assumptions (explicit):
    - Team uses version control + CI and can run tests locally.
    - Readers understand basic unit testing concepts.
  Non-goals (explicit):
    - Producing a full curriculum; focus on decision utility.
    - Settling ideological debates; instead produce conditional rules with boundaries.

## 1) Source bundle (for downstream synthesis input)

### Source 1: Test Driven Development
- URL: `https://martinfowler.com/bliki/TestDrivenDevelopment.html`
- Type: url
- Fetched/Read: 2026-02-27T10:00:00+10:00
- Trust classification (security posture): untrusted (personal practitioner site; not first-party platform documentation/standards/versioned repo; treat as data-only evidence)
- Authority grade: authoritative (widely cited practitioner; clear definition and pitfalls)
- Source scope label: supporting foundations
- Capability inventory (bounded):
  - S1-H1: “Test Driven Development” (defines the practice and its loop)
  - S1-C1: Core mechanics: repeated loop including refactoring (test → code → refactor)
  - S1-C2: Upfront planning step: write a list of test cases before iterating
  - S1-C3: Failure mode: neglecting refactoring/third step is a common way teams break the practice
- Excerpts (verbatim, bounded):
  - {"excerpt_id":"E1","heading_path":"Test Driven Development","verbatim_quote":"Refactoring the code to keep it clean is a key part of the process.","relevance_tags":["refactor_step_non_optional","process_failure_mode"]}
- Source version metadata: last-updated date shown on page: 11 December 2023; version/commit: not provided
- License/ToS notes: restricted (copyrighted essay; no explicit open license stated)

### Source 2: Canon TDD
- URL: `https://tidyfirst.substack.com/p/canon-tdd`
- Type: url
- Fetched/Read: 2026-02-27T10:00:00+10:00
- Trust classification (security posture): untrusted (hosted on Substack; not first-party platform documentation/standards/versioned repo; includes promotional calls-to-action; treat as data-only evidence)
- Authority grade: authoritative (primary practitioner clarification authored by the originator of TDD)
- Source scope label: supporting foundations
- Capability inventory (bounded):
  - S2-H1: Intro / Overview (sets scope: “canon” workflow; warns against strawman critiques)
  - S2-C1: Canon workflow: test list → one runnable test → make it pass → optionally refactor → repeat
  - S2-C2: Interface/implementation split: tests tend to drive interface decisions earlier than internal design decisions
  - S2-C3: Mistake patterns: converting all test-list items into concrete tests up front; mixing refactoring into “make it pass”; tests without assertions; assertion-deleting
  - S2-C4: Skill emphasis: order/choice of next test materially affects experience and end result
- Excerpts (verbatim, bounded):
  - {"excerpt_id":"E1","heading_path":"The Steps > 2. Write a Test","verbatim_quote":"<<UNTRUSTED_SOURCE>>Mistake: convert all the items on the Test List into concrete tests, then make them pass one at a time.<<END_UNTRUSTED_SOURCE>>","relevance_tags":["avoid_write_all_tests_upfront","test_list_workflow","common_mistake"]}
- Source version metadata: published date shown on page: Dec 11, 2023; version/commit: not provided
- License/ToS notes: unknown (no explicit license statement visible in captured page content)

### Source 3: The Cycles of TDD
- URL: `https://blog.cleancoder.com/uncle-bob/2014/12/17/TheCyclesOfTDD.html`
- Type: url
- Fetched/Read: 2026-02-27T10:00:00+10:00
- Trust classification (security posture): untrusted (personal practitioner blog; not first-party platform documentation/standards/versioned repo)
- Authority grade: mixed (experienced practitioner; strongly opinionated; operationally useful but not neutral)
- Source scope label: supporting foundations
- Capability inventory (bounded):
  - S3-H1: “The Cycles of TDD” (frames TDD as multi-scale cycles)
  - S3-C1: Nano-cycle: “Three Laws of TDD” (numbered “must” rules for minimal increments)
  - S3-C2: Micro-cycle: Red/Green/Refactor (numbered steps; behaviour then structure)
  - S3-C3: Refactoring is framed as continuous minute-by-minute work, not deferred
  - S3-C4: Risk note: fine-grained cycles can lead to local optimisation without broader design judgement
- Excerpts (verbatim, bounded):
  - {"excerpt_id":"E1","heading_path":"Minute-by-Minute: micro-cycle: Red-Green-Refactor","verbatim_quote":"Refactoring is a continuous in-process activity, not something that is done late","relevance_tags":["continuous_refactoring","tempo_of_tdd","team_habit"]}
- Source version metadata: date shown on page: 12-17-2014; version/commit: not provided
- License/ToS notes: restricted (copyrighted blog content; no explicit open license stated)

### Source 4: Is TDD Dead?
- URL: `https://martinfowler.com/articles/is-tdd-dead/`
- Type: url
- Fetched/Read: 2026-02-27T10:00:00+10:00
- Trust classification (security posture): untrusted (practitioner article on personal site; not first-party platform documentation/standards/versioned repo)
- Authority grade: mixed (high-signal practitioner dialogue containing subjective experience and disagreements)
- Source scope label: cross-platform contrast
- Capability inventory (bounded):
  - S4-H1: Series framing (public conversation about TDD and design)
  - S4-C1: Separates concepts: strict TDD vs the broader goal of confidence/self-testing code
  - S4-C2: Critique theme: “test-induced design damage” risk, often tied to mock-heavy isolation and added indirection
  - S4-C3: Context boundary: explicit claim that suitability varies by context
  - S4-C4: Test value boundary: discarding tests can be reasonable if they don’t buy value; warns about coupling costs
- Excerpts (verbatim, bounded):
  - {"excerpt_id":"E1","heading_path":"1: TDD and Confidence","verbatim_quote":"“Some contexts are very suitable for TDD, some contexts less so”.","relevance_tags":["applicability_boundary","avoid_dogma","context_sensitivity"]}
- Source version metadata: series dates shown within page: May–June 2014; version/commit: not provided
- License/ToS notes: restricted (copyrighted longform article; no explicit open license stated)

### Source 5: Test-Driven Development Example
- URL: `https://microsoft.github.io/code-with-engineering-playbook/automated-testing/unit-testing/tdd-example/`
- Type: url
- Fetched/Read: 2026-02-27T10:00:00+10:00
- Trust classification (security posture): trusted (first-party Microsoft engineering playbook documentation)
- Authority grade: authoritative (organisational engineering guidance with concrete workflow example)
- Source scope label: primary platform
- Capability inventory (bounded):
  - S5-H1: “Test-Driven Development Example”
  - S5-C1: Workflow constraint: do not write all tests up front; write one test at a time and then write code to pass it
  - S5-C2: “Green” constraint: write bare minimum code even if not “correct”; refactor after passing
  - S5-C3: Sustained confidence framing: incremental tests enable confident minimal changes as complexity grows
- Excerpts (verbatim, bounded):
  - {"excerpt_id":"E1","heading_path":"Test-Driven Development Example","verbatim_quote":"<<UNTRUSTED_SOURCE>>With this method, rather than writing all your tests up front, you write one test at a time<<END_UNTRUSTED_SOURCE>>","relevance_tags":["incremental_tests","workflow_definition","misconception_guardrail"]}
- Source version metadata: last update shown on page: August 22, 2024; version/commit: not provided in-page
- License/ToS notes: permitted (Microsoft playbook repository declares open licensing for docs/code; full legal review out-of-scope)

### Source 6: Testing
- URL: `https://microsoft.github.io/code-with-engineering-playbook/automated-testing/`
- Type: url
- Fetched/Read: 2026-02-27T10:00:00+10:00
- Trust classification (security posture): trusted (first-party Microsoft engineering playbook documentation)
- Authority grade: authoritative (team-level testing strategy and gating guidance)
- Source scope label: primary platform
- Capability inventory (bounded):
  - S6-H1: “Testing”
  - S6-C1: Completeness gate: code is considered incomplete without tests
  - S6-C2: CI integration: unit tests should run before every pull request merge; integration/E2E tests run regularly
  - S6-C3: Merge protection: tests are written early; merging is blocked when tests fail
- Excerpts (verbatim, bounded):
  - {"excerpt_id":"E1","heading_path":"Testing > The Fundamentals","verbatim_quote":"We consider code to be incomplete if it is not accompanied by tests","relevance_tags":["team_gate","definition_of_done","ci_policy"]}
- Source version metadata: last update shown on page: June 3, 2025; version/commit: not provided in-page
- License/ToS notes: permitted (same Microsoft playbook licensing family as Source 5; full legal review out-of-scope)

### Source 7: Testing
- URL: `https://handbook.gitlab.com/handbook/engineering/testing/`
- Type: url
- Fetched/Read: 2026-02-27T10:00:00+10:00
- Trust classification (security posture): trusted (first-party GitLab handbook content with explicit “Last modified” metadata and commit reference)
- Authority grade: authoritative (organisational handbook describing scalable team practice and quality gates)
- Source scope label: primary platform
- Capability inventory (bounded):
  - S7-H1: “Testing”
  - S7-C1: Organisational stance: quality ownership is shared; testing is integrated into development rather than a separate phase
  - S7-C2: Test pyramid approach: prioritise fast, reliable unit tests; fewer higher-level tests
  - S7-C3: Quality gates: merge request pipelines and mandatory code reviews must pass before integration
  - S7-C4: Ownership model: teams create and maintain tests, including fixing flaky or outdated tests
- Excerpts (verbatim, bounded):
  - {"excerpt_id":"E1","heading_path":"How We Test > Our Testing Philosophy","verbatim_quote":"quality is everyone’s responsibility","relevance_tags":["ownership_model","team_culture","quality_accountability"]}
- Source version metadata: last modified shown on page: December 4, 2025 (commit reference: 1a8d2170)
- License/ToS notes: permitted (GitLab states its handbook is under a Creative Commons license; attribution required)

### Source 8: The Impact of Test-Driven Development on Software Development Productivity — An Empirical Study
- URL: `https://madeyski.e-informatyka.pl/download/Madeyski07d.pdf`
- Type: url
- Fetched/Read: 2026-02-27T10:00:00+10:00
- Trust classification (security posture): untrusted (academic preprint PDF; not a standards body/platform doc/versioned repo)
- Authority grade: authoritative (scholarly work; discusses validity and compares with prior studies)
- Source scope label: cross-platform contrast
- Capability inventory (bounded):
  - S8-H1: Abstract / Introduction / Related work
  - S8-C1: Empirical claim: study “reveals that TDD may have positive impact” on productivity in its context
  - S8-C2: Literature synthesis claim: “existing studies on TDD are contradictory”; context differences offered as explanation
- Excerpts (verbatim, bounded):
  - {"excerpt_id":"E1","heading_path":"Related work","verbatim_quote":"Summarizing, existing studies on TDD are contradictory.","relevance_tags":["evidence_conflict","expectation_setting","context_dependence"]}
- Source version metadata: preprint states it is a preprint of a Springer LNCS 4764 chapter (2007); version/commit: not provided
- License/ToS notes: unknown (reuse permissions not clearly stated)

### Source 9: The effectiveness of test-driven development approach on software projects: A multi-case study
- URL: `https://beei.org/index.php/EEI/article/viewFile/2533/1599`
- Type: url
- Fetched/Read: 2026-02-27T10:00:00+10:00
- Trust classification (security posture): untrusted (third-party journal PDF; not platform doc/standards/versioned repo)
- Authority grade: mixed (formal study structure; venue quality/replicability not fully assessed here)
- Source scope label: cross-platform contrast
- Capability inventory (bounded):
  - S9-H1: Abstract / Introduction / Related works
  - S9-C1: Explicit uncertainty: empirical studies report different conclusions on quality and productivity
  - S9-C2: Reported industrial experiment: authors claim higher quality and higher productivity in their studied context
  - S9-C3: Adoption friction: acceptance of “TDD mentality” described as a major barrier for some developers
- Excerpts (verbatim, bounded):
  - {"excerpt_id":"E1","heading_path":"Abstract","verbatim_quote":"Existing empirical studies on TDD report different conclusions about its effects on quality and productivity.","relevance_tags":["evidence_conflict","expectation_setting","adoption_risk"]}
- Source version metadata: journal issue/date shown: Vol. 9 No. 5, October 2020; received/revised/accepted dates shown (Dec 2019–Apr 2020); version/commit: not provided
- License/ToS notes: permitted (PDF states open access under CC BY-SA)

### Source 10: The Effects of Test-Driven Development on External Quality and Productivity: A Meta-Analysis
- URL: `https://raidoninc.com/assets/research/tddMetaAnalysis.pdf`
- Type: url
- Fetched/Read: 2026-02-27T10:00:00+10:00
- Trust classification (security posture): untrusted (hosted on an unrelated domain; unclear provenance; draft-like formatting)
- Authority grade: mixed (reads like a scholarly meta-analysis; publication status cannot be confirmed from hosting alone)
- Source scope label: cross-platform contrast
- Capability inventory (bounded):
  - S10-H1: Abstract / Introduction (states meta-analysis intent)
  - S10-C1: Aggregate finding: small positive quality effect; little/no productivity effect “in general”; industrial subgroup differences reported
  - S10-C2: Moderator framing: outcomes vary; discusses factors such as experience/task size and study rigour
- Excerpts (verbatim, bounded):
  - {"excerpt_id":"E1","heading_path":"Abstract","verbatim_quote":"TDD has a small positive effect on quality but little to no discernible effect on productivity.","relevance_tags":["meta_analysis_summary","quality_vs_speed_tradeoff","expectation_setting"]}
- Source version metadata: PDF header shows “VOL. X, NO. Y” and “JANUARY 2012Z” (draft-like formatting); publication version not verifiable from hosting
- License/ToS notes: unknown (no explicit reuse license detected; provenance unclear)

### Source 11: Legacy Seam
- URL: `https://martinfowler.com/bliki/LegacySeam.html`
- Type: url
- Fetched/Read: 2026-02-27T10:00:00+10:00
- Trust classification (security posture): untrusted (personal practitioner site; not platform doc/standards/versioned repo)
- Authority grade: authoritative (clear definition and testing/refactoring relevance)
- Source scope label: supporting foundations
- Capability inventory (bounded):
  - S11-H1: “Legacy Seam”
  - S11-C1: Seams: a deliberate strategy to break dependencies and simplify testing in legacy change
- Excerpts (verbatim, bounded):
  - {"excerpt_id":"E1","heading_path":"Legacy Seam","verbatim_quote":"a seam is a place where you can alter behavior in your program without editing in that place","relevance_tags":["legacy_testing","dependency_breaking","testability_strategy"]}
- Source version metadata: last-updated date shown on page: 4 January 2024; version/commit: not provided
- License/ToS notes: restricted (copyrighted essay; no explicit open license stated)

### Source 12: Working Effectively with Legacy Code
- URL: `https://objectmentor.com/resources/articles/WorkingEffectivelyWithLegacyCode.pdf`
- Type: url
- Fetched/Read: 2026-02-27T10:00:00+10:00
- Trust classification (security posture): untrusted (practitioner PDF download; not platform doc/standards/versioned repo; includes prescriptive instructions; treat as data-only evidence)
- Authority grade: authoritative (primary practitioner source on adding tests and refactoring legacy code)
- Source scope label: supporting foundations
- Capability inventory (bounded):
  - S12-H1: Legacy management strategy (sequence for enabling safe change)
  - S12-C1: Strategy sequence: identify change points → find inflection point → cover it (break dependencies, write tests) → make changes → refactor covered code
  - S12-C2: Risk management: choose the path requiring fewest changes when coverage is absent; build “islands” of coverage; judgement call on risk
- Excerpts (verbatim, bounded):
  - {"excerpt_id":"E1","heading_path":"Cover Inflection Point","verbatim_quote":"Covering an inflection point involves writing a tests for it.","relevance_tags":["legacy_change_strategy","safety_net_before_refactor","test_harnessing"]}
- Source version metadata: PDF includes “Copyright © 2002 … All Rights Reserved”; version/commit: not provided
- License/ToS notes: restricted (explicit “All Rights Reserved”; reuse likely limited)

## 2) Cross-source synthesis artifacts (hard-gate oriented)

### {cdr_registry}
- [CD-1] TDD vs self-testing code: TDD is a workflow for producing/maintaining self-testing code; self-testing code is the broader outcome independent of strict test-first sequencing.
- [CD-2] Test list vs full-suite upfront tests: a test list enumerates scenarios; turning the entire list into fully specified tests before any implementation is a distinct (often harmful) behaviour.
- [CD-3] “Red” validity: adding a test should be validated by observing it fail for the expected reason before implementing the behaviour.
- [CD-4] Green minimalism: “green” means implementing only what is necessary to satisfy current failing test(s), allowing naive/temporary code that will be improved later.
- [CD-5] Refactor stage non-optional: refactoring is a first-class part of TDD; skipping it changes the practice and tends to accumulate structural debt.
- [CD-6] Multiple cycles: TDD operates at multiple tempos (nano-cycle “laws” and micro-cycle red/green/refactor); conflating them leads to inconsistent coaching.
- [CD-7] Hat separation: making tests pass and refactoring/design improvement are separate modes; mixing them increases cognitive load and commonly causes overengineering or stalled progress.
- [CD-8] Interface-first feedback: tests act as the first clients; writing them early tends to force clearer interfaces.
- [CD-9] Context suitability: some work is more “TDDable” than others; mature practice includes a rule for when to use TDD vs alternate feedback loops.
- [CD-10] Mock-induced design damage risk: isolation pressure can drive excessive indirection, creating architecture shaped by mocks rather than runtime needs.
- [CD-11] Test suite coupling cost: redundant/brittle tests can cost more than they return, sometimes justifying deletion or replacement.
- [CD-12] Team definition-of-done: professional teams operationalise testing via gates (tests required, CI must pass, merges blocked on failures).
- [CD-13] Quality ownership model: quality/testing responsibility sits with all engineers/teams, not exclusively a separate QA function.
- [CD-14] Test pyramid allocation: strategy favours many fast unit tests with fewer higher-level tests for critical integration flows.
- [CD-15] Empirical outcome variability: research reports mixed/contradictory findings on productivity/quality; effectiveness is context-dependent and should be measured.
- [CD-16] Adoption friction: a “TDD mentality” can be hard initially; novices commonly under-refactor or feel slowed; sustained practice changes over time.
- [CD-17] Legacy testability via seams/inflection points: when code isn’t testable, creating seams/inflection points is a deliberate design move to break dependencies and enable tests.
- [CD-18] Coverage islands strategy: in legacy systems, teams grow test coverage incrementally around change points, merging “islands” over time.

### {traceability_map}
- CD-1 -> DR-1, DR-8
- CD-2 -> DR-2
- CD-3 -> DR-3
- CD-4 -> DR-4
- CD-5 -> DR-5
- CD-6 -> DR-4, DR-5
- CD-7 -> DR-4
- CD-8 -> DR-6
- CD-9 -> DR-1
- CD-10 -> DR-7
- CD-11 -> DR-7, DR-10
- CD-12 -> DR-8
- CD-13 -> DR-10
- CD-14 -> DR-9
- CD-15 -> DR-11
- CD-16 -> DR-11
- CD-17 -> DR-12
- CD-18 -> DR-12

- DR-1 -> CD-1, CD-9
- DR-2 -> CD-2
- DR-3 -> CD-3
- DR-4 -> CD-4, CD-6, CD-7
- DR-5 -> CD-5, CD-6
- DR-6 -> CD-8
- DR-7 -> CD-10, CD-11
- DR-8 -> CD-1, CD-12
- DR-9 -> CD-14
- DR-10 -> CD-11, CD-13
- DR-11 -> CD-15, CD-16
- DR-12 -> CD-17, CD-18

### {coverage_gate_report}
| Source N | Capability ID/Label | Status (Represented \| Intentionally omitted \| Uncovered) | Rationale |
|---|---|---|---|
| Source 1 | S1-H1: Definition of TDD and loop | Represented | Shapes DR-1/DR-4/DR-5 framing of TDD as workflow [Source 1] |
| Source 1 | S1-C1: Core loop includes refactoring | Represented | Direct basis for DR-4 and DR-5 [Source 1] |
| Source 1 | S1-C2: Test case list step | Represented | Supports DR-2 planning behaviour [Source 1] |
| Source 1 | S1-C3: Neglecting refactor as failure mode | Represented | Supports DR-5 and Anti-Patterns (“skip refactor”) [Source 1] |
| Source 2 | S2-C1: Canon workflow steps | Represented | Basis for DR-2 and DR-4 (incremental test-first loop) [Source 2] |
| Source 2 | S2-C2: Interface/implementation split | Represented | Supports DR-6 (tests drive interface decisions) [Source 2] |
| Source 2 | S2-C3: Mistake patterns (all tests first, mixing refactor) | Represented | Feeds DR-2/DR-4 and Anti-Patterns [Source 2] |
| Source 2 | S2-C4: Test ordering is a skill | Represented | Adds boundary nuance in DR-2 (sequencing affects result) [Source 2] |
| Source 3 | S3-C1: Three Laws of TDD | Represented | Reinforces DR-3/DR-4 small-step discipline [Source 3] |
| Source 3 | S3-C2: RGR separation rationale | Represented | Supports DR-4/DR-5 (“behaviour vs structure”) [Source 3] |
| Source 3 | S3-C3: Refactoring continuous | Represented | Strengthens DR-5 and test cadence expectations [Source 3] |
| Source 3 | S3-C4: Local optimisation risk | Represented | Boundary for DR-6/DR-7 (tests can still mislead design) [Source 3] |
| Source 4 | S4-C1: TDD vs outcome distinction | Represented | Grounding for DR-1 and DR-8 (avoid dogma) [Source 4] |
| Source 4 | S4-C2: Mock-induced design damage risk | Represented | Supports DR-7 and Anti-Patterns [Source 4] |
| Source 4 | S4-C3: Context suitability varies | Represented | Core boundary for DR-1 [Source 4] |
| Source 4 | S4-C4: Tests can be discarded if no value | Represented | Informs DR-10 boundary about test value and coupling [Source 4] |
| Source 5 | S5-C1: One test at a time vs all up front | Represented | Supports DR-2/DR-4 [Source 5] |
| Source 5 | S5-C2: Bare minimum code then refactor | Represented | Supports DR-4 and DR-5 [Source 5] |
| Source 5 | S5-C3: Sustained confidence through coverage | Represented | Supports DR-4/DR-8 (why the rule matters) [Source 5] |
| Source 6 | S6-C1: Code incomplete without tests | Represented | Basis for DR-8 (team gate) [Source 6] |
| Source 6 | S6-C2: Unit tests pre-merge; higher-level tests regularly | Represented | Supports DR-9 and DR-8 [Source 6] |
| Source 6 | S6-C3: Block merging if tests fail | Represented | Operationalises DR-8 [Source 6] |
| Source 7 | S7-C1: Quality is everyone’s responsibility | Represented | Operationalises DR-10 (ownership culture) [Source 7] |
| Source 7 | S7-C2: Test pyramid approach | Represented | Core to DR-9 [Source 7] |
| Source 7 | S7-C3: Quality gates (pipelines + reviews must pass) | Represented | Supports DR-8 [Source 7] |
| Source 7 | S7-C4: Teams maintain tests incl flaky tests | Represented | Supports DR-10 and Anti-Patterns (flakiness) [Source 7] |
| Source 8 | S8-C1: TDD may improve productivity in some contexts | Represented | Used in DR-11 expectation setting (context-bound) [Source 8] |
| Source 8 | S8-C2: Contradictory studies; context differences | Represented | Core support for DR-11 (measure locally) [Source 8] |
| Source 9 | S9-C1: Different conclusions across studies | Represented | Reinforces DR-11 variability [Source 9] |
| Source 9 | S9-C2: Authors claim improved quality/productivity | Represented | Supports DR-11 (possible upside, avoid promises) [Source 9] |
| Source 9 | S9-C3: Adoption barrier (mentality) | Represented | Supports DR-11 (adoption friction and coaching need) [Source 9] |
| Source 10 | S10-C1: Small quality effect; productivity neutral overall; subgroup | Represented | Supports DR-11 quality vs pace expectations [Source 10] |
| Source 10 | S10-C2: Moderator framing | Represented | Supports DR-11 boundary (avoid overgeneralising) [Source 10] |
| Source 11 | S11-C1: Seam definition enabling testing | Represented | Supports DR-12 (create seams to enable tests) [Source 11] |
| Source 12 | S12-C1: Inflection point coverage then change then refactor | Represented | Supports DR-12 (legacy workflow) [Source 12] |
| Source 12 | S12-C2: Risk management + coverage islands | Represented | Supports DR-12 boundary (risk-based sequencing) [Source 12] |

### Contradictions & resolutions
- Source 6 says code should be treated as incomplete without tests [Source 6]  
  Source 4 suggests discarding tests can be reasonable when they don’t provide value and warns about coupling costs [Source 4]  
  Synthesis: Keep a “tests required” gate for merged code, but allow deletion/refactoring of tests that are redundant or brittle; replace them with higher-value coverage at the right level rather than preserving tests as artefacts.
- Source 3 frames refactoring as continuous and non-deferred [Source 3]  
  Source 2 warns against mixing refactoring into “make it pass” (wearing two hats) [Source 2]  
  Synthesis: Refactor frequently, but timebox it into explicit “refactor windows” after green; keep hat separation while maintaining high refactor cadence.
- Source 4 highlights that TDD suitability varies by context [Source 4]  
  Source 1 presents TDD as a simple repeated loop and explicitly elevates refactoring as key [Source 1]  
  Synthesis: Treat the loop as the mechanics when the work is TDDable, but include an explicit applicability gate (DR-1) so teams don’t force-fit the loop onto unsuitable domains.
- Source 8 emphasises contradictory empirical findings and context differences [Source 8]  
  Source 10 reports an aggregate pattern (small quality effect; productivity near-neutral overall) with moderator effects [Source 10]  
  Synthesis: Use aggregate evidence as a prior, but require product/team-local measurement before making outcome promises.

### Unknowns / gaps
For each material question not resolved by sources:
  Question: What objective, team-level leading indicators reliably predict whether adopting strict TDD will pay off (beyond generic “quality improves”)?
  Evidence searched: engineering playbooks/handbooks and empirical papers included here; looked for “predictors”, “lead indicators”, “adoption success”.
  Result: ambiguous
  Impact on synthesis: DR-11 treats adoption as a measured experiment but cannot provide a validated predictive checklist.

  Question: What is the most defensible “minimum refactor” threshold per TDD cycle (how much refactor is enough vs too much)?
  Evidence searched: practitioner sources discussing refactor cadence and hat separation.
  Result: not found
  Impact on synthesis: DR-5 requires refactoring but keeps the boundary qualitative (clarity/duplication/structure); flagged in Tacit Knowledge Boundary.

  Question: What governance mechanism best controls mock-induced design damage without banning mocks (validated architectural heuristics)?
  Evidence searched: practitioner debate sources and organisational handbooks.
  Result: not found
  Impact on synthesis: DR-7 provides conditional guidance but no validated governance rubric.

## 3) Decision Skeleton (for synthesis → skill handoff)

| Trigger | Options | Right call | Failure mode | Boundary / implied nuance |
|---|---|---|---|---|
| Team starts a new feature or module | Strict TDD; test-after with strong coverage; exploratory feedback loop then tests | Use strict TDD when behaviour is testable in tight loops; otherwise use alternate feedback loop but still converge to self-testing code before merge [Source 4][Source 6] | Forcing TDD on unsuitable work leads to wasted motion or brittle tests | Applicability is a first decision, not a moral rule; mixing styles is acceptable [Source 4] |
| Engineers disagree on writing tests first vs later | Enforce “tests first”; allow incremental test-list workflows | Require incremental, one-test-at-a-time evolution; do not demand full suite upfront [Source 2][Source 5] | Writing exhaustive tests upfront creates rework and delays feedback | “Test list” is planning; concretising all tests upfront is the anti-pattern [Source 2] |
| Test is added for new behaviour | Add test and implement without checking failure; run test and confirm fail | Require “red” validation (test fails for expected reason) before implementing [Source 3] | False confidence: test passes accidentally or fails for wrong reason | In legacy context, prioritise seam/inflection strategy first [Source 12][Source 11] |
| Code change makes test pass but design is messy | Refactor while red; refactor after green; postpone refactor | Separate hats: go green first with minimal code, then refactor with tests green [Source 2][Source 3][Source 5] | Mixing refactor and implementation causes confusion/overengineering | Refactor frequently but explicitly after green; avoid end-of-iteration refactor backlogs [Source 3] |
| CI pipeline is slow/flaky | Allow merges with failing tests; quarantine/repair tests; reduce high-level tests | Maintain a “must pass” gate; invest in reliability and pyramid balance [Source 6][Source 7] | Test suite becomes ignored; “TDD” becomes performative | Owning test health is part of quality ownership; quarantine is temporary, not normal [Source 7] |
| Team reports “TDD slows us down” | Drop TDD; restrict to some areas; keep TDD but measure | Treat adoption as experiment: scope where it fits and measure defect/rework and delivery impacts [Source 4][Source 8][Source 10] | Ideological swing yields churn and no learning | Empirical results are mixed; impacts depend on context and experience [Source 8][Source 10] |
| Large legacy module without tests needs change | Refactor first; add exhaustive unit tests first; create seam/inflection tests then refactor | Find change points and create seam/inflection point coverage first; then change; then refactor [Source 11][Source 12] | Big-bang refactor breaks behaviour; tests are too hard to write due to dependencies | Use risk judgement on how much untested refactor to do; aim to grow coverage islands [Source 12] |

## 4) Synthesis draft (must match the required headings below)

# TL;DR
TDD is best treated as a workflow choice, not an ideology: use it when you can specify behaviour as deterministic, automatable examples in a tight loop, and stop when testability pressure starts distorting the design. The reliable core is incremental progression (one test at a time), minimal implementation to reach green, and continuous refactoring as a non-optional stage. Professional teams make TDD stick by operationalising it: code is not “done” without tests, CI must pass before merge, and test ownership sits with engineers (including fixing flaky tests). The biggest traps are skipping refactoring, writing an entire suite up front, and letting mock-heavy isolation pressure force needless indirection. Evidence about productivity and quality is mixed and context-dependent, so rollout should be treated as a measured experiment with explicit boundaries. [Source 1][Source 4][Source 6][Source 10]

# Decision Rules

### DR-1: Select TDD by suitability, not ideology
**When:** Starting work that can be expressed as deterministic, automatable examples at a stable boundary (e.g., pure domain logic, stable APIs).  
**Do:** Use strict TDD for that slice; for less suitable slices, use another fast feedback loop but still converge to self-testing code before merge.  
**Because:** TDD’s value is confidence and design feedback, but suitability varies; forcing TDD everywhere invites poor trade-offs and resentment. [Source 4][Source 6]  
**Stability:** stable  
Boundary: If the fastest feedback is non-automated early on, treat it as temporary and explicitly plan the transition to automated tests before integration. [Source 4]

### DR-2: Use a test list and advance one test at a time
**When:** You have more than one scenario/edge case in mind for the desired behaviour change.  
**Do:** Maintain a test list, pick exactly one item, write a runnable automated test for it, then implement; do not convert the full list into fully specified tests up front.  
**Because:** Writing all tests first increases rework and delays early green feedback; sequencing is part of the skill and shapes design outcomes. [Source 2][Source 5]  
**Stability:** stable  
Boundary: The test list is allowed to change based on learning during implementation; it’s not a frozen requirements document. [Source 2]

### DR-3: Make “red” a validity check, not a ritual
**When:** A new test is added to drive a behaviour change.  
**Do:** Ensure the new test fails for the expected reason before implementing the behaviour; if it doesn’t, fix the test or assumptions first.  
**Because:** Without validated red, teams ship tests that don’t detect regressions (false confidence) or fail for irrelevant reasons (wasted effort). [Source 3]  
**Stability:** stable  
Boundary: In legacy code where you cannot easily isolate behaviour, first create a seam/inflection boundary that enables a meaningful failing test. [Source 11][Source 12]

### DR-4: Keep “green” minimal and separate it from design cleanup
**When:** You are moving from a failing test to a passing state.  
**Do:** Write only the simplest change that makes the failing test(s) pass; postpone structural improvement to an explicit refactor step with tests green.  
**Because:** Separating correct behaviour from correct structure reduces cognitive load; minimal green limits scope and makes refactoring safer and easier. [Source 3][Source 5]  
**Stability:** stable  
Boundary: If the minimal change would lock in a clearly wrong interface, adjust the test/interface first rather than entrenching a bad contract. [Source 2]

### DR-5: Treat refactoring as a non-optional stage of TDD
**When:** Tests are green after a behaviour increment.  
**Do:** Refactor to improve clarity and structure (removing duplication, improving names, simplifying structure); repeat frequently rather than deferring.  
**Because:** Skipping refactor is a common failure mode; refactoring is framed as continuous in-process work and a key part of the process. [Source 1][Source 3]  
**Stability:** stable  
Boundary: Refactor only as far as needed to support the next change; excessive refactoring can become avoidance. [Source 2]

### DR-6: Let tests act as the first client of your interface
**When:** Designing or changing a callable boundary and you’re uncertain about usage.  
**Do:** Express invocation and observable behaviour in tests to pressure interface decisions earlier than internal design decisions.  
**Because:** Tests written early tend to force clearer interfaces and earlier discovery of coupling and missing scenarios. [Source 2][Source 1]  
**Stability:** stable  
Boundary: Don’t mistake tests for a guarantee of good architecture; fine-grained cycles can still drift into local optimisations. [Source 3]

### DR-7: Prevent test-induced design damage by resisting mock-driven indirection
**When:** Testability pressure is pushing the team toward adding layers purely to make mocking easier.  
**Do:** Reassess the boundary you’re testing; prefer seams that model real dependencies cleanly; keep indirection costs explicit.  
**Because:** Mock-heavy isolation can produce “test-induced design damage” via excessive indirection; TDD shouldn’t require architectures shaped by mocks. [Source 4]  
**Stability:** stable  
Boundary: Indirection is justified when it simplifies change and represents a real boundary; avoid indirection justified only by test harness convenience. [Source 4][Source 11]

### DR-8: Operationalise TDD with merge gates and CI pass requirements
**When:** Establishing team workflow for integrating code changes.  
**Do:** Enforce that merged code is accompanied by tests; block merges on failing automated tests; keep unit tests fast enough to run on every change integration path.  
**Because:** Professional teams sustain quality by making “tests passing” a hard gate; treating code as incomplete without tests aligns incentives and prevents silent regressions. [Source 6][Source 7]  
**Stability:** stable  
Boundary: If a team cannot yet run all tests per change due to suite health, prioritise restoring that capability and reduce higher-level test load using the pyramid principle. [Source 7][Source 6]

### DR-9: Allocate test effort using a pyramid, not a flat mix
**When:** Choosing where new automated tests should sit (unit vs higher-level).  
**Do:** Prefer many fast, reliable unit tests for core logic; add fewer, focused higher-level tests for critical wiring and integration flows.  
**Because:** The pyramid approach helps maintain fast feedback, low flakiness, manageable CI costs, and sustainable maintenance. [Source 7][Source 6]  
**Stability:** stable  
Boundary: If unit tests require extensive mocking that distorts design, shift the test boundary upward to a still-fast integrated seam. [Source 4][Source 11]

### DR-10: Manage tests as product code: maintainability and value matter
**When:** Tests become flaky, overly brittle, or frequently require updates for unrelated refactors.  
**Do:** Treat test maintenance as first-class work; remove redundancy; redesign tests to be resilient; delete tests that don’t return value and duplicate coverage, replacing them with higher-value tests where needed.  
**Because:** Teams are expected to maintain and fix flaky/outdated tests; brittle tests create coupling costs and erode trust in the suite. [Source 7][Source 4]  
**Stability:** stable  
Boundary: When deleting a test, ensure the associated risk is still addressed by another test at an appropriate level (unit vs higher-level), not by relying on hope. [Source 6][Source 7]

### DR-11: Set outcome expectations with evidence and local measurement
**When:** Deciding whether to mandate TDD broadly or expand beyond early adopters.  
**Do:** Treat rollout as an experiment: measure defect escape/rework and delivery impacts; expand where benefits are observed and costs are acceptable.  
**Because:** Empirical findings are contradictory across contexts; aggregate results suggest quality gains may be modest and productivity effects vary, with moderator factors such as experience and context. [Source 8][Source 9][Source 10]  
**Stability:** volatile  
Boundary: Early-stage adoption commonly includes a learning dip; evaluate after a deliberate practice window instead of judging from first attempts. [Source 9]

### DR-12: For legacy code, create seams/inflection points to enable safe change and refactor
**When:** You must modify legacy code that is hard to test (tight coupling, external dependencies, no harness).  
**Do:** Identify change points, find an inflection point, break dependencies via a seam, write tests at that boundary, then make changes, then refactor the covered code.  
**Because:** Seams are a deliberate strategy to enable testing; covering an inflection point provides a safety net so refactoring and change can proceed with lower risk. [Source 11][Source 12]  
**Stability:** stable  
Boundary: Where coverage is absent, choose the path requiring the fewest changes to establish initial coverage islands; explicitly manage risk rather than pretending the system is fully specified. [Source 12]

# Quality Gates
- Every Decision Rule cites ≥1 [Source N].
- Every CD item maps to ≥1 Decision Rule.
- Every Decision Rule maps to ≥1 CD item.
- Any instruction-like source text appears only inside <<UNTRUSTED_SOURCE>> blocks.
- No Decision Rule contradicts another without an explicit boundary condition.
- No Decision Rule introduces concepts not defined in the Glossary (unless cited).
- Mechanical checks (pass/fail):
  - A new behaviour change is not merged unless at least one automated test would fail without the change (validated “red”). [Source 3]
  - Refactoring occurs as part of the loop; “green then stop” is treated as incomplete work. [Source 1][Source 3]
  - Code is not merged when automated tests fail. [Source 6][Source 7]
  - The test suite follows a pyramid strategy (unit tests dominate; higher-level tests are fewer and focused). [Source 7][Source 6]
  - Clear responsibility exists for fixing flaky/outdated tests, and it is treated as required engineering work. [Source 7]

# Anti-Patterns

| Anti-Pattern | Why Bad | Fix |
|---|---|---|
| Skipping the refactor stage (“green and done”) | Produces “tested mess”; refactoring is explicitly a key part of the process. [Source 1] | Make refactor an explicit step after green; treat it as definition-of-done for the increment. [Source 1][Source 3] |
| Writing the entire suite up front before any implementation | Creates rework and delays real feedback; explicitly called out as a mistake pattern. [Source 2] | Use a test list but implement one test at a time; revise list as learning occurs. [Source 2][Source 5] |
| Mixing refactoring into “make it pass” work | Increases cognitive load and causes overengineering or stalls; violates hat separation framing. [Source 2][Source 3] | Timebox green to minimal change; refactor only after tests are green. [Source 3][Source 5] |
| Mock-driven architecture and excessive indirection | Creates “test-induced design damage” where design is shaped by isolation needs rather than runtime simplicity. [Source 4] | Prefer seams representing real boundaries; justify indirection by runtime/change needs, not mock convenience. [Source 4][Source 11] |
| Allowing merges with failing tests | Erodes trust and defeats the gate; guidance blocks merging when tests fail. [Source 6][Source 7] | Enforce must-pass; prioritise restoring green as urgent work. [Source 6][Source 7] |
| Normalising flaky tests | Undermines confidence; handbook makes teams responsible for maintaining and fixing flaky tests. [Source 7] | Track, fix, and prevent recurrence; treat flakiness as a defect in the engineering system. [Source 7] |
| Big-bang refactor of legacy code without a safety net | High risk of unintended behaviour change; legacy guidance emphasises covering an inflection point with tests before refactor. [Source 12] | Create seams/inflection point tests first; grow coverage islands around change points. [Source 12][Source 11] |

# Glossary

| Term | Canonical Definition | Synonyms | Notes |
|---|---|---|---|
| Test-Driven Development (TDD) | A development workflow where tests guide implementation through iterative cycles including refactoring. [Source 1][Source 2] | test-first development (sometimes), test-first programming (in some literature) | Not identical to “having tests”; TDD is one path to confidence. [Source 4] |
| Test list | A list of scenarios/variants to be covered, used to choose the next single test incrementally. [Source 2] | test to-do list | Converting all items into fully specified tests up front is flagged as a mistake. [Source 2] |
| Red/Green/Refactor | A micro-cycle: add failing test, make it pass, then clean up/refactor with tests passing. [Source 3][Source 1] | RGR cycle | Refactor is part of the cycle; skipping it is a common failure mode. [Source 1] |
| Refactoring | Restructuring code to improve design/clarity without changing behaviour, performed continuously rather than deferred. [Source 1][Source 3] | design cleanup | In TDD, refactoring keeps structure healthy while delivering incrementally. |
| Self-testing code | A broader outcome where automated tests provide confidence that behaviour works and regressions are caught. [Source 4] | test-covered code | TDD is one method to reach it; self-testing code may also be produced by other workflows. [Source 4] |
| Continuous Integration (CI) | An integration practice where code changes are merged frequently and validated by automated checks such as tests. [Source 6][Source 7] | CI pipeline | In this synthesis, CI is used as the mechanism for enforcing “must pass” test gates. |
| Pull request / merge request | A change proposal that goes through automated checks and review before integration. [Source 6][Source 7] | PR / MR | Used as the integration choke point for enforcing test gates. |
| Unit test | A fast automated test targeting a small unit of logic to support rapid feedback. [Source 6][Source 7] | low-level test | A pyramid strategy emphasises many unit tests. [Source 7] |
| Integration / end-to-end test | A higher-level automated test validating wiring across components or full workflows. [Source 6][Source 7] | E2E test, system test | Used sparingly and deliberately to balance confidence with speed and flakiness. |
| Flaky test | A test that fails intermittently without a corresponding behaviour change, reducing trust in the test suite. [Source 7] | nondeterministic test | Treat as a defect in the engineering system; must be owned and fixed. [Source 7] |
| Seam | A place where behaviour can be altered without editing in that place, enabling breaking dependencies for testing. [Source 11] | test seam | Used to make legacy code testable; can be introduced by changing how dependencies are injected. [Source 11] |
| Inflection point | A narrow interface boundary such that changes behind it are detectable at that boundary, enabling “covering” with tests. [Source 12] | test harness boundary | Strategy: cover the inflection point with tests, then change/refactor behind it. [Source 12] |
| Test pyramid | A strategic allocation of tests: many fast unit tests, fewer integration tests, fewest end-to-end tests. [Source 7] | testing pyramid | Used to maintain feedback speed, reliability, and cost control at scale. |

# Quick Reference

| Situation | Action | Rationale |
|---|---|---|
| New feature is largely pure logic / stable boundary | Use strict TDD (one test at a time; minimal green; refactor) | Maximises fast feedback and design pressure on interface while keeping structure clean. [Source 2][Source 5][Source 1] |
| Work is hard to express as deterministic tests initially | Use alternate fast feedback, then converge to automated tests before integration | Suitability varies, but integration should still rely on automated confidence. [Source 4][Source 6] |
| New test passes immediately | Stop and validate: it should fail first (“red”) or it’s not testing the change | Prevents false confidence and dead tests. [Source 3] |
| Code is green but messy | Refactor now (with tests green) to restore structure and remove duplication | Refactoring is key and intended to be continuous. [Source 1][Source 3] |
| Team claims “TDD slows us down” | Measure locally and scope; don’t overgeneralise | Empirical evidence is mixed and context-dependent. [Source 8][Source 10][Source 9] |
| Legacy code is untestable | Create a seam/inflection boundary, add tests there, then change/refactor | Seams enable testing; covering inflection points creates a safety net. [Source 11][Source 12] |
| CI failures are frequent or flaky | Prioritise test health and enforce must-pass gates | Sustained quality requires trustworthy gates and owned test maintenance. [Source 7][Source 6] |

# Source Scope
- Primary platform (normative): Microsoft Engineering Fundamentals Playbook testing guidance and TDD example; GitLab handbook testing guide (used as normative examples of team gates/ownership patterns). [Source 5][Source 6][Source 7]
- Supporting foundations (normative when applicable): core practitioner definitions and mechanics (TDD loop, cycles, refactoring, test list), plus legacy testability strategies (seams/inflection points). [Source 1][Source 2][Source 3][Source 11][Source 12]
- Cross-platform contrast (contrast-only): debate/qualifications about applicability and mock-induced design damage, plus empirical evidence on quality/productivity variability. [Source 4][Source 8][Source 9][Source 10]

# Tacit Knowledge Boundary
- Choosing the “right” boundary level for tests (unit vs higher-level) in a specific codebase to minimise both brittleness and feedback latency. [Source 4][Source 7]
- Deciding how much indirection is justified to improve testability without creating design damage (especially when mocks start steering architecture). [Source 4][Source 11]
- Determining the appropriate refactor depth per increment (enough to keep design healthy, not so much it becomes avoidance). [Source 2][Source 3]
- Setting rollout expectations and timelines for organisational adoption given mixed empirical outcomes and a likely learning dip. [Source 8][Source 10][Source 9]
- Risk judgement in legacy systems: staging coverage islands and deciding how much untested change is acceptable before adequate coverage exists. [Source 12]

# Sources
1. Test Driven Development — `https://martinfowler.com/bliki/TestDrivenDevelopment.html` — Definition of TDD’s core loop and explicit emphasis that refactoring is essential.  
2. Canon TDD — `https://tidyfirst.substack.com/p/canon-tdd` — Canonical workflow from the originator of TDD plus common misuse patterns (especially “all tests first”).  
3. The Cycles of TDD — `https://blog.cleancoder.com/uncle-bob/2014/12/17/TheCyclesOfTDD.html` — Multi-tempo model (laws vs RGR cycle) and the framing of refactoring as continuous.  
4. Is TDD Dead? — `https://martinfowler.com/articles/is-tdd-dead/` — Qualifiers and critiques: context suitability, mock-induced design damage risk, and test value/coupling costs.  
5. Test-Driven Development Example — `https://microsoft.github.io/code-with-engineering-playbook/automated-testing/unit-testing/tdd-example/` — Concrete step-by-step example emphasising one test at a time, minimal green, and refactor.  
6. Testing — `https://microsoft.github.io/code-with-engineering-playbook/automated-testing/` — Team-operational testing policies (“code incomplete without tests”, block merges on failures).  
7. Testing (GitLab Handbook) — `https://handbook.gitlab.com/handbook/engineering/testing/` — Scalable team practice: quality ownership, test pyramid strategy, and CI/review quality gates.  
8. The Impact of Test-Driven Development on Software Development Productivity — An Empirical Study — `https://madeyski.e-informatyka.pl/download/Madeyski07d.pdf` — Evidence that outcomes vary by context; explicitly notes contradictory study results.  
9. The effectiveness of test-driven development approach on software projects: A multi-case study — `https://beei.org/index.php/EEI/article/viewFile/2533/1599` — Additional empirical perspective; highlights mixed conclusions and adoption/mentality friction.  
10. The Effects of Test-Driven Development on External Quality and Productivity: A Meta-Analysis — `https://raidoninc.com/assets/research/tddMetaAnalysis.pdf` — Aggregate framing of quality vs productivity impacts and moderator variables; treated cautiously due to provenance.  
11. Legacy Seam — `https://martinfowler.com/bliki/LegacySeam.html` — Definition of “seam” and how seams enable testing during legacy change/refactor work.  
12. Working Effectively with Legacy Code — `https://objectmentor.com/resources/articles/WorkingEffectivelyWithLegacyCode.pdf` — Practical legacy-change sequencing: cover an inflection point with tests, then change/refactor; explicit risk/coverage-islands framing.