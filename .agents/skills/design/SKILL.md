---
name: design
description: "Comprehensive design skill: brand identity, design tokens, UI styling, logo generation (55 styles, Gemini, Atlas Cloud, or MuAPI AI), corporate identity program (50 deliverables, CIP mockups), HTML presentations (Chart.js), banner design (22 styles, social/ads/web/print), icon design (15 styles, SVG), social photos (HTML to screenshot, multi-platform). Actions: design logo, create CIP, generate mockups, build slides, design banner, generate icon, create social photos, social media images, brand identity, design system. Platforms: Facebook, Twitter, LinkedIn, YouTube, Instagram, Pinterest, TikTok, Threads, Google Ads."
argument-hint: "[design-type] [context]"
---

# Design

Unified design skill: brand, tokens, UI, logo, CIP, slides, banners, social
photos, icons.

## When to Use

- Brand identity, voice, assets
- Design system tokens and specs
- UI styling with shadcn/ui + Tailwind
- Logo design and AI generation
- Corporate identity program (CIP) deliverables
- Presentations and pitch decks
- Banner design for social media, ads, web, print
- Social photos for Instagram, Facebook, LinkedIn, Twitter, Pinterest, TikTok

## Sub-skill Routing

| Task | Sub-skill | Details |
|------|-----------|---------| 
| Brand identity, voice, assets | `brand` | Bundled sibling skill |
| Tokens, specs, CSS vars | `design-system` | Bundled sibling skill |
| shadcn/ui, Tailwind, code | `ui-styling` | Bundled sibling skill |
| Logo creation, AI generation | Logo (built-in) | `.claude/skills/design/references/logo-design.md` |
| CIP mockups, deliverables | CIP (built-in) | `.claude/skills/design/references/cip-design.md` |
| Presentations, pitch decks | Slides (built-in) | `.claude/skills/design/references/slides.md` |
| Banners, covers, headers | Banner (built-in) | `.claude/skills/design/references/banner-sizes-and-styles.md` |
| Social media images/photos | Social Photos (built-in) | `.claude/skills/design/references/social-photos-design.md` |
| SVG icons, icon sets | Icon (built-in) | `.claude/skills/design/references/icon-design.md` |

## Script Paths

Scripts for this skill are in `.claude/skills/design/scripts/`. They read
and write project files relative to the project root. Keep your working
directory at the project root when running them.

> **Note (migrated from Claude Code):** The original skill used
> `${CLAUDE_PLUGIN_ROOT}` to locate scripts. In Antigravity, use the
> explicit project-relative path `.claude/skills/design/scripts/` as
> shown in each example below.

## Logo Design (Built-in)

55+ styles, 30 color palettes, 25 industry guides. Gemini Nano Banana,
Atlas Cloud, and MuAPI image generation.

### Logo: Generate Design Brief

```bash
python .claude/skills/design/scripts/logo/search.py "tech startup modern" --design-brief -p "BrandName"
```

### Logo: Search Styles/Colors/Industries

```bash
python .claude/skills/design/scripts/logo/search.py "minimalist clean" --domain style
python .claude/skills/design/scripts/logo/search.py "tech professional" --domain color
python .claude/skills/design/scripts/logo/search.py "healthcare medical" --domain industry
```

### Logo: Generate with AI

**ALWAYS** generate output logo images with white background.

```bash
python .claude/skills/design/scripts/logo/generate.py --brand "TechFlow" --style minimalist --industry tech
python .claude/skills/design/scripts/logo/generate.py --prompt "coffee shop vintage badge" --style vintage
python .claude/skills/design/scripts/logo/generate.py --brand "TechFlow" --provider atlas
python .claude/skills/design/scripts/logo/generate.py --brand "TechFlow" --provider muapi
```

**IMPORTANT:** When scripts fail, try to fix them directly.

After generation, **ALWAYS** ask the user about an HTML preview. If yes,
use the bundled `ui-ux-pro-max` skill for the gallery.

## CIP Design (Built-in)

50+ deliverables, 20 styles, 20 industries.

### CIP: Generate Brief

```bash
python .claude/skills/design/scripts/cip/search.py "tech startup" --cip-brief -b "BrandName"
```

### CIP: Generate Mockups

```bash
# With logo (RECOMMENDED)
python .claude/skills/design/scripts/cip/generate.py --brand "TopGroup" --logo /path/to/logo.png --deliverable "business card" --industry "consulting"

# Full CIP set
python .claude/skills/design/scripts/cip/generate.py --brand "TopGroup" --logo /path/to/logo.png --industry "consulting" --set
```

Models: `flash` (default), `pro` (4K text)

### CIP: Render HTML Presentation

```bash
python .claude/skills/design/scripts/cip/render-html.py --brand "TopGroup" --industry "consulting" --images /path/to/cip-output
```

## Slides (Built-in)

Strategic HTML presentations with Chart.js, design tokens, copywriting
formulas.

Load `.claude/skills/design/references/slides-create.md` for the creation
workflow.

## Banner Design (Built-in)

22 art direction styles across social, ads, web, print.

Load `.claude/skills/design/references/banner-sizes-and-styles.md` for
complete sizes and styles reference.

### Banner: Workflow

1. **Gather requirements** — purpose, platform, content, brand, style, quantity
2. **Research** — read banner reference; use `ui-ux-pro-max` for style/palette guidance
3. **Design** — create HTML/CSS banner at exact platform dimensions
4. **Export** — capture PNG at exact dimensions; if unavailable, deliver HTML/CSS source
5. **Present** — show all options side-by-side, iterate on feedback

## Icon Design (Built-in)

15 styles, 12 categories. SVG text output via Gemini 3.1 Pro Preview.

### Icon: Generate

```bash
python .claude/skills/design/scripts/icon/generate.py --prompt "settings gear" --style outlined
python .claude/skills/design/scripts/icon/generate.py --name "dashboard" --category navigation --style duotone
python .claude/skills/design/scripts/icon/generate.py --prompt "cloud upload" --batch 4 --output-dir ./icons
```

## Social Photos (Built-in)

Multi-platform social image design: HTML/CSS ? screenshot export.

Load `.claude/skills/design/references/social-photos-design.md` for sizes,
templates, best practices.

### Social Photos: Key Sizes

| Platform | Size (px) | Platform | Size (px) |
|----------|-----------|----------|-----------| 
| IG Post | 1080×1080 | FB Post | 1200×630 |
| IG Story | 1080×1920 | X Post | 1200×675 |
| IG Carousel | 1080×1350 | LinkedIn | 1200×627 |
| YT Thumb | 1280×720 | Pinterest | 1000×1500 |

## Prerequisites

**Python:** On Windows, use `python` instead of `python3`.

```bash
python --version
```

## Setup

```bash
export GEMINI_API_KEY="your-key"  # https://aistudio.google.com/apikey
pip install google-genai pillow

# Optional MuAPI provider
export MUAPI_API_KEY="your-key"
```

**Note for Windows:** Use `python -m pip install ...` instead of `pip`.

## Integration

**Bundled sub-skills:** brand, design-system, ui-styling
**Related skills:** ui-ux-pro-max
