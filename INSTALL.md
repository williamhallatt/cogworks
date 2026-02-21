# Installing Cogworks Agent & Skills

This guide covers Claude and Codex installation plus the unified testing workflow.

## Automated Installation (Recommended)

```bash
tar -xzf cogworks-{version}.tar.gz
cd cogworks-{version}
./install.sh
```

Non-interactive examples:

```bash
./install.sh --local
./install.sh --global
./install.sh --target codex --local
./install.sh --target codex --global
./install.sh --dry-run
```

## Both Targets (Claude + Codex)

Install Claude and Codex components in a single run:

```bash
./install.sh --target both --local
./install.sh --target both --global
```

## Codex Installation

Codex uses skills under `.agents/skills`:

```bash
./install.sh --target codex --local
./install.sh --target codex --global
./install.sh --codex
```

## Manual Installation

Copy Claude components:

```bash
cp -r cogworks-{version}/.claude/agents your-project/.claude/
cp -r cogworks-{version}/.claude/skills/cogworks-* your-project/.claude/skills/
```

Copy Codex components:

```bash
cp -r cogworks-{version}/.agents/skills/* your-project/.agents/skills/
```

Testing framework is shared and path-neutral:

```bash
cp -r cogworks-{version}/tests/framework your-project/tests/
```

## Verify Installation

```bash
ls your-project/.claude/agents/cogworks.md
ls your-project/.claude/skills/cogworks-encode/SKILL.md
ls your-project/.claude/skills/cogworks-learn/SKILL.md
ls your-project/tests/framework/scripts/cogworks-eval.py
```

## Check for Updates

Run from the installed/extracted cogworks root:

```bash
bash scripts/check-cogworks-updates.sh
```

The checker compares your local packaged version (`install.sh`) with the latest GitHub release.

## Test Generated Skills

```bash
bash scripts/test-generated-skill.sh --skill-path .claude/skills/my-skill
bash scripts/test-generated-skill.sh --skill-path .agents/skills/my-skill --with-behavioral
```

## Pipeline Benchmark

```bash
bash scripts/test-cogworks-pipeline.sh --mode offline --run-id 20260220-ab1
```

Real mode:

```bash
export COGWORKS_BENCH_CLAUDE_CMD="your-claude-runner --sources '{sources_path}' --out '{out_dir}'"
export COGWORKS_BENCH_CODEX_CMD="your-codex-runner --sources '{sources_path}' --out '{out_dir}'"
bash scripts/test-cogworks-pipeline.sh --mode real --run-id 20260220-ab1
```

## Recursive Improvement Round

Canonical runbook: `tests/datasets/recursive-round/README.md`

```bash
cp tests/datasets/recursive-round/round-manifest.example.json \
  tests/datasets/recursive-round/round-manifest.local.json
bash scripts/pin-test-bundle-hash.sh \
  tests/datasets/recursive-round/round-manifest.local.json
source scripts/recursive-env.example.sh
bash scripts/run-recursive-round.sh \
  --round-manifest tests/datasets/recursive-round/round-manifest.local.json \
  --mode fast \
  --run-id rr-20260220-fast1
```

## Troubleshooting

- Missing `jq` or `PyYAML`: install dependencies then re-run tests.
- Missing benchmark metrics: ensure pipeline runner writes `<out_dir>/metrics.json`.
- Missing behavioral traces: scaffold with `python3 tests/framework/scripts/cogworks-eval.py behavioral scaffold --skill <slug>`.
