# Installing Cogworks Skills

## Quick Install (Recommended)

Use the [`npx skills`](https://www.npmjs.com/package/skills) CLI to add all cogworks skills with one command:

```bash
npx skills add williamhallatt/cogworks
```

> NOTE: `cogworks` is the normal user-facing entry point. `cogworks-encode` and
> `cogworks-learn` ship as supporting doctrine skills and can still be used
> independently as expert surfaces.

To update or remove, see the [npx skills documentation](https://www.npmjs.com/package/skills).

## Support Boundaries

Install location and build-flow support are not the same thing:

- generated skills are portable across agents that support skills
- the normal `cogworks` product flow remains one stable entry point
- the trust-first internal sub-agent build flow is currently supported only on
  Claude Code and GitHub Copilot CLI
- Codex can consume generated skills, but it is not a supported surface for the
  current trust-first build flow

If you mention Codex in local docs or examples, keep that distinction explicit.

## Installation Options

```bash
# Install specific skills only
npx skills add williamhallatt/cogworks --skill cogworks-encode --skill cogworks-learn

# Install to a specific supported build surface
npx skills add williamhallatt/cogworks -a claude-code

# Install globally (across all projects)
npx skills add williamhallatt/cogworks -g

# Copy files instead of symlinks
npx skills add williamhallatt/cogworks --copy

# List available skills without installing
npx skills add williamhallatt/cogworks --list
```

## Manual Installation

Clone the repository and copy skills directly:

```bash
git clone https://github.com/williamhallatt/cogworks.git

# For Claude Code
cp -r cogworks/skills/cogworks your-project/.claude/skills/
cp -r cogworks/skills/cogworks-encode your-project/.claude/skills/
cp -r cogworks/skills/cogworks-learn your-project/.claude/skills/

# For agents using the shared `.agents/skills/` directory
cp -r cogworks/skills/cogworks your-project/.agents/skills/
cp -r cogworks/skills/cogworks-encode your-project/.agents/skills/
cp -r cogworks/skills/cogworks-learn your-project/.agents/skills/
```

The three skills above are the minimum required set.

Installing the files into `.agents/skills/` does not imply every agent supports
the same internal build behavior. For Codex specifically, treat this as
generated-skill portability support, not trust-first build-flow support.

## Verify Installation

```bash
# For Claude Code
ls your-project/.claude/skills/cogworks/SKILL.md
ls your-project/.claude/skills/cogworks-encode/SKILL.md
ls your-project/.claude/skills/cogworks-learn/SKILL.md

# For agents using the shared `.agents/skills/` directory
ls your-project/.agents/skills/cogworks/SKILL.md
ls your-project/.agents/skills/cogworks-encode/SKILL.md
ls your-project/.agents/skills/cogworks-learn/SKILL.md
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

- **Skills not discovered**: Verify SKILL.md exists in each skill directory and symlinks resolve
- **Missing dependencies**: `npx skills` requires Node.js 18+
- **Symlink issues on Windows**: Use `--copy` flag instead
- **Codex support confusion**: Generated skills are portable to Codex, but the
  current trust-first internal build flow is supported only on Claude Code and
  GitHub Copilot CLI

For testing generated skills, see [TESTING.md](TESTING.md).
