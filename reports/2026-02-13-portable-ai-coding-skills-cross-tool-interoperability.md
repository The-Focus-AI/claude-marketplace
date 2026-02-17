# Building Portable AI Coding Skills Across Multiple AI Coding Assistants

**Date:** February 13, 2026
**Author:** Research Report
**Status:** Current as of February 2026

---

## Abstract

The AI coding assistant ecosystem has undergone rapid consolidation around shared standards since late 2024, driven primarily by three initiatives: the Model Context Protocol (MCP) for tool integration, the Agent Skills specification for portable capabilities, and the AGENTS.md convention for project-level instructions. This report examines the plugin, extension, and configuration systems across eight major AI coding assistants -- Claude Code, Cursor, OpenAI Codex CLI, GitHub Copilot, Windsurf, Cline, Continue, and Aider -- and evaluates the emerging portability layers that enable building skills once and deploying them across multiple tools. MCP has achieved near-universal adoption with 97 million monthly SDK downloads and backing from all major AI vendors. Agent Skills, open-sourced by Anthropic in December 2025, has been adopted by over 25 platforms including OpenAI Codex, GitHub Copilot, VS Code, Cursor, and Gemini CLI. AGENTS.md, contributed by OpenAI to the Linux Foundation's Agentic AI Foundation, has been adopted by 60,000+ open source projects. While significant fragmentation remains in tool-specific features like hooks, subagents, and IDE-level integration, the practical path for building portable AI coding skills today is clear: use Agent Skills (SKILL.md) as the primary capability format, MCP servers for tool integrations, and AGENTS.md for project-level instructions.

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Plugin and Extension Systems by Tool](#2-plugin-and-extension-systems-by-tool)
3. [MCP as a Portability Layer](#3-mcp-as-a-portability-layer)
4. [Agent Skills: The Emerging Universal Capability Format](#4-agent-skills-the-emerging-universal-capability-format)
5. [Rules Files and Project-Level Instructions](#5-rules-files-and-project-level-instructions)
6. [The Agentic AI Foundation and Governance](#6-the-agentic-ai-foundation-and-governance)
7. [Cross-Tool Portability Projects and Patterns](#7-cross-tool-portability-projects-and-patterns)
8. [Current State of the Ecosystem](#8-current-state-of-the-ecosystem)
9. [Practical Recommendations](#9-practical-recommendations)
10. [Conclusion](#10-conclusion)
11. [References](#11-references)

---

## 1. Introduction

As of February 2026, the AI coding assistant market has matured significantly. Developers routinely use multiple tools -- a terminal-based agent like Claude Code or Codex CLI alongside an IDE-integrated assistant like Cursor, Copilot, or Windsurf. This creates a pressing need for portable skills and configurations that work across tools without maintaining separate implementations for each platform.

This report examines the current state of cross-tool portability across three dimensions:

1. **Tool integration** (MCP): How AI agents connect to external tools, APIs, and data sources
2. **Capability packaging** (Agent Skills): How procedural knowledge and workflows are packaged as reusable modules
3. **Project configuration** (AGENTS.md/CLAUDE.md): How project-specific instructions and conventions are communicated to AI agents

The research draws from official documentation, industry analysis, and community projects published between 2025 and early 2026. Over 20 primary sources were consulted, including official tool documentation, the Agent Skills specification, Linux Foundation announcements, and practitioner analysis.

---

## 2. Plugin and Extension Systems by Tool

### 2.1 Claude Code

Claude Code has the most comprehensive extension system of any AI coding assistant, offering five distinct extension mechanisms according to [the official documentation](https://code.claude.com/docs/en/plugins) and [Alex Op's architectural analysis](https://alexop.dev/posts/understanding-claude-code-full-stack/):

| Component | Trigger Type | Purpose |
|-----------|-------------|---------|
| **CLAUDE.md** | Automatic (startup) | Project memory -- conventions, architecture, patterns. Loads hierarchically from enterprise to directory level. |
| **Slash Commands** | Manual (`/command`) | User-triggered workflows stored in `.claude/commands/` as Markdown files. Support `$ARGUMENTS` and `@file` syntax. |
| **Agent Skills** | Automatic (context-driven) | Folder-based capabilities with `SKILL.md` descriptors. Claude discovers and activates relevant skills based on task context. |
| **Hooks** | Automatic (event-based) | Event-driven automation (PreToolUse, PostToolUse, UserPromptSubmit) defined in `.claude/settings.json`. |
| **Subagents** | Automatic (task-driven) | Specialized AI agents with isolated context windows and configurable tool access. Run in parallel. |
| **MCP Servers** | Manual (via tool calls) | Universal adapter connecting external systems (GitHub, databases, APIs). |
| **Plugins** | Package format | Distributable bundles of commands, skills, agents, hooks, and MCP servers with a `.claude-plugin/plugin.json` manifest. |

**Plugin structure:**
```
my-plugin/
  .claude-plugin/
    plugin.json          # Manifest with name, description, version
  commands/              # Slash commands as Markdown
  skills/                # Agent Skills with SKILL.md files
  agents/                # Subagent definitions
  hooks/
    hooks.json           # Event handlers
  .mcp.json              # MCP server configurations
  .lsp.json              # LSP server configurations
```

Claude Code plugins support marketplace distribution, version management, and team sharing. Skills are namespaced per plugin (e.g., `/my-plugin:hello`) to prevent conflicts. According to the [Claude Code plugins documentation](https://code.claude.com/docs/en/plugins), plugins require Claude Code version 1.0.33 or later.

**Key distinction:** Claude Code's skills follow the open [Agent Skills standard](https://agentskills.io/home), making them portable to other platforms. However, hooks, subagents, and the plugin packaging format are Claude Code-specific.

### 2.2 Cursor

Cursor supports extensions through several mechanisms, as documented in [Cursor MCP setup guides](https://www.braingrid.ai/blog/cursor-mcp) and [the rules file analysis](https://www.everydev.ai/p/blog-ai-coding-agent-rules-files-fragmentation-formats-and-the-push-to-standardize):

- **Rules files:** Originally `.cursorrules` in the project root, now evolved to `.cursor/rules/*.mdc` -- Markdown files with YAML frontmatter and XML-like tags. Support activation modes: Always, Auto Attached, Agent Requested. Also supports AGENTS.md.
- **MCP servers:** Configured via `.cursor/mcp.json` (project-level) or `~/.cursor/mcp.json` (global). Cursor's January 2026 update improved dynamic context loading for tool descriptions across multiple servers.
- **Agent Skills:** Cursor appears in the [Agent Skills adopters list](https://agentskills.io/home), indicating support for the SKILL.md format.

Cursor's rules format includes features that [other tools lack](https://paddo.dev/blog/claude-rules-path-specific-native/), such as rule types (Always, Auto Attached, Agent Requested) and globs-based path matching in frontmatter.

### 2.3 OpenAI Codex CLI

According to the [official Codex documentation](https://developers.openai.com/codex/skills), Codex CLI offers a rich extension system:

- **AGENTS.md:** Codex reads `AGENTS.md` files before doing any work. Files are concatenated from root down, with closer files taking precedence.
- **Skills:** Codex supports the Agent Skills format with `SKILL.md` files. Skills are discovered at repository level (`.agents/skills/`), user level (`$HOME/.agents/skills/`), admin level (`/etc/codex/skills/`), and system level. Users invoke skills with `$skill-name` or let Codex select automatically.
- **Slash commands:** Built-in commands (`/review`, `/fork`) plus custom ones for team-specific workflows.
- **MCP servers:** Configured in `~/.codex/config.toml` or project-scoped `.codex/config.toml`. Supports STDIO and Streamable HTTP transports. Managed via `codex mcp add` CLI command.
- **Configuration:** `config.toml` format with profiles, feature flags, and model selection.

According to [Codex MCP documentation](https://developers.openai.com/codex/mcp/), MCP servers support timeout configuration, tool filtering (`enabled_tools`/`disabled_tools`), and OAuth authentication.

### 2.4 GitHub Copilot

According to [GitHub's documentation](https://docs.github.com/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot) and [VS Code's Agent Skills guide](https://code.visualstudio.com/docs/copilot/customization/agent-skills):

- **Custom instructions:** `.github/copilot-instructions.md` for repository-wide instructions. Path-specific `.instructions.md` files with `applyTo` fields for directory-level rules.
- **Agent Skills:** VS Code Copilot supports the Agent Skills standard. Skills are discovered in `.github/skills/`, `.claude/skills/`, and `.agents/skills/` directories. The `chat.agentSkillsLocations` setting allows custom paths.
- **Extensions:** GitHub Copilot extensions system for adding specialized capabilities.
- **MCP servers:** Supported through VS Code's MCP integration.
- **Organization instructions:** File-based org-wide configuration in `.github` repos with audit trails and rollback.

The [VS Code Agent Skills documentation](https://code.visualstudio.com/docs/copilot/customization/agent-skills) confirms explicit cross-platform compatibility: "Agent Skills is an open standard that works across multiple AI agents, including GitHub Copilot in VS Code, GitHub Copilot CLI, and GitHub Copilot coding agent."

### 2.5 Windsurf

According to [Windsurf documentation](https://docs.windsurf.com/windsurf/getting-started) and the [rules comparison guide](https://deeplearning.fr/ai-coding-assistant-rules-for-windsurf-and-cursor/):

- **Rules:** `.windsurfrules` in project root, or configured via Settings > Workspace AI Rules. Also supports `global_rules.md` for workspace-wide settings and `.windsurf/rules` for project-specific rules.
- **Memories:** Auto-generated or manually created context that persists across sessions.
- **MCP servers:** Supported for extending Cascade (Windsurf's AI agent) capabilities.
- **Extensions:** Supports VS Code-compatible extensions via JS/TS APIs, with some limitations.

### 2.6 Cline

According to [Cline's documentation](https://docs.cline.bot/mcp/configuring-mcp-servers) and the [MCP plugin development guide](https://cline.bot/blog/calling-all-developers-how-to-build-mcp-plugins-with-cline):

- **Rules:** `.clinerules` files, now evolved to `.clinerules/` folder structures for modular organization.
- **MCP servers:** First-class MCP support. Configuration stored in `cline_mcp_settings.json`. Cline can create, install, and manage MCP servers directly. MCP prompts appear as slash commands (`/mcp:<server>:<prompt>`).
- **MCP plugin development:** Cline has a `.clinerules` protocol file specifically for MCP plugin development.

### 2.7 Continue

According to [Continue's documentation](https://docs.continue.dev/ide-extensions/agent/quick-start) and the [Docker partnership announcement](https://blog.continue.dev/simplifying-ai-development-with-model-context-protocol-docker-and-continue-hub/):

- **Continue Hub:** A marketplace for sharing custom-built assistants and building blocks. Launched with Continue 1.0.
- **MCP support:** Full MCP integration for connecting to external tools and data sources. Partnership with Docker for containerized MCP blocks.
- **Configuration:** Supports multiple model providers and custom configuration.
- **Skills:** Recent updates include agent skills support (e.g., `cn-check` skill).

### 2.8 Aider

According to [Aider's documentation](https://aider.chat/) and [community MCP integrations](https://github.com/disler/aider-mcp-server):

- **Configuration:** `.aider.conf.yml` file for model selection, conventions, and settings. Supports `--read` flag for loading convention files like `CONVENTIONS.md`.
- **MCP support:** No native MCP client support. Community projects like `mcpm-aider` and `aider-mcp-server` provide MCP integration by wrapping Aider as an MCP server, but these are explicitly positioned as experimental.
- **Conventions:** Supports reading external convention files passed as arguments.

---

## 3. MCP as a Portability Layer

### 3.1 What is MCP?

The Model Context Protocol, [originally open-sourced by Anthropic in November 2024](https://en.wikipedia.org/wiki/Model_Context_Protocol), provides a universal standard for connecting AI models to external tools, data sources, and applications. According to [Pento's year-in-review analysis](https://www.pento.ai/blog/a-year-of-mcp-2025-review), MCP has achieved remarkable adoption:

- **97 million+ monthly SDK downloads** across Python and TypeScript
- **10,000+ active MCP servers** published
- First-class client support in Claude, ChatGPT, Cursor, Gemini, Microsoft Copilot, and VS Code

### 3.2 Adoption Timeline

| Date | Milestone |
|------|-----------|
| November 2024 | Anthropic open-sources MCP with Python and TypeScript SDKs |
| March 2025 | OpenAI integrates MCP across Agents SDK, Responses API, ChatGPT Desktop |
| April 2025 | Google DeepMind confirms MCP support for Gemini models |
| November 2025 | Major spec update: async operations, statelessness, server identity, community registry |
| December 2025 | Anthropic donates MCP to Agentic AI Foundation under Linux Foundation |

### 3.3 Which Tools Support MCP?

Based on research across all sources, here is the current MCP support matrix:

| Tool | MCP Client Support | Configuration Format | Maturity |
|------|-------------------|---------------------|----------|
| Claude Code | Full | `.mcp.json` in plugins, CLI config | Production |
| Claude Desktop | Full | `claude_desktop_config.json` | Production |
| Cursor | Full | `.cursor/mcp.json` | Production |
| OpenAI Codex CLI | Full | `config.toml` (`[mcp_servers]`) | Production |
| GitHub Copilot / VS Code | Full | VS Code settings | Production |
| Windsurf | Full | Settings-based | Production |
| Cline | Full | `cline_mcp_settings.json` | Production |
| Continue | Full | Hub + config | Production |
| ChatGPT Desktop | Full | App settings | Production |
| Gemini | Full | Platform config | Production |
| Aider | Community only | Third-party wrappers | Experimental |

### 3.4 Can MCP Servers Serve as Universal Plugins?

MCP servers provide excellent portability for **tool integrations** -- connecting AI agents to databases, APIs, file systems, and external services. An MCP server written once works across all MCP-compatible clients.

However, MCP has important limitations as a general plugin mechanism:

1. **Tool-only scope:** MCP provides tools (functions the agent can call), resources (data the agent can read), and prompts. It does not provide instructions, workflows, or procedural knowledge.
2. **No progressive disclosure:** MCP tool descriptions are loaded into context upfront (though Cursor's January 2026 update added dynamic loading). Skills handle this better with metadata-first discovery.
3. **No workflow orchestration:** MCP cannot define multi-step workflows or decision trees. According to the [Anthropic engineering blog](https://claude.com/blog/equipping-agents-for-the-real-world-with-agent-skills), Agent Skills "complement Model Context Protocol servers by teaching agents more complex workflows that involve external tools and software."
4. **Security concerns:** As noted in [Pento's analysis](https://www.pento.ai/blog/a-year-of-mcp-2025-review), significant security gaps remain including authentication vulnerabilities, prompt injection risks, and data exfiltration through multi-tool chaining.

**Bottom line:** MCP is the right choice for portable tool integrations, but Agent Skills are needed for portable capability packaging. The two are complementary, not competing.

---

## 4. Agent Skills: The Emerging Universal Capability Format

### 4.1 What are Agent Skills?

Agent Skills, [published as an open standard by Anthropic in December 2025](https://agentskills.io/home), are folders of instructions, scripts, and resources that AI agents can discover and use. According to the [specification](https://agentskills.io/home), skills solve the problem that "agents are increasingly capable, but often don't have the context they need to do real work reliably."

### 4.2 SKILL.md Specification

Every skill requires a `SKILL.md` file with YAML frontmatter:

```yaml
---
name: code-review
description: Reviews code for best practices and potential issues.
  Use when reviewing code, checking PRs, or analyzing code quality.
---

When reviewing code, check for:
1. Code organization and structure
2. Error handling
3. Security concerns
4. Test coverage
```

**Required fields:**
- `name`: Unique lowercase identifier (max 64 characters)
- `description`: Explains capabilities and use cases (max 1024 characters)

**Optional fields:**
- `argument-hint`: Guidance for slash command usage
- `user-invokable`: Controls visibility in `/` menu (defaults to true)
- `disable-model-invocation`: Requires manual invocation only (defaults to false)

**Full directory structure:**
```
my-skill/
  SKILL.md              # Core instructions (required)
  scripts/              # Executable Python/Bash scripts (optional)
  references/           # Documentation loaded into context (optional)
  assets/               # Templates and binary files (optional)
```

### 4.3 Progressive Disclosure Architecture

According to the [Anthropic engineering blog](https://claude.com/blog/equipping-agents-for-the-real-world-with-agent-skills), skills use a three-tier progressive disclosure model:

1. **Metadata layer:** Only `name` and `description` are loaded into the system prompt at startup, enabling relevance matching without consuming full context.
2. **Instructions loading:** Full `SKILL.md` content loads when the agent determines the skill is applicable.
3. **Resource access:** Scripts, references, and assets load only when specifically needed.

This design makes context "effectively unbounded" because skills consume tokens only when relevant.

### 4.4 Platform Adoption

According to [agentskills.io](https://agentskills.io/home), Agent Skills are supported by over 25 platforms as of February 2026:

**Major adopters:** Claude Code, Claude (web/API), OpenAI Codex, GitHub/VS Code, Cursor, Gemini CLI, Goose, Amp (Sourcegraph), Roo Code, Firebender, Factory, Databricks, Spring AI, TRAE (ByteDance), Mistral Vibe, Qodo, and others.

According to [VentureBeat](https://venturebeat.com/technology/anthropic-launches-enterprise-agent-skills-and-opens-the-standard), "Within two months of Anthropic publishing the open standard, OpenAI quietly added skills support to both ChatGPT and their Codex CLI tool."

### 4.5 Discovery Locations

Different tools scan different paths, but a convergence pattern has emerged:

| Location | Claude Code | Codex CLI | VS Code Copilot |
|----------|-------------|-----------|-----------------|
| `.agents/skills/` | Yes | Yes | Yes |
| `.claude/skills/` | Yes | No | Yes |
| `.github/skills/` | No | No | Yes |
| `~/.agents/skills/` | No | Yes | Yes |
| `~/.claude/skills/` | Yes | No | Yes |
| `~/.copilot/skills/` | No | No | Yes |
| `/etc/codex/skills/` | No | Yes | No |

**Best practice for portability:** Place skills in `.agents/skills/` at the project level and `~/.agents/skills/` at the user level. This path is recognized by most adopters.

### 4.6 Relationship to MCP

Skills and MCP are complementary layers. According to the [Anthropic engineering analysis](https://claude.com/blog/equipping-agents-for-the-real-world-with-agent-skills):

- **MCP** provides the tools (function calls, data access)
- **Skills** provide the knowledge of how and when to use those tools
- A skill can declare MCP dependencies via optional metadata (Codex uses `agents/openai.yaml` with `dependencies.tools`)

Example: An MCP server might provide a `create_jira_ticket` tool, while a skill teaches the agent the workflow for triaging bugs, determining priority, and creating properly formatted tickets.

---

## 5. Rules Files and Project-Level Instructions

### 5.1 The Fragmentation Problem

According to [EveryDev's analysis](https://www.everydev.ai/p/blog-ai-coding-agent-rules-files-fragmentation-formats-and-the-push-to-standardize), "The ecosystem of rule files that guide these agents is totally fragmented." As of mid-2025, each tool used its own format:

| Tool | Rules File(s) |
|------|--------------|
| Claude Code | `CLAUDE.md` |
| Cursor | `.cursorrules`, `.cursor/rules/*.mdc` |
| Windsurf | `.windsurfrules`, `.windsurf/rules/` |
| GitHub Copilot | `.github/copilot-instructions.md` |
| Cline | `.clinerules`, `.clinerules/` |
| Codex CLI | `AGENTS.md` |
| Replit | `.replit.md` |
| VS Code | `.prompt.md` |

### 5.2 AGENTS.md as the Convergence Standard

[AGENTS.md](https://developers.openai.com/codex/guides/agents-md/), released by OpenAI in August 2025, has emerged as the dominant project-level instruction format. According to the [Linux Foundation announcement](https://www.linuxfoundation.org/press/linux-foundation-announces-the-formation-of-the-agentic-ai-foundation), it has been "adopted by more than 60,000 open source projects and agent frameworks including Amp, Codex, Cursor, Devin, Factory, Gemini CLI, GitHub Copilot, Jules and VS Code."

According to [Kaushik Gopal's analysis](https://kau.sh/blog/agents-md/), "Most coding tools have since consolidated around `AGENTS.md` as the standard." The following tools now recognize AGENTS.md:

- Cursor
- OpenAI Codex
- Gemini CLI / Android Studio
- VS Code with Copilot
- Firebender (IntelliJ)

**Claude Code remains an exception**, still requiring its own `CLAUDE.md`. The recommended workaround is:

```bash
echo 'See @AGENTS.md' > CLAUDE.md
```

Or using symlinks:

```bash
ln -s AGENTS.md CLAUDE.md
```

### 5.3 AGENTS.md Structure

AGENTS.md files support hierarchical organization:
- **Project level:** `AGENTS.md` in the project root
- **Directory level:** Nested `AGENTS.md` files in subdirectories for module-specific guidance
- **User level:** `~/.agents/AGENTS.md` for personal preferences (applies globally)

Files closer to the current working directory take precedence over those further up the hierarchy.

### 5.4 Practical Comparison: AGENTS.md vs CLAUDE.md

According to [Paddo's comparison](https://paddo.dev/blog/claude-rules-path-specific-native/), the formats are nearly identical in practice:
- Cursor uses `globs:` frontmatter; Claude uses `paths:`
- Both support nested directories and version control
- Cursor has activation modes (Always, Auto Attached, Agent Requested) that Claude lacks
- The content itself -- coding standards, architecture notes, conventions -- is interchangeable

---

## 6. The Agentic AI Foundation and Governance

### 6.1 Formation

On December 9, 2025, the Linux Foundation [announced the formation](https://www.linuxfoundation.org/press/linux-foundation-announces-the-formation-of-the-agentic-ai-foundation) of the Agentic AI Foundation (AAIF) with three founding projects:

1. **Model Context Protocol (MCP)** -- donated by Anthropic
2. **goose** -- donated by Block (an open-source, local-first AI agent framework)
3. **AGENTS.md** -- donated by OpenAI

### 6.2 Membership

**Platinum members:** Amazon Web Services, Anthropic, Block, Bloomberg, Cloudflare, Google, Microsoft, OpenAI

**Gold members:** Cisco, Docker, IBM, JetBrains, Okta, Oracle, Salesforce, Snowflake, Twilio, and others (18 total)

**Silver members:** Hugging Face, Elasticsearch, Pydantic, Uber, Zapier, and others (21 total)

### 6.3 Significance

The AAIF represents an unprecedented level of industry alignment on AI agent standards. Having Anthropic, OpenAI, Google, and Microsoft all as platinum members of a single foundation governing shared protocols suggests the era of extreme fragmentation is ending. However, note that Agent Skills is not (yet) an AAIF project -- it is governed separately through the [agentskills.io](https://agentskills.io) specification and GitHub repository.

---

## 7. Cross-Tool Portability Projects and Patterns

### 7.1 Agent Client Protocol (ACP)

[JetBrains and Zed](https://blog.jetbrains.com/ai/2025/10/jetbrains-zed-open-interoperability-for-ai-coding-agents-in-your-ide/) are collaborating on the Agent Client Protocol -- an open protocol for AI coding agents to work inside editors. Think of ACP as "Language Server Protocol, but for AI agents."

- Available in JetBrains IDEs 2025.3+ and Zed
- [ACP Agent Registry](https://blog.jetbrains.com/ai/2026/01/acp-agent-registry/) launched January 2026 -- a directory of AI coding agents integrated into IDEs
- Addresses a different layer than MCP: ACP handles agent-to-IDE communication, while MCP handles agent-to-tool communication

### 7.2 Symlink-Based Portability

A common pattern documented by [Kaushik Gopal](https://kau.sh/blog/agents-md/) is using symbolic links to maintain a single source of truth:

```bash
# Project level: single AGENTS.md serves all tools
ln -s AGENTS.md CLAUDE.md
ln -s AGENTS.md .cursorrules

# User level: global instructions sync across tools
ln -sfn ~/.agents/AGENTS.md ~/.codex/AGENTS.md
```

### 7.3 The steipete/agent-rules Project

The [agent-rules](https://github.com/steipete/agent-rules) repository (now archived, December 2025) was an early attempt at maintaining shared rules for Claude Code and Cursor. It separated rules into `global-rules/` and `project-rules/` with installation scripts. The author has since moved to a newer project at `github.com/steipete/agent-scripts`, reflecting the rapid evolution of the ecosystem.

### 7.4 Continue Hub

[Continue's Hub](https://blog.continue.dev/simplifying-ai-development-with-model-context-protocol-docker-and-continue-hub/) provides a marketplace for sharing custom assistants and building blocks, including containerized MCP servers through a Docker partnership. This approach addresses the distribution challenge but is specific to the Continue ecosystem.

### 7.5 Skills Marketplaces

Multiple skills marketplaces have emerged:
- [SkillsMP](https://skillsmp.com/) -- Agent Skills marketplace for Claude, Codex, and ChatGPT
- [Anthropic's skills repository](https://github.com/anthropics/skills) -- Official example skills
- Claude Code plugin marketplaces -- distributable plugin packages

### 7.6 Open Agentic Schema Framework (OASF)

According to [EveryDev's analysis](https://www.everydev.ai/p/blog-ai-coding-agent-rules-files-fragmentation-formats-and-the-push-to-standardize), OASF is an emerging framework defining standard agent capabilities. Additionally, Letta AI has proposed the Agent File Format (.af) as a portable snapshot format for agent state.

---

## 8. Current State of the Ecosystem

### 8.1 Where Standards Have Converged

**Strong convergence:**
- **MCP for tool integration:** Near-universal adoption. Write an MCP server once, use it everywhere.
- **Agent Skills for capabilities:** Rapid adoption across 25+ platforms since December 2025. The SKILL.md format is becoming the standard for packaging agent capabilities.
- **AGENTS.md for project instructions:** Adopted by 60,000+ projects and most major tools (with Claude Code as the notable holdout).

### 8.2 Where Fragmentation Persists

**Significant fragmentation remains in:**

1. **IDE-level integration:** ACP (JetBrains/Zed) vs VS Code extension model vs Cursor's proprietary system. Each IDE handles agent-to-editor communication differently.

2. **Hooks and lifecycle events:** Claude Code's hook system (PreToolUse, PostToolUse, etc.) has no cross-tool equivalent. Cursor and Windsurf handle automation differently.

3. **Subagent orchestration:** Claude Code's subagent model (isolated context windows, parallel execution) is unique. Other tools handle multi-agent workflows differently or not at all.

4. **Plugin packaging and distribution:** Claude Code plugins (`.claude-plugin/plugin.json`), Continue Hub blocks, and VS Code extensions are all different distribution formats. There is no universal plugin package format.

5. **Rules file path conventions:** While AGENTS.md is converging as the standard, tools still scan different paths for skills, rules, and configuration. The `.agents/` directory is emerging as the neutral convention but is not yet universal.

6. **MCP configuration format:** Each tool stores MCP server definitions differently -- JSON for Cursor/Claude, TOML for Codex, JSON for Cline, settings UI for others.

### 8.3 The Three-Layer Portability Model

A clear architecture has emerged for building portable AI coding skills:

```
Layer 3: Project Instructions (AGENTS.md)
  - Coding standards, architecture notes, conventions
  - Tool-agnostic Markdown files
  - Highest portability today

Layer 2: Agent Skills (SKILL.md)
  - Procedural knowledge, workflows, domain expertise
  - Cross-platform via agentskills.io specification
  - Growing portability (25+ platforms)

Layer 1: Tool Integration (MCP)
  - External tools, APIs, data sources
  - Universal protocol via AAIF/Linux Foundation
  - Highest maturity and adoption
```

---

## 9. Practical Recommendations

### 9.1 For Building Portable Skills Today

1. **Use the Agent Skills format (SKILL.md):** This is the highest-leverage investment. A skill with a `SKILL.md` file, optional `scripts/`, `references/`, and `assets/` directories will work across Claude Code, Codex, VS Code Copilot, Cursor, Gemini CLI, and others.

2. **Place skills in `.agents/skills/`:** This is the most widely recognized discovery path. For user-level skills, use `~/.agents/skills/`.

3. **Write MCP servers for tool integrations:** If your skill needs to interact with external services, build an MCP server. It will work across all major clients.

4. **Use AGENTS.md for project instructions:** Create an `AGENTS.md` at the project root. For Claude Code compatibility, add a `CLAUDE.md` that references it:
   ```bash
   echo 'See @AGENTS.md' > CLAUDE.md
   ```

5. **Keep tool-specific features separate:** If you need Claude Code hooks, Cursor rule types, or other platform-specific features, keep them in tool-specific configuration files alongside your portable components.

### 9.2 Portable Skill Directory Structure

```
my-portable-skill/
  SKILL.md                    # Works across 25+ platforms
  scripts/
    run-analysis.sh           # Deterministic automation
  references/
    api-guide.md              # Context loaded on demand
  assets/
    template.json             # Templates and resources

# For Claude Code plugin distribution (optional):
  .claude-plugin/
    plugin.json
  hooks/
    hooks.json                # Claude Code-specific

# For project-level instructions:
AGENTS.md                     # Works everywhere except Claude Code
CLAUDE.md                     # -> 'See @AGENTS.md' for Claude Code
```

### 9.3 MCP Server for Maximum Portability

Build MCP servers in TypeScript or Python using the official SDKs. Configure per-tool:

- **Claude Code:** `.mcp.json` in plugin root or project `.claude/` directory
- **Codex CLI:** `~/.codex/config.toml` under `[mcp_servers]`
- **Cursor:** `.cursor/mcp.json`
- **Cline:** `cline_mcp_settings.json`
- **VS Code:** VS Code settings

### 9.4 What to Avoid

1. **Do not build platform-specific plugins when a portable option exists.** Agent Skills and MCP cover most use cases.
2. **Do not assume AGENTS.md alone is sufficient.** It provides instructions but not structured capabilities -- use Skills for that.
3. **Do not rely on community MCP wrappers for production.** Aider's MCP integration, for example, is experimental. Use tools with first-class MCP client support.

---

## 10. Conclusion

The AI coding assistant ecosystem in February 2026 is in a state of rapid but incomplete convergence. Three complementary standards have emerged with broad industry backing:

- **MCP** (tool integration) -- the most mature, with near-universal adoption and Linux Foundation governance
- **Agent Skills** (capability packaging) -- rapidly growing, adopted by 25+ platforms within two months of open-sourcing
- **AGENTS.md** (project instructions) -- widely adopted as a convention, backed by 60,000+ projects

For developers building AI coding skills today, the practical advice is clear: **build on these three standards.** Skills written in the Agent Skills format, tools exposed via MCP, and project context provided through AGENTS.md will work across the vast majority of AI coding assistants available today.

The remaining fragmentation -- in hooks, subagents, plugin packaging, and IDE integration -- represents areas where tools are still competing on features. These platform-specific capabilities can be layered on top of the portable foundation when needed.

The formation of the Agentic AI Foundation under the Linux Foundation, with platinum backing from all major AI vendors, suggests that the industry is committed to maintaining and evolving these shared standards. The era of maintaining separate `.cursorrules`, `.windsurfrules`, `CLAUDE.md`, and `.clinerules` files is ending. The era of portable AI coding skills has begun.

---

## 11. References

1. [Model Context Protocol - Wikipedia](https://en.wikipedia.org/wiki/Model_Context_Protocol) -- Overview and history of MCP
2. [A Year of MCP: From Internal Experiment to Industry Standard - Pento](https://www.pento.ai/blog/a-year-of-mcp-2025-review) -- Comprehensive review of MCP adoption in 2025
3. [MCP Specification (2025-11-25)](https://modelcontextprotocol.io/specification/2025-11-25) -- Official MCP specification
4. [Create Plugins - Claude Code Docs](https://code.claude.com/docs/en/plugins) -- Official Claude Code plugin documentation
5. [Understanding Claude Code's Full Stack - alexop.dev](https://alexop.dev/posts/understanding-claude-code-full-stack/) -- Analysis of Claude Code's extension architecture
6. [AI Agent Rule Files Chaos - EveryDev.ai](https://www.everydev.ai/p/blog-ai-coding-agent-rules-files-fragmentation-formats-and-the-push-to-standardize) -- Comprehensive analysis of rules file fragmentation
7. [Agent Skills Overview - agentskills.io](https://agentskills.io/home) -- Official Agent Skills specification and adopter list
8. [Agent Skills: Anthropic's Next Bid to Define AI Standards - The New Stack](https://thenewstack.io/agent-skills-anthropics-next-bid-to-define-ai-standards/) -- Industry analysis of Agent Skills
9. [Anthropic Launches Enterprise Agent Skills - VentureBeat](https://venturebeat.com/technology/anthropic-launches-enterprise-agent-skills-and-opens-the-standard) -- Launch coverage and adoption details
10. [Agent Skills in VS Code - VS Code Docs](https://code.visualstudio.com/docs/copilot/customization/agent-skills) -- VS Code/Copilot Agent Skills implementation
11. [Codex CLI Skills - OpenAI Developers](https://developers.openai.com/codex/skills) -- Codex CLI skills documentation
12. [Codex MCP Configuration - OpenAI Developers](https://developers.openai.com/codex/mcp/) -- Codex CLI MCP support
13. [Custom Instructions for AGENTS.md - OpenAI Developers](https://developers.openai.com/codex/guides/agents-md/) -- AGENTS.md specification for Codex
14. [Adding Custom Instructions for GitHub Copilot - GitHub Docs](https://docs.github.com/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot) -- Copilot instruction files
15. [Keep Your AGENTS.md in Sync - Kaushik Gopal](https://kau.sh/blog/agents-md/) -- Practical AGENTS.md sync strategies
16. [Linux Foundation Announces AAIF Formation](https://www.linuxfoundation.org/press/linux-foundation-announces-the-formation-of-the-agentic-ai-foundation) -- Agentic AI Foundation announcement
17. [JetBrains x Zed: Agent Client Protocol](https://blog.jetbrains.com/ai/2025/10/jetbrains-zed-open-interoperability-for-ai-coding-agents-in-your-ide/) -- ACP protocol announcement
18. [ACP Agent Registry Is Live - JetBrains](https://blog.jetbrains.com/ai/2026/01/acp-agent-registry/) -- ACP registry launch
19. [Configuring MCP Servers - Cline](https://docs.cline.bot/mcp/configuring-mcp-servers) -- Cline MCP documentation
20. [Simplifying AI Development with MCP, Docker, and Continue Hub](https://blog.continue.dev/simplifying-ai-development-with-model-context-protocol-docker-and-continue-hub/) -- Continue MCP integration
21. [Equipping Agents for the Real World with Agent Skills - Anthropic](https://claude.com/blog/equipping-agents-for-the-real-world-with-agent-skills) -- Agent Skills engineering design
22. [Claude Code Gets Path-Specific Rules - Paddo.dev](https://paddo.dev/blog/claude-rules-path-specific-native/) -- Rules format comparison
23. [AI Coding Assistant Rules for Windsurf and Cursor - Deeplearning.fr](https://deeplearning.fr/ai-coding-assistant-rules-for-windsurf-and-cursor/) -- Windsurf/Cursor rules comparison
24. [agent-rules - GitHub (steipete)](https://github.com/steipete/agent-rules) -- Cross-tool rules repository (archived)
25. [Cursor MCP Server Setup - BrainGrid](https://www.braingrid.ai/blog/cursor-mcp) -- Cursor MCP configuration guide
