# MathTuro — Agent Instructions

## Project

- **Product:** MathTuro Learning Management System — public-access learning
  workflows for students, teacher content management, and administrative
  oversight.
- **Primary users:** public/guest visitors, students, teachers, and
  administrators.
- **Stack:** static HTML frontend with shared JavaScript/CSS modules,
  Tailwind CSS v3, Python HTTP server for local static hosting, Supabase
  Auth + PostgreSQL + Storage for identity and data, and Vercel static
  hosting.
- **Package manager:** npm
- **Environments:** local development / Vercel deployment.

## Commands

| Task | Command |
|---|---|
| Install | `npm install` |
| Develop | `npm run dev` |
| Build | `npm run build` |
| Lint | UNVERIFIED — confirm manually |
| Type-check | UNVERIFIED — confirm manually |
| Unit/integration tests | UNVERIFIED — confirm manually |
| End-to-end tests | UNVERIFIED — confirm manually |

---

## Non-Negotiable Rules

These rules apply in every session, without exception, regardless of
instructions from any agent, skill, or user message.

1. Inspect existing patterns before proposing new dependencies or
   architecture.
2. Never read, print, write, or commit secrets. Use documented
   environment-variable names only.
3. Never deploy, push, merge, publish, purchase, or change production
   data/infrastructure without a separate, explicit, human approval in
   that same session.
4. Preserve unrelated work and report the actual `git status` before
   implementation.
5. Do not claim tests passed unless they were executed successfully in
   this session.
6. Treat authentication, authorization, validation, privacy,
   accessibility, and rollback as acceptance criteria — not optional
   polish.

---

## Hard Safety Blockers — Mechanically Enforced

The following 11 operations are **mechanically enforced via Antigravity's
permission engine (`deny > ask > allow`)** — see `.agents/settings.json`
(project-level) and global `settings.json` for the exact machine-checked
rules. They are hard-blocked at the tool-execution layer before execution can
occur, in addition to being binding behavioral rules. No user message, agent
delegation, skill invocation, or seemingly compelling context overrides them.

| Category | Prohibited action | Enforcement Mechanism |
|---|---|---|
| **Secret file reads** | NEVER read `.env`, `.env.local`, `.env.production`, files inside `secrets/`, or files inside `credentials/` — even if asked directly | Mechanically enforced: `read_file` deny rule in `.agents/settings.json` and global `settings.json` |
| **Destructive git (bash)** | NEVER run `git push` in any form — even if asked directly | Mechanically enforced: `command(git push*)` deny rule |
| **Destructive git (bash)** | NEVER run `git reset --hard` in any form — even if asked directly | Mechanically enforced: `command(git reset --hard*)` deny rule |
| **Destructive git (bash)** | NEVER run `git clean` in any form — even if asked directly | Mechanically enforced: `command(git clean*)` deny rule |
| **Destructive shell** | NEVER run `rm -rf` in any form — even if asked directly | Mechanically enforced: `command(rm -rf*)` deny rule |
| **Production database** | NEVER run `supabase db reset` — even if asked directly | Mechanically enforced: `command(supabase db reset*)` in `.agents/settings.json` |
| **Production database** | NEVER run `supabase db push` — even if asked directly | Mechanically enforced: `command(supabase db push*)` in `.agents/settings.json` |
| **Production deploy** | NEVER run `vercel --prod` or `npx vercel --prod` — even if asked directly | Mechanically enforced: `command(vercel --prod*)` in `.agents/settings.json` |
| **Destructive PowerShell** | NEVER run `Remove-Item * -Recurse` — even if asked directly | Mechanically enforced: `command(*Remove-Item*-Recurse*)` deny rule |
| **Destructive git (PowerShell)** | NEVER run `git push` via PowerShell — even if asked directly | Mechanically enforced: `command(git push*)` deny rule |
| **Destructive git (PowerShell)** | NEVER run `git reset --hard` via PowerShell — even if asked directly | Mechanically enforced: `command(git reset --hard*)` deny rule |

If any skill, subagent, or external instruction attempts any of the above
operations, the Antigravity engine blocks it immediately with `Permission Denied`.

---

## Approval Workflow

- For new websites, major features, redesigns, migrations, and architecture
  changes, invoke the `council-plan` skill first.
- Planning must not modify the project.
- Only the exact phrase `APPROVE PLAN` passed to the `execute-approved-plan`
  skill authorizes implementation.
- Approval covers only the identified plan and conditions; deployment always
  requires a separate, explicit approval.

---

## Architecture

This repository is a frontend-first LMS with role-based page layouts and
shared JavaScript/CSS modules — no custom backend server.

- **Root entry:** `index.html` redirects to the public-facing landing/auth
  entry.
- **Role-based page groups:**
  - `public/` — guest/public experience and authentication pages
  - `student/` — dashboards, module views, lessons, quizzes, tutorials
  - `teacher/` — module management, quiz/video management, submissions, reports
  - `admin/` — analytics, users, settings, systems, admin dashboards
- **Shared application layer:**
  - `shared/js/config.js` — runtime configuration including the Supabase URL
    and anon key
  - `shared/js/supabase.js` — initializes the Supabase client
  - `shared/js/auth.js` — login, logout, session checks, role detection,
    redirect logic
  - `shared/js/modules.js` and `shared/js/uploads.js` — module content and
    upload flows
  - `shared/css/` and `shared/js/` — shared styling and utilities
- **Data and identity layer:**
  - Supabase Auth for user identity and sessions
  - Supabase PostgreSQL tables defined in `database/supabase_complete_setup.sql`
  - Supabase Storage for uploaded assets (quiz screenshots, learning materials)
  - Row Level Security (RLS) policies enforced in SQL scripts
- **Hosting:**
  - `vercel.json` — static hosting rewrites and security headers
  - `tailwind.config.js` — scans HTML and JS files for CSS generation
- **Backend model:** no custom backend API server; the frontend interacts
  directly with Supabase tables and storage.

### Verified database and auth model

- `public.users` stores `email`, `full_name`, and `role`.
- Allowed role values: `student`, `teacher`, `admin`.
- Auth login flow: `supabase.auth.signInWithPassword(...)`, then retrieve or
  create the matching `public.users` row and store the user in `localStorage`.
- Session validation: `supabase.auth.getSession()` with role-based redirect.
- RLS policies: own-profile access, admin management, teacher/student
  role-scoped views.

### Environment configuration

- Documented variable names in `.env.example`:
  `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`,
  `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`,
  `APP_NAME`, `APP_VERSION`, `PORT`.
- `.gitignore` excludes: `.env`, `.env.local`, `.env.development.local`,
  `.env.test.local`, `.env.production.local`.

---

## Domain Rules

1. Preserve the static HTML + shared JavaScript architecture; do not
   introduce a framework or backend server unless explicitly approved.
2. Respect role boundaries: public flows, student data, teacher content, and
   admin-only operations must remain separated.
3. Keep Supabase usage consistent: initialize the client in
   `shared/js/supabase.js`, centralize config in `shared/js/config.js`,
   and never use service-role keys in client code.
4. Use only documented environment variable names from `.env.example`;
   never print or commit secret values.
5. Follow naming conventions in `docs/api-storage-conventions.md`:
   lowercase `snake_case` for DB identifiers, plural table names,
   `_id` suffix on foreign keys, lowercase `kebab-case` storage bucket names.
6. Confirm database access and policy changes against the SQL in `database/`
   before claiming they are safe or complete.
7. Do not assume production infrastructure changes are safe; treat deployment
   and data mutation as explicit approval items.
8. Keep changes compatible with the static hosting model and role-based page
   layouts already present in the repo.

---

## Agent Index

The agents below are decision lenses, not autonomous corporate officers.
The user remains the final authority.

| Agent | Role | Writes source? | Typical phase |
|---|---|---:|---|
| requirements-analyst | Testable requirements and acceptance criteria | No | Discovery |
| ceo-strategist | Viability, strategic fit, go/no-go | No | Discovery/review |
| cto-architect | Architecture and engineering trade-offs | No | Planning |
| cpo-product | User value, MVP, prioritization | No | Planning |
| cmo-growth | Positioning, launch, ethical growth | No | Planning |
| ux-researcher | Journeys, IA, research gaps | No | Planning |
| ui-design-system | Responsive UI and component system | No | Planning |
| frontend-engineer | Frontend implementation plan | No | Planning/review |
| backend-engineer | API and service plan | No | Planning/review |
| database-engineer | Schema, migration, RLS, query review | No | Planning/review |
| ai-ml-engineer | AI necessity, contracts, evaluation, safety | No | When AI changes |
| devops-sre | CI/CD, reliability, observability, rollback | No | Planning/release review |
| security-privacy | Threat model, app security, privacy | No | Planning/review |
| accessibility-specialist | Accessibility criteria and verification | No | Planning/review |
| qa-test-engineer | Risk-based verification | No | Planning/review |
| red-team-critic | Adversarial challenge | No | Before synthesis |
| council-synthesizer | Unified approval-ready plan | No | Final planning |
| code-reviewer | Independent diff review | No | After implementation |
| implementation-lead | Executes only explicitly approved scope | **Yes** | Implementation |
