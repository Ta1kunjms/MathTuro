# Known Limitations

## Navigation

- Docs Home: [README.md](README.md)
- Project README: [../README.md](../README.md)


Track known issues and technical debt here.

## Product and UX Limitations

1. Role experiences are split across many static pages, which can increase maintenance overhead.
2. Navigation and UI consistency can drift between portals over time.
3. Some workflows rely on manual verification and may need stronger automation.

## Technical Limitations

1. Frontend uses client-side configuration file for environment settings.
2. Build pipeline is minimal and focused on static hosting.
3. SQL change history includes many targeted fix files that can be hard to sequence without a strict migration state tracker.
4. Automated end-to-end tests are not yet part of the default workflow.

## Operational Limitations

1. Recovery steps are currently documentation-driven and not fully automated.
2. Environment drift risk exists without automated schema comparison.
3. Release verification is largely manual.

## Security and Governance Limitations

1. Policy complexity can grow as more role rules are added.
2. Periodic RLS audits are required to prevent privilege regressions.
3. Storage path consistency depends on implementation discipline.

## Prioritized Improvements

1. Introduce automated policy and permission tests.
2. Add migration version state tracking and validation scripts.
3. Add end-to-end test coverage for critical student, teacher, and admin paths.
4. Standardize component and page templates to reduce UI drift.
5. Formalize environment and secret management beyond static config.

## Change Log for Limitations File

- 2026-03-25: Initial limitations baseline added.

---

**Previous:** [incident-rollback-guide.md](incident-rollback-guide.md) | **Home:** [README.md](README.md)
