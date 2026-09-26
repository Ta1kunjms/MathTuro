---
name: execute-approved-plan
description: Implements only a plan the user explicitly approved, then runs independent review and reports evidence. Never use for planning or implicit approval.
argument-hint: APPROVE PLAN: <plan reference and conditions>
---

> **THIS SKILL MUST NEVER GENERATE IMPLEMENTATION CONTENT DIRECTLY WITHOUT
> AN EXPLICIT "APPROVE PLAN" AUTHORIZATION IN THE INVOCATION ARGUMENTS.**
> If the invocation does not contain the exact phrase `APPROVE PLAN`, stop
> immediately and return an error. Do not attempt to reconstruct missing
> approval from memory or prior conversation context.

# execute-approved-plan

Implements an explicitly approved plan, then runs independent verification
and presents evidence. **Never use for planning or implicit approval.**

## Hard gate

Continue **only** if the invocation arguments contain the exact phrase
`APPROVE PLAN` and unambiguously identify the complete plan in the current
conversation.

Approval authorizes **only** the identified plan and stated conditions.
It does **not** authorize:
- Deployment or `git push`
- Merge or publish
- Purchases, credential changes, or production database operations
- Destructive commands or unrelated refactors

If the approved plan cannot be recovered verbatim enough to determine scope
and acceptance criteria, **stop**. Never reconstruct missing approval from
memory or guesswork.

## Execution authorization

The invocation argument must be the user's explicit approval text, for
example:
```
APPROVE PLAN: <identify the plan and any conditions or exclusions>
```

## Workflow

1. **Preserve unrelated work** — check `git status` and note any changes
   outside the approved scope before touching anything.

2. **Delegate to implementation-lead** — pass the explicit approval, the
   full plan text, exclusions, and repository context.

3. **Inspect after implementation** — review the diff and actual command
   output before calling verification.

4. **Run independent reviews** — delegate the diff and approved acceptance
   criteria to `code-reviewer`, `security-privacy`, `accessibility-specialist`,
   and `qa-test-engineer`. Add `database-engineer`, `ai-ml-engineer`, or
   `devops-sre` when their domains changed.

5. **Resolve blockers** — if reviewers find blockers or high-severity defects
   within approved scope, ask `implementation-lead` to correct them, then
   rerun relevant verification. Do not hide unresolved disagreement.

6. **Stop before deployment** — present:
   - Changed files and why each changed
   - Commands/tests run with actual results
   - Acceptance-criteria traceability
   - Review findings and unresolved risks
   - Manual checks still needed
   - Migration, rollback, and deployment instructions (not yet executed)
   - Any new approval required before proceeding

## Never say

Do not say "complete," "secure," "accessible," "bias-free,"
"production-ready," or "tests passed" unless the reported evidence
supports that exact claim.

---

> **Note on tool permissions (migrated from Claude Code):** The original
> skill declared `disable-model-invocation: true`, meaning it was structured
> as an orchestrator that never generated implementation content on its own.
> Antigravity does not enforce this as a frontmatter flag. The intent is
> preserved as the hard rule at the top of this file.
