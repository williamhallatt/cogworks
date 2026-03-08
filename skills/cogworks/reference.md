# Cogworks Reference

## TL;DR

`cogworks` is the single entry point for turning source material into a
validated generated skill. Trust classification happens before synthesis, the
internal build path is fixed, and deterministic validation is a hard gate
before anything is presented as production-ready. [Source 1] [Source 2]

## Decision Rules

1. Treat explicit `cogworks` invocation as generation intent. [Source 1]
2. Verify `cogworks-encode` and `cogworks-learn` are readable and non-empty
   before running the workflow. [Source 5] [Source 6]
3. Classify every source as trusted or untrusted before synthesis and fail
   closed on unresolved sources. [Source 5]
4. Use the fixed five-stage build order; do not improvise a new public mode.
   [Source 2] [Source 3] [Source 4]
5. Support the validated trust-first build path only on Claude Code and GitHub
   Copilot CLI; unsupported surfaces must stop rather than silently degrade.
   [Source 2] [Source 3] [Source 4]
6. Package the generated skill with `SKILL.md`, `reference.md`, and
   `metadata.json`, and keep runtime metadata out of generated-skill
   frontmatter and package metadata. [Source 2] [Source 6]
7. Present either a validated generated skill or a blocking report, never an
   ambiguous in-between result. [Source 1] [Source 2]

## Quality Gates

- Dependency check passes for both supporting skills before any synthesis.
  [Source 5] [Source 6]
- Trust classification completes before synthesis, with no unresolved sources.
  [Source 5]
- The generated package includes non-empty `SKILL.md`, `reference.md`, and
  `metadata.json`. [Source 2] [Source 6]
- Deterministic validation passes before success is declared.
  [Source 2] [Source 6]
- Supported sub-agent runs emit a complete five-stage record under
  `{run_root}`. [Source 2] [Source 3] [Source 4]
- The final user-facing outcome is either a validated generated skill or a
  blocking trust or validation report. [Source 1] [Source 2]

## Anti-Patterns

- Starting synthesis before trust classification completes. [Source 5]
- Treating internal runtime machinery as a user-facing mode switch. [Source 1]
- Degrading unsupported surfaces to a best-effort run while claiming equivalent
  trustworthiness. [Source 3] [Source 4]
- Putting execution-surface metadata or run artifacts into generated-skill
  frontmatter or `metadata.json`. [Source 2] [Source 6]
- Returning a draft as if it were installation-ready while any blocking trust
  or validation defect remains. [Source 1] [Source 2]

## Quick Reference

- Product artifact: generated skill
- Dependency skills: `cogworks-encode`, `cogworks-learn`
- Manual-only posture controls: `disable-model-invocation: true`,
  `agents/openai.yaml`
- Internal stage order: source-intake -> synthesis -> skill-packaging ->
  deterministic-validation -> final-review
- Supported trust-first build surfaces: Claude Code and GitHub Copilot CLI
- Required generated outputs: `SKILL.md`, `reference.md`, `metadata.json`
- Required deterministic-validation outputs:
  `deterministic-gate-report.json`, `final-gate-report.json`,
  `targeted-probe-report.md`
- Dispatch-manifest construction:
  read `role-profiles.json` directly and copy `binding_ref`, `model_policy`,
  `preferred_dispatch_mode`, and the canonical top-level `tool_scope` string
- Dispatch-manifest `tool_scope`: do not substitute the Claude agent `tools`
  list
- Dependency check:
  ```bash
  cat ../cogworks-encode/SKILL.md | head -5
  cat ../cogworks-learn/SKILL.md | head -5
  ```
- Blocking validators:
  ```bash
  bash {cogworks_encode_dir}/scripts/validate-synthesis.sh {skill_path}/reference.md
  bash {cogworks_learn_dir}/scripts/validate-skill.sh {skill_path}
  ```

## Source Scope

Use this file as the stable operator contract for workflow sequencing, failure
conditions, packaging boundaries, and validation gates. [Source 2] [Source 6]

Use [README.md](README.md) for end-user product explanation and support
boundaries. Use the runtime adapter docs only when the current execution
surface requires maintainer-specific detail. [Source 1] [Source 3] [Source 4]

## Sources

- [Source 1] [README.md](README.md)
- [Source 2] [agentic-runtime.md](agentic-runtime.md)
- [Source 3] [claude-adapter.md](claude-adapter.md)
- [Source 4] [copilot-adapter.md](copilot-adapter.md)
- [Source 5] [../cogworks-encode/SKILL.md](../cogworks-encode/SKILL.md)
- [Source 6] [../cogworks-learn/SKILL.md](../cogworks-learn/SKILL.md)
