# history.md

## Learnings

**2026-03-08 — D2 Extension: Agentic Dispatch Security Audit**

Completed comprehensive audit of the agentic dispatch attack surface per charter extension mandate. Key findings:

1. **Attack Surface Mapped** — Three trust boundaries exist in the source flow: pre-intake (user → coordinator), at-intake (coordinator → intake-analyst), post-intake (manifest → synthesizer). The at-intake boundary is a specification without enforcement.

2. **Delimiter Bypass Opportunity Confirmed** — A malicious source containing `<</UNTRUSTED_SOURCE>>` could break out of the delimiter block if the source is not flagged as untrusted during intake. cogworks-encode escaping (M2) works only if upstream classification is accurate.

3. **Gap Characterized** — The coordinator has responsibility to classify sources before dispatch, but: (a) there is no mandatory classification schema in dispatch-manifest.json, (b) there is no pre-dispatch validation gate, (c) there is no audit trail of classification decisions.

4. **Hardening Proposal Written** — Proposed a three-point mitigation: (1) pre-dispatch classification gate in coordinator, (2) intake-level validation gate in intake-analyst, (3) mandatory audit trail in dispatch-manifest.json. Detailed implementation phases: Phase 1 (docs), Phase 2 (runtime enforcement), Phase 3 (validation tests), Phase 4 (learning). Severity: HIGH — blocks third-party platform shipping.

5. **Prerequisite for Third-Party Shipping** — This gate closes the only unmitigated boundary in the agentic dispatch path. cogworks-encode and cogworks-learn provide other layers; this gate ensures classification decisions are made at the boundary, auditable, and cannot be bypassed.

**2026-03-04 — Gap Closure Round 3: M2 & M9 Completion**

Closed two critical security gaps from self-knowledge audit:

1. **M2 — Deterministic Delimiter Escape** — Deterministic preprocessing replaces delimiter tags with neutral tokens before wrapping. See D-020.

2. **M9 — Extended Post-Generation Injection Scan** — Prior check only flagged delimiter leakage. Extended `cogworks-learn/SKILL.md` item 10 to also detect: prompt-override phrases ("ignore prior", "ignore previous"), standalone agent imperative directives ("you must", "you should always", "always do", "never do"), tool call syntax not belonging to skill delimiters. All checks case-insensitive pattern matches; user confirmation required before write if triggered.


**2026-03-08 — Post-Review Fan-Out (Security Hardening)**

Ash proposed P0-tier dispatch security hardening with four layers: input validation (schema enforcement), artifact integrity (signatures), dispatch isolation (privilege separation), output verification (deterministic checks). 1-week core timeline + 2-3 weeks full suite. Proposals consolidated into decisions.md pending approval.

**Cross-references:** Ripley prioritized as P0; depends on Dallas's skeleton ownership fix and Lambert's glossary. Ash/Dallas/Lambert are critical path for Phase 1 (Weeks 1-2 parallel spec hardening + Weeks 3-4 security foundation).

