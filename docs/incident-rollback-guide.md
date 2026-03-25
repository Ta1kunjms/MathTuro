# Incident and Rollback Guide

## Navigation

- Docs Home: [README.md](README.md)
- Project README: [../README.md](../README.md)


Use this guide when production behavior regresses after changes.

## Incident Severity

1. SEV-1
- Complete outage or critical role workflows unavailable.

2. SEV-2
- Major feature degradation with workaround.

3. SEV-3
- Minor degradation, low-impact bugs.

## Immediate Response

1. Declare incident channel and owner.
2. Freeze non-essential deployments.
3. Capture timeline and first known bad change.
4. Protect data by pausing risky write paths if needed.

## Triage Steps

1. Identify affected role flows and pages.
2. Check deployment diff and recent SQL changes.
3. Validate Supabase auth, database, storage, and policy behavior.
4. Classify if issue is frontend, schema, policy, or data.

## Rollback Decision Criteria

Rollback when:
- User-facing critical paths are broken.
- A bad migration or policy blocks access.
- Data integrity is at risk.

Hotfix when:
- Issue is isolated and low-risk to patch quickly.

## Rollback Paths

### A. Frontend Rollback

1. Re-deploy previous known good commit.
2. Re-test public, student, teacher, and admin entry paths.
3. Confirm browser cache/CDN invalidation behavior.

### B. Database and Policy Rollback

1. Stop additional schema modifications.
2. Restore from backup or run approved rollback SQL.
3. Re-apply stable policy set.
4. Validate critical read and write operations per role.

### C. Combined Rollback

1. Rollback frontend first to reduce user impact.
2. Rollback database or policies second if still failing.
3. Re-run smoke matrix after each stage.

## Evidence Collection

Capture the following:
- Deploy ID and commit hash
- SQL files executed
- Error logs and affected routes
- User reports with timestamps
- Final root cause statement

## Communication Template

- Incident status:
- Impacted users:
- Start time:
- Current mitigation:
- ETA for resolution:
- Next update time:

## Post-Incident Review

1. Root cause
2. Why safeguards failed
3. Corrective actions
4. Preventive actions
5. Owner and due dates

## Preventive Controls

- Require staging migration dry runs.
- Require policy verification before production release.
- Keep rollback SQL scripts versioned and reviewed.
- Add automated smoke checks for role entry routes.

---

**Previous:** [release-process.md](release-process.md) | **Next:** [known-limitations.md](known-limitations.md)
