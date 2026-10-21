---
name: slides
description: "Create strategic HTML presentations with Chart.js, design tokens, responsive layouts, copywriting formulas, and contextual slide strategies."
argument-hint: "[topic] [slide-count]"
---

# Slides

Strategic HTML presentation design with data visualization.

## When to Use

- Marketing presentations and pitch decks
- Data-driven slides with Chart.js
- Strategic slide design with layout patterns
- Copywriting-optimized presentation content

## Subcommands

| Subcommand | Description | Reference |
|------------|-------------|-----------|
| `create` | Create strategic presentation slides | `.claude/skills/slides/references/create.md` |

## Script Paths

Scripts for this skill are located in `.claude/skills/slides/scripts/`.
They read and write project files relative to the project root. Keep your
working directory at the project root when running them.

## References (Knowledge Base)

| Topic | File |
|-------|------|
| Layout Patterns | `.claude/skills/slides/references/layout-patterns.md` |
| HTML Template | `.claude/skills/slides/references/html-template.md` |
| Copywriting Formulas | `.claude/skills/slides/references/copywriting-formulas.md` |
| Slide Strategies | `.claude/skills/slides/references/slide-strategies.md` |

## Routing

1. Parse the subcommand from the argument passed to this skill (first word)
2. Load the corresponding `references/{subcommand}.md` from
   `.claude/skills/slides/references/`
3. Execute with remaining arguments
