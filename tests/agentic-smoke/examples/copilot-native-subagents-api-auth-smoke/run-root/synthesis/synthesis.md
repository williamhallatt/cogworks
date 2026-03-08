# Synthesis Notes

**Stage:** synthesis
**Skill:** api-auth-smoke
**Surface:** copilot-cli / agentic
**Source set:** src-01 (`01-status-codes.md`), src-02 (`02-token-handling.md`)
**Trust posture:** Both sources `internal/trusted`; no derivative risk; no contradictions.

---

## Synthesis Narrative

### 1. Core Semantic Boundary: Authentication vs Authorization

The two sources converge on a single, clear decision boundary:

| Condition | Correct Response |
|-----------|-----------------|
| Token missing | 401 |
| Token invalid (any reason) | 401 |
| Token expired | 401 (explicitly reinforced by src-02) |
| Token malformed | 401 (explicitly reinforced by src-02) |
| Caller authenticated, lacks permission | 403 |

**Authority:** Both sources assert this boundary independently; src-02 refines the edge cases (expired, malformed) that src-01 leaves implicit. Neither source contradicts the other. The combined claim set is stronger than either source alone.

**Synthesis note:** The distinction is categorical, not a matter of preference. Returning `403` for expired or malformed tokens is treated as incorrect behaviour, not a style choice. This must be preserved as a normative rule in any packaged skill guidance.

---

### 2. WWW-Authenticate Header

src-01 establishes a conditional obligation: when the auth scheme permits or requires credential retry, a `WWW-Authenticate` header **must** accompany the `401` response. src-02 does not address this header; there is no conflict.

**Synthesis note:** This is a conditional rule scoped to auth schemes that support retry. It should be represented as a conditional norm, not an unconditional one.

---

### 3. Token Lifecycle

src-02 introduces the positive guidance: **prefer short-lived access tokens**. This is a design recommendation, not an error-response rule. It is the only forward-looking (preventive) claim in the source set; all other claims are reactive (error-response semantics).

**Synthesis note:** Short-lived token preference is advisory/best-practice weight, not the same normative force as the 401/403 boundary rule. This distinction should be preserved in packaging.

---

### 4. Operator-Facing Documentation Obligation

src-02 contains a documentation obligation: operators must be informed of the authentication/authorization distinction. This is a meta-claim — it governs how the skill guidance itself must be surfaced, not just what the API should do.

**Synthesis note:** This obligation applies to the skill package, not only to the consuming API. The skill packaging stage must honour it.

---

### 5. Coverage Gaps (advisory, non-blocking)

The following topics are absent from the source set. They are noted to avoid false completeness assumptions downstream:

- **Refresh token flows** — no guidance on how to signal expired access tokens when a refresh token is available (e.g., `401` with a specific `WWW-Authenticate` challenge vs. silent refresh)
- **Token revocation / blacklisting** — no guidance on how revoked-but-not-expired tokens should be handled
- **Multi-factor / step-up authentication** — no guidance on `401` with step-up challenge semantics
- **Rate-limiting interaction** — no guidance on `429 Too Many Requests` in the context of auth retry loops

These gaps are scoped out of this skill; they are not contradictions or errors.

---

### 6. Derivative and Trust Assessment

Both sources are first-party fixtures under version control. No external citations, no copy-pasted boilerplate, no executable content. Trust assessment from source-intake is carried forward unchanged: **PASS**.

---

## Synthesis Verdict

**Status: PASS**

The source set is internally consistent, mutually reinforcing, and free of contradictions. The synthesised knowledge set is suitable for skill packaging. No blocking issues.
