# Cogworks Update Checker Packaging Plan (Accepted 2026-02-20)

## Summary

Add a cogworks-specific update checker and include it in release artifacts as a convenience utility.

## Decisions

- Keep update checking separate from installer core behavior.
- Provide human-readable output only (no JSON mode).
- Include the utility in packaged releases so users can run it immediately after extraction/install.

## Implementation Scope

1. Add `scripts/check-cogworks-updates.sh`.
2. Add a post-install next-step hint in `install.sh`.
3. Update release workflow to package `scripts/check-cogworks-updates.sh`.
4. Document usage in `README.md` and `INSTALL.md`.
5. Update `RELEASES.md` package contents/checklist.

## Validation

- Script `--help` works.
- Script exits with expected codes for up-to-date, update available, and error conditions.
- Release artifact creation step contains `scripts/check-cogworks-updates.sh`.

