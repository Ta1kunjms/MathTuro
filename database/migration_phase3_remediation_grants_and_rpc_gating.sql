-- ============================================================================
-- Migration: Phase 3 Remediation — Table Grants, Assessment Question RPC Fix,
--                                   Submission-Path Progression Gating
-- Project: MathTuro LMS (Staging: jlmdvcmdvkvdxpfkqivh)
-- Applied to staging manually via SQL Editor on 2026-10-20; verified by
-- scripts/qa/verify_phase3_authenticated_api.ps1 (40/40 PASS).
--
-- Run AFTER migration_phase5_exp_gamification_and_leaderboard.sql.
-- If phase 3 or phase 5 is re-run later, it will CREATE OR REPLACE the
-- ungated submit_* functions over the wrappers below: re-run this file after.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Table-level grants (RLS policies still decide which rows each role sees)
-- ----------------------------------------------------------------------------
GRANT SELECT, INSERT, UPDATE, DELETE
    ON public.module_assessments, public.presentations, public.quiz_questions
    TO authenticated;

-- Attempts are written only by SECURITY DEFINER RPCs; clients need read access
GRANT SELECT ON public.module_assessment_attempts, public.quiz_attempt_answers TO authenticated;

-- ----------------------------------------------------------------------------
-- 2. get_assessment_questions_for_student: qualify "id" (was 42702 ambiguous
--    against the RETURNS TABLE output column)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_assessment_questions_for_student(
    p_assessment_id uuid
)
RETURNS TABLE (
    id uuid,
    order_index smallint,
    question_text text,
    question_type varchar(20),
    options jsonb,
    points smallint
)
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

    SELECT ma.* INTO v_asmt
    FROM public.module_assessments ma
    WHERE ma.id = p_assessment_id AND ma.is_published = true;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Assessment not found or unpublished';
    END IF;

    IF v_asmt.assessment_type = 'pre_test' THEN
        v_allowed := public.can_student_access_pre_test(v_student_id, p_assessment_id);
    ELSIF v_asmt.assessment_type = 'post_test' THEN
        v_allowed := public.can_student_access_post_test(v_student_id, p_assessment_id);
    END IF;

    IF NOT v_allowed THEN
        RAISE EXCEPTION 'Assessment locked by module progression';
    END IF;

    RETURN QUERY
    SELECT
        qq.id,
        qq.order_index,
        qq.question_text,
        qq.question_type,
        qq.options,
        qq.points
    FROM public.quiz_questions qq
    WHERE qq.assessment_id = p_assessment_id
    ORDER BY qq.order_index ASC;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.get_assessment_questions_for_student(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_assessment_questions_for_student(uuid) TO authenticated;

-- ----------------------------------------------------------------------------
-- 3. Submission-path gating: keep existing grading logic as *_core (not
--    callable by clients) and expose gated wrappers under the original names
-- ----------------------------------------------------------------------------
DO $$
BEGIN
    IF to_regprocedure('public.submit_and_grade_assessment_core(uuid, jsonb)') IS NULL THEN
        ALTER FUNCTION public.submit_and_grade_assessment(uuid, jsonb)
            RENAME TO submit_and_grade_assessment_core;
    END IF;

    IF to_regprocedure('public.submit_and_grade_regular_quiz_core(uuid, jsonb)') IS NULL THEN
        ALTER FUNCTION public.submit_and_grade_regular_quiz(uuid, jsonb)
            RENAME TO submit_and_grade_regular_quiz_core;
    END IF;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.submit_and_grade_assessment_core(uuid, jsonb) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.submit_and_grade_regular_quiz_core(uuid, jsonb) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.submit_and_grade_assessment(
    p_assessment_id uuid,
    p_answers jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_type varchar(10);
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT ma.assessment_type INTO v_type
    FROM public.module_assessments ma
    WHERE ma.id = p_assessment_id;

    IF (v_type = 'pre_test'  AND NOT public.can_student_access_pre_test(auth.uid(), p_assessment_id))
    OR (v_type = 'post_test' AND NOT public.can_student_access_post_test(auth.uid(), p_assessment_id)) THEN
        RAISE EXCEPTION 'Assessment locked by module progression';
    END IF;

    RETURN public.submit_and_grade_assessment_core(p_assessment_id, p_answers);
END;
$$;

REVOKE EXECUTE ON FUNCTION public.submit_and_grade_assessment(uuid, jsonb) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.submit_and_grade_assessment(uuid, jsonb) TO authenticated;

CREATE OR REPLACE FUNCTION public.submit_and_grade_regular_quiz(
    p_quiz_id uuid,
    p_answers jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    IF NOT public.can_student_access_quiz(auth.uid(), p_quiz_id) THEN
        RAISE EXCEPTION 'Quiz access locked by module progression or unpublished';
    END IF;

    RETURN public.submit_and_grade_regular_quiz_core(p_quiz_id, p_answers);
END;
$$;

REVOKE EXECUTE ON FUNCTION public.submit_and_grade_regular_quiz(uuid, jsonb) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.submit_and_grade_regular_quiz(uuid, jsonb) TO authenticated;
