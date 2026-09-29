-- ============================================================================
-- Migration: Phase 5 — EXP Gamification & Leaderboard System
-- Purpose:
--   1. Create an append-only EXP ledger, protected so only the database can
--      write to it (no direct student/teacher INSERT/UPDATE/DELETE)
--   2. Award EXP = raw earned score of the FIRST completed and graded
--      submission per (student, source) — enforced by a unique constraint,
--      not application logic. Pass/fail status does not affect the amount;
--      a score of 0 is valid and permanently locks that source at 0 EXP.
--   3. Wire the award into every currently-live grading entry point for
--      quizzes, pre-tests, and post-tests (see note below — this covers two
--      parallel code paths per source type, not just the Phase 3 ones)
--   4. Add a section-scoped leaderboard, exposed only via a no-argument
--      SECURITY DEFINER RPC (not a selectable view — the caller's section is
--      derived server-side from auth.uid(), never accepted as a parameter),
--      excluding archived and non-approved accounts
-- Explicitly NOT in this migration:
--   - No change to the 75% passing threshold, 3-attempt cap, score-lock-
--     after-pass, or progression/unlock logic. Every modified function below
--     has exactly one new statement added (the EXP award call); no existing
--     branch, condition, or return value is altered.
--   - No backfill (per client decision: no retroactive EXP in Phase 5).
-- Coverage note (found during implementation, not anticipated in planning):
--   This codebase currently has TWO live grading entry points per source
--   type, not one:
--     quiz:      submit_and_grade_regular_quiz (Phase 3, native — used by
--                student/take-quiz.html) AND submit_regular_quiz_score
--                (Phase 2, legacy self-reported score — still used by
--                student/quizzes.html and student/module-view.html)
--     pre/post:  submit_and_grade_assessment (Phase 3, native) AND
--                verify_assessment_attempt (Phase 2, teacher-verifies a
--                student-submitted paper score — still used by
--                teacher/assets/js/teacher.js)
--   All four are modified below so EXP is awarded regardless of which page a
--   student/teacher is actually using. apply_assessment_override and
--   apply_quiz_override are NOT modified: both only flip a result flag on an
--   already-graded attempt and never change student_score, so the EXP for
--   that source was already locked in (or correctly zeroed) at the original
--   grading step.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. EXP ledger (protected — no direct write access for authenticated)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.exp_transactions (
    id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id    uuid        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    source_type   varchar(20) NOT NULL CHECK (source_type IN ('quiz', 'pre_test', 'post_test')),
    source_id     uuid        NOT NULL,
    exp_awarded   integer     NOT NULL CHECK (exp_awarded >= 0),
    awarded_at    timestamptz NOT NULL DEFAULT now(),
    UNIQUE (student_id, source_type, source_id)
);

CREATE INDEX IF NOT EXISTS idx_exp_transactions_student
    ON public.exp_transactions(student_id);

ALTER TABLE public.exp_transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS exp_transactions_student_read_own ON public.exp_transactions;
CREATE POLICY exp_transactions_student_read_own
    ON public.exp_transactions
    FOR SELECT
    USING (student_id = auth.uid());

DROP POLICY IF EXISTS exp_transactions_teacher_admin_read ON public.exp_transactions;
CREATE POLICY exp_transactions_teacher_admin_read
    ON public.exp_transactions
    FOR SELECT
    USING (public.is_current_user_teacher_or_admin());

-- No INSERT/UPDATE/DELETE policy is defined for any role, and only SELECT is
-- granted below — direct writes from the client are rejected at both the
-- privilege layer and the RLS layer. The ledger is written exclusively by
-- award_exp_if_first_completion() (section 2), which runs as the function
-- owner and bypasses RLS by design (SECURITY DEFINER).
REVOKE ALL ON public.exp_transactions FROM PUBLIC;
GRANT SELECT ON public.exp_transactions TO authenticated;

-- ----------------------------------------------------------------------------
-- 2. Internal award helper — NOT exposed to authenticated/anon
-- ----------------------------------------------------------------------------
-- Called only from inside the SECURITY DEFINER grading functions in section 4.
-- Every call passes the raw earned score already computed by the caller — no
-- formula, tier, or pass/fail branching happens here. The UNIQUE constraint on
-- exp_transactions is the entire anti-duplication mechanism: calling this on
-- every attempt (not just the first) is intentional and safe, because attempt
-- 2/3 will always hit ON CONFLICT DO NOTHING and leave attempt 1's row intact.
CREATE OR REPLACE FUNCTION public.award_exp_if_first_completion(
    p_student_id  uuid,
    p_source_type varchar,
    p_source_id   uuid,
    p_exp_amount  integer
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.exp_transactions (student_id, source_type, source_id, exp_awarded)
    VALUES (p_student_id, p_source_type, p_source_id, p_exp_amount)
    ON CONFLICT (student_id, source_type, source_id) DO NOTHING;
END;
$$;

-- Deliberately no GRANT EXECUTE to authenticated/anon/public. Callers that are
-- SECURITY DEFINER functions owned by the same role as this function invoke it
-- via ownership, not privilege grant — see the four functions in section 4.
REVOKE ALL ON FUNCTION public.award_exp_if_first_completion(uuid, varchar, uuid, integer) FROM PUBLIC;

-- ----------------------------------------------------------------------------
-- 3. Leaderboard: internal aggregation view + section-scoped RPC
-- ----------------------------------------------------------------------------
-- Internal aggregation only. Deliberately NOT granted to authenticated: a
-- plain SELECT-able view here would let any authenticated caller enumerate
-- every student's total EXP across every section (worse than a section leak,
-- since it has no section filter at all). It exists purely so
-- get_my_section_leaderboard() below has a simple source to read from within
-- its own SECURITY DEFINER context.
CREATE OR REPLACE VIEW public.student_exp_summary AS
SELECT
    student_id,
    COALESCE(SUM(exp_awarded), 0) AS total_exp,
    COUNT(*) AS sources_completed,
    MAX(awarded_at) AS last_earned_at
FROM public.exp_transactions
GROUP BY student_id;

REVOKE ALL ON public.student_exp_summary FROM PUBLIC;
-- No GRANT SELECT to authenticated/anon — internal use only, read exclusively
-- from inside SECURITY DEFINER functions such as the one below.

-- Section-scoped leaderboard, exposed only through a no-argument RPC — not a
-- selectable view. A client-supplied section_id/student_id would be
-- presentation logic pretending to be authorization: a student could edit
-- the request and read another section's rankings. This RPC instead derives
-- the caller's own section server-side from auth.uid() and public.users, so
-- there is no parameter for a client to tamper with. It exposes only
-- rank/full_name/total_exp/quizzes_completed — never student_id, email, LRN,
-- assessment results, raw per-quiz scores, or exp_transactions rows.
CREATE OR REPLACE FUNCTION public.get_my_section_leaderboard()
RETURNS TABLE (
    rank               integer,
    full_name          text,
    total_exp          integer,
    quizzes_completed  integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_caller_id  uuid := auth.uid();
    v_section_id uuid;
BEGIN
    IF v_caller_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT u.section_id INTO v_section_id
    FROM public.users u
    WHERE u.id = v_caller_id;

    -- No section on the caller's own record: safe empty result, not an error.
    IF v_section_id IS NULL THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        ROW_NUMBER() OVER (ORDER BY COALESCE(s.total_exp, 0) DESC, u.full_name ASC)::integer AS rank,
        u.full_name::text AS full_name,
        COALESCE(s.total_exp, 0)::integer AS total_exp,
        COALESCE(s.sources_completed, 0)::integer AS quizzes_completed
    FROM public.users u
    LEFT JOIN public.student_exp_summary s ON s.student_id = u.id
    WHERE u.role = 'student'
      AND u.is_archived = false
      AND u.approval_status = 'approved'
      AND u.section_id = v_section_id
    ORDER BY total_exp DESC, u.full_name ASC;
END;
$$;

-- Teacher/admin access is intentionally NOT added here — not requested, and
-- adding a "see any section" branch would be an assumption, not a
-- specification. A teacher/admin caller gets exactly the same behavior as
-- any other caller: their own users.section_id row, or an empty result if
-- they don't have one set.
REVOKE ALL ON FUNCTION public.get_my_section_leaderboard() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_my_section_leaderboard() FROM anon;
GRANT EXECUTE ON FUNCTION public.get_my_section_leaderboard() TO authenticated;

-- ----------------------------------------------------------------------------
-- 4. Wire the EXP award into every live grading entry point
-- ----------------------------------------------------------------------------

-- 4a. submit_and_grade_regular_quiz (Phase 3, native quiz path)
-- Identical to the Phase 3 body except for one added statement before RETURN.
CREATE OR REPLACE FUNCTION public.submit_and_grade_regular_quiz(
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
        RAISE EXCEPTION 'Submitted answers count does not match total quiz questions';
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
        'approved', -- Native digital quiz auto-approved
        v_new_attempt_number,
        'incomplete',
        now()
    )
    RETURNING id INTO v_submission_id;

    FOR v_q IN
        SELECT id, question_type, correct_answer, points
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
        ELSIF v_q.question_type = 'identification' THEN
            v_is_correct := (LOWER(TRIM(v_student_answer)) = LOWER(TRIM(v_q.correct_answer)));
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
    v_is_passing := (v_score_pct >= COALESCE(v_quiz.passing_threshold, 75.00));

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

    -- Phase 5: EXP = raw earned score, awarded once per (student, quiz),
    -- regardless of pass/fail. No-ops on retake attempts via the unique
    -- constraint on exp_transactions.
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

-- 4b. submit_and_grade_assessment (Phase 3, native pre-test/post-test path)
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
    v_status varchar(30);
    v_remaining_attempts integer;
    v_verification_status varchar(20);
    v_assessment_result varchar(10);
    v_attempt_id uuid;
    v_answer_item record;
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
        SELECT id, question_type, correct_answer, points
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
        ELSIF v_q.question_type = 'identification' THEN
            v_is_correct := (LOWER(TRIM(v_student_answer)) = LOWER(TRIM(v_q.correct_answer)));
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

    -- Phase 5: EXP = raw earned score, source_type mirrors this assessment's
    -- own type ('pre_test' or 'post_test'), awarded once per (student,
    -- assessment) regardless of pass/fail.
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

-- 4c. submit_regular_quiz_score (Phase 2, legacy self-reported quiz score —
-- still used by student/quizzes.html and student/module-view.html)
CREATE OR REPLACE FUNCTION public.submit_regular_quiz_score(
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

    IF v_pct >= COALESCE(v_quiz.passing_threshold, 75.00) THEN
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

-- 4d. verify_assessment_attempt (Phase 2, teacher verifies a student-submitted
-- paper pre-test/post-test score — still used by teacher/assets/js/teacher.js)
CREATE OR REPLACE FUNCTION public.verify_assessment_attempt(
    p_attempt_id uuid,
    p_verified_score smallint DEFAULT NULL,
    p_verified_total smallint DEFAULT NULL,
    p_verification_notes text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_attempt record;
    v_asmt record;
    v_final_score smallint;
    v_final_total smallint;
    v_score_pct numeric(5,2);
    v_result varchar(10);
BEGIN
    IF NOT public.is_current_user_teacher_or_admin() THEN
        RAISE EXCEPTION 'Unauthorized: only teachers or admins may verify assessments';
    END IF;

    SELECT * INTO v_attempt
    FROM public.module_assessment_attempts
    WHERE id = p_attempt_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Attempt not found';
    END IF;

    IF v_attempt.verification_status = 'verified' THEN
        RAISE EXCEPTION 'Attempt is already verified';
    END IF;

    SELECT * INTO v_asmt
    FROM public.module_assessments
    WHERE id = v_attempt.assessment_id;

    v_final_score := COALESCE(p_verified_score, v_attempt.student_score);
    v_final_total := COALESCE(p_verified_total, v_attempt.total_items);

    IF v_final_score < 0 OR v_final_total <= 0 OR v_final_score > v_final_total THEN
        RAISE EXCEPTION 'Invalid verified score bounds';
    END IF;

    v_score_pct := ROUND((v_final_score::numeric / v_final_total::numeric) * 100, 2);

    IF v_score_pct >= v_asmt.passing_threshold THEN
        v_result := 'passed';
    ELSE
        IF v_attempt.attempt_number < v_asmt.max_attempts THEN
            v_result := 'incomplete';
        ELSE
            v_result := 'failed';
        END IF;
    END IF;

    UPDATE public.module_assessment_attempts
    SET student_score = v_final_score,
        total_items = v_final_total,
        verification_status = 'verified',
        verified_by = auth.uid(),
        verified_at = now(),
        verification_notes = p_verification_notes,
        assessment_result = v_result
    WHERE id = p_attempt_id;

    -- Phase 5: EXP = raw verified score, awarded once per (student,
    -- assessment). Caller here is the teacher, so student_id comes from the
    -- attempt row, not auth.uid().
    PERFORM public.award_exp_if_first_completion(v_attempt.student_id, v_asmt.assessment_type, v_attempt.assessment_id, v_final_score);

    RETURN jsonb_build_object(
        'success', true,
        'attempt_id', p_attempt_id,
        'verification_status', 'verified',
        'assessment_result', v_result,
        'score_pct', v_score_pct
    );
END;
$$;

-- Function-level grants for all four functions above are unchanged by
-- CREATE OR REPLACE (signatures are identical to their Phase 2/3 originals),
-- so no GRANT/REVOKE statements are repeated here.

NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- ROLLBACK (manual — run only if this migration must be reverted)
-- ============================================================================
-- Reverting the four CREATE OR REPLACE functions above requires restoring
-- their exact pre-Phase-5 bodies from migration_phase2_formal_assessment_foundation.sql
-- and migration_phase3_native_quiz_cms_and_presentations.sql (CREATE OR REPLACE
-- replaces the whole body, so "just remove the EXP call" is not sufficient —
-- the full prior definition must be re-run from those files).
-- DROP FUNCTION IF EXISTS public.get_my_section_leaderboard();
-- DROP VIEW IF EXISTS public.student_exp_summary;
-- DROP FUNCTION IF EXISTS public.award_exp_if_first_completion(uuid, varchar, uuid, integer);
-- DROP TABLE IF EXISTS public.exp_transactions;
-- NOTIFY pgrst, 'reload schema';
