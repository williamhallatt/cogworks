# API Authentication Response Handling

## TL;DR

Use `401 Unauthorized` for authentication failures (missing, invalid, or expired tokens) and `403 Forbidden` for authorization failures (authenticated but insufficient permissions) [Source 1] [Source 2]. Always include `WWW-Authenticate` headers with 401 responses [Source 1]. Prefer short-lived access tokens and document the distinction between authentication and authorization failures for operators [Source 2].

## Decision Rules

1. **Missing or invalid token → 401 Unauthorized** [Source 1]: When no token is provided, or the token cannot be parsed or validated, return 401.
2. **Expired token → 401 Unauthorized** [Source 2]: Expired tokens are authentication failures because the caller's identity can no longer be verified. Do not use 403.
3. **Authenticated but insufficient permissions → 403 Forbidden** [Source 1]: When the caller has a valid token but lacks the required role, scope, or permission for the requested resource, return 403.
4. **Include WWW-Authenticate header with 401** [Source 1]: When the authentication scheme requires the client to retry with credentials, the 401 response must include a `WWW-Authenticate` header.
5. **Prefer short-lived access tokens** [Source 2]: Short-lived tokens reduce the window of exposure if a token is compromised.

## Anti-Patterns

- **Using 403 for expired tokens** [Source 2]: Expired tokens are an authentication failure (identity cannot be verified), not an authorization failure. Always use 401.
- **Omitting WWW-Authenticate on 401 responses** [Source 1]: Clients need the header to know how to re-authenticate.
- **Conflating authentication and authorization** [Source 1] [Source 2]: Mixing these concepts in error responses confuses API consumers and makes debugging harder.

## Quick Reference

| Scenario | Status Code | Header |
|---|---|---|
| No token provided | 401 | WWW-Authenticate |
| Invalid token | 401 | WWW-Authenticate |
| Expired token | 401 | WWW-Authenticate |
| Valid token, no permission | 403 | — |

## Sources

1. [Source 1] `01-status-codes.md` — API Auth Status Codes
2. [Source 2] `02-token-handling.md` — Token Handling
