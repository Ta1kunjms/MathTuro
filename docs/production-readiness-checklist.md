# Production Readiness Checklist

## Navigation

- Docs Home: [README.md](README.md)
- Project README: [../README.md](../README.md)


Use this checklist before each production release.

## A. Planning and Scope

1. Release scope is frozen and documented.
2. Risk level is assessed for all included changes.
3. Ownership is assigned for deploy and verification.

## B. Database and Policy Readiness

1. Required SQL files are identified and ordered.
2. Migration runbook reviewed: [migration-playbook.md](migration-playbook.md).
3. Backup and restore path verified.
4. RLS expectations cross-checked with [access-control-matrix.md](access-control-matrix.md).
5. Storage bucket rules validated against [api-storage-conventions.md](api-storage-conventions.md).

## C. Application Readiness

1. Critical role flows pass manual regression: [qa-test-matrix.md](qa-test-matrix.md).
2. Public routes and auth flows validated.
3. Student content and progress flows validated.
4. Teacher management and submission flows validated.
5. Admin management and analytics flows validated.

## D. Environment and Config

1. Target environment confirmed.
2. Environment strategy reviewed: [environment-strategy.md](environment-strategy.md).
3. Supabase URL and anon key verified for target environment.
4. No service-role secrets are exposed to frontend assets.

## E. Deployment and Monitoring

1. Deploy steps reviewed: [release-process.md](release-process.md).
2. Rollback plan ready: [incident-rollback-guide.md](incident-rollback-guide.md).
3. Post-deploy smoke checks assigned.
4. Monitoring window and response owner assigned.

## F. Documentation and Audit

1. Changelog updated: [../CHANGELOG.md](../CHANGELOG.md).
2. Known limitations reviewed: [known-limitations.md](known-limitations.md).
3. Any new risks are documented with follow-up owners.

## Release Sign-Off

- Release version:
- Environment:
- Deployment owner:
- QA owner:
- Approval timestamp:
- Final status:

---

**Previous:** [qa-test-matrix.md](qa-test-matrix.md) | **Next:** [release-process.md](release-process.md)
