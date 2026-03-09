# Traceability Map

## Synthesis Claims to Source Provenance

### Decision Rules Section

| Synthesis Claim | Source | Line/Section |
|-----------------|--------|--------------|
| Use 401 for missing authentication token | src-001 | Line 3: "when the caller has not authenticated or their token is missing" |
| Use 401 for invalid authentication token | src-001 | Line 3: "or their token is...invalid" |
| Use 401 for expired authentication token | src-002 | Line 3: "reject expired tokens with `401`" |
| Use 401 for malformed authentication token | src-002 | Line 5: "Do not use `403` for expired or malformed tokens" |
| Use 403 when authenticated but lacks permission | src-001 | Line 5: "when the caller is authenticated but lacks permission for the resource" |
| Return WWW-Authenticate headers with 401 | src-001 | Line 7: "Return `WWW-Authenticate` headers with `401` responses" |
| WWW-Authenticate when auth scheme requires retry | src-001 | Line 7: "when the auth scheme requires the client to retry with credentials" |
| Prefer short-lived access tokens | src-002 | Line 3: "Prefer short-lived access tokens" |

### Anti-Patterns Section

| Anti-Pattern | Source | Line/Section |
|--------------|--------|--------------|
| Do not use 403 for expired tokens | src-002 | Line 5: "Do not use `403` for expired or malformed tokens" |
| Do not use 403 for malformed tokens | src-002 | Line 5: "Do not use `403` for expired or malformed tokens" |
| Do not conflate authentication and authorization | src-002 | Line 5: "those are authentication failures, not authorization failures" |

### Quick Reference Table

| Table Row | Source(s) | Derivation |
|-----------|-----------|------------|
| Missing token → 401 + WWW-Authenticate | src-001 | Lines 3, 7 |
| Invalid token → 401 + WWW-Authenticate | src-001 | Lines 3, 7 |
| Expired token → 401 + WWW-Authenticate | src-002, src-001 | src-002 line 3, src-001 line 7 |
| Malformed token → 401 + WWW-Authenticate | src-002, src-001 | src-002 line 5, src-001 line 7 |
| Valid token, no permission → 403 | src-001 | Line 5 |

## Source Coverage Analysis

### Source 1 (01-status-codes.md)

**Coverage in synthesis**: High
- Cited 6 times in Decision Rules
- Cited 5 times in Quick Reference
- Forms foundation for 401/403 distinction

**Uncovered content**: None - all substantive claims incorporated

### Source 2 (02-token-handling.md)

**Coverage in synthesis**: High
- Cited 5 times in Decision Rules
- Cited 3 times in Anti-Patterns
- Cited 2 times in Quick Reference
- Extends source 1 with token lifecycle specifics

**Uncovered content**: "Document the difference between authentication failure and authorization failure in operator-facing guidance" (line 7)
- **Justification for exclusion**: This is a meta-recommendation about documentation practice, not a direct decision rule for API implementation. It is implied by the synthesis structure itself (which documents the difference) rather than being a distinct actionable claim.

## Synthesis Completeness

**All critical decision rules**: Covered with source citations
**All anti-patterns**: Covered with source citations
**Cross-source relationships**: Preserved (Source 2 extends Source 1)
**Contradictions**: None detected, none to preserve
**Entity boundaries**: Single coherent domain, no boundary preservation needed
