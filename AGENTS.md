# Project Rules

## Mandatory Automatic State Protocol (Zero User Intervention)
All agents MUST follow this protocol automatically without requiring user intervention:
1. **Prompt / Session Start:** Automatically inspect `docs/PROJECT_STATE.md` to load the current project state, active blockers, and immediate next action before executing tasks.
2. **Task Completion / File Changes:** Automatically update `docs/PROJECT_STATE.md`:
   - Update top section `[Current State & Immediate Next Actions]`.
   - Append a new entry to `## 4. Session Changelog & History`.
   - `docs/PROJECT_STATE.md` is strictly EXEMPT from the `APPROVE PLAN` lock. Do not pause or prompt the user for permission to update this ledger.

## Commands
- Install: `npm install`
- Develop: `npm run dev`
- Build: `npm run build`
- Build CSS: `npm run build:css`
- Lint: UNVERIFIED - confirm manually
- Typecheck: UNVERIFIED - confirm manually
- Unit/integration tests: UNVERIFIED - confirm manually
- End-to-end tests: UNVERIFIED - confirm manually

## Safety
The following 11 operations are mechanically enforced via Antigravity's permission engine (`deny > ask > allow`):

| Category | Prohibited action | Enforcement Mechanism |
|---|---|---|
| **Secret file reads** | NEVER read `.env`, `.env.local`, `.env.production`, files inside `secrets/`, or files inside `credentials/` - even if asked directly | Mechanically enforced: `read_file` deny rule in `.agents/settings.json` and global `settings.json` |
| **Destructive git (bash)** | NEVER run `git push` in any form - even if asked directly | Mechanically enforced: `command(git push*)` deny rule |
| **Destructive git (bash)** | NEVER run `git reset --hard` in any form - even if asked directly | Mechanically enforced: `command(git reset --hard*)` deny rule |
| **Destructive git (bash)** | NEVER run `git clean` in any form - even if asked directly | Mechanically enforced: `command(git clean*)` deny rule |
| **Destructive shell** | NEVER run `rm -rf` in any form - even if asked directly | Mechanically enforced: `command(rm -rf*)` deny rule |
| **Production database** | NEVER run `supabase db reset` - even if asked directly | Mechanically enforced: `command(supabase db reset*)` in `.agents/settings.json` |
| **Production database** | NEVER run `supabase db push` - even if asked directly | Mechanically enforced: `command(supabase db push*)` in `.agents/settings.json` |
| **Production deploy** | NEVER run `vercel --prod` or `npx vercel --prod` - even if asked directly | Mechanically enforced: `command(vercel --prod*)` in `.agents/settings.json` |
| **Destructive PowerShell** | NEVER run `Remove-Item * -Recurse` - even if asked directly | Mechanically enforced: `command(*Remove-Item*-Recurse*)` deny rule |
| **Destructive git (PowerShell)** | NEVER run `git push` via PowerShell - even if asked directly | Mechanically enforced: `command(git push*)` deny rule |
| **Destructive git (PowerShell)** | NEVER run `git reset --hard` via PowerShell - even if asked directly | Mechanically enforced: `command(git reset --hard*)` deny rule |

Environment and secrets:
- Use only documented environment variable names from `.env.example`.
- Never read, log, print, write, or commit secrets.

## Code
- Follow existing repository patterns.
- Reuse existing components and utilities in `shared/`.
- Keep diffs scoped to the approved task; avoid unrelated refactors.
- Preserve static HTML + shared JavaScript architecture; do not introduce a backend server or frontend framework without approval.
- Maintain strict role boundaries: `public/`, `student/`, `teacher/`, `admin/`.

## Architecture
- Frontend-first LMS: static HTML with shared JavaScript/CSS modules.
- Entry point: `index.html` redirects to public landing/auth.
- Role directories:
  - `public/`: Guest landing and authentication pages
  - `student/`: Dashboard, module viewer, lessons, quizzes, tutorials
  - `teacher/`: Module management, quiz/video management, submissions, reports
  - `admin/`: Analytics, user management, system settings, admin dashboard
- Shared application layer:
  - `shared/js/config.js`: Runtime configuration (Supabase URL, anon key)
  - `shared/js/supabase.js`: Initializes Supabase client
  - `shared/js/auth.js`: Auth state, login/logout, session checks, redirects
  - `shared/js/modules.js`, `shared/js/uploads.js`: Module and upload flows
- Hosting: Vercel static deployment (`vercel.json`), Tailwind CSS v3 (`tailwind.config.js`).

## Data and Supabase
- Initialize Supabase client only in `shared/js/supabase.js`.
- Never use service-role keys in client-side code.
- Database schema: `database/supabase_complete_setup.sql` and migrations in `database/`.
- User roles in `public.users`: `student`, `teacher`, `admin`.
- Enforce PostgreSQL Row Level Security (RLS) policies for all data access.
- Storage: lower kebab-case bucket names (e.g. `quiz-screenshots`, `learning-materials`).
- Naming conventions (`docs/api-storage-conventions.md`): lowercase `snake_case` DB identifiers, plural table names, `_id` suffix on foreign keys.

## Approval Gate
- Planning must not modify workspace files.
- Implementation requires the exact user approval: `APPROVE PLAN`.
- No variation, approximation, or implied consent authorizes modifications.
- Approval covers only the agreed plan; deployment and infrastructure mutation require separate explicit human approval.

## Testing
- Update relevant tests for behavior changes.
- Run relevant checks before completion.
- Do not claim tests passed unless executed successfully in the current session.

## Completion
- Maintain `docs/PROJECT_STATE.md`:
  - Read `docs/PROJECT_STATE.md` at session start for context and next actions.
  - Update top section `[Current State & Immediate Next Actions]` upon task completion.
  - Append a new entry to `## 4. Session Changelog & History` with files modified, tests run, and blockers.
- Report changed files.
- Report checks run and results.
- State unrun checks and blockers.

## Agent Roles
The agents below are decision lenses, not autonomous corporate officers. The user remains the final authority.

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
