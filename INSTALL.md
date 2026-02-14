# Installing Cogworks Agent & Skills

This guide explains how to install the cogworks agent and its required skills into your Claude Code project.

## Quick Start

### Using tar.gz (Linux/macOS)

```bash
# Extract the archive
tar -xzf cogworks-{version}.tar.gz

# Copy to your Claude Code project
cp -r cogworks-{version}/.claude/* your-project/.claude/
```

### Using zip (all platforms)

```bash
# Extract the archive
unzip cogworks-{version}.zip

# Copy to your Claude Code project
cp -r cogworks-{version}/.claude/* your-project/.claude/
```

## Detailed Installation

### 1. Create `.claude/` structure (if needed)

If your project doesn't have a `.claude/` directory yet, create it:

```bash
mkdir -p your-project/.claude/agents
mkdir -p your-project/.claude/skills
```

### 2. Install the cogworks agent

Copy the agent file:

```bash
cp cogworks-{version}/.claude/agents/cogworks.md your-project/.claude/agents/
```

### 3. Install required skills

The cogworks agent **requires** these skills to function:

- **cogworks-encode** - Synthesis methodology for combining multiple sources
- **cogworks-learn** - Expertise in writing and structuring skills

Optional skill included in releases:

- **cogworks-test** - Testing and validation framework (requires test-framework)

Install all skills and dependencies:

```bash
cp -r cogworks-{version}/.claude/skills/cogworks-* your-project/.claude/skills/
cp -r cogworks-{version}/.claude/test-framework your-project/.claude/
```

### 4. Verify installation

Your `.claude/` directory structure should now look like:

```
your-project/
└── .claude/
    ├── agents/
    │   └── cogworks.md
    ├── skills/
    │   ├── cogworks-encode/
    │   │   ├── SKILL.md
    │   │   └── reference.md
    │   ├── cogworks-learn/
    │   │   ├── SKILL.md
    │   │   ├── patterns.md
    │   │   ├── examples.md
    │   │   ├── reference.md
    │   │   └── persuasion-principles.md
    │   ├── cogworks-test/
    │   │   └── SKILL.md
    │   └── [other cogworks-* skills]/
    └── test-framework/              # Required by cogworks-test
        ├── config/
        ├── graders/
        ├── scripts/
        └── templates/
```

## Usage

Once installed, the cogworks agent can be invoked in Claude Code:

### Auto-invocation

Claude automatically loads the cogworks skill when your request is related to:

- Synthesizing knowledge from multiple sources
- Learning how to write skills
- Other cogworks-related tasks

### Manual invocation

Force load cogworks by typing:

```
@cogworks <your request>
```

Or use the `/cogworks` slash command in Claude Code.

## Troubleshooting

### "cogworks-encode skill not found"

**Cause:** The required `cogworks-encode` skill is not installed.

**Solution:**

```bash
cp -r cogworks-{version}/.claude/skills/cogworks-encode your-project/.claude/skills/
```

### "cogworks-learn skill not found"

**Cause:** The required `cogworks-learn` skill is not installed.

**Solution:**

```bash
cp -r cogworks-{version}/.claude/skills/cogworks-learn your-project/.claude/skills/
```

### Skill not loading in Claude Code

**Cause:** Skills may not load immediately after copying files.

**Solution:**

1. Close and reopen the Claude Code editor
2. Verify `.claude/` directory is at your project root (same level as `.git/`)
3. Check that SKILL.md files are present in each skill directory

### File permission errors

**Cause:** Files copied with incorrect permissions on Linux/macOS.

**Solution:**

```bash
chmod 644 your-project/.claude/**/*.md
chmod 755 your-project/.claude
chmod 755 your-project/.claude/agents
chmod 755 your-project/.claude/skills
```

## Updating

To update to a newer version:

1. Extract the new release archive
2. Back up your current `.claude/` directory:
   ```bash
   cp -r your-project/.claude your-project/.claude.backup
   ```
3. Copy new files (replacing existing):
   ```bash
   cp -r cogworks-{new-version}/.claude/* your-project/.claude/
   ```
4. If you have custom skills, restore them from backup

## Uninstalling

To remove cogworks and its skills:

```bash
# Keep cogworks agent but remove skills
rm -r your-project/.claude/skills/cogworks-*

# Remove agent
rm your-project/.claude/agents/cogworks.md

# Remove entire .claude directory (if no other agents/skills)
rm -r your-project/.claude/
```

## Platform Support

- ✅ **Linux** (Ubuntu and derivatives) - Fully supported
- ✅ **macOS** - File structure compatible
- ✅ **Windows** - File structure compatible (use WSL for best results)

> **Note:** Cogworks uses Linux-specific paths in some skills. See [ROADMAP.md](ROADMAP.md) for cross-platform support plans.

## Getting Help

For issues with cogworks installation or usage:

1. Check the [README.md](README.md) for project overview
2. Review [ROADMAP.md](ROADMAP.md) for known limitations
3. Open an issue on the [GitHub repository](https://github.com/williamhallatt/cogworks)

## Version Information

This release contains:

- **cogworks agent** - Core skill synthesis and learning orchestration
- **cogworks-encode** - Multi-source synthesis methodology
- **cogworks-learn** - Skill authoring expertise
- **cogworks-test** (if included) - Testing and evaluation framework

See included `README.md` for full documentation.
