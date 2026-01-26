#!/usr/bin/env bash
# Check for local modifications in focus-marketplace plugins
# Compares installed plugin files against the LATEST git source (not the recorded SHA)

set -e

INSTALLED_PLUGINS="$HOME/.claude/plugins/installed_plugins.json"
MARKETPLACE_REPO="The-Focus-AI/claude-marketplace"
MODIFIED_PLUGINS=()
CLEAN_PLUGINS=()
OUTDATED_PLUGINS=()

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=== Checking Focus Marketplace Plugins for Local Modifications ==="
echo ""

# Fetch marketplace.json to get source repos for each plugin
echo "Fetching marketplace configuration..."
MARKETPLACE_JSON=$(gh api "repos/$MARKETPLACE_REPO/contents/.claude-plugin/marketplace.json" --jq '.content' 2>/dev/null | base64 -D 2>/dev/null || echo "")

if [ -z "$MARKETPLACE_JSON" ]; then
    echo -e "${RED}Error: Could not fetch marketplace.json${NC}"
    exit 1
fi

# Get list of focus-marketplace plugins
plugins=$(jq -r '.plugins | to_entries[] | select(.key | endswith("@focus-marketplace")) | "\(.key)|\(.value[0].installPath)|\(.value[0].version)"' "$INSTALLED_PLUGINS" 2>/dev/null)

if [ -z "$plugins" ]; then
    echo "No focus-marketplace plugins installed."
    exit 0
fi

# Create temp directory for cloning
TEMP_DIR=$(mktemp -d)
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

echo ""

check_plugin() {
    local plugin_id="$1"
    local install_path="$2"
    local installed_version="$3"
    local plugin_name="${plugin_id%@focus-marketplace}"

    if [ ! -d "$install_path" ]; then
        echo -e "${YELLOW}⚠${NC}  $plugin_name: Install path not found"
        return
    fi

    # Get the source repo for this plugin from marketplace.json
    local source_repo=$(echo "$MARKETPLACE_JSON" | jq -r --arg name "$plugin_name" '.plugins[] | select(.name == $name) | .source.repo // empty')
    local marketplace_version=$(echo "$MARKETPLACE_JSON" | jq -r --arg name "$plugin_name" '.plugins[] | select(.name == $name) | .version // empty')

    if [ -z "$source_repo" ]; then
        echo -e "${YELLOW}⚠${NC}  $plugin_name: Not found in marketplace.json"
        return
    fi

    # Clone the repo to temp dir (shallow clone of just main/master)
    local repo_dir="$TEMP_DIR/$plugin_name"
    if ! git clone --quiet --depth 1 "https://github.com/$source_repo.git" "$repo_dir" 2>/dev/null; then
        echo -e "${YELLOW}⚠${NC}  $plugin_name: Could not clone $source_repo"
        return
    fi

    # Get the repo's current version
    local repo_version=""
    if [ -f "$repo_dir/.claude-plugin/plugin.json" ]; then
        repo_version=$(jq -r '.version // empty' "$repo_dir/.claude-plugin/plugin.json" 2>/dev/null)
    elif [ -f "$repo_dir/plugin.json" ]; then
        repo_version=$(jq -r '.version // empty' "$repo_dir/plugin.json" 2>/dev/null)
    fi

    # Compare using diff -r, excluding build artifacts and generated files
    local diff_output
    diff_output=$(diff -r \
        --exclude=node_modules \
        --exclude=.git \
        --exclude=package-lock.json \
        --exclude=pnpm-lock.yaml \
        --exclude=.DS_Store \
        --exclude=.beads \
        --exclude=bin \
        --exclude=dist \
        --exclude=build \
        --exclude=.claude \
        --exclude='*.log' \
        "$repo_dir" "$install_path" 2>&1 || true)

    if [ -z "$diff_output" ]; then
        echo -e "${GREEN}✓${NC}  $plugin_name (v$installed_version): Clean - matches repo"
        CLEAN_PLUGINS+=("$plugin_name")
    else
        # Count the differences
        local diff_files=$(echo "$diff_output" | grep -c "^diff " 2>/dev/null || true)
        local only_in_repo=$(echo "$diff_output" | grep -c "^Only in $repo_dir" 2>/dev/null || true)
        local only_in_local=$(echo "$diff_output" | grep -c "^Only in $install_path" 2>/dev/null || true)
        diff_files=${diff_files:-0}
        only_in_repo=${only_in_repo:-0}
        only_in_local=${only_in_local:-0}

        # Check if it's just version mismatch (outdated) vs real local modifications
        if [ "$installed_version" != "$repo_version" ] && [ -n "$repo_version" ]; then
            echo -e "${BLUE}↑${NC}  $plugin_name: v$installed_version installed, v$repo_version available"
            OUTDATED_PLUGINS+=("$plugin_name|$installed_version|$repo_version|$source_repo")
        else
            echo -e "${RED}✗${NC}  $plugin_name (v$installed_version): Local modifications"
            # Show summary of changes
            if [ "$diff_files" -gt 0 ]; then
                echo "      $diff_files file(s) differ"
            fi
            if [ "$only_in_local" -gt 0 ]; then
                echo "      $only_in_local file(s) added locally"
                echo "$diff_output" | grep "^Only in $install_path" | sed 's/^Only in /      + /' | sed 's/: /\//' | head -5
            fi
            if [ "$only_in_repo" -gt 0 ]; then
                echo "      $only_in_repo file(s) missing locally"
            fi
            MODIFIED_PLUGINS+=("$plugin_name|$source_repo")
        fi
    fi
}

# Process each plugin
while IFS='|' read -r plugin_id install_path version; do
    [ -z "$plugin_id" ] && continue
    check_plugin "$plugin_id" "$install_path" "$version"
done <<< "$plugins"

echo ""
echo "=== Summary ==="
echo -e "Clean plugins:    ${GREEN}${#CLEAN_PLUGINS[@]}${NC}"
echo -e "Outdated plugins: ${BLUE}${#OUTDATED_PLUGINS[@]}${NC}"
echo -e "Modified plugins: ${RED}${#MODIFIED_PLUGINS[@]}${NC}"

if [ ${#OUTDATED_PLUGINS[@]} -gt 0 ]; then
    echo ""
    echo "Plugins with updates available:"
    for entry in "${OUTDATED_PLUGINS[@]}"; do
        IFS='|' read -r name old_ver new_ver repo <<< "$entry"
        echo "  - $name: v$old_ver → v$new_ver"
    done
    echo ""
    echo "Run: mise run update-plugins"
fi

if [ ${#MODIFIED_PLUGINS[@]} -gt 0 ]; then
    echo ""
    echo "Plugins with local modifications:"
    for entry in "${MODIFIED_PLUGINS[@]}"; do
        IFS='|' read -r name repo <<< "$entry"
        echo "  - $name (source: $repo)"
    done
    echo ""
    echo "To sync changes back to source repos, copy files and push."
    echo "To discard local changes: mise run update-plugins"
    exit 1
fi

exit 0
