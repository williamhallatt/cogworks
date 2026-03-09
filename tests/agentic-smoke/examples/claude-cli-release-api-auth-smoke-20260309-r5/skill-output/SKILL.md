---
name: api-auth-smoke-claude-bridge
description: Comprehensive guidance for AI agents on HTTP API authentication and authorization status codes, token handling, and WWW-Authenticate headers with clear rules for 401 vs 403 semantics
disable-model-invocation: true
---

# API Authentication and Authorization Status Code Guidance

## TL;DR

Use `401 Unauthorized` for authentication failures (missing, invalid, or expired tokens). Use `403 Forbidden` for authorization failures (authenticated caller lacks permission). Include `WWW-Authenticate` headers with `401` responses when retry with credentials is expected. Prefer short-lived access tokens.

## Decision Rules

### Status Code Selection

**401 Unauthorized** [Source 1] [Source 2]
- Missing authentication token
- Invalid authentication token
- Expired authentication token [Source 2]
- Malformed authentication token [Source 2]
- Caller has not authenticated [Source 1]

**403 Forbidden** [Source 1]
- Caller is authenticated but lacks permission for the resource
- Valid token, insufficient authorization scope

### Header Requirements

**WWW-Authenticate header** [Source 1]
- Return with `401` responses when the authentication scheme requires the client to retry with credentials
- Indicates the authentication scheme and realm to the client

### Token Lifecycle

**Access token policy** [Source 2]
- Prefer short-lived access tokens
- Reject expired tokens with `401` (authentication failure)

## Anti-Patterns

**Do not use `403` for expired or malformed tokens** [Source 2]
- These are authentication failures, not authorization failures
- Must return `401` instead

**Do not conflate authentication and authorization failures** [Source 2]
- Authentication = proving identity (401 when fails)
- Authorization = checking permission (403 when insufficient)

## Quick Reference

| Condition | Status Code | Header |
|-----------|-------------|---------|
| Missing token | 401 | WWW-Authenticate [Source 1] |
| Invalid token | 401 | WWW-Authenticate [Source 1] |
| Expired token | 401 [Source 2] | WWW-Authenticate [Source 1] |
| Malformed token | 401 [Source 2] | WWW-Authenticate [Source 1] |
| Valid token, no permission | 403 [Source 1] | - |

## Sources

1. `/home/will/code/cogworks/tests/agentic-smoke/fixtures/api-auth-smoke/01-status-codes.md` - HTTP status code guidance for authentication and authorization, 401 vs 403 semantics, WWW-Authenticate header requirements
2. `/home/will/code/cogworks/tests/agentic-smoke/fixtures/api-auth-smoke/02-token-handling.md` - Token lifecycle guidance, short-lived token preference, expired/malformed token classification as authentication failures, operator documentation requirements
