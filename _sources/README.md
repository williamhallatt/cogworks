# Source Corpus Warning

`_sources/` is a reference corpus, not a canonical instruction surface.

It contains a mix of:

- primary source material
- third-party documentation dumps
- local syntheses
- research notes
- historical implementation summaries

Default retrieval policy:

- Do not load `_sources/` opportunistically for ordinary repo work.
- Load only the specific source files needed for a research or synthesis task.
- Prefer primary source material over local syntheses when both exist.
