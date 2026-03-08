# API Authentication Status Code and Token Handling Reference

## TL;DR

Use 401 for authentication failures (missing, invalid, or expired tokens). Use 403 for authorization failures (authenticated but insufficient permissions). Always return WWW-Authenticate headers with 401 when the auth scheme requires client retry with credentials. [Source 1] [Source 2]

## Decision Rules

### DR-1: Status Code Selection Based on Failure Type

**Trigger:** API request fails authentication or authorization check

**Preferred Action:**
- Return `401 Unauthorized` when the caller has not authenticated OR their token is missing, invalid, or expired [Source 1] [Source 2]
- Return `403 Forbidden` when the caller is authenticated but lacks permission for the resource [Source 1]

**Boundary Condition:** The key distinction is whether identity has been established. If identity is unknown or cannot be verified (authentication failure), use 401. If identity is known but access is denied (authorization failure), use 403. [Source 1] [Source 2]

**Citation:** [Source 1] [Source 2]

---

### DR-2: Expired Token Handling

**Trigger:** Received token has expired timestamp

**Preferred Action:**
- Reject with `401 Unauthorized` [Source 2]
- Do NOT use `403 Forbidden` - expired tokens are authentication failures, not authorization failures [Source 2]

**Boundary Condition:** This applies regardless of whether the token would have granted sufficient permissions if it were valid. The authentication layer must reject before authorization evaluation. [Source 2]

**Citation:** [Source 2]

---

### DR-3: Malformed Token Handling

**Trigger:** Received token cannot be parsed or validated

**Preferred Action:**
- Reject with `401 Unauthorized` [Source 2]
- Do NOT use `403 Forbidden` - malformed tokens are authentication failures, not authorization failures [Source 2]

**Boundary Condition:** This includes tokens with invalid signatures, corrupted encoding, or structure that doesn't match the expected format. [Source 2]

**Citation:** [Source 2]

---

### DR-4: WWW-Authenticate Header Requirements

**Trigger:** Returning `401 Unauthorized` response

**Preferred Action:**
- Return `WWW-Authenticate` header when the auth scheme requires the client to retry with credentials [Source 1]

**Boundary Condition:** The WWW-Authenticate header signals to the client what authentication scheme to use. Include this when you want the client to attempt authentication or re-authentication. [Source 1]

**Citation:** [Source 1]

---

### DR-5: Token Lifetime Policy

**Trigger:** Designing or implementing token generation

**Preferred Action:**
- Prefer short-lived access tokens [Source 2]
- Reject expired tokens with `401` [Source 2]

**Boundary Condition:** Short-lived tokens reduce the window of opportunity if a token is compromised. The specific duration should balance security needs against user experience and system load. [Source 2]

**Citation:** [Source 2]

---

## Anti-Patterns

### AP-1: Using 403 For Authentication Failures

**Problem:** Using `403 Forbidden` for expired tokens, malformed tokens, or missing credentials [Source 2]

**Why It's Wrong:** This conflates authentication failure (who are you?) with authorization failure (what can you do?). It prevents clients from understanding whether they need to re-authenticate or if they need different permissions. [Source 2]

**Correct Approach:** Use `401 Unauthorized` for all authentication failures, including expired and malformed tokens. [Source 2]

---

### AP-2: Omitting WWW-Authenticate Headers

**Problem:** Returning `401` responses without `WWW-Authenticate` headers when the auth scheme requires client retry [Source 1]

**Why It's Wrong:** Clients may not know what authentication scheme to use or how to construct valid credentials. [Source 1]

**Correct Approach:** Include `WWW-Authenticate` headers with `401` responses to guide client authentication behavior. [Source 1]

---

### AP-3: Undocumented Authentication vs Authorization Semantics

**Problem:** Failing to document the difference between authentication failure and authorization failure in operator-facing guidance [Source 2]

**Why It's Wrong:** Operators and developers need to understand this distinction to properly diagnose issues, implement correct error handling, and maintain consistent API behavior. [Source 2]

**Correct Approach:** Document the difference explicitly in operator-facing guidance. Make it clear that authentication establishes identity and authorization determines permissions. [Source 2]

---

## Quick Reference

| Scenario | Status Code | Include WWW-Authenticate? | Rationale |
|----------|-------------|---------------------------|-----------|
| Missing token | 401 | Yes (if auth scheme requires) | Authentication failure [Source 1] |
| Invalid token | 401 | Yes (if auth scheme requires) | Authentication failure [Source 1] |
| Expired token | 401 | Yes (if auth scheme requires) | Authentication failure, not authorization [Source 2] |
| Malformed token | 401 | Yes (if auth scheme requires) | Authentication failure, not authorization [Source 2] |
| Valid token, insufficient permissions | 403 | No | Authorization failure [Source 1] |

**Key Distinction:** 401 = identity not established or verified; 403 = identity known but access denied [Source 1] [Source 2]

**Token Policy:** Prefer short-lived access tokens [Source 2]

**Documentation Requirement:** Operator-facing guidance must explain authentication vs authorization failure semantics [Source 2]

---

## Sources

- [Source 1] `/home/will/code/cogworks/tests/agentic-smoke/fixtures/api-auth-smoke/01-status-codes.md` - API authentication status code guidance covering 401 vs 403 distinction and WWW-Authenticate header requirements
- [Source 2] `/home/will/code/cogworks/tests/agentic-smoke/fixtures/api-auth-smoke/02-token-handling.md` - Token lifecycle guidance covering short-lived token preference, expired token handling, and authentication vs authorization failure semantics
