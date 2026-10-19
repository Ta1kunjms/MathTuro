# GitHub Copilot Instructions - MathTuro

This repository is a frontend-first Learning Management System (LMS) built with static HTML, shared JavaScript/CSS modules, and Supabase.

For complete shared project rules and agent roles, see [AGENTS.md](../AGENTS.md).

## Commands
- Develop: `npm run dev`
- Build: `npm run build`
- Build CSS: `npm run build:css`
- Lint/Test: UNVERIFIED - confirm manually before running

## Safety
- Never read secrets or environment files (`.env`, `.env.*`, `secrets/`, `credentials/`).
- Never run destructive Git, filesystem, database, or production deployment commands (`git push`, `git reset --hard`, `git clean`, `rm -rf`, `Remove-Item * -Recurse`).
- Never push, reset hard, clean, reset databases (`supabase db reset`, `supabase db push`), mutate production data, or deploy to production (`vercel --prod`) without explicit separate human approval.

## Approval Gate
Implementation requires the exact user approval: `APPROVE PLAN`.
Do not modify or create workspace files during planning or review.

## Architecture & Code
- Static HTML with shared JavaScript/CSS modules; hosted on Vercel.
- Do not introduce React, Vue, Next.js, or backend servers without explicit approval.
- Role-based directories: `public/`, `student/`, `teacher/`, `admin/`. Maintain strict role boundaries.
- Supabase client initialized only in `shared/js/supabase.js`. Never expose service-role keys in client code.
- Database schemas and migrations reside in `database/`. Always verify RLS policies.
- Keep diffs scoped to the requested task. Do not perform unrelated refactors.

## Completion
- Report changed files.
- Report checks run and results.
- State unrun checks and blockers.
