# Contributing to cogworks

## Development setup

```bash
git clone https://github.com/williamhallatt/cogworks.git
cd cogworks
```

Requires Node.js 18+ and Python 3.

To install your local copy for development into a test project:

```bash
bash scripts/install-cogworks.sh --agent claude-code --project /path/to/test-project
```

## Running tests

```bash
# Framework meta-tests
bash tests/run-black-box-tests.sh

# Fast recursive improvement round
bash scripts/run-recursive-round.sh \
  --round-manifest tests/datasets/recursive-round/round-manifest.local.json \
  --mode fast
```

> **Note:** `bash tests/run-all.sh` runs the full offline bar (Layers 1–5a). See [TESTING.md](TESTING.md) for Layer 5b judge-evaluated tests and the complete layer table.

See [TESTING.md](TESTING.md) for the full test runbook, including recursive improvement rounds and generated-skill testing.

When changing docs, keep the public support matrix consistent:
- generated skills are portable across agents that support skills
- the trust-first internal build flow is currently supported only on Claude Code
  and GitHub Copilot CLI
- Codex may appear in benchmark or trigger-smoke docs without implying build
  parity

## Coding conventions

- Skill directories and slugs use kebab-case (e.g., `cogworks-learn`, `deployment-workflow-benchmark`)
- Shell scripts use strict mode (`set -euo pipefail`) and descriptive function names (`print_success`, `validate_source_archive`)
- Commit format: `<type>/ <summary>` (e.g., `add/ ...`, `refactor/ ...`, `docs/ ...`, `chore/ ...`)
- Keep commits atomic: list each file path explicitly when staging

## Submitting changes

PR checklist:

- [ ] Changes to `skills/**`, `.claude/**`, or `.agents/**` pass Layer 1 deterministic checks (`bash scripts/validate-quality-gates.sh`)
- [ ] Changes to native agent wiring keep both `.claude/agents/**` and `.github/agents/**` renderable from `scripts/render-agentic-role-bindings.py`
- [ ] Shell scripts pass shellcheck
- [ ] README.md, INSTALL.md, and other affected user-facing docs are updated if public behavior or support boundaries changed
- [ ] Public docs do not imply unsupported surface parity, especially around Codex versus the internal trust-first build flow
- [ ] Commit messages follow the `<type>/ <summary>` format
- [ ] PRs touching `skills/**`, `.claude/**`, `.agents/**`, `README.md`, `INSTALL.md`, or `LICENSE` pass `.github/workflows/pre-release-validation.yml`

## Releasing

### Release strategy

Releases use **semantic versioning** with git tags: `v{major}.{minor}.{patch}`

Git tags are the sole source of truth for version numbers. The repo checkout and
bootstrap installer are the canonical product install path.

### Step 1: Validate

```bash
# Verify all skills have SKILL.md
for skill in skills/*/; do
  [ ! -f "$skill/SKILL.md" ] && echo "Missing: $skill/SKILL.md"
done

# Verify native agent renderings are current
python3 scripts/render-agentic-role-bindings.py --check

# Run tests
bash tests/run-black-box-tests.sh
```

### Step 2: Tag and push

```bash
git tag -a v1.0.0 -m "Release cogworks v1.0.0"
git push origin v1.0.0
```

### Step 3: Automated workflow

Pushing a tag triggers `.github/workflows/release.yml`, which:

1. Validates all skills have SKILL.md with valid frontmatter
2. Validates native agent renderings are current
3. Generates a changelog from commits
4. Creates a GitHub Release with installation instructions

### What gets released

The release contains the canonical skill sources plus the generated native agent
bindings and bootstrap installer.

```
skills/
├── cogworks/                    # Orchestrator
├── cogworks-encode/             # Synthesis methodology
├── cogworks-learn/              # Skill writing expertise
scripts/install-cogworks.sh      # Native-first bootstrap installer
.claude/agents/                  # Rendered Claude native agents
.github/agents/                  # Rendered Copilot native agents
```

### Release validation checklist

- [ ] All commits pushed to `main`
- [ ] All `skills/*/SKILL.md` files exist with valid frontmatter
- [ ] `.claude/agents/` and `.github/agents/` are current
- [ ] Tests pass: `bash tests/run-black-box-tests.sh`
- [ ] README.md and INSTALL.md are up to date

### Troubleshooting

**Workflow fails: "SKILL.md not found"**

A skill directory exists but lacks SKILL.md. Check with:

```bash
for skill in skills/*/; do
  [ ! -f "$skill/SKILL.md" ] && echo "Missing: $skill/SKILL.md"
done
```

**Rendered native agents out of date**

```bash
python3 scripts/render-agentic-role-bindings.py --check
```

### Generating release notes locally

Preview release notes before tagging by running the script directly:

```bash
bash scripts/generate-release-notes.sh \
  --tag v3.1.0 \
  --previous-tag v3.0.0
```

Write to a file instead of stdout with `--output`:

```bash
bash scripts/generate-release-notes.sh \
  --tag v3.1.0 \
  --previous-tag v3.0.0 \
  --output /tmp/release-preview.md
```

For the first release (no previous tag), pass an empty string:

```bash
bash scripts/generate-release-notes.sh \
  --tag v1.0.0 \
  --previous-tag ""
```

**Commit-type to section mapping:**

| Commit prefix | Section |
|---|---|
| `add/` | New Features |
| `fix/` | Bug Fixes |
| `refactor/` | Refactors |
| `docs/` | Documentation |
| `chore/`, `release/` | *(omitted)* |
| anything else | Other Changes |

Sections with no commits are omitted from the output.
