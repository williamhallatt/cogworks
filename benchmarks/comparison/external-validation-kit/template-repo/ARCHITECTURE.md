# Architecture

## Execution Model

- Orchestrator: `bench/scripts/run-protocol-benchmark.sh`
- Case executor: `bench/scripts/run-protocol-case.sh`
- Generator entrypoint: `bench/scripts/run-protocol-generator.sh`

For each pipeline/task/repeat/variant:
1. Create ephemeral sandbox workspace under `/tmp`.
2. Copy task sources and protocol docs into sandbox.
3. Detect pipeline capability (`skill_installed` vs `protocol_prompt`).
4. If `skill_installed`, install skills in isolated per-case environment via `npx skills add`.
5. Run generator command using the sandbox workspace.
6. Verify installed-skill usage evidence (`skill-use-evidence.json`).
7. Copy generated skill to run output directory.
8. Score via scorer-v1 and scorer-v2.
9. Emit provenance artifact.

## Trust Gates

- contamination scan across generation logs
- reproducibility contract verifier
- dual-scorer winner agreement
- skill-installed install/usage evidence gates

## Data Contracts

- Protocol manifests under `bench/protocols/`
- Datasets under `bench/datasets/pipeline-benchmark/`
- Run artifacts under `bench/results/pipeline-benchmark/<run-id>/`
- Mode split in reports: `skill_installed` vs `protocol_prompt`
