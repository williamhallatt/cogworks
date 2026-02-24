# Cogworks Release Process

## Release Strategy

Releases use **semantic versioning** with git tags: `v{major}.{minor}.{patch}`

Git tags are the sole source of truth for version numbers. The `skills` CLI installs directly from the repository — no archives to build or upload.

## Creating a Release

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

## What Gets Released

The entire `skills/` directory is the release. The `skills` CLI clones the repo and discovers skills automatically. No archives needed.

```
skills/
├── cogworks/                    # Orchestrator
├── cogworks-encode/             # Synthesis methodology
├── cogworks-learn/              # Skill writing expertise
├── claude-prompt-engineering/   # Claude prompt guidance
├── codex-prompt-engineering/    # Codex prompt guidance
└── skill-evaluation/            # Evaluation methodology
```

## Release Validation Checklist

- [ ] All commits pushed to `main`
- [ ] All `skills/*/SKILL.md` files exist with valid frontmatter
- [ ] `.claude/skills/` symlinks resolve
- [ ] Tests pass: `bash tests/run-black-box-tests.sh`
- [ ] README.md and INSTALL.md are up to date

## Troubleshooting

### Workflow fails: "SKILL.md not found"

A skill directory exists but lacks SKILL.md. Check with:

```bash
for skill in skills/*/; do
  [ ! -f "$skill/SKILL.md" ] && echo "Missing: $skill/SKILL.md"
done
```

### Broken symlinks

Symlinks in `.claude/skills/` must point to `../../skills/<name>`. Verify:

```bash
ls -la .claude/skills/
```
