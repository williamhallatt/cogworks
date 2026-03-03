# Skill Benchmark Lab (External Validation)

This repository is the authoritative harness for externally validating generated-skill quality across pipelines.

Official result policy:
- Only CI runs from clean runners are authoritative.
- Local runs are debugging-only.
- Skill-quality claims must come from `skill_installed` execution mode.

## Quick Start

1. Pin vendors under `vendors/`:
- `vendors/cogworks`
- `vendors/generator-a`
- `vendors/generator-b`

2. Run pilot smoke:
```bash
bash bench/scripts/run-protocol-benchmark.sh \
  --protocol bench/protocols/protocol-pilot.json \
  --mode offline \
  --run-id pilot-smoke-$(date +%Y%m%d-%H%M%S) \
  --force
```

3. Run hard real protocol:
```bash
bash bench/scripts/run-protocol-benchmark.sh \
  --protocol bench/protocols/protocol-hard-v2.json \
  --mode real \
  --repeats 3 \
  --run-id hard-real-$(date +%Y%m%d-%H%M%S) \
  --force
```

4. Review trust status:
- `bench/results/pipeline-benchmark/<run-id>/trust-report.md`

## Required Tooling
- `bash`
- `python3`
- `node` + `npm`/`npx`
- `codex` CLI (authenticated, for `--mode real`)
- `git`
- `jsonschema` Python package (for protocol schema validation)

Install validation dependency:
- `python3 -m pip install jsonschema`

Real mode installs skill pipelines via:
- `npx skills add <source> -a codex -y`
