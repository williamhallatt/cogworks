# Incident Brief: JWT Signing Key Exposure
A private signing key was exposed in CI logs 47 minutes ago.
Current services validate JWTs against JWKS with a 10-minute cache.
Mobile clients can refresh every 8 hours and may keep bearer tokens offline.

## Required outcomes
- Emergency key rotation without full outage.
- Contain replay risk from stolen tokens.
- Avoid revoking healthy machine-to-machine traffic unnecessarily.
