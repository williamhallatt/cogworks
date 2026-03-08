# Traceability Map

This document maps synthesis content back to source evidence.

## Synthesis Section: TL;DR

| Statement | Source Evidence |
|-----------|-----------------|
| Use 401 for authentication failures (missing, invalid, or expired tokens) | [Source 1] line 3, [Source 2] line 3 |
| Use 403 for authorization failures (authenticated but insufficient permissions) | [Source 1] line 5 |
| Return WWW-Authenticate headers with 401 when auth scheme requires client retry | [Source 1] line 7 |

---

## Synthesis Section: Decision Rules

### DR-1: Status Code Selection Based on Failure Type

| Component | Source Evidence |
|-----------|-----------------|
| Return 401 when caller has not authenticated or token is missing/invalid | [Source 1] line 3 |
| Return 401 when token is expired | [Source 2] line 3, line 5 |
| Return 403 when caller is authenticated but lacks permission | [Source 1] line 5 |
| Boundary condition (identity established vs not established) | [Source 1] lines 3-5, [Source 2] line 7 |

### DR-2: Expired Token Handling

| Component | Source Evidence |
|-----------|-----------------|
| Reject expired tokens with 401 | [Source 2] line 3 |
| Do not use 403 for expired tokens | [Source 2] line 5 |
| Expired tokens are authentication failures | [Source 2] line 5 |

### DR-3: Malformed Token Handling

| Component | Source Evidence |
|-----------|-----------------|
| Reject malformed tokens with 401 | [Source 2] line 5 (by extension from "those are authentication failures") |
| Do not use 403 for malformed tokens | [Source 2] line 5 |
| Malformed tokens are authentication failures | [Source 2] line 5 |

### DR-4: WWW-Authenticate Header Requirements

| Component | Source Evidence |
|-----------|-----------------|
| Return WWW-Authenticate with 401 responses | [Source 1] line 7 |
| Conditional: when auth scheme requires client retry with credentials | [Source 1] line 7 |

### DR-5: Token Lifetime Policy

| Component | Source Evidence |
|-----------|-----------------|
| Prefer short-lived access tokens | [Source 2] line 3 |
| Reject expired tokens with 401 | [Source 2] line 3 |

---

## Synthesis Section: Anti-Patterns

### AP-1: Using 403 For Authentication Failures

| Component | Source Evidence |
|-----------|-----------------|
| Using 403 for expired or malformed tokens | [Source 2] line 5 |
| Why it's wrong: conflates authentication and authorization | [Source 2] line 5 |
| Correct approach: use 401 for all authentication failures | [Source 2] lines 3, 5 |

### AP-2: Omitting WWW-Authenticate Headers

| Component | Source Evidence |
|-----------|-----------------|
| Problem: omitting WWW-Authenticate with 401 | [Source 1] line 7 (implicit from requirement statement) |
| Correct approach: include WWW-Authenticate | [Source 1] line 7 |

### AP-3: Undocumented Authentication vs Authorization Semantics

| Component | Source Evidence |
|-----------|-----------------|
| Document difference in operator-facing guidance | [Source 2] line 7 |
| The distinction that must be documented | [Source 2] line 7 |

---

## Synthesis Section: Quick Reference

| Table Row | Source Evidence |
|-----------|-----------------|
| Missing token -> 401 | [Source 1] line 3 |
| Invalid token -> 401 | [Source 1] line 3 |
| Expired token -> 401 | [Source 2] line 3 |
| Malformed token -> 401 | [Source 2] line 5 |
| Valid token, insufficient permissions -> 403 | [Source 1] line 5 |
| Key distinction (identity vs access) | [Source 1] lines 3-5, [Source 2] line 7 |
| Token policy (short-lived) | [Source 2] line 3 |
| Documentation requirement | [Source 2] line 7 |

---

## Source Content Inventory

### Source 1: 01-status-codes.md

- **Line 3:** "Use `401 Unauthorized` when the caller has not authenticated or their token is missing or invalid."
- **Line 5:** "Use `403 Forbidden` when the caller is authenticated but lacks permission for the resource."
- **Line 7:** "Return `WWW-Authenticate` headers with `401` responses when the auth scheme requires the client to retry with credentials."

### Source 2: 02-token-handling.md

- **Line 3:** "Prefer short-lived access tokens and reject expired tokens with `401`."
- **Line 5:** "Do not use `403` for expired or malformed tokens; those are authentication failures, not authorization failures."
- **Line 7:** "Document the difference between authentication failure and authorization failure in operator-facing guidance."

---

## Cross-Source Synthesis

| Synthesized Concept | Contributing Sources | Synthesis Type |
|---------------------|---------------------|----------------|
| 401 vs 403 core distinction | [Source 1] lines 3,5; [Source 2] line 5,7 | Reinforcement - both sources state the same principle |
| Expired token handling | [Source 2] line 3,5 | Single-source derivation |
| Malformed token handling | [Source 2] line 5 | Single-source derivation (implied from "malformed tokens" reference) |
| WWW-Authenticate header requirement | [Source 1] line 7 | Single-source statement |
| Short-lived token preference | [Source 2] line 3 | Single-source recommendation |
| Documentation requirement | [Source 2] line 7 | Single-source requirement |

---

## Coverage Assessment

**Source 1 Coverage:** 100% - all three guidance statements (401 use, 403 use, WWW-Authenticate requirement) are incorporated into decision rules.

**Source 2 Coverage:** 100% - all three guidance statements (short-lived token preference, 403 misuse avoidance, documentation requirement) are incorporated into decision rules and anti-patterns.

**Uncovered Content:** None - both sources are concise guidance documents with no extraneous content.

**Contradictions Found:** None - the sources are complementary and do not conflict.

**Gaps Identified:** Sources do not specify:
- Exact token lifetime values
- Specific WWW-Authenticate header formats
- Refresh token handling
- Multi-factor authentication scenarios
- Token revocation handling

These gaps are acknowledged as out-of-scope for the current source set.
