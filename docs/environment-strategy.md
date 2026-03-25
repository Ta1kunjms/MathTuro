# Environment Strategy

## Navigation

- Docs Home: [README.md](README.md)
- Project README: [../README.md](../README.md)


This document defines environment separation and configuration standards.

## Environment Model

Use three Supabase projects:

1. Development
- Purpose: daily feature work and local experimentation.
- Data: synthetic or non-sensitive test data.

2. Staging
- Purpose: pre-release validation and full regression checks.
- Data: staging-safe subset or generated realistic data.

3. Production
- Purpose: live traffic.
- Data: real user data with strict controls.

## Configuration Strategy

Current project stores config in shared/js/config.js.

Recommended approach over time:

1. Keep public-safe values only in frontend configuration.
2. Move environment-specific values to deployment-managed variables where possible.
3. Never include service role keys in frontend assets.

## Branch and Deploy Mapping

- Feature branches -> development environment previews
- Main or release branch -> staging validation deploy
- Tagged release -> production deploy

## Access Control and Secrets

1. Restrict production database write access.
2. Use least privilege for all human and automation accounts.
3. Rotate secrets on schedule and after incidents.
4. Keep audit trail for who changed environment config.

## Data Management

1. Do not clone production PII into dev.
2. Use anonymization for any staging refresh derived from production.
3. Define retention policy for logs and activity data.

## Environment Readiness Checklist

Before declaring an environment ready:

1. Schema version is known and documented.
2. Required storage buckets exist.
3. RLS policies are validated.
4. Base admin account path is tested.
5. Smoke tests pass for all role paths.

## Release Gates

Required gates before production deploy:

1. Migration dry run in staging.
2. QA matrix pass in staging.
3. Security checks for auth and RLS.
4. Rollback plan approved.

## Recommended Next Additions

- Add per-environment domain and redirect mapping.
- Add environment health dashboard checks.
- Add automated schema drift detection.

---

**Previous:** [migration-playbook.md](migration-playbook.md) | **Next:** [qa-test-matrix.md](qa-test-matrix.md)
