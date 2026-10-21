---
name: web-engineering-standard
description: "Full-cycle engineering standard for building, reviewing, hardening, and launching ANY website or web application — regardless of framework, language, hosting, or project type (Next.js, React, Angular, Vue, Svelte, Laravel, PHP, Node/Express, Django, Flask, WordPress, static HTML, full-stack apps, PWAs, SaaS, dashboards, e-commerce, internal tools, school/CMS systems). Use this whenever starting a new website or web app, adding or modifying a feature, refactoring, adding auth/database/forms/integrations, preparing for deployment or launch, debugging production issues, or doing a security/performance/accessibility/SEO pass. Also trigger on requests like 'is this ready to ship,' 'review this before I deploy,' 'audit my site before launch,' 'make this production-ready,' or 'check this for security/accessibility/SEO issues' — even if the user does not say 'skill' or name a specific checklist. Always discover the actual project first; never assume the stack."
---

# Web Engineering Standard

A permanent engineering standard for building websites and web applications
— not a one-off audit script. Applies across the whole lifecycle:
**PLAN ? ARCHITECT ? BUILD ? REVIEW ? TEST ? HARDEN ? DEPLOY ? LAUNCH ?
MONITOR ? MAINTAIN**.

Think like a small team of senior engineers (full-stack, security, DevOps,
QA, accessibility, SEO, performance, UX, database) — catching problems early
and continuously, not just at the end. But do not over-engineer: a five-page
portfolio site does not need the same rigor as a multi-tenant SaaS app —
match the response to the project's actual size and risk.

## Step 0 — Always discover the project first, never assume it

Before recommending or changing anything, inspect the real project:
framework, language, package manager, routing/rendering strategy,
database/ORM, auth provider, hosting/CI setup, existing env vars, existing
tests/linting, and every third-party service actually wired in (analytics,
payments, email, maps, storage, monitoring, chat, ads).

Read `.claude/skills/web-engineering-standard/references/discovery.md`
for what to look for and how to find it in different stack types.

Treat what you find in the codebase as ground truth over what the user
*says* the stack is — codebases drift from memory.

If the project is brand new (empty repo / greenfield idea), skip to Phase 1
(Planning) in `references/planning-and-architecture.md`.

Never invent a fact about the project you could not find. If you cannot
determine something material, say so plainly and ask.

## Step 1 — Figure out the project stage and scope accordingly

| Stage | What triggered this turn | What to actually do |
|---|---|---|
| **New project** | Starting from scratch | Help with planning + architecture before writing code. See `references/planning-and-architecture.md`. |
| **Active development** | Adding or changing a feature | Review *that feature* against relevant phases. Do not re-audit the whole app. |
| **Refactor** | Restructuring existing code | Protect existing behavior first; watch for regressions. |
| **Pre-launch** | Preparing to ship / "is this ready" | Run the full Phase 17-18 launch audit. |
| **Post-launch** | Site is live; bug, update, or periodic review | Focus on regressions, dependency/security updates, monitoring signals. |

## Step 2 — Work the relevant phases

Only open reference files relevant to the current stage/task.

| Phases | Reference file | Covers |
|---|---|---|
| 1-3: Planning, Architecture, Dev Standards | `references/planning-and-architecture.md` | Project structure, scoping, code quality, type safety, config/secrets |
| 4-6: Security, Auth, Database | `references/security-and-data.md` | Secrets, injection/XSS/CSRF, auth flows, server-side authorization, schema/query safety |
| 7-9: Frontend UX, Accessibility, Responsive | `references/ux-accessibility-responsive.md` | Navigation/states/feedback, WCAG, mobile/tablet/desktop |
| 10-11: Performance, SEO | `references/performance-and-seo.md` | Bundle/image/font performance, titles/meta/OG/sitemap/robots |
| 12-14: Forms, Privacy, Third-Party | `references/forms-privacy-integrations.md` | Client+server validation, spam protection, data-collection audit |
| 15-16: Testing, QA | `references/testing-and-qa.md` | What to run vs. what to flag as unverified |
| 17-19: Pre-Deployment, Launch, Post-Launch | `references/deployment-launch-maintenance.md` | Full launch checklist and post-ship maintenance |

All reference files are in `.claude/skills/web-engineering-standard/references/`.

## Automation Principle — when to just fix it

Fix things directly, without asking, when ALL of these hold:
1. The problem is clearly understood (not a guess)
2. The fix is safe — cannot plausibly break something else
3. It does not require a business, legal, or branding decision
4. It does not require credentials you do not have
5. The intended behavior is obvious from context

Examples: dead internal links, missing alt text, obvious contrast failures,
a missing `.env.example`, an unlazy-loaded below-the-fold image.

## Human Decision Principle — when to stop and ask

Ask before proceeding when the decision touches:
- Business strategy, branding, or product requirements
- Legal content (privacy policy / terms)
- Credentials, domain ownership, or account creation
- Irreversible or costly architectural changes

When you ask, say what you need, why, what it affects, and what you can keep
doing without it.

## Never do this

Do not invent credentials, domains, business facts, or legal claims. Do not
claim a build, test, or deployment succeeded unless you actually ran and
observed it — clearly separate **Verified** from **Not verified / assumed**.
Do not silently add new dependencies, rewrite working architecture, or make
breaking changes without flagging them first. Do not expose secrets in your
output. Do not run the full 19-phase treatment on a one-line CSS tweak.

## Severity system

- ?? **BLOCKER** — should prevent release (exposed secret, broken auth,
  data-loss risk, site does not build)
- ?? **HIGH** — should normally be fixed before release (missing HTTPS
  enforcement, no server validation on a public form, major accessibility
  failure)
- ?? **MEDIUM** — real improvement, not urgent (missing alt text on a few
  images, suboptimal bundle size, thin meta descriptions)
- ?? **LOW** — polish (minor copy, small spacing/consistency nit)
- ?? **GOOD** — reviewed and fine as-is

## Reporting

For small/medium work, a short inline summary is enough.

For a genuine pre-launch or full-project audit, use the Production Readiness
Report format in `.claude/skills/web-engineering-standard/references/reporting-templates.md`.
It includes project/stack summary, current stage, overall status
(?? NOT READY / ?? NEEDS ATTENTION / ?? READY), a findings table, blockers,
remaining work, actions that need the human, and what was actually verified
vs. assumed.
