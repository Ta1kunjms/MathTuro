-- ============================================================================
-- Migration: Restore attempt rules and review after the passing-rule migration
-- Project: MathTuro LMS (Production: ynkzcybctsstpqxdoweq)
-- Date: 2026-11-06
--
-- migration_passing_rule_floor_and_screenshot.sql was built from the batch2
-- grading cores instead of migration_security_fix_is_archived_and_service_role.sql.
-- That dropped attempt_id/submission_id/allow_review from grading results and the
-- 3-attempt limit on regular quizzes, and reported 999 / 0 attempts left.
--
-- 1. Grading cores: floor passing rule kept; every test and quiz now allows 3
--    attempts, a failed attempt reports what is left, a pass ends attempts.
-- 2. Pre/post-test review switched on (allow_review defaulted to false with no
--    screen to change it). Students can review after passing or using all 3
--    attempts; teachers and admins can always review.
-- 3. get_my_locked_presentations(): titles of published presentations the student
--    cannot open yet, with the reason. No file paths are returned.
--
-- Safe to re-run. Run in the Supabase SQL Editor as one script.
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1a. Pre/post-test grading core
-- ----------------------------------------------------------------------------
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
    v_assessment_result varchar(10);
    v_status varchar(30);
    v_remaining_attempts integer;
    v_attempt_id uuid;
    v_q record;
    v_student_answer text;
    v_is_correct boolean;
    v_points_awarded smallint;
BEGIN
    IF v_student_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    PERFORM pg_advisory_xact_lock(hashtext(v_student_id::text || p_assessment_id::text));

    SELECT * INTO v_asmt FROM public.module_assessments WHERE id = p_assessment_id AND is_published = true;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Assessment not found or unpublished';
    END IF;

    SELECT 
        COUNT(*),
        COALESCE(BOOL_OR(assessment_result = 'passed' OR is_teacher_override = true), false)
    INTO v_existing_attempts, v_has_passed
    FROM public.module_assessment_attempts
    WHERE assessment_id = p_assessment_id AND student_id = v_student_id;

    IF v_has_passed THEN
        RAISE EXCEPTION 'Assessment has already been passed';
    END IF;

    IF v_existing_attempts >= 3 THEN
        RAISE EXCEPTION 'Maximum attempts (3) already reached';
    END IF;

    v_new_attempt_number := v_existing_attempts + 1;

    SELECT COUNT(*), COALESCE(SUM(points), 0)
    INTO v_total_questions, v_total_possible_score
    FROM public.quiz_questions
    WHERE assessment_id = p_assessment_id;

    IF v_total_questions = 0 OR v_total_possible_score <= 0 THEN
        RAISE EXCEPTION 'No questions configured for this assessment';
    END IF;

    IF p_answers IS NULL OR jsonb_array_length(p_answers) <> v_total_questions THEN
        RAISE EXCEPTION 'Submitted answers count (%) does not match required total questions (%)',
            COALESCE(jsonb_array_length(p_answers), 0), v_total_questions;
    END IF;

    INSERT INTO public.module_assessment_attempts (
        assessment_id,
        student_id,
        attempt_number,
        student_score,
        total_items,
        verification_status,
        assessment_result
    ) VALUES (
        p_assessment_id,
        v_student_id,
        v_new_attempt_number,
        0,
        v_total_possible_score,
        'pending',
        'pending'
    )
    RETURNING id INTO v_attempt_id;

    FOR v_q IN
        SELECT id, question_type, correct_answer, points, numeric_tolerance
        FROM public.quiz_questions
        WHERE assessment_id = p_assessment_id
        ORDER BY order_index ASC
    LOOP
        SELECT item->>'answer' INTO v_student_answer
        FROM jsonb_array_elements(p_answers) AS item
        WHERE (item->>'question_id')::uuid = v_q.id;

        IF v_student_answer IS NULL THEN
            RAISE EXCEPTION 'Missing answer for question ID %', v_q.id;
        END IF;

        IF v_q.question_type IN ('multiple_choice', 'true_false') THEN
            v_is_correct := (UPPER(TRIM(v_student_answer)) = UPPER(TRIM(v_q.correct_answer)));
        ELSIF v_q.question_type IN ('identification', 'fill_in_blank') THEN
            -- Check case-insensitive against pipe-separated acceptable synonyms
            v_is_correct := EXISTS (
                SELECT 1
                FROM unnest(string_to_array(LOWER(TRIM(v_q.correct_answer)), '|')) AS ans
                WHERE TRIM(ans) = LOWER(TRIM(v_student_answer))
            );
        ELSIF v_q.question_type = 'numeric' THEN
            -- Validate that student submitted a valid numeric string
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
    -- Passing rule: floor(total x threshold), minimum 1 (10 items @75% -> 7).
    v_is_passing := (v_earned_score >= GREATEST(1, FLOOR(v_total_possible_score * COALESCE(v_asmt.passing_threshold, 75.00) / 100.0)));

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
        IF v_is_passing THEN
            v_assessment_result := 'passed';
            v_status := 'Passed';
            v_remaining_attempts := 0;
        ELSIF v_new_attempt_number < 3 THEN
            v_assessment_result := 'incomplete';
            v_status := 'Incomplete';
            v_remaining_attempts := 3 - v_new_attempt_number;
        ELSE
            v_assessment_result := 'failed';
            v_status := 'Failed';
            v_remaining_attempts := 0;
        END IF;
    END IF;

    UPDATE public.module_assessment_attempts
    SET student_score = v_earned_score,
        total_items = v_total_possible_score,
        verification_status = v_verification_status,
        assessment_result = v_assessment_result
    WHERE id = v_attempt_id;

    -- Phase 5 EXP Awarding
    PERFORM public.award_exp_if_first_completion(v_student_id, v_asmt.assessment_type, p_assessment_id, v_earned_score);

    RETURN jsonb_build_object(
        'attempt_id', v_attempt_id,
        -- Answers stay hidden while the student can still retake this test.
        'allow_review', (COALESCE(v_asmt.allow_review, true) AND (v_is_passing OR v_remaining_attempts = 0)),
        'score', v_earned_score,
        'total_items', v_total_possible_score,
        'percentage', v_score_pct,
        'is_passing', v_is_passing,
        'status', v_status,
        'remaining_attempts', v_remaining_attempts
    );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.submit_and_grade_assessment_core(uuid, jsonb) FROM PUBLIC, anon, authenticated;

-- ----------------------------------------------------------------------------
-- 1b. Regular quiz grading core
-- ----------------------------------------------------------------------------
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
    v_status varchar(30);
    v_remaining_attempts integer;
    v_assessment_result varchar(10);
    v_submission_id uuid;
    v_q record;
    v_student_answer text;
    v_is_correct boolean;
    v_points_awarded smallint;
BEGIN
    IF v_student_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    PERFORM pg_advisory_xact_lock(hashtext(v_student_id::text || p_quiz_id::text));

    SELECT * INTO v_quiz FROM public.quizzes WHERE id = p_quiz_id AND is_published = true;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Quiz not found or unpublished';
    END IF;

    SELECT 
        COUNT(*),
        COALESCE(BOOL_OR(assessment_result = 'passed' OR is_teacher_override = true), false)
    INTO v_existing_attempts, v_has_passed
    FROM public.quiz_submissions
    WHERE quiz_id = p_quiz_id AND user_id = v_student_id;

    IF v_has_passed THEN
        RAISE EXCEPTION 'Quiz has already been passed';
    END IF;

    IF v_existing_attempts >= 3 THEN
        RAISE EXCEPTION 'Maximum attempts (3) already reached';
    END IF;

    v_new_attempt_number := v_existing_attempts + 1;

    SELECT COUNT(*), COALESCE(SUM(points), 0)
    INTO v_total_questions, v_total_possible_score
    FROM public.quiz_questions
    WHERE quiz_id = p_quiz_id;

    IF v_total_questions = 0 OR v_total_possible_score <= 0 THEN
        RAISE EXCEPTION 'No questions configured for this quiz';
    END IF;

    IF p_answers IS NULL OR jsonb_array_length(p_answers) <> v_total_questions THEN
        RAISE EXCEPTION 'Submitted answers count (%) does not match required total questions (%)',
            COALESCE(jsonb_array_length(p_answers), 0), v_total_questions;
    END IF;

    INSERT INTO public.quiz_submissions (
        quiz_id,
        module_id,
        user_id,
        student_score,
        total_items,
        status,
        attempt_number,
        assessment_result,
        submitted_at
    ) VALUES (
        p_quiz_id,
        v_quiz.module_id,
        v_student_id,
        0,
        v_total_possible_score,
        'approved',
        v_new_attempt_number,
        'incomplete',
        now()
    )
    RETURNING id INTO v_submission_id;

    FOR v_q IN
        SELECT id, question_type, correct_answer, points, numeric_tolerance
        FROM public.quiz_questions
        WHERE quiz_id = p_quiz_id
        ORDER BY order_index ASC
    LOOP
        SELECT item->>'answer' INTO v_student_answer
        FROM jsonb_array_elements(p_answers) AS item
        WHERE (item->>'question_id')::uuid = v_q.id;

        IF v_student_answer IS NULL THEN
            RAISE EXCEPTION 'Missing answer for question ID %', v_q.id;
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
    -- Passing rule: floor(total x 75%), minimum 1 (10 items -> 7).
    v_is_passing := (v_earned_score >= GREATEST(1, FLOOR(v_total_possible_score * 0.75)));

    IF v_is_passing THEN
        v_assessment_result := 'passed';
        v_status := 'Passed';
        v_remaining_attempts := 0;
    ELSIF v_new_attempt_number < 3 THEN
        v_assessment_result := 'incomplete';
        v_status := 'Incomplete';
        v_remaining_attempts := 3 - v_new_attempt_number;
    ELSE
        v_assessment_result := 'failed';
        v_status := 'Failed';
        v_remaining_attempts := 0;
    END IF;

    UPDATE public.quiz_submissions
    SET student_score = v_earned_score,
        total_items = v_total_possible_score,
        assessment_result = v_assessment_result
    WHERE id = v_submission_id;

    -- Phase 5 EXP Awarding
    PERFORM public.award_exp_if_first_completion(v_student_id, 'quiz', p_quiz_id, v_earned_score);

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

REVOKE EXECUTE ON FUNCTION public.submit_and_grade_regular_quiz_core(uuid, jsonb) FROM PUBLIC, anon, authenticated;

-- ----------------------------------------------------------------------------
-- 2. Pre/post-test review
-- ----------------------------------------------------------------------------
UPDATE public.module_assessments SET allow_review = true WHERE allow_review = false;

ALTER TABLE public.module_assessments ALTER COLUMN allow_review SET DEFAULT true;

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
    v_attempt_count integer;
    v_has_passed boolean;
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

    -- Correct answers stay hidden while the student can still retake the test.
    IF NOT public.is_current_user_teacher_or_admin() THEN
        SELECT COUNT(*), COALESCE(BOOL_OR(assessment_result = 'passed' OR is_teacher_override = true), false)
        INTO v_attempt_count, v_has_passed
        FROM public.module_assessment_attempts
        WHERE assessment_id = v_attempt.assessment_id AND student_id = v_attempt.student_id;

        IF NOT v_has_passed AND v_attempt_count < 3 THEN
            RAISE EXCEPTION 'Review opens after you pass or use all 3 attempts' USING ERRCODE = '42501';
        END IF;
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
-- 3. Locked presentations for the signed-in student
-- ----------------------------------------------------------------------------
-- pres_select_student hides presentations of locked modules, so the student page
-- could not explain why an uploaded presentation was missing.
CREATE OR REPLACE FUNCTION public.get_my_locked_presentations()
RETURNS TABLE (
    presentation_id uuid,
    presentation_title text,
    module_title text,
    locked_reason text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_student_id uuid := auth.uid();
    v_grade_level_id uuid;
    v_section_id uuid;
BEGIN
    IF v_student_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT u.grade_level_id, u.section_id INTO v_grade_level_id, v_section_id
    FROM public.users u
    WHERE u.id = v_student_id AND u.role = 'student';

    IF NOT FOUND THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        p.id,
        p.title::text,
        m.title::text,
        CASE WHEN NOT public.can_student_access_module(v_student_id, m.id)
             THEN 'previous_module' ELSE 'pre_test' END
    FROM public.presentations p
    JOIN public.modules m ON m.id = p.module_id
    WHERE p.is_published = true
      AND m.status = 'published'
      AND (m.grade_level_id IS NULL OR m.grade_level_id = v_grade_level_id)
      AND (m.section_id IS NULL OR m.section_id = v_section_id)
      AND NOT (public.can_student_access_module(v_student_id, m.id)
               AND public.is_module_content_unlocked(v_student_id, m.id))
    ORDER BY m.title, p.order_index;
END;
$$;

REVOKE ALL ON FUNCTION public.get_my_locked_presentations() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_my_locked_presentations() TO authenticated;

COMMIT;

-- ============================================================================
-- VERIFICATION (read-only)
-- ============================================================================
-- SELECT proname,
--        prosrc LIKE '%attempt_id%' OR prosrc LIKE '%submission_id%' AS returns_ids,
--        prosrc LIKE '%999%' AS still_unlimited
-- FROM pg_proc
-- WHERE proname IN ('submit_and_grade_assessment_core', 'submit_and_grade_regular_quiz_core');
-- Expected: 2 rows, returns_ids = true, still_unlimited = false.
-- SELECT allow_review, COUNT(*) FROM public.module_assessments GROUP BY 1;
-- Expected: only allow_review = true.
-- ============================================================================
