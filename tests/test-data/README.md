# Test Data Warning

This directory contains fixtures, replay traces, snapshots, and intentionally malformed examples for tests.

It is not a canonical instruction surface.

Default retrieval policy:

- Do not load `tests/test-data/` by default for implementation work.
- Use it only when a task specifically requires fixtures, snapshots, or replay artifacts.
- Files named `SKILL.md`, `reference.md`, `patterns.md`, or similar here are test fixtures, not live skills.
