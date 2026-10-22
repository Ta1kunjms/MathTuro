-- ============================================================================
-- Migration: Quiz CMS v2 Batch 2 — Question Types, Parts & Flexible Scoring
-- Project: MathTuro LMS (Production: ynkzcybctsstpqxdoweq)
-- Date: 2026-10-22
--
-- Scope:
--   1. Schema: ALTER TABLE public.quiz_questions
--      - Add part_label VARCHAR(100) (e.g., 'Part I: Multiple Choice')
--      - Add numeric_tolerance NUMERIC(8,4) DEFAULT 0
--      - Update CHECK constraints for question_type and options format
--   2. Update Student Question Delivery RPCs:
--      - DROP and RECREATE get_assessment_questions_for_student(uuid)
--      - DROP and RECREATE get_quiz_questions_for_student(uuid)
--      - Includes part_label in output; NEVER exposes answer keys or tolerance
--   3. Update Server-Side Grading Core Engines:
--      - submit_and_grade_assessment_core
--      - submit_and_grade_regular_quiz_core
--      - Adds support for fill_in_blank (synonyms via '|') and numeric (tolerance)
--      - Preserves Phase 5 EXP gamification awarding
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. Schema Alterations on public.quiz_questions
-- ----------------------------------------------------------------------------

-- Add part_label and numeric_tolerance if not present
ALTER TABLE public.quiz_questions 
    ADD COLUMN IF NOT EXISTS part_label VARCHAR(100),
    ADD COLUMN IF NOT EXISTS numeric_tolerance NUMERIC(8,4) DEFAULT 0;

-- Expand question_type check constraint
ALTER TABLE public.quiz_questions DROP CONSTRAINT IF EXISTS quiz_questions_question_type_check;
ALTER TABLE public.quiz_questions ADD CONSTRAINT quiz_questions_question_type_check 
    CHECK (question_type IN ('multiple_choice', 'true_false', 'identification', 'fill_in_blank', 'numeric'));

-- Update options format check constraint
ALTER TABLE public.quiz_questions DROP CONSTRAINT IF EXISTS chk_options_format;
ALTER TABLE public.quiz_questions ADD CONSTRAINT chk_options_format CHECK (
    (question_type IN ('identification', 'fill_in_blank', 'numeric') AND options IS NULL) OR
    (question_type IN ('multiple_choice', 'true_false') AND jsonb_typeof(options) = 'array' AND jsonb_array_length(options) >= 2)
);

CREATE INDEX IF NOT EXISTS idx_qq_part_label ON public.quiz_questions(part_label);

-- ----------------------------------------------------------------------------
-- 2. Sanitized Student Question Delivery RPCs
-- ----------------------------------------------------------------------------

-- Must drop first because return table signature changes to include part_label
DROP FUNCTION IF EXISTS public.get_quiz_questions_for_student(uuid);

CREATE OR REPLACE FUNCTION public.get_quiz_questions_for_student(
    p_quiz_id uuid
)
RETURNS TABLE (
    id uuid,
    order_index smallint,
    part_label varchar(100),
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
BEGIN
    IF v_student_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    IF NOT public.can_student_access_quiz(v_student_id, p_quiz_id) THEN
        RAISE EXCEPTION 'Quiz access locked by module progression or unpublished';
    END IF;

    RETURN QUERY
    SELECT 
        qq.id,
        qq.order_index,
        qq.part_label,
        qq.question_text,
        qq.question_type,
        qq.options,
        qq.points
    FROM public.quiz_questions qq
    WHERE qq.quiz_id = p_quiz_id
    ORDER BY qq.order_index ASC;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.get_quiz_questions_for_student(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_quiz_questions_for_student(uuid) TO authenticated;


DROP FUNCTION IF EXISTS public.get_assessment_questions_for_student(uuid);

CREATE OR REPLACE FUNCTION public.get_assessment_questions_for_student(
    p_assessment_id uuid
)
RETURNS TABLE (
    id uuid,
    order_index smallint,
    part_label varchar(100),
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
        qq.part_label,
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
-- 3. Update Server-Side Grading Core: Assessment (Pre/Post Test)
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
        v_status := CASE WHEN v_is_passing THEN 'Passed' ELSE 'Incomplete' END;
        v_remaining_attempts := 0;
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
-- 4. Update Server-Side Grading Core: Regular Practice Quiz
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
    v_is_passing := (v_score_pct >= 75.00);

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

    -- Phase 5 EXP Awarding
    PERFORM public.award_exp_if_first_completion(v_student_id, 'regular_quiz', p_quiz_id, v_earned_score);

    RETURN jsonb_build_object(
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

COMMIT;

-- ============================================================================
-- VERIFICATION QUERIES (Read-Only)
-- ============================================================================
-- 1. Verify new columns:
-- SELECT column_name, data_type, is_nullable
-- FROM information_schema.columns
-- WHERE table_name = 'quiz_questions' AND column_name IN ('part_label', 'numeric_tolerance');
--
-- 2. Verify student RPC signatures:
-- SELECT routine_name, routine_type, security_type
-- FROM information_schema.routines
-- WHERE routine_name IN ('get_quiz_questions_for_student', 'get_assessment_questions_for_student')
--   AND routine_schema = 'public';
-- ============================================================================
