# Migration Playbook

## Navigation

- Docs Home: [README.md](README.md)
- Project README: [../README.md](../README.md)


This playbook defines safe, repeatable SQL execution flows.

## Principles

1. Never run unknown SQL blindly in production.
2. Backup before any schema or policy changes.
3. Apply migrations in a deterministic order.
4. Verify after each phase.
5. Keep rollback options ready before applying risky changes.

## File Categories in database Folder

- Baseline setup: supabase_complete_setup.sql
- Versioned migrations: migration_v*.sql
- Targeted fixes: fix_*.sql and FIX_*.sql
- Restore helpers: MASTER_DB_RESTORE.sql, POST_RESTORE_VISIBILITY_FIX.sql
- Seed data: SEED_CONTENT_MINIMAL.sql

## Scenario A: Fresh Environment Setup

1. Create a new Supabase project.
2. Run supabase_complete_setup.sql.
3. Apply migration_v files in ascending version order.
4. Apply only relevant fix scripts for known issues.
5. Apply optional seed script if required.
6. Validate auth, RLS, storage, and core CRUD paths.

## Scenario B: Existing Environment Upgrade

1. Export backup and capture schema snapshot.
2. List current migration state and target state.
3. Apply missing migration_v files in order.
4. Apply only justified fix scripts with change notes.
5. Run smoke tests for each role.
6. Record results in release notes.

## Scenario C: Restore and Recover

1. Restore from last known good backup.
2. Run MASTER_DB_RESTORE.sql if your recovery process requires it.
3. Run POST_RESTORE_VISIBILITY_FIX.sql if visibility issues appear.
4. Re-run critical policy verification queries.
5. Validate key user journeys.

## Pre-Migration Checklist

1. Maintenance window confirmed.
2. Backup tested and restorable.
3. SQL review completed by at least one peer.
4. Dependencies identified, especially policy dependencies.
5. Rollback criteria defined.
6. Post-migration test owner assigned.

## Post-Migration Verification

1. Authentication and login works for all roles.
2. Student can view only allowed content.
3. Teacher can manage content and review submissions.
4. Admin can access management pages.
5. Storage upload and read policies behave correctly.
6. No critical errors in browser console or logs.

## Rollback Triggers

Rollback immediately if any of the following occurs:
- Widespread authorization failures
- Data corruption indicators
- Broken core flows for multiple roles
- Unexpected destructive schema drift

## Change Logging Template

Use this format in releases:

- Date:
- Environment:
- Operator:
- SQL files applied:
- Preconditions checked:
- Verification results:
- Issues found:
- Follow-up actions:

## Automation Recommendations

- Adopt a migration runner with explicit version tracking table.
- Add CI checks that parse and validate SQL naming and order.
- Add a policy verification script for core read and write scenarios.

---

**Previous:** [access-control-matrix.md](access-control-matrix.md) | **Next:** [environment-strategy.md](environment-strategy.md)
