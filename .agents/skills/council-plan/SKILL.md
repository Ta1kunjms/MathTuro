---
name: council-plan
description: Runs an approval-first, multidisciplinary website review and produces one evidence-based plan without editing code. Use for a new website, feature, redesign, migration, or major architectural decision.
argument-hint: <website or feature request>
---

> **THIS SKILL MUST NEVER GENERATE IMPLEMENTATION CONTENT DIRECTLY.**
> It only produces a plan and then waits for explicit approval before any
> execution agent runs. Do not Edit, Write, create files, install packages,
> change configuration, deploy, commit, or push — not even a single line.

# council-plan

Runs an approval-first council. This invocation is planning only.

## Trigger

Invoke this skill when the user requests a new website, major feature,
redesign, migration, or significant architectural decision — or when the
user says "plan this" / "review this before I build it."

Pass the full user request as the argument to this skill.

## Constraints (planning-phase hard limits)

- Do NOT edit any file in the project.
- Do NOT write new files.
- Do NOT install packages or change configuration.
- Do NOT deploy, commit, or push.
- Do NOT invoke the implementation-lead agent.

## Workflow

1. **Inspect the repository** — identify actual stack, conventions, working
   tree state, and relevant existing implementation. If no repository exists,
   state that this is greenfield and identify assumptions.

2. **Ask only blocking questions.** If reasonable defaults allow useful
   planning, state them and continue.

3. **Delegate in parallel** where agents are independent:
   - `requirements-analyst`, `cpo-product`, `ux-researcher`
   - `ceo-strategist` and `cmo-growth` when business, public-service
     adoption, launch, content, or growth matters
   - `cto-architect` plus relevant `frontend-engineer`, `backend-engineer`,
     `database-engineer`, `ai-ml-engineer`, `devops-sre` specialists
   - `security-privacy`, `accessibility-specialist`, `qa-test-engineer`

4. **Do not invoke irrelevant roles** merely to create volume. Record why
   omitted roles are not material.

5. **Red-team pass** — give first-round findings to `red-team-critic`. Ask
   it to attack assumptions, contradictions, scope, architecture, and
   release safety.

6. **Synthesis** — give the original request, repository evidence, all
   specialist reports, and red-team findings to `council-synthesizer`.
   Require one approval-ready plan, not disconnected opinions.

7. **Validate** the synthesis against the repository. Ensure every must-have
   has acceptance criteria and a verification step.

8. **Present** the final plan, material disagreements, unresolved questions,
   and an explicit Approval Block.

## End condition

End the skill output with exactly:

```
STATUS: AWAITING USER APPROVAL
To authorize implementation, invoke execute-approved-plan with the exact
phrase "APPROVE PLAN: <identify this plan and any conditions>".
Anything else — including continued discussion — is not approval.
```

---

> **Note on tool permissions (migrated from Claude Code):** The original
> skill declared `disable-model-invocation: true` and restricted tools to
> Read/Grep/Glob/WebSearch/WebFetch and agent delegation. Antigravity does
> not enforce these as frontmatter flags. The intent is preserved as the
> hard rule at the top of this file: this skill produces a plan only.
