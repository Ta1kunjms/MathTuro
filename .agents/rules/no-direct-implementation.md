---
trigger: always_on
always_on: true
description: Enforces strict gate requiring the exact phrase 'APPROVE PLAN' before any implementation, preventing unauthorized file generation or editing by council-plan, execute-approved-plan, and verify-delivery.
---

# Gate Enforcement — No Direct Implementation Without Explicit Approval

This rule is **permanently active** across all sessions and interactions. It mechanically binds the planning, execution, and verification lifecycle.

## Core Principle

No agent, skill, subagent, or autonomous workflow may write, edit, replace, or delete project files without prior explicit human authorization using the exact phrase:

```text
APPROVE PLAN
```

No variation, approximation, or implied consent (e.g., "looks good", "proceed", "go ahead", "yes please", "do it", "approved") authorizes code implementation or file modification.

---

## Role-Specific Strict Constraints

### 1. `council-plan` (Planning & Discovery)
- **Prohibition:** NEVER generate, modify, write, or delete implementation files, source code, configuration files, database schemas, or test suites.
- **Allowed Scope:** Discovery, analysis, reading documentation, evaluating architecture, and writing read-only plan artifacts or review reports to the brain/artifacts directory.
- **Gate Behavior:** Once planning is complete, present the plan to the user and HALT. Do not execute any implementation steps.

### 2. `execute-approved-plan` (Implementation Execution)
- **Strict Precondition:** NEVER execute implementation tasks or modify files unless the user has explicitly entered the exact phrase **`APPROVE PLAN`** in the conversation.
- **Verification Requirement:**
  - Before making any file edit (`write_to_file`, `replace_file_content`, `multi_replace_file_content`, or shell commands modifying files), check the conversation history for the exact token: `APPROVE PLAN`.
  - If the phrase has NOT been stated verbatim by the user in this session, immediately refuse implementation, display the plan summary, and request:
    > "Implementation is locked. Please respond with the exact phrase **`APPROVE PLAN`** to authorize modifications."
- **Scope Limit:** Only execute items explicitly detailed and agreed upon within the approved plan. Never perform out-of-scope refactoring or unauthorized additions.

### 3. `verify-delivery` (Independent Verification & Auditing)
- **Prohibition:** NEVER modify, edit, generate, patch, or revert source code, tests, documentation, or configuration files during verification.
- **Allowed Scope:** Read-only inspection, running non-destructive tests/linters, comparing outputs against acceptance criteria, and producing an evidence-based verification report.
- **Remediation Rule:** If defects or deviations are discovered, report them as findings with actionable diff suggestions in the verification report — do NOT attempt autonomous remediation or direct fixes.

---

## Tool Enforcement Summary

| Tool | Authorized Under `council-plan` | Authorized Under `verify-delivery` | Authorized Under `execute-approved-plan` |
|---|---|---|---|
| `view_file`, `list_dir`, `grep_search` | ✅ Yes | ✅ Yes | ✅ Yes |
| `read_url_content`, `search_web` | ✅ Yes | ✅ Yes | ✅ Yes |
| `run_command` (read-only/test/lint) | ✅ Yes | ✅ Yes (non-destructive only) | ✅ Yes |
| `write_to_file` (workspace files) | ❌ **DENIED** | ❌ **DENIED** | 🔒 **REQUIRES EXACT `APPROVE PLAN`** |
| `replace_file_content` | ❌ **DENIED** | ❌ **DENIED** | 🔒 **REQUIRES EXACT `APPROVE PLAN`** |
| `multi_replace_file_content` | ❌ **DENIED** | ❌ **DENIED** | 🔒 **REQUIRES EXACT `APPROVE PLAN`** |
| `run_command` (build/migrate/write) | ❌ **DENIED** | ❌ **DENIED** | 🔒 **REQUIRES EXACT `APPROVE PLAN`** |

Any attempt to bypass this gate is a direct violation of repository security and workflow policy.
