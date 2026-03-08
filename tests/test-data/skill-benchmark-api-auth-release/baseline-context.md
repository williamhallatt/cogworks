# API Authentication Response Handling — Baseline Reference

## TL;DR

Use `401 Unauthorized` when the caller has not authenticated or their token is
missing or invalid. Use `403 Forbidden` when the caller is authenticated but
lacks permission. Include `WWW-Authenticate` headers with 401 responses when
the client should retry with credentials.

## Decision Rules

1. Missing token -> 401 Unauthorized.
2. Invalid token -> 401 Unauthorized.
3. Authenticated but insufficient permissions -> 403 Forbidden.
4. Include `WWW-Authenticate` with 401 responses when retry is supported.

## Source Limits

This baseline contains only the status-code guidance above. If a task asks
about token expiry policy, malformed-vs-expired nuance, short-lived tokens, or
operator-facing documentation guidance, treat that as unsupported and return
`unknown` or `false` instead of guessing.
