# focus-marketplace

Claude Code marketplace with skills for Focus.AI integration, theming, and development workflows.

## Installation

```bash
# Add the marketplace
/plugin marketplace add The-Focus-AI/claude-marketplace

# Install the plugin
/plugin install focus-marketplace
```

Then restart Claude Code.

## Skills

### theme-factory
Apply professional styling themes to artifacts (slides, docs, reports, HTML pages). Includes 10 pre-set themes with colors and fonts.

**Triggers:** "apply a theme", "style this presentation", "make it look professional"

### focus-ai-brand
Apply Focus.AI brand guidelines to materials. Supports two sub-brands:
- **Focus.AI Client** - services, proposals, client work
- **Focus.AI Labs** - research, experiments, public content

**Triggers:** "focus.ai style", "focus brand", "labs style"

### focus-account-integration
Integrate applications with Focus API for authentication, wallet/credits, and job management.

**Triggers:** "connect to focus api", "device-code flow", "credit management"

### distill-backend-service
Build Distill microservices for content aggregation from platforms (Twitter/X, Email, GitHub, YouTube).

**Triggers:** "build distill service", "content aggregation", "watch/unwatch lifecycle"

### twitter-oauth-cli
Build CLI tools that authenticate with Twitter/X OAuth 2.0 using PKCE flow.

**Triggers:** "twitter cli auth", "oauth pkce", "tweet from terminal"

## Commands

### /do-research
Find the optimal library, tool, or technique for a project need. Generates a research report with recommendations.

```bash
/do-research date formatting library for TypeScript
```

### /engineering-processes-advisor
Analyze a codebase and produce a comprehensive engineering assessment covering:
- Technology stack audit
- Testing assessment
- Security review
- Dependency health
- Prioritized improvements

```bash
/engineering-processes-advisor
```

## Related Plugins

- [nano-banana-cli](https://github.com/The-Focus-AI/nano-banana-cli) - Google Gemini image generation

## Development

This plugin follows the Claude Code plugin structure:

```
claude-marketplace/
├── .claude-plugin/
│   ├── plugin.json        # Plugin manifest
│   └── marketplace.json   # Marketplace manifest
├── skills/
│   ├── theme-factory/
│   ├── focus-ai-brand/
│   ├── focus-account-integration/
│   ├── distill-backend-service/
│   └── twitter-oauth-cli/
└── commands/
    ├── do-research.md
    └── engineering-processes-advisor.md
```

## License

Proprietary - The Focus AI
