-- ============================================================================
-- DO NOT RE-RUN. Already applied. Its grading cores are superseded by
-- migration_restore_attempts_and_review.sql; running this again brings back
-- 999/0 attempts left and removes the 3-attempt limit on regular quizzes.
-- ============================================================================
-- ============================================================================
-- Migration: Passing Rule (75% rounded down) + Pre-Test/Quiz Backfill +
--            Required Screenshot Proof for External Quizzes
-- Project: MathTuro LMS (Production: ynkzcybctsstpqxdoweq)
-- Date: 2026-11-02
--
-- 1. Grading cores pass when score >= GREATEST(1, FLOOR(total x 75%)).
--    10 items -> 7, 4 -> 3, 2 -> 1, 1 -> 1. Matches shared/js/passing.js.
--    Bodies are copied from migration_quiz_cms_v2_batch2_question_types_and_parts.sql
--    (native cores) and migration_phase5_exp_gamification_and_leaderboard.sql
--    (legacy self-reported core). Only the pass line changes, plus the native
--    quiz EXP source_type 'regular_quiz' -> 'quiz' (exp_transactions CHECK only
--    allows quiz/pre_test/post_test).
--    Public wrappers (access gating) are untouched.
-- 2. Backfill: pre-tests get passing_threshold 75. Content still unlocks after
--    any attempt (is_module_content_unlocked only checks an attempt exists).
--    quizzes.passing_score is recomputed from total_items.
-- 3. submit_regular_quiz_score(uuid, smallint, smallint, text): same gating as
--    the 3-arg wrapper, requires a screenshot stored under the caller's own
--    folder in the quiz-screenshots bucket, and saves its path.
--
-- Safe to re-run. Run in the Supabase SQL Editor as one script.
-- If migration_phase5_exp_gamification_and_leaderboard.sql or the batch2
-- migration is ever re-run, run this file again afterwards.
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1a. Native pre/post-test grading core
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
-- 1b. Native regular quiz grading core
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
    -- Passing rule: floor(total x 75%), minimum 1 (10 items -> 7).
    v_is_passing := (v_earned_score >= GREATEST(1, FLOOR(v_total_possible_score * 0.75)));

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
    PERFORM public.award_exp_if_first_completion(v_student_id, 'quiz', p_quiz_id, v_earned_score);

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

-- ----------------------------------------------------------------------------
-- 1c. Legacy self-reported (external link) quiz core
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.submit_regular_quiz_score_core(
    p_quiz_id uuid,
    p_score smallint,
    p_total smallint
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_student_id uuid := auth.uid();
    v_quiz record;
    v_existing_count smallint;
    v_has_passed boolean;
    v_new_attempt smallint;
    v_pct numeric(5,2);
    v_result varchar(10);
    v_submission_id uuid;
BEGIN
    IF v_student_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT * INTO v_quiz
    FROM public.quizzes
    WHERE id = p_quiz_id AND is_published = true;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Quiz not found or not published';
    END IF;

    IF p_score < 0 OR p_total <= 0 OR p_score > p_total THEN
        RAISE EXCEPTION 'Invalid score bounds';
    END IF;

    SELECT
        COUNT(*),
        COALESCE(BOOL_OR(assessment_result = 'passed' OR is_teacher_override = true), false)
    INTO v_existing_count, v_has_passed
    FROM public.quiz_submissions
    WHERE quiz_id = p_quiz_id AND user_id = v_student_id;

    IF v_has_passed THEN
        RAISE EXCEPTION 'Quiz has already been passed';
    END IF;

    IF v_existing_count >= 3 THEN
        RAISE EXCEPTION 'Maximum attempts (3) already reached';
    END IF;

    v_new_attempt := v_existing_count + 1;
    v_pct := ROUND((p_score::numeric / p_total::numeric) * 100, 2);

    -- Passing rule: floor(total x threshold), minimum 1 (10 items @75% -> 7).
    IF p_score >= GREATEST(1, FLOOR(p_total * COALESCE(v_quiz.passing_threshold, 75.00) / 100.0)) THEN
        v_result := 'passed';
    ELSE
        IF v_new_attempt < COALESCE(v_quiz.max_attempts, 3) THEN
            v_result := 'incomplete';
        ELSE
            v_result := 'failed';
        END IF;
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
        p_score,
        p_total,
        'pending',
        v_new_attempt,
        v_result,
        now()
    )
    RETURNING id INTO v_submission_id;

    -- Phase 5: EXP = raw submitted score, awarded once per (student, quiz),
    -- regardless of pass/fail.
    PERFORM public.award_exp_if_first_completion(v_student_id, 'quiz', p_quiz_id, p_score);

    RETURN jsonb_build_object(
        'success', true,
        'submission_id', v_submission_id,
        'attempt_number', v_new_attempt,
        'assessment_result', v_result,
        'score_pct', v_pct
    );
END;
$$;
REVOKE EXECUTE ON FUNCTION public.submit_regular_quiz_score_core(uuid, smallint, smallint) FROM PUBLIC, anon, authenticated;

-- ----------------------------------------------------------------------------
-- 2. Backfill passing values
-- ----------------------------------------------------------------------------
UPDATE public.module_assessments
SET passing_threshold = 75.00
WHERE assessment_type = 'pre_test'
  AND passing_threshold IS DISTINCT FROM 75.00;

ALTER TABLE public.module_assessments
    ALTER COLUMN passing_threshold SET DEFAULT 75.00;

UPDATE public.quizzes
SET passing_score = CASE
        WHEN COALESCE(total_items, 0) < 1 THEN 0
        ELSE GREATEST(1, FLOOR(total_items * 0.75))::integer
    END
WHERE passing_score IS DISTINCT FROM CASE
        WHEN COALESCE(total_items, 0) < 1 THEN 0
        ELSE GREATEST(1, FLOOR(total_items * 0.75))::integer
    END;

-- ----------------------------------------------------------------------------
-- 3. Screenshot proof for external quizzes
-- ----------------------------------------------------------------------------
-- Bucket already exists in production (supabase_complete_setup.sql); only
-- created here if missing.
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('quiz-screenshots', 'quiz-screenshots', false, 5242880,
        ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp'])
ON CONFLICT (id) DO NOTHING;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects'
                   AND policyname = 'quiz_screenshots_student_insert_own') THEN
        CREATE POLICY quiz_screenshots_student_insert_own ON storage.objects
            FOR INSERT TO authenticated
            WITH CHECK (bucket_id = 'quiz-screenshots'
                        AND auth.uid()::text = (storage.foldername(name))[1]);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects'
                   AND policyname = 'quiz_screenshots_read_own_or_staff') THEN
        CREATE POLICY quiz_screenshots_read_own_or_staff ON storage.objects
            FOR SELECT TO authenticated
            USING (bucket_id = 'quiz-screenshots'
                   AND (auth.uid()::text = (storage.foldername(name))[1]
                        OR public.is_current_user_teacher_or_admin()));
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.submit_regular_quiz_score(
    p_quiz_id uuid,
    p_score smallint,
    p_total smallint,
    p_screenshot_path text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_result jsonb;
    v_path text := btrim(COALESCE(p_screenshot_path, ''));
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Proof must be an object the caller uploaded to their own folder.
    IF v_path = '' THEN
        RAISE EXCEPTION 'A screenshot of your score is required';
    END IF;
    IF split_part(v_path, '/', 1) <> auth.uid()::text OR v_path LIKE '%..%' THEN
        RAISE EXCEPTION 'Invalid screenshot path';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM storage.objects o
                   WHERE o.bucket_id = 'quiz-screenshots' AND o.name = v_path) THEN
        RAISE EXCEPTION 'Screenshot upload not found';
    END IF;

    -- Same gating, total pinning and native-quiz rejection as the 3-arg wrapper.
    v_result := public.submit_regular_quiz_score(p_quiz_id, p_score, p_total);

    UPDATE public.quiz_submissions
    SET screenshot_url = v_path
    WHERE id = (v_result->>'submission_id')::uuid
      AND user_id = auth.uid();

    RETURN v_result || jsonb_build_object('screenshot_path', v_path);
END;
$$;

REVOKE EXECUTE ON FUNCTION public.submit_regular_quiz_score(uuid, smallint, smallint, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.submit_regular_quiz_score(uuid, smallint, smallint, text) TO authenticated;

COMMIT;

-- ============================================================================
-- VERIFICATION (read-only)
-- ============================================================================
-- SELECT assessment_type, passing_threshold, COUNT(*) FROM public.module_assessments GROUP BY 1, 2;
-- SELECT title, total_items, passing_score FROM public.quizzes ORDER BY created_at DESC LIMIT 20;
-- SELECT p.oid::regprocedure, p.prosecdef FROM pg_proc p
--  WHERE p.proname IN ('submit_and_grade_assessment_core', 'submit_and_grade_regular_quiz_core',
--                      'submit_regular_quiz_score', 'submit_regular_quiz_score_core');
-- Expected: 5 rows (two submit_regular_quiz_score overloads), all prosecdef = true.
-- ============================================================================
