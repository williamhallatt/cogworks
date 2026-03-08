# Source Trust Report

**Stage:** source-intake
**Skill:** api-auth-smoke
**Surface:** copilot-cli / agentic
**Generated:** run `copilot-native-subagents-api-auth-smoke-example`

---

## Summary

| File | Trust Class | Risk Signals |
|------|-------------|--------------|
| `01-status-codes.md` | `internal/trusted` | none |
| `02-token-handling.md` | `internal/trusted` | none |

---

## Per-Source Assessment

### src-01 — `01-status-codes.md`

- **Trust class:** `internal/trusted` (local fixture, coordinator-designated)
- **Provenance:** Cogworks smoke-test fixture tree; under version control.
- **Content risk:** None. Guidance text only; no executable code, credentials, or external references.
- **Derivative-source risk:** None detected. No citations, external URLs, or copy-pasted boilerplate.
- **Entity-boundary risk:** Low. Scope is narrow (HTTP 401/403 + WWW-Authenticate); no ambiguous scope overlap with other domains.
- **Contradiction signals:** None.

### src-02 — `02-token-handling.md`

- **Trust class:** `internal/trusted` (local fixture, coordinator-designated)
- **Provenance:** Cogworks smoke-test fixture tree; under version control.
- **Content risk:** None. Guidance text only; no executable code, credentials, or external references.
- **Derivative-source risk:** None detected.
- **Entity-boundary risk:** Low. Scope is token lifecycle; consistent with and complementary to src-01.
- **Contradiction signals:** None. src-02 explicitly reinforces src-01's 401-for-token-failures rule.

---

## Cross-Source Consistency

The two sources are fully consistent. `02-token-handling.md` refines the edge case (expired/malformed tokens → 401 not 403) that could otherwise be misread from `01-status-codes.md` alone.

---

## Coverage Gaps (advisory, not blocking)

- No guidance on refresh token flows.
- No guidance on token revocation or blacklisting.
- No guidance on multi-factor or step-up authentication responses.
- No guidance on rate-limiting / `429` interaction with auth retries.

---

## Decision

**PASS** — Both sources are internal/trusted, mutually consistent, and contain no executable risk. Safe to proceed to synthesis.
