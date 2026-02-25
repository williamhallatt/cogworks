#!/bin/bash

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

# Get the latest tag
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null)

if [ -z "$LATEST_TAG" ]; then
    echo "No tags found. Starting from v0.0.0"
    LATEST_TAG="v0.0.0"
fi

echo "Latest release tag: $LATEST_TAG"

# Parse version
VERSION=${LATEST_TAG#v}
MAJOR=$(echo $VERSION | cut -d. -f1)
MINOR=$(echo $VERSION | cut -d. -f2)
PATCH=$(echo $VERSION | cut -d. -f3)

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

METADATA_FILES=(
    "skills/cogworks/metadata.json"
    "skills/cogworks-encode/metadata.json"
    "skills/cogworks-learn/metadata.json"
)

SKILL_FILES=(
    "skills/cogworks/SKILL.md"
    "skills/cogworks-encode/SKILL.md"
    "skills/cogworks-learn/SKILL.md"
)

# Bump skill metadata versions and create a commit, then tag
if [ "$DRY_RUN" -eq 1 ]; then
    echo ""
    echo "DRY RUN: Would execute the following version bump commands:"
    for f in "${METADATA_FILES[@]}"; do
        echo "  sed -i 's/\"version\": \"[0-9.]*\"/\"version\": \"$BARE_VERSION\"/' $f"
    done
    for f in "${SKILL_FILES[@]}"; do
        echo "  sed -i \"0,/^---\$/!b; /version: v/s/version: v[0-9.]*/version: $NEW_VERSION/\" $f"
    done
    echo ""
    echo "DRY RUN: Would stage:"
    for f in "${METADATA_FILES[@]}" "${SKILL_FILES[@]}"; do
        echo "  git add $f"
    done
    echo ""
    echo "DRY RUN: Would commit:"
    echo "  git commit -m \"chore/ bump skill metadata to $NEW_VERSION\""
    echo ""
    echo "DRY RUN: Would execute:"
    echo "  git tag -a \"$NEW_VERSION\" -m \"$RELEASE_MSG\""
    echo ""
    echo "✓ DRY RUN: Tag would be created: $NEW_VERSION"
    echo ""
    echo "To actually create this tag, run the script without --dry-run:"
    echo ""
    echo "./scripts/create-release-tag.sh"
    echo ""
else
    for f in "${METADATA_FILES[@]}"; do
        sed -i "s/\"version\": \"[0-9.]*\"/\"version\": \"$BARE_VERSION\"/" "$f"
    done
    for f in "${SKILL_FILES[@]}"; do
        sed -i "0,/^---$/!b; /version: v/s/version: v[0-9.]*/version: $NEW_VERSION/" "$f"
    done

    git add "${METADATA_FILES[@]}" "${SKILL_FILES[@]}"
    git commit -m "chore/ bump skill metadata to $NEW_VERSION"

    git tag -a "$NEW_VERSION" -m "$RELEASE_MSG"

    if [ $? -eq 0 ]; then
        echo ""
        echo "✓ Skill metadata bumped to $NEW_VERSION"
        echo "✓ Tag created: $NEW_VERSION"
    else
        echo "Error creating tag. Exiting."
        exit 1
    fi
fi

echo ""
echo "To push this tag upstream, run:"
echo ""
echo "git push origin $NEW_VERSION"
echo ""
