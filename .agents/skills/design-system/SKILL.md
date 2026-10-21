---
name: design-system
description: "Token architecture, component specifications, and slide generation. Three-layer tokens (primitive?semantic?component), CSS variables, spacing/typography scales, component specs, strategic slide creation. Use for design tokens, systematic design, brand-compliant presentations."
argument-hint: "[component or token]"
---

# Design System

Token architecture, component specifications, systematic design, slide
generation.

## When to Use

- Design token creation
- Component state definitions
- CSS variable systems
- Spacing/typography scales
- Design-to-code handoff
- Tailwind theme configuration
- Slide/presentation generation

## Token Architecture

Load: `.claude/skills/design-system/references/token-architecture.md`

### Three-Layer Structure

```
Primitive (raw values)
       ?
Semantic (purpose aliases)
       ?
Component (component-specific)
```

**Example:**
```css
/* Primitive */
--color-blue-600: #2563EB;

/* Semantic */
--color-primary: var(--color-blue-600);

/* Component */
--button-bg: var(--color-primary);
```

## Script Paths

Scripts for this skill are in `.claude/skills/design-system/scripts/`.
They read and write project files relative to the project root. Keep your
working directory at the project root when running them.

## Quick Start

**Generate tokens:**
```bash
node .claude/skills/design-system/scripts/generate-tokens.cjs --config tokens.json -o tokens.css
```

**Validate usage:**
```bash
node .claude/skills/design-system/scripts/validate-tokens.cjs --dir src/
```

## References

| Topic | File |
|-------|------|
| Token Architecture | `.claude/skills/design-system/references/token-architecture.md` |
| Primitive Tokens | `.claude/skills/design-system/references/primitive-tokens.md` |
| Semantic Tokens | `.claude/skills/design-system/references/semantic-tokens.md` |
| Component Tokens | `.claude/skills/design-system/references/component-tokens.md` |
| Component Specs | `.claude/skills/design-system/references/component-specs.md` |
| States & Variants | `.claude/skills/design-system/references/states-and-variants.md` |
| Tailwind Integration | `.claude/skills/design-system/references/tailwind-integration.md` |

## Component Spec Pattern

| Property | Default | Hover | Active | Disabled |
|----------|---------|-------|--------|----------|
| Background | primary | primary-dark | primary-darker | muted |
| Text | white | white | white | muted-fg |
| Border | none | none | none | muted-border |
| Shadow | sm | md | none | none |

## Scripts

| Script | Purpose |
|--------|---------|
| `generate-tokens.cjs` | Generate CSS from JSON token config |
| `validate-tokens.cjs` | Check for hardcoded values in code |
| `search-slides.py` | BM25 search + contextual recommendations |
| `slide-token-validator.py` | Validate slide HTML for token compliance |
| `fetch-background.py` | Fetch images from Pexels/Unsplash |

## Integration

**With brand:** Extract primitives from brand colors/typography
**With ui-styling:** Component tokens ? Tailwind config

## Slide System

Brand-compliant presentations using design tokens + Chart.js + contextual
decision system.

### Source of Truth

| File | Purpose |
|------|---------|
| `docs/brand-guidelines.md` | Brand identity, voice, colors |
| `assets/design-tokens.json` | Token definitions (primitive?semantic?component) |
| `assets/design-tokens.css` | CSS variables (import in slides) |
| `assets/css/slide-animations.css` | CSS animation library |

### Slide Search (BM25)

```bash
# Basic search
python .claude/skills/design-system/scripts/search-slides.py "investor pitch"

# Domain-specific
python .claude/skills/design-system/scripts/search-slides.py "problem agitation" -d copy
python .claude/skills/design-system/scripts/search-slides.py "revenue growth" -d chart

# Contextual
python .claude/skills/design-system/scripts/search-slides.py "problem slide" --context --position 2 --total 9
```

**Note for Windows:** Use `python` instead of `python3`.

### Slide Requirements

**ALL slides MUST:**
1. Import `assets/design-tokens.css` — single source of truth
2. Use CSS variables: `var(--color-primary)`, `var(--slide-bg)`, etc.
3. Use Chart.js for charts (NOT CSS-only bars)
4. Include navigation (keyboard arrows, click, progress bar)
5. Center-align content
6. Focus on persuasion/conversion

### Chart.js Integration

```html
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>

<canvas id="revenueChart"></canvas>
<script>
new Chart(document.getElementById("revenueChart"), {
    type: "line",
    data: {
        labels: ["Sep", "Oct", "Nov", "Dec"],
        datasets: [{
            data: [5, 12, 28, 45],
            borderColor: "#FF6B6B",
            backgroundColor: "rgba(255, 107, 107, 0.1)",
            fill: true,
            tension: 0.4
        }]
    }
});
</script>
```

### Token Compliance

```css
/* CORRECT - uses token */
background: var(--slide-bg);
color: var(--color-primary);
font-family: var(--typography-font-heading);

/* WRONG - hardcoded */
background: #0D0D0D;
color: #FF6B6B;
font-family: "Space Grotesk";
```

## Best Practices

1. Never use raw hex in components — always reference tokens
2. Semantic layer enables theme switching (light/dark)
3. Component tokens enable per-component customization
4. Use HSL format for opacity control
5. Document every token's purpose
6. Slides must import design-tokens.css and use `var()` exclusively
