# MathTuro — Project Domain Rules

This file contains the detailed domain rules and architecture reference for
the MathTuro LMS. It is loaded on demand for tasks involving architecture
decisions, database work, naming conventions, or stack-specific constraints.
For the universal non-negotiables and safety blockers, see the root-level
`AGENTS.md`.

---

## Architecture Reference

MathTuro is a **frontend-first, role-based LMS** built on static HTML with
shared JavaScript/CSS modules. There is no custom backend API server — all
data and auth operations go directly through the Supabase client.

### Entry points and role groups

| Path | Audience |
|---|---|
| `index.html` | Redirects to public landing/auth entry |
| `public/` | Guest visitors — landing, auth pages |
| `student/` | Student dashboards, module views, lessons, quizzes, tutorials |
| `teacher/` | Module management, quiz/video management, submissions, reports |
| `admin/` | Analytics, users, settings, systems, admin dashboards |

### Shared application layer

| File | Purpose |
|---|---|
| `shared/js/config.js` | Centralizes runtime configuration; contains the hardcoded Supabase URL and anon key |
| `shared/js/supabase.js` | Initializes the Supabase client via `window.supabase.createClient` |
| `shared/js/auth.js` | Login, logout, session checks, role detection, redirect logic |
| `shared/js/modules.js` | Module and content management flows |
| `shared/js/uploads.js` | Upload flows for quiz screenshots and learning materials |
| `shared/css/` | Shared styling |

### Data and identity layer

| Layer | Technology | Notes |
|---|---|---|
| Auth | Supabase Auth | `supabase.auth.signInWithPassword(...)` ? create/retrieve `public.users` row ? store in `localStorage` |
| Database | Supabase PostgreSQL | Schema in `database/supabase_complete_setup.sql` and migration scripts |
| Storage | Supabase Storage | Uploaded assets: quiz screenshots, learning materials |
| RLS | PostgreSQL Row Level Security | Policies in SQL scripts; enforce per-role access |
| Session | `supabase.auth.getSession()` | Role-based redirect after session check |

### Verified schema

- `public.users` columns: `email`, `full_name`, `role`
- Allowed role values: `student`, `teacher`, `admin`
- RLS policy coverage: own-profile read, admin full management,
  teacher/student role-scoped views

### Hosting and build

| File | Purpose |
|---|---|
| `vercel.json` | Static hosting rewrites and security headers for Vercel |
| `tailwind.config.js` | Scans HTML and JS files for Tailwind CSS generation |

---

## Domain Rules (Detailed)

### 1 — Architecture preservation

**Preserve the static HTML + shared JavaScript architecture.** Do not
introduce a React/Vue/Svelte/Next.js framework, a Node/Express backend, or
any build step that changes the static-hosting model unless the user has
explicitly approved it via the council-plan ? execute-approved-plan workflow.

Rationale: the Vercel static config and role-based page layout depend on
HTML files being served directly. Adding a framework or SSR layer changes
the routing, build pipeline, and Vercel configuration.

### 2 — Role boundary enforcement

**Keep role boundaries strict at all times.** Public flows, student data,
teacher content, and admin-only operations must remain in their respective
page groups. Do not add cross-role data access without verifying RLS policy
coverage in the SQL in `database/`.

Indicators of a role-boundary violation:
- A student page that reads `teacher` or `admin` rows without an RLS policy
  explicitly permitting it
- Shared logic that combines role-specific queries without branching on
  `user.role`

### 3 — Supabase client usage

**Initialize the Supabase client only in `shared/js/supabase.js`.** Do not
create secondary client instances in page-level files. Centralize config
in `shared/js/config.js`.

**Never use the service-role key in client-side code.** The service-role key
bypasses RLS; if it appears in `shared/js/config.js` or any browser-loaded
file, it is a critical security defect.

### 4 — Environment variable discipline

- Use only documented variable names from `.env.example`
- Never print, log, or commit secret values
- When a new variable is needed, add it to `.env.example` with a placeholder
  value and document it before using it in code
- Current documented names: `SUPABASE_URL`, `SUPABASE_ANON_KEY`,
  `SUPABASE_SERVICE_ROLE_KEY`, `NEXT_PUBLIC_SUPABASE_URL`,
  `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `APP_NAME`, `APP_VERSION`, `PORT`

### 5 — Naming conventions

Source of truth: `docs/api-storage-conventions.md`

| Item | Convention | Example |
|---|---|---|
| Database table names | Lowercase `snake_case`, plural | `user_modules`, `quiz_submissions` |
| Foreign key columns | `_id` suffix | `module_id`, `teacher_id` |
| Storage bucket names | Lowercase `kebab-case` | `quiz-screenshots`, `learning-materials` |
| JavaScript files | Lowercase `kebab-case` | `shared/js/auth.js` |

### 6 — Database change safety

Before claiming a database or RLS change is safe:

1. Read the existing SQL in `database/` and any migration scripts
2. Confirm the new policy does not grant access beyond the intended role
3. Check that existing policies are not inadvertently overridden
4. Note whether a `ROLLBACK` path exists
5. Flag the change as requiring production approval

Do not run `supabase db push` or `supabase db reset` — these are
unconditionally prohibited (see `AGENTS.md` Hard Safety Blockers).

### 7 — Deployment and production safety

Treat every deployment, production database write, and infrastructure change
as an **explicit approval item**. The approval that covers an implementation
does not automatically cover deployment.

Before any deployment-adjacent recommendation, state:
- What will change in production
- Whether it is reversible
- What the rollback path is
- That explicit user approval is required before executing

### 8 — Compatibility with static hosting

Every change must remain compatible with:
- Vercel static file serving (no server-side rendering unless explicitly added)
- The existing `vercel.json` rewrite rules
- The role-based page layout (each role has its own directory)
- Tailwind CSS v3 generation from the existing `tailwind.config.js`

If a proposed change breaks any of these, flag it as a blocker before
proceeding.

---

## Approval Workflow (detailed)

### Planning phase (`council-plan`)

The `council-plan` skill runs an approval-first, multidisciplinary review.
It delegates to specialist agents in parallel, runs a red-team pass, and
produces a single synthesized plan. **It must not edit, write, install,
configure, deploy, commit, or push anything.**

End condition: `STATUS: AWAITING USER APPROVAL`

### Execution phase (`execute-approved-plan`)

The `execute-approved-plan` skill unlocks only when the user's invocation
contains the exact phrase `APPROVE PLAN` and unambiguously identifies the
complete approved plan.

What approval does NOT cover:
- Deployment or `git push`
- Merge or publish
- Purchases, credential changes, or production database operations
- Destructive commands or unrelated refactors

### Verification phase (`verify-delivery`)

After implementation, `verify-delivery` runs independent read-only review
with specialist agents. It reports `PASS`, `CONDITIONAL PASS`, or `FAIL` per
acceptance criterion.

A passing static review is not proof that runtime behavior works.
