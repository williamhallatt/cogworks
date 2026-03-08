# Generated Run Artifacts

This directory contains generated run artifacts and smoke evidence.

It is not a canonical instruction surface.

Default retrieval policy:

- Do not load `.cogworks-runs/` by default.
- Use it only when validating provenance, inspecting a preserved example, or debugging runtime artifacts.
- Prefer future live runs to write scratch outputs outside the repository unless there is a specific reason to preserve an example artifact here.
- Preserved example artifacts now live under `tests/agentic-smoke/examples/`.
