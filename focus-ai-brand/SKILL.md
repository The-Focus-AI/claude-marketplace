---
name: focus-ai-brand
description: Apply Focus.AI brand guidelines to presentations, proposals, PDFs, PowerPoints, and other documents. Use when creating branded materials that need to follow Focus.AI's visual identity including color palette (Paper, Ink, Petrol, Vermilion), typography (CinaGEO fonts), asymmetric layouts, and design system specifications. Trigger when user mentions "focus.ai style" or requests branded Focus.AI materials.
---

# Focus.AI Brand Style Guide

Apply Focus.AI's editorial design system to create professional documents, presentations, PDFs, and HTML artifacts that maintain brand consistency.

## Core Brand Principles

Focus.AI emphasizes:
- **Editorial clarity**: Asymmetric layouts inspired by high-quality print design
- **Technical precision**: Schema-driven visual language with structured patterns
- **Human-centered**: Interfaces supporting decision-making and operator control
- **Restrained palette**: Limited colors used intentionally, never decoratively

## Color System

### Primary Colors (Maximum 5 per composition)

| Color | Hex | Usage |
|-------|-----|-------|
| **Paper** | `#faf9f6` | Primary background, light surfaces |
| **Ink** | `#161616` | Primary text, headings, high-emphasis |
| **Graphite** | `#4a4a4a` | Secondary text, muted content |
| **Petrol** | `#0e3b46` | Primary brand color, CTAs, links, accents |
| **Vermilion** | `#c3471d` | Secondary accent, highlights (use sparingly) |

### Tinted Backgrounds (Perceptually Equal Brightness)

| Tint | Hex | HSL | Usage |
|------|-----|-----|-------|
| **Cool** | `#edf6f8` | hsl(195, 45%, 95%) | Work pages |
| **Sage** | `#eef6ee` | hsl(120, 35%, 95%) | Capabilities pages |
| **Warm** | `#f7f0e6` | hsl(30, 45%, 94%) | About pages |
| **Lavender** | `#f2eef6` | hsl(270, 35%, 95%) | Insights/Tools |
| **Aqua** | `#edf6f6` | hsl(180, 30%, 95%) | Contact pages |

### Color Rules

1. Never exceed 5 colors (excluding tints) in a single composition
2. Always check contrast: Minimum 4.5:1 for body text, 3:1 for large text
3. Petrol is primary for actions, navigation, brand moments
4. Vermilion is accent only - use sparingly
5. No gradients - use solid colors
6. Override text colors when changing backgrounds for proper contrast

## Typography

### Font Families

All fonts available in `assets/fonts/`:
- **CinaGEO** (Light, Regular, Medium, Bold): Headings, body text, UI
- **00HypertextMono** (Light, Medium, Bold): Code, technical content (rare)
- **GhostlyGothic** (Light): Display/decorative (very rare)

**Default**: Use CinaGEO Medium (500) for body, Bold (700) for headings.

### Typography Scale

#### Desktop
| Element | Size | Weight | Line Height | Letter Spacing |
|---------|------|--------|-------------|----------------|
| **H1** | 88px (5.5rem) | 700 | 0.95 | -0.045em |
| **H2** | 48px (3rem) | 700 | 1.0 | -0.03em |
| **H3** | 30px (1.875rem) | 700 | 1.2 | -0.02em |
| **H4** | 24px (1.5rem) | 700 | 1.3 | -0.01em |
| **Body** | 17px | 500 | 1.6 | 0 |
| **Large Body** | 20px | 500 | 1.5 | 0 |
| **Small Text** | 14px | 500 | 1.5 | 0 |
| **Label** | 12px | 500 | 1.2 | 0.12em (uppercase) |

#### Mobile (≤768px)
- **H1**: 32-56px, -0.035em letter-spacing
- **H2**: 24-36px, 1.1 line-height
- **Body**: 16px, 1.65 line-height
- **Label**: 11px, 0.1em letter-spacing

Use `clamp()` for fluid responsive sizing:
```css
font-size: clamp(32px, 8vw, 88px);
```

### Typography Rules

1. Use negative letter-spacing on large text (improves readability at display sizes)
2. Minimum weight is Medium (500) - never lighter for body text
3. Bold (700) for all headings - consistent hierarchy through size, not weight
4. Uppercase labels always: 12px (11px mobile), uppercase, 0.12em spacing
5. Line height increases at smaller sizes

## Layout System

### Asymmetric Three-Column Grid (Desktop)

```
[Label: 140px] [Content: 1fr, max 740px] [Marginalia: 200px]
Gap: 3rem (48px)
Max-width: 1400px
```

**Mobile (≤1024px)**: Single column, 1.5rem gap

### CSS Grid Example

```css
.asymmetric-container {
    display: grid;
    grid-template-columns: 140px 1fr 200px;
    gap: 3rem;
    max-width: 1400px;
    margin: 0 auto;
}

.label-gutter { /* Left column */ }
.content-main { max-width: 740px; /* Center column */ }
.marginalia-gutter { /* Right column */ }
```

### Section Spacing

- **Desktop**: 7rem (112px) vertical padding
- **Mobile**: 3rem (48px) vertical padding
- **Container**: 2rem (32px) horizontal padding (desktop), 1.25rem (20px) mobile

### Spacing Scale (8px base unit)

| Token | Value | Usage |
|-------|-------|-------|
| `gap-2` | 8px | Tight spacing |
| `gap-3` | 12px | Icon-to-text |
| `gap-4` | 16px | Default component spacing |
| `gap-6` | 24px | Section internal |
| `gap-8` | 32px | Between major sections |
| `gap-12` | 48px | Extra large |

## Component Patterns

### Primary CTA Link

```css
font: CinaGEO, 12px, Medium (500)
text-transform: uppercase
letter-spacing: 0.15em
padding: 0.875rem 1.5rem (14px 24px)
border: 1px solid var(--petrol)
background: transparent
border-radius: 6px
transition: 200ms cubic-bezier(0.4, 0, 0.2, 1)
```

**Hover states**:
- Subtle petrol background (4% opacity)
- `translateY(-1px)`
- Soft shadow
- Arrow icon: `translateX(4px)`

### Cards

**Standard Card**:
```css
background: var(--paper)
border: 1px solid #d4d3cf
border-radius: 8px
padding: 2rem
hover: translateX(4px), shadow
```

**Elevated Card**:
```css
box-shadow: 0 2px 8px rgba(22, 22, 22, 0.04)
hover: translateY(-4px), larger shadow
```

**Minimal Card**:
```css
background: transparent
border: none
padding: 1.5rem
hover: subtle background fill
```

### Links

Midpoint underline animation:
```css
.link::after {
  width: 0 → 100% on hover
  Expands from center (translateX(-50%))
  Transition: 150ms ease
}
```

### Dividers

```css
/* Quiet Rule */
height: 1px
background: rgba(212, 211, 207, 0.5)

/* Gradient Rule */
linear-gradient(transparent 0%, color 10%, color 90%, transparent 100%)
```

### Labels/Kickers

```css
font: CinaGEO, 12px (11px mobile), Medium (500)
text-transform: uppercase
letter-spacing: 0.12em (0.1em mobile)
color: var(--ink) or var(--petrol)
```

## Border & Radius

### Border System

| Type | Width | Color/Opacity | Usage |
|------|-------|---------------|-------|
| **Quiet Rule** | 1px | `rgb(212 211 207 / 0.5)` | Subtle dividers |
| **Standard** | 1px | `#d4d3cf` | Card outlines |
| **Petrol** | 1px | `rgb(14 59 70 / 0.5)` | Branded dividers |
| **Emphasis** | 2px | Use rarely | Active states only |

### Border Radius

| Token | Value | Usage |
|-------|-------|-------|
| `rounded-sm` | 4px | Tags, badges |
| `rounded` | 6px | Buttons, inputs |
| `rounded-lg` | 8px | Cards, containers (default) |
| `rounded-xl` | 12px | Large cards |

**Default**: Use 8px for most cards and containers.

## Animation & Interaction

### Timing Functions

```css
/* Standard */
cubic-bezier(0.4, 0, 0.2, 1)

/* Smooth */
ease
```

### Durations

| Duration | Usage |
|----------|-------|
| 150ms | Quick interactions (underlines, small transforms) |
| 200ms | Standard transitions (buttons, colors) |
| 300ms | Hover effects on cards |
| 600ms | Fade-in animations |
| 800ms | Section reveals |

### Common Animations

**Fade In Up**:
```css
opacity: 0 → 1
transform: translateY(30px) → translateY(0)
duration: 800ms cubic-bezier(0.4, 0, 0.2, 1)
```

**Hover Translate**:
```css
transform: translateX(0) → translateX(4px)
duration: 300ms
```

## HTML Examples

See `assets/examples/` for complete implementations:

1. **hero-section.html**: Asymmetric layout with label gutter, heading, body, and CTA
2. **card-components.html**: Three card variations (standard, elevated, minimal)
3. **full-landing-page.html**: Complete page with multiple sections, proper spacing, and tinted backgrounds

### Font Loading in HTML

```html
<style>
@font-face {
    font-family: 'CinaGEO';
    src: url('path/to/CinaGEO-Medium.ttf') format('truetype');
    font-weight: 500;
}
@font-face {
    font-family: 'CinaGEO';
    src: url('path/to/CinaGEO-Bold.ttf') format('truetype');
    font-weight: 700;
}
</style>
```

## Creating Presentations (PPTX)

When creating PowerPoint presentations:

1. **Use the PPTX skill** first: Read `/mnt/skills/public/pptx/SKILL.md` for PowerPoint creation best practices
2. **Apply Focus.AI colors**: Use hex values from color system
3. **Typography**: CinaGEO Bold for titles, Medium for body
4. **Layout**: Asymmetric layouts with left-aligned content and generous whitespace
5. **Minimal design**: Clean slides, maximum 5 colors, no decorative elements

### Slide Layout Pattern

```
[Left margin: empty or label]
[Main content: max 740px width equivalent]
[Right margin: metadata or notes]
```

## Creating Documents (DOCX)

When creating Word documents:

1. **Use the DOCX skill** first: Read `/mnt/skills/public/docx/SKILL.md` for document creation
2. **Typography**: CinaGEO Medium for body (11-12pt), Bold for headings
3. **Colors**: Petrol for headings/accents, Ink for body
4. **Spacing**: Generous line height (1.6 for body)
5. **Margins**: Asymmetric if possible - wider left margin

## Creating PDFs

When creating or editing PDFs:

1. **Use the PDF skill** first: Read `/mnt/skills/public/pdf/SKILL.md` for PDF handling
2. **Apply brand colors** consistently
3. **Typography**: Embed CinaGEO fonts if possible
4. **Layout**: Follow asymmetric grid principles

## Accessibility Standards

- **Body text contrast**: Minimum 4.5:1 (WCAG AA)
- **Large text (24px+)**: Minimum 3:1 (WCAG AA)
- **UI components**: Minimum 3:1
- **Focus states**: 2px solid petrol outline, 2px offset
- **Touch targets**: Minimum 44px × 44px on mobile
- **Semantic HTML**: Use proper heading hierarchy, ARIA labels

### Current Contrast Ratios

| Combination | Ratio | Pass |
|-------------|-------|------|
| Ink on Paper | 14.5:1 | AAA ✓ |
| Graphite on Paper | 6.5:1 | AA ✓ |
| Petrol on Paper | 10.2:1 | AAA ✓ |
| Vermilion on Paper | 5.8:1 | AA ✓ |

## Responsive Breakpoints

```css
/* Mobile */
@media (max-width: 768px)

/* Tablet */
@media (max-width: 1024px)

/* Desktop */
@media (min-width: 1025px)
```

### Mobile-Specific Rules

1. Reduce font sizes - use `clamp()` with mobile-first ranges
2. Increase line height for better readability
3. Reduce section padding (7rem → 3rem)
4. Single column layout (collapse asymmetric grid)
5. Minimum 44px touch targets

## Design Token Reference

```css
/* Colors */
--paper: #faf9f6
--ink: #161616
--graphite: #4a4a4a
--petrol: #0e3b46
--vermilion: #c3471d
--border: #d4d3cf

/* Tints */
--tint-cool: #edf6f8
--tint-sage: #eef6ee
--tint-warm: #f7f0e6
--tint-lavender: #f2eef6
--tint-aqua: #edf6f6

/* Typography */
--font-sans: "CinaGEO", system-ui, sans-serif

/* Spacing */
--radius: 8px
```

## Quick Reference Patterns

### Hero Section
```
Background: Paper
Label: 12px uppercase, Ink
H1: 88px Bold, -0.045em, Ink
Body: 20px Medium, Graphite
CTA: 12px uppercase, Petrol border
Layout: Asymmetric grid
```

### Section with Cards
```
Background: Tinted (cool/sage/warm)
Label: 12px uppercase in label gutter
H2: 48px Bold, -0.03em
Cards: 8px radius, 1px border, 2rem padding
Grid: Auto-fit, minmax(280px, 1fr)
```

### Content Section
```
Background: Paper or tinted
Label: Left gutter
H2/H3: Content main (max 740px)
Body: 17px, 1.6 line-height, Graphite
Metadata: Right gutter (marginalia)
```

## Workflow

1. **Choose document type**: Determine if creating HTML, PPTX, DOCX, or PDF
2. **Read relevant skill**: Load the appropriate skill documentation (pptx/docx/pdf) if needed
3. **Apply color system**: Use only Paper, Ink, Graphite, Petrol, Vermilion (+ tints)
4. **Set typography**: CinaGEO Bold for headings, Medium for body, proper scale
5. **Use asymmetric layout**: Label gutter, content main, marginalia gutter
6. **Check examples**: Reference `assets/examples/` for implementation patterns
7. **Embed fonts**: Use fonts from `assets/fonts/` when creating documents
8. **Verify accessibility**: Check contrast ratios and focus states
9. **Test responsive**: Ensure mobile breakpoints work properly

## Common Mistakes to Avoid

❌ Using more than 5 colors in a composition
❌ Using font weights lighter than Medium (500) for body text
❌ Forgetting negative letter-spacing on large headings
❌ Using decorative gradients or effects
❌ Centered layouts instead of asymmetric
❌ Insufficient contrast ratios
❌ Forgetting to override text colors when changing backgrounds
❌ Using Vermilion heavily (it's an accent, use sparingly)
❌ Missing uppercase on labels (always 12px uppercase, 0.12em spacing)
❌ Tight spacing (use generous whitespace)

## Quality Checklist

Before finalizing any branded material:

- [ ] Colors limited to 5 (Paper, Ink, Graphite, Petrol, Vermilion + tints)
- [ ] CinaGEO fonts applied correctly (Bold for headings, Medium for body)
- [ ] Typography scale followed (H1: 88px, H2: 48px, Body: 17px, etc.)
- [ ] Negative letter-spacing on headings (-0.045em on H1, -0.03em on H2)
- [ ] Asymmetric layout used (140px label gutter, 740px content, 200px marginalia)
- [ ] Generous whitespace (7rem section padding desktop, 3rem mobile)
- [ ] Labels are uppercase, 12px, 0.12em letter-spacing
- [ ] Petrol used for primary actions, Vermilion used sparingly
- [ ] Contrast ratios meet WCAG AA standards (4.5:1 minimum for body text)
- [ ] Border radius is 8px for cards and containers
- [ ] Hover states include subtle animations (200-300ms cubic-bezier)
- [ ] Mobile responsive with appropriate breakpoints
- [ ] Examples consulted from `assets/examples/`

---

**For questions or detailed specifications, consult the original brand style guide in `/mnt/user-data/uploads/BRAND_STYLE_GUIDE.md`**
