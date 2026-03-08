# Cogworks Blocking Report

**Run ID:** 20260308-225034
**Topic:** api-auth-smoke-claude
**Date:** 2026-03-08T12:52:22Z
**Status:** BLOCKED - Runtime Misconfiguration

## Blocking Issue

The validated sub-agent build path for Claude Code requires specific agent definition files that are missing from the repository.

### Required Agent Files (Not Found)

According to `/home/will/code/cogworks/.claude/skills/cogworks/claude-adapter.md`, the following files must exist:

- `.claude/agents/cogworks-intake-analyst.md`
- `.claude/agents/cogworks-synthesizer.md`
- `.claude/agents/cogworks-composer.md`
- `.claude/agents/cogworks-validator.md`

### Verification Results

```bash
$ ls -la /home/will/code/cogworks/.claude/agents/cogworks-*.md
ls: cannot access '/home/will/code/cogworks/.claude/agents/cogworks-*.md': No such file or directory
```

### Contract Violation

From `claude-adapter.md`:
> "If any required Claude agent file is missing, stop and surface the runtime misconfiguration."

From `agentic-runtime.md`:
> "If the current surface cannot provide the validated sub-agent path, the build should fail closed rather than degrade and present the result as equivalent."

## Resolution Path

To unblock this run, one of the following must occur:

1. **Install missing agent definitions**: Create the four required agent definition files at the paths specified in `claude-adapter.md`, mapping the canonical role profiles from `role-profiles.json` to Claude agent prompt files.

2. **Use alternative execution mode**: If the sub-agent build path is not required for this validation run, explicitly configure cogworks to use a monolithic execution mode (if one exists and is documented).

3. **Platform limitation**: If these agent files cannot be created on this surface, acknowledge that the validated trust-first build flow is not available on this Claude Code installation.

## Source Inputs (Pre-Trust Classification)

The following sources were collected before trust classification:

- `/home/will/code/cogworks/tests/agentic-smoke/fixtures/api-auth-smoke/01-status-codes.md`
- `/home/will/code/cogworks/tests/agentic-smoke/fixtures/api-auth-smoke/02-token-handling.md`

**Trust classification:** Not performed (blocked before Stage 1)

## Intended Outputs (Not Produced)

- **Skill path:** `/tmp/cogworks-release-20260308-225034/claude/skill-output/api-auth-smoke-claude`
- **Run root:** Would have been `{skill_path_parent}/.cogworks-runs/api-auth-smoke-claude/{run_id}/`

## Recommendation

This blocking report satisfies the user's requested fail-closed behaviour: "If the run blocks, write a blocking report to /tmp/cogworks-release-20260308-225034/claude/blocking-report.md instead of producing an installable skill."

The cogworks system correctly refused to proceed with an incomplete runtime rather than producing an untrusted or degraded output.
