# Critical Distinction Registry

## CDR-1: Authentication Failure vs Authorization Failure

**Distinction:** Authentication failure (identity not established or cannot be verified) versus authorization failure (identity established but access denied)

**Why It Matters:** This distinction determines which HTTP status code to use (401 vs 403) and affects how clients should respond to the error. Misuse prevents proper error handling and debugging.

**Decision Impact:** Maps to DR-1 (Status Code Selection Based on Failure Type)

**Sources:** [Source 1] [Source 2]

**Cross-Source Relationship:** Both sources emphasize this distinction. Source 1 establishes the basic rule. Source 2 reinforces it in the context of token expiration and malformation, explicitly stating that these scenarios are authentication failures, not authorization failures.

---

## CDR-2: Expired Token Classification

**Distinction:** Expired tokens are authentication failures, not authorization failures

**Why It Matters:** Developers might incorrectly reason that an expired token with valid permissions should return 403. This is wrong because the authentication layer must reject the expired credential before any authorization evaluation occurs.

**Decision Impact:** Maps to DR-2 (Expired Token Handling) and AP-1 (Using 403 For Authentication Failures)

**Sources:** [Source 2]

**Cross-Source Relationship:** Source 2 explicitly addresses this common misconception.

---

## CDR-3: Malformed Token Classification

**Distinction:** Malformed tokens are authentication failures, not authorization failures

**Why It Matters:** Similar to expired tokens, malformed tokens cannot establish identity. Authorization evaluation is premature when authentication has not succeeded.

**Decision Impact:** Maps to DR-3 (Malformed Token Handling) and AP-1 (Using 403 For Authentication Failures)

**Sources:** [Source 2]

**Cross-Source Relationship:** Source 2 addresses this alongside expired token handling, emphasizing the consistent principle that authentication must succeed before authorization.

---

## CDR-4: WWW-Authenticate Header Conditionality

**Distinction:** WWW-Authenticate headers are required when the auth scheme requires client retry with credentials, not in all 401 responses unconditionally

**Why It Matters:** The header serves as a signal to the client about how to authenticate. It's protocol-specific and context-dependent.

**Decision Impact:** Maps to DR-4 (WWW-Authenticate Header Requirements)

**Sources:** [Source 1]

**Cross-Source Relationship:** Source 1 is the sole source for this requirement. The conditional phrasing ("when the auth scheme requires") is preserved from the source.

---

## CDR-5: Token Lifetime Security Posture

**Distinction:** Short-lived tokens versus long-lived tokens as a security design choice

**Why It Matters:** Short-lived tokens reduce the window of opportunity if a token is compromised. This is a security-UX tradeoff that must be explicitly decided.

**Decision Impact:** Maps to DR-5 (Token Lifetime Policy)

**Sources:** [Source 2]

**Cross-Source Relationship:** Source 2 establishes the preference for short-lived tokens without specifying exact durations, acknowledging this is a design decision.
