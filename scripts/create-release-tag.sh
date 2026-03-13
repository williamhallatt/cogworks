#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Check for --dry-run flag
DRY_RUN=0
for arg in "$@"; do
    if [ "$arg" = "--dry-run" ]; then
        DRY_RUN=1
        break
    fi
done

if [ "$DRY_RUN" -eq 1 ]; then
    echo "🧪 DRY RUN MODE - No tags will be created"
    echo ""
fi

VERSION=$(python3 "$ROOT_DIR/scripts/resolve-release-version.py" --format bare)
LATEST_TAG=$(python3 "$ROOT_DIR/scripts/resolve-release-version.py" --latest-tag --format tag --default-tag "v$VERSION")

echo "Current VERSION file: v$VERSION"
echo "Latest release tag: $LATEST_TAG"

# Parse version
MAJOR=$(echo "$VERSION" | cut -d. -f1)
MINOR=$(echo "$VERSION" | cut -d. -f2)
PATCH=$(echo "$VERSION" | cut -d. -f3)

echo ""
echo "Current version: $MAJOR.$MINOR.$PATCH"
echo ""
echo "What type of release is this?"
echo "1) Patch fix (v$MAJOR.$MINOR.$((PATCH+1)))"
echo "2) New functionality (v$MAJOR.$((MINOR+1)).0)"
echo "3) Major new version (v$((MAJOR+1)).0.0)"
echo ""
read -p "Enter your choice (1-3): " CHOICE

case $CHOICE in
    1)
        NEW_VERSION="v$MAJOR.$MINOR.$((PATCH+1))"
        ;;
    2)
        NEW_VERSION="v$MAJOR.$((MINOR+1)).0"
        ;;
    3)
        NEW_VERSION="v$((MAJOR+1)).0.0"
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

echo ""
read -p "Enter release message for $NEW_VERSION: " RELEASE_MSG

BARE_VERSION="${NEW_VERSION#v}"

# Bump skill metadata versions and create a commit, then tag
if [ "$DRY_RUN" -eq 1 ]; then
    echo ""
    echo "DRY RUN: Would execute the following version bump commands:"
    echo "  write $BARE_VERSION to VERSION"
    echo "  render live versioned manifests and skill metadata/frontmatter"
    echo "  render plugin-facing skills with scripts/render-plugin-skills.py"
    echo ""
    echo "DRY RUN: Would stage:"
    echo "  git add VERSION"
    echo "  git add plugin.json"
    echo "  git add .claude-plugin/marketplace.json"
    echo "  git add .github/plugin/marketplace.json"
    echo "  git add skills/cogworks/metadata.json"
    echo "  git add skills/cogworks-encode/metadata.json"
    echo "  git add skills/cogworks-learn/metadata.json"
    echo "  git add skills/cogworks/SKILL.md"
    echo "  git add skills/cogworks-encode/SKILL.md"
    echo "  git add skills/cogworks-learn/SKILL.md"
    echo "  git add plugin/skills/"
    echo ""
    echo "DRY RUN: Would commit:"
    echo "  git commit -m \"chore/ bump release version to $NEW_VERSION\""
    echo ""
    echo "DRY RUN: Would execute:"
    echo "  git tag -a \"$NEW_VERSION\" -m \"$RELEASE_MSG\""
    echo "  git push origin main"
    echo "  git push origin \"$NEW_VERSION\""
    echo ""
    echo "✓ DRY RUN: Tag would be created and pushed: $NEW_VERSION"
    echo ""
    echo "To actually create this tag, run the script without --dry-run:"
    echo ""
    echo "./scripts/create-release-tag.sh"
    echo ""
else
    printf '%s\n' "$BARE_VERSION" > "$ROOT_DIR/VERSION"
    python3 "$ROOT_DIR/scripts/render-release-version-files.py"
    python3 "$ROOT_DIR/scripts/render-plugin-skills.py"
    python3 "$ROOT_DIR/scripts/render-release-version-files.py" --check
    python3 "$ROOT_DIR/scripts/render-plugin-skills.py" --check

    git add \
        "$ROOT_DIR/VERSION" \
        "$ROOT_DIR/plugin.json" \
        "$ROOT_DIR/.claude-plugin/marketplace.json" \
        "$ROOT_DIR/.github/plugin/marketplace.json" \
        "$ROOT_DIR/skills/cogworks/metadata.json" \
        "$ROOT_DIR/skills/cogworks-encode/metadata.json" \
        "$ROOT_DIR/skills/cogworks-learn/metadata.json" \
        "$ROOT_DIR/skills/cogworks/SKILL.md" \
        "$ROOT_DIR/skills/cogworks-encode/SKILL.md" \
        "$ROOT_DIR/skills/cogworks-learn/SKILL.md" \
        "$ROOT_DIR/plugin/skills"
    git commit -m "chore/ bump release version to $NEW_VERSION"

    git tag -a "$NEW_VERSION" -m "$RELEASE_MSG"

    if [ $? -eq 0 ]; then
        echo ""
        echo "✓ Skill metadata bumped to $NEW_VERSION"
        echo "✓ Tag created: $NEW_VERSION"
    else
        echo "Error creating tag. Exiting."
        exit 1
    fi

    git push origin main
    git push origin "$NEW_VERSION"

    if [ $? -eq 0 ]; then
        echo ""
        echo "✓ Pushed main and tag $NEW_VERSION to origin"
    else
        echo "Error pushing to origin. Push manually:"
        echo ""
        echo "  git push origin main && git push origin $NEW_VERSION"
        echo ""
        exit 1
    fi
fi
