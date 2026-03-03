# Trust Model

## High-Trust Requirements

A run is high-trust only if all gates pass:
1. No contamination findings.
2. Reproducibility contract pass.
3. Dual scorer overall winner agreement.
4. Dual scorer skill-installed winner agreement.
5. Minimum repeat count satisfied.
6. For all `skill_installed` pipelines: install and skill-usage evidence gates pass.

## Claim Boundaries

- `skill_installed` results: eligible for external skill-quality claims.
- `protocol_prompt` results: exploratory only; do not claim equivalence with skill-installed runs.
- Offline/local runs are diagnostic and non-authoritative, even when technical gates pass.
- Only real CI runs are claim-eligible for high-trust external statements.
- Conditional trust runs: internal prioritization only.

## What We Do Not Trust

- Runs in shared workspaces with visibility into historical outputs.
- Single-pass anecdotal runs.
- Claims based on a single scorer or missing install/usage evidence.
