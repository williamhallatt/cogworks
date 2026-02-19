# Installing Cogworks Agent & Skills

This guide explains how to install the cogworks agent and its required skills into your Claude Code project, plus the Codex skill workflow for OpenAI Codex users.

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
- Present a menu to choose target (Claude or Codex) and installation scope (local or global)
- Create necessary directories
- Copy agent, skills, and test framework
- Validate the installation
- Provide next steps

### Non-Interactive Installation

For automation or CI/CD:

```bash
# Install to current project (Claude)
./install.sh --local

# Install to current project (Codex)
./install.sh --target codex --local

# Install to personal directory (Claude)
./install.sh --global

# Install to personal directory (Codex)
./install.sh --target codex --global

# Force overwrite existing files
./install.sh --global --force

# Preview changes without modifying files
./install.sh --local --dry-run
./install.sh --target codex --local --dry-run
```

Run `./install.sh --help` for all options.

---

## OpenAI Codex Installation

Codex does not support Claude sub-agents. Use the Codex skill workflow instead:

```bash
./install.sh --target codex --local
./install.sh --target codex --global
# Legacy shorthand (global):
./install.sh --codex
```

This installs the Codex skills into `./.agents/skills` (local) or `~/.agents/skills` (global).

### Codex First Run (Recommended)

After installing, try a small local source directory and run Layer 1 validation:

```bash
cogworks encode _sources/my-topic/ as my-topic --test
```

Then validate:

```bash
/cogworks-test my-topic --layer1-only
```

---

## Manual Installation

If you prefer manual installation or need custom setup, follow these instructions.

## Manual Installation (Codex)

1. Create the Codex skills directory:

```bash
mkdir -p "./.agents/skills"
# Or global:
mkdir -p "$HOME/.agents/skills"
```

2. Copy Codex skills:

```bash
cp -r cogworks-{version}/codex/skills/* "./.agents/skills/"
# Or global:
cp -r cogworks-{version}/codex/skills/* "$HOME/.agents/skills/"
```

## Quick Start

### Using tar.gz (Linux/macOS)

```bash
# Extract the archive
tar -xzf cogworks-{version}.tar.gz

# Copy to your Claude Code project
cp -r cogworks-{version}/.claude/* your-project/.claude/

# If you extracted the release inside your project, you can install in-place
# by running ./install.sh --local (it will treat the existing .claude/ as the target).
```

### Using zip (all platforms)

```bash
# Extract the archive
unzip cogworks-{version}.zip

# Copy to your Claude Code project
cp -r cogworks-{version}/.claude/* your-project/.claude/

# If you extracted the release inside your project, you can install in-place
# by running ./install.sh --local (it will treat the existing .claude/ as the target).
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

See [README.md](README.md) for instructions on using the `cogworks` agent and its skills in your Claude Code projects, or the Codex skill workflow.

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

> **Note:** cogworks uses Linux-specific paths in some skills. See [ROADMAP.md](ROADMAP.md) for cross-platform support plans.

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
