---
name: brand
description: "Brand voice, visual identity, messaging frameworks, asset management, brand consistency. Activate for branded content, tone of voice, marketing assets, brand compliance, style guides."
argument-hint: "[update|review|create] [args]"
---

# Brand

Brand identity, voice, messaging, asset management, and consistency
frameworks.

## When to Use

- Brand voice definition and content tone guidance
- Visual identity standards and style guide development
- Messaging framework creation
- Brand consistency review and audit
- Asset organization, naming, and approval
- Color palette management and typography specs

## Script Paths

Scripts in this skill are located in the original skill folder at
`.claude/skills/brand/scripts/`. They read and write project files
(e.g. `docs/brand-guidelines.md`, `assets/design-tokens.json`) relative
to the project root. Keep your working directory at the project root when
running them.

## Quick Start

**Inject brand context into prompts:**
```bash
node .claude/skills/brand/scripts/inject-brand-context.cjs
node .claude/skills/brand/scripts/inject-brand-context.cjs --json
```

**Validate an asset:**
```bash
node .claude/skills/brand/scripts/validate-asset.cjs <asset-path>
```

**Extract/compare colors:**
```bash
node .claude/skills/brand/scripts/extract-colors.cjs --palette
node .claude/skills/brand/scripts/extract-colors.cjs <image-path>
```

## Brand Sync Workflow

```bash
# 1. Edit docs/brand-guidelines.md (or invoke this skill with "update")
# 2. Sync to design tokens
node .claude/skills/brand/scripts/sync-brand-to-tokens.cjs
# 3. Verify
node .claude/skills/brand/scripts/inject-brand-context.cjs --json | head -20
```

The sync stops when it detects existing token files, `:root` custom
properties or Tailwind v4 `@theme` variables in common CSS entry points,
or Tailwind theme colors and presets. Review the reported source before
proceeding. If the detected files are the managed `assets/design-tokens.*`
outputs from an earlier sync and replacing them is intentional, re-run
with `--force`.

**Files synced:**
- `docs/brand-guidelines.md` ? Source of truth
- `assets/design-tokens.json` ? Token definitions
- `assets/design-tokens.css` ? CSS variables

## Subcommands

| Subcommand | Description | Reference |
|------------|-------------|-----------|
| `update` | Update brand identity and sync to all design systems | `.claude/skills/brand/references/update.md` |

## References

| Topic | File |
|-------|------|
| Voice Framework | `.claude/skills/brand/references/voice-framework.md` |
| Visual Identity | `.claude/skills/brand/references/visual-identity.md` |
| Messaging | `.claude/skills/brand/references/messaging-framework.md` |
| Consistency | `.claude/skills/brand/references/consistency-checklist.md` |
| Guidelines Template | `.claude/skills/brand/references/brand-guideline-template.md` |
| Asset Organization | `.claude/skills/brand/references/asset-organization.md` |
| Color Management | `.claude/skills/brand/references/color-palette-management.md` |
| Typography | `.claude/skills/brand/references/typography-specifications.md` |
| Logo Usage | `.claude/skills/brand/references/logo-usage-rules.md` |
| Approval Checklist | `.claude/skills/brand/references/approval-checklist.md` |

## Scripts

| Script | Purpose |
|--------|---------|
| `inject-brand-context.cjs` | Extract brand context for prompt injection |
| `sync-brand-to-tokens.cjs` | Sync brand-guidelines.md ? design-tokens.json/css |
| `validate-asset.cjs` | Validate asset naming, size, format |
| `extract-colors.cjs` | Extract and compare colors against palette |

## Templates

| Template | Purpose |
|----------|---------|
| `.claude/skills/brand/templates/brand-guidelines-starter.md` | Complete starter template for new brands |

## Routing

1. Parse subcommand from the argument passed to this skill (first word)
2. Load the corresponding `references/{subcommand}.md` from
   `.claude/skills/brand/references/`
3. Execute with remaining arguments
