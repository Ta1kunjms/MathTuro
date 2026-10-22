-- ============================================================================
-- Migration: Quiz CMS v2 Batch 1B Preparations
-- Project: MathTuro LMS (Production: ynkzcybctsstpqxdoweq)
-- Date: 2026-10-22
--
-- Scope:
--   1. Schema: ALTER TABLE public.quizzes ALTER COLUMN quiz_url DROP NOT NULL
--   2. Gate legacy paper assessment score RPC (submit_assessment_score):
--      - Renames existing implementation to submit_assessment_score_core
--      - Revokes execute on core function
--      - Wraps submit_assessment_score with access checks (can_student_access_pre_test /
--        can_student_access_post_test) and rejection of native questions
--   3. Update submit_regular_quiz_score wrapper:
--      - Rejects if quiz_url IS NULL (native quizzes) in addition to quiz_questions check
--
-- Invariants:
--   - Does NOT touch submit_and_grade_assessment or submit_and_grade_regular_quiz
--   - Does NOT touch *_core grading functions or Phase 3 / Phase 5 schemas
--   - Idempotent and safe to run multiple times
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. Schema: Allow quizzes without external URLs (Native Quiz CMS)
-- ----------------------------------------------------------------------------
ALTER TABLE public.quizzes ALTER COLUMN quiz_url DROP NOT NULL;

-- ----------------------------------------------------------------------------
-- 2. Gating Wrapper: submit_assessment_score (Paper score for formal assessments)
-- ----------------------------------------------------------------------------
DO $$
BEGIN
    IF to_regprocedure('public.submit_assessment_score_core(uuid, smallint, smallint)') IS NULL THEN
        IF to_regprocedure('public.submit_assessment_score(uuid, smallint, smallint)') IS NOT NULL THEN
            ALTER FUNCTION public.submit_assessment_score(uuid, smallint, smallint)
                RENAME TO submit_assessment_score_core;
        END IF;
    END IF;
END;
$$;

-- Revoke direct execution of core function
DO $$
BEGIN
    IF to_regprocedure('public.submit_assessment_score_core(uuid, smallint, smallint)') IS NOT NULL THEN
        REVOKE EXECUTE ON FUNCTION public.submit_assessment_score_core(uuid, smallint, smallint) FROM PUBLIC, anon, authenticated;
    END IF;
END;
$$;

-- Create gated public wrapper
CREATE OR REPLACE FUNCTION public.submit_assessment_score(
    p_assessment_id uuid,
    p_student_score smallint,
    p_total_items smallint
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_student_id uuid := auth.uid();
    v_asmt record;
    v_allowed boolean := false;
BEGIN
    IF v_student_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT a.id, a.module_id, a.assessment_type, a.is_published
    INTO v_asmt
    FROM public.module_assessments a
    WHERE a.id = p_assessment_id;

    IF NOT FOUND OR NOT v_asmt.is_published THEN
        RAISE EXCEPTION 'Assessment not found or not published';
    END IF;

    -- Check progression permission
    IF v_asmt.assessment_type = 'pre_test' THEN
        v_allowed := public.can_student_access_pre_test(v_student_id, p_assessment_id);
    ELSIF v_asmt.assessment_type = 'post_test' THEN
        v_allowed := public.can_student_access_post_test(v_student_id, p_assessment_id);
    END IF;

    IF NOT v_allowed THEN
        RAISE EXCEPTION 'Assessment access locked by module progression or unpublished';
    END IF;

    -- Rejection of native questions: native items must go through take-quiz server runner
    IF EXISTS (SELECT 1 FROM public.quiz_questions qq WHERE qq.assessment_id = p_assessment_id) THEN
        RAISE EXCEPTION 'This assessment is graded automatically; submit answers instead of a score';
    END IF;

    RETURN public.submit_assessment_score_core(p_assessment_id, p_student_score, p_total_items);
END;
$$;

REVOKE EXECUTE ON FUNCTION public.submit_assessment_score(uuid, smallint, smallint) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.submit_assessment_score(uuid, smallint, smallint) TO authenticated;

-- ----------------------------------------------------------------------------
-- 3. Update Wrapper: submit_regular_quiz_score
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.submit_regular_quiz_score(
    p_quiz_id uuid,
    p_score smallint,
    p_total smallint
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_quiz record;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    IF NOT public.can_student_access_quiz(auth.uid(), p_quiz_id) THEN
        RAISE EXCEPTION 'Quiz access locked by module progression or unpublished';
    END IF;

    SELECT q.total_items, q.quiz_url INTO v_quiz FROM public.quizzes q WHERE q.id = p_quiz_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Quiz not found';
    END IF;

    -- Natively authored quizzes (quiz_url is NULL or has quiz_questions) must go through server-side grading
    IF v_quiz.quiz_url IS NULL OR EXISTS (SELECT 1 FROM public.quiz_questions qq WHERE qq.quiz_id = p_quiz_id) THEN
        RAISE EXCEPTION 'This quiz is graded automatically; submit answers instead of a score';
    END IF;

    IF p_total IS DISTINCT FROM v_quiz.total_items THEN
        RAISE EXCEPTION 'Total items must match the quiz (%)', v_quiz.total_items;
    END IF;

    RETURN public.submit_regular_quiz_score_core(p_quiz_id, p_score, p_total);
END;
$$;

REVOKE EXECUTE ON FUNCTION public.submit_regular_quiz_score(uuid, smallint, smallint) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.submit_regular_quiz_score(uuid, smallint, smallint) TO authenticated;

COMMIT;

-- ============================================================================
-- VERIFICATION QUERIES (Read-Only)
-- Run these after the migration to verify schema and function grants
-- ============================================================================
-- 1. Verify quiz_url is nullable
-- SELECT column_name, is_nullable, data_type 
-- FROM information_schema.columns 
-- WHERE table_name = 'quizzes' AND column_name = 'quiz_url';
-- Expected: is_nullable = 'YES'
--
-- 2. Verify functions and core separation
-- SELECT routine_name, routine_type, security_type
-- FROM information_schema.routines
-- WHERE routine_name IN ('submit_assessment_score', 'submit_assessment_score_core', 'submit_regular_quiz_score', 'submit_regular_quiz_score_core')
--   AND routine_schema = 'public';
-- Expected: 4 functions, all SECURITY DEFINER
-- ============================================================================
