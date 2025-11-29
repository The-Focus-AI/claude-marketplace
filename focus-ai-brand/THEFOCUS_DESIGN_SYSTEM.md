# The Focus.AI Design System — Foundation

> This document defines the shared philosophy, principles, and foundations that unite all Focus.AI brands. For specific implementation details, see:
> - [THEFOCUS_CLIENT_DESIGN_SYSTEM.md](./THEFOCUS_CLIENT_DESIGN_SYSTEM.md) — Client work, services, products
> - [THEFOCUS_LABS_DESIGN_SYSTEM.md](./THEFOCUS_LABS_DESIGN_SYSTEM.md) — Research, experiments, public content

---

## Brand Architecture

```
The Focus.AI
├── Focus.AI (Client)     → Services, products, client-facing work
│   Aesthetic: Editorial, polished, professional
│   Palette: Paper, Ink, Petrol, Vermilion
│
└── Focus.AI Labs         → Research, experiments, public content
    Aesthetic: Research report, Bell Labs, exploratory
    Palette: Paper, Void, Rand-Blue, Alert-Red
```

### Relationship

Both brands share:
- Core philosophy: "Distill the signal from the noise"
- Typography: Inter (sans) + Courier Prime (mono)
- Foundation principles: Clarity, precision, warmth
- Quality standards: Accessible, well-crafted, intentional

They differ in:
- Color palettes (related but distinct)
- Aesthetic feel (editorial vs. research)
- Audience (clients vs. peer community)
- Voice (professional vs. curious)

---

## Core Philosophy

### "Distill the Signal from the Noise"

This isn't just a tagline — it's the operating principle for everything Focus.AI creates:

- **In client work**: Connecting siloed data, creating curated UIs, filtering noise from systems
- **In Labs**: Synthesizing conference insights, documenting experiments, sharing learnings

Every design decision should support signal clarity. If an element doesn't help the reader focus on what matters, question whether it belongs.

### Design Principles

1. **Clarity over decoration** — Every element earns its place
2. **Warmth without softness** — Human and approachable, but precise
3. **Structure reveals meaning** — Layout, hierarchy, and spacing do the work
4. **Accessibility is non-negotiable** — If it's not readable, it's not designed

---

## Shared Typography

Both brands use the same font families, applied differently based on context.

### Font Families

| Family | Stack | Usage |
|--------|-------|-------|
| **Sans** | Inter, system-ui, sans-serif | Headings, body text, UI |
| **Mono** | Courier Prime, monospace | Metadata, labels, code, technical content |

### Why These Fonts

- **Inter**: Highly legible, excellent at all sizes, professional without being cold, widely available
- **Courier Prime**: Designed for readability (unlike most monospace fonts), warmth of a typewriter, signals "technical document"

### Type Scale (Shared Base)

| Element | Size | Weight | Notes |
|---------|------|--------|-------|
| **Hero** | 60-96px | 900 (Black) | Brand moments only |
| **H1** | 36-48px | 900 (Black) | Page titles |
| **H2** | 24-30px | 700-900 | Section headers |
| **H3** | 20px | 700 | Subsections |
| **Body** | 16-17px | 400-500 | Default readable size |
| **Small** | 14px | 400-500 | Secondary text |
| **Label** | 10-12px | 500-700 | Metadata, always mono |

### Typography Rules

1. **Headings**: Use `font-black` (900) for impact, negative letter-spacing at large sizes
2. **Body**: Use `font-normal` (400) or `font-medium` (500), generous line-height (1.5-1.6)
3. **Labels**: Always `font-mono`, uppercase for navigational labels, normal case for metadata
4. **Never mix**: Don't use sans and mono in the same text block (except inline code)

---

## Shared Spacing System

Base unit: **4px** (using Tailwind's default scale)

| Token | Value | Usage |
|-------|-------|-------|
| 1 | 4px | Tight inline spacing |
| 2 | 8px | Button padding, list gaps |
| 3 | 12px | Icon-to-text spacing |
| 4 | 16px | Default component spacing |
| 6 | 24px | Section internal spacing |
| 8 | 32px | Between major elements |
| 12 | 48px | Large section padding |
| 16 | 64px | Page-level spacing |

### Spacing Philosophy

- **Generous whitespace** — Let content breathe
- **Consistent rhythm** — Use the scale, don't invent values
- **Responsive reduction** — Desktop can be more spacious; mobile compresses

---

## Color Philosophy

Both brands use warm backgrounds and limited palettes, but with different accent colors.

### Shared Principles

1. **Maximum 5 colors** per composition (excluding tints)
2. **Warm paper tones** — Never pure white (`#ffffff`) for backgrounds
3. **High contrast text** — Minimum 4.5:1 for body text (WCAG AA)
4. **Accent restraint** — Brand colors for emphasis, not decoration

### Color Comparison

| Role | Client | Labs | Notes |
|------|--------|------|-------|
| **Background** | Paper `#faf9f6` | Paper `#f3f2ea` | Labs is warmer |
| **Text** | Ink `#161616` | Void `#1a1a1a` | Nearly identical |
| **Primary Accent** | Petrol `#0e3b46` | Rand-Blue `#0055aa` | Both "trustworthy" blues |
| **Secondary Accent** | Vermilion `#c3471d` | Alert-Red `#d93025` | Both warm highlights |
| **Secondary Text** | Graphite `#4a4a4a` | (uses gray scale) | Client has named token |

### Why Different Palettes?

- **Client (Petrol/Vermilion)**: Sophisticated, editorial, contemporary — signals "professional services"
- **Labs (Rand-Blue/Alert-Red)**: Institutional, classic, research — signals "serious documentation"

The difference is intentional: you should be able to tell at a glance whether you're looking at client-facing work or a Labs experiment.

---

## Shared Accessibility Standards

Both brands must meet these minimums:

| Requirement | Standard | Test |
|-------------|----------|------|
| Body text contrast | 4.5:1 minimum | WCAG AA |
| Large text (24px+) | 3:1 minimum | WCAG AA |
| Focus indicators | Visible, 2px+ | Keyboard navigation |
| Touch targets | 44px minimum | Mobile usability |
| Heading hierarchy | Logical sequence | Screen readers |

### Contrast Ratios to Verify

Before shipping, check:
- Primary text on background
- Secondary text on background
- Accent colors on background
- Text on accent-colored buttons

---

## Border & Radius Principles

### Borders

Both brands use borders for structure, not decoration:

- **1px borders**: Default for cards, dividers
- **2px borders**: Emphasis only (active states, focus)
- **Subtle colors**: Borders should recede, not compete with content

### Border Radius

| Context | Radius | Notes |
|---------|--------|-------|
| Buttons, inputs | 4-6px | Softened but not round |
| Cards, containers | 6-8px | Default for content blocks |
| Pills, tags | Full radius | Small UI elements only |

**Never**: Fully rounded corners on large containers — it reads as "playful" which conflicts with the professional/research tone.

---

## Voice & Tone Foundations

Both brands share core communication values, expressed differently:

| Value | Client Expression | Labs Expression |
|-------|------------------|-----------------|
| **Clarity** | Precise, confident | Clear, exploratory |
| **Warmth** | Professional-friendly | Peer-to-peer |
| **Expertise** | Demonstrated through work | Shared through findings |
| **Honesty** | Direct about capabilities | Transparent about process |

### Shared Anti-Patterns

Both brands avoid:
- Corporate buzzwords ("leverage", "synergize", "unlock value")
- Hyperbole ("revolutionary", "game-changing")
- Condescension (explaining basics to expert audiences)
- Self-promotion (let the work speak)

---

## Technical Stack

Both brands are built on similar foundations:

| Layer | Technology | Notes |
|-------|------------|-------|
| **Framework** | Astro | Static-first, islands architecture |
| **Components** | React | For interactive elements |
| **Styling** | Tailwind CSS v4 | Utility-first, design tokens |
| **Fonts** | Inter + Courier Prime | Self-hosted or system fallbacks |

### Tailwind Configuration

Both brands should define custom colors in Tailwind config:

```javascript
// Shared structure, different values per brand
theme: {
  extend: {
    colors: {
      paper: 'var(--color-paper)',
      primary: 'var(--color-primary)', // Petrol or Rand-Blue
      accent: 'var(--color-accent)',   // Vermilion or Alert-Red
      text: 'var(--color-text)',       // Ink or Void
    },
    fontFamily: {
      sans: ['Inter', 'system-ui', 'sans-serif'],
      mono: ['Courier Prime', 'monospace'],
    },
  },
}
```

---

## When to Use Which Brand

| Context | Use Client Brand | Use Labs Brand |
|---------|------------------|----------------|
| Client proposals | ✓ | |
| Case studies | ✓ | |
| Service pages | ✓ | |
| Product marketing | ✓ | |
| Conference analysis | | ✓ |
| Research reports | | ✓ |
| Experiments | | ✓ |
| Technical blog posts | | ✓ |
| Open source projects | | ✓ |

**Rule of thumb**: If it's for a client or selling services, use Client. If it's sharing what you learned or explored, use Labs.

---

## Quality Checklist (Both Brands)

Before shipping any Focus.AI branded material:

- [ ] Typography uses Inter (sans) and/or Courier Prime (mono)
- [ ] Color palette limited to 5 colors max
- [ ] Background is warm paper tone, not pure white
- [ ] Body text contrast meets 4.5:1 minimum
- [ ] Spacing follows 4px base unit scale
- [ ] Layout supports clarity — no decorative elements
- [ ] Voice matches brand (professional or curious)
- [ ] Anti-patterns avoided (no buzzwords, no hype)
- [ ] Mobile responsive with appropriate breakpoints
- [ ] Accessibility requirements met

---

## File Reference

| Document | Purpose |
|----------|---------|
| This file | Shared philosophy and foundations |
| [THEFOCUS_CLIENT_DESIGN_SYSTEM.md](./THEFOCUS_CLIENT_DESIGN_SYSTEM.md) | Client brand specifics: colors, layouts, voice |
| [THEFOCUS_LABS_DESIGN_SYSTEM.md](./THEFOCUS_LABS_DESIGN_SYSTEM.md) | Labs brand specifics: colors, patterns, voice |
| [SKILL.md](./SKILL.md) | How to use this skill |
