---
name: verify-delivery
description: Independently verifies an implementation against an approved plan and reports evidence without editing source files.
argument-hint: <approved plan or acceptance criteria>
---

> **THIS SKILL MUST NEVER EDIT SOURCE FILES OR GENERATE IMPLEMENTATION
> CONTENT DIRECTLY.** It only reads, inspects, and produces a verification
> report. It never fixes, patches, or modifies any project file.

# verify-delivery

Independently verifies an implementation against an approved plan and
reports a structured evidence-based result. Read-only — no source file
edits, no fixes, no commits.

## Trigger

Invoke this skill after `execute-approved-plan` has completed, passing the
approved acceptance criteria or plan reference as the argument.

## Constraints (verification hard limits)

- Do NOT edit any source file.
- Do NOT write new implementation files.
- Do NOT deploy, commit, or push.
- Do NOT claim a check passed unless you executed it and observed the result.

## Workflow

1. **Recover the approved acceptance criteria** from the current
   conversation. If they cannot be found, stop and ask the user to provide
   them before proceeding.

2. **Inspect the diff and relevant call paths** — read changed files,
   trace execution paths from entry points to modified logic.

3. **Run independent parallel reviews** — delegate to `code-reviewer`,
   `security-privacy`, `accessibility-specialist`, and `qa-test-engineer`.
   Add `database-engineer`, `ai-ml-engineer`, or `devops-sre` only when
   their domains are affected.

4. **Reconcile findings** — deduplicate overlapping results across reviewers.
   Cite specific files and actual command outputs.

5. **Separate executed checks from recommended checks** — clearly mark:
   - **Verified:** you ran it and saw the result
   - **Not verified / assumed:** inferred from reading code

6. **Report per acceptance criterion:**
   - `PASS` — criterion met with supporting evidence
   - `CONDITIONAL PASS` — met with caveats or remaining risk
   - `FAIL` — criterion not met; describe exact gap

## Output

A passing static review is **not** proof that runtime behavior works.
Always distinguish code-level findings from runtime verification.

---

> **Note on tool permissions (migrated from Claude Code):** The original
> skill declared `disable-model-invocation: true` and restricted tools to
> Read/Grep/Glob and agent delegation. Antigravity does not enforce these
> as frontmatter flags. The intent is preserved as the hard rule at the
> top of this file: this skill produces a report only, never implementation.
