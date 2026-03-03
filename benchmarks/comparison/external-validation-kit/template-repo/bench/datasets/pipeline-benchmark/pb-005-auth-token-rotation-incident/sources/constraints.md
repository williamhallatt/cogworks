# Constraints
- API availability SLO: 99.95% (cannot do global auth freeze).
- Some edge gateways lag JWKS refresh by up to 12 minutes.
- Token TTL currently 60 minutes in production.
- Audit team requires explicit timeline and rollback criteria.
