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

# Get the latest repo tag by version, not just the nearest reachable tag
LATEST_TAG=$(git tag --sort=-version:refname | head -n1)

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

PLUGIN_MANIFEST_FILES=(
    "plugin.json"
    ".claude-plugin/plugin.json"
    ".claude-plugin/marketplace.json"
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
        echo "  update metadata.json version and cogworks_version to $BARE_VERSION in $f"
    done
    for f in "${PLUGIN_MANIFEST_FILES[@]}"; do
        echo "  update plugin manifest version to $BARE_VERSION in $f"
    done
    for f in "${SKILL_FILES[@]}"; do
        echo "  update frontmatter metadata.version to $BARE_VERSION in $f"
    done
    echo "  render plugin-facing skills with scripts/render-plugin-skills.py"
    echo ""
    echo "DRY RUN: Would stage:"
    for f in "${METADATA_FILES[@]}" "${PLUGIN_MANIFEST_FILES[@]}" "${SKILL_FILES[@]}"; do
        echo "  git add $f"
    done
    echo "  git add plugin-skills/"
    echo ""
    echo "DRY RUN: Would commit:"
    echo "  git commit -m \"chore/ bump skill metadata to $NEW_VERSION\""
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
    for f in "${METADATA_FILES[@]}"; do
        python3 - <<'PY' "$f" "$BARE_VERSION"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
version = sys.argv[2]
data = json.loads(path.read_text(encoding="utf-8"))
data["version"] = version
data["cogworks_version"] = version
path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY
    done
    for f in "${SKILL_FILES[@]}"; do
        python3 - <<'PY' "$f" "$BARE_VERSION"
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
version = sys.argv[2]
text = path.read_text(encoding="utf-8")
updated = re.sub(r"(^metadata:\n(?:.*\n)*?  version:\s*)(?:v)?[0-9]+\.[0-9]+\.[0-9]+", rf"\g<1>{version}", text, count=1, flags=re.MULTILINE)
if updated == text:
    raise SystemExit(f"Failed to update metadata.version in {path}")
path.write_text(updated, encoding="utf-8")
PY
    done

    for f in "${PLUGIN_MANIFEST_FILES[@]}"; do
        python3 - <<'PY' "$f" "$BARE_VERSION"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
version = sys.argv[2]
data = json.loads(path.read_text(encoding="utf-8"))
if path.name == "marketplace.json":
    data["plugins"][0]["version"] = version
else:
    data["version"] = version
path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY
    done

    python3 scripts/render-plugin-skills.py

    git add "${METADATA_FILES[@]}" "${PLUGIN_MANIFEST_FILES[@]}" "${SKILL_FILES[@]}" plugin-skills
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
