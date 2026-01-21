# focus-marketplace

Claude Code plugin marketplace for Focus.AI tools and workflows.

## Installation

### Add the Marketplace

```bash
# Add the marketplace (gives access to all plugins)
/plugin marketplace add The-Focus-AI/claude-marketplace
```

Then restart Claude Code.

### Install Individual Plugins

After adding the marketplace, install specific plugins:

```bash
# Install a plugin from the marketplace
/plugin install <plugin-name>@focus-marketplace

# Examples:
/plugin install nano-banana@focus-marketplace
/plugin install google-skill@focus-marketplace
/plugin install chrome-driver@focus-marketplace
```

## Available Plugins

### Media Generation

| Plugin | Install | Description |
|--------|---------|-------------|
| **[nano-banana](https://github.com/The-Focus-AI/nano-banana-cli)** | `/plugin install nano-banana@focus-marketplace` | AI image and video generation using Google Gemini and Veo models |

**Skills:** `nano-banana-imagegen` (text-to-image, editing, style transfer), `nano-banana-videogen` (text-to-video, image-to-video)

### Browser Automation

| Plugin | Install | Description |
|--------|---------|-------------|
| **[chrome-driver](https://github.com/The-Focus-AI/chrome-driver)** | `/plugin install chrome-driver@focus-marketplace` | Web automation via Chrome DevTools Protocol |

**Commands:** `/browser` `/screenshot` `/pdf` `/extract` `/navigate` `/interact` `/form` `/record` `/cookies`

### Google Services

| Plugin | Install | Description |
|--------|---------|-------------|
| **[google-skill](https://github.com/The-Focus-AI/google-skill)** | `/plugin install google-skill@focus-marketplace` | Unified Google services with shared OAuth |

**Skills:** `/gmail` (email + calendar), `/gsheets` (spreadsheets), `/gdocs` (documents), `/youtube` (video search)

### Social Media

| Plugin | Install | Description |
|--------|---------|-------------|
| **[twitter-skill](https://github.com/The-Focus-AI/twitter-skill)** | `/plugin install twitter-skill@focus-marketplace` | Twitter/X API - tweets, timeline, lists, engagement |

**Skills:** `/twitter` (post tweets, read timeline, manage lists, engage with content)

### Productivity Integrations

| Plugin | Install | Description |
|--------|---------|-------------|
| **[buttondown-skill](https://github.com/The-Focus-AI/buttondown-skill)** | `/plugin install buttondown-skill@focus-marketplace` | Newsletter management for Buttondown |
| **[granola-skill](https://github.com/The-Focus-AI/granola-skill)** | `/plugin install granola-skill@focus-marketplace` | Access Granola meeting notes and transcripts |
| **[microsoft-skill](https://github.com/The-Focus-AI/microsoft-skill)** | `/plugin install microsoft-skill@focus-marketplace` | Microsoft Graph API - Outlook/Hotmail email access |

**Skills:** `/buttondown` (drafts, scheduling, analytics), `/granola` (meetings, transcripts, search), `/microsoft-outlook` (emails, messages, download)

### Focus.AI Development

| Plugin | Install | Description |
|--------|---------|-------------|
| **[focus-ai-brand](https://github.com/The-Focus-AI/focus-ai-brand)** | `/plugin install focus-ai-brand@focus-marketplace` | Apply Focus.AI brand guidelines |
| **[focus-skills](https://github.com/The-Focus-AI/focus-skills)** | `/plugin install focus-skills@focus-marketplace` | Development guidance for Focus.AI ecosystem |
| **[focus-commands](https://github.com/The-Focus-AI/focus-commands)** | `/plugin install focus-commands@focus-marketplace` | Project setup automation |

**Skills/Commands:** `/report` (branded HTML), `/setup-beads` (issue tracking), Distill backend, Focus Account, Twitter OAuth

### Research

| Plugin | Install | Description |
|--------|---------|-------------|
| **[focus-agents](https://github.com/The-Focus-AI/focus-agents)** | `/plugin install focus-agents@focus-marketplace` | Academic-style web research and report generation |

**Skills:** `/research` (gather 10+ sources, generate markdown reports)

## Structure

This is a registry-only marketplace. All plugins are hosted in their own repositories:

```
focus-marketplace/
└── .claude-plugin/
    └── marketplace.json   # Registry pointing to plugin repos
```

## License

Proprietary - The Focus AI
