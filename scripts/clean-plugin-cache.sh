#!/usr/bin/env bash
set -e

CACHE_DIR="$HOME/.claude/plugins/cache"

echo "=== Cleaning Plugin Cache ==="
echo ""

if [ ! -d "$CACHE_DIR" ]; then
    echo "Cache directory does not exist."
    exit 0
fi

# Show what will be cleaned
echo "Current cache contents:"
du -sh "$CACHE_DIR"/* 2>/dev/null || echo "  (empty)"

echo ""

# Check for --force flag
if [[ "$1" == "--force" ]] || [[ "$1" == "-f" ]]; then
    confirm="y"
else
    read -p "Remove all cached plugins? This will force re-download. [y/N] " confirm
fi

if [[ "$confirm" =~ ^[Yy]$ ]]; then
    # Remove temp directories
    find "$CACHE_DIR" -maxdepth 1 -type d -name "temp_github_*" -exec rm -rf {} + 2>/dev/null || true

    # Remove focus-marketplace cache
    if [ -d "$CACHE_DIR/focus-marketplace" ]; then
        echo "Removing focus-marketplace cache..."
        rm -rf "$CACHE_DIR/focus-marketplace"
    fi

    echo ""
    echo "Cache cleaned. Plugins will be re-downloaded on next Claude Code start."
else
    echo "Cancelled."
fi
