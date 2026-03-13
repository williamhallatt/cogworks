# Installing Cogworks

## Quick Install (Recommended)

Install directly from the main `cogworks` repository using the native plugin
surface for your agent:

```bash
# GitHub Copilot CLI
copilot plugin install williamhallatt/cogworks

# Claude Code
/plugin marketplace add williamhallatt/cogworks
/plugin install cogworks@williamhallatt
```

This plugin path installs:
- the three required `cogworks` skills
- the native agent definitions for the selected surface

`cogworks` is the normal user-facing entry point. `cogworks-encode` and
`cogworks-learn` remain supporting doctrine skills and expert surfaces.

To update:
- Copilot: rerun `copilot plugin install williamhallatt/cogworks`
- Claude: refresh the marketplace source if needed, then reinstall

## Support Boundaries

Install location and build-flow support are not the same thing:

- generated skills are portable across agents that support skills
- the normal `cogworks` product flow remains one stable entry point
- the trust-first internal sub-agent build flow is currently supported only on
  Claude Code and GitHub Copilot CLI
- Codex can consume generated skills, but it is not a supported surface for the
  current trust-first build flow

If you mention Codex in local docs or examples, keep that distinction explicit.

## Direct Install Contract

Primary supported plugin-install flows:

```bash
# GitHub Copilot CLI
copilot plugin install williamhallatt/cogworks

# Claude Code
/plugin marketplace add williamhallatt/cogworks
/plugin install cogworks@williamhallatt
```

Packaging surfaces in this repo:
- `plugin.json`: Copilot plugin manifest
- `.claude-plugin/plugin.json`: Claude plugin manifest
- `.claude-plugin/marketplace.json`: Claude marketplace-source catalog
- `skills/`: shipped skills
- `agents/`: shipped plugin agent files

## Bootstrap Fallback

Use this only for local development, offline testing, or if a native plugin
install path is temporarily unavailable:

```bash
bash scripts/install-cogworks.sh --agent claude-code --project /path/to/project
bash scripts/install-cogworks.sh --agent copilot-cli --project /path/to/project
bash scripts/install-cogworks.sh --agent claude-code --project /path/to/project --copy
```

The bootstrap installer writes repo-local skills and native agent files into a
target project directory.

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
# Plugin package surfaces in this repo
ls plugin.json
ls .claude-plugin/plugin.json
ls agents/cogworks-intake-analyst.agent.md

# Bootstrap fallback outputs
ls /path/to/your/project/.claude/agents/cogworks-intake-analyst.md
ls /path/to/your/project/.github/agents/cogworks-intake-analyst.agent.md
```

## Invoking Skills

After installation, invoke `cogworks` using your agent's native skill style:

| Agent | Prefix | Example |
|-------|--------|---------|
| Claude Code | `/` | `/cogworks:cogworks Turn these docs into an agent skill for incident triage.` |
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

- **Plugin install failed**: Verify the target CLI supports plugins and rerun the platform-native install command
- **Claude install needs a source first**: Add `williamhallatt/cogworks` as a marketplace source, then install `cogworks@williamhallatt`
- **Bootstrap install failed**: Verify the target project directory exists and rerun the fallback installer from the repo checkout
- **Skills not discovered**: Verify SKILL.md exists in each installed skill directory and symlinks resolve
- **Missing dependencies**: the bootstrap fallback requires Node.js 18+ and Python 3
- **Symlink issues on Windows**: Use `--copy` flag instead
- **Codex support confusion**: Generated skills are portable to Codex, but the
  current trust-first internal build flow is supported only on Claude Code and
  GitHub Copilot CLI

For testing generated skills, see [TESTING.md](TESTING.md).
