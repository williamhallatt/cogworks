# Cogworks Release Process

This document describes how to create and automate releases of the cogworks agent and skills.

## Release Strategy

Releases use **semantic versioning** with git tags: `v{major}.{minor}.{patch}`

Examples: `v0.1.0`, `v1.0.0`, `v1.2.3`

Git tags are the sole source of truth for version numbers.

## Creating a Release

### Step 1: Run pre-release validation (optional but recommended)

Before tagging a release, validate the repository state using the pre-release validation workflow:

**Option A: Automatic on pull request**

- Create a PR with changes to `.claude/`
- The `.github/workflows/pre-release-validation.yml` workflow runs automatically
- Review the validation results before merging

**Option B: Manual validation**

```bash
# Run validation checks locally
# Verify agent exists
ls -la .claude/agents/cogworks.md

# Verify all cogworks-* skills exist
ls -la .claude/skills/cogworks-*/SKILL.md
```

**What validation checks:**

- `.claude/agents/cogworks.md` exists with valid YAML frontmatter
- All `cogworks-*` skills have valid SKILL.md files with required fields

### Step 3: Create git tag and push

```bash
# Create annotated tag with release message
git tag -a v1.0.0 -m "Release cogworks v1.0.0"

# Push tag to GitHub (triggers release workflow)
git push origin v1.0.0
```

### Step 4: Automated workflow

Once the tag is pushed:

1. GitHub Actions automatically triggers the `.github/workflows/release.yml` workflow
2. Workflow validates:
   - cogworks agent exists at `.claude/agents/cogworks.md`
   - All `cogworks-*` skills present in `.claude/skills/`
   - Each skill has a valid `SKILL.md` with proper frontmatter
   - Agent declares required dependencies
3. Workflow creates release artifacts:
   - `cogworks-{version}.tar.gz` (for Linux/macOS)
   - `cogworks-{version}.zip` (for Windows)
4. GitHub Release is automatically created with:
   - Both archive formats attached
   - Auto-generated release notes with installation instructions
   - List of included skills

### Step 5: Verify release

Check that the release was created successfully:

```bash
# View release details (requires GitHub CLI)
gh release view v1.0.0

# Verify assets were uploaded
gh release view v1.0.0 --json assets
```

Navigate to https://github.com/williamhallatt/cogworks/releases to verify in browser.

## What Gets Released

Each release package includes:

```
cogworks-{version}/
├── .claude/
│   ├── agents/
│   │   └── cogworks.md              # Main agent
│   └── skills/
│       ├── cogworks-encode/         # Required
│       │   └── SKILL.md, reference.md, ...
│       ├── cogworks-learn/          # Required
│       │   └── SKILL.md, patterns.md, examples.md, reference.md, ...
│       └── cogworks-test/           # If available
│           └── SKILL.md, ...
├── README.md                         # Project overview
├── LICENSE                           # MIT License
└── INSTALL.md                       # Installation instructions
```

**Excluded from releases:**

- `.git/` directory
- `_sources/` (only needed for development)
- `_plans/` (development planning)
- `tests/` (test infrastructure, not user-facing)
- `.github/workflows/` (for maintainers only)
- `RELEASES.md` (maintainer documentation)
- `CLAUDE.md` (development guidance)

## Release Validation Checklist

Before tagging a release, verify:

- [ ] All commits for the release are pushed to `main`
- [ ] `.claude/agents/cogworks.md` exists and is syntactically correct
- [ ] All `.claude/skills/cogworks-*/` directories have valid SKILL.md files
- [ ] SKILL.md files have proper YAML frontmatter with `name:`, `description:` fields
- [ ] Agent declares dependencies on `cogworks-encode` and `cogworks-learn`
- [ ] README.md is up to date
- [ ] No broken internal links in .md files

## Release Notes Template

GitHub Actions auto-generates release notes with installation instructions. You can customize this by:

1. Editing `.github/workflows/release.yml`
2. Modifying the `RELEASE_NOTES` variable in the "Create GitHub Release" step
3. Commit and push before creating the release tag

## Troubleshooting Release Issues

### Workflow fails: "cogworks agent not found"

**Cause:** `.claude/agents/cogworks.md` doesn't exist or was moved.

**Solution:**

```bash
# Verify agent location
ls -la .claude/agents/cogworks.md

# If missing, restore from backup or fix commit
git log --oneline -- .claude/agents/cogworks.md
```

### Workflow fails: "SKILL.md not found in cogworks-\*"

**Cause:** A cogworks skill directory exists but lacks SKILL.md file.

**Solution:**

```bash
# Check which skills are missing SKILL.md
for skill in .claude/skills/cogworks-*/; do
  [ ! -f "$skill/SKILL.md" ] && echo "Missing: $skill/SKILL.md"
done

# Add SKILL.md to the skill directory and commit before releasing
```

### Release created but assets not attached

**Cause:** Workflow encountered an error during archive creation.

**Solution:**

1. Check workflow logs: https://github.com/williamhallatt/cogworks/actions
2. Look for error messages in the "Create release artifact" step
3. Fix the issue and rerun with a new tag version (can't reuse tags)

### Can't push tag

**Cause:** Tag already exists locally or remotely.

**Solution:**

```bash
# Create a new tag with a different version
git tag -a v1.0.1 -m "Release cogworks v1.0.1"
git push origin v1.0.1

# If you need to delete old tag
git tag -d v1.0.0                  # Delete locally
git push origin --delete v1.0.0    # Delete remotely (use with caution)
```

## Manual Release (if automation fails)

If the GitHub Actions workflow fails, you can manually create a release:

```bash
# Create the release directory structure
ARTIFACT_NAME="cogworks-1.0.0"
mkdir -p "${ARTIFACT_NAME}/.claude/agents"
mkdir -p "${ARTIFACT_NAME}/.claude/skills"

# Copy agent
cp ".claude/agents/cogworks.md" "${ARTIFACT_NAME}/.claude/agents/"

# Copy all cogworks-* skills
cp -r .claude/skills/cogworks-* "${ARTIFACT_NAME}/.claude/skills/"

# Copy documentation
cp README.md LICENSE INSTALL.md "${ARTIFACT_NAME}/"

# Create archives
tar -czf "${ARTIFACT_NAME}.tar.gz" "${ARTIFACT_NAME}/"
zip -r "${ARTIFACT_NAME}.zip" "${ARTIFACT_NAME}/"

# Manually upload to: https://github.com/williamhallatt/cogworks/releases
```

## Future Enhancements

Planned improvements to the release process:

- [ ] Automated changelog generation from commit messages
- [ ] Pre-release validation workflow (runs on branch PRs)
- [ ] Skill quality checks (syntax, link validation, frontmatter validation)
- [ ] npm registry distribution for skills (exploratory)
- [ ] Cross-platform validation (Windows, macOS, Linux)
- [ ] Integration with skill marketplace/registry

## Related Documentation

- [README.md](README.md) - Project overview and quick start
- [INSTALL.md](INSTALL.md) - End-user installation instructions
- [CLAUDE.md](CLAUDE.md) - Development team guidance
- [ROADMAP.md](ROADMAP.md) - Future feature planning
