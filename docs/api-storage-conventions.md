# API and Storage Conventions

## Navigation

- Docs Home: [README.md](README.md)
- Project README: [../README.md](../README.md)


This project is frontend-first and primarily interacts with Supabase tables and storage rather than a custom backend API server.

## Data Access Conventions

1. Keep table access logic in shared JS modules where possible.
2. Reuse shared/js/supabase.js for client initialization.
3. Centralize app constants in shared/js/config.js.
4. Keep role checks explicit and consistent.

## Naming Conventions

### Tables and Columns

- Use lowercase snake_case.
- Use plural names for tables.
- Use _id suffix for foreign keys.
- Use created_at and updated_at timestamps where practical.

### Storage Buckets

- Use lowercase kebab-case bucket names.
- Current buckets include:
  - quiz-screenshots
  - learning-materials

### Object Paths

Use deterministic object key patterns:

1. quiz-screenshots
- student/{user_id}/{submission_id}/{filename}

2. learning-materials
- role/{teacher_or_admin_id}/module/{module_id}/{filename}

## Upload Rules

1. Validate file type and size client-side before upload.
2. Enforce type and path constraints in storage policies.
3. Store stable metadata in table rows where needed.
4. Do not trust filename uniqueness without namespacing.

## Error Handling Conventions

1. Always surface actionable error messages to users.
2. Log detailed diagnostics in development only.
3. Use consistent toast or alert patterns for failures.
4. Retry transient network operations only when safe.

## Versioning and Compatibility

1. Add migration SQL before relying on new fields in UI.
2. Guard UI against missing columns during phased rollouts.
3. Keep policy changes backward compatible when possible.

## Security Conventions

1. Never use service role keys in client files.
2. Enforce role and ownership checks in RLS.
3. Avoid broad wildcard policies in production.
4. Ensure public pages cannot query private records.

## Recommended Implementation Follow-Up

- Add a storage helper module for path generation.
- Add upload metadata standards for content type and original filename.
- Add static lint checks for forbidden key usage.

---

**Previous:** [data-model-reference.md](data-model-reference.md) | **Next:** [access-control-matrix.md](access-control-matrix.md)
