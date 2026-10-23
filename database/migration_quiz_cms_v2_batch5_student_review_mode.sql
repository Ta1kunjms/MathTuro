-- ============================================================================
-- MathTuro LMS — Quiz CMS v2 Batch 5
-- Migration: Student Post-Submission Review Mode & Feedback Controls
-- Environment: Production (ynkzcybctsstpqxdoweq) on main branch
-- Author: Tycoon James Flores
-- Date: 2026-10-23
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. Schema Extensions: allow_review Flags
-- ----------------------------------------------------------------------------

-- Regular Formative Quizzes default to TRUE (instant educational feedback)
ALTER TABLE public.quizzes 
ADD COLUMN IF NOT EXISTS allow_review boolean NOT NULL DEFAULT true;

-- Pre/Post Assessments default to FALSE (security for diagnostic/gating tests)
ALTER TABLE public.module_assessments 
ADD COLUMN IF NOT EXISTS allow_review boolean NOT NULL DEFAULT false;

-- ----------------------------------------------------------------------------
-- 2. Secure Post-Submission Review Function: Regular Quizzes
-- ----------------------------------------------------------------------------

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

    -- Authorization check: student owns submission OR caller is teacher/admin
    IF v_sub.student_id <> v_student_id AND NOT public.is_current_user_teacher_or_admin() THEN
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
        'created_at', v_sub.created_at,
        'items', COALESCE(v_items, '[]'::jsonb)
    );
END;
$$;

-- ----------------------------------------------------------------------------
-- 3. Secure Post-Submission Review Function: Module Assessments
-- ----------------------------------------------------------------------------

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
        'score', v_attempt.score,
        'total_items', v_attempt.total_items,
        'percentage', v_attempt.percentage,
        'assessment_result', v_attempt.assessment_result,
        'created_at', v_attempt.created_at,
        'items', COALESCE(v_items, '[]'::jsonb)
    );
END;
$$;

-- ----------------------------------------------------------------------------
-- 4. Update Core Grading Engines to Return attempt/submission IDs & allow_review
-- ----------------------------------------------------------------------------

-- Assessment Core
CREATE OR REPLACE FUNCTION public.submit_and_grade_assessment_core(
    p_assessment_id uuid,
    p_answers jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_student_id uuid := auth.uid();
    v_asmt record;
    v_existing_attempts smallint;
    v_has_passed boolean;
    v_new_attempt_number smallint;
    v_total_questions integer;
    v_total_possible_score smallint := 0;
    v_earned_score smallint := 0;
    v_score_pct numeric(5,2);
    v_is_passing boolean;
    v_verification_status varchar(20);
    v_assessment_result varchar(20);
    v_status varchar(50);
    v_remaining_attempts smallint;
    v_attempt_id uuid;
    v_q record;
    v_student_answer text;
    v_is_correct boolean;
    v_points_awarded smallint;
BEGIN
    SELECT * INTO v_asmt FROM public.module_assessments WHERE id = p_assessment_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Assessment not found' USING ERRCODE = 'P0002';
    END IF;

    SELECT
        COUNT(*)::smallint,
        COALESCE(BOOL_OR(assessment_result = 'passed'), false)
    INTO v_existing_attempts, v_has_passed
    FROM public.module_assessment_attempts
    WHERE assessment_id = p_assessment_id AND student_id = v_student_id;

    IF v_asmt.assessment_type = 'post_test' THEN
        IF v_has_passed THEN
            RAISE EXCEPTION 'Post-test already passed for this module' USING ERRCODE = 'P0001';
        END IF;
        IF v_existing_attempts >= 3 THEN
            RAISE EXCEPTION 'Maximum attempts (3) already reached for this post-test' USING ERRCODE = 'P0001';
        END IF;
    ELSIF v_asmt.assessment_type = 'pre_test' THEN
        IF v_existing_attempts >= 1 THEN
            RAISE EXCEPTION 'Pre-test already taken for this module' USING ERRCODE = 'P0001';
        END IF;
    END IF;

    SELECT COUNT(*), COALESCE(SUM(points), 0)
    INTO v_total_questions, v_total_possible_score
    FROM public.quiz_questions
    WHERE assessment_id = p_assessment_id;

    IF v_total_questions = 0 THEN
        RAISE EXCEPTION 'Assessment has no questions configured' USING ERRCODE = 'P0001';
    END IF;

    IF jsonb_array_length(p_answers) <> v_total_questions THEN
        RAISE EXCEPTION 'Answer count (%) does not match question count (%)',
            jsonb_array_length(p_answers), v_total_questions
            USING ERRCODE = 'P0001';
    END IF;

    v_new_attempt_number := v_existing_attempts + 1;

    INSERT INTO public.module_assessment_attempts (
        assessment_id,
        student_id,
        attempt_number,
        score,
        total_items,
        percentage,
        verification_status,
        assessment_result,
        is_latest_attempt,
        created_at
    ) VALUES (
        p_assessment_id,
        v_student_id,
        v_new_attempt_number,
        0,
        v_total_possible_score,
        0.00,
        'pending',
        'incomplete',
        true,
        now()
    )
    RETURNING id INTO v_attempt_id;

    FOR v_q IN
        SELECT id, question_type, options, correct_answer, points, numeric_tolerance
        FROM public.quiz_questions
        WHERE assessment_id = p_assessment_id
        ORDER BY order_index ASC
    LOOP
        SELECT a->>'answer' INTO v_student_answer
        FROM jsonb_array_elements(p_answers) a
        WHERE (a->>'question_id')::uuid = v_q.id;

        IF v_student_answer IS NULL THEN
            RAISE EXCEPTION 'Missing answer for question id %', v_q.id
                USING ERRCODE = 'P0001';
        END IF;

        IF v_q.question_type IN ('multiple_choice', 'true_false') THEN
            v_is_correct := (UPPER(TRIM(v_student_answer)) = UPPER(TRIM(v_q.correct_answer)));
        ELSIF v_q.question_type IN ('identification', 'fill_in_blank') THEN
            v_is_correct := EXISTS (
                SELECT 1
                FROM unnest(string_to_array(LOWER(TRIM(v_q.correct_answer)), '|')) AS ans
                WHERE TRIM(ans) = LOWER(TRIM(v_student_answer))
            );
        ELSIF v_q.question_type = 'numeric' THEN
            IF TRIM(v_student_answer) ~ '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$' THEN
                v_is_correct := (
                    ABS(TRIM(v_student_answer)::numeric - v_q.correct_answer::numeric) 
                    <= COALESCE(v_q.numeric_tolerance, 0)
                );
            ELSE
                v_is_correct := false;
            END IF;
        ELSE
            v_is_correct := false;
        END IF;

        IF v_is_correct THEN
            v_points_awarded := v_q.points;
            v_earned_score := v_earned_score + v_points_awarded;
        ELSE
            v_points_awarded := 0;
        END IF;

        INSERT INTO public.quiz_attempt_answers (
            assessment_attempt_id,
            question_id,
            student_answer,
            is_correct,
            points_awarded
        ) VALUES (
            v_attempt_id,
            v_q.id,
            TRIM(v_student_answer),
            v_is_correct,
            v_points_awarded
        );
    END LOOP;

    v_score_pct := ROUND((v_earned_score::numeric / v_total_possible_score::numeric) * 100, 2);
    v_is_passing := (v_score_pct >= v_asmt.passing_threshold);

    IF v_asmt.assessment_type = 'post_test' THEN
        IF v_is_passing THEN
            v_verification_status := 'verified';
            v_assessment_result := 'passed';
            v_status := 'Passed';
            v_remaining_attempts := 0;
        ELSE
            IF v_new_attempt_number < 3 THEN
                v_verification_status := 'verified';
                v_assessment_result := 'incomplete';
                v_status := 'Incomplete';
                v_remaining_attempts := 3 - v_new_attempt_number;
            ELSE
                v_verification_status := 'verified';
                v_assessment_result := 'failed';
                v_status := 'Failed';
                v_remaining_attempts := 0;
            END IF;
        END IF;
    ELSE
        v_verification_status := 'verified';
        v_assessment_result := CASE WHEN v_is_passing THEN 'passed' ELSE 'incomplete' END;
        v_status := CASE WHEN v_is_passing THEN 'Completed' ELSE 'Needs Practice' END;
        v_remaining_attempts := 0;
    END IF;

    UPDATE public.module_assessment_attempts
    SET score = v_earned_score,
        total_items = v_total_possible_score,
        percentage = v_score_pct,
        verification_status = v_verification_status,
        assessment_result = v_assessment_result
    WHERE id = v_attempt_id;

    -- EXP Award
    PERFORM public.award_exp_if_first_completion(v_student_id, v_asmt.assessment_type, p_assessment_id, v_earned_score);

    RETURN jsonb_build_object(
        'attempt_id', v_attempt_id,
        'allow_review', COALESCE(v_asmt.allow_review, false),
        'score', v_earned_score,
        'total_items', v_total_possible_score,
        'percentage', v_score_pct,
        'is_passing', v_is_passing,
        'status', v_status,
        'remaining_attempts', v_remaining_attempts
    );
END;
$$;

-- Regular Quiz Core
CREATE OR REPLACE FUNCTION public.submit_and_grade_regular_quiz_core(
    p_quiz_id uuid,
    p_answers jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_student_id uuid := auth.uid();
    v_quiz record;
    v_existing_attempts smallint;
    v_has_passed boolean;
    v_new_attempt_number smallint;
    v_total_questions integer;
    v_total_possible_score smallint := 0;
    v_earned_score smallint := 0;
    v_score_pct numeric(5,2);
    v_is_passing boolean;
    v_assessment_result varchar(20);
    v_status varchar(50);
    v_remaining_attempts smallint;
    v_submission_id uuid;
    v_q record;
    v_student_answer text;
    v_is_correct boolean;
    v_points_awarded smallint;
BEGIN
    SELECT * INTO v_quiz FROM public.quizzes WHERE id = p_quiz_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Quiz not found' USING ERRCODE = 'P0002';
    END IF;

    SELECT
        COUNT(*)::smallint,
        COALESCE(BOOL_OR(student_score >= v_quiz.passing_score), false)
    INTO v_existing_attempts, v_has_passed
    FROM public.quiz_submissions
    WHERE quiz_id = p_quiz_id AND student_id = v_student_id;

    SELECT COUNT(*), COALESCE(SUM(points), 0)
    INTO v_total_questions, v_total_possible_score
    FROM public.quiz_questions
    WHERE quiz_id = p_quiz_id;

    IF v_total_questions = 0 THEN
        RAISE EXCEPTION 'Quiz has no questions configured' USING ERRCODE = 'P0001';
    END IF;

    IF jsonb_array_length(p_answers) <> v_total_questions THEN
        RAISE EXCEPTION 'Answer count (%) does not match question count (%)',
            jsonb_array_length(p_answers), v_total_questions
            USING ERRCODE = 'P0001';
    END IF;

    v_new_attempt_number := v_existing_attempts + 1;

    INSERT INTO public.quiz_submissions (
        quiz_id,
        student_id,
        student_score,
        total_items,
        assessment_result,
        created_at
    ) VALUES (
        p_quiz_id,
        v_student_id,
        0,
        v_total_possible_score,
        'incomplete',
        now()
    )
    RETURNING id INTO v_submission_id;

    FOR v_q IN
        SELECT id, question_type, options, correct_answer, points, numeric_tolerance
        FROM public.quiz_questions
        WHERE quiz_id = p_quiz_id
        ORDER BY order_index ASC
    LOOP
        SELECT a->>'answer' INTO v_student_answer
        FROM jsonb_array_elements(p_answers) a
        WHERE (a->>'question_id')::uuid = v_q.id;

        IF v_student_answer IS NULL THEN
            RAISE EXCEPTION 'Missing answer for question id %', v_q.id
                USING ERRCODE = 'P0001';
        END IF;

        IF v_q.question_type IN ('multiple_choice', 'true_false') THEN
            v_is_correct := (UPPER(TRIM(v_student_answer)) = UPPER(TRIM(v_q.correct_answer)));
        ELSIF v_q.question_type IN ('identification', 'fill_in_blank') THEN
            v_is_correct := EXISTS (
                SELECT 1
                FROM unnest(string_to_array(LOWER(TRIM(v_q.correct_answer)), '|')) AS ans
                WHERE TRIM(ans) = LOWER(TRIM(v_student_answer))
            );
        ELSIF v_q.question_type = 'numeric' THEN
            IF TRIM(v_student_answer) ~ '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$' THEN
                v_is_correct := (
                    ABS(TRIM(v_student_answer)::numeric - v_q.correct_answer::numeric) 
                    <= COALESCE(v_q.numeric_tolerance, 0)
                );
            ELSE
                v_is_correct := false;
            END IF;
        ELSE
            v_is_correct := false;
        END IF;

        IF v_is_correct THEN
            v_points_awarded := v_q.points;
            v_earned_score := v_earned_score + v_points_awarded;
        ELSE
            v_points_awarded := 0;
        END IF;

        INSERT INTO public.quiz_attempt_answers (
            quiz_submission_id,
            question_id,
            student_answer,
            is_correct,
            points_awarded
        ) VALUES (
            v_submission_id,
            v_q.id,
            TRIM(v_student_answer),
            v_is_correct,
            v_points_awarded
        );
    END LOOP;

    v_score_pct := ROUND((v_earned_score::numeric / v_total_possible_score::numeric) * 100, 2);
    v_is_passing := (v_earned_score >= COALESCE(v_quiz.passing_score, 0));

    IF v_is_passing THEN
        v_assessment_result := 'passed';
        v_status := 'Passed';
        v_remaining_attempts := 0;
    ELSE
        v_assessment_result := 'incomplete';
        v_status := 'Incomplete';
        v_remaining_attempts := 999;
    END IF;

    UPDATE public.quiz_submissions
    SET student_score = v_earned_score,
        total_items = v_total_possible_score,
        assessment_result = v_assessment_result
    WHERE id = v_submission_id;

    -- EXP Award
    PERFORM public.award_exp_if_first_completion(v_student_id, 'regular_quiz', p_quiz_id, v_earned_score);

    RETURN jsonb_build_object(
        'submission_id', v_submission_id,
        'allow_review', COALESCE(v_quiz.allow_review, true),
        'score', v_earned_score,
        'total_items', v_total_possible_score,
        'percentage', v_score_pct,
        'is_passing', v_is_passing,
        'status', v_status,
        'remaining_attempts', v_remaining_attempts
    );
END;
$$;

-- Revoke direct execute on cores (security gating pattern)
REVOKE EXECUTE ON FUNCTION public.submit_and_grade_assessment_core(uuid, jsonb) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.submit_and_grade_regular_quiz_core(uuid, jsonb) FROM PUBLIC, anon, authenticated;

-- ----------------------------------------------------------------------------
-- 5. Permissions: Grants to authenticated
-- ----------------------------------------------------------------------------

GRANT EXECUTE ON FUNCTION public.get_quiz_submission_review(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_assessment_attempt_review(uuid) TO authenticated;

COMMIT;
