# cogworks

Turn source material into trustworthy agent skills.

`cogworks` is one skill-building product surface. The user provides links,
files, or source directories. `cogworks` either produces a production-ready
generated skill or stops with a clear trust report explaining why it will not.

## Installation

```bash
# GitHub Copilot CLI
copilot plugin install williamhallatt/cogworks

# Claude Code
/plugin marketplace add williamhallatt/cogworks
/plugin install cogworks@williamhallatt
```

Requires the target agent CLI. See [INSTALL.md](INSTALL.md) for the direct repo
install flow, Claude marketplace-source step, and bootstrap fallback.

## Quick Start

Start your agent in your project directory and invoke the `cogworks` skill in
your agent's native style.

> **Note:** Skill prefixes are agent-specific. With the Claude plugin install
> path, the explicit slash form is `/cogworks:cogworks`. Other agents may use a
> different prefix or natural-language invocation style.

```text
/cogworks:cogworks Turn these API docs into a deployable agent skill for handling webhook retries.
/cogworks:cogworks Build a skill from `_sources/auth/` that teaches correct OAuth callback handling.
/cogworks:cogworks Use these sources to create a skill named `incident-triage-playbook`.
```

`cogworks` will:
- gather the source material
- classify trust and provenance before synthesis
- synthesize the guidance into decision-ready doctrine
- package the result as a generated skill
- run deterministic validation before presenting the final output

The default output location is `_generated-skills/{slug}/`.

## Support At A Glance

Separate three things when evaluating support:

| Surface | Can install generated skills? | Product support status | Can run the internal trust-first sub-agent build path? |
|---|---|---|---|
| Claude Code | Yes | Yes | Yes |
| GitHub Copilot CLI | Yes | Yes | Yes, when its delegated-task behavior is locally validated |
| Codex | Yes | Portable generated-skill target only | No |

Codex can consume generated skills, but Codex sub-agent build support is **not**
part of the current trust-first internal build flow.

## Product Contract

`cogworks` is optimized for two things:
- quality of the generated skill
- trust in both the tool and the generated output

That means:
- there is one stable user-facing entry point: `cogworks`
- internal orchestration choices are not a user-facing mode
- the generated skill is the only primary product artifact
- weak or contradictory source material causes a fail-closed stop, not a
  production-ready result

If trust classification, contradiction handling, or deterministic validation
fails, `cogworks` returns a blocking trust report instead of shipping a dubious
skill.

## How It Works

### User-facing flow

The user experience is intentionally concise:
1. invoke `cogworks`
2. provide sources and, optionally, a desired skill name or destination
3. review only when a real overwrite or trust decision is needed
4. receive either:
   - a validated generated skill, or
   - a blocking trust report with the next required action

### Internal build path

Internally, `cogworks` uses:
- `cogworks-encode` for synthesis doctrine
- `cogworks-learn` for skill-authoring doctrine
- specialist sub-agents on supported surfaces when that improves quality and
  context isolation

Sub-agents are implementation machinery, not a public interface. They are used
to keep the coordinator context small and to give source intake, synthesis,
packaging, and validation explicit ownership.

The recommended install path is therefore plugin-first: install directly from
the `cogworks` repo so the three skills and native agent files arrive together.
The bootstrap installer remains a maintainer fallback.

## Supporting Skills

The repository ships three skills:

| Skill | Role |
|---|---|
| `cogworks` | The only normal user-facing product entry point |
| `cogworks-encode` | Internal synthesis doctrine; also available as an expert surface when you want synthesis help without full skill generation |
| `cogworks-learn` | Internal skill-authoring doctrine; also available as an expert surface for manual skill design or review |

Most users should start with `cogworks`, not with the support skills directly.

## Quality And Trust

Trust comes from layered gates:
- source trust classification before synthesis
- explicit contradiction handling and traceability
- deterministic validation of the generated skill structure
- fail-closed behavior when blocking uncertainty remains

Benchmarking and comparative evaluation still matter, but they are maintainer
surfaces under `evals/` and `scripts/`. They do not change the normal user
workflow or the generated skill output contract.

## Maintainer Notes

For maintainers investigating the internal sub-agent build path:
- see [skills/cogworks/agentic-runtime.md](skills/cogworks/agentic-runtime.md)
- see [skills/cogworks/claude-adapter.md](skills/cogworks/claude-adapter.md)
- see [skills/cogworks/copilot-adapter.md](skills/cogworks/copilot-adapter.md)
- see [tests/agentic-smoke/README.md](tests/agentic-smoke/README.md)

These are implementation and validation surfaces, not the normal product entry
point.

## Limitations

- authenticated or private web sources still require a surface capable of
  accessing them
- source quality limits output quality; cogworks can fail closed, but it cannot
  invent trustworthy evidence
- generated skills aim to follow the [Agent Skills standard](https://agentskills.io),
  so the artifact format is portable across agents that support skills
- build-surface support is narrower than artifact portability; the current
  trust-first internal build flow is supported only on Claude Code and GitHub
  Copilot CLI
- Codex support is currently limited to consuming portable generated skills, not
  running the trust-first internal build flow

## Contributing

See [CONTRIBUTIONS.md](CONTRIBUTIONS.md) for development setup, conventions, and
release process.

## License

[MIT](LICENSE)
