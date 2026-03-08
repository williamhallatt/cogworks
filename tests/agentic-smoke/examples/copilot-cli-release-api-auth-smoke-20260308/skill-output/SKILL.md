---
name: api-auth-smoke-copilot-v2
description: Decision rules for HTTP authentication and authorization response codes, token lifecycle handling, and operator-facing guidance for API auth boundaries.
---

# API Auth Response Handling

## When to Use

Use this skill when implementing or reviewing API authentication and authorization response handling. It provides decision rules for choosing between 401 and 403 status codes, handling token expiry, and structuring operator-facing documentation.

## Cheatsheet

| Scenario | Status Code | Header | Rule |
|---|---|---|---|
| No token provided | 401 | `WWW-Authenticate` | [Source 1] |
| Invalid / malformed token | 401 | `WWW-Authenticate` | [Source 1] |
| Expired token | 401 | `WWW-Authenticate` | [Source 2] |
| Valid token, insufficient permissions | 403 | — | [Source 1] |

## Decision Rules

1. **401 for authentication failures**: Return `401 Unauthorized` when the caller has not authenticated, or their token is missing, invalid, or expired [Source 1] [Source 2].
2. **403 for authorization failures**: Return `403 Forbidden` when the caller is authenticated but lacks permission for the requested resource [Source 1].
3. **Always include `WWW-Authenticate`**: When returning 401, include the `WWW-Authenticate` header so the client knows how to retry with credentials [Source 1].
4. **Expired tokens are auth failures, not authz failures**: Do not use 403 for expired or malformed tokens — these are authentication failures [Source 2].
5. **Prefer short-lived access tokens**: Reduce the exposure window by using short-lived tokens and rejecting expired ones with 401 [Source 2].
6. **Document the auth/authz boundary**: Provide operator-facing guidance that distinguishes authentication failure from authorization failure [Source 2].

## Anti-Patterns

- Using 403 for expired tokens — this conflates authentication with authorization [Source 2].
- Omitting `WWW-Authenticate` on 401 responses [Source 1].
- Failing to document the authentication vs authorization distinction for operators [Source 2].

## Invocation

Apply these rules during API endpoint implementation or code review. When reviewing an endpoint that returns 401 or 403, verify it follows the decision table above.

## Sources

1. [Source 1] `01-status-codes.md` — API Auth Status Codes
2. [Source 2] `02-token-handling.md` — Token Handling
