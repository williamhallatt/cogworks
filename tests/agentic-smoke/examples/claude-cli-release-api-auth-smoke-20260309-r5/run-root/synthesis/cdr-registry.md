# Contradictions, Derivatives, and Resolution Registry

## Contradictions

**None detected.**

Both sources consistently distinguish authentication failures (401) from authorization failures (403). There are no conflicting guidance items across the source set.

## Derivative Relationships

### Source 2 extends Source 1

**Relationship type**: Conceptual extension

**Authority**: Source 1 establishes the fundamental 401/403 distinction. Source 2 applies this distinction to specific token lifecycle scenarios.

**Derivative claims in Source 2**:
- "Reject expired tokens with `401`" - applies Source 1's authentication failure rule to expired tokens
- "Do not use `403` for expired or malformed tokens" - reinforces Source 1's distinction by explicitly covering edge cases

**Resolution strategy**: Source 2 does not contradict Source 1; it specializes the general rules to token-specific scenarios. Both sources should be cited when discussing token expiration or malformation to show the conceptual lineage.

## Entity Boundaries

### Internal test fixture domain

**Boundary**: Both sources originate from the same test fixture directory (`tests/agentic-smoke/fixtures/api-auth-smoke/`) and represent a single controlled knowledge domain.

**Coherence**: The sources form a coherent unit of guidance on API authentication and authorization semantics. They do not represent competing perspectives or external authorities.

**Implication for synthesis**: These sources can be unified into a single skill without cross-entity conflict resolution. No boundary preservation logic is required in downstream skill packaging.

## Resolution Strategies

### For skill generation

**Strategy**: Unified synthesis with tiered specificity
- Present Source 1's foundational distinction (401 vs 403)
- Layer Source 2's token lifecycle specializations on top
- Cite both sources to preserve traceability

**No conflict resolution needed**: The sources are mutually reinforcing, not contradictory.
