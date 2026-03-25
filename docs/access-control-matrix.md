# Access Control Matrix

## Navigation

- Docs Home: [README.md](README.md)
- Project README: [../README.md](../README.md)


This matrix describes intended role permissions for core entities.

Legend:
- Y: allowed
- O: owner-scoped
- N: not allowed
- C: conditional based on status or policy rules

## Entity Permissions

| Entity | Student Read | Student Create | Student Update | Student Delete | Teacher Read | Teacher Create | Teacher Update | Teacher Delete | Admin Read | Admin Create | Admin Update | Admin Delete |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| users | O | N | O | N | C | N | N | N | Y | Y | Y | Y |
| modules | Y | N | N | N | Y | Y | Y | Y | Y | Y | Y | Y |
| lessons | Y | N | N | N | Y | Y | Y | Y | Y | Y | Y | Y |
| quiz_submissions | O | Y | O | N | Y | N | Y | N | Y | N | Y | Y |
| lesson_progress | O | Y | O | N | Y | N | N | N | Y | N | Y | Y |
| notifications | O | N | O | N | C | C | C | C | Y | Y | Y | Y |
| activity_log | N | C | N | N | N | C | N | N | Y | C | N | N |

## Storage Permissions

| Bucket | Student Upload | Student Read | Teacher Upload | Teacher Read | Admin Upload | Admin Read |
|---|---|---|---|---|---|---|
| quiz-screenshots | Y | O | C | Y | Y | Y |
| learning-materials | N | C | Y | Y | Y | Y |

## Policy Design Rules

1. Default deny, then allow least privilege.
2. Student access should be owner-scoped unless intentionally public.
3. Teacher access should be scoped to instructional responsibilities.
4. Admin access should be explicit and auditable.
5. Public and guest paths should not bypass protected resources.

## Validation Checklist

1. Confirm RLS enabled on every protected table.
2. Verify each permission path with role-specific test accounts.
3. Verify negative paths, especially cross-user access attempts.
4. Validate storage policies for read and upload ownership rules.

## Notes

- This matrix is the intended model and should be reconciled with actual SQL policy definitions in the database folder.

---

**Previous:** [api-storage-conventions.md](api-storage-conventions.md) | **Next:** [migration-playbook.md](migration-playbook.md)
