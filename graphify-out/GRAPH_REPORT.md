# Graph Report - MathTuro  (2026-10-21)

## Corpus Check
- 187 files · ~598,206 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 12 file(s) not represented in the graph (top: .css 6, .woff 2, .woff2 2)

## Summary
- 2169 nodes · 3836 edges · 152 communities (79 shown, 73 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 68 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `e45dc05e`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- public/shared/js/supabase-lib.js
- shared/js/supabase-lib.js
- J
- J
- DevTools
- ComponentManager
- TestRunner
- t
- t
- 5. Agent Instructions for Appending New Entries
- ErrorHandler
- shared/js/utils.js
- SecurityManager
- PerformanceManager
- ApiClient
- _onConnOpen
- _onConnOpen
- MathTuro Staging Program Status Audit
- MathTuro Learning Management System
- public/shared/js/utils.js
- 4. Session Changelog & History (Chronological Ledger)
- package.json
- PathManager
- send
- _debug
- constructor
- send
- _debug
- constructor
- student.js
- lessonplan-dnd.js
- admin-content.js
- UI Styling Skill
- Design
- n
- n
- Domain Rules (Detailed)
- Admin Portal UI Inconsistencies Report
- Project Rules
- Design System
- Supabase
- Changelog
- Changelog
- Writing Guidelines for Postgres References
- UI/UX Pro Max - Design Intelligence
- teacher.js
- Summary of Changes
- Banner Design - Multi-Format Creative Banner System
- Incident and Rollback Guide
- API and Storage Conventions
- Migration Playbook
- public/shared/js/modules.js
- shared/js/modules.js
- Brand
- [1.0.0] - 2026-03-25
- 3A. UI Redesign Workstream (Requirements, Status, Decisions)
- encode
- encode
- Section Definitions
- Web Engineering Standard
- Environment Strategy
- public/shared/js/auth.js
- shared/js/auth.js
- Gate Enforcement — No Direct Implementation Without Explicit Approval
- Production Readiness Checklist
- QA Test Matrix
- Contributor Quickstart
- verify_phase3_authenticated_api.ps1
- Data Model Reference
- Known Limitations
- MathTuro — Unified Project State & Session Handover Ledger
- Docs Home
- Release Process and Checklist
- Slides
- Access Control Matrix
- Architecture Diagram
- student/assets/js/sidebar.js
- lesson-plan-files.js
- admin/assets/js/sidebar.js
- council-plan
- execute-approved-plan
- Supabase Postgres Best Practices
- verify-delivery
- vercel.json
- settings.json
- index.ts
- public/shared/js/supabase.js
- shared/js/supabase.js
- advanced-full-text-search.md
- advanced-jsonb-indexing.md
- conn-idle-timeout.md
- conn-limits.md
- conn-pooling.md
- conn-prepared-statements.md
- data-batch-inserts.md
- data-n-plus-one.md
- data-pagination.md
- data-upsert.md
- lock-advisory.md
- lock-deadlock-prevention.md
- lock-short-transactions.md
- lock-skip-locked.md
- monitor-explain-analyze.md
- monitor-pg-stat-statements.md
- monitor-vacuum-analyze.md
- query-composite-indexes.md
- query-covering-indexes.md
- query-index-types.md
- query-missing-indexes.md
- query-partial-indexes.md
- schema-constraints.md
- schema-data-types.md
- schema-foreign-key-indexes.md
- schema-lowercase-identifiers.md
- schema-partitioning.md
- schema-primary-keys.md
- security-privileges.md
- security-rls-basics.md
- security-rls-performance.md
- _template.md
- public/shared/js/config.js
- shared/js/config.js
- routes.js

## God Nodes (most connected - your core abstractions)
1. `DevTools` - 61 edges
2. `5. Agent Instructions for Appending New Entries` - 47 edges
3. `J()` - 46 edges
4. `ErrorHandler` - 46 edges
5. `J()` - 46 edges
6. `TestRunner` - 44 edges
7. `ComponentManager` - 41 edges
8. `_returnResult()` - 39 edges
9. `SecurityManager` - 39 edges
10. `_returnResult()` - 39 edges

## Surprising Connections (you probably didn't know these)
- `_challenge()` --indirect_call--> `t()`  [INFERRED]
  public/shared/js/supabase-lib.js → public/shared/js/supabase-lib.js  _Bridges community 7 → community 2_
- `on()` --indirect_call--> `t()`  [INFERRED]
  public/shared/js/supabase-lib.js → public/shared/js/supabase-lib.js  _Bridges community 7 → community 34_
- `_push()` --indirect_call--> `t()`  [INFERRED]
  public/shared/js/supabase-lib.js → public/shared/js/supabase-lib.js  _Bridges community 7 → community 23_
- `ne()` --indirect_call--> `n()`  [INFERRED]
  public/shared/js/supabase-lib.js → public/shared/js/supabase-lib.js  _Bridges community 34 → community 0_
- `_push()` --indirect_call--> `n()`  [INFERRED]
  public/shared/js/supabase-lib.js → public/shared/js/supabase-lib.js  _Bridges community 34 → community 23_

## Import Cycles
- None detected.

## Communities (152 total, 73 thin omitted)

### Community 0 - "public/shared/js/supabase-lib.js"
Cohesion: 0.02
Nodes (59): _appendParams(), channel(), cloneRequestState(), cr(), createNamespace(), createNamespaceIfNotExists(), createTable(), createTableIfNotExists() (+51 more)

### Community 1 - "shared/js/supabase-lib.js"
Cohesion: 0.02
Nodes (59): _appendParams(), channel(), cloneRequestState(), cr(), createNamespace(), createNamespaceIfNotExists(), createTable(), createTableIfNotExists() (+51 more)

### Community 2 - "J"
Cohesion: 0.07
Nodes (70): _acquireLock(), _approveAuthorization(), _authenticate(), _challenge(), _challengeAndVerify(), createNewAbortSignal(), _createOAuthClient(), createUser() (+62 more)

### Community 3 - "J"
Cohesion: 0.07
Nodes (70): _acquireLock(), _approveAuthorization(), _authenticate(), _challenge(), _challengeAndVerify(), createNewAbortSignal(), _createOAuthClient(), createUser() (+62 more)

### Community 6 - "TestRunner"
Cohesion: 0.07
Nodes (3): ConsoleReporter, HTMLReporter, TestRunner

### Community 7 - "t"
Cohesion: 0.07
Nodes (50): Be(), cn(), copy(), createBucket(), createIndex(), createSignedUploadUrl(), createSignedUrl(), createSignedUrls() (+42 more)

### Community 8 - "t"
Cohesion: 0.07
Nodes (50): Be(), cn(), copy(), createBucket(), createIndex(), createSignedUploadUrl(), createSignedUrl(), createSignedUrls() (+42 more)

### Community 9 - "5. Agent Instructions for Appending New Entries"
Cohesion: 0.04
Nodes (47): [2026-10-20 04:35] — Git Commit e4ccf9b, [2026-10-20 04:57] — Git Commit 3197813, [2026-10-20 04:57] — Git Commit b4e3704, [2026-10-20 04:57] — Git Commit c30b100, [2026-10-20 04:57] — Git Commit ef0ae91, [2026-10-20 14:35] — Git Commit 72854ed, [2026-10-20 14:35] — Git Commit 8b95615, [2026-10-20 14:35] — Git Commit b8fe074 (+39 more)

### Community 11 - "shared/js/utils.js"
Cohesion: 0.06
Nodes (16): cache, clearCache(), createToastContainer(), escapeHtml(), getToastColorClass(), getToastIcon(), handleNetworkError(), handleSessionExpired() (+8 more)

### Community 14 - "ApiClient"
Cohesion: 0.10
Nodes (3): ApiClient, ApiError, authToken

### Community 15 - "_onConnOpen"
Cohesion: 0.10
Nodes (37): _clearAllTimers(), _clearTimer(), connect(), connectionState(), disconnect(), endpointURL(), flushSendBuffer(), isConnected() (+29 more)

### Community 16 - "_onConnOpen"
Cohesion: 0.10
Nodes (37): _clearAllTimers(), _clearTimer(), connect(), connectionState(), disconnect(), endpointURL(), flushSendBuffer(), isConnected() (+29 more)

### Community 17 - "MathTuro Staging Program Status Audit"
Cohesion: 0.06
Nodes (34): 10. Regression / UI / Manual QA Executed, 1. Authentication and Provisioning, 1. Static / Local Inspection Completed, 2. Account Data, 2. Unauthenticated Staging Probes Completed, 3. Accessibility and Design, 3. Authenticated Staging Tests Prepared, 4. Authenticated Staging Tests Executed (+26 more)

### Community 18 - "MathTuro Learning Management System"
Cohesion: 0.06
Nodes (34): 1. Prerequisites, 2. Install dependencies, 3. Start local server, 4. Alternative local server (if Python command is unavailable), Admin, Backend Services, Contributing, Current Feature Coverage (+26 more)

### Community 19 - "public/shared/js/utils.js"
Cohesion: 0.09
Nodes (16): cache, clearCache(), createToastContainer(), escapeHtml(), getToastColorClass(), getToastIcon(), handleNetworkError(), handleSessionExpired() (+8 more)

### Community 20 - "4. Session Changelog & History (Chronological Ledger)"
Cohesion: 0.06
Nodes (31): [2026-09-25] — Commit `4ee9576`: Accounts, Demographic Security & Approval Queue, [2026-09-26] — Commit `c245b0a`: Formal Assessment Foundation & Progression Gating, [2026-09-29] — Commit `f7b8435`: Native Quiz CMS, Archiving, EXP & Accessibility, [2026-10-20 02:55] — Zero-Intervention Automatic State Protocol Setup, [2026-10-20 03:33] — Test User Authentication & Staging RLS Diagnostic, [2026-10-20 03:45] — Authenticated Phase 3 Suite Run & Staging Diagnosis, [2026-10-20 03:55] — Manual Staging Unblock Steps Handed to User, [2026-10-20 04:00] — Suite Extended; Assessment RPC Bug & Submission Gating Gap Found (+23 more)

### Community 21 - "package.json"
Cohesion: 0.07
Nodes (24): author, description, devDependencies, dotenv, supabase, tailwindcss, keywords, license (+16 more)

### Community 23 - "send"
Cohesion: 0.11
Nodes (26): _addToPushBuffer(), _cancelRefEvent(), _cancelTimeout(), _canPush(), destroy(), _fetchWithTimeout(), finally(), _getPayloadRecords() (+18 more)

### Community 24 - "_debug"
Cohesion: 0.14
Nodes (26): _autoRefreshTokenTick(), bn(), _callRefreshToken(), _debug(), delete(), _emitInitialSession(), fn(), _getSessionFromURL() (+18 more)

### Community 25 - "constructor"
Cohesion: 0.10
Nodes (26): cloneDeep(), constructor(), _handleTokenChanged(), _initializeOptions(), _initRealtimeClient(), _initSupabaseAuthClient(), inPendingSyncState(), _isClosed() (+18 more)

### Community 26 - "send"
Cohesion: 0.11
Nodes (26): _addToPushBuffer(), _cancelRefEvent(), _cancelTimeout(), _canPush(), destroy(), _fetchWithTimeout(), finally(), _getPayloadRecords() (+18 more)

### Community 27 - "_debug"
Cohesion: 0.14
Nodes (26): _autoRefreshTokenTick(), bn(), _callRefreshToken(), _debug(), delete(), _emitInitialSession(), fn(), _getSessionFromURL() (+18 more)

### Community 28 - "constructor"
Cohesion: 0.10
Nodes (26): cloneDeep(), constructor(), _handleTokenChanged(), _initializeOptions(), _initRealtimeClient(), _initSupabaseAuthClient(), inPendingSyncState(), _isClosed() (+18 more)

### Community 29 - "student.js"
Cohesion: 0.08
Nodes (3): getStudentAchievements(), getStudentDashboardStats(), getStudentStreak()

### Community 30 - "lessonplan-dnd.js"
Cohesion: 0.14
Nodes (23): allFiles, createProgressBar(), deleteFile(), deleteSelectedFiles(), editFilePrompt(), formatBytes(), formatDate(), getCurrentUser() (+15 more)

### Community 31 - "admin-content.js"
Cohesion: 0.11
Nodes (11): archiveModule(), archiveQuiz(), archiveVideo(), createLessonPlan(), filterContent(), getAllLessonPlans(), normalizeLessonPlanRow(), updateLessonPlan() (+3 more)

### Community 32 - "UI Styling Skill"
Cohesion: 0.08
Nodes (23): Accessibility Patterns, Alternative: Tailwind-Only Setup, Best Practices, Component Layer: shadcn/ui, Component Library Guide, Component + Styling Setup, Core Stack, Quick Start (+15 more)

### Community 33 - "Design"
Cohesion: 0.09
Nodes (22): Banner Design (Built-in), Banner: Workflow, CIP Design (Built-in), CIP: Generate Brief, CIP: Generate Mockups, CIP: Render HTML Presentation, Design, Icon Design (Built-in) (+14 more)

### Community 34 - "n"
Cohesion: 0.16
Nodes (22): an(), catch(), execute(), getPromise(), gr(), invoke(), ln(), n() (+14 more)

### Community 35 - "n"
Cohesion: 0.16
Nodes (22): an(), catch(), execute(), getPromise(), gr(), invoke(), ln(), n() (+14 more)

### Community 36 - "Domain Rules (Detailed)"
Cohesion: 0.10
Nodes (20): 1 � Architecture preservation, 2 � Role boundary enforcement, 3 � Supabase client usage, 4 � Environment variable discipline, 5 � Naming conventions, 6 � Database change safety, 7 � Deployment and production safety, 8 � Compatibility with static hosting (+12 more)

### Community 37 - "Admin Portal UI Inconsistencies Report"
Cohesion: 0.11
Nodes (18): 1. Sidebar Icon Discrepancy - Dashboard Page, 2. Sidebar Not Loading - Users Page, 3. Visual Distinctiveness - Content Management Pages, 4. Shared Components and CSS Issues, Admin Portal UI Inconsistencies Report, Fix Recommendation, Fix Recommendations, Fix Recommendations (+10 more)

### Community 38 - "Project Rules"
Cohesion: 0.11
Nodes (16): Agent Roles, Approval Gate, Architecture, Code, Commands, Completion, Data and Supabase, Mandatory Automatic State Protocol (Zero User Intervention) (+8 more)

### Community 39 - "Design System"
Cohesion: 0.11
Nodes (17): Best Practices, Chart.js Integration, Component Spec Pattern, Design System, Integration, Quick Start, References, Script Paths (+9 more)

### Community 40 - "Supabase"
Cohesion: 0.11
Nodes (15): Fix suggestion, Source, What happened, Skill Feedback, Steps, Core Principles, Debugging, Making and Committing Schema Changes (+7 more)

### Community 41 - "Changelog"
Cohesion: 0.12
Nodes (16): [1.2.0](https://github.com/supabase/agent-skills/compare/v1.1.1...v1.2.0) (2026-06-02), [1.3.0](https://github.com/supabase/agent-skills/compare/v1.2.0...v1.3.0) (2026-06-05), [1.4.0](https://github.com/supabase/agent-skills/compare/v1.3.0...v1.4.0) (2026-07-10), [1.5.0](https://github.com/supabase/agent-skills/compare/supabase-postgres-best-practices-v1.4.0...supabase-postgres-best-practices-v1.5.0) (2026-07-30), [1.6.0](https://github.com/supabase/agent-skills/compare/supabase-postgres-best-practices-v1.5.0...supabase-postgres-best-practices-v1.6.0) (2026-07-30), Bug Fixes, Bug Fixes, Bug Fixes (+8 more)

### Community 42 - "Changelog"
Cohesion: 0.12
Nodes (15): [0.1.3](https://github.com/supabase/agent-skills/compare/v0.1.2...v0.1.3) (2026-06-02), [0.1.4](https://github.com/supabase/agent-skills/compare/v0.1.3...v0.1.4) (2026-06-05), [0.1.5](https://github.com/supabase/agent-skills/compare/v0.1.4...v0.1.5) (2026-07-10), [0.1.6](https://github.com/supabase/agent-skills/compare/v0.1.5...supabase-v0.1.6) (2026-07-30), [0.1.7](https://github.com/supabase/agent-skills/compare/v0.1.6...supabase-v0.1.7) (2026-08-12), Bug Fixes, Bug Fixes, Bug Fixes (+7 more)

### Community 43 - "Writing Guidelines for Postgres References"
Cohesion: 0.12
Nodes (15): 1. Concrete Transformation Patterns, 2. Error-First Structure, 3. Quantified Impact, 4. Self-Contained Examples, 5. Semantic Naming, Code Example Standards, Comments, Impact Level Guidelines (+7 more)

### Community 44 - "UI/UX Pro Max - Design Intelligence"
Cohesion: 0.12
Nodes (15): Before Delivering App UI, If a search returns 0 results, Output Formats, Query Contract, Rule Categories by Priority, Running the Search Tool, Step 1: Analyze User Requirements, Step 2: Generate Design System (REQUIRED for new pages/projects) (+7 more)

### Community 46 - "teacher.js"
Cohesion: 0.16
Nodes (3): escText(), jsArg(), loadTeacherSections()

### Community 47 - "Summary of Changes"
Cohesion: 0.14
Nodes (13): 1. Sidebar Inconsistencies Fixed, 2. Content Management Pages Visual Distinctiveness, 3. Admin Portal Visual Identity, 4. Technical Improvements, 5. Admin Portal vs. Teacher Portal Comparison, Admin Portal Visual Distinctiveness Refactor Summary, Dashboard Page - Missing Icons, Key Changes: (+5 more)

### Community 48 - "Banner Design - Multi-Format Creative Banner System"
Cohesion: 0.14
Nodes (13): Art Direction Styles (Top 10), Available Resources, Banner Design - Multi-Format Creative Banner System, Banner Size Quick Reference, Design Rules, Security, Step 1: Gather Requirements, Step 2: Research & Art Direction (+5 more)

### Community 49 - "Incident and Rollback Guide"
Cohesion: 0.14
Nodes (14): A. Frontend Rollback, B. Database and Policy Rollback, C. Combined Rollback, Communication Template, Evidence Collection, Immediate Response, Incident and Rollback Guide, Incident Severity (+6 more)

### Community 50 - "API and Storage Conventions"
Cohesion: 0.17
Nodes (12): API and Storage Conventions, Data Access Conventions, Error Handling Conventions, Naming Conventions, Navigation, Object Paths, Recommended Implementation Follow-Up, Security Conventions (+4 more)

### Community 51 - "Migration Playbook"
Cohesion: 0.17
Nodes (12): Automation Recommendations, Change Logging Template, File Categories in database Folder, Migration Playbook, Navigation, Post-Migration Verification, Pre-Migration Checklist, Principles (+4 more)

### Community 52 - "public/shared/js/modules.js"
Cohesion: 0.20
Nodes (3): getModuleById(), isContentInStudentScope(), normalizeScopeGrade()

### Community 53 - "shared/js/modules.js"
Cohesion: 0.20
Nodes (3): getModuleById(), isContentInStudentScope(), normalizeScopeGrade()

### Community 54 - "Brand"
Cohesion: 0.18
Nodes (10): Brand, Brand Sync Workflow, Quick Start, References, Routing, Script Paths, Scripts, Subcommands (+2 more)

### Community 55 - "[1.0.0] - 2026-03-25"
Cohesion: 0.18
Nodes (11): [1.0.0] - 2026-03-25, Added, Added, Changed, Changed, Changelog, Fixed, Fixed (+3 more)

### Community 56 - "3A. UI Redesign Workstream (Requirements, Status, Decisions)"
Cohesion: 0.18
Nodes (11): 3A.10 Remaining UI Work and Recommended Sequence, 3A.1 UI Redesign Mandate and Scope, 3A.2 Visual Reference and Shared Design DNA, 3A.3 Role Identity and Semantic Color Mapping, 3A.4 Anti-patterns (do not carry forward), 3A.5 Portal-Specific Layout Requirements, 3A.6 Accessibility and Responsive Acceptance Criteria (all future UI phases), 3A.7 CSS / Component Isolation and Concurrent-Workspace Rules (+3 more)

### Community 57 - "encode"
Cohesion: 0.24
Nodes (11): _binaryDecode(), _binaryEncodeUserBroadcastPush(), decode(), _decodeUserBroadcast(), encode(), _encodeBinaryUserBroadcastPush(), _encodeJsonUserBroadcastPush(), _encodeUserBroadcastPush() (+3 more)

### Community 58 - "encode"
Cohesion: 0.24
Nodes (11): _binaryDecode(), _binaryEncodeUserBroadcastPush(), decode(), _decodeUserBroadcast(), encode(), _encodeBinaryUserBroadcastPush(), _encodeJsonUserBroadcastPush(), _encodeUserBroadcastPush() (+3 more)

### Community 59 - "Section Definitions"
Cohesion: 0.20
Nodes (9): 1. Query Performance (query), 2. Connection Management (conn), 3. Security & RLS (security), 4. Schema Design (schema), 5. Concurrency & Locking (lock), 6. Data Access Patterns (data), 7. Monitoring & Diagnostics (monitor), 8. Advanced Features (advanced) (+1 more)

### Community 60 - "Web Engineering Standard"
Cohesion: 0.20
Nodes (9): Automation Principle � when to just fix it, Human Decision Principle � when to stop and ask, Never do this, Reporting, Severity system, Step 0 � Always discover the project first, never assume it, Step 1 � Figure out the project stage and scope accordingly, Step 2 � Work the relevant phases (+1 more)

### Community 61 - "Environment Strategy"
Cohesion: 0.20
Nodes (10): Access Control and Secrets, Branch and Deploy Mapping, Configuration Strategy, Data Management, Environment Model, Environment Readiness Checklist, Environment Strategy, Navigation (+2 more)

### Community 62 - "public/shared/js/auth.js"
Cohesion: 0.27
Nodes (4): getBasePath(), logout(), redirectToDashboard(), redirectToLogin()

### Community 63 - "shared/js/auth.js"
Cohesion: 0.29
Nodes (4): getBasePath(), logout(), redirectToDashboard(), redirectToLogin()

### Community 65 - "Gate Enforcement — No Direct Implementation Without Explicit Approval"
Cohesion: 0.22
Nodes (8): 1. `council-plan` (Planning & Discovery), 2. `execute-approved-plan` (Implementation Execution), 3. `verify-delivery` (Independent Verification & Auditing), Autonomous State Ledger Exemption, Core Principle, Gate Enforcement — No Direct Implementation Without Explicit Approval, Role-Specific Strict Constraints, Tool Enforcement Summary

### Community 66 - "Production Readiness Checklist"
Cohesion: 0.22
Nodes (9): A. Planning and Scope, B. Database and Policy Readiness, C. Application Readiness, D. Environment and Config, E. Deployment and Monitoring, F. Documentation and Audit, Navigation, Production Readiness Checklist (+1 more)

### Community 67 - "QA Test Matrix"
Cohesion: 0.22
Nodes (9): Admin, Navigation, Public and Auth, QA Test Matrix, Security and Policy, Sign-Off Template, Student, Teacher (+1 more)

### Community 68 - "Contributor Quickstart"
Cohesion: 0.22
Nodes (9): 1. Prepare Local Environment, 2. Understand the Project Areas, 3. Read Core Docs Before Changing Logic, 4. Make Changes Safely, 5. Validate Before PR, 6. Release and Incident Awareness, Contributor Quickstart, Navigation (+1 more)

### Community 69 - "verify_phase3_authenticated_api.ps1"
Cohesion: 0.28
Nodes (4): Add-TestResult(), Invoke-SupabaseAuthSafe(), Mask-Email(), Test-Leakage()

### Community 70 - "Data Model Reference"
Cohesion: 0.25
Nodes (8): Core Entities, Data Model Reference, Navigation, Recommended Next Additions, Relationship Summary, Role and Access Notes, Schema Validation Checklist, Storage Model

### Community 71 - "Known Limitations"
Cohesion: 0.25
Nodes (8): Change Log for Limitations File, Known Limitations, Navigation, Operational Limitations, Prioritized Improvements, Product and UX Limitations, Security and Governance Limitations, Technical Limitations

### Community 72 - "MathTuro — Unified Project State & Session Handover Ledger"
Cohesion: 0.25
Nodes (7): 1. Quick Orientation: "Where We Left Off" (The 5-Day Memory), 2. Technical Snapshot & Golden Rules, 3. Master Phase Status Summary, Architecture, MathTuro — Unified Project State & Session Handover Ledger, Strict Invariants (Enforced for both Claude & Antigravity), 🎯 The Immediate Next Action (Do This First)

### Community 73 - "Docs Home"
Cohesion: 0.25
Nodes (8): Developer Path, Docs Home, Fast Start Paths, Full Documentation Index, Navigation, QA Path, Release Manager Path, Suggested Reading Order by Task

### Community 74 - "Release Process and Checklist"
Cohesion: 0.25
Nodes (8): Changelog Convention, Deployment Checklist, Navigation, Post-Release Checklist, Pre-Release Checklist, Release Flow, Release Process and Checklist, Versioning Guidance

### Community 76 - "Slides"
Cohesion: 0.29
Nodes (6): References (Knowledge Base), Routing, Script Paths, Slides, Subcommands, When to Use

### Community 77 - "Access Control Matrix"
Cohesion: 0.29
Nodes (7): Access Control Matrix, Entity Permissions, Navigation, Notes, Policy Design Rules, Storage Permissions, Validation Checklist

### Community 78 - "Architecture Diagram"
Cohesion: 0.29
Nodes (7): Architecture Diagram, Data Ownership Boundaries, Future Architecture Additions, High-Level Architecture, Navigation, Request Flow Example, Runtime Layers

### Community 79 - "student/assets/js/sidebar.js"
Cohesion: 0.48
Nodes (5): handleLogout(), initSidebar(), loadGradeSectionInfo(), loadSidebarUserInfo(), loadStreakCount()

### Community 80 - "lesson-plan-files.js"
Cohesion: 0.57
Nodes (6): deleteLessonPlanFile(), formatBytes(), formatDate(), getCurrentUser(), handleLessonPlanFileUpload(), loadLessonPlanFiles()

### Community 81 - "admin/assets/js/sidebar.js"
Cohesion: 0.53
Nodes (5): createAdminSidebar(), enhanceMobileDrawer(), ensureAdminIconStylesheet(), setFilesDropdownExpanded(), toggleFilesDropdown()

### Community 82 - "council-plan"
Cohesion: 0.33
Nodes (5): Constraints (planning-phase hard limits), council-plan, End condition, Trigger, Workflow

### Community 83 - "execute-approved-plan"
Cohesion: 0.33
Nodes (5): execute-approved-plan, Execution authorization, Hard gate, Never say, Workflow

### Community 84 - "Supabase Postgres Best Practices"
Cohesion: 0.33
Nodes (5): How to Use, References, Rule Categories by Priority, Supabase Postgres Best Practices, When to Apply

### Community 85 - "verify-delivery"
Cohesion: 0.33
Nodes (5): Constraints (verification hard limits), Output, Trigger, verify-delivery, Workflow

### Community 88 - "vercel.json"
Cohesion: 0.33
Nodes (5): buildCommand, headers, outputDirectory, rewrites, version

### Community 90 - "settings.json"
Cohesion: 0.50
Nodes (3): permissions, deny, $schema

## Knowledge Gaps
- **553 isolated node(s):** `$schema`, `deny`, `name`, `version`, `description` (+548 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 961 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **73 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `MathTuro Learning Management System` connect `MathTuro Learning Management System` to `docs/README.md`?**
  _High betweenness centrality (0.002) - this node is a cross-community bridge._
- **What connects `$schema`, `deny`, `name` to the rest of the system?**
  _553 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `public/shared/js/supabase-lib.js` be split into smaller, more focused modules?**
  _Cohesion score 0.023278236914600552 - nodes in this community are weakly interconnected._
- **Why does `API and Storage Conventions` connect `API and Storage Conventions` to `docs/README.md`?**
  _High betweenness centrality (0.001) - this node is a cross-community bridge._
- **Should `shared/js/supabase-lib.js` be split into smaller, more focused modules?**
  _Cohesion score 0.023278236914600552 - nodes in this community are weakly interconnected._
- **Should `J` be split into smaller, more focused modules?**
  _Cohesion score 0.07287784679089027 - nodes in this community are weakly interconnected._
- **Should `J` be split into smaller, more focused modules?**
  _Cohesion score 0.07287784679089027 - nodes in this community are weakly interconnected._