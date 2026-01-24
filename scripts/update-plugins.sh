#!/usr/bin/env bash
set -e

CACHE_DIR="$HOME/.claude/plugins/cache"
FOCUS_CACHE="$CACHE_DIR/focus-marketplace"

echo "=== Updating Focus Marketplace Plugins ==="
echo ""

# Get list of focus-marketplace plugins
plugins=$(claude plugin list --json 2>/dev/null | jq -r '.[] | select(.id | endswith("@focus-marketplace")) | .id')

if [ -z "$plugins" ]; then
    echo "No focus-marketplace plugins installed."
    exit 0
fi

# Update each plugin
for plugin in $plugins; do
    echo "Updating: $plugin"
    claude plugin update "$plugin" 2>&1 || echo "  Warning: Failed to update $plugin"
done

echo ""
echo "=== Cleaning up cache ==="

# Clean up temp directories
if [ -d "$CACHE_DIR" ]; then
    temp_dirs=$(find "$CACHE_DIR" -maxdepth 1 -type d -name "temp_github_*" 2>/dev/null || true)
    if [ -n "$temp_dirs" ]; then
        echo "Removing temp directories..."
        echo "$temp_dirs" | while read dir; do
            if [ -n "$dir" ]; then
                echo "  Removing: $(basename "$dir")"
                rm -rf "$dir"
            fi
        done
    else
        echo "No temp directories to clean."
    fi
fi

# Clean up old version directories (keep only latest)
if [ -d "$FOCUS_CACHE" ]; then
    echo ""
    echo "Checking for old plugin versions..."
    for plugin_dir in "$FOCUS_CACHE"/*/; do
        [ -d "$plugin_dir" ] || continue
        plugin_name=$(basename "$plugin_dir")
        version_count=$(find "$plugin_dir" -maxdepth 1 -type d ! -name "$plugin_name" 2>/dev/null | wc -l | tr -d ' ')
        if [ "$version_count" -gt 1 ]; then
            echo "  $plugin_name has $version_count versions - keeping latest only"
            # Get the latest version (highest semver sort)
            latest=$(ls -1 "$plugin_dir" | sort -V | tail -1)
            for ver_dir in "$plugin_dir"*/; do
                [ -d "$ver_dir" ] || continue
                ver=$(basename "$ver_dir")
                if [ "$ver" != "$latest" ]; then
                    echo "    Removing old version: $ver"
                    rm -rf "$ver_dir"
                fi
            done
        fi
    done
fi

echo ""
echo "=== Done ==="
echo "Restart Claude Code to apply updates."
