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
It does prove that the saved artifact set records the canonical role/profile
bindings, dispatch modes, and per-stage `tool_scope` values defined by the
maintained contract.

> Context hygiene: prefer a disposable output root outside the repository, for
> example `/tmp/cogworks-subagent-smoke/`. Repo-local `.cogworks-runs/` and
> `tmp-agentic-output/` are non-canonical artifact surfaces and should not be
> your default scratch locations.

If you need preserved in-repo artifact sets for contract inspection, use:

- `tests/agentic-smoke/examples/copilot-cli-release-api-auth-smoke-20260308/`
- `tests/agentic-smoke/examples/claude-cli-release-api-auth-smoke-20260309-r5/`
- `tests/agentic-smoke/examples/claude-cli-no-task-fail-closed-20260308/`

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

For Claude Code live runs, also render the project-scoped Claude agents from
the canonical role profiles:

```bash
python3 scripts/render-agentic-role-bindings.py
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

## Fail-Closed Evidence

Release-grade validation should also include one negative-path run that stops
with a blocking report and does not produce an installable skill. After that
run completes, validate the evidence with:

```bash
bash tests/validate-fail-closed-run.sh \
  --report-path <blocking-report-path> \
  --skill-path <blocked-output-path> \
  --expect-pattern "BLOCKED - Runtime Misconfiguration"
```

Release-grade validation should always include at least one stable
`--expect-pattern` check so the validator confirms the failure reason text as
well as the absence of `SKILL.md`.

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
  model policy, dispatch modes, and canonical per-stage `tool_scope` values
- the generated skill itself does **not** leak runtime metadata such as engine
  mode, execution surface, or run root into its public frontmatter or
  `metadata.json`

## Preserved Examples

The repository keeps canonical maintainer evidence under:

```text
tests/agentic-smoke/examples/copilot-cli-release-api-auth-smoke-20260308/
tests/agentic-smoke/examples/claude-cli-release-api-auth-smoke-20260309-r5/
tests/agentic-smoke/examples/claude-cli-no-task-fail-closed-20260308/
```

Treat these as maintainer evidence only, not as default instruction surfaces.
