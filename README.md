# MathTuro Learning Management System

MathTuro is a role-based Learning Management System (LMS) built with static HTML pages, shared JavaScript modules, and Supabase for authentication, database, and storage.

It includes dedicated experiences for:
- Public/guest users
- Students
- Teachers
- Administrators

Primary documentation entrypoint: [docs/README.md](docs/README.md)

## Start Here

> New to this repository?
> Begin with [docs/README.md](docs/README.md) for role-based reading paths.

- Contributor onboarding: [docs/quickstart-contributors.md](docs/quickstart-contributors.md)
- Release readiness: [docs/production-readiness-checklist.md](docs/production-readiness-checklist.md)
- Change history: [CHANGELOG.md](CHANGELOG.md)

## Table of Contents

- [Start Here](#start-here)
- [What This Project Does](#what-this-project-does)
- [Current Feature Coverage](#current-feature-coverage)
- [Tech Stack](#tech-stack)
- [Repository Structure](#repository-structure)
- [Getting Started (Local)](#getting-started-local)
- [Supabase Setup](#supabase-setup)
- [Database Migrations and SQL Files](#database-migrations-and-sql-files)
- [Running and Testing](#running-and-testing)
- [Deployment](#deployment)
- [Security Notes](#security-notes)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [Docs Home](#docs-home)
- [Project Documentation Index](#project-documentation-index)
- [Next Documentation Enhancements](#next-documentation-enhancements)

## What This Project Does

MathTuro manages educational content and progress across multiple roles:

- Public pages for discovery, login, registration, and policies
- Student pages for modules, lessons, quizzes, and progress
- Teacher pages for module/content management and submissions review
- Admin pages for users, analytics, settings, and system visibility

The backend is provided by Supabase services and SQL migrations in the `database/` folder.

## Current Feature Coverage

### Student
- Browse modules and view lessons
- Access quizzes and track progress
- View dashboard and learning flow pages
- Related docs: [docs/access-control-matrix.md](docs/access-control-matrix.md), [docs/qa-test-matrix.md](docs/qa-test-matrix.md), [docs/data-model-reference.md](docs/data-model-reference.md)

### Teacher
- Manage modules, quizzes, videos, and lesson plans
- Review student submissions
- Access reporting and student-progress pages
- Related docs: [docs/access-control-matrix.md](docs/access-control-matrix.md), [docs/api-storage-conventions.md](docs/api-storage-conventions.md), [docs/qa-test-matrix.md](docs/qa-test-matrix.md)

### Admin
- Manage users and content visibility
- Access activity, analytics, and status pages
- Configure settings and grade/section related pages
- Related docs: [docs/access-control-matrix.md](docs/access-control-matrix.md), [docs/release-process.md](docs/release-process.md), [docs/incident-rollback-guide.md](docs/incident-rollback-guide.md)

### Public/Guest
- Landing, about, contact, legal pages
- Authentication pages (login/register/reset)
- Guest modules and tutorial/video related entry points
- Related docs: [docs/architecture-diagram.md](docs/architecture-diagram.md), [docs/qa-test-matrix.md](docs/qa-test-matrix.md), [docs/environment-strategy.md](docs/environment-strategy.md)

## Tech Stack

### Frontend
- HTML5
- CSS (Tailwind CSS usage in pages, plus shared and role-specific styles)
- Vanilla JavaScript

### Backend Services
- Supabase Auth
- Supabase PostgreSQL
- Supabase Storage
- Supabase Row Level Security (RLS)

### Tooling
- Node.js scripts via `package.json`
- Python simple HTTP server for local static hosting
- Vercel configuration via `vercel.json`

## Repository Structure

```text
.
|-- index.html
|-- package.json
|-- vercel.json
|-- README.md
|-- admin/
|   |-- dashboard.html
|   |-- users.html
|   |-- analytics.html
|   |-- settings.html
|   |-- ...
|   `-- assets/
|-- public/
|   |-- index.html
|   |-- login.html
|   |-- register.html
|   |-- modules.html
|   |-- ...
|-- student/
|   |-- dashboard.html
|   |-- modules.html
|   |-- module-view.html
|   |-- lesson-view.html
|   |-- quizzes.html
|   `-- assets/
|-- teacher/
|   |-- dashboard.html
|   |-- manage-modules.html
|   |-- manage-quizzes.html
|   |-- manage-videos.html
|   |-- submissions.html
|   |-- reports.html
|   |-- student-progress.html
|   `-- assets/
|-- shared/
|   |-- css/
|   |   `-- base.css
|   `-- js/
|       |-- config.js
|       |-- supabase.js
|       |-- auth.js
|       |-- modules.js
|       |-- uploads.js
|       `-- ...
|-- database/
|   |-- supabase_complete_setup.sql
|   |-- migration_v*.sql
|   |-- fix_*.sql
|   `-- ...
|-- Logo/
`-- Researchers/
```

## Getting Started (Local)

### 1. Prerequisites

Install:
- Node.js 18+ (recommended)
- Python 3 (for the local static server script)

### 2. Install dependencies

```bash
npm install
```

### 3. Start local server

```bash
npm run dev
```

By default this runs:

```bash
python -m http.server 3000
```

Open:
- `http://localhost:3000/`

The root `index.html` immediately redirects to `public/index.html`.

### 4. Alternative local server (if Python command is unavailable)

Windows fallback examples:

```bash
py -m http.server 3000
```

or use VS Code Live Server on `index.html`.

## Supabase Setup

Supabase credentials are read from:
- `shared/js/config.js`

Update:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Important:
- The anon key is intended for client-side usage, but only safe when RLS policies are correctly enforced.
- Do not expose service role keys in frontend code.

## Database Migrations and SQL Files

The `database/` folder contains setup, migration, restore, and fix scripts.

Suggested execution approach for a fresh environment:

1. Run `database/supabase_complete_setup.sql` as baseline.
2. Apply migration scripts (`migration_v*.sql`) in version order.
3. Apply targeted fix scripts only if relevant to your environment.
4. Use seed scripts (for example `SEED_CONTENT_MINIMAL.sql`) only when needed.

Notes:
- There are also restore-oriented scripts (`MASTER_DB_RESTORE.sql`, `POST_RESTORE_VISIBILITY_FIX.sql`).
- Read each SQL file before executing to avoid conflicting operations in existing environments.

## Running and Testing

### Package scripts

- `npm run dev` : Starts local static server on port 3000
- `npm run build` : Copies project into `dist/` (best-effort script)

### Manual checks recommended before deployment

- Public flows: login, register, reset password
- Student flows: module view, lesson view, quiz pages
- Teacher flows: module management and submissions review
- Admin flows: users, analytics, settings
- Supabase auth and RLS-protected reads/writes

## Deployment

Vercel configuration is already included in `vercel.json`.

Current config characteristics:
- Static output
- Route rewrites for `public`, `student`, `teacher`, `admin`, `shared`, and asset folders
- Security headers:
  - `X-Content-Type-Options: nosniff`
  - `X-Frame-Options: DENY`
  - `X-XSS-Protection: 1; mode=block`

Typical deployment flow:

1. Push repository to Git provider.
2. Import project in Vercel.
3. Deploy with repository defaults.
4. Validate route rewrites and direct deep links.

## Security Notes

- Enforce RLS on all user data tables.
- Keep authorization checks consistent for student/teacher/admin roles.
- Validate upload type and size in both UI and storage policies.
- Avoid placing sensitive secrets in frontend JavaScript.
- Periodically audit old fix scripts before applying in production.

## Troubleshooting

### Local server starts but pages fail to load assets

- Confirm you opened `http://localhost:3000/` (project root), not a nested file URL.
- Verify path references are root-relative or correctly relative.

### Login or data operations fail

- Re-check `shared/js/config.js` Supabase URL and anon key.
- Verify SQL migrations and RLS policies are applied.
- Validate table/bucket names expected by page scripts.

### Route works locally but fails on deploy

- Re-check `vercel.json` rewrite coverage.
- Test direct navigation to nested routes (`/student/...`, `/teacher/...`, `/admin/...`).

## Contributing

1. Create a feature branch.
2. Keep changes scoped by area (`public`, `student`, `teacher`, `admin`, `shared`, `database`).
3. Test affected role flows end-to-end.
4. Open a pull request with:
   - What changed
   - Why it changed
   - How it was tested

## Docs Home

Start here for role-based reading paths:

- [docs/README.md](docs/README.md)

## Project Documentation Index

The following documentation set is now included:

1. Docs Home: [docs/README.md](docs/README.md)
2. Architecture diagram: [docs/architecture-diagram.md](docs/architecture-diagram.md)
3. Data model reference: [docs/data-model-reference.md](docs/data-model-reference.md)
4. Migration playbook: [docs/migration-playbook.md](docs/migration-playbook.md)
5. Environment strategy: [docs/environment-strategy.md](docs/environment-strategy.md)
6. QA test matrix: [docs/qa-test-matrix.md](docs/qa-test-matrix.md)
7. Incident and rollback guide: [docs/incident-rollback-guide.md](docs/incident-rollback-guide.md)
8. Access control matrix: [docs/access-control-matrix.md](docs/access-control-matrix.md)
9. API and storage conventions: [docs/api-storage-conventions.md](docs/api-storage-conventions.md)
10. Release process and checklist: [docs/release-process.md](docs/release-process.md)
11. Known limitations: [docs/known-limitations.md](docs/known-limitations.md)
12. Changelog: [CHANGELOG.md](CHANGELOG.md)
13. Contributor quickstart: [docs/quickstart-contributors.md](docs/quickstart-contributors.md)
14. Production readiness checklist: [docs/production-readiness-checklist.md](docs/production-readiness-checklist.md)

## Next Documentation Enhancements

1. Add generated ERD images from the active production-like schema.
2. Add executable policy verification scripts for CI.
3. Add role-based end-to-end test automation and attach results to releases.
4. Add architecture decision records for major changes.
