---
name: ui-styling
description: "Create beautiful, accessible user interfaces with shadcn/ui components (built on Radix UI + Tailwind), Tailwind CSS utility-first styling, and canvas-based visual designs. Use when building user interfaces, implementing design systems, creating responsive layouts, adding accessible components (dialogs, dropdowns, forms, tables), customizing themes and colors, implementing dark mode, generating visual designs and posters, or establishing consistent styling patterns across applications."
argument-hint: "[component or layout]"
---

# UI Styling Skill

Comprehensive skill for creating beautiful, accessible user interfaces
combining shadcn/ui components, Tailwind CSS utility styling, and
canvas-based visual design systems.

## Reference

- shadcn/ui: https://ui.shadcn.com/llms.txt
- Tailwind CSS: https://tailwindcss.com/docs

## When to Use This Skill

Use when:
- Building UI with React-based frameworks (Next.js, Vite, Remix, Astro)
- Implementing accessible components (dialogs, forms, tables, navigation)
- Styling with utility-first CSS approach
- Creating responsive, mobile-first layouts
- Implementing dark mode and theme customization
- Building design systems with consistent tokens
- Generating visual designs, posters, or brand materials
- Rapid prototyping with immediate visual feedback
- Adding complex UI patterns (data tables, charts, command palettes)

## Core Stack

### Component Layer: shadcn/ui
- Pre-built accessible components via Radix UI primitives
- Copy-paste distribution model (components live in your codebase)
- TypeScript-first with full type safety
- Composable primitives for complex UIs
- CLI-based installation and management

### Styling Layer: Tailwind CSS
- Utility-first CSS framework
- Build-time processing with zero runtime overhead
- Mobile-first responsive design
- Consistent design tokens (colors, spacing, typography)
- Automatic dead code elimination

### Visual Design Layer: Canvas
- Museum-quality visual compositions
- Philosophy-driven design approach
- Sophisticated visual communication
- Minimal text, maximum visual impact
- Systematic patterns and refined aesthetics

## Script Paths

Scripts for this skill are in `.claude/skills/ui-styling/scripts/`. They
read and write project files relative to the project root.

## Quick Start

### Component + Styling Setup

**Install shadcn/ui with Tailwind:**
```bash
npx shadcn@latest init
```

**Add components:**
```bash
npx shadcn@latest add button card dialog form
```

**Use components with utility styling:**
```tsx
import { Button } from "@/components/ui/button"
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card"

export function Dashboard() {
  return (
    <div className="container mx-auto p-6 grid gap-6 md:grid-cols-2 lg:grid-cols-3">
      <Card className="hover:shadow-lg transition-shadow">
        <CardHeader>
          <CardTitle className="text-2xl font-bold">Analytics</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-muted-foreground">View your metrics</p>
          <Button variant="default" className="w-full">
            View Details
          </Button>
        </CardContent>
      </Card>
    </div>
  )
}
```

### Alternative: Tailwind-Only Setup

**Vite projects:**
```bash
npm install -D tailwindcss @tailwindcss/vite
```

```javascript
// vite.config.ts
import tailwindcss from "@tailwindcss/vite"
export default { plugins: [tailwindcss()] }
```

```css
/* src/index.css */
@import "tailwindcss";
```

## Component Library Guide

See: `.claude/skills/ui-styling/references/shadcn-components.md`

Covers form/input components, layout/navigation, overlays/dialogs,
feedback/status, and display components.

## Theme & Customization

See: `.claude/skills/ui-styling/references/shadcn-theming.md`

Covers dark mode, CSS variable system, color customization, component
variant customization, theme toggle implementation.

## Accessibility Patterns

See: `.claude/skills/ui-styling/references/shadcn-accessibility.md`

Covers ARIA patterns, keyboard navigation, screen reader support,
focus management, form validation accessibility.

## Tailwind Utilities

See: `.claude/skills/ui-styling/references/tailwind-utilities.md`

## Responsive Design

See: `.claude/skills/ui-styling/references/tailwind-responsive.md`

## Tailwind Customization

See: `.claude/skills/ui-styling/references/tailwind-customization.md`

## Visual Design System

See: `.claude/skills/ui-styling/references/canvas-design-system.md`

## Utility Scripts

### shadcn_add.py
```bash
python .claude/skills/ui-styling/scripts/shadcn_add.py button card dialog
```

### tailwind_config_gen.py
```bash
python .claude/skills/ui-styling/scripts/tailwind_config_gen.py --colors brand:blue --fonts display:Inter
```

The generator refuses to create or replace a config when any sibling
`tailwind.config.js`, `.cjs`, `.mjs`, or `.ts` already exists. Pass
`--force` only when intentional:
```bash
python .claude/skills/ui-styling/scripts/tailwind_config_gen.py --colors brand:blue --force
```

**Note for Windows:** Use `python` instead of `python3`.

## Best Practices

1. **Component Composition**: Build complex UIs from simple, composable primitives
2. **Utility-First Styling**: Use Tailwind classes directly; extract components only for true repetition
3. **Mobile-First Responsive**: Start with mobile styles, layer responsive variants
4. **Accessibility-First**: Leverage Radix UI primitives, add focus states, use semantic HTML
5. **Design Tokens**: Use consistent spacing scale, color palettes, typography system
6. **Dark Mode Consistency**: Apply dark variants to all themed elements
7. **Performance**: Leverage automatic CSS purging, avoid dynamic class names
8. **TypeScript**: Use full type safety for better DX
9. **Visual Hierarchy**: Let composition guide attention, use spacing and color intentionally
10. **Expert Craftsmanship**: Every detail matters — treat UI as a craft

## Resources

- shadcn/ui Docs: https://ui.shadcn.com
- Tailwind CSS Docs: https://tailwindcss.com
- Radix UI: https://radix-ui.com
- Tailwind UI: https://tailwindui.com
- Headless UI: https://headlessui.com
- v0 (AI UI Generator): https://v0.dev
