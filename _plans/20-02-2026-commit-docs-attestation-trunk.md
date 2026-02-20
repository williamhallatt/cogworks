# Commit Docs Attestation for Trunk

Date: 2026-02-20
Status: Accepted

## Summary

Implement commit-level documentation attestation for trunk-based development using:

- A required commit trailer contract
- Local `commit-msg` hook validation
- CI enforcement on `push` to `main`
- Documentation updates in maintainer and contributor guides

## Decision-Locked Contract

Required trailers on every commit message:

```text
Docs-Impact: updated|none|required-followup
Docs-Updated: <csv-paths>|none
Docs-Why-None: <text>  (required when Docs-Impact is none or required-followup)
```

Rules:

1. `Docs-Impact: updated` requires `Docs-Updated` to list one or more docs files.
2. `Docs-Impact: none` requires `Docs-Updated: none` and a non-empty `Docs-Why-None`.
3. `Docs-Impact: required-followup` requires `Docs-Updated: none` and `Docs-Why-None` must include:
   - a date in `YYYY-MM-DD`
   - an owner handle in `@name` form

## Planned Interfaces

1. `scripts/validate-docs-attestation.sh --commit <sha>`
2. `scripts/validate-docs-attestation.sh --range <base>..<head>`
3. `scripts/install-git-hooks.sh`
4. `.githooks/commit-msg` using shared validator logic
5. `.github/workflows/docs-attestation.yml` on `push` to `main`

## Validation Scenarios

- Valid `updated`, `none`, and `required-followup` commits pass.
- Missing/invalid/duplicate trailers fail with actionable error output.
- Push workflow validates all commits in pushed range and hard-fails on violation.
