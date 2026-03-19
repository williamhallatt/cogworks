# Installing Cogworks

## Quick Install

### Claude Code CLI

Claude Code CLI has an interactive `/plugin` command for managing plugins. To install cogworks, run:

```bash
/plugin marketplace add williamhallatt/cogworks
/plugin <make your selection>
```

### GitHub Copilot CLI

```bash
/plugin marketplace add williamhallatt/cogworks
/plugin install cogworks@cogworks
```

> Copilot also supports `copilot plugin install williamhallatt/cogworks` as a
> one-step direct install, but the marketplace-first flow above allows future
> updates.

`cogworks` is the normal user-facing entry point. `cogworks-encode` and
`cogworks-learn` are supporting skills and are installed automatically.

To update:

- Copilot: rerun `copilot plugin install cogworks@williamhallatt`
- Claude Code: refresh the marketplace source if needed, then reinstall

## Codex

Codex does not support sub-agents, so cogworks cannot run there. Generated
skills are portable to Codex and can be installed with the skills CLI:

```bash
npx skills add ./_generated-skills -a codex
```

Node.js 18+ is required for the `skills` CLI.

## Bootstrap Fallback

Use this only for local development, offline testing, or if a native plugin
install path is temporarily unavailable:

```bash
bash scripts/install-cogworks.sh --agent claude-code --project /path/to/project
bash scripts/install-cogworks.sh --agent copilot-cli --project /path/to/project
bash scripts/install-cogworks.sh --agent claude-code --project /path/to/project --copy
```

## Troubleshooting

- **Plugin install failed**: verify the target CLI supports plugins and rerun
  the platform-native install command
- **Claude install needs a source first**: add `williamhallatt/cogworks` as a
  marketplace source, then install `cogworks@williamhallatt`
- **Bootstrap install failed**: verify the target project directory exists and
  rerun the fallback installer from the repo checkout
- **Skills not discovered**: verify SKILL.md exists in each installed skill
  directory and symlinks resolve
- **Symlink issues on Windows**: use `--copy` flag instead

For testing generated skills, see [TESTING.md](TESTING.md).
