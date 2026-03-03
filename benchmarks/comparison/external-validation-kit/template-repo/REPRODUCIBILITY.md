# Reproducibility

## Required Pinning

- Benchmark repo commit SHA
- Vendor commit SHAs
- Container image digest (`BENCH_CONTAINER_DIGEST`)
- Protocol manifest version
- Node/npm/codex versions used for installation/execution

## Required Provenance Fields

Each run directory must include `provenance.json` with:
- benchmark commit
- vendor commits
- model family/id
- input hashes
- output hashes
- sandbox path

Each case must include:
- `execution-mode.json`
- `skill-install-report.json`
- `skill-use-evidence.json`

## Repeatability Procedure

1. Re-run same protocol with identical pinned commits/image/toolchain.
2. Compare winners and ranking order by mode.
3. Confirm install/usage evidence pass rates unchanged.
4. Record differences in `bench/reports/`.

Authority note:
- Offline/local reruns are reproducibility diagnostics only.
- High-trust external claims require real-mode CI reruns.
