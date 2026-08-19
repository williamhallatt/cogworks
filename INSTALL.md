# Installing Cogworks

## Install via `npx skills add` (recommended)

Clone the repo and install both skills into every detected agent:

```bash
git clone https://github.com/williamhallatt/cogworks.git
cd cogworks
npx skills add ./skills/cogworks-encode ./skills/cogworks-learn
```

Requires Node.js 18+. Install from [nodejs.org](https://nodejs.org/).

## Manual install

Copy the two skill directories into your agent's skills folder:

```bash
# Personal (all your projects)
cp -r skills/cogworks-encode ~/.claude/skills/
cp -r skills/cogworks-learn ~/.claude/skills/

# Project (this project only)
cp -r skills/cogworks-encode /path/to/project/.claude/skills/
cp -r skills/cogworks-learn /path/to/project/.claude/skills/
```

Other agents use their own skill directories; consult your agent's docs.

## Invoking

Both skills are `disable-model-invocation: true` — invoke them explicitly by
name.

| Agent | Prefix | Example |
|-------|--------|---------|
| Claude Code | `/` | `/cogworks-encode Synthesize these OAuth docs into a single knowledge base.` |
| GitHub Copilot CLI | `$` or natural language | `$cogworks-learn Write a SKILL.md for the incident-triage playbook.` |
| Codex CLI | `$` | `$cogworks-encode ...` |
| Other agents | varies | consult agent documentation |

## Verify installation

```bash
ls skills/cogworks-encode/SKILL.md
ls skills/cogworks-learn/SKILL.md
```

## Troubleshooting

- **Skills not discovered** — verify `SKILL.md` exists in each installed
  skill directory and that the skill directory is at the expected scope path
  for your agent.
- **`npx skills add` missing** — install Node.js 18+ from
  [nodejs.org](https://nodejs.org/).
