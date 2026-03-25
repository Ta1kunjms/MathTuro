# Release Process and Checklist

## Navigation

- Docs Home: [README.md](README.md)
- Project README: [../README.md](../README.md)


This document defines a repeatable release workflow.

## Release Flow

1. Freeze scope for the release.
2. Confirm migrations required for new features.
3. Validate in staging using the QA matrix.
4. Prepare release notes entry.
5. Deploy and run production smoke checks.
6. Monitor and close release.

## Pre-Release Checklist

1. All critical bugs triaged.
2. SQL migrations reviewed and ordered.
3. RLS and storage policy checks complete.
4. QA matrix pass recorded.
5. Rollback plan documented.
6. Changelog draft complete.

## Deployment Checklist

1. Confirm target commit hash.
2. Apply database changes in approved order.
3. Deploy frontend.
4. Validate role entry routes and key operations.
5. Validate no severe console or runtime errors.

## Post-Release Checklist

1. Monitor auth, query, and upload error rates.
2. Confirm no high-severity regressions.
3. Publish final changelog notes.
4. Record follow-up actions for minor issues.

## Changelog Convention

Use CHANGELOG.md with this structure:

- Added
- Changed
- Fixed
- Security

For each release include:
- Version
- Date
- Summary
- Notable migration or policy notes

## Versioning Guidance

- Use semantic versioning where practical.
- Increment major for breaking behavior changes.
- Increment minor for backward-compatible features.
- Increment patch for bug fixes.

---

**Previous:** [production-readiness-checklist.md](production-readiness-checklist.md) | **Next:** [incident-rollback-guide.md](incident-rollback-guide.md)
