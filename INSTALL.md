# Installing Cogworks Skills

## Quick Install (Recommended)

Use the [`npx skills`](https://www.npmjs.com/package/skills) CLI to add all cogworks skills with one command:

```bash
npx skills add williamhallatt/cogworks
```

This installs all cogworks skills to detected agents using symlinks.

## Installation Options

```bash
# Install specific skills only (NOTE: standaloe cogworks will not work without cogworks-encode and cogworks-learn!)
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

To update, or remove, please see [npx skills documentation](https://www.npmjs.com/package/skills) for available commands:

## Manual Installation

Clone the repository and copy skills directly:

```bash
git clone https://github.com/williamhallatt/cogworks.git
cp -r cogworks/skills/cogworks your-project/.claude/skills/
cp -r cogworks/skills/cogworks-encode your-project/.claude/skills/
cp -r cogworks/skills/cogworks-learn your-project/.claude/skills/
```

The three skills above are the minimum required set. Optional skills:

```bash
cp -r cogworks/skills/claude-prompt-engineering your-project/.claude/skills/
cp -r cogworks/skills/skill-evaluation your-project/.claude/skills/
```

## Verify Installation

```bash
ls your-project/.claude/skills/cogworks/SKILL.md
ls your-project/.claude/skills/cogworks-encode/SKILL.md
ls your-project/.claude/skills/cogworks-learn/SKILL.md
```

## Available Skills

| Skill                       | Purpose                                   | Required |
| --------------------------- | ----------------------------------------- | -------- |
| `cogworks`                  | Orchestrator - full encode workflow       | Yes      |
| `cogworks-encode`           | Synthesis methodology (8-phase process)   | Yes      |
| `cogworks-learn`            | Skill writing expertise and quality gates | Yes      |
| `claude-prompt-engineering` | Claude prompt optimisation guidance       | No       |
| `codex-prompt-engineering`  | Codex prompt optimisation guidance        | No       |
| `skill-evaluation`          | Skill evaluation methodology              | No       |

## Test Generated Skills

```bash
bash scripts/test-generated-skill.sh --skill-path .claude/skills/my-skill
bash scripts/test-generated-skill.sh --skill-path .claude/skills/my-skill --with-behavioral
```

## Troubleshooting

- **Skills not discovered**: Verify SKILL.md exists in each skill directory and symlinks resolve
- **Missing dependencies**: `npx skills` requires Node.js 18+
- **Symlink issues on Windows**: Use `--copy` flag instead
