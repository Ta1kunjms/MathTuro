-- ============================================================
-- MIGRATION V9: STUDENT GRADE/SECTION SCOPE RLS HARDENING
-- Purpose:
-- - Enforce student visibility by grade/section in DB policies
-- - Block cross-section access even if frontend query is bypassed
-- Rules:
-- - Students can see published content in their own grade
-- - If student has section_id: content section must match OR be NULL (grade-wide)
-- - If student has no section_id: only content with NULL section_id
-- - Teacher/Admin policies are preserved
-- ============================================================

BEGIN;

-- ------------------------------
-- MODULES POLICIES
-- ------------------------------
DROP POLICY IF EXISTS "modules_read_published" ON public.modules;
DROP POLICY IF EXISTS "students_view_scoped_modules" ON public.modules;

CREATE POLICY "students_view_scoped_modules" ON public.modules
FOR SELECT USING (
    status = 'published'
    AND EXISTS (
        SELECT 1
        FROM public.users u
        WHERE u.id = auth.uid()
          AND u.role = 'student'
          AND (
            (
              modules.grade_level_id IS NOT NULL
              AND u.grade_level_id IS NOT NULL
              AND modules.grade_level_id = u.grade_level_id
            )
            OR (
              modules.grade_level_id IS NULL
              AND NULLIF(TRIM(modules.grade_level), '') IS NOT NULL
              AND (
                LOWER(REGEXP_REPLACE(NULLIF(TRIM(modules.grade_level), ''), '^grade\\s*', '', 'i'))
                =
                LOWER(REGEXP_REPLACE(COALESCE(NULLIF(TRIM(u.grade_level_text), ''), NULLIF(TRIM(u.grade_level), '')), '^grade\\s*', '', 'i'))
              )
            )
            OR (
              modules.grade_level_id IS NULL
              AND NULLIF(TRIM(modules.grade_level), '') IS NULL
            )
          )
          AND (
            (u.section_id IS NOT NULL AND (modules.section_id = u.section_id OR modules.section_id IS NULL))
            OR (u.section_id IS NULL AND modules.section_id IS NULL)
          )
    )
);

-- Keep teacher/admin access policies
-- (existing policies already present in setup scripts)

-- ------------------------------
-- VIDEOS POLICIES
-- ------------------------------
DROP POLICY IF EXISTS "anyone_view_published_videos" ON public.videos;
DROP POLICY IF EXISTS "students_view_scoped_videos" ON public.videos;

CREATE POLICY "students_view_scoped_videos" ON public.videos
FOR SELECT USING (
    is_published = true
    AND EXISTS (
        SELECT 1
        FROM public.users u
        WHERE u.id = auth.uid()
          AND u.role = 'student'
          AND (
            (
              videos.grade_level_id IS NOT NULL
              AND u.grade_level_id IS NOT NULL
              AND videos.grade_level_id = u.grade_level_id
            )
            OR (
              videos.grade_level_id IS NULL
              AND NULLIF(TRIM(videos.grade_level), '') IS NOT NULL
              AND (
                LOWER(REGEXP_REPLACE(NULLIF(TRIM(videos.grade_level), ''), '^grade\\s*', '', 'i'))
                =
                LOWER(REGEXP_REPLACE(COALESCE(NULLIF(TRIM(u.grade_level_text), ''), NULLIF(TRIM(u.grade_level), '')), '^grade\\s*', '', 'i'))
              )
            )
            OR (
              videos.grade_level_id IS NULL
              AND NULLIF(TRIM(videos.grade_level), '') IS NULL
            )
          )
          AND (
            (u.section_id IS NOT NULL AND (videos.section_id = u.section_id OR videos.section_id IS NULL))
            OR (u.section_id IS NULL AND videos.section_id IS NULL)
          )
    )
);

-- ------------------------------
-- QUIZZES POLICIES
-- ------------------------------
DROP POLICY IF EXISTS "anyone_view_published_quizzes" ON public.quizzes;
DROP POLICY IF EXISTS "students_view_scoped_quizzes" ON public.quizzes;

CREATE POLICY "students_view_scoped_quizzes" ON public.quizzes
FOR SELECT USING (
    is_published = true
    AND EXISTS (
        SELECT 1
        FROM public.users u
        WHERE u.id = auth.uid()
          AND u.role = 'student'
          AND (
            (
              quizzes.grade_level_id IS NOT NULL
              AND u.grade_level_id IS NOT NULL
              AND quizzes.grade_level_id = u.grade_level_id
            )
            OR (
              quizzes.grade_level_id IS NULL
              AND NULLIF(TRIM(quizzes.grade_level), '') IS NOT NULL
              AND (
                LOWER(REGEXP_REPLACE(NULLIF(TRIM(quizzes.grade_level), ''), '^grade\\s*', '', 'i'))
                =
                LOWER(REGEXP_REPLACE(COALESCE(NULLIF(TRIM(u.grade_level_text), ''), NULLIF(TRIM(u.grade_level), '')), '^grade\\s*', '', 'i'))
              )
            )
            OR (
              quizzes.grade_level_id IS NULL
              AND NULLIF(TRIM(quizzes.grade_level), '') IS NULL
            )
          )
          AND (
            (u.section_id IS NOT NULL AND (quizzes.section_id = u.section_id OR quizzes.section_id IS NULL))
            OR (u.section_id IS NULL AND quizzes.section_id IS NULL)
          )
    )
);

COMMIT;
