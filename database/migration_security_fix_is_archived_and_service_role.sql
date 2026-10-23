-- ============================================================================
-- MathTuro LMS — Security Fix & Schema Alignment: is_archived + Core Assessment Engines
-- Migration: QA Security & Grading Remediation
-- Environment: Production (ynkzcybctsstpqxdoweq) on main branch
-- Author: Tycoon James Flores
-- Date: 2026-10-23
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. Table Grants & Default Privileges for service_role
-- ----------------------------------------------------------------------------
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON ROUTINES TO service_role;

-- ----------------------------------------------------------------------------
-- 2. Enforce is_archived protection and trigger on public.users
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.prevent_protected_user_changes()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Allow postgres superuser (SQL Editor), service_role (Admin API / scripts), and admins
  IF session_user IN ('postgres', 'service_role')
     OR COALESCE(current_setting('request.jwt.claim.role', true), '') = 'service_role'
     OR public.is_current_user_admin() THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' THEN
    -- If an active teacher is updating a student's approval status only
    IF public.is_current_user_teacher_or_admin() AND OLD.role = 'student' AND NEW.role = 'student' THEN
      IF NEW.email IS DISTINCT FROM OLD.email
         OR NEW.lrn IS DISTINCT FROM OLD.lrn
         OR NEW.school_year IS DISTINCT FROM OLD.school_year
         OR NEW.gender IS DISTINCT FROM OLD.gender
         OR NEW.first_name IS DISTINCT FROM OLD.first_name
         OR NEW.last_name IS DISTINCT FROM OLD.last_name
         OR NEW.full_name IS DISTINCT FROM OLD.full_name
         OR NEW.grade_level_id IS DISTINCT FROM OLD.grade_level_id
         OR NEW.section_id IS DISTINCT FROM OLD.section_id
         OR NEW.grade_level_text IS DISTINCT FROM OLD.grade_level_text
         OR NEW.section_text IS DISTINCT FROM OLD.section_text
         OR NEW.is_archived IS DISTINCT FROM OLD.is_archived THEN
        RAISE EXCEPTION 'Teachers may only update student approval status, not demographic or archive fields'
          USING ERRCODE = '42501';
      END IF;
      RETURN NEW;
    END IF;

    -- For all other users/fields, block modification of protected fields
    IF NEW.role IS DISTINCT FROM OLD.role
       OR NEW.is_active IS DISTINCT FROM OLD.is_active
       OR NEW.is_archived IS DISTINCT FROM OLD.is_archived  -- SECURITY FIX: students cannot self-archive
       OR NEW.approval_status IS DISTINCT FROM OLD.approval_status
       OR NEW.lrn IS DISTINCT FROM OLD.lrn
       OR NEW.school_year IS DISTINCT FROM OLD.school_year
       OR NEW.email IS DISTINCT FROM OLD.email
       OR NEW.full_name IS DISTINCT FROM OLD.full_name
       OR NEW.first_name IS DISTINCT FROM OLD.first_name
       OR NEW.last_name IS DISTINCT FROM OLD.last_name
       OR NEW.grade_level_id IS DISTINCT FROM OLD.grade_level_id
       OR NEW.section_id IS DISTINCT FROM OLD.section_id
       OR NEW.grade_level_text IS DISTINCT FROM OLD.grade_level_text
       OR NEW.section_text IS DISTINCT FROM OLD.section_text
       OR NEW.gender IS DISTINCT FROM OLD.gender THEN
      RAISE EXCEPTION 'Protected account fields may only be changed by an administrator'
        USING ERRCODE = '42501';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS protect_user_profile_fields ON public.users;
CREATE TRIGGER protect_user_profile_fields
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.prevent_protected_user_changes();

-- ----------------------------------------------------------------------------
-- 3. Fix submit_and_grade_assessment_core Schema Alignment & 3-Attempt Contract
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

    -- Concurrency serialization lock
    PERFORM pg_advisory_xact_lock(hashtext(v_student_id::text || p_assessment_id::text));

    SELECT
        COUNT(*)::smallint,
        COALESCE(BOOL_OR(assessment_result = 'passed'), false)
    INTO v_existing_attempts, v_has_passed
    FROM public.module_assessment_attempts
    WHERE assessment_id = p_assessment_id AND student_id = v_student_id;

    IF v_asmt.assessment_type = 'post_test' AND v_has_passed THEN
        RAISE EXCEPTION 'Post-test already passed for this module' USING ERRCODE = 'P0001';
    END IF;

    IF v_existing_attempts >= 3 THEN
        RAISE EXCEPTION 'Maximum attempts (3) already reached' USING ERRCODE = 'P0001';
    END IF;

    SELECT COUNT(*), COALESCE(SUM(points), 0)
    INTO v_total_questions, v_total_possible_score
    FROM public.quiz_questions
    WHERE assessment_id = p_assessment_id;

    IF v_total_questions = 0 THEN
        RAISE EXCEPTION 'Assessment has no questions configured' USING ERRCODE = 'P0001';
    END IF;

    IF p_answers IS NULL OR jsonb_array_length(p_answers) <> v_total_questions THEN
        RAISE EXCEPTION 'Answer count (%) does not match question count (%)',
            COALESCE(jsonb_array_length(p_answers), 0), v_total_questions
            USING ERRCODE = 'P0001';
    END IF;

    v_new_attempt_number := v_existing_attempts + 1;

    -- Insert attempt row matching public.module_assessment_attempts schema
    INSERT INTO public.module_assessment_attempts (
        assessment_id,
        student_id,
        attempt_number,
        student_score,
        total_items,
        verification_status,
        assessment_result,
        created_at
    ) VALUES (
        p_assessment_id,
        v_student_id,
        v_new_attempt_number,
        0,
        v_total_possible_score,
        'pending',
        'pending',
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
        v_status := CASE WHEN v_is_passing THEN 'Passed' ELSE 'Incomplete' END;
        v_remaining_attempts := 3 - v_new_attempt_number;
    END IF;

    UPDATE public.module_assessment_attempts
    SET student_score = v_earned_score,
        total_items = v_total_possible_score,
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

-- ----------------------------------------------------------------------------
-- 4. Fix submit_and_grade_regular_quiz_core Schema Alignment (user_id)
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

    -- Concurrency serialization lock
    PERFORM pg_advisory_xact_lock(hashtext(v_student_id::text || p_quiz_id::text));

    SELECT
        COUNT(*)::smallint,
        COALESCE(BOOL_OR(student_score >= v_quiz.passing_score), false)
    INTO v_existing_attempts, v_has_passed
    FROM public.quiz_submissions
    WHERE quiz_id = p_quiz_id AND user_id = v_student_id;

    IF v_has_passed THEN
        RAISE EXCEPTION 'Quiz already passed' USING ERRCODE = 'P0001';
    END IF;

    IF v_existing_attempts >= 3 THEN
        RAISE EXCEPTION 'Maximum attempts (3) already reached' USING ERRCODE = 'P0001';
    END IF;

    SELECT COUNT(*), COALESCE(SUM(points), 0)
    INTO v_total_questions, v_total_possible_score
    FROM public.quiz_questions
    WHERE quiz_id = p_quiz_id;

    IF v_total_questions = 0 THEN
        RAISE EXCEPTION 'Quiz has no questions configured' USING ERRCODE = 'P0001';
    END IF;

    IF p_answers IS NULL OR jsonb_array_length(p_answers) <> v_total_questions THEN
        RAISE EXCEPTION 'Answer count (%) does not match question count (%)',
            COALESCE(jsonb_array_length(p_answers), 0), v_total_questions
            USING ERRCODE = 'P0001';
    END IF;

    v_new_attempt_number := v_existing_attempts + 1;

    -- Insert into public.quiz_submissions using user_id and status = 'approved'
    INSERT INTO public.quiz_submissions (
        quiz_id,
        module_id,
        user_id,
        student_score,
        total_items,
        status,
        attempt_number,
        assessment_result,
        created_at
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
    v_is_passing := (v_earned_score >= v_quiz.passing_score);

    IF v_is_passing THEN
        v_assessment_result := 'passed';
        v_status := 'Passed';
        v_remaining_attempts := 0;
    ELSE
        IF v_new_attempt_number < 3 THEN
            v_assessment_result := 'incomplete';
            v_status := 'Incomplete';
            v_remaining_attempts := 3 - v_new_attempt_number;
        ELSE
            v_assessment_result := 'failed';
            v_status := 'Failed';
            v_remaining_attempts := 0;
        END IF;
    END IF;

    UPDATE public.quiz_submissions
    SET student_score = v_earned_score,
        total_items = v_total_possible_score,
        assessment_result = v_assessment_result
    WHERE id = v_submission_id;

    -- EXP Award
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

-- Revoke public access, allow authenticated and service_role
REVOKE ALL ON FUNCTION public.submit_and_grade_assessment_core(uuid, jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.submit_and_grade_regular_quiz_core(uuid, jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_and_grade_assessment_core(uuid, jsonb) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.submit_and_grade_regular_quiz_core(uuid, jsonb) TO authenticated, service_role;

-- ----------------------------------------------------------------------------
-- 5. Admin QA Cleanup RPC
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_qa_cleanup_test_users()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_deleted_public  int := 0;
  v_deleted_auth    int := 0;
  v_user            record;
BEGIN
  IF NOT public.is_current_user_admin()
     AND session_user NOT IN ('postgres', 'service_role')
     AND COALESCE(current_setting('request.jwt.claim.role', true), '') NOT IN ('service_role') THEN
    RAISE EXCEPTION 'Only admins or service_role may execute admin_qa_cleanup_test_users'
      USING ERRCODE = '42501';
  END IF;

  DELETE FROM public.users
  WHERE email LIKE '%@mathturo-qa.test';
  GET DIAGNOSTICS v_deleted_public = ROW_COUNT;

  FOR v_user IN
    SELECT id FROM auth.users WHERE email LIKE '%@mathturo-qa.test'
  LOOP
    DELETE FROM auth.users WHERE id = v_user.id;
    v_deleted_auth := v_deleted_auth + 1;
  END LOOP;

  RETURN jsonb_build_object(
    'deleted_public_users', v_deleted_public,
    'deleted_auth_users',   v_deleted_auth,
    'timestamp',            now()
  );
END;
$$;

REVOKE ALL ON FUNCTION public.admin_qa_cleanup_test_users() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_qa_cleanup_test_users() TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_qa_cleanup_test_users() TO service_role;

COMMIT;
