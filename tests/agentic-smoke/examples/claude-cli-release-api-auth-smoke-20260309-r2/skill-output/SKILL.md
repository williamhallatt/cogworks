---
name: api-auth-smoke-claude-bridge
description: Use when implementing or debugging API authentication status codes (401 vs 403), token expiration handling, or WWW-Authenticate header requirements for HTTP authentication failures.
license: MIT
---

# API Authentication Status Code and Token Handling

## Overview

This skill provides decision rules for selecting correct HTTP status codes when API authentication or authorization fails, handling expired and malformed tokens, and including appropriate WWW-Authenticate headers.

The core principle: use 401 Unauthorized when identity cannot be established or verified (authentication failure), and 403 Forbidden when identity is known but access is denied (authorization failure).

## When to Use

Use this skill when:
- implementing API authentication or authorization logic
- debugging status code selection for auth failures
- designing token validation and rejection behavior
- deciding whether to include WWW-Authenticate headers with 401 responses
- writing operator-facing guidance that explains authentication vs authorization semantics

Do not use it for OAuth flow implementation, refresh token handling, or multi-factor authentication scenarios (out of scope).

## Quick Decision Cheatsheet

- Missing, invalid, expired, or malformed tokens return 401 (authentication failure)
- Valid token with insufficient permissions returns 403 (authorization failure)
- Expired tokens are authentication failures, never authorization failures
- Include WWW-Authenticate headers with 401 when the auth scheme requires client retry
- Prefer short-lived access tokens to reduce compromise windows

## Supporting Docs

See [reference.md](reference.md) for:
- Detailed decision rules with triggers, actions, boundary conditions
- Anti-patterns covering common mistakes like using 403 for expired tokens
- Quick reference table mapping scenarios to status codes
- Full source citations

## Sources

All guidance is synthesized from source materials documented in [reference.md](reference.md).
