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

# Create the annotated tag (only if not dry-run)
if [ "$DRY_RUN" -eq 1 ]; then
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
    git tag -a "$NEW_VERSION" -m "$RELEASE_MSG"

    if [ $? -eq 0 ]; then
        echo ""
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
