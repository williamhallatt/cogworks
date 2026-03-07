# Token Handling

Prefer short-lived access tokens and reject expired tokens with `401`.

Do not use `403` for expired or malformed tokens; those are authentication failures, not authorization failures.

Document the difference between authentication failure and authorization failure in operator-facing guidance.
