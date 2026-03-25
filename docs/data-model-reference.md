# Data Model Reference

## Navigation

- Docs Home: [README.md](README.md)
- Project README: [../README.md](../README.md)


This reference summarizes the core data model used by MathTuro.

Important:
- Source of truth is the SQL in the database folder.
- Table definitions can evolve through migration and fix scripts.

## Core Entities

1. users
- Purpose: stores user profile and role metadata tied to Supabase auth users.
- Key fields: id, email, full_name, role, created_at, updated_at.

2. modules
- Purpose: top-level learning units.
- Key fields: id, title, description, order, is_active, created_by, created_at, updated_at.

3. lessons
- Purpose: lesson items under modules.
- Key fields: id, module_id, title, content, order, video_url, quiz_url, is_active, created_by, created_at, updated_at.

4. quiz_submissions
- Purpose: stores student quiz submissions and review outcomes.
- Key fields: id, student_id, lesson_id, score, total_items, screenshot_url, status, teacher_comment, reviewed_by, reviewed_at, submitted_at.

5. lesson_progress
- Purpose: tracks completion status per student per lesson.
- Key fields: id, student_id, lesson_id, completed, completed_at.
- Constraint pattern: unique combination of student_id and lesson_id.

6. notifications
- Purpose: user-facing system notifications.
- Key fields: id, user_id, title, message, read, created_at.

7. activity_log
- Purpose: audit-style activity entries.
- Key fields: id, user_id, action, details, created_at.

## Relationship Summary

- users 1 to many modules via modules.created_by
- users 1 to many lessons via lessons.created_by
- modules 1 to many lessons via lessons.module_id
- users 1 to many quiz_submissions via quiz_submissions.student_id
- lessons 1 to many quiz_submissions via quiz_submissions.lesson_id
- users 1 to many lesson_progress via lesson_progress.student_id
- lessons 1 to many lesson_progress via lesson_progress.lesson_id
- users 1 to many notifications via notifications.user_id
- users 1 to many activity_log via activity_log.user_id

## Role and Access Notes

- role values are expected to include student, teacher, admin.
- RLS should enforce least privilege based on role and record ownership.

## Storage Model

Common buckets used by project scripts and docs:
- quiz-screenshots
- learning-materials

## Schema Validation Checklist

Use this checklist when setting up or upgrading environments:

1. Confirm all expected tables exist.
2. Confirm foreign keys are in place for ownership and hierarchy.
3. Confirm unique constraints for progress and similar dedupe-sensitive records.
4. Confirm indexes on common filter columns such as module_id, lesson_id, student_id, role, status.
5. Confirm RLS is enabled and policies are present.
6. Confirm storage buckets and policies are configured.

## Recommended Next Additions

- Export and include ER diagram generated from actual production schema.
- Document indexes and query performance notes.
- Add field-level descriptions for all columns with nullable rules.

---

**Previous:** [architecture-diagram.md](architecture-diagram.md) | **Next:** [api-storage-conventions.md](api-storage-conventions.md)
