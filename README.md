# focus-marketplace

Claude Code plugin marketplace for Focus.AI tools and workflows.

## Installation

```bash
# Add the marketplace
/plugin marketplace add The-Focus-AI/claude-marketplace
```

Then restart Claude Code.

## Available Plugins

| Plugin | Description | Repo |
|--------|-------------|------|
| **focus-agents** | Research and engineering analysis agents | [focus-agents](https://github.com/The-Focus-AI/focus-agents) |
| **focus-ai-brand** | Apply Focus.AI brand guidelines (Client and Labs) | [focus-ai-brand](https://github.com/The-Focus-AI/focus-ai-brand) |
| **focus-skills** | Development skills (Distill, Focus API, Twitter OAuth) | [focus-skills](https://github.com/The-Focus-AI/focus-skills) |
| **focus-commands** | Project setup commands (beads, etc.) | [focus-commands](https://github.com/The-Focus-AI/focus-commands) |
| **nano-banana** | Google Gemini image/video generation | [nano-banana-cli](https://github.com/The-Focus-AI/nano-banana-cli) |
| **chrome-driver** | Browser automation via Chrome DevTools Protocol | [chrome-driver](https://github.com/The-Focus-AI/chrome-driver) |
| **buttondown-skill** | Manage Buttondown newsletters | [buttondown-skill](https://github.com/The-Focus-AI/buttondown-skill) |
| **gmail-skill** | Gmail and Google Calendar integration | [gmail-skill](https://github.com/The-Focus-AI/gmail-skill) |

## Structure

This is a registry-only marketplace. All plugins are hosted in their own repositories:

```
focus-marketplace/
└── .claude-plugin/
    └── marketplace.json   # Registry pointing to plugin repos
```

## License

Proprietary - The Focus AI
