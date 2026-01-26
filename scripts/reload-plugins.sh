#!/usr/bin/env bash
# Force reload of focus-marketplace plugins by clearing cache and reinstalling
set -e

CACHE_DIR="$HOME/.claude/plugins/cache/focus-marketplace"
INSTALLED_PLUGINS="$HOME/.claude/plugins/installed_plugins.json"

echo "=== Reloading Focus Marketplace Plugins ==="
echo ""

# Get list of installed focus-marketplace plugins
plugins=$(jq -r '.plugins | keys[] | select(endswith("@focus-marketplace"))' "$INSTALLED_PLUGINS" 2>/dev/null || echo "")

if [ -z "$plugins" ]; then
    echo "No focus-marketplace plugins installed."
    exit 0
fi

echo "Installed plugins:"
echo "$plugins" | sed 's/@focus-marketplace$//' | sed 's/^/  - /'
echo ""

# Clear the cache
if [ -d "$CACHE_DIR" ]; then
    echo "Clearing plugin cache..."
    rm -rf "$CACHE_DIR"
    echo "Cache cleared."
else
    echo "No cache to clear."
fi

echo ""
echo "Reinstalling plugins..."
echo ""

# Reinstall each plugin
for plugin in $plugins; do
    plugin_name="${plugin%@focus-marketplace}"
    echo "Reinstalling: $plugin_name"
    claude plugin update "$plugin" 2>&1 | grep -v "^$" | sed 's/^/  /' || echo "  Warning: Failed to update $plugin"
done

echo ""
echo "=== Done ==="
echo "Restart Claude Code to apply changes."
