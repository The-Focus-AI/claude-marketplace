# thefocus-skills

Skills and integration documentation repository for Focus.AI - building agentic software for mission-critical operations.

## Overview

This repository contains reference documentation, brand assets, and implementation patterns for the Focus.AI platform ecosystem.

## Skills

Each skill provides a `SKILL.md` with front matter (name, description) and implementation guidance, plus a `REFERENCE.md` with complete specifications.

### Distill Backend Service
[distill-backend-service/](distill-backend-service/)

Build microservices for AI-powered content aggregation:
- **[SKILL.md](distill-backend-service/SKILL.md)** - Quick start guide and patterns
- **[REFERENCE.md](distill-backend-service/REFERENCE.md)** - Full framework specification
- Watch/unwatch user lifecycle management
- Standard API patterns for service discovery
- AI-generated summaries and feeds
- JWT-based authentication via Clerk

### Focus Account Integration
[focus-account-integration/](focus-account-integration/)

Connect applications to the Focus API:
- **[SKILL.md](focus-account-integration/SKILL.md)** - Integration quick start
- **[REFERENCE.md](focus-account-integration/REFERENCE.md)** - Complete API guide
- Authentication methods (PAT, Clerk JWT, browser cookies)
- Wallet and credit management
- Job creation, completion, and failure workflows
- Device-code flow for CLI applications

### Focus.AI Brand System
[focus-ai-brand/](focus-ai-brand/)

Complete brand identity system:
- **[SKILL.md](focus-ai-brand/SKILL.md)** - Style guide with colors, typography, layout
- **Color Palette** - Paper, Ink, Graphite, Petrol, Vermilion
- **Typography** - CinaGEO, 00HypertextMono, GhostlyGothic
- **Layout** - Asymmetric three-column grid system
- **Assets** - Font files and HTML examples

```
focus-ai-brand/assets/
├── fonts/           # CinaGEO, 00HypertextMono, GhostlyGothic
└── examples/        # HTML reference implementations
    ├── hero-section.html
    ├── card-components.html
    └── full-landing-page.html
```

## Claude Code Integration

The repository includes a generated `CLAUDE.md` file that provides Claude Code with a reference of all available skills and when to use them.

### Regenerating CLAUDE.md

After adding or modifying skills, run:

```bash
./generate-claude-md.sh
```

This extracts front matter from all `*/SKILL.md` files and creates a consolidated reference.

## Target Users

- **Backend developers** implementing Distill services
- **Frontend developers** integrating Focus APIs
- **Designers** creating branded materials
- **DevOps/infrastructure teams** deploying services

## Core Principles

- Schema-first systems maintaining human control
- Intelligent content aggregation and summarization
- Extensible, LLM-optimized service interfaces
- Unified authentication and credit management
