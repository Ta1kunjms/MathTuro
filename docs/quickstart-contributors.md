# Contributor Quickstart

## Navigation

- Docs Home: [README.md](README.md)
- Project README: [../README.md](../README.md)


This quickstart is the fastest safe path for new contributors.

## 1. Prepare Local Environment

1. Install Node.js and Python 3.
2. Run npm install.
3. Run npm run dev.
4. Open http://localhost:3000/.

## 2. Understand the Project Areas

- public: landing and authentication pages
- student: student learning experience
- teacher: teacher management and review experience
- admin: administration and governance views
- shared: reusable JavaScript and CSS
- database: SQL migrations and policy scripts

## 3. Read Core Docs Before Changing Logic

1. Architecture: [architecture-diagram.md](architecture-diagram.md)
2. Data model: [data-model-reference.md](data-model-reference.md)
3. Access control: [access-control-matrix.md](access-control-matrix.md)
4. API and storage conventions: [api-storage-conventions.md](api-storage-conventions.md)
5. Migration playbook: [migration-playbook.md](migration-playbook.md)
6. QA matrix: [qa-test-matrix.md](qa-test-matrix.md)

## 4. Make Changes Safely

1. Keep edits scoped to one feature area when possible.
2. If schema changes are required, add SQL in the database folder and document intent.
3. Verify role-based behavior for affected pages.
4. Keep naming and storage conventions consistent.

## 5. Validate Before PR

1. Run manual smoke checks using [qa-test-matrix.md](qa-test-matrix.md).
2. Confirm no role can access data they should not access.
3. Confirm key page flows still work in public, student, teacher, and admin paths.
4. Summarize what changed and how it was tested.

## 6. Release and Incident Awareness

- Review release steps in [release-process.md](release-process.md).
- Review rollback flow in [incident-rollback-guide.md](incident-rollback-guide.md).

## PR Template Suggestions

Include the following in each PR description:

- Scope
- Risk level
- SQL changes
- RLS or permission impact
- Test evidence
- Rollback notes

---

**Previous:** [README.md](README.md) | **Next:** [architecture-diagram.md](architecture-diagram.md)
