---
title: "Accessing and Searching Claude Code Conversation History"
date: 2025-11-28
tags: [claude-code, history, search, productivity, cli]
project_stack: [Astro, TypeScript, pnpm]
recommendation: "Use a custom /history command for day-to-day access, and install claude-conversation-extractor for advanced search and export needs"
use_when:
  - "You need to find a specific conversation from the past"
  - "You want to resume a previous Claude Code session"
  - "You need to export or backup conversation history"
  - "You want to analyze your Claude Code usage patterns"
dont_use_when:
  - "You just need to continue your most recent session (use `claude -c` instead)"
  - "You're looking for conversations in the Claude web/desktop app (different system)"
---

# Accessing and Searching Claude Code Conversation History

## Summary

Claude Code stores all conversation history locally in `~/.claude/` but doesn't provide built-in search capabilities beyond resuming your last 3 sessions. For this project, you have **700+ session files** scattered across the project-specific directory at `~/.claude/projects/-Users-wschenk-The-Focus-AI-2025-11-20-ai-engineering-code-summit/`.

The recommended approach is a two-tier solution: create a custom `/history` command for quick access to your conversation list, and install `claude-conversation-extractor` (a Python CLI tool) for powerful search and export capabilities. For visual exploration, the **Claude Code History Viewer** desktop app provides heatmaps and analytics.

## Project Context

This project (AI Engineering Code Summit 2025) has extensive Claude Code usage with:
- 700+ individual session files (JSONL format)
- Sessions stored at: `~/.claude/projects/-Users-wschenk-The-Focus-AI-2025-11-20-ai-engineering-code-summit/`
- Global command history in: `~/.claude/history.jsonl` (312KB)
- No existing custom `/history` command configured

## Detailed Findings

### Option 1: Built-in Commands (Limited)

**What it is**: Claude Code's native session resumption features.

**Why consider it**: Zero setup, immediately available.

**How to use**:

```bash
# Continue your most recent session
claude -c
# or
claude --continue

# Interactive picker for last 3 sessions
claude --resume
```

**Trade-offs**:
- Pro: No setup required, works immediately
- Con: Only shows last 3 sessions - essentially useless for finding older conversations
- Con: No search capability

### Option 2: Custom /history Command (Recommended for Quick Access)

**What it is**: A markdown file that instructs Claude Code to read and format your conversation history.

**Why consider it**: Gives you a searchable table of ALL conversations directly in any Claude Code session.

**How to implement**:

1. Create the global commands directory:

```bash
mkdir -p ~/.claude/commands
```

2. Create the history command file:

```bash
cat > ~/.claude/commands/history.md << 'EOF'
# Conversation History Viewer

Read my global conversation history from `~/.claude/history.jsonl` and display it as a formatted table.

For each conversation entry, show:
1. Entry number
2. Human-readable date/time (e.g., "Nov 23, 2025 20:15")
3. Project folder name (just the last segment of the path)
4. First 60-80 characters of the conversation topic/first message
5. Session ID (for resuming)

Sort by most recent first. Format as a markdown table.

If the user asks to filter, search the message content for their keywords.
EOF
```

3. Use it in any Claude Code session:

```
/history
```

4. Resume any found session:

```bash
claude --resume <session-id>
```

**Trade-offs**:
- Pro: Works within Claude Code, no external tools
- Pro: Claude can intelligently filter/search based on your request
- Con: Reads entire history file each time (can be slow with large histories)
- Con: Costs tokens to display

### Option 3: Claude Conversation Extractor (Best for Search & Export)

**What it is**: A Python CLI tool for searching and exporting Claude Code conversations.

**Why consider it**: Real-time search across all projects, multiple export formats, zero config.

**How to install**:

```bash
# Using pipx (recommended for CLI tools)
pipx install claude-conversation-extractor

# Or with pip
pip install claude-conversation-extractor
```

**How to use**:

```bash
# Interactive mode with search
claude-start

# Direct search
claude-search "speaker decorator"

# List all conversations
claude-extract --list

# Export specific conversation
claude-extract <session-id>

# Export all conversations
claude-extract --all

# Export with full details (tool calls, MCP, etc.)
claude-extract --detailed

# Different formats
claude-extract --format json
claude-extract --format html
claude-extract --format markdown  # default
```

**For this project specifically**:

```bash
# Search for speaker-related conversations
claude-search "speaker"

# Search for theme-related work
claude-search "theme"

# Search for specific commands used
claude-search "conference-analysis"
```

**Trade-offs**:
- Pro: Real-time fuzzy search across all conversations
- Pro: Multiple export formats (markdown, JSON, HTML)
- Pro: Works offline, 100% local
- Pro: Can include detailed tool call information
- Con: Requires Python/pipx installation
- Con: Separate terminal session (not integrated into Claude Code)

### Option 4: Claude Code History Viewer (Desktop App)

**What it is**: A Tauri-based desktop application for browsing conversation history with analytics.

**Why consider it**: Visual interface, usage analytics, syntax highlighting.

**How to install**:

Download from: https://github.com/jhlee0409/claude-code-history-viewer/releases

Or build from source:
```bash
git clone https://github.com/jhlee0409/claude-code-history-viewer
cd claude-code-history-viewer
./scripts/setup-build-env.sh
pnpm tauri:build:auto
```

**Key features**:
- File tree navigation for projects/sessions
- Activity heatmaps
- Per-project token usage breakdown
- Tool usage statistics
- Syntax-highlighted code blocks
- Formatted diffs

**Trade-offs**:
- Pro: Beautiful visual interface
- Pro: Analytics and usage insights
- Pro: Helps understand Claude Code habits
- Con: Beta status - expect rough edges
- Con: Requires desktop app installation
- Con: No Windows support yet (macOS/Linux only)

### Option 5: Direct File Grep (Quick & Dirty)

**What it is**: Using standard Unix tools to search JSONL files directly.

**Why consider it**: Instant, no installation, works right now.

**How to use**:

```bash
# Search all sessions in this project for a term
grep -l "speaker" ~/.claude/projects/-Users-wschenk-The-Focus-AI-2025-11-20-ai-engineering-code-summit/*.jsonl

# Search and see context
grep -h "speaker" ~/.claude/projects/-Users-wschenk-The-Focus-AI-2025-11-20-ai-engineering-code-summit/*.jsonl | head -20

# Find sessions from a specific date (by file modification time)
ls -lt ~/.claude/projects/-Users-wschenk-The-Focus-AI-2025-11-20-ai-engineering-code-summit/*.jsonl | head -20

# Search global history for topics
grep "conference" ~/.claude/history.jsonl
```

**Trade-offs**:
- Pro: No installation, works immediately
- Pro: Familiar Unix tools
- Con: Raw JSONL output is hard to read
- Con: No semantic understanding of conversation structure

## Recommendation

For this project, implement a **two-tier approach**:

1. **For day-to-day use**: Create the custom `/history` command (Option 2). This gives you quick access to your conversation list without leaving Claude Code.

2. **For deep search/export**: Install `claude-conversation-extractor` (Option 3). When you need to find a specific conversation or export your work, this provides the most powerful search.

3. **Optional bonus**: Install the History Viewer desktop app if you want to visualize your usage patterns and get analytics.

### Quick Setup Script

```bash
# Create /history command
mkdir -p ~/.claude/commands
cat > ~/.claude/commands/history.md << 'EOF'
Read ~/.claude/history.jsonl and show as a table with:
- Entry # | Date | Project | Topic (first 60 chars) | Session ID
Sort newest first. Filter by user's keywords if provided.
EOF

# Install search tool
pipx install claude-conversation-extractor

echo "Done! Use /history in Claude Code or claude-search in terminal"
```

## When NOT to Use This

- **Just need to continue working**: Use `claude -c` to continue your last session
- **Looking for Claude web app history**: This is different from Claude Code CLI - the web app has its own search at claude.ai
- **Searching for file changes**: Use Git history instead (`git log -p`)
- **Finding what Claude edited**: Check `~/.claude/file-history/` for file-level backups

## Sources

- [Claude Code's hidden conversation history (kentgigger.com)](https://kentgigger.com/posts/claude-code-conversation-history)
- [claude-conversation-extractor (GitHub)](https://github.com/ZeroSumQuant/claude-conversation-extractor)
- [Claude Code History Viewer (GitHub)](https://github.com/jhlee0409/claude-code-history-viewer)
- [Claude Code Assist VS Code Extension](https://marketplace.visualstudio.com/items?itemName=agsoft.claude-history-viewer)
- [Using Claude's chat search and memory (Anthropic Help)](https://support.claude.com/en/articles/11817273-using-claude-s-chat-search-and-memory-to-build-on-previous-context)
