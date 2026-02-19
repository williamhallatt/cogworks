# Installing Cogworks Agent & Skills

This guide explains how to install the cogworks agent and its required skills into your Claude Code project.

## Automated Installation (Recommended)

The cogworks release includes an installation script that handles setup automatically.

### Extract and Run

#### Linux/macOS

```bash
tar -xzf cogworks-{version}.tar.gz
cd cogworks-{version}
./install.sh
```

#### Windows (using Git Bash or WSL)

```bash
unzip cogworks-{version}.zip
cd cogworks-{version}
./install.sh
```

The script will:
- Present a menu to choose installation location (local or global)
- Create necessary directories
- Copy agent, skills, and test framework
- Validate the installation
- Provide next steps

### Non-Interactive Installation

For automation or CI/CD:

```bash
# Install to current project
./install.sh --local

# Install to personal directory
./install.sh --global

# Force overwrite existing files
./install.sh --global --force

# Preview changes without modifying files
./install.sh --local --dry-run
```

Run `./install.sh --help` for all options.

---

## Manual Installation

If you prefer manual installation or need custom setup, follow these instructions.

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

### Dependencies (for cogworks-test)

The deterministic checks require:

- `jq`
- `python3` with `PyYAML` installed

Example install commands:

```bash
# Ubuntu/Debian
sudo apt-get install -y jq python3-pip
python3 -m pip install pyyaml
```

### 4. Verify installation

Your `.claude/` directory structure should now look like:

```bash
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

See [README.md](README.md) for instructions on using the `cogworks` agent and its skills in your Claude Code projects.

## Troubleshooting

### Skill not loading in Claude Code

**Cause:** Skills may not load immediately after copying files.

**Solution:**

1. Close and reopen the Claude Code editor
2. Verify `.claude/` directory is at your project root (same level as `.git/`)
3. Check that SKILL.md files are present in each skill directory

## Updating

To update to a newer version:

1. Extract the new release archive
2. Back up your current `.claude/` directory (just in case, but the new release should be a drop-in replacement):

   ```bash
   cp -r your-project/.claude your-project/.claude.backup
   ```

3. Copy new files (replacing existing):

   ```bash
   cp -r cogworks-{new-version}/.claude/* your-project/.claude/
   ```

4. Confirm that the gremlins didn't nuke anything they shouldn't have. If so, restore from backup.

   ```bash
   rm -r your-project/.claude
   mv your-project/.claude.backup your-project/.claude
   ```

## Uninstalling

To remove cogworks and its skills:

```bash
# Remove skills
rm -r your-project/.claude/skills/cogworks-*

# Remove test framework (if installed)
rm -r your-project/.claude/test-framework

# Remove agent
rm your-project/.claude/agents/cogworks.md
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
