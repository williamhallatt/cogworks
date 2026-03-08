# Sub-Agent Smoke Runbook

Use this runbook to validate the maintainer-only sub-agent build path on a live
agent surface.

## Scope

This is a **live smoke test**, not a benchmark. It answers:
- does `cogworks` still produce a generated skill as the primary artifact?
- does the supported surface actually use the expected sub-agent build path?
- does it write the required run artifacts under `.cogworks-runs/`?
- do the run artifacts record specialist ownership and surface bindings
  truthfully?

It does **not** prove the build path is better than alternatives.

> Context hygiene: prefer a disposable output root outside the repository, for
> example `/tmp/cogworks-subagent-smoke/`. Repo-local `.cogworks-runs/` and
> `tmp-agentic-output/` are non-canonical artifact surfaces and should not be
> your default scratch locations.

If you need a preserved in-repo example artifact set for contract inspection,
use `tests/agentic-smoke/examples/copilot-native-subagents-api-auth-smoke/`.

## Fixture Sources

Use the fixture source set under:

```text
tests/agentic-smoke/fixtures/api-auth-smoke/
```

## Prerequisites

- local cogworks skills installed into the surface you are testing
- `jq`
- the target agent surface available in your shell

Optional local install command from this repo:

```bash
npx skills add . -a claude-code -y
```

## Live Smoke Procedure

1. Choose a disposable output root, preferably outside the repo.
2. Start the target agent surface in a directory where the fixture path is
   available.
3. Invoke `cogworks` naturally for skill generation. Example:

```text
/cogworks Turn tests/agentic-smoke/fixtures/api-auth-smoke/ into a skill named api-auth-smoke and write it to /tmp/cogworks-subagent-smoke/skills/
```

Outside the repo root, replace the fixture path with an absolute path.

4. Approve file creation if prompted.
5. Let the run finish.

Surface-specific expectations:
- Claude Code: expect `execution_surface = claude-cli`
- GitHub Copilot CLI: expect `execution_surface = copilot-cli`

This smoke run is only valid for surfaces where the real sub-agent build path is
available. If the surface cannot provide it, the product should fail closed
rather than silently present an equivalent-looking single-agent result.

## Expected User-Facing Behavior

The live run should:
- behave like one stable `cogworks` build flow, not a mode-selection UI
- preserve the generated skill as the primary output
- write the skill to the requested disposable output path
- create a run root alongside that output path, typically under
  `/tmp/cogworks-subagent-smoke/.cogworks-runs/`
- keep internal runtime jargon secondary to the generated skill result

## Validate Artifacts

After the run completes, locate the run root and validate it.

Example:

```bash
find /tmp/cogworks-subagent-smoke -path '*/.cogworks-runs/*' -maxdepth 5 -type f | sort
```

Then run:

```bash
bash scripts/validate-agentic-run.sh \
  --run-root <resolved-run-root> \
  --skill-path /tmp/cogworks-subagent-smoke/skills/ \
  --expect-surface claude-cli
```

Copilot example:

```bash
bash scripts/validate-agentic-run.sh \
  --run-root <resolved-run-root> \
  --skill-path /tmp/cogworks-subagent-smoke/skills/ \
  --expect-surface copilot-cli
```

## Manual Review Checklist

Confirm all of the following:
- the generated skill exists at the requested output path
- `run-manifest.json` exists
- `dispatch-manifest.json` exists
- `stage-index.json` exists
- `final-summary.md` exists either at the run root or under `final-review/`
- all five stage directories exist
- each stage directory contains `stage-status.json`
- `run-manifest.json` records `run_type: "subagent-skill-build"`
- `execution_surface` is present
- `specialist_profile_source` is present
- `dispatch-manifest.json` records canonical role profiles, surface bindings,
  model policy, and dispatch modes
- the generated skill itself does **not** leak runtime metadata such as engine
  mode, execution surface, or run root into its public frontmatter or
  `metadata.json`

## Preserved Example

The repository keeps one canonical example under:

```text
tests/agentic-smoke/examples/copilot-native-subagents-api-auth-smoke/
```

Treat it as maintainer evidence only, not as a default instruction surface.
