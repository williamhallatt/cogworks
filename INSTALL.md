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

## Installation Options

```bash
# Install specific skills only
npx skills add williamhallatt/cogworks --skill cogworks-encode --skill cogworks-learn

# Install to specific agents
npx skills add williamhallatt/cogworks -a claude-code -a codex

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

# For Copilot, Codex, Cursor, and other agents
cp -r cogworks/skills/cogworks your-project/.agents/skills/
cp -r cogworks/skills/cogworks-encode your-project/.agents/skills/
cp -r cogworks/skills/cogworks-learn your-project/.agents/skills/
```

The three skills above are the minimum required set.

## Verify Installation

```bash
# For Claude Code
ls your-project/.claude/skills/cogworks/SKILL.md
ls your-project/.claude/skills/cogworks-encode/SKILL.md
ls your-project/.claude/skills/cogworks-learn/SKILL.md

# For Copilot, Codex, Cursor, and other agents
ls your-project/.agents/skills/cogworks/SKILL.md
ls your-project/.agents/skills/cogworks-encode/SKILL.md
ls your-project/.agents/skills/cogworks-learn/SKILL.md
```

## Invoking Skills

After installation, invoke `cogworks` using your agent's native skill style:

| Agent | Prefix | Example |
|-------|--------|---------|
| Claude Code | `/` | `/cogworks Turn these docs into an agent skill for incident triage.` |
| Codex CLI | varies | natural language or see Codex docs |
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
```

Node.js 18+ is required for the `skills` CLI. Install from [nodejs.org](https://nodejs.org/).

## Troubleshooting

- **Skills not discovered**: Verify SKILL.md exists in each skill directory and symlinks resolve
- **Missing dependencies**: `npx skills` requires Node.js 18+
- **Symlink issues on Windows**: Use `--copy` flag instead

For testing generated skills, see [TESTING.md](TESTING.md).
