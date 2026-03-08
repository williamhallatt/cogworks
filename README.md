# cogworks

Turn source material into trustworthy agent skills.

`cogworks` is a single skill-building product surface. The user provides links,
files, or source directories. `cogworks` either produces a production-ready
generated skill or stops with a clear trust report explaining why it will not.

## Installation

```bash
npx skills add williamhallatt/cogworks
```

Requires Node.js 18+. See [INSTALL.md](INSTALL.md) for installation options and
manual verification steps.

## Quick Start

Start your agent in your project directory and invoke the `cogworks` skill in
your agent's native style.

> **Note:** Skill prefixes are agent-specific. Examples use `/` for Claude Code.
> Other agents may use a different prefix or natural-language invocation style.

```text
/cogworks Turn these API docs into a deployable agent skill for handling webhook retries.
/cogworks Build a skill from `_sources/auth/` that teaches correct OAuth callback handling.
/cogworks Use these sources to create a skill named `incident-triage-playbook`.
```

`cogworks` will:
- gather the source material
- classify trust and provenance before synthesis
- synthesize the guidance into decision-ready doctrine
- package the result as a generated skill
- run deterministic validation before presenting the final output

The default output location is `_generated-skills/{slug}/`.

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

## Supported Execution Surfaces

Current product direction:
- **Claude Code**: first-class target for the trust-first sub-agent build path
- **GitHub Copilot CLI**: first-class only when its delegated-task behavior is
  proven by local maintainer smoke evidence
- **Codex**: generated skills remain portable there, but Codex sub-agent build
  support is deferred for now

`cogworks` should not claim cross-agent parity unless the surface has a real,
tested path.

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
- generated skills aim to follow the [Agent Skills standard](https://agentskills.io)
  where the artifact format is portable, but the build system itself is not
  assumed to be equally portable across agent surfaces

## Contributing

See [CONTRIBUTIONS.md](CONTRIBUTIONS.md) for development setup, conventions, and
release process.

## License

[MIT](LICENSE)
