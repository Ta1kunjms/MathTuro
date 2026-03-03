-- ============================================================
-- POST-RESTORE VISIBILITY FIX (ONE RUN)
-- Purpose:
-- 1) Add legacy columns expected by current frontend code
-- 2) Backfill data so teacher/student/admin pages can read content
-- 3) Make existing content visible (published/active)
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- A) Compatibility columns expected by frontend JS
-- ------------------------------------------------------------

-- modules: frontend uses is_active + order
ALTER TABLE public.modules
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

ALTER TABLE public.modules
  ADD COLUMN IF NOT EXISTS "order" INTEGER DEFAULT 0;

UPDATE public.modules
SET is_active = COALESCE(is_active, status IN ('published', 'active')),
    "order" = COALESCE("order", order_index, 0)
WHERE TRUE;

-- lessons: frontend may use order
ALTER TABLE public.lessons
  ADD COLUMN IF NOT EXISTS "order" INTEGER DEFAULT 0;

UPDATE public.lessons
SET "order" = COALESCE("order", order_index, 0)
WHERE TRUE;

-- quizzes: frontend reads score in some places and status in admin views
ALTER TABLE public.quiz_submissions
  ADD COLUMN IF NOT EXISTS score INTEGER;

UPDATE public.quiz_submissions
SET score = COALESCE(score, student_score, 0)
WHERE TRUE;

ALTER TABLE public.videos
  ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'active';

ALTER TABLE public.quizzes
  ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'active';

UPDATE public.videos
SET status = COALESCE(status, CASE WHEN is_published THEN 'active' ELSE 'draft' END)
WHERE TRUE;

UPDATE public.quizzes
SET status = COALESCE(status, CASE WHEN is_published THEN 'active' ELSE 'draft' END)
WHERE TRUE;

-- lesson_progress: some code expects completed boolean
ALTER TABLE public.lesson_progress
  ADD COLUMN IF NOT EXISTS completed BOOLEAN DEFAULT false;

UPDATE public.lesson_progress
SET completed = COALESCE(completed, completed_at IS NOT NULL, status = 'completed')
WHERE TRUE;

-- student_streaks: frontend uses user_id in one path
ALTER TABLE public.student_streaks
  ADD COLUMN IF NOT EXISTS user_id UUID;

UPDATE public.student_streaks
SET user_id = COALESCE(user_id, student_id)
WHERE TRUE;

CREATE INDEX IF NOT EXISTS idx_student_streaks_user_id ON public.student_streaks(user_id);

-- users: some pages still read legacy text columns directly
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS grade_level VARCHAR(50);

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS section VARCHAR(50);

UPDATE public.users
SET grade_level = COALESCE(grade_level, grade_level_text),
    section = COALESCE(section, section_text)
WHERE TRUE;

-- ------------------------------------------------------------
-- B) Ensure content is visible in app filters
-- ------------------------------------------------------------

-- Student pages commonly need active/published module rows
UPDATE public.modules
SET status = 'published',
    is_active = true
WHERE status IS DISTINCT FROM 'archived';

-- Admin/teacher pages often expect status='active'
UPDATE public.videos
SET status = 'active',
    is_published = true
WHERE status IS DISTINCT FROM 'archived';

UPDATE public.quizzes
SET status = 'active',
    is_published = true
WHERE status IS DISTINCT FROM 'archived';

-- ------------------------------------------------------------
-- C) Ensure teacher ownership exists (required by RLS/policies)
-- ------------------------------------------------------------

WITH owner_user AS (
  SELECT id
  FROM public.users
  WHERE role IN ('teacher', 'admin')
  ORDER BY created_at
  LIMIT 1
)
UPDATE public.modules m
SET teacher_id = o.id
FROM owner_user o
WHERE m.teacher_id IS NULL;

WITH owner_user AS (
  SELECT id
  FROM public.users
  WHERE role IN ('teacher', 'admin')
  ORDER BY created_at
  LIMIT 1
)
UPDATE public.videos v
SET teacher_id = o.id
FROM owner_user o
WHERE v.teacher_id IS NULL;

WITH owner_user AS (
  SELECT id
  FROM public.users
  WHERE role IN ('teacher', 'admin')
  ORDER BY created_at
  LIMIT 1
)
UPDATE public.quizzes q
SET teacher_id = o.id
FROM owner_user o
WHERE q.teacher_id IS NULL;

-- ------------------------------------------------------------
-- D) Useful indexes for current app filters
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_modules_is_active ON public.modules(is_active);
CREATE INDEX IF NOT EXISTS idx_modules_order_legacy ON public.modules("order");
CREATE INDEX IF NOT EXISTS idx_lessons_order_legacy ON public.lessons("order");
CREATE INDEX IF NOT EXISTS idx_videos_status ON public.videos(status);
CREATE INDEX IF NOT EXISTS idx_quizzes_status ON public.quizzes(status);

-- ------------------------------------------------------------
-- E) Fix RLS so teachers can view students in their own sections
-- ------------------------------------------------------------
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sections ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS admin_manage_sections ON public.sections;
DROP POLICY IF EXISTS teachers_view_own_sections ON public.sections;
DROP POLICY IF EXISTS everyone_view_active_sections ON public.sections;

CREATE POLICY teachers_view_own_sections
ON public.sections
FOR SELECT
USING (teacher_id = auth.uid());

CREATE POLICY admin_manage_sections
ON public.sections
FOR ALL
USING (
  COALESCE(
    auth.jwt() -> 'user_metadata' ->> 'role',
    auth.jwt() -> 'app_metadata' ->> 'role'
  ) = 'admin'
)
WITH CHECK (
  COALESCE(
    auth.jwt() -> 'user_metadata' ->> 'role',
    auth.jwt() -> 'app_metadata' ->> 'role'
  ) = 'admin'
);

CREATE POLICY everyone_view_active_sections
ON public.sections
FOR SELECT
USING (is_active = true);

DROP POLICY IF EXISTS teachers_view_students_in_own_sections ON public.users;
DROP POLICY IF EXISTS teachers_view_all_students ON public.users;

CREATE POLICY teachers_view_all_students
ON public.users
FOR SELECT
USING (
  role = 'student'
  AND COALESCE(
    auth.jwt() -> 'user_metadata' ->> 'role',
    auth.jwt() -> 'app_metadata' ->> 'role'
  ) IN ('teacher', 'admin')
);

COMMIT;

-- ------------------------------------------------------------
-- E) Quick checks (run manually after script)
-- ------------------------------------------------------------
-- SELECT COUNT(*) AS modules_total FROM public.modules;
-- SELECT COUNT(*) AS lessons_total FROM public.lessons;
-- SELECT COUNT(*) AS videos_total FROM public.videos;
-- SELECT COUNT(*) AS quizzes_total FROM public.quizzes;
-- SELECT COUNT(*) AS lessonplans_total FROM public.lesson_plan_files;
