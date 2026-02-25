# Contributing to cogworks

## Development setup

```bash
git clone https://github.com/williamhallatt/cogworks.git
cd cogworks
```

Requires Node.js 18+. Uses [`npx skills`](https://github.com/vercel-labs/skills) for installation.

To install your local copy for development (run from root):

```bash
npx skills add ./skills
```

## Running tests

```bash
# Framework meta-tests
bash tests/run-black-box-tests.sh

# Behavioral gates for repo skills
python3 tests/framework/scripts/cogworks-eval.py behavioral run --skill-prefix cogworks-

# Fast recursive improvement round
bash scripts/run-recursive-round.sh \
  --round-manifest tests/datasets/recursive-round/round-manifest.local.json \
  --mode fast
```

See [TESTING.md](TESTING.md) for the full test runbook, including recursive improvement rounds and generated-skill testing.

## Coding conventions

- Skill directories and slugs use kebab-case (e.g., `cogworks-learn`, `deployment-workflow-benchmark`)
- Shell scripts use strict mode (`set -euo pipefail`) and descriptive function names (`print_success`, `validate_source_archive`)
- Commit format: `<type>/ <summary>` (e.g., `add/ ...`, `refactor/ ...`, `docs/ ...`, `chore/ ...`)
- Keep commits atomic: list each file path explicitly when staging

## Submitting changes

PR checklist:

- [ ] Changes to `skills/**` or `.claude/**` include updated or passing behavioral tests
- [ ] Shell scripts pass shellcheck
- [ ] README.md and INSTALL.md updated if user-facing behavior changed
- [ ] Commit messages follow the `<type>/ <summary>` format
- [ ] PRs touching `skills/**`, `.claude/**`, `README.md`, `INSTALL.md`, or `LICENSE` pass `.github/workflows/pre-release-validation.yml`

## Releasing

### Release strategy

Releases use **semantic versioning** with git tags: `v{major}.{minor}.{patch}`

Git tags are the sole source of truth for version numbers. The `skills` CLI installs directly from the repository — no archives to build or upload.

### Step 1: Validate

```bash
# Verify all skills have SKILL.md
for skill in skills/*/; do
  [ ! -f "$skill/SKILL.md" ] && echo "Missing: $skill/SKILL.md"
done

# Verify symlinks resolve
for link in .claude/skills/*; do
  [ -L "$link" ] && [ ! -e "$link/SKILL.md" ] && echo "Broken: $link"
done

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
2. Validates symlinks resolve
3. Generates a changelog from commits
4. Creates a GitHub Release with installation instructions

### What gets released

The entire `skills/` directory is the release. The `skills` CLI clones the repo and discovers skills automatically. No archives needed.

```
skills/
├── cogworks/                    # Orchestrator
├── cogworks-encode/             # Synthesis methodology
├── cogworks-learn/              # Skill writing expertise
```

### Release validation checklist

- [ ] All commits pushed to `main`
- [ ] All `skills/*/SKILL.md` files exist with valid frontmatter
- [ ] `.claude/skills/` symlinks resolve
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

**Broken symlinks**

Symlinks in `.claude/skills/` must point to `../../skills/<name>`. Verify:

```bash
ls -la .claude/skills/
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
