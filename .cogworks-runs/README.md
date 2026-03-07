# Generated Run Artifacts

This directory contains generated run artifacts and smoke evidence.

It is not a canonical instruction surface.

Default retrieval policy:

- Do not load `.cogworks-runs/` by default.
- Use it only when validating provenance, inspecting a specific historical run, or debugging runtime artifacts.
- Prefer future live runs to write scratch outputs outside the repository unless there is a specific reason to preserve an example artifact here.
