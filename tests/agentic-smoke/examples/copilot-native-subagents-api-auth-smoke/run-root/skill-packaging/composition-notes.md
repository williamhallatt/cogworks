# Composition Notes

**Stage:** skill-packaging
**Skill:** api-auth-smoke
**Surface:** copilot-cli
**Execution style:** sub-agent build

---

## Source Fidelity

Both synthesis sources (`src-01`, `src-02`) are `internal/trusted`. No derivative risk. No contradictions. The entity-map and contradiction-log were both clean — contradiction count is zero. One near-miss tension (expired/malformed token 401 vs 403) was fully resolved by src-02 explicit language prior to this stage.

---

## Decision Mapping

Five decisions were extracted from the entity-map and encoded in `decision-skeleton.json`:

| ID | Weight | Entity Refs |
|----|--------|-------------|
| dec-01 | required | ent-http-401, ent-authn-failure |
| dec-02 | required | ent-http-403, ent-authz-failure |
| dec-03 | conditional-required | ent-www-authenticate, ent-http-401 |
| dec-04 | recommended | ent-token-lifecycle |
| dec-05 | required | ent-authn-failure, ent-authz-failure |

Decisions dec-01, dec-02, and dec-05 are rendered as normative rule blocks in SKILL.md.
Decision dec-03 is rendered as a conditional norm (`when … then …` structure).
Decision dec-04 is rendered as a best-practice advisory note, explicitly differentiated from normative text.

---

## SKILL.md Composition Choices

- **YAML frontmatter** includes `name`, `description`, `version`, and `sources`.
- **Structure:** Overview → Core Rules (normative) → Conditional Rules → Best Practices → Out-of-Scope → Quick-Reference Table.
- The 401/403 boundary is foregrounded as the primary decision rule because both sources assert it with equal normative weight.
- Expired and malformed token cases are called out explicitly in a dedicated warning block, honouring the synthesis note that "returning 403 for expired or malformed tokens is treated as incorrect behaviour."
- The documentation obligation (dec-05) is honoured: the skill's own explanatory text clearly separates authentication failure from authorization failure throughout.
- Coverage gaps from synthesis are surfaced verbatim in an Out-of-Scope section to prevent false completeness assumptions.

---

## reference.md Composition Choices

- Citations use `[Source 1]` and `[Source 2]` labels mapped to `src-01` and `src-02` respectively.
- Each normative claim is traced to at least one source citation.
- No claim is introduced that lacks a source trace.

---

## Deviations and Suppressions

None. All decisions from the entity-map are represented in the packaged skill. No synthesis claims were suppressed. No new claims were introduced.

---

## Stage Assessment

**Status: PASS** — all required artifacts written; content is structurally complete, source-faithful, and normatively differentiated.
