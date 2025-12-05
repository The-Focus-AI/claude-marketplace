---
title: "Claude Code Plugin Marketplace: Architecture & Packaging Strategy"
date: 2025-12-05
topic: claude-code-marketplace
recommendation: Monorepo with marketplace.json
version_researched: Claude Code Plugins Beta (October 2025)
use_when:
  - Building a collection of related plugins for a team or organization
  - Distributing multiple skills, commands, and agents together
  - Want centralized version management and discovery
  - Need mix of local and external plugin sources
avoid_when:
  - Single standalone plugin with no related components
  - Plugin requires complex build/compilation steps
  - External contributors need independent release cycles
project_context:
  language: Markdown/JSON (plugin definitions)
  relevant_dependencies: beads, mise
---

## Summary

Claude Code plugins operate in a **JSON-catalog-based ecosystem** separate from GitHub Marketplace[1]. A marketplace is simply a git repository containing a `.claude-plugin/marketplace.json` file that catalogs available plugins[2]. Your current repository structure is exemplary—it already implements the monorepo pattern with 8 plugins (skills, agents, commands) managed by a single marketplace manifest.

The ecosystem has grown rapidly since the October 2025 beta launch, with marketplaces like `claude-code-plugins-plus` hosting 254 plugins, 73% of which include Agent Skills[3]. The architecture supports **three distinct component types**: Skills (model-invoked capabilities), Commands (user-invoked shortcuts), and Agents (delegated specialized workers). All three can coexist in a single repository or be split across multiple repos—the marketplace.json handles both patterns through relative paths and GitHub repo references.

**Key finding**: One monorepo with marketplace.json is the recommended approach for related plugins. External plugins can still be referenced by GitHub URL, giving you hybrid flexibility without repo sprawl.

## Philosophy & Mental Model

### The Three Component Types

| Component | Invocation | Purpose | File Location |
|-----------|------------|---------|---------------|
| **Skills** | Model-invoked (automatic) | Teach Claude new capabilities | `skills/skill-name/SKILL.md` |
| **Commands** | User-invoked (`/command`) | Automate workflows | `commands/command-name.md` |
| **Agents** | Model or user-invoked | Delegate complex work | `agents/agent-name.md` |

**Skills** are "what to do"—they expand Claude's knowledge about specific domains. When a user asks about themes or styling, Claude automatically activates the `theme-factory` skill based on context matching[4].

**Commands** are "how to do it"—explicit shortcuts for common workflows. `/setup-beads` runs a predetermined sequence without interpretation.

**Agents** are "who should do it"—specialized workers with constrained tools and focused expertise. The `tech-research` agent has `model: opus` for complex analysis tasks[5].

### Marketplace as Registry

A marketplace is NOT a package manager—it's a **discovery catalog**. It tells Claude Code:
1. What plugins exist
2. Where to find them (path or URL)
3. Metadata for filtering/searching

The actual plugin content lives either in the same repo (relative paths) or external repos (GitHub URLs). This design enables:
- Monorepos for related plugins
- External references for third-party plugins
- Local development with production distribution

## Setup

### Marketplace Structure

```
your-marketplace/
├── .claude-plugin/
│   └── marketplace.json      # Required: catalog of plugins
├── skills/
│   └── skill-name/
│       ├── .claude-plugin/
│       │   └── plugin.json   # Plugin manifest
│       └── skills/
│           └── skill-name/
│               └── SKILL.md  # Skill definition
├── agents/
│   ├── .claude-plugin/
│   │   └── plugin.json
│   └── agents/
│       └── agent-name.md
├── commands/
│   ├── .claude-plugin/
│   │   └── plugin.json
│   └── commands/
│       └── command-name.md
└── README.md
```

### marketplace.json Schema

```json
{
  "name": "your-marketplace-name",
  "owner": {
    "name": "Your Organization",
    "email": "optional@email.com"
  },
  "metadata": {
    "description": "Optional marketplace description",
    "version": "1.0.0",
    "pluginRoot": "./plugins"
  },
  "plugins": [
    {
      "name": "local-plugin",
      "source": "./path/to/plugin",
      "version": "1.0.0",
      "description": "Plugin description",
      "category": "optional-category",
      "tags": ["optional", "tags"]
    },
    {
      "name": "external-plugin",
      "source": {
        "source": "github",
        "repo": "owner/repo-name"
      },
      "version": "2.0.0",
      "description": "External plugin"
    }
  ]
}
```

### plugin.json Manifest (per plugin)

```json
{
  "name": "plugin-identifier",
  "version": "1.0.0",
  "description": "What this plugin does",
  "author": {
    "name": "Author Name"
  },
  "commands": "./commands",
  "agents": "./agents",
  "skills": "./skills",
  "hooks": "./hooks.json",
  "mcpServers": "./mcp-config.json"
}
```

### Installation Commands

```bash
# Add marketplace
/plugin marketplace add owner/repo-name
/plugin marketplace add https://gitlab.com/org/marketplace.git
/plugin marketplace add ./local-path

# Install plugin from marketplace
/plugin install plugin-name@marketplace-name

# Direct plugin install (no marketplace)
/plugin add owner/plugin-repo
```

## Core Usage Patterns

### Pattern 1: Skill Definition (SKILL.md)

Skills teach Claude domain-specific capabilities that activate automatically based on context.

```markdown
---
name: my-skill
description: What this skill enables Claude to do (max 1024 chars). Include trigger phrases.
license: MIT
allowed-tools: Read, Glob, Grep
---

# Skill Title

## Purpose
[What capability this adds]

## Usage Instructions
[Step-by-step guide for Claude]

## Examples
[Concrete examples of when/how to use]
```

**Key insight**: The `description` field is critical for discovery. Include natural language trigger phrases: "styling artifacts", "apply themes", "professional design"[6].

### Pattern 2: Command Definition

Commands are user-invoked workflows with explicit `/command` syntax.

```markdown
---
description: What this command does
argument-hint: <required-arg> [optional-arg]
allowed-tools: Bash, Read, Write
model: sonnet
---

# Command Instructions

Steps to execute when user runs this command...

## Arguments
$ARGUMENTS - all arguments
$1, $2 - positional arguments

## Execution
!bash-command-to-run
@path/to/include/file.md
```

### Pattern 3: Agent Definition

Agents are specialized workers with their own system prompts and tool constraints.

```markdown
---
description: When this agent should be invoked (for auto-delegation)
model: opus
tools: Read, Glob, Grep, WebSearch, WebFetch
skills: related-skill-1, related-skill-2
---

# Agent System Prompt

You are a specialized agent for [domain]...

## Your Mission
[Core objective]

## Process
[Step-by-step methodology]

## Output Format
[Expected deliverables]
```

### Pattern 4: Hybrid Plugin (Skills + Commands + Agents)

A single plugin can contain all three component types:

```
my-hybrid-plugin/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   └── my-skill/
│       └── SKILL.md
├── commands/
│   └── my-command.md
└── agents/
    └── my-agent.md
```

### Pattern 5: Monorepo with Multiple Plugins

Your current structure—multiple plugins in one repo referenced by marketplace.json:

```json
{
  "plugins": [
    {"name": "theme-factory", "source": "./skills/theme-factory"},
    {"name": "focus-agents", "source": "./agents"},
    {"name": "project-setup", "source": "./project-setup"},
    {"name": "nano-banana", "source": {"source": "github", "repo": "The-Focus-AI/nano-banana-cli"}}
  ]
}
```

## Anti-Patterns & Pitfalls

### Don't: Nest .claude-plugin inside skills/commands directories

```
# WRONG
skills/
└── my-skill/
    └── .claude-plugin/
        └── plugin.json
        └── skills/           # Double nesting!
            └── my-skill/
                └── SKILL.md
```

**Why it's wrong:** Creates confusing double-nested paths. The plugin root should contain `.claude-plugin/` and component directories at the same level.

### Instead: Flat structure at plugin root

```
# CORRECT
my-skill-plugin/
├── .claude-plugin/
│   └── plugin.json
└── skills/
    └── my-skill/
        └── SKILL.md
```

---

### Don't: Vague skill descriptions

```markdown
---
name: helper-tool
description: A helpful tool for various tasks
---
```

**Why it's wrong:** Claude can't determine when to activate this skill. No trigger phrases, no context matching.

### Instead: Specific, trigger-rich descriptions

```markdown
---
name: theme-factory
description: Toolkit for styling artifacts with a theme. Applies to slides, docs, reports, HTML landing pages. 10 pre-set themes with colors/fonts. Triggers: "apply theme", "style presentation", "professional design"
---
```

---

### Don't: One plugin per repo for related functionality

Creating separate repos for `theme-factory`, `brand-guidelines`, `design-system` when they're all related.

**Why it's wrong:** Version management nightmare, harder discovery, duplicated infrastructure.

### Instead: Monorepo with marketplace.json

Single repo, multiple plugins, one marketplace manifest. Users can still install individually:
```
/plugin install theme-factory@focus-marketplace
/plugin install brand-guidelines@focus-marketplace
```

---

### Don't: Hardcode paths in hooks/MCP configs

```json
{
  "command": "/Users/me/plugins/my-plugin/scripts/run.sh"
}
```

**Why it's wrong:** Breaks for other users, non-portable.

### Instead: Use ${CLAUDE_PLUGIN_ROOT}

```json
{
  "command": "${CLAUDE_PLUGIN_ROOT}/scripts/run.sh"
}
```

---

### Don't: Mix strict and non-strict without understanding

```json
{
  "name": "my-plugin",
  "strict": false,
  "version": "1.0.0"
}
```

**Why it's wrong:** When `strict: false`, marketplace entry becomes the ENTIRE manifest if plugin.json doesn't exist. Can cause unexpected behavior.

### Instead: Use strict: true (default) or omit

Let the plugin's own manifest be authoritative. Marketplace supplements but doesn't replace.

## Caveats

- **No monetization**: All plugins are free and open-source. No payment/licensing infrastructure exists yet[1].

- **No private marketplaces**: Marketplace repos must be accessible to users. For internal tools, use private GitHub repos with team access.

- **Skills vs Commands confusion**: Skills auto-activate; commands require `/`. If users expect explicit invocation, use commands. If contextual, use skills.

- **Agent model costs**: Agents with `model: opus` incur higher costs. Use `model: haiku` for simple delegation, `sonnet` for balanced, `opus` only for complex analysis.

- **MCP server plugins are rare**: Only ~2% of ecosystem uses MCP servers. Most plugins are markdown-based instructions, not executable code[3].

- **Version pinning**: marketplace.json versions are informational, not enforced. No lockfile mechanism exists.

## Your Current Structure Analysis

Your repository implements the recommended monorepo pattern:

```
claude-marketplace/
├── .claude-plugin/
│   └── marketplace.json          # Catalogs 8 plugins
├── skills/
│   ├── theme-factory/            # Plugin with SKILL.md
│   ├── focus-ai-brand/           # Plugin with SKILL.md
│   ├── focus-account-integration/
│   ├── distill-backend-service/
│   └── twitter-oauth-cli/
├── agents/                       # Plugin with agents/*.md
│   └── agents/
│       ├── tech-research.md
│       └── engineering-processes-advisor.md
└── project-setup/                # Plugin with commands/*.md
    └── commands/
        └── setup-beads.md
```

**What's working well:**
- Single marketplace.json managing all plugins
- Mix of local (relative path) and external (GitHub) sources
- Clear separation of skills vs agents vs commands
- Proper plugin.json manifests in each plugin

**Recommendations:**
1. Your skills have double-nested paths (`skills/theme-factory/skills/theme-factory/SKILL.md`). Consider flattening to `skills/theme-factory/SKILL.md`.
2. Add `category` and `tags` fields to marketplace entries for better discoverability.
3. Consider adding a `/list-plugins` command that shows available marketplace plugins with descriptions.

## References

[1] [Anthropic Launches Claude Code Plugins in Beta](https://medium.com/@CherryZhouTech/anthropic-launches-claude-code-plugins-in-beta-signaling-a-shift-to-ai-coding-ecosystems-0d83d9a32b45) - Overview of ecosystem and no-monetization model

[2] [Plugin Marketplaces - Claude Code Docs](https://code.claude.com/docs/en/plugin-marketplaces) - Official marketplace schema and hosting documentation

[3] [claude-code-plugins-plus GitHub](https://github.com/jeremylongshore/claude-code-plugins-plus) - Largest marketplace with 254 plugins, 73% with Agent Skills

[4] [Skills Guide - Claude Code Docs](https://code.claude.com/docs/en/skills.md) - SKILL.md format and auto-activation

[5] [Sub-agents Documentation - Claude Code Docs](https://code.claude.com/docs/en/sub-agents.md) - Agent configuration and YAML frontmatter

[6] [Plugins Reference - Claude Code Docs](https://code.claude.com/docs/en/plugins-reference.md) - Complete schema and directory structure

[7] [claude-code-marketplace GitHub](https://github.com/ananddtyagi/claude-code-marketplace) - Alternative marketplace structure with auto-sync

[8] [Customize Claude Code with plugins - Anthropic](https://www.anthropic.com/news/claude-code-plugins) - Official announcement and design philosophy
