# QA Test Matrix

## Navigation

- Docs Home: [README.md](README.md)
- Project README: [../README.md](../README.md)


Use this matrix for manual regression before releases.

## Test Scope

- Public and auth flows
- Student learning flows
- Teacher management and review flows
- Admin governance flows
- Supabase data and policy behavior

## Public and Auth

| ID | Area | Scenario | Expected Result |
|---|---|---|---|
| PUB-01 | Landing | Open public home page | Page loads without console errors |
| PUB-02 | Register | Register a new account | Account created and redirected correctly |
| PUB-03 | Login | Login with valid credentials | Session established and role route works |
| PUB-04 | Login | Login with invalid credentials | Clear validation error displayed |
| PUB-05 | Reset | Request password reset | Reset flow completes without app crash |

## Student

| ID | Area | Scenario | Expected Result |
|---|---|---|---|
| STU-01 | Dashboard | Open student dashboard | Data loads and cards render correctly |
| STU-02 | Modules | Open modules list | Visible modules match role and filters |
| STU-03 | Module View | Open module details | Lesson list and metadata load correctly |
| STU-04 | Lesson View | Open lesson content | Content, media, and actions function |
| STU-05 | Quiz | Submit quiz attempt | Submission persisted and status visible |
| STU-06 | Progress | Mark lesson progress | Progress reflects in UI and database |

## Teacher

| ID | Area | Scenario | Expected Result |
|---|---|---|---|
| TCH-01 | Dashboard | Open teacher dashboard | Summary metrics load |
| TCH-02 | Modules | Create or edit module | Changes persist and display correctly |
| TCH-03 | Quizzes | Manage quiz-linked data | Correct update behavior |
| TCH-04 | Videos | Manage video resources | Upload or links remain accessible |
| TCH-05 | Submissions | Approve or reject submission | Status updates and comments persist |
| TCH-06 | Reports | Open reports and progress pages | Data loads without role violations |

## Admin

| ID | Area | Scenario | Expected Result |
|---|---|---|---|
| ADM-01 | Login | Admin login flow | Access granted only to admin role |
| ADM-02 | Users | Create or update user role | Changes persist and are reflected |
| ADM-03 | Analytics | Open analytics page | Charts and summaries load |
| ADM-04 | Settings | Update system setting | Setting persists and takes effect |
| ADM-05 | Sections and Grades | Open and manage grade-section pages | Data operations succeed |
| ADM-06 | Activity | Review activity page | Audit entries are visible and scoped |

## Security and Policy

| ID | Area | Scenario | Expected Result |
|---|---|---|---|
| SEC-01 | RLS | Student reads another student private data | Access denied |
| SEC-02 | RLS | Teacher manages allowed content records | Access allowed |
| SEC-03 | RLS | Non-admin attempts admin-only action | Access denied |
| SEC-04 | Storage | Upload invalid type | Rejected by validation and policy |
| SEC-05 | Storage | Upload valid file | Upload succeeds and retrieval rules apply |

## Sign-Off Template

- Build or commit:
- Environment:
- Test date:
- Tester:
- Passed cases:
- Failed cases:
- Blocking issues:
- Final recommendation:

---

**Previous:** [environment-strategy.md](environment-strategy.md) | **Next:** [production-readiness-checklist.md](production-readiness-checklist.md)
