# Installing Cogworks Skills

## Quick Install (Recommended)

Clone the repository, then run the bootstrap installer for the surface you
actually want to use for trust-first skill generation:

```bash
git clone https://github.com/williamhallatt/cogworks.git

# Claude Code
bash cogworks/scripts/install-cogworks.sh --agent claude-code --project /path/to/your/project

# GitHub Copilot CLI
bash cogworks/scripts/install-cogworks.sh --agent copilot-cli --project /path/to/your/project
```

This bootstrap path installs:
- the three required `cogworks` skills
- the native agent definitions for the selected surface

`cogworks` is the normal user-facing entry point. `cogworks-encode` and
`cogworks-learn` remain supporting doctrine skills and expert surfaces.

To update, rerun the same bootstrap command from the repo checkout.

## Support Boundaries

Install location and build-flow support are not the same thing:

- generated skills are portable across agents that support skills
- the normal `cogworks` product flow remains one stable entry point
- the trust-first internal sub-agent build flow is currently supported only on
  Claude Code and GitHub Copilot CLI
- Codex can consume generated skills, but it is not a supported surface for the
  current trust-first build flow

If you mention Codex in local docs or examples, keep that distinction explicit.

## Installer Contract

The bootstrap installer lives at `scripts/install-cogworks.sh`.

Supported arguments:

```bash
bash scripts/install-cogworks.sh --agent claude-code --project /path/to/project
bash scripts/install-cogworks.sh --agent copilot-cli --project /path/to/project
bash scripts/install-cogworks.sh --agent claude-code --project /path/to/project --copy
```

Defaults and behavior:
- `--agent` is required and must be `claude-code` or `copilot-cli`
- `--project` is required and must point at an existing project directory
- by default the installer uses symlinks; `--copy` writes copies instead
- unsupported surfaces fail closed

Install targets:
- Claude Code: `.claude/skills/` plus `.claude/agents/`
- GitHub Copilot CLI: `.agents/skills/` plus `.github/agents/`

## Manual Skill-Only Install

Use this only when you deliberately want the three skills without the full
native-first product install:

```bash
npx skills add williamhallatt/cogworks --skill cogworks-encode --skill cogworks-learn
npx skills add williamhallatt/cogworks -a claude-code
```

This can make the skill directories available, but it does not provision the
native sub-agents that the highest-quality `cogworks` flow depends on.

## Verify Installation

```bash
ls /path/to/your/project/.claude/skills/cogworks/SKILL.md
ls /path/to/your/project/.claude/agents/cogworks-intake-analyst.md

ls /path/to/your/project/.agents/skills/cogworks/SKILL.md
ls /path/to/your/project/.github/agents/cogworks-intake-analyst.agent.md
```

## Invoking Skills

After installation, invoke `cogworks` using your agent's native skill style:

| Agent | Prefix | Example |
|-------|--------|---------|
| Claude Code | `/` | `/cogworks Turn these docs into an agent skill for incident triage.` |
| GitHub Copilot CLI | varies | consult Copilot CLI docs for the current skill invocation style |
| Codex CLI | varies | use Codex-native invocation for portable generated skills; do not treat Codex as a supported trust-first build surface |
| Other agents | varies | consult agent documentation |

## Available Skills

| Skill                       | Purpose                                   | Required |
| --------------------------- | ----------------------------------------- | -------- |
| `cogworks`                  | Product entry point for generating skills from source material | Yes      |
| `cogworks-encode`           | Synthesis doctrine and source-fidelity methodology | Yes      |
| `cogworks-learn`            | Skill-authoring doctrine and quality gates | Yes      |

## Test Generated Skills

```bash
bash scripts/test-generated-skill.sh --skill-path .claude/skills/my-skill
bash scripts/test-generated-skill.sh --skill-path .claude/skills/my-skill --with-behavioral
```

## Installing Generated Skills

When you use `cogworks`, generated skills are written to the
`_generated-skills/` staging directory. The workflow automatically installs them
to detected agents via `npx skills add`.

If automatic installation fails (e.g. Node.js not available), install manually:

```bash
npx skills add ./_generated-skills

# Example: install a generated skill to Codex
npx skills add ./_generated-skills -a codex
```

Node.js 18+ is required for the `skills` CLI. Install from [nodejs.org](https://nodejs.org/).

## Troubleshooting

- **Bootstrap install failed**: Verify the target project directory exists and rerun the installer from the repo checkout
- **Skills not discovered**: Verify SKILL.md exists in each installed skill directory and symlinks resolve
- **Missing dependencies**: the bootstrap installer requires Node.js 18+ and Python 3
- **Symlink issues on Windows**: Use `--copy` flag instead
- **Codex support confusion**: Generated skills are portable to Codex, but the
  current trust-first internal build flow is supported only on Claude Code and
  GitHub Copilot CLI

For testing generated skills, see [TESTING.md](TESTING.md).
