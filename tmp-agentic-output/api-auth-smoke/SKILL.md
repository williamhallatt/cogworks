---
name: api-auth-smoke
description: >
  Normative guidance on HTTP status codes and token handling for API authentication.
  Covers the 401/403 decision boundary, WWW-Authenticate header obligations,
  token lifecycle best practices, and the conceptual distinction between
  authentication failure and authorization failure.
version: "1.0.0"
engine_mode: agentic
execution_surface: copilot-cli
sources:
  - id: src-01
    file: 01-status-codes.md
    trust: internal/trusted
  - id: src-02
    file: 02-token-handling.md
    trust: internal/trusted
---

# API Authentication — HTTP Status Codes and Token Handling

## Overview

This skill provides normative guidance for API implementors on selecting the correct HTTP response codes when authentication or authorization fails, and on structuring tokens to reduce the risk of those failures. The central rule is a strict categorical boundary:

- **401 Unauthorized** — the caller has not authenticated, or their credentials are invalid in any way.
- **403 Forbidden** — the caller is authenticated, but lacks permission for the requested resource.

These two codes are not interchangeable. Misusing 403 for authentication failures is a common implementation error; this skill treats it as incorrect behaviour, not a style preference.

---

## Core Rules (Normative)

### Rule 1 — Use 401 for All Authentication Failures

Return **HTTP 401** whenever the request cannot be authenticated. This covers all of the following conditions without exception:

| Condition | Correct Status |
|-----------|---------------|
| Token is absent / not provided | **401** |
| Token is present but invalid | **401** |
| Token is expired | **401** |
| Token is malformed | **401** |

> ⚠️ **Common error:** Returning `403` for expired or malformed tokens is incorrect. Expiry and malformation are authentication failures, not permission failures. The caller has not proven their identity; they have not been refused access to a resource they are authenticated for.

### Rule 2 — Use 403 Exclusively for Post-Authentication Permission Failures

Return **HTTP 403** only when both of the following are true:

1. The caller has successfully authenticated (their token is present, valid, not expired, not malformed).
2. That authenticated caller does not have permission to perform the requested operation on the requested resource.

Do not use 403 for any condition that arises from a token problem.

### Rule 3 — Document the Authentication / Authorization Distinction for Operators

Any operator-facing documentation (API references, error catalogues, runbooks) **must** clearly explain:

- What "authentication failure" means (identity cannot be verified → 401).
- What "authorization failure" means (identity is verified, permission is denied → 403).

Conflating these in documentation leads to misimplementation and difficult-to-diagnose client errors.

---

## Conditional Rules

### Rule 4 — Include WWW-Authenticate with 401 When the Auth Scheme Requires It

When the authentication scheme in use permits or requires credential retry (e.g., HTTP Basic, Bearer token schemes following RFC 6750), include a `WWW-Authenticate` header in the 401 response.

```
HTTP/1.1 401 Unauthorized
WWW-Authenticate: Bearer realm="example", error="invalid_token"
```

This rule is **conditional** on the auth scheme. If the scheme does not define a retry or challenge mechanism, the header may be omitted. When in doubt, include it — it aids client implementors and is harmless when not acted upon.

---

## Best Practices (Advisory)

### BP-1 — Prefer Short-Lived Access Tokens

Design access tokens to be short-lived. Short-lived tokens reduce the exposure window when a token is compromised or leaked. When a token expires frequently, the window during which an expired token could be replayed by an attacker is narrowed.

> This is a **recommended** design practice, not a protocol requirement. The operational tradeoff (token refresh overhead vs. security exposure) is context-dependent.

---

## Out of Scope

The following topics are explicitly outside the boundary of this skill. They are noted to prevent false completeness assumptions:

- **Refresh token flows** — how to signal expiry to a client that has a refresh token; when to issue a 401 vs. silently attempt refresh.
- **Token revocation / blacklisting** — response semantics for revoked-but-not-expired tokens.
- **Step-up / multi-factor authentication** — 401 with step-up challenge semantics (e.g., `WWW-Authenticate: Bearer error="insufficient_user_authentication"`).
- **Rate-limiting interaction** — `429 Too Many Requests` semantics in auth retry loops.

---

## Quick Reference

```
Request arrives
│
├─ No token present?          → 401 Unauthorized
├─ Token present but invalid? → 401 Unauthorized
├─ Token expired?             → 401 Unauthorized
├─ Token malformed?           → 401 Unauthorized
│
└─ Token valid + authenticated?
    ├─ Has permission?         → 2xx (proceed)
    └─ No permission?          → 403 Forbidden
```

---

## Decision Boundary Summary

| Situation | Status Code | Notes |
|-----------|-------------|-------|
| Missing token | 401 | Must not be 403 |
| Invalid token | 401 | Must not be 403 |
| Expired token | 401 | Must not be 403 — common error |
| Malformed token | 401 | Must not be 403 — common error |
| Valid token, no permission | 403 | Must not be 401 |
| Valid token, has permission | 2xx | Normal path |
