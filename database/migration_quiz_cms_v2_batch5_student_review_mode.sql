-- ============================================================================
-- MathTuro LMS — Quiz CMS v2 Batch 5
-- Migration: Student Post-Submission Review Mode & Feedback Controls (Clean & Hardened)
-- Target: Production (ynkzcybctsstpqxdoweq) on main branch
-- Author: Tycoon James Flores
-- Date: 2026-10-24
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. Schema Extensions: allow_review Flags
-- ----------------------------------------------------------------------------

-- Regular Formative Quizzes default to TRUE (instant learning feedback)
ALTER TABLE public.quizzes 
ADD COLUMN IF NOT EXISTS allow_review boolean NOT NULL DEFAULT true;

-- Pre/Post Assessments default to FALSE (tight diagnostic & gating test security)
ALTER TABLE public.module_assessments 
ADD COLUMN IF NOT EXISTS allow_review boolean NOT NULL DEFAULT false;

-- ----------------------------------------------------------------------------
-- 2. Secure Post-Submission Review Function: Regular Quizzes
-- ----------------------------------------------------------------------------
-- Returns full itemized review including correct answers and teacher explanations
-- only if the calling user owns the submission or is a teacher/admin,
-- and review is permitted by the quiz configuration.

CREATE OR REPLACE FUNCTION public.get_quiz_submission_review(p_submission_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_student_id uuid := auth.uid();
    v_sub record;
    v_quiz record;
    v_items jsonb;
BEGIN
    IF v_student_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required' USING ERRCODE = '42501';
    END IF;

    SELECT * INTO v_sub FROM public.quiz_submissions WHERE id = p_submission_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Submission not found' USING ERRCODE = 'P0002';
    END IF;

    -- Authorization check: student owns submission (user_id) OR caller is teacher/admin
    IF v_sub.user_id <> v_student_id AND NOT public.is_current_user_teacher_or_admin() THEN
        RAISE EXCEPTION 'Access denied to this quiz submission' USING ERRCODE = '42501';
    END IF;

    SELECT * INTO v_quiz FROM public.quizzes WHERE id = v_sub.quiz_id;
    -- Policy check: review enabled OR caller is teacher/admin
    IF COALESCE(v_quiz.allow_review, true) = false AND NOT public.is_current_user_teacher_or_admin() THEN
        RAISE EXCEPTION 'Answer review is disabled for this quiz' USING ERRCODE = '42501';
    END IF;

    SELECT jsonb_agg(
        jsonb_build_object(
            'question_id', q.id,
            'order_index', q.order_index,
            'part_label', q.part_label,
            'question_text', q.question_text,
            'question_type', q.question_type,
            'options', q.options,
            'student_answer', a.student_answer,
            'is_correct', a.is_correct,
            'points_awarded', a.points_awarded,
            'points_possible', q.points,
            'correct_answer', q.correct_answer,
            'explanation', q.explanation
        ) ORDER BY q.order_index ASC
    ) INTO v_items
    FROM public.quiz_attempt_answers a
    JOIN public.quiz_questions q ON q.id = a.question_id
    WHERE a.quiz_submission_id = p_submission_id;

    RETURN jsonb_build_object(
        'submission_id', p_submission_id,
        'quiz_id', v_sub.quiz_id,
        'quiz_title', v_quiz.title,
        'student_score', v_sub.student_score,
        'total_items', v_sub.total_items,
        'assessment_result', v_sub.assessment_result,
        'created_at', v_sub.created_at,
        'items', COALESCE(v_items, '[]'::jsonb)
    );
END;
$$;

-- ----------------------------------------------------------------------------
-- 3. Secure Post-Submission Review Function: Module Assessments
-- ----------------------------------------------------------------------------
-- Returns full itemized review including correct answers and teacher explanations
-- only if the calling user owns the attempt or is a teacher/admin,
-- and review is explicitly permitted by the assessment configuration.

CREATE OR REPLACE FUNCTION public.get_assessment_attempt_review(p_attempt_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_student_id uuid := auth.uid();
    v_attempt record;
    v_asmt record;
    v_items jsonb;
BEGIN
    IF v_student_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required' USING ERRCODE = '42501';
    END IF;

    SELECT * INTO v_attempt FROM public.module_assessment_attempts WHERE id = p_attempt_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Assessment attempt not found' USING ERRCODE = 'P0002';
    END IF;

    -- Authorization check: student owns attempt OR caller is teacher/admin
    IF v_attempt.student_id <> v_student_id AND NOT public.is_current_user_teacher_or_admin() THEN
        RAISE EXCEPTION 'Access denied to this assessment attempt' USING ERRCODE = '42501';
    END IF;

    SELECT * INTO v_asmt FROM public.module_assessments WHERE id = v_attempt.assessment_id;
    -- Policy check: review enabled OR caller is teacher/admin
    IF COALESCE(v_asmt.allow_review, false) = false AND NOT public.is_current_user_teacher_or_admin() THEN
        RAISE EXCEPTION 'Answer review is disabled for this assessment' USING ERRCODE = '42501';
    END IF;

    SELECT jsonb_agg(
        jsonb_build_object(
            'question_id', q.id,
            'order_index', q.order_index,
            'part_label', q.part_label,
            'question_text', q.question_text,
            'question_type', q.question_type,
            'options', q.options,
            'student_answer', a.student_answer,
            'is_correct', a.is_correct,
            'points_awarded', a.points_awarded,
            'points_possible', q.points,
            'correct_answer', q.correct_answer,
            'explanation', q.explanation
        ) ORDER BY q.order_index ASC
    ) INTO v_items
    FROM public.quiz_attempt_answers a
    JOIN public.quiz_questions q ON q.id = a.question_id
    WHERE a.assessment_attempt_id = p_attempt_id;

    RETURN jsonb_build_object(
        'attempt_id', p_attempt_id,
        'assessment_id', v_attempt.assessment_id,
        'assessment_title', v_asmt.title,
        'student_score', v_attempt.student_score,
        'total_items', v_attempt.total_items,
        'score_pct', v_attempt.score_pct,
        'assessment_result', v_attempt.assessment_result,
        'created_at', v_attempt.created_at,
        'items', COALESCE(v_items, '[]'::jsonb)
    );
END;
$$;

-- ----------------------------------------------------------------------------
-- 4. Grants & Execution Privileges
-- ----------------------------------------------------------------------------

REVOKE ALL ON FUNCTION public.get_quiz_submission_review(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_assessment_attempt_review(uuid) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.get_quiz_submission_review(uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_assessment_attempt_review(uuid) TO authenticated, service_role;

COMMIT;
