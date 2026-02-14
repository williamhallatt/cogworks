#!/bin/bash

# Download all Claude Code docs from the links file
# Usage: ./download-docs.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LINKS_FILE="$SCRIPT_DIR/cc-md-docs-links.md"

# Extract URLs from markdown links and download each file
grep -oE 'https://code\.claude\.com/docs/en/[a-z0-9-]+\.md' "$LINKS_FILE" | while read -r url; do
    # Extract filename from URL
    filename=$(basename "$url")
    output_path="$OUTPUT_DIR/$filename"

    echo "Downloading: $url -> $filename"
    curl -sS "$url" -o "$output_path"

    if [ $? -eq 0 ]; then
        echo "  ✓ Downloaded $filename"
    else
        echo "  ✗ Failed to download $filename"
    fi
done

echo "Done!"
