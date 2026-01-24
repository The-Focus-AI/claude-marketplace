#!/usr/bin/env bash

echo "=== Installed Plugins ==="
echo ""

claude plugin list --json 2>/dev/null | jq -r '
    .[] |
    "\(.enabled | if . then "✓" else "✗" end) \(.id)\t\(.version)\t\(.lastUpdated | split("T")[0])"
' | column -t -s $'\t'

echo ""
echo "=== Cache Size ==="
du -sh ~/.claude/plugins/cache/* 2>/dev/null | sort -hr

echo ""
echo "=== Temp Directories ==="
temp_count=$(find ~/.claude/plugins/cache -maxdepth 1 -type d -name "temp_github_*" 2>/dev/null | wc -l | tr -d ' ')
echo "Found $temp_count temp directories"
