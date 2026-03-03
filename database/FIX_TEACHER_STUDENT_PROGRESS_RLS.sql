-- ============================================================
-- FIX: Teachers cannot see students in Student Progress
-- Run this once in Supabase SQL Editor
-- ============================================================

BEGIN;

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sections ENABLE ROW LEVEL SECURITY;

-- Break recursion on sections policies (old admin policy queried public.users)
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

NOTIFY pgrst, 'reload schema';

COMMIT;
