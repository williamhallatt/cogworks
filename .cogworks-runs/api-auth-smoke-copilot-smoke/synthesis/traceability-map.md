# Traceability Map — api-auth-smoke

Maps each synthesised claim to its authoritative source(s).

| Claim | Source(s) | Normative Weight |
|-------|-----------|-----------------|
| Return 401 for missing token | src-01 | Required |
| Return 401 for invalid token | src-01 | Required |
| Return 401 for expired token | src-02 | Required |
| Return 401 for malformed token | src-02 | Required |
| Return 403 for authenticated-but-unauthorized | src-01 | Required |
| Do not return 403 for expired/malformed tokens | src-02 | Required |
| Return WWW-Authenticate header with 401 (conditional) | src-01 | Conditional |
| Prefer short-lived access tokens | src-02 | Advisory |
| Document the auth/authz distinction to operators | src-02 | Required (meta) |

## Coverage Gaps (not traced — absent from source set)

- Refresh token flows
- Token revocation / blacklisting
- Step-up / multi-factor authentication
- Rate-limiting (429) interaction with auth retry loops
