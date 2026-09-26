---
name: ui-ux-pro-max
description: "UI/UX design intelligence for web, mobile, and desktop. This skill should be used when designing, building, reviewing, or fixing interfaces, including pages, components, design systems, accessibility, interaction, responsive layout, typography, color, charts, and stack-specific UI implementation. Searchable local data: 79 searchable styles (50 active), 192 product palettes and reasoning profiles, 74 font pairings, 119 UX guidelines, 105 icons, 17 GSAP presets, 25 chart types, and 22 stacks."
---

# UI/UX Pro Max - Design Intelligence

Searchable local UI/UX guidance: 79 searchable styles (50 active), 192
product palettes and exact reasoning profiles, 74 font pairings, 119 UX
guidelines, 105 curated icons, 17 GSAP presets, 25 chart types, and 22
technology stacks.

## When to Apply

Use this skill when the task involves **UI structure, visual design
decisions, interaction patterns, or user experience quality control**:
designing new pages, creating/refactoring UI components, choosing
color/typography/spacing/layout systems, reviewing UI for
UX/accessibility/consistency, implementing navigation/animation/responsive
behavior, or improving perceived quality and usability.

Skip it for pure backend logic, API/database design, non-visual performance
work, infrastructure/DevOps, or non-visual scripts — unless the task changes
how something **looks, feels, moves, or is interacted with**.

## Rule Categories by Priority

| Priority | Category | Impact | Key Checks (Must Have) | Anti-Patterns (Avoid) |
|----------|----------|--------|------------------------|------------------------|
| 1 | Accessibility | CRITICAL | Contrast 4.5:1, Alt text, Keyboard nav, Aria-labels | Removing focus rings, Icon-only buttons without labels |
| 2 | Touch & Interaction | CRITICAL | Min size 44×44px, 8px+ spacing, Loading feedback | Reliance on hover only, Instant state changes (0ms) |
| 3 | Performance | HIGH | WebP/AVIF, Lazy loading, Reserve space (CLS < 0.1) | Layout thrashing, Cumulative Layout Shift |
| 4 | Style Selection | HIGH | Match product type, Consistency, SVG icons (no emoji) | Mixing flat & skeuomorphic randomly, Emoji as icons |
| 5 | Layout & Responsive | HIGH | Mobile-first breakpoints, Viewport meta, No horizontal scroll | Horizontal scroll, Fixed px container widths, Disable zoom |
| 6 | Typography & Color | MEDIUM | Base 16px, Line-height 1.5, Semantic color tokens | Text < 12px body, Gray-on-gray, Raw hex in components |
| 7 | Animation | MEDIUM | Context-aware timing, Motion conveys meaning, Spatial continuity | One duration for every transition, Animating width/height, No reduced-motion |
| 8 | Forms & Feedback | MEDIUM | Visible labels, Error near field, Helper text, Progressive disclosure | Placeholder-only label, Errors only at top |
| 9 | Navigation Patterns | HIGH | Predictable back, Bottom nav =5, Deep linking | Overloaded nav, Broken back behavior |
| 10 | Charts & Data | LOW | Legends, Tooltips, Accessible colors | Relying on color alone to convey meaning |

For the full rule list (119 UX guidelines with rationale), read:
`.claude/skills/ui-ux-pro-max/references/quick-reference.md`

For app-specific polish rules and the canonical pre-delivery checklist, read:
`.claude/skills/ui-ux-pro-max/references/pro-rules.md`

---

## Running the Search Tool

The search script is located in this skill's own scripts directory. Run it
from the project root, pointing explicitly to the script path:

```bash
python .claude/skills/ui-ux-pro-max/scripts/search.py "<query>" --domain <domain>
```

If `python` is not found, try `python3`, then `py -3`. Requires Python 3.x,
no external dependencies.

> **Note (migrated from Claude Code):** The original skill used the runtime
> variable `${CLAUDE_PLUGIN_ROOT}` to locate the script. In Antigravity,
> use the explicit project-relative path `.claude/skills/ui-ux-pro-max/scripts/search.py`
> as shown above.

## Workflow

### Query Contract

Choose the smallest search mode that fits the request:

1. **New project/page or system-wide visual direction** ? use `--design-system`
2. **Targeted concern or component bug** ? use one explicit `--domain`
3. **Known implementation stack** ? use `--stack`; add a separate domain
   search only for a distinct design concern

Build each query around **one dominant intent**, using **2–5 meaningful
terms** and one useful constraint such as product, platform, or interaction.
Verify the returned domain/category, top result identity, and fit for the
user's product and platform before applying it. **Retry once** with a
narrower rewrite or explicit domain/stack when output is empty or off-topic.
If that retry fails, state that no verified match was found and label any
general guidance as a fallback. **Do not persist unverified output.**

### Step 1: Analyze User Requirements

Extract:
- **Product type**: SaaS, e-commerce, portfolio, dashboard, entertainment, tool
- **Target audience & context**: age group, usage context
- **Style keywords**: playful, vibrant, minimal, dark mode, content-first
- **Stack**: detect from `package.json` deps. **Never assume a stack.**

### Step 2: Generate Design System (REQUIRED for new pages/projects)

```bash
python .claude/skills/ui-ux-pro-max/scripts/search.py "<product_type> <industry> <keywords>" --design-system [-p "Project Name"]
```

**Example:**
```bash
python .claude/skills/ui-ux-pro-max/scripts/search.py "beauty spa wellness service" --design-system -p "Serenity Spa"
```

### Step 2b: Persist Design System (Master + Overrides Pattern)

```bash
python .claude/skills/ui-ux-pro-max/scripts/search.py "<query>" --design-system --persist -p "Project Name" --output-dir "<project-root>"
```

This creates:
- `design-system/<project-slug>/MASTER.md` — Global Source of Truth
- `design-system/<project-slug>/pages/` — Folder for page-specific overrides

Read an existing `MASTER.md` before deciding whether `--force` is justified.
**Never use `--force` without explicit user authorization.**

### Step 2c: Design Dials (optional)

```bash
python .claude/skills/ui-ux-pro-max/scripts/search.py "<query>" --design-system --variance <1-10> --motion <1-10> --density <1-10>
```

| Dial | Low (1-3) | Mid (4-7) | High (8-10) |
|------|-----------|-----------|-------------|
| `--variance` | Centered / minimal | Balanced / modern | Bold / asymmetric |
| `--motion` | Subtle micro-interactions | Standard scroll/stagger | Complex choreography |
| `--density` | Spacious (24-96px) | Standard (16-64px) | Dense/dashboard (8-32px) |

### Step 3: Supplement with Detailed Searches

```bash
python .claude/skills/ui-ux-pro-max/scripts/search.py "<keyword>" --domain <domain> [-n <max_results>]
```

| Need | Domain | Example |
|------|--------|---------|
| Product type patterns | `product` | `"entertainment social" --domain product` |
| More style options | `style` | `"glassmorphism dark" --domain style` |
| Color palettes | `color` | `"entertainment vibrant" --domain color` |
| Font pairings | `typography` | `"playful modern" --domain typography` |
| Individual Google Fonts | `google-fonts` | `"sans serif popular variable" --domain google-fonts` |
| Chart recommendations | `chart` | `"real-time dashboard" --domain chart` |
| UX best practices | `ux` | `"error summary validation" --domain ux` |
| Landing page structure | `landing` | `"hero social-proof" --domain landing` |
| Icon recommendations | `icons` | `"decorative icon aria hidden" --domain icons` |
| GSAP animation presets | `gsap` | `"scroll reveal stagger" --domain gsap` |

### Step 4: Stack Guidelines

```bash
python .claude/skills/ui-ux-pro-max/scripts/search.py "<keyword>" --stack <stack>
```

**Available stacks:** `react`, `nextjs`, `vue`, `svelte`, `astro`, `nuxtjs`,
`nuxt-ui`, `angular`, `laravel`, `swiftui`, `react-native`, `flutter`,
`jetpack-compose`, `html-tailwind`, `shadcn`, `threejs`, `javafx`, `wpf`,
`winui`, `avalonia`, `uno`, `uwp`.

---

## If a search returns 0 results

Do not fabricate output. Instead:
1. Retry once with a narrower query or an explicit domain/stack.
2. If still empty, fall back to the priority table above and explicitly say
   this recommendation came from built-in defaults, not a database match.
3. Never present a 0-result search as if it returned data.

## Output Formats

`--design-system` supports:
- `-f ascii` (default, terminal display)
- `-f markdown` (documentation)
- `--json` (machine-readable)

## Before Delivering App UI

Read `.claude/skills/ui-ux-pro-max/references/pro-rules.md` and run through
its canonical Pre-Delivery Checklist. It covers icon/visual-element
discipline, interaction feedback, light/dark contrast, safe-area layout, and
accessibility — scoped to native/mobile app UI.
