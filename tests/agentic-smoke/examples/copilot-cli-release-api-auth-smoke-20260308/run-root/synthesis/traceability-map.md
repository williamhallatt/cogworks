# Traceability Map

| Decision Rule | Primary Source | Supporting Source |
|---|---|---|
| Missing/invalid token → 401 | [Source 1] | — |
| Expired token → 401 | [Source 2] | [Source 1] |
| Insufficient permissions → 403 | [Source 1] | — |
| WWW-Authenticate with 401 | [Source 1] | — |
| Prefer short-lived tokens | [Source 2] | — |
| Document auth vs authz distinction | [Source 2] | [Source 1] |
