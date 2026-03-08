# Reference — api-auth-smoke

## TL;DR

Return `401` for any authentication failure (missing, invalid, expired, or malformed token). Return `403` only when the caller is authenticated but lacks permission. Never use `403` for token failures.

---

## Decision Rules

1. **Missing token → 401.** No token present means no authentication — always 401.
2. **Invalid token → 401.** Invalid includes expired, malformed, revoked.
3. **Authenticated caller, no permission → 403.** The caller proved identity; the resource denied access.
4. **WWW-Authenticate with 401 (conditional).** When the auth scheme supports credential retry, include this header.
5. **Short-lived access tokens (advisory).** Prefer tokens that expire quickly to minimise exposure.
6. **Document the auth/authz distinction.** Operators must be informed of the 401/403 boundary.

---

## Anti-Patterns

- **Using 403 for expired tokens.** Expired tokens are not a permission failure — they are an authentication failure.
- **Using 403 for malformed tokens.** Same reasoning: malformed means unauthenticated, not unauthorized.
- **Omitting WWW-Authenticate when the scheme requires it.** This breaks RFC-compliant clients expecting a retry challenge.
- **Using 401 for a known-valid, correctly scoped caller who simply lacks access.** That is a 403, not a 401.

---

## Quick Reference

| Condition | Code | Header |
|-----------|------|--------|
| No token | 401 | WWW-Authenticate (if scheme allows) |
| Token invalid | 401 | WWW-Authenticate (if scheme allows) |
| Token expired | 401 | WWW-Authenticate (if scheme allows) |
| Token malformed | 401 | — |
| Authenticated, no permission | 403 | — |

---

## Sources

This document traces each normative claim to its authoritative source.

### Source Index

| Citation | Source ID | File |
|----------|-----------|------|
| [Source 1] | src-01 | `01-status-codes.md` |
| [Source 2] | src-02 | `02-token-handling.md` |

Both sources are classified `internal/trusted`.

---

## Claim Trace

### HTTP 401 — Authentication Failures

**Claim:** Return 401 when the caller has not authenticated or the token is missing.
**Citation:** [Source 1]

**Claim:** Return 401 when the token is present but invalid.
**Citation:** [Source 1]

**Claim:** Return 401 for expired tokens (not 403).
**Citation:** [Source 2]

**Claim:** Return 401 for malformed tokens (not 403).
**Citation:** [Source 2]

**Synthesis note:** [Source 1] establishes the base rule; [Source 2] explicitly closes the expired and malformed edge cases. The combined claim set is normative.

---

### HTTP 403 — Post-Authentication Permission Failures

**Claim:** Return 403 when the caller is authenticated but lacks permission for the resource.
**Citation:** [Source 1]

**Claim:** Do not use 403 for expired or malformed tokens.
**Citation:** [Source 2]

---

### WWW-Authenticate Header

**Claim:** Return a `WWW-Authenticate` header with 401 responses when the authentication scheme requires credential retry.
**Citation:** [Source 1]

---

### Short-Lived Access Tokens

**Claim:** Prefer short-lived access tokens to reduce the exposure window for token-based authentication failures.
**Citation:** [Source 2]

---

### Documentation Obligation

**Claim:** Operators must be informed of the distinction between authentication failure and authorization failure.
**Citation:** [Source 2]

---

## Coverage Gaps

The following topics have no source coverage and are not represented in skill claims:

- Refresh token flows — no authoritative source in scope
- Token revocation / blacklisting — no authoritative source in scope
- Step-up / multi-factor authentication semantics — no authoritative source in scope
- Rate-limiting (429) interaction with auth retry loops — no authoritative source in scope

---

## Contradiction Log

Contradiction count: **0**

One near-miss tension was identified and resolved: [Source 1] did not explicitly address whether expired or malformed tokens return 401 or 403. [Source 2] resolved this by explicitly prohibiting 403 for those cases. The sources are mutually consistent.
