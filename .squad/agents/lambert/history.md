# history.md

## Learnings

### Round 2: Compatibility Documentation & Schema (2026-03-10)

**Core Skills Hash Tracking (Issue #12)**
- Proposed `core_skills_hash` field in `skills-lock.json` to detect unintentional drift of cogworks core
- Hash computed from combined SKILL.md of three core skills (lexicographic sort)
- Agent integration: warn on mismatch but don't block; support override flag
- Migration path: compute + jq + commit pattern for existing lock files
- Future-proofed schema versioning model defined

**Codex Behavioral Capture Pipeline (Issue #10)**
- Codex lacks auto-loading (no `.claude/skills/` symlink equivalence); skills must be explicitly injected
- Behavioral traces are inherently non-deterministic; evaluator uses structural/semantic checks, not byte-for-byte
- Capture format: JSON in `tests/behavioral/{skill}/traces/{case_id}.json` + JSONL test registry
- Key fields: `skill_slug`, `case_id`, `activation_source`, `model`, `trace_source`, quality metadata
- Non-determinism handling: BLEU/ROUGE scoring + manual quality gates in shared evaluator

**AGENTS.md vs CLAUDE.md Deduplication (Issue #19)**
- Files are currently byte-for-byte identical (verified via diff)
- No Claude-specific sections exist in AGENTS.md that would warrant divergence
- Auto-loading & live-edit hazard already documented in both
- Recommendation: CLAUDE.md → minimal pointer to AGENTS.md with optional 2-line preamble
- Expert subtraction principle applied: remove duplication, retain discoverability

**2026-03-03 — Team coordination notes**

- Dallas implemented complementary pipeline guards (M5, M11, D3, D7) addressing overwrite protection, cross-source synthesis validation, CDR completeness, and convergence risk.
- Ash implemented security guards (D2, D1, D1) addressing escalation boundaries, stale skill detection, and intent clarification.
- Ripley implemented quality calibration gate (D4) in cogworks-encode Self-Verification to detect superficial synthesis.
- Hudson added generalization probe and edge case tests (D8) plus pre-release CI gate to catch circular verification failures.
