# Agentic Smoke Runbook

Use this runbook to validate that the new opt-in `--engine agentic` flow actually works on a live agent surface.

## Scope

This is a **live smoke test**, not a benchmark. It answers:
- does `cogworks` recognize `--engine agentic`?
- does it still generate a skill as the primary artifact?
- does it write the required run artifacts under `.cogworks-runs/`?
- does the current surface report its adapter behavior honestly, including degraded single-agent execution when native subagents are unavailable?

It does **not** prove the agentic engine is better than legacy.

> Context hygiene: prefer a disposable output root outside the repository, for example `/tmp/cogworks-agentic-smoke/`. Repo-local `.cogworks-runs/` and `tmp-agentic-output/` are non-canonical artifact surfaces and should not be your default scratch locations.

## Fixture Sources

Use the tiny source set under:

```text
tests/agentic-smoke/fixtures/api-auth-smoke/
```

These are intentionally small so the smoke run completes quickly.
They are still large enough to trigger the simplified 5-stage run, so expect
the validation tail to take a few minutes.

## Prerequisites

- local cogworks skill installed into the surface you are testing
- `jq`
- the target agent surface available in your shell

Optional local install command from this repo:

```bash
npx skills add . -a claude-code -y
```

## Live Smoke Procedure

1. Choose one of these working styles:
   - preferred: use a disposable working directory outside the repo and replace the source argument with the absolute path to `tests/agentic-smoke/fixtures/api-auth-smoke/`
   - allowed but less clean: start the tested agent surface from the cogworks repo root and use the repo-relative fixture path shown below
2. Start the target agent surface in that directory.
3. Run the equivalent cogworks command for that surface:

```text
/cogworks encode --engine agentic api-auth-smoke from tests/agentic-smoke/fixtures/api-auth-smoke/ to /tmp/cogworks-agentic-smoke/skills/
```

If you are outside the repo root, use an absolute path instead:

```text
/cogworks encode --engine agentic api-auth-smoke from /absolute/path/to/cogworks/tests/agentic-smoke/fixtures/api-auth-smoke/ to /tmp/cogworks-agentic-smoke/skills/
```

4. Approve the run when cogworks asks to proceed with file creation.
5. Let the run finish.

Surface-specific expectations:
- Claude Code: expect `execution_surface = claude-cli` and, when the `Task` tool is available, `execution_adapter = native-subagents`
- GitHub Copilot CLI: expect `execution_surface = copilot-cli`; native-subagent execution is valid only if the surface exposes a real spawn primitive, otherwise expect `execution_adapter = single-agent-fallback`

Do not classify the run as stalled just because `deterministic-validation/` or
`final-review/` appears later than the earlier stage directories.

## Expected User-Facing Behavior

The live run should:
- explicitly acknowledge `agentic` mode
- preserve generated skills as the primary output
- write the skill to the requested disposable output path
- create a run root alongside that output path, typically under `/tmp/cogworks-agentic-smoke/.cogworks-runs/`
- mention or record `execution_surface`
- mention or record `execution_adapter`
- mention or record `execution_mode`
- mention or record `specialist_profile_source`
- fall back honestly to degraded single-agent execution if subagents are unavailable

## Validate Artifacts

After the run completes, locate the run root and validate it.

Example:

```bash
find . -path '*/.cogworks-runs/*' -maxdepth 5 -type f | sort
```

Then run:

```bash
bash scripts/validate-agentic-run.sh \
  --run-root <resolved-run-root> \
  --skill-path /tmp/cogworks-agentic-smoke/skills/
```

If you know the surface and adapter that should have been used, add:

```bash
  --expect-surface claude-cli \
  --expect-adapter native-subagents
```

Copilot CLI examples:

```bash
  --expect-surface copilot-cli \
  --expect-adapter native-subagents

  --expect-surface copilot-cli \
  --expect-adapter single-agent-fallback
```

## Manual Review Checklist

Confirm all of the following:
- the generated skill exists at the requested output path
- `run-manifest.json` exists
- `dispatch-manifest.json` exists for `native-subagents` runs
- `stage-index.json` exists
- `final-summary.md` exists either at the run root or under `final-review/`
- all five stage directories exist
- each stage directory contains `stage-status.json`
- `run-manifest.json` records `engine_mode: "agentic"`
- `execution_surface` is present
- `execution_adapter` is present
- `execution_mode` is present
- `specialist_profile_source` is present
- `agentic_path` is present
- `dispatch-manifest.json` records canonical role profiles, surface bindings, model policy, and dispatch modes when the run claims `native-subagents`
- the run does not claim native subagent execution if the tested surface could not actually provide it

## Legacy Comparison Smoke

Repeat once without `--engine agentic`:

```text
/cogworks encode api-auth-smoke from tests/agentic-smoke/fixtures/api-auth-smoke/ to ./tmp-legacy-output/
```

Outside the repo root, replace the source argument with the same absolute path you used for the agentic smoke.

Expected difference:
- no agentic run contract is claimed
- no `.cogworks-runs/` requirement is implied
- output is still a generated skill
