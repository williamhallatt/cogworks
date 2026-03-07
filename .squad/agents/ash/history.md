# history.md

## Learnings

**2026-03-04 — Gap Closure Round 3: M2 & M9 Completion**

Closed two critical security gaps from self-knowledge audit:

1. **M2 — Deterministic Delimiter Escape** — Deterministic preprocessing replaces delimiter tags with neutral tokens before wrapping. See D-020.

2. **M9 — Extended Post-Generation Injection Scan** — Prior check only flagged delimiter leakage. Extended `cogworks-learn/SKILL.md` item 10 to also detect: prompt-override phrases ("ignore prior", "ignore previous"), standalone agent imperative directives ("you must", "you should always", "always do", "never do"), tool call syntax not belonging to skill delimiters. All checks case-insensitive pattern matches; user confirmation required before write if triggered.

