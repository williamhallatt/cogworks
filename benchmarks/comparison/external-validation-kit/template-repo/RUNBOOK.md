# RUNBOOK

## 1) Repository Setup

```bash
git clone <new-benchmark-repo-url> skill-benchmark-lab
cd skill-benchmark-lab
```

Add pinned vendor commits:
```bash
git submodule add <cogworks-url> vendors/cogworks
git submodule add <generator-a-url> vendors/generator-a
git submodule add <generator-b-url> vendors/generator-b
git -C vendors/cogworks checkout <cogworks-commit>
git -C vendors/generator-a checkout <generator-a-commit>
git -C vendors/generator-b checkout <generator-b-commit>
```

## 2) Validate Protocol

Install validation dependency:
```bash
python3 -m pip install jsonschema
```

Then validate:
```bash
python3 - <<'PY'
import json
from pathlib import Path
from jsonschema import validate
schema=json.loads(Path('bench/protocols/protocol.schema.json').read_text())
for p in ['bench/protocols/protocol-pilot.json','bench/protocols/protocol-hard-v2.json']:
    validate(instance=json.loads(Path(p).read_text()), schema=schema)
print('protocol schema validation passed')
PY
```

## 3) Smoke Run (Offline)

```bash
bash bench/scripts/run-protocol-benchmark.sh \
  --protocol bench/protocols/protocol-pilot.json \
  --mode offline \
  --run-id pilot-smoke-$(date +%Y%m%d-%H%M%S) \
  --force
```

## 4) Real Run (Authoritative)

Prereqs:
- `codex` authenticated
- `npx skills` available

```bash
export BENCH_MODEL_FAMILY=gpt-5-codex
bash bench/scripts/run-protocol-benchmark.sh \
  --protocol bench/protocols/protocol-hard-v2.json \
  --mode real \
  --repeats 3 \
  --run-id hard-real-$(date +%Y%m%d-%H%M%S) \
  --force
```

## 5) Required Outputs

Per run:
- `pilot-summary.json`
- `pilot-report.md`
- `benchmark-summary.json` (compat)
- `benchmark-report.md` (compat)
- `contamination-report.json`
- `reproducibility-report.json`
- `trust-report.json`
- `trust-report.md`

Per case run directory:
- `execution-mode.json`
- `skill-install-report.json`
- `skill-use-evidence.json`

## 6) Pass Criteria for High Trust

- contamination findings = 0
- reproducibility report = pass
- scorer-v1 winner == scorer-v2 winner
- scorer-v1/v2 skill-installed winner agreement
- repeats >= protocol minimum
- all `skill_installed` cases pass install and usage evidence gates
- run is authoritative (`--mode real` and executed in CI)

If any condition fails, treat result as non-authoritative.
