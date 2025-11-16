# thefocus-skills

Skills and integration documentation repository for Focus.AI - building agentic software for mission-critical operations.

## Overview

This repository contains reference documentation, brand assets, and implementation patterns for the Focus.AI platform ecosystem.

## Contents

### Distill Backend Service Specification
[distill-backend-service.md](distill-backend-service.md)

A comprehensive microservices framework for building AI-powered content aggregation services. Key features:
- Distributed architecture for collecting content from multiple platforms (Twitter/X, Email, GitHub, YouTube, etc.)
- AI-native self-documentation for LLM integration
- Standard API patterns for service discovery, health checks, and data synchronization
- JWT-based authentication via Clerk
- Explicit user lifecycle management (watch/unwatch patterns)

### Focus Account Integration Guide
[focus-account-integration.md](focus-account-integration.md)

Integration patterns for connecting applications to the Focus API. Includes:
- Authentication methods (PAT, Clerk JWT, browser cookies)
- Wallet and credit management
- Job creation, completion, and failure workflows
- Device-code flow for CLI applications
- Error handling patterns

### Focus.AI Brand System
[focus-ai-brand/](focus-ai-brand/)

Complete brand identity system with assets and guidelines:
- **[SKILL.md](focus-ai-brand/SKILL.md)** - Comprehensive style guide covering colors, typography, layout, and components
- **Color Palette** - Paper, Ink, Graphite, Petrol, Vermilion with tinted background variants
- **Typography** - CinaGEO (primary), 00HypertextMono (code), GhostlyGothic (display)
- **Layout** - Asymmetric three-column grid system
- **Assets** - Font files and HTML reference implementations

#### Brand Assets
```
focus-ai-brand/assets/
├── fonts/           # CinaGEO, 00HypertextMono, GhostlyGothic
└── examples/        # HTML reference implementations
    ├── hero-section.html
    ├── card-components.html
    └── full-landing-page.html
```

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
