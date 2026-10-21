-- ============================================================================
-- MathTuro — Client additions: Lesson Objectives, Term backfill, Admin EXP
-- leaderboard.
--
-- Run once in the PRODUCTION SQL Editor (ynkzcybctsstpqxdoweq). Idempotent:
-- safe to re-run. Non-destructive: adds one nullable column, fills
-- term_number from the existing quarter value, and adds one new function.
-- It does NOT replace any existing function, so it cannot regress the gated
-- grading wrappers (unlike a re-run of the Phase 3/5 migrations).
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. Lesson Objectives on modules (teacher-entered, one objective per line)
-- ----------------------------------------------------------------------------
ALTER TABLE public.modules
    ADD COLUMN IF NOT EXISTS lesson_objectives text;

-- ----------------------------------------------------------------------------
-- 2. DepEd Terms: backfill modules.term_number from the legacy quarter value
--    Q1 -> Term 1, Q2 -> Term 2, Q3 and Q4 -> Term 3 (approved mapping).
--    Rows without a usable quarter keep their current term_number.
--    term_number / week_number columns already exist (Phase 3 migration).
-- ----------------------------------------------------------------------------
UPDATE public.modules
SET term_number = CASE
        WHEN quarter::text ~ '^[0-9]+$' AND quarter::text::int = 1 THEN 1
        WHEN quarter::text ~ '^[0-9]+$' AND quarter::text::int = 2 THEN 2
        WHEN quarter::text ~ '^[0-9]+$' AND quarter::text::int IN (3, 4) THEN 3
        ELSE term_number
    END
WHERE quarter IS NOT NULL;

-- ----------------------------------------------------------------------------
-- 3. Admin EXP leaderboard
--    System-wide ranking for admins only, with optional grade/section filters.
--    Admin check is server-side (is_current_user_admin()); non-admins get an
--    exception, not an empty list, so a UI bug can't silently hide misuse.
--    Reads the internal student_exp_summary view (no client SELECT grant).
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_admin_exp_leaderboard(
    p_grade_level_id uuid DEFAULT NULL,
    p_section_id     uuid DEFAULT NULL
)
RETURNS TABLE (
    rank               integer,
    student_id         uuid,
    full_name          text,
    lrn                text,
    grade_level        text,
    section            text,
    total_exp          integer,
    sources_completed  integer
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    IF NOT public.is_current_user_admin() THEN
        RAISE EXCEPTION 'Only admins can view the EXP leaderboard'
            USING ERRCODE = '42501';
    END IF;

    RETURN QUERY
    SELECT
        ROW_NUMBER() OVER (ORDER BY COALESCE(s.total_exp, 0) DESC, u.full_name ASC)::integer AS rank,
        u.id AS student_id,
        u.full_name::text AS full_name,
        u.lrn::text AS lrn,
        COALESCE(g.name, u.grade_level_text)::text AS grade_level,
        COALESCE(sec.name, u.section_text)::text AS section,
        COALESCE(s.total_exp, 0)::integer AS total_exp,
        COALESCE(s.sources_completed, 0)::integer AS sources_completed
    FROM public.users u
    LEFT JOIN public.student_exp_summary s ON s.student_id = u.id
    LEFT JOIN public.grade_levels g ON g.id = u.grade_level_id
    LEFT JOIN public.sections sec ON sec.id = u.section_id
    WHERE u.role = 'student'
      AND u.is_archived = false
      AND u.approval_status = 'approved'
      AND (p_grade_level_id IS NULL OR u.grade_level_id = p_grade_level_id)
      AND (p_section_id IS NULL OR u.section_id = p_section_id)
    ORDER BY COALESCE(s.total_exp, 0) DESC, u.full_name ASC;
END;
$$;

REVOKE ALL ON FUNCTION public.get_admin_exp_leaderboard(uuid, uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_admin_exp_leaderboard(uuid, uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.get_admin_exp_leaderboard(uuid, uuid) TO authenticated;

COMMIT;

-- ----------------------------------------------------------------------------
-- Read-only checks to run after the migration (expected results in comments)
-- ----------------------------------------------------------------------------
-- 1) Column exists → 1 row
-- SELECT column_name FROM information_schema.columns
--  WHERE table_schema = 'public' AND table_name = 'modules' AND column_name = 'lesson_objectives';
--
-- 2) No module left with quarter 4 mapped anywhere but Term 3 → 0
-- SELECT count(*) FROM public.modules WHERE quarter::text = '4' AND term_number <> 3;
--
-- 3) Function exists, anon cannot run it → anon_exec = false, auth_exec = true
-- SELECT has_function_privilege('anon', 'public.get_admin_exp_leaderboard(uuid, uuid)', 'EXECUTE') AS anon_exec,
--        has_function_privilege('authenticated', 'public.get_admin_exp_leaderboard(uuid, uuid)', 'EXECUTE') AS auth_exec;
