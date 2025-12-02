---
title: "Best Practices for Capturing and Applying Design Systems"
date: 2025-11-28
tags: [design-systems, design-tokens, AI, LLM, brand-guidelines, documentation]
project_stack: [Astro, Tailwind CSS, React, TypeScript]
recommendation: "Use the W3C Design Tokens format (JSON) as your single source of truth, combined with structured markdown documentation for AI context"
use_when:
  - "Extracting a design system from existing visuals or products"
  - "Creating documentation that both humans and AI tools can consume"
  - "Ensuring consistent AI-generated code matches your brand"
  - "Scaling design across multiple products or platforms"
dont_use_when:
  - "One-off projects with no reuse expected"
  - "Very early prototyping where design hasn't stabilized"
  - "Teams without design-development collaboration"
---

# Best Practices for Capturing and Applying Design Systems

## Summary

Capturing a design system involves three phases: **extraction** (auditing existing visuals to identify patterns), **documentation** (recording decisions in machine-readable and human-readable formats), and **application** (using that documentation to drive consistent output from both human developers and AI tools).

The W3C Design Tokens Community Group released their first stable specification (2025.10) in October 2025, providing a standardized JSON format that major tools like Figma, Tokens Studio, and Style Dictionary now support. For AI/LLM workflows, combining design tokens with structured markdown documentation creates "guardrails" that direct AI agents toward on-brand, consistent results.

Your existing Tailwind theme in `global.css` is a good foundation—the next step is formalizing it into a portable, tool-agnostic format that AI editors can consume.

## Project Context

This project uses:
- **Astro** for static site generation
- **Tailwind CSS v4** with a custom `@theme` block defining colors (`paper`, `void`, `rand-blue`, etc.) and fonts (`Inter`, `Courier Prime`)
- **React** components
- Custom CSS effects (halftone, CRT scanlines, Bell Labs photo filters)

The design language has a distinct "retro-tech" aesthetic that needs to be captured systematically.

## Detailed Findings

### Phase 1: Extraction — The Visual Audit Process

**What it is**: A systematic inventory of every visual element in your product to identify patterns, inconsistencies, and opportunities for standardization.

**Why consider it**: You can't document what you haven't identified. Companies like UXPin discovered 116 color variables with 62 shades of gray before conducting an audit—massive redundancy that slowed development.

**How to implement**:

1. **Define scope**: Start with core screens or the "happy path" user journey
2. **Screenshot everything**: Capture unique instances of typography, colors, buttons, icons, spacing, navigation
3. **Use automated tools**: CSS Stats can extract colors, spacing, and typography from existing stylesheets
4. **Organize by category**:
   - **Foundations**: Colors, typography, spacing, icons, motion
   - **Components**: Buttons, forms, cards, navigation, tables
   - **Patterns**: Functional (reusable UI), perceptual (brand aesthetics), platform-specific

```bash
# For web projects, CSS Stats can help
# Visit https://cssstats.com and paste your URL or CSS

# Or inspect programmatically with browser tools:
# - DevTools > Elements > Computed styles
# - Look for repeated values in padding, margin, font-size
```

**What to capture for each element**:

| Category | Elements to Extract |
|----------|---------------------|
| Colors | Primary, secondary, accent, semantic (error, success, warning), neutrals/grays, background surfaces |
| Typography | Font families, size scale (H1-H6, body, small), weights, line heights, letter spacing |
| Spacing | Base unit, scale (4px, 8px, 16px, etc.), component padding, layout margins |
| Effects | Shadows, borders, radii, transitions, filters |
| Icons | Style (outlined/filled), sizes, stroke weights |

**Trade-offs**:
- Pro: Reveals hidden inconsistencies and bloat
- Con: Time-intensive for large products (budget 1-2 weeks for comprehensive audit)

---

### Phase 2: Documentation — The W3C Design Tokens Format

**What it is**: A standardized JSON format for expressing design decisions as portable, tool-agnostic data.

**Why consider it**: The October 2025 stable release means major tools (Figma, Sketch, Tokens Studio, Style Dictionary, Penpot) now support or are implementing this standard. One file works everywhere.

**How to implement**:

Design token files use `.tokens` or `.tokens.json` extensions with this structure:

```json
{
  "$description": "Design tokens for the AI Engineering Summit site",

  "color": {
    "$type": "color",
    "paper": {
      "$value": "#f3f2ea",
      "$description": "Primary background - warm off-white"
    },
    "void": {
      "$value": "#1a1a1a",
      "$description": "Primary text and dark elements"
    },
    "rand-blue": {
      "$value": "#0055aa",
      "$description": "Accent color for links and highlights"
    },
    "alert-red": {
      "$value": "#d93025",
      "$description": "Error states and warnings"
    },
    "surface": {
      "$value": "#e6e4dc",
      "$description": "Secondary background surfaces"
    },
    "terminal-green": {
      "$value": "#00ff41",
      "$description": "CRT terminal effect accent"
    }
  },

  "fontFamily": {
    "$type": "fontFamily",
    "sans": {
      "$value": ["Inter", "Helvetica", "Arial", "sans-serif"],
      "$description": "Primary text font"
    },
    "mono": {
      "$value": ["Courier Prime", "monospace"],
      "$description": "Code and terminal styling"
    }
  },

  "fontSize": {
    "$type": "dimension",
    "xs": { "$value": { "value": 12, "unit": "px" } },
    "sm": { "$value": { "value": 14, "unit": "px" } },
    "base": { "$value": { "value": 16, "unit": "px" } },
    "lg": { "$value": { "value": 18, "unit": "px" } },
    "xl": { "$value": { "value": 20, "unit": "px" } },
    "2xl": { "$value": { "value": 24, "unit": "px" } },
    "3xl": { "$value": { "value": 30, "unit": "px" } },
    "4xl": { "$value": { "value": 36, "unit": "px" } }
  },

  "spacing": {
    "$type": "dimension",
    "1": { "$value": { "value": 4, "unit": "px" } },
    "2": { "$value": { "value": 8, "unit": "px" } },
    "3": { "$value": { "value": 12, "unit": "px" } },
    "4": { "$value": { "value": 16, "unit": "px" } },
    "6": { "$value": { "value": 24, "unit": "px" } },
    "8": { "$value": { "value": 32, "unit": "px" } },
    "12": { "$value": { "value": 48, "unit": "px" } },
    "16": { "$value": { "value": 64, "unit": "px" } }
  }
}
```

**Key specification rules**:
- All spec properties use `$` prefix (`$value`, `$type`, `$description`)
- Token names cannot contain `$`, `{`, `}`, or `.`
- Types inherit downward through groups
- References use `{group.token}` syntax: `"$value": "{color.rand-blue}"`

**Trade-offs**:
- Pro: Tool-agnostic, emerging industry standard, supported by major design tools
- Con: Still evolving; some tools have partial support

---

### Phase 3: Application — Structuring for AI/LLM Consumption

**What it is**: Formatting your design system documentation so AI code editors (Cursor, Windsurf, Claude Code) can use it as context for generating consistent code.

**Why consider it**: Without design context, LLMs produce generic output. With proper context, AI "provides code that better aligns to your design system in both design and code quality."

**How to implement**:

#### Option A: MCP Server Connection (Recommended for Figma users)

Figma's Dev Mode MCP server connects directly to AI editors, providing real-time access to:
- Component structures and naming
- Design variables and tokens
- Style definitions

```bash
# In Cursor/Windsurf/Claude Code settings, add MCP server:
# Figma Dev Mode MCP provides live design context
```

#### Option B: Structured Markdown Documentation (Universal)

Create a `DESIGN_SYSTEM.md` file that AI tools can reference:

```markdown
# Design System Reference

## Brand Voice
Retro-tech aesthetic inspired by Bell Labs and early computing.
Professional but approachable. Technical precision with warmth.

## Color Palette

| Token | Hex | Usage |
|-------|-----|-------|
| `paper` | #f3f2ea | Page backgrounds |
| `void` | #1a1a1a | Primary text, dark UI |
| `rand-blue` | #0055aa | Links, accents, CTAs |
| `alert-red` | #d93025 | Errors, warnings |
| `surface` | #e6e4dc | Cards, secondary backgrounds |
| `terminal-green` | #00ff41 | CRT/terminal effects only |

## Typography

- **Sans (Inter)**: All body text, headings, UI elements
- **Mono (Courier Prime)**: Code blocks, terminal styling, data

### Scale
- H1: 36px / font-bold
- H2: 30px / font-bold
- H3: 24px / font-semibold
- Body: 16px / font-normal
- Small: 14px / font-normal

## Spacing System
Base unit: 4px. Use multiples: 4, 8, 12, 16, 24, 32, 48, 64px

## Component Patterns

### Buttons
- Primary: bg-rand-blue text-paper rounded px-4 py-2
- Secondary: border border-void text-void rounded px-4 py-2

### Cards
- bg-surface rounded-lg p-6 shadow-sm

## Effects (Use Sparingly)
- `.halftone`: Subtle dot pattern overlay for images
- `.bell-labs-photo`: Grayscale + contrast filter for speaker photos
- `.scanlines`: CRT monitor effect for terminal sections

## DO NOT
- Use terminal-green outside of CRT/terminal contexts
- Mix Inter and Courier Prime in the same text block
- Use pure white (#ffffff) backgrounds—always use paper
```

#### Option C: Embedding in AI Prompts

For one-off tasks, embed guidelines directly:

```markdown
You are generating code for a site with these brand guidelines:
- Colors: paper (#f3f2ea) for backgrounds, void (#1a1a1a) for text, rand-blue (#0055aa) for accents
- Fonts: Inter for UI, Courier Prime for code
- Style: Retro-tech Bell Labs aesthetic
- Use Tailwind CSS classes

Generate a card component for displaying speaker information.
```

**Trade-offs**:
- MCP: Pro (live sync), Con (Figma-specific, requires setup)
- Markdown: Pro (universal, version-controlled), Con (manual updates)
- Inline prompts: Pro (quick), Con (not scalable, repetitive)

---

### Tools for Extraction and Management

| Tool | Purpose | Notes |
|------|---------|-------|
| [CSS Stats](https://cssstats.com) | Extract colors, typography, spacing from CSS | Free, web-based |
| [Tokens Studio](https://tokens.studio) | Figma plugin for managing design tokens | Supports W3C format |
| [Style Dictionary](https://styledictionary.com) | Build system for design tokens | Transforms tokens to CSS, iOS, Android |
| [Figma Dev Mode MCP](https://www.figma.com) | Connect Figma to AI editors | Works with Cursor, Claude Code |
| [Supernova](https://supernova.io) | Design system documentation platform | Auto-generates docs from Figma |

## Recommendation

For this project specifically:

1. **Formalize your existing Tailwind theme** into a `.tokens.json` file using W3C format
2. **Create a `DESIGN_SYSTEM.md`** in your project root with the structured documentation above
3. **Add design context to your Claude Code skills** (you already have `focus-ai-brand` and `theme-factory` skills—extend these with specific token references)

This gives you:
- A portable source of truth (JSON tokens)
- Human-readable documentation (Markdown)
- AI-consumable context for consistent code generation

## When NOT to Use This

- **Rapid prototyping phase**: Don't formalize until visual direction is stable. Premature documentation creates maintenance burden.
- **Solo projects with no handoff**: If you're the only one touching the code and there's no AI assistance, the overhead may not pay off.
- **Highly dynamic brands**: Some brands intentionally break consistency for creative effect. A rigid system can constrain this.
- **Legacy systems without refactor budget**: Documenting a system you can't change creates frustration. Audit first, then decide if formalization is worth it.

## Sources

- [Design Tokens Community Group - W3C](https://www.w3.org/community/design-tokens/)
- [Design Tokens Specification 2025.10](https://www.designtokens.org/TR/drafts/format/)
- [Design System Checklist - UXPin](https://www.uxpin.com/studio/blog/launching-design-system-checklist/)
- [How to Create an Interface Inventory - Mainmatter](https://mainmatter.com/blog/2021/06/02/how-to-create-an-interface-inventory/)
- [Design Systems with AI - James Carleton](https://www.carletondesign.com/2025/07/28/ds-ai/)
- [Visual Design Audit Guide - Design Shack](https://designshack.net/articles/ux-design/visual-design-audit-guide/)
- [Design System Audit - Ramotion](https://www.ramotion.com/blog/design-system-audit/)
- [Best Design System Examples 2025 - UXPin](https://www.uxpin.com/studio/blog/best-design-system-examples/)
- [Enterprise Design Systems Best Practices - Softkraft](https://www.softkraft.co/enterprise-design-systems/)
- [Markdown Prompting in AI - Applied AI Tools](https://appliedai.tools/prompt-engineering/markdown-prompting-in-ai-prompt-engineering-explained-examples-tips/)
- [Prompt Design Strategies - Google AI](https://ai.google.dev/gemini-api/docs/prompting-strategies)
