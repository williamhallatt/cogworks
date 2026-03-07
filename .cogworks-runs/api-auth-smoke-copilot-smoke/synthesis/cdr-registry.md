# CDR Registry — api-auth-smoke

Contradiction/Decision Registry for the synthesis stage.

## Contradictions

| ID | Sources | Description | Resolution |
|----|---------|-------------|------------|
| — | — | No contradictions found in source set | — |

Contradiction count: 0

## Near-Miss Tensions Resolved

| Description | Source A | Source B | Resolution |
|-------------|----------|----------|------------|
| Expired/malformed token response code | src-01 (implicit 401) | src-02 (explicit 401 for expired/malformed) | src-02 refines src-01; mutually consistent |

## Decisions Made During Synthesis

| ID | Decision | Rationale |
|----|----------|-----------|
| SYN-001 | 401 for all token failure variants | Both sources agree; src-02 explicitly closes edge cases |
| SYN-002 | 403 strictly for post-auth permission failures | Both sources independently support strict 403 scope |
| SYN-003 | WWW-Authenticate as conditional norm | src-01 only; no conflict; conditional on auth scheme |
| SYN-004 | Short-lived tokens as advisory best practice | src-02 only; lower normative weight than error-response rules |
| SYN-005 | Document auth/authz distinction obligation | src-02 meta-claim; applies to skill packaging output |
