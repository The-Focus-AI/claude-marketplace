# Focus.AI Skills Reference

This repository contains skills for Focus.AI development. When a user asks about topics related to these skills, load the appropriate SKILL.md file to get detailed instructions and patterns.

## Available Skills

### distill-backend-service
**Path**: `distill-backend-service/SKILL.md`

Build Distill microservices that collect, process, and summarize content from platforms (Twitter/X, Email, GitHub, YouTube). Use when implementing watch/unwatch lifecycle, sync endpoints, AI-generated summaries, or service discovery patterns. Trigger when user needs to create a content aggregation service, implement standard API patterns, or build LLM-optimized service interfaces.

---

### focus-account-integration
**Path**: `focus-account-integration/SKILL.md`

Integrate applications with Focus API for authentication, wallet/credits, and job management. Use when implementing Clerk JWT auth, device-code flow for CLI tools, credit reservation and settlement, or job lifecycle (create/complete/fail). Trigger when building apps that connect to account.thefocus.ai or need to manage user credits and jobs.

---

### focus-ai-brand
**Path**: `focus-ai-brand/SKILL.md`

Apply Focus.AI brand guidelines to presentations, proposals, PDFs, PowerPoints, and other documents. Use when creating branded materials that need to follow Focus.AI's visual identity including color palette (Paper, Ink, Petrol, Vermilion), typography (CinaGEO fonts), asymmetric layouts, and design system specifications. Trigger when user mentions "focus.ai style" or requests branded Focus.AI materials.

---

## How to Use

When a user request matches one of the skill descriptions above:

1. **Load the SKILL.md file** for that skill to get detailed implementation guidance
2. **Follow the patterns** described in the skill documentation

### Trigger Examples

- "Create a Distill service for Twitter" → Load `distill-backend-service/SKILL.md`
- "Integrate my app with Focus authentication" → Load `focus-account-integration/SKILL.md`
- "Apply Focus.AI branding to this presentation" → Load `focus-ai-brand/SKILL.md`
- "Build a content aggregation microservice" → Load `distill-backend-service/SKILL.md`
- "Implement job credit management" → Load `focus-account-integration/SKILL.md`
- "Use Focus.AI color palette" → Load `focus-ai-brand/SKILL.md`
