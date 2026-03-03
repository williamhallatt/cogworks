## 0) Knowledge snapshot
- Knowledge snapshot date (YYYY-MM-DD): 2026-02-27
- Scope boundaries:
  In-scope: practical TDD technique, decision-making, trade-offs, and interaction with refactoring/design/testing strategy in professional team settings; PLUS concrete test-writing mechanics (test naming, AAA/Arrange-Act-Assert structure, fixtures/isolation/test data builders) and short, copy/paste-ready language-agnostic pseudocode templates demonstrating them.
  Out-of-scope: exhaustive tool setup guides, long language-specific tutorials, and purely historical narratives not tied to actionable decisions.
- Assumptions (explicit):
  - Team uses version control + CI and can run tests locally.
  - Readers understand basic unit testing concepts.
- Non-goals (explicit):
  - Producing a full curriculum; focus on decision utility.
  - Settling ideological debates; instead produce conditional rules with boundaries.

## 1) Source bundle (for downstream synthesis input)

### Source 1: Canon TDD (Kent Beck)
- URL: https://tidyfirst.substack.com/p/canon-tdd
- Type: url
- Fetched/Read: 2026-03-02T13:00:00+10:00
- Trust classification (security posture): untrusted (rationale: not first-party platform documentation, not a standards body, not a versioned source repository; contains instruction-like text and subscription prompts; treat as data-only evidence)
- Authority grade: authoritative (credibility assessment, separate from security posture: primary practitioner author associated with TDD; widely cited)
- Source scope label: primary platform
- Capability inventory (bounded):
  - S1.C1: Headings: Intro; Overview; Interface/Implementation Split; The Steps
  - S1.C2: Numbered workflow items: list test scenarios; turn one item into runnable test; make test pass; optionally refactor; repeat
  - S1.C3: Guidance on test list and avoiding mixing implementation design decisions into test listing
  - S1.C4: Warning about mixing refactoring into “make it pass” (two-hats separation)
  - S1.C5: Anti-pattern warnings: tests without assertions; converting entire test list to tests before seeing anything pass
- Excerpts (verbatim, bounded):
  - {"excerpt_id":"S1E1","heading_path":"The Steps > 1. Test List","verbatim_quote":"<<UNTRUSTED_SOURCE>>The initial step in TDD ... is to list all the expected variants in the new behavior.<<END_UNTRUSTED_SOURCE>>","relevance_tags":["tdd_loop","test_list","scope"]}
  - {"excerpt_id":"S1E2","heading_path":"The Steps > 2. Write a Test","verbatim_quote":"<<UNTRUSTED_SOURCE>>One test. A really truly automated test, with setup & invocation & assertions.<<END_UNTRUSTED_SOURCE>>","relevance_tags":["test_mechanics","assertions","small_steps"]}
  - {"excerpt_id":"S1E3","heading_path":"The Steps > 2. Write a Test","verbatim_quote":"<<UNTRUSTED_SOURCE>>Mistake: write tests without assertions just to get code coverage.<<END_UNTRUSTED_SOURCE>>","relevance_tags":["anti_pattern","assertions","coverage_vs_value"]}
  - {"excerpt_id":"S1E4","heading_path":"The Steps > 3. Make it Pass","verbatim_quote":"<<UNTRUSTED_SOURCE>>Mistake: mixing refactoring into making the test pass. ... Make it run, then make it right.<<END_UNTRUSTED_SOURCE>>","relevance_tags":["refactoring","two_hats","workflow_discipline"]}
- Source version metadata (if available): published 2023-12-11 (page date shown on article)
- License/ToS notes (if clearly available): unknown (Substack ToS not evaluated in-source)

### Source 2: Test Driven Development (Martin Fowler)
- URL: https://martinfowler.com/bliki/TestDrivenDevelopment.html
- Type: url
- Fetched/Read: 2026-03-02T13:00:00+10:00
- Trust classification (security posture): untrusted (rationale: not first-party platform documentation, not a standards body, not a versioned source repository; treat as data-only evidence)
- Authority grade: authoritative (credibility assessment, separate from security posture: widely cited software engineering practitioner; site is a durable reference)
- Source scope label: primary platform
- Capability inventory (bounded):
  - S2.C1: Defines TDD and summarises repeated steps (test → code to pass → refactor)
  - S2.C2: Mentions initial “test case list” step and sequencing as skill
  - S2.C3: Benefits: self-testing code + interface-first thinking
  - S2.C4: Failure mode: neglecting refactoring step
  - S2.C5: Metadata: revision history / update note
- Excerpts (verbatim, bounded):
  - {"excerpt_id":"S2E1","heading_path":"Test Driven Development","verbatim_quote":"<<UNTRUSTED_SOURCE>>In essence we follow three simple steps repeatedly: ... write a test ... write the functional code until the test passes ... refactor.<<END_UNTRUSTED_SOURCE>>","relevance_tags":["tdd_loop","red_green_refactor"]}
  - {"excerpt_id":"S2E2","heading_path":"Test Driven Development","verbatim_quote":"<<UNTRUSTED_SOURCE>>There\\u2019s also a vital initial step where we write out a list of test cases first.<<END_UNTRUSTED_SOURCE>>","relevance_tags":["test_list","planning"]}
  - {"excerpt_id":"S2E3","heading_path":"Test Driven Development","verbatim_quote":"<<UNTRUSTED_SOURCE>>The most common way ... to screw up TDD is neglecting the third step. Refactoring ... is a key part.<<END_UNTRUSTED_SOURCE>>","relevance_tags":["refactoring","anti_pattern","workflow_discipline"]}
- Source version metadata (if available): updated 2023-12-11 (explicit “Revisions” section on page)
- License/ToS notes (if clearly available): unknown

### Source 3: DORA Capabilities: Test automation
- URL: https://dora.dev/capabilities/test-automation/
- Type: url
- Fetched/Read: 2026-03-02T13:00:00+10:00
- Trust classification (security posture): untrusted (rationale: not first-party platform documentation, not a standards body, not a versioned source repository; contains imperative guidance; treat as data-only evidence)
- Authority grade: authoritative (credibility assessment, separate from security posture: DORA guidance is widely used; page presents research-backed capability framing)
- Source scope label: primary platform
- Capability inventory (bounded):
  - S3.C1: Rationale for fast feedback; drawbacks of manual regression and late testing phases
  - S3.C2: Continuous testing throughout delivery lifecycle; curated fast reliable automated suites in pipelines
  - S3.C3: Organisational practices: testers alongside devs; continuous review of suites; developers do TDD
  - S3.C4: Constraints: feedback from automated tests under ~10 minutes; acceptance tests gating “dev complete”
  - S3.C5: Pitfalls: devs not involved; unreliable/flaky tests; lack of suite curation; over-reliance on mocking
- Excerpts (verbatim, bounded):
  - {"excerpt_id":"S3E1","heading_path":"Test automation","verbatim_quote":"<<UNTRUSTED_SOURCE>>Create and curate fast, reliable suites of automated tests ... run as part of your continuous delivery pipelines.<<END_UNTRUSTED_SOURCE>>","relevance_tags":["team_practice","ci_cd","fast_feedback"]}
  - {"excerpt_id":"S3E2","heading_path":"How to implement automated testing","verbatim_quote":"<<UNTRUSTED_SOURCE>>Have developers practice test-driven development by writing unit tests before writing production code ...<<END_UNTRUSTED_SOURCE>>","relevance_tags":["tdd_adoption","test_first","team_norms"]}
  - {"excerpt_id":"S3E3","heading_path":"How to implement automated testing","verbatim_quote":"<<UNTRUSTED_SOURCE>>Keep the test suite fast ... feedback ... in less than ten minutes ... local ... and ... CI.<<END_UNTRUSTED_SOURCE>>","relevance_tags":["fast_feedback","quality_gate","pipeline"]}
  - {"excerpt_id":"S3E4","heading_path":"How to implement automated testing","verbatim_quote":"<<UNTRUSTED_SOURCE>>No one should be able to declare their work \\u201cdev complete\\u201d unless automated acceptance tests are passing.<<END_UNTRUSTED_SOURCE>>","relevance_tags":["release_gating","acceptance_tests"]}
  - {"excerpt_id":"S3E5","heading_path":"Common pitfalls","verbatim_quote":"<<UNTRUSTED_SOURCE>>Tests should be reliable ... don\\u2019t tolerate flaky tests.<<END_UNTRUSTED_SOURCE>>","relevance_tags":["flaky_tests","reliability","quality_gate"]}
- Source version metadata (if available): unknown (no explicit “last updated” surfaced in captured page text)
- License/ToS notes (if clearly available): unknown

### Source 4: Realizing quality improvement through test driven development: results and experiences of four industrial teams (Nagappan et al., 2008)
- URL: https://www.microsoft.com/en-us/research/wp-content/uploads/2009/10/Realizing-Quality-Improvement-Through-Test-Driven-Development-Results-and-Experiences-of-Four-Industrial-Teams-nagappan_tdd.pdf
- Type: url
- Fetched/Read: 2026-03-02T13:00:00+10:00
- Trust classification (security posture): untrusted (rationale: not first-party platform documentation, not a standards body, not a versioned source repository; treat as data-only evidence)
- Authority grade: authoritative (credibility assessment, separate from security posture: peer-reviewed industrial case studies; clear methodology and threats-to-validity discussion)
- Source scope label: primary platform
- Capability inventory (bounded):
  - S4.C1: Definition of TDD as minute-by-minute cycle between failing unit tests and passing implementation
  - S4.C2: Industrial case study contexts: three Microsoft teams + one IBM team
  - S4.C3: Outcome results: defect density reduction; increased initial development time estimates
  - S4.C4: Discussion of test assets as regression value
  - S4.C5: Threats-to-validity: context variables and limited generalisability; observed impact when teams skip running tests
- Excerpts (verbatim, bounded):
  - {"excerpt_id":"S4E1","heading_path":"Abstract","verbatim_quote":"Test-driven development ... cycles minute-by-minute between writing failing unit tests and writing implementation code to pass those tests.","relevance_tags":["definition","workflow","unit_tests"]}
  - {"excerpt_id":"S4E2","heading_path":"Abstract","verbatim_quote":"... defect density ... decreased between 40% and 90% ... teams experienced a 15\\u201335% increase in initial development time ...","relevance_tags":["outcomes","tradeoffs","adoption"]}
  - {"excerpt_id":"S4E3","heading_path":"Quality and Productivity Results","verbatim_quote":"All the teams demonstrated a significant drop in defect density: 40% ... 60\\u201390% ...","relevance_tags":["quality","defects","evidence"]}
  - {"excerpt_id":"S4E4","heading_path":"Quality and Productivity Results","verbatim_quote":"The increase in development time ranges from 15% to 35%.","relevance_tags":["productivity","tradeoffs","planning"]}
  - {"excerpt_id":"S4E5","heading_path":"Conclusions and Discussion","verbatim_quote":"... took some shortcuts by not running the unit tests, and consequently the defect density increased ...","relevance_tags":["enforcement","regression","team_discipline"]}
- Source version metadata (if available): published online 2008-02-27 (shown in PDF header); DOI 10.1007/s10664-008-9062-z (shown in PDF)
- License/ToS notes (if clearly available): unknown (publisher terms not evaluated in-source)

### Source 5: The effects of test driven development on internal quality, external quality and productivity: A systematic review (Bissi et al., 2016)
- URL: https://www.sciencedirect.com/science/article/abs/pii/S0950584916300222
- Type: url
- Fetched/Read: 2026-03-02T13:00:00+10:00
- Trust classification (security posture): untrusted (rationale: not first-party platform documentation, not a standards body, not a versioned source repository; preview content only; treat as data-only evidence)
- Authority grade: authoritative (credibility assessment, separate from security posture: systematic review with explicit method and summary statistics)
- Source scope label: primary platform
- Capability inventory (bounded):
  - S5.C1: Review scope and selection: 1999–2014; 1107 collected; 27 studied in depth
  - S5.C2: Quality outcomes: majority report increases in internal and external quality
  - S5.C3: Productivity outcomes differ by setting (academic vs industrial); nontrivial share indicates lower productivity in industry
  - S5.C4: Summary conclusion emphasising quality benefit but productivity cost
- Excerpts (verbatim, bounded):
  - {"excerpt_id":"S5E1","heading_path":"Highlights","verbatim_quote":"A total of 1107 articles were collected and 27 were studied in depth.","relevance_tags":["evidence_scope","methodology"]}
  - {"excerpt_id":"S5E2","heading_path":"Highlights","verbatim_quote":"Most of the studies (76%) ... increase in the internal software quality ... (88%) ... external software quality ...","relevance_tags":["quality","evidence_summary"]}
  - {"excerpt_id":"S5E3","heading_path":"Highlights","verbatim_quote":"... increase in productivity ... academic environment, but a decrease in an industrial scenario ...","relevance_tags":["productivity","tradeoffs","context_dependence"]}
  - {"excerpt_id":"S5E4","heading_path":"Abstract > Results","verbatim_quote":"Overall, about 44% of the studies indicated lower productivity when using TDD compared to TLD.","relevance_tags":["productivity","tradeoffs","evidence_summary"]}
  - {"excerpt_id":"S5E5","heading_path":"Abstract > Conclusion","verbatim_quote":"... TDD yields more benefits than TLD for internal and external software quality, but ... lower developer productivity ...","relevance_tags":["decision_tradeoff","quality_vs_speed"]}
- Source version metadata (if available): publication date June 2016 (Volume 74); DOI 10.1016/j.infsof.2016.02.004 (shown on page)
- License/ToS notes (if clearly available): restricted (Elsevier rights/purchase language present on page; full text not included)

### Source 6: Software Engineering at Google (SWE book), Chapter 12: Unit Testing
- URL: https://abseil.io/resources/swe-book/html/ch12.html
- Type: url
- Fetched/Read: 2026-03-02T13:00:00+10:00
- Trust classification (security posture): untrusted (rationale: not first-party platform documentation, not a standards body, not a versioned source repository; treat as data-only evidence)
- Authority grade: authoritative (credibility assessment, separate from security posture: organisational engineering guidance; detailed examples; durable publication)
- Source scope label: primary platform
- Capability inventory (bounded):
  - S6.C1: TL;DR guidelines: unchanging tests; public APIs; state not interactions; complete & concise; avoid logic; failure messages; DAMP over DRY
  - S6.C2: Behaviour-first framing: tests for behaviours; many-to-many mapping between methods and behaviours
  - S6.C3: Test structuring mechanics: given/when/then (and notes on multi-step alternating blocks)
  - S6.C4: Naming guidance for actionable failures: test name as primary failure token; avoid “and” multi-behaviour names
  - S6.C5: Clarity guidance: avoid logic in tests; prefer straight-line code; accept duplication for clarity; DAMP vs DRY
  - S6.C6: Test infrastructure guidance: shared infrastructure as product; standardisation; infrastructure needs its own tests
- Excerpts (verbatim, bounded):
  - {"excerpt_id":"S6E1","heading_path":"TL;DRs","verbatim_quote":"Strive for unchanging tests.","relevance_tags":["test_stability","anti_pattern"]}
  - {"excerpt_id":"S6E2","heading_path":"TL;DRs","verbatim_quote":"Test via public APIs.","relevance_tags":["public_api","design_pressure"]}
  - {"excerpt_id":"S6E3","heading_path":"Test Behaviors, Not Methods","verbatim_quote":"There\\u2019s a better way: ... write a test for each behavior.","relevance_tags":["behavior_focus","test_granularity"]}
  - {"excerpt_id":"S6E4","heading_path":"Structure tests to emphasize behaviors","verbatim_quote":"Each test should cover only a single behavior ... vast majority ... require only one \\\"when\\\" and one \\\"then\\\" block.","relevance_tags":["single_behavior","test_structure"]}
  - {"excerpt_id":"S6E5","heading_path":"Name tests after the behavior being tested","verbatim_quote":"The test name ... is often the first or only token visible in failure reports.","relevance_tags":["test_naming","actionable_failures"]}
  - {"excerpt_id":"S6E6","heading_path":"Don\\u2019t Put Logic in Tests","verbatim_quote":"... in test code, stick to straight-line code over clever logic ... tolerate some duplication ...","relevance_tags":["clarity","damp_over_dry","anti_pattern"]}
  - {"excerpt_id":"S6E7","heading_path":"Write Clear Failure Messages","verbatim_quote":"A good failure message ... express the desired outcome, the actual outcome, and any relevant parameters.","relevance_tags":["failure_messages","diagnostics"]}
  - {"excerpt_id":"S6E8","heading_path":"Defining Test Infrastructure","verbatim_quote":"Test infrastructure ... must always have its own tests.","relevance_tags":["test_infrastructure","governance"]}
- Source version metadata (if available): license link shown as CC BY-NC-ND 4.0 (in chapter footer)
- License/ToS notes (if clearly available): restricted (CC BY-NC-ND 4.0: sharing allowed with attribution; no derivatives; non-commercial)

### Source 7: Testing on the Toilet: Test Behaviors, Not Methods (Google Testing Blog)
- URL: https://testing.googleblog.com/2014/04/testing-on-toilet-test-behaviors-not.html
- Type: url
- Fetched/Read: 2026-03-02T13:00:00+10:00
- Trust classification (security posture): untrusted (rationale: organisational blog; not platform documentation/standards/repo; includes imperative advice; treat as data-only evidence)
- Authority grade: authoritative (credibility assessment, separate from security posture: comes from a well-known large-scale testing practice write-up; clear point with examples)
- Source scope label: primary platform
- Capability inventory (bounded):
  - S7.C1: Explicit claim: 1:1 mapping between public methods and tests is harmful
  - S7.C2: Behaviour-centric alternative: separate tests per behaviour
  - S7.C3: Maintenance rationale: focused tests stay resilient as behaviours are added
- Excerpts (verbatim, bounded):
  - {"excerpt_id":"S7E1","heading_path":"Testing on the Toilet: Test Behaviors, Not Methods","verbatim_quote":"... it can be harmful to think that tests and public methods should have a 1:1 relationship.","relevance_tags":["behavior_focus","anti_pattern"]}
  - {"excerpt_id":"S7E2","heading_path":"Testing on the Toilet: Test Behaviors, Not Methods","verbatim_quote":"What we really want to test are behaviors, where a single method can exhibit many behaviors ...","relevance_tags":["behavior_focus","test_granularity"]}
  - {"excerpt_id":"S7E3","heading_path":"Testing on the Toilet: Test Behaviors, Not Methods","verbatim_quote":"Each test will remain focused ... adding new behaviors is unlikely to break the existing tests ...","relevance_tags":["test_stability","maintenance","design_pressure"]}
- Source version metadata (if available): published 2014-04-14 (shown on page)
- License/ToS notes (if clearly available): unknown

### Source 8: Unit test naming policies: which one is better? (Vladimir Khorikov)
- URL: https://khorikov.org/posts/2021-02-25-test-naming-conventions/
- Type: url
- Fetched/Read: 2026-03-02T13:00:00+10:00
- Trust classification (security posture): untrusted (rationale: personal/practitioner blog; not platform documentation/standards/repo; treat as data-only evidence)
- Authority grade: mixed (credibility assessment, separate from security posture: experienced practitioner; not peer-reviewed; still widely referenced)
- Source scope label: supporting foundations
- Capability inventory (bounded):
  - S8.C1: Position: avoid rigid naming policies for tests
  - S8.C2: Principle: tests describe behaviour in language understandable beyond programmers
  - S8.C3: Distinction: “what-to” (observable behaviour) vs “how-to” (implementation detail)
  - S8.C4: Example contrast: rigid pattern vs readable behaviour statement
- Excerpts (verbatim, bounded):
  - {"excerpt_id":"S8E1","heading_path":"Preamble","verbatim_quote":"I advocate against rigid unit test naming policies.","relevance_tags":["test_naming","style_tradeoff"]}
  - {"excerpt_id":"S8E2","heading_path":"Preamble","verbatim_quote":"... unit tests should describe your system\\u2019s behavior ... understandable ... to non-technical people too.","relevance_tags":["test_naming","shared_understanding"]}
  - {"excerpt_id":"S8E3","heading_path":"Preamble","verbatim_quote":"A good test name should describe the system\\u2019s what-to\\u2019s, not its how-to\\u2019s.","relevance_tags":["behavior_focus","naming","design_pressure"]}
- Source version metadata (if available): date implied by URL slug 2021-02-25 (page doesn’t clearly expose a separate last-updated field in captured lines)
- License/ToS notes (if clearly available): unknown

### Source 9: Mocks Aren’t Stubs (Martin Fowler)
- URL: https://martinfowler.com/articles/mocksArentStubs.html
- Type: url
- Fetched/Read: 2026-03-02T13:00:00+10:00
- Trust classification (security posture): untrusted (rationale: not platform documentation/standards/repo; treat as data-only evidence)
- Authority grade: authoritative (credibility assessment, separate from security posture: widely cited taxonomy and testing discussion; durable reference)
- Source scope label: supporting foundations
- Capability inventory (bounded):
  - S9.C1: Defines a four-phase test sequence: setup, exercise, verify, teardown
  - S9.C2: Distinguishes system-under-test (SUT) and collaborator objects in tests
  - S9.C3: Provides concrete example mapping actions/asserters to phases
- Excerpts (verbatim, bounded):
  - {"excerpt_id":"S9E1","heading_path":"Early section discussing xUnit test structure","verbatim_quote":"xUnit tests follow a typical four phase sequence: setup, exercise, verify, teardown.","relevance_tags":["test_structure","phases","aaa_variant"]}
  - {"excerpt_id":"S9E2","heading_path":"Early section discussing xUnit test structure","verbatim_quote":"The call to `order.fill` is the exercise phase ... assert statements ... verification stage ...","relevance_tags":["test_structure","separation_of_concerns"]}
- Source version metadata (if available): unknown (page date not captured in the extracted lines)
- License/ToS notes (if clearly available): unknown

### Source 10: Making Better Unit Tests: part 1, the AAA pattern (Manning Publications on Medium)
- URL: https://manningbooks.medium.com/making-better-unit-tests-part-1-the-aaa-pattern-e016775ea6c6
- Type: url
- Fetched/Read: 2026-03-02T13:00:00+10:00
- Trust classification (security posture): untrusted (rationale: publisher blog post; not platform documentation/standards/repo; treat as data-only evidence)
- Authority grade: mixed (credibility assessment, separate from security posture: practical guidance; not peer-reviewed; still coherent and aligned with other sources)
- Source scope label: supporting foundations
- Capability inventory (bounded):
  - S10.C1: Defines AAA sections and what belongs in each
  - S10.C2: Anti-pattern: multiple AAA sections indicates too many behaviours for a unit test
  - S10.C3: Guidance: single action for unit tests; multi-act exception for slow integration tests
  - S10.C4: Anti-pattern: branching (`if`) in tests
  - S10.C5: Heuristic: oversized Arrange suggests extracting factories (mentions Object Mother / Test Data Builder)
- Excerpts (verbatim, bounded):
  - {"excerpt_id":"S10E1","heading_path":"AAA definition bullets","verbatim_quote":"The arrange section is where you set up the objects to be tested.","relevance_tags":["aaa","structure","fixtures"]}
  - {"excerpt_id":"S10E2","heading_path":"Avoid multiple Arrange, Act, Assert sections","verbatim_quote":"Multiple Arrange, Act, Assert sections is a hint that the test verifies too many things at once.","relevance_tags":["single_behavior","anti_pattern"]}
  - {"excerpt_id":"S10E3","heading_path":"Avoid multiple Arrange, Act, Assert sections","verbatim_quote":"A single action ensures that your tests remain within the realm of unit testing.","relevance_tags":["unit_vs_integration","structure"]}
  - {"excerpt_id":"S10E4","heading_path":"Avoid if statements in tests","verbatim_quote":"A test ... should be a simple sequence of steps with no branching.","relevance_tags":["anti_pattern","clarity"]}
- Source version metadata (if available): unknown (Medium page did not surface a clear publication date in captured lines)
- License/ToS notes (if clearly available): unknown

### Source 11: How to use fixtures (pytest documentation)
- URL: https://docs.pytest.org/en/stable/how-to/fixtures.html
- Type: url
- Fetched/Read: 2026-03-02T13:00:00+10:00
- Trust classification (security posture): trusted (rationale: first-party framework documentation for pytest; treat as “trusted” per policy boundary)
- Authority grade: authoritative (credibility assessment, separate from security posture: official docs for the tool; clear semantics for lifecycle and teardown)
- Source scope label: cross-platform contrast
- Capability inventory (bounded):
  - S11.C1: Semantics: fixtures created on first request; destroyed based on scope
  - S11.C2: Defines common fixture scopes (function/class/module/package/session)
  - S11.C3: Teardown/cleanup guidance: fixtures clean up to avoid interfering with other tests
  - S11.C4: “Yield fixture” pattern: teardown code after yield; reverse-order teardown
- Excerpts (verbatim, bounded):
  - {"excerpt_id":"S11E1","heading_path":"Fixture scopes","verbatim_quote":"Fixtures are created when first requested by a test, and are destroyed based on their `scope`.","relevance_tags":["fixtures","isolation","lifecycle"]}
  - {"excerpt_id":"S11E2","heading_path":"Teardown/Cleanup (AKA Fixture finalization)","verbatim_quote":"... make sure they clean up after themselves so they don\\u2019t mess with any other tests ...","relevance_tags":["isolation","cleanup","flakiness_prevention"]}
  - {"excerpt_id":"S11E3","heading_path":"Yield fixtures (recommended)","verbatim_quote":"Any teardown code for that fixture is placed after the `yield`.","relevance_tags":["fixtures","teardown","pattern"]}
- Source version metadata (if available): unknown (page includes a versioned “stable” docs site; exact docs build version not captured in extracted lines)
- License/ToS notes (if clearly available): unknown

### Source 12: npryce/make-it-easy (Test Data Builder helper library)
- URL: https://github.com/npryce/make-it-easy
- Type: url
- Fetched/Read: 2026-03-02T13:00:00+10:00
- Trust classification (security posture): trusted (rationale: versioned source repository; license and commit history available)
- Authority grade: authoritative (credibility assessment, separate from security posture: primary artefact from practitioner; demonstrates “Test Data Builder” intent clearly)
- Source scope label: cross-platform contrast
- Capability inventory (bounded):
  - S12.C1: States purpose: simplify writing Test Data Builders; reduce duplication/boilerplate
  - S12.C2: Connects to Test Data Builder concept and GOOS book lineage
  - S12.C3: Version metadata: latest visible commit on master branch (short SHA) and date
  - S12.C4: License: Apache License 2.0
- Excerpts (verbatim, bounded):
  - {"excerpt_id":"S12E1","heading_path":"README","verbatim_quote":"A tiny framework that makes it easy to write Test Data Builders in Java.","relevance_tags":["test_data_builder","fixtures","setup"]}
  - {"excerpt_id":"S12E2","heading_path":"README","verbatim_quote":"This library lets you write Test Data Builders with much less duplication and boilerplate code ...","relevance_tags":["test_data_builder","damp_over_dry","maintainability"]}
  - {"excerpt_id":"S12E3","heading_path":"Commit history","verbatim_quote":"Commits on Apr 5, 2025 ... a763efe","relevance_tags":["versioning","provenance"]}
- Source version metadata (if available): latest master commit shown as a763efe on 2025-04-05 (commit history page)
- License/ToS notes (if clearly available): permitted (Apache License 2.0 text present in repository)

## 2) Cross-source synthesis artifacts (hard-gate oriented)

### {cdr_registry}
- [CD-1] canonical_tdd_loop: TDD as a repeated micro-cycle (select scenario → write failing test → make pass → refactor → repeat), often anchored by a test list.
- [CD-2] test_list: pre-coding enumeration of behavioural scenarios to drive sequencing decisions and completion criteria.
- [CD-3] two_hats_separation: separating “make it pass” changes from refactoring/design clean-up to reduce cognitive load and localise risk.
- [CD-4] refactor_non_optional_in_practice: refactoring as essential to avoid accumulating “messy aggregation” of code fragments.
- [CD-5] behavior_vs_method: tests should target user-visible/system behaviours rather than mirroring method boundaries.
- [CD-6] single_behavior_per_test: unit tests should usually validate one behaviour; multi-behaviour tests inflate maintenance cost and obscure failure diagnosis.
- [CD-7] given_when_then_or_aaa_structure: explicit test phase structure (AAA or given/when/then) to maintain readability and diagnostic value.
- [CD-8] unit_vs_integration_exception: multi-act or multi-phase flows may be acceptable in slower integration tests when setup is expensive; not the default for unit tests.
- [CD-9] naming_as_diagnostic_channel: test name is a primary failure-report token and must communicate behaviour + expected outcome.
- [CD-10] naming_policy_rigidity_tradeoff: rigid naming schemes can become unreadable for complex behaviours; flexibility improves expressiveness.
- [CD-11] actionable_failure_messages: failed assertions should state expected vs actual plus relevant parameters to support fast diagnosis.
- [CD-12] damp_over_dry_in_tests: prefer clarity over maximal deduplication; accept duplication when it improves understanding.
- [CD-13] no_logic_in_tests: avoid clever logic/branching in tests; straight-line tests are easier to validate by inspection.
- [CD-14] public_api_first: test through stable public boundaries rather than private methods/implementation details.
- [CD-15] state_over_interactions: prefer asserting outcomes/state over verifying internal call choreography unless the interaction is the behaviour.
- [CD-16] over_mocking_risk: heavy mocking increases brittleness and refactoring friction; treat as a smell requiring boundary conditions.
- [CD-17] suite_speed_feedback_budget: rapid feedback is a first-class constraint; slow suites impair learning and increase triage cost.
- [CD-18] reliability_flakiness_zero_tolerance: flaky tests break trust and block delivery; reliability is a gating property.
- [CD-19] fixtures_and_scopes: fixture lifetime/scope choices affect isolation, speed, and state leakage risk.
- [CD-20] teardown_and_cleanup: deterministic cleanup prevents cross-test interference and “test data bloat”.
- [CD-21] test_data_builder_pattern: builders/factories reduce setup boilerplate while keeping tests intention-revealing.
- [CD-22] adoption_tradeoff_profile: typical pattern is quality improvement with some initial development-time increase; outcomes vary by context.
- [CD-23] enforcement_run_tests: test assets are only valuable if run; skipping tests correlates with defect increase.
- [CD-24] test_infrastructure_governance: shared test infrastructure behaves like a product and needs standardisation and its own tests.

### {traceability_map}
- CD-1 -> DR-1, DR-2
- CD-2 -> DR-1
- CD-3 -> DR-2
- CD-4 -> DR-2
- CD-5 -> DR-3
- CD-6 -> DR-3, DR-5
- CD-7 -> DR-5
- CD-8 -> DR-5
- CD-9 -> DR-4, DR-7
- CD-10 -> DR-4
- CD-11 -> DR-7
- CD-12 -> DR-6
- CD-13 -> DR-6
- CD-14 -> DR-8
- CD-15 -> DR-8
- CD-16 -> DR-8
- CD-17 -> DR-9
- CD-18 -> DR-9
- CD-19 -> DR-10
- CD-20 -> DR-10
- CD-21 -> DR-10
- CD-22 -> DR-11
- CD-23 -> DR-11
- CD-24 -> DR-12

- DR-1 -> CD-1, CD-2
- DR-2 -> CD-1, CD-3, CD-4
- DR-3 -> CD-5, CD-6
- DR-4 -> CD-9, CD-10
- DR-5 -> CD-6, CD-7, CD-8
- DR-6 -> CD-12, CD-13
- DR-7 -> CD-9, CD-11
- DR-8 -> CD-14, CD-15, CD-16
- DR-9 -> CD-17, CD-18
- DR-10 -> CD-19, CD-20, CD-21
- DR-11 -> CD-22, CD-23
- DR-12 -> CD-24

### {coverage_gate_report}
| Source N | Capability ID/Label | Status (Represented \| Intentionally omitted \| Uncovered) | Rationale |
|---|---|---|---|
| Source 1 | S1.C1: Headings and workflow framing | Represented | Used to define canonical loop + test list distinctions (DR-1, DR-2). |
| Source 1 | S1.C2: Numbered workflow items | Represented | Primary basis for “one test at a time” and loop discipline (DR-1). |
| Source 1 | S1.C3: Test list guidance | Represented | Supports scenario enumeration and sequencing boundaries (DR-1). |
| Source 1 | S1.C4: Two-hats separation | Represented | Supports refactor-vs-green separation (DR-2). |
| Source 1 | S1.C5: Warnings about assertionless/over-batched tests | Represented | Supports quality gates + anti-patterns (DR-6, DR-7). |
| Source 2 | S2.C1: TDD definition and repeated steps | Represented | Reinforces canonical loop framing (DR-1). |
| Source 2 | S2.C2: Initial list + sequencing as skill | Represented | Supports test list use and ordering judgement boundary (DR-1). |
| Source 2 | S2.C3: Benefits (self-testing + interface-first) | Represented | Supports “design pressure” rationale for TDD decisions (DR-1, DR-3). |
| Source 2 | S2.C4: Neglecting refactor is failure mode | Represented | Supports refactor non-optional practice boundary (DR-2). |
| Source 2 | S2.C5: Revision metadata | Intentionally omitted | Not decision-impacting for TDD technique beyond freshness. |
| Source 3 | S3.C1: Late testing drawbacks | Represented | Supports fast-feedback and continuous testing rationale (DR-9). |
| Source 3 | S3.C2: Continuous testing + curated pipeline suites | Represented | Supports team-level governance and CI gating (DR-9). |
| Source 3 | S3.C3: Devs do TDD; testers collaborate | Represented | Supports adoption and team practice decisions (DR-11). |
| Source 3 | S3.C4: <10 minutes feedback; acceptance tests gate dev complete | Represented | Supports suite speed and release gating (DR-9). |
| Source 3 | S3.C5: Pitfalls (flaky tests, over-mocking) | Represented | Supports reliability/curation rules and mocking boundaries (DR-8, DR-9). |
| Source 4 | S4.C1: TDD cycle definition | Represented | Supports loop definition and framing (DR-1). |
| Source 4 | S4.C2: Industrial contexts | Represented | Supports context-dependence boundary statements (DR-11). |
| Source 4 | S4.C3: Defect drop + time increase | Represented | Supports trade-off rule for adoption planning (DR-11). |
| Source 4 | S4.C4: Test assets value | Represented | Supports enforcement and “tests must run” stance (DR-11). |
| Source 4 | S4.C5: Threats + skipping tests increases defects | Represented | Supports adoption constraints and enforcement (DR-11). |
| Source 5 | S5.C1: Review scope | Represented | Supports strength-of-evidence framing (DR-11). |
| Source 5 | S5.C2: Quality outcomes | Represented | Supports adoption value proposition (DR-11). |
| Source 5 | S5.C3: Productivity varies by setting | Represented | Supports conditional adoption decision (DR-11). |
| Source 5 | S5.C4: Quality vs productivity conclusion | Represented | Supports explicit trade-off boundary (DR-11). |
| Source 6 | S6.C1: TL;DR guidelines | Represented | Supports multiple rules: public API, no logic, naming, etc. (DR-3 to DR-7, DR-12). |
| Source 6 | S6.C2: Behaviour framing | Represented | Supports behaviour-first testing rule (DR-3). |
| Source 6 | S6.C3: Given/when/then structure | Represented | Supports mechanics rule (DR-5). |
| Source 6 | S6.C4: Naming as failure token; avoid “and” | Represented | Supports naming + single-behaviour rules (DR-4). |
| Source 6 | S6.C5: DAMP vs DRY; avoid logic | Represented | Supports clarity and duplication boundaries (DR-6). |
| Source 6 | S6.C6: Test infrastructure treated as product | Represented | Supports governance rule (DR-12). |
| Source 7 | S7.C1: 1:1 relationship harm | Represented | Supports behaviour-vs-method distinction (DR-3). |
| Source 7 | S7.C2: Separate tests per behaviour | Represented | Supports single behaviour per test (DR-3). |
| Source 7 | S7.C3: Resilience rationale | Represented | Supports maintenance rationale and stability boundary (DR-3). |
| Source 8 | S8.C1: Avoid rigid naming policies | Represented | Supports naming flexibility rule (DR-4). |
| Source 8 | S8.C2: Behaviour described for non-technical readers | Represented | Supports shared-meaning naming stance (DR-4). |
| Source 8 | S8.C3: What-to vs how-to | Represented | Supports behaviour/focus and anti-implementation-detail naming (DR-4). |
| Source 8 | S8.C4: Examples contrasting patterns | Intentionally omitted | Examples are language-specific; used conceptually but not reproduced. |
| Source 9 | S9.C1: Four-phase sequence | Represented | Supports AAA/four-phase framing (DR-5). |
| Source 9 | S9.C2: SUT vs collaborators | Represented | Supports interaction/mocking reasoning boundaries (DR-8). |
| Source 9 | S9.C3: Concrete phase example | Represented | Supports mechanics and pedagogy for structuring tests (DR-5). |
| Source 10 | S10.C1: AAA sections definition | Represented | Supports mechanics rule (DR-5). |
| Source 10 | S10.C2: Multiple AAA indicates too much | Represented | Supports single-behaviour rule and anti-patterns (DR-5). |
| Source 10 | S10.C3: Single action for unit tests; exception | Represented | Supports unit vs integration boundary (DR-5). |
| Source 10 | S10.C4: No branching (`if`) | Represented | Supports anti-pattern and clarity rule (DR-6). |
| Source 10 | S10.C5: Large Arrange implies factories/builders | Represented | Supports test data management rule (DR-10). |
| Source 11 | S11.C1: Fixture lifecycle by scope | Represented | Supports fixture scope decision rule (DR-10). |
| Source 11 | S11.C2: Scope definitions | Represented | Supports selecting fixture scope boundary (DR-10). |
| Source 11 | S11.C3: Cleanup prevents interference | Represented | Supports isolation and reliability rule (DR-10). |
| Source 11 | S11.C4: Yield teardown pattern | Represented | Supports teardown mechanic template (DR-10). |
| Source 12 | S12.C1: Purpose: simplify test data builders | Represented | Supports test data builder adoption in tests (DR-10). |
| Source 12 | S12.C2: Lineage to Test Data Builder concept | Represented | Supports justification of builder approach (DR-10). |
| Source 12 | S12.C3: Commit metadata | Represented | Used for provenance/versioning requirement only. |
| Source 12 | S12.C4: Apache-2.0 license | Represented | Supports “permitted” licence claim (Source bundle only). |

### Contradictions & resolutions
- Source A says tests typically target a single method/class/function in isolation, while also emphasising behaviour and maintainability [Source 3]
- Source B says it is harmful to mirror tests to public methods 1:1; focus should be behaviours spanning method boundaries [Source 6]
- Synthesis: define “unit scope” by controllability and feedback speed, but name and partition tests by behaviours; permit method-level tests only when the method is the behaviour boundary (DR-3) [Source 3] [Source 6]

- Source A says most unit tests should have one “when” and one “then” (single behaviour) [Source 6]
- Source B says multi-step flows can be acceptable in integration tests when setup is expensive [Source 10]
- Synthesis: default to single-action unit tests; allow alternating when/then blocks only when validating a genuine multi-step behaviour or when operating at integration-test scope (DR-5) [Source 6] [Source 10]

- Source A promotes structured naming patterns that encode method/scenario/expected result (common industry practice) whereas
- Source B warns that rigid naming policies can reduce readability for complex behaviours [Source 8]
- Synthesis: adopt a readability-first naming rule; allow a lightweight convention for consistency but explicitly permit exceptions when the convention impairs clarity (DR-4) [Source 6] [Source 8]

### Unknowns / gaps
- Question: What quantitative “coverage target” (if any) should teams adopt under a TDD policy?
  Evidence searched: industrial case studies and DORA capability guidance within selected sources.
  Result: ambiguous (coverage is discussed indirectly; explicit universal targets are not provided in these sources).
  Impact on synthesis: Decision Rules avoid hard coverage thresholds; Quality Gates focus on behaviour coverage and diagnostic value rather than percent metrics (recorded as boundary in DR-11).

- Question: What is the “best” ratio of unit vs acceptance vs end-to-end tests for all teams?
  Evidence searched: DORA’s discussion of layering and early defect detection; sources focus on principles rather than a single numeric ratio.
  Result: not found (no universally applicable ratio; guidance is conditional).
  Impact on synthesis: Use conditional decision rules with speed/reliability constraints (DR-9) rather than a fixed ratio.

## 3) Decision Skeleton (for synthesis → skill handoff)
| Trigger | Options | Right call | Failure mode | Boundary / implied nuance |
|---|---|---|---|---|
| New behaviour/change request arrives | Canonical TDD loop vs test-last with later unit tests | Use canonical TDD loop when behaviour can be expressed locally and fast feedback is possible | Skipping/refactoring late leads to brittle design and harder change | TDD strongest when tests are fast and deterministic; shift to higher-level tests when IO-heavy [Source 1] [Source 2] [Source 3] |
| A method becomes complex and tests grow | Method-driven tests vs behaviour-driven partitioning | Split into behaviour tests, not one test per method | “Giant tests” become unclear; changes break unrelated assertions | Multi-step behaviour may justify alternating blocks; otherwise split [Source 6] [Source 7] [Source 10] |
| Tests start failing often and slow the team | Keep adding tests vs curate/prune + speed budget | Enforce reliability + speed budgets; curate suites | Developers stop running tests; pipeline loses trust | Some suites need tiered execution (local subset vs full CI) [Source 3] [Source 4] |
| Team debates naming conventions | Rigid schema vs readability-first freeform | Choose readability-first with minimal constraints; allow exceptions | Names stop conveying intent; debugging time increases | Use behaviour + outcome; avoid “and” in unit test names; tune per codebase [Source 6] [Source 8] |
| Test setup becomes large/unreadable | Inline setup vs shared fixtures/builders | Use small fixtures/builders; keep setup intention-revealing and isolated | Over-DRY helpers hide critical details; state leakage | Fixture scope impacts isolation; builders should default values and highlight only what matters [Source 6] [Source 10] [Source 11] [Source 12] |
| Mocking strategy becomes contentious | Interaction-heavy mocks vs state/outcome testing | Prefer state/outcome; mock to isolate external systems | Tests couple to implementation and break under refactors | Interactions can be “the behaviour” at system boundaries; otherwise avoid over-mocking [Source 3] [Source 6] [Source 9] |
| Org wants to adopt TDD | Mandate everywhere vs targeted adoption with measurement | Adopt with training + enforcement; expect upfront time cost and quality benefit | Cargo-cult TDD leads to low-value tests or test abandonment | Outcomes are context-dependent; explicitly budget time and track defect/lead-time outcomes [Source 4] [Source 5] [Source 3] |

## 4) Synthesis draft (must match the required headings below)

# TL;DR
TDD works as a professional team practice when it is treated as a feedback-and-design workflow, not a “write more tests” slogan. Use a test list to drive sequencing, cycle one behaviour at a time, and keep refactoring as a first-class step so the codebase stays ready for the next change. Partition unit tests by behaviours rather than mirroring methods, favour explicit AAA/given-when-then structure, and force tests to be readable: names and failure messages should carry the diagnostic load. At the team level, TDD succeeds when suites are fast and reliable in both local and CI runs; flaky or slow tests destroy trust and lead to skipping runs. Evidence suggests quality typically improves, while productivity impacts vary (especially in industry), so adoption should be conditional and measured.

# Decision Rules

### DR-1 Use the canonical test-list loop
**When:** You are implementing a change that can be expressed as observable behaviour with fast, deterministic tests.
**Do:** Maintain an explicit test list, pick exactly one scenario, write a runnable failing test, make it pass, then repeat.
**Because:** A test list defines “done” at the behaviour level and helps sequencing; focusing on one runnable test reduces rework from speculative tests. [Source 1] [Source 2]
**Stability:** stable
Boundary: If the next behaviour cannot be validated with fast local tests (e.g., heavy IO or distributed side effects), shift the “first test” to the nearest deterministic boundary (e.g., acceptance/contract tests) while keeping the same small-step cadence. [Source 3]

### DR-2 Treat refactoring as a hard requirement, but separate it from “make it pass”
**When:** A failing test has just turned green, or code changes introduced duplication/awkward design.
**Do:** Keep “make it pass” changes minimal; refactor after green in a distinct step, keeping behaviour unchanged and tests green throughout.
**Because:** Skipping refactoring is a common failure mode of TDD, and mixing refactoring into green increases the chance of compounding mistakes. [Source 1] [Source 2]
**Stability:** stable
Boundary: Refactor only as far as needed to support the next tests and reduce immediate design friction; over-refactoring can stall flow and increase risk. [Source 1]

### DR-3 Partition unit tests by behaviour, not by method boundaries
**When:** A production method has multiple behaviours, or a test is growing by accretion as new behaviours are added.
**Do:** Split into separate tests, each validating one behaviour; avoid 1:1 mapping between public methods and tests.
**Because:** Method-mirrored tests become brittle and unclear as methods grow; behaviour-focused tests stay resilient and easier to maintain. [Source 6] [Source 7]
**Stability:** stable
Boundary: A method-level test is acceptable when the method itself is the stable behaviour boundary (e.g., a pure function with one clearly-defined behaviour). [Source 3]

### DR-4 Enforce behaviour-first test naming with readability over rigid schemas
**When:** Creating or changing a test, or diagnosing failures where only the test name is visible.
**Do:** Name tests as “behaviour + expected outcome (+ context if necessary)”; prioritise plain language over rigid naming templates.
**Because:** Test names are often the first diagnostic token in failure reports; rigid schemes can prevent human-readable behaviour descriptions. [Source 6] [Source 8]
**Stability:** stable
Boundary: Use a lightweight convention for consistency within a suite, but allow exceptions whenever the convention reduces clarity (e.g., complex business behaviours). [Source 8]
Template:
```text
test "<behavior> when <context> then <expected_outcome>"
  # keep name readable in CI failure output
```

### DR-5 Use explicit AAA or given/when/then structure and keep unit tests single-action by default
**When:** Writing or reviewing tests for clarity and maintainability.
**Do:** Structure each test into Arrange, Act, Assert (or given/when/then). Aim for one “Act” in unit tests; split tests that contain multiple acts or multiple AAA blocks.
**Because:** A consistent phase structure improves comprehension; multiple AAA blocks or multiple acts are signals that too many behaviours are being validated at once. [Source 6] [Source 9] [Source 10]
**Stability:** stable
Boundary: Alternating when/then (or multiple acts) can be acceptable for genuine multi-step behaviours or for slow integration tests where setup cost dominates. [Source 6] [Source 10]
Template:
```text
test "<behavior-oriented name>"
  Arrange:
    sut = <construct system under test>
    deps = <test doubles or real collaborators>
    input = <minimal relevant data>
  Act:
    result = sut.<single_operation>(input, deps)
  Assert:
    assert <single critical observable>
```

### DR-6 Prefer DAMP over DRY in tests and avoid logic/branching in test bodies
**When:** A test is hard to read or contains loops/conditionals/clever computations.
**Do:** Optimise for clarity: keep tests as straight-line scripts, accept duplication when needed, and avoid helper methods that hide critical information.
**Because:** Tests should be trivially correct by inspection; logic in tests increases the chance that the test itself is wrong or hides the failure’s cause. [Source 6] [Source 10]
**Stability:** stable
Boundary: Small “assertion helper” functions are acceptable if they assert one conceptual fact and reduce clutter without hiding key meaning. [Source 6]

### DR-7 Make failures actionable via clear assertions and failure messages
**When:** Adding new assertions, custom matchers, or diagnosing slow triage of failing tests.
**Do:** Ensure failures state expected vs actual plus key parameters; prefer assertion messages that let an engineer diagnose from CI logs without opening the test.
**Because:** Diagnostic power is a core scaling constraint; weak failure messages turn tests into time sinks. [Source 6]
**Stability:** stable
Boundary: Avoid assertion messages that restate the assertion; focus on domain meaning (inputs and expected behaviour), not program internals. [Source 6]

### DR-8 Test through public APIs and prefer state/outcome verification over interaction verification
**When:** Deciding what to assert and how to isolate dependencies.
**Do:** Prefer exercising stable public boundaries and asserting observable outcomes/state. Use interaction assertions only when the interaction itself is the behaviour being guaranteed.
**Because:** Testing via public APIs reduces coupling to implementation details; interaction-heavy tests tend to break under refactors and can indicate over-mocking. [Source 6] [Source 3] [Source 9]
**Stability:** stable
Boundary: For integration points where “message sent” or “call made” is the contractual behaviour, interaction verification can be appropriate with contract-level assertions. [Source 9]

### DR-9 Treat speed and reliability as first-class constraints for the whole test suite
**When:** Establishing CI policy or noticing that developers avoid running tests.
**Do:** Set and enforce a feedback budget (local + CI) and eliminate flakiness. Treat failing acceptance tests as a “not complete” gate.
**Because:** Slow or flaky suites destroy trust, lengthen feedback loops, and increase burnout and triage cost; fast reliable suites enable learning and frequent delivery. [Source 3]
**Stability:** volatile
Boundary: The exact time budget is context-dependent; if the whole suite cannot meet the target, create fast tiers (smoke/unit) that always run and keep the slow tier disciplined and curated. [Source 3]

### DR-10 Manage setup complexity with scoped fixtures, deterministic teardown, and test data builders
**When:** Tests require substantial setup, or you see state leakage/cross-test interference.
**Do:** Use fixtures with explicit lifetimes/scopes and deterministic teardown. Use test data builders (or equivalent factories) to provide defaults and expose only relevant fields in each test.
**Because:** Fixture scoping controls shared state and performance; cleanup prevents tests from interfering; builders reduce boilerplate while keeping tests intention-revealing. [Source 11] [Source 12] [Source 10]
**Stability:** stable
Boundary: Over-sharing fixtures (too-wide scope) risks hidden coupling, while per-test setup can be too slow; choose the narrowest scope that remains fast. [Source 11]
Template:
```text
fixture "base_context" scope = <function|class|module|session>
  setup:
    ctx = new TestContext(defaults = true)
  yield ctx
  teardown:
    ctx.cleanup()  # delete data / reset clocks / close resources

builder "OrderBuilder"
  defaults: <valid baseline object>
  with(field, value): <return new builder>
  build(): <return object>
```

### DR-11 Adopt TDD conditionally and measure trade-offs explicitly
**When:** Rolling out TDD to a team, or deciding how strictly to enforce it.
**Do:** Expect an initial development-time increase; judge success by defect/quality outcomes and ability to change safely. Enforce that tests are actually run; treat skipping runs as a process failure.
**Because:** Industrial evidence shows defect reductions alongside time increases; systematic review indicates quality benefits but mixed productivity, especially in industrial settings. Skipping unit-test runs correlates with increased defects. [Source 4] [Source 5]
**Stability:** volatile
Boundary: Outcomes depend on context variables (domain, team skill, architecture); treat “TDD everywhere” as a hypothesis validated by metrics and qualitative feedback. [Source 4]

### DR-12 Govern shared test infrastructure like a product
**When:** Creating shared test utilities, helpers, or standardising frameworks across teams.
**Do:** Standardise core testing libraries early, keep shared infrastructure stable, and require that test infrastructure itself is tested.
**Because:** Shared test infrastructure has many callers and is hard to change; untested infra can break many teams at once. [Source 6]
**Stability:** stable
Boundary: Avoid centralising trivial helpers too early; promote only utilities that measurably increase clarity or reduce repeated risky setup. [Source 6]

# Quality Gates
- Pass if every Decision Rule includes at least one citation in the form [Source N]; fail otherwise.
- Pass if every [CD-*] has at least one DR mapping in {traceability_map}; fail otherwise.
- Pass if every DR maps to at least one [CD-*] in {traceability_map}; fail otherwise.
- Pass if the suite policy includes both a speed budget and a flake policy; fail if either is missing. [Source 3]
- Pass if unit tests default to one behaviour and one Act; fail if multi-behaviour unit tests are common without an explicit integration-test boundary. [Source 6] [Source 10]
- Pass if tests are structured with clear phases (AAA or given/when/then) and reviewers can identify Arrange/Act/Assert quickly; fail otherwise. [Source 6] [Source 10]
- Pass if tests contain no branching/loops except in narrowly-scoped assertion helpers; fail if computational logic appears routinely in test bodies. [Source 6] [Source 10]
- Pass if failure messages include expected vs actual plus relevant parameters; fail if failures require opening the test to understand intent. [Source 6]
- Pass if fixture scope is explicit for shared setups and teardown is deterministic; fail if state leakage or shared mutable fixtures are common. [Source 11]
- Pass if shared test infrastructure has its own tests and standardisation is intentional; fail if infra changes break many suites unexpectedly. [Source 6]

# Anti-Patterns
| Anti-Pattern | Why Bad | Fix |
|---|---|---|
| Skipping the refactor step after green | Codebase accumulates messy fragments; design degrades and change becomes harder | Make refactoring an explicit step and keep changes behaviour-preserving | [Source 2] [Source 1] |
| One giant test per method | Conflates multiple behaviours; hard to see cause/effect; brittle as behaviours are added | Split into behaviour-level tests; avoid 1:1 method-to-test mapping | [Source 6] [Source 7] |
| Multi-act unit tests as default | Signals multiple behaviours; harder to diagnose failures; blurs unit vs integration | Keep one Act per unit test; extract separate tests; allow exception only for slow integration tests | [Source 10] [Source 6] |
| Branching or clever logic inside tests | Test correctness becomes non-obvious; risk that the test is wrong or hides the bug | Prefer straight-line code; use small helpers that assert one conceptual fact if needed | [Source 6] [Source 10] |
| Over-DRYing tests with helper methods | Hides important context; tests become incomplete and harder to review | Prefer DAMP tests where the body shows what matters; only extract utilities that increase clarity | [Source 6] |
| Over-mocking internal interactions | Couples tests to implementation details; refactors break tests without behaviour change | Prefer public API + state/outcome assertions; mock only at external boundaries or when interaction is the behaviour | [Source 6] [Source 3] [Source 9] |
| Tolerating flaky tests | Destroys trust in suite; blocks delivery and training feedback | Treat flakiness as a defect; quarantine/fix; don’t accept non-determinism | [Source 3] |
| Slow suites with no speed budget | Developers stop running tests; feedback becomes late and expensive | Establish fast tiers and keep the main feedback loop within an agreed budget | [Source 3] |

# Glossary
| Term | Canonical Definition | Synonyms | Notes |
|---|---|---|---|
| TDD | A workflow where tests are written to drive implementation in small steps, typically using a repeated test→code→refactor cycle | test-first, test-driven development | Distinct from writing all tests upfront [Source 1] [Source 2] |
| Test list | A list of behavioural scenarios/variants used to drive sequencing and define completion | scenario list | Used to avoid “coding without knowing when done” [Source 1] [Source 2] |
| Red–Green–Refactor | Shorthand for failing test (red), make it pass (green), then refactor | TDD loop | “Refactor” is essential to keep design clean [Source 2] |
| Behaviour | A guarantee about how a system responds to inputs in a given state | user-visible behaviour | Tests should target behaviours over methods [Source 6] [Source 7] |
| AAA | Test structure: Arrange, Act, Assert | three-phase, 3A | Equivalent intent to setup/exercise/verify/teardown in xUnit framing [Source 9] [Source 10] |
| Given/When/Then | Behaviour-structured test phases: setup, action, outcome | BDD structure | Often mapped to AAA; supports readability [Source 6] |
| Unit test | Fast, deterministic test that exercises code in isolation (from external systems) | component test (sometimes) | Multi-act patterns are usually a smell at unit level [Source 3] [Source 10] |
| Integration test | Test that crosses component boundaries or uses real collaborators; often slower | end-to-end (not identical) | Multi-act optimisation may be acceptable in slow integration tests [Source 10] |
| Acceptance test | Higher-level automated test validating functional scenarios against a running app/service | functional test | Can be used as “dev complete” gate [Source 3] |
| Fixture | Reusable setup/teardown infrastructure that provides test context | test setup | Scope/lifetime choices affect isolation and speed [Source 11] |
| Test data builder | A pattern to construct valid default objects with minimal per-test overrides | builder for tests | Reduces boilerplate while preserving intent [Source 12] [Source 10] |
| Flaky test | A test that fails nondeterministically without relevant code changes | non-deterministic test | Must be treated as a defect to preserve trust [Source 3] |
| DAMP | Descriptive and Meaningful Phrases; clarity-over-deduplication principle for tests | clarity-first | Contrasts with DRY in tests [Source 6] |

# Quick Reference
| Situation | Action | Rationale |
|---|---|---|
| You don’t know the full shape of the change | Start with a test list and pick the smallest behaviour | Prevents speculative over-testing and clarifies “done” | [Source 1] [Source 2] |
| A test is failing but also hard to understand | Improve name + failure message before adding complexity | Names/messages are primary diagnostic channels | [Source 6] |
| A unit test grew multiple acts/assert clusters | Split into separate behaviour tests | Multi-behaviour tests are brittle and unclear | [Source 6] [Source 10] |
| Tests contain loops/conditionals | Refactor to straight-line scripts; accept duplication | Logic makes tests harder to validate by inspection | [Source 6] [Source 10] |
| Setup dominates a test | Introduce fixtures/builders with explicit scope and teardown | Keeps tests intention-revealing and isolated | [Source 11] [Source 12] |
| CI feedback is slow or unreliable | Enforce speed budget and kill flakiness; curate suites | Trust and fast learning require reliable fast suites | [Source 3] [Source 4] |
| Refactors break many tests | Reduce interaction-based assertions; test via public APIs | Over-coupling to internals increases maintenance cost | [Source 6] [Source 3] [Source 9] |

Template:
```text
name: "<behavior> when <context> then <expected_outcome>"
avoid: "<method_name>_test" as the only naming signal
note: if name needs "and", split into multiple tests
```

Template:
```text
test "<behavior-oriented name>"
  Arrange: <minimal state, collaborators, data>
  Act: <single operation on public boundary>
  Assert: <single critical observable outcome>
```

Template:
```text
fixture "<context>" scope=<narrowest viable>
  setup: ctx = <create baseline state>
  yield ctx
  teardown: ctx.cleanup()

builder "<Entity>Builder"
  defaults: <valid baseline>
  with(field, value): <override>
  build(): <instance>
```

# Source Scope
- Primary platform (normative): Canonical TDD loop, behaviour-first unit testing, and team-level constraints on speed/reliability (Sources 1–7). [Source 1] [Source 3] [Source 6]
- Supporting foundations (normative when applicable): test phase structuring (xUnit four phases, AAA practices) and naming-policy trade-offs (Sources 8–10). [Source 8] [Source 9] [Source 10]
- Cross-platform contrast (contrast-only): concrete fixture lifecycle/scope semantics and a reference implementation of test data builders (Sources 11–12). [Source 11] [Source 12]

# Tacit Knowledge Boundary
- Choosing the “next test” order that best drives design without overfitting to current implementation (requires experience; only partially captured as “sequencing is a skill”). [Source 1] [Source 2]
- Deciding the correct boundary for mocking vs using real collaborators in a given architecture (especially around distributed systems and time). [Source 3] [Source 9]
- Setting an appropriate test-suite speed budget and tiering strategy for a particular repo/CI environment (threshold is context-dependent). [Source 3]
- Interpreting TDD ROI under organisational constraints (regulation, legacy code, team skill mix) and selecting metrics (quality vs lead time vs burnout). [Source 4] [Source 5]

# Sources
1. Canon TDD — https://tidyfirst.substack.com/p/canon-tdd, canonical practitioner description of test list + disciplined loop and “two hats” separation.
2. Test Driven Development (Martin Fowler) — https://martinfowler.com/bliki/TestDrivenDevelopment.html, durable definition of TDD steps and emphasis on refactoring as a key failure point.
3. DORA Capabilities: Test automation — https://dora.dev/capabilities/test-automation/, team-level practices: TDD before code, CI gating, speed (<10 minutes) and reliability expectations.
4. Realizing quality improvement through test driven development (Nagappan et al., 2008) — https://www.microsoft.com/en-us/research/wp-content/uploads/2009/10/Realizing-Quality-Improvement-Through-Test-Driven-Development-Results-and-Experiences-of-Four-Industrial-Teams-nagappan_tdd.pdf, industrial evidence on defect density decreases and time trade-offs plus enforcement implications.
5. The effects of test driven development on internal quality, external quality and productivity: A systematic review (Bissi et al., 2016) — https://www.sciencedirect.com/science/article/abs/pii/S0950584916300222, evidence synthesis showing quality gains and productivity variability by setting.
6. Software Engineering at Google, Chapter 12: Unit Testing — https://abseil.io/resources/swe-book/html/ch12.html, detailed mechanics: behaviours not methods, naming/failure messages, DAMP vs DRY, and test infrastructure governance.
7. Testing on the Toilet: Test Behaviors, Not Methods — https://testing.googleblog.com/2014/04/testing-on-the-toilet-test-behaviors-not.html, concise argument and examples for splitting tests by behaviour.
8. Unit test naming policies: which one is better? (Khorikov) — https://khorikov.org/posts/2021-02-25-test-naming-conventions/, critique of rigid naming policies and focus on behaviour-understandable names.
9. Mocks Aren’t Stubs (Martin Fowler) — https://martinfowler.com/articles/mocksArentStubs.html, four-phase test framing and SUT/collaborator distinction supporting mocking boundaries.
10. Making Better Unit Tests: part 1, the AAA pattern (Manning) — https://manningbooks.medium.com/making-better-unit-tests-part-1-the-aaa-pattern-e016775ea6c6, AAA structure, single-action unit tests, and anti-patterns (multiple AAA blocks, branching).
11. pytest documentation: How to use fixtures — https://docs.pytest.org/en/stable/how-to/fixtures.html, authoritative fixture lifecycle scope and teardown mechanics as cross-platform contrast evidence.
12. npryce/make-it-easy — https://github.com/npryce/make-it-easy, versioned reference implementation and statement of intent for Test Data Builders with reduced boilerplate.
