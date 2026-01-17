# focus-marketplace

Claude Code plugin marketplace for Focus.AI tools and workflows.

## Installation

```bash
# Add the marketplace
/plugin marketplace add The-Focus-AI/claude-marketplace
```

Then restart Claude Code.

## Available Plugins

### Media Generation

| Plugin | Description | Skills |
|--------|-------------|--------|
| **[nano-banana](https://github.com/The-Focus-AI/nano-banana-cli)** | AI image and video generation using Google Gemini and Veo models | `nano-banana-imagegen` - Text-to-image, image editing, style transfer, batch processing<br>`nano-banana-videogen` - Text-to-video, image-to-video, scene extensions |

### Browser Automation

| Plugin | Description | Commands |
|--------|-------------|----------|
| **[chrome-driver](https://github.com/The-Focus-AI/chrome-driver)** | Web automation via Chrome DevTools Protocol (pure Perl) | `/browser` `/screenshot` `/pdf` `/extract` `/navigate` `/interact` `/form` `/record` `/cookies` |

### Google Services

| Plugin | Description | Skills |
|--------|-------------|--------|
| **[google-skill](https://github.com/The-Focus-AI/google-skill)** | Unified Google services with shared OAuth | `/gmail` - Read, send, search emails; manage calendar events<br>`/gsheets` - Create spreadsheets, read/write cells, append rows<br>`/gdocs` - Create documents, insert text, find/replace<br>`/youtube` - Search videos, channels, playlists, view comments |

### Productivity Integrations

| Plugin | Description | Skills |
|--------|-------------|--------|
| **[buttondown-skill](https://github.com/The-Focus-AI/buttondown-skill)** | Newsletter management for Buttondown | `/buttondown` - Create drafts, schedule sends, view analytics, manage content |
| **[granola-skill](https://github.com/The-Focus-AI/granola-skill)** | Access Granola meeting notes and transcripts | `/granola` - List meetings, show details, search by participant/content, export to markdown |

### Focus.AI Development

| Plugin | Description | Skills/Commands |
|--------|-------------|-----------------|
| **[focus-ai-brand](https://github.com/The-Focus-AI/focus-ai-brand)** | Apply Focus.AI brand guidelines | `/report` - Convert markdown to branded HTML<br>Auto-triggers on "focus.ai style" or "focus brand" |
| **[focus-skills](https://github.com/The-Focus-AI/focus-skills)** | Development guidance for Focus.AI ecosystem | Distill backend service, Focus Account integration, Twitter OAuth CLI |
| **[focus-commands](https://github.com/The-Focus-AI/focus-commands)** | Project setup automation | `/setup-beads` - Initialize Beads issue tracking |

### Research

| Plugin | Description | Skills |
|--------|-------------|--------|
| **[tech-researcher](https://github.com/The-Focus-AI/focus-agents)** | Academic-style web research and report generation | `/research` - Gather 10+ sources, ask clarifying questions, generate markdown reports |

## Structure

This is a registry-only marketplace. All plugins are hosted in their own repositories:

```
focus-marketplace/
└── .claude-plugin/
    └── marketplace.json   # Registry pointing to plugin repos
```

## License

Proprietary - The Focus AI
