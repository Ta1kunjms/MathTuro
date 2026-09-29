-- ============================================================================
-- Migration: Phase 3 — Native Quiz CMS, Protected Server-Side Auto-Grading,
--                      PDF-Only Presentation Engine & Curriculum Linkage
-- Project: MathTuro LMS (Staging: jlmdvcmdvkvdxpfkqivh)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Extend public.modules with Term & Week Curriculum Hierarchy
-- ----------------------------------------------------------------------------
ALTER TABLE public.modules
    ADD COLUMN IF NOT EXISTS term_number smallint DEFAULT 1 CHECK (term_number BETWEEN 1 AND 3),
    ADD COLUMN IF NOT EXISTS week_number smallint CHECK (week_number IS NULL OR (week_number BETWEEN 1 AND 12));

CREATE INDEX IF NOT EXISTS idx_modules_term_number ON public.modules(term_number);
CREATE INDEX IF NOT EXISTS idx_modules_week_number ON public.modules(week_number);

-- ----------------------------------------------------------------------------
-- 2. Create public.quiz_questions (Native Item Bank)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.quiz_questions (
    id                uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
    quiz_id           uuid         REFERENCES public.quizzes(id) ON DELETE CASCADE,
    assessment_id     uuid         REFERENCES public.module_assessments(id) ON DELETE CASCADE,
    order_index       smallint     NOT NULL CHECK (order_index > 0),
    question_text     text         NOT NULL,
    question_type     varchar(20)  NOT NULL CHECK (question_type IN ('multiple_choice', 'true_false', 'identification')),
    options           jsonb,       -- Array of objects: [{"id": "A", "text": "1/2"}, {"id": "B", "text": "3/4"}]
    correct_answer    text         NOT NULL, -- Kept secret; never exposed to student clients
    points            smallint     NOT NULL DEFAULT 1 CHECK (points > 0),
    explanation       text,        -- Teacher-only explanation
    created_at        timestamptz  NOT NULL DEFAULT now(),
    updated_at        timestamptz  NOT NULL DEFAULT now(),
    CONSTRAINT chk_exclusive_owner CHECK (
        (quiz_id IS NOT NULL AND assessment_id IS NULL) OR
        (quiz_id IS NULL AND assessment_id IS NOT NULL)
    ),
    CONSTRAINT chk_options_format CHECK (
        (question_type = 'identification' AND options IS NULL) OR
        (question_type IN ('multiple_choice', 'true_false') AND jsonb_typeof(options) = 'array' AND jsonb_array_length(options) >= 2)
    )
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_quiz_questions_quiz_order 
    ON public.quiz_questions(quiz_id, order_index) 
    WHERE quiz_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_quiz_questions_asmt_order 
    ON public.quiz_questions(assessment_id, order_index) 
    WHERE assessment_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_qq_quiz_id ON public.quiz_questions(quiz_id);
CREATE INDEX IF NOT EXISTS idx_qq_assessment_id ON public.quiz_questions(assessment_id);

-- ----------------------------------------------------------------------------
-- 3. Create public.quiz_attempt_answers (Teacher-Only Itemized Audit Trail)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.quiz_attempt_answers (
    id                    uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
    assessment_attempt_id uuid         REFERENCES public.module_assessment_attempts(id) ON DELETE CASCADE,
    quiz_submission_id    uuid         REFERENCES public.quiz_submissions(id) ON DELETE CASCADE,
    question_id           uuid         NOT NULL REFERENCES public.quiz_questions(id) ON DELETE CASCADE,
    student_answer        text         NOT NULL,
    is_correct            boolean      NOT NULL,
    points_awarded        smallint     NOT NULL DEFAULT 0 CHECK (points_awarded >= 0),
    created_at            timestamptz  NOT NULL DEFAULT now(),
    CONSTRAINT chk_exclusive_attempt CHECK (
        (assessment_attempt_id IS NOT NULL AND quiz_submission_id IS NULL) OR
        (assessment_attempt_id IS NULL AND quiz_submission_id IS NOT NULL)
    ),
    CONSTRAINT uq_asmt_attempt_question UNIQUE (assessment_attempt_id, question_id),
    CONSTRAINT uq_quiz_sub_question UNIQUE (quiz_submission_id, question_id)
);

CREATE INDEX IF NOT EXISTS idx_qaa_asmt_attempt ON public.quiz_attempt_answers(assessment_attempt_id);
CREATE INDEX IF NOT EXISTS idx_qaa_quiz_sub ON public.quiz_attempt_answers(quiz_submission_id);
CREATE INDEX IF NOT EXISTS idx_qaa_question ON public.quiz_attempt_answers(question_id);

-- ----------------------------------------------------------------------------
-- 4. Create public.presentations (PDF Slide Decks)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.presentations (
    id                uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
    module_id         uuid         NOT NULL REFERENCES public.modules(id) ON DELETE CASCADE,
    lesson_id         uuid         REFERENCES public.lessons(id) ON DELETE SET NULL,
    title             varchar(200) NOT NULL,
    description       text,
    file_path         text         NOT NULL, -- Canonical path in private bucket: presentations/<module_id>/<id>.pdf
    file_size_bytes   bigint       NOT NULL CHECK (file_size_bytes > 0 AND file_size_bytes <= 26214400), -- 25 MB max
    page_count        integer      DEFAULT 0 CHECK (page_count >= 0),
    order_index       smallint     NOT NULL DEFAULT 1 CHECK (order_index > 0),
    is_published      boolean      NOT NULL DEFAULT false,
    uploaded_by       uuid         REFERENCES public.users(id) ON DELETE SET NULL,
    created_at        timestamptz  NOT NULL DEFAULT now(),
    updated_at        timestamptz  NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_presentations_module ON public.presentations(module_id);
CREATE INDEX IF NOT EXISTS idx_presentations_lesson ON public.presentations(lesson_id);
CREATE INDEX IF NOT EXISTS idx_presentations_published ON public.presentations(is_published);

-- ----------------------------------------------------------------------------
-- 5. Access Precondition Helper Functions
-- ----------------------------------------------------------------------------

-- Pre-Test: Accessible even if module content is locked (Option B), provided parent module is accessible in sequence
CREATE OR REPLACE FUNCTION public.can_student_access_pre_test(
    p_student_id uuid,
    p_assessment_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_module_id uuid;
    v_asmt_type varchar(10);
    v_is_published boolean;
BEGIN
    SELECT a.module_id, a.assessment_type, a.is_published 
    INTO v_module_id, v_asmt_type, v_is_published
    FROM public.module_assessments a
    WHERE a.id = p_assessment_id;

    IF v_module_id IS NULL OR v_asmt_type <> 'pre_test' OR NOT v_is_published THEN
        RETURN false;
    END IF;

    -- Sequential module access required; content lock intentionally bypassed for pre-test
    RETURN public.can_student_access_module(p_student_id, v_module_id);
END;
$$;

REVOKE EXECUTE ON FUNCTION public.can_student_access_pre_test(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.can_student_access_pre_test(uuid, uuid) TO authenticated;

-- Regular Quiz: Requires sequential module access AND module content unlock
CREATE OR REPLACE FUNCTION public.can_student_access_quiz(
    p_student_id uuid,
    p_quiz_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_module_id uuid;
    v_is_published boolean;
BEGIN
    SELECT q.module_id, q.is_published INTO v_module_id, v_is_published
    FROM public.quizzes q
    WHERE q.id = p_quiz_id;

    IF v_module_id IS NULL OR NOT v_is_published THEN
        RETURN false;
    END IF;

    RETURN public.can_student_access_module(p_student_id, v_module_id)
       AND public.is_module_content_unlocked(p_student_id, v_module_id);
END;
$$;

REVOKE EXECUTE ON FUNCTION public.can_student_access_quiz(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.can_student_access_quiz(uuid, uuid) TO authenticated;

-- Post-Test: Requires sequential module access AND pre-test content unlock
CREATE OR REPLACE FUNCTION public.can_student_access_post_test(
    p_student_id uuid,
    p_assessment_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_module_id uuid;
    v_asmt_type varchar(10);
    v_is_published boolean;
BEGIN
    SELECT a.module_id, a.assessment_type, a.is_published 
    INTO v_module_id, v_asmt_type, v_is_published
    FROM public.module_assessments a
    WHERE a.id = p_assessment_id;

    IF v_module_id IS NULL OR v_asmt_type <> 'post_test' OR NOT v_is_published THEN
        RETURN false;
    END IF;

    RETURN public.can_student_access_module(p_student_id, v_module_id)
       AND public.is_module_content_unlocked(p_student_id, v_module_id);
END;
$$;

REVOKE EXECUTE ON FUNCTION public.can_student_access_post_test(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.can_student_access_post_test(uuid, uuid) TO authenticated;

-- ----------------------------------------------------------------------------
-- 6. Sanitized Student Question Delivery RPCs (No Answer Keys)
-- ----------------------------------------------------------------------------

-- Contract 1: Fetch questions for regular practice quizzes
CREATE OR REPLACE FUNCTION public.get_quiz_questions_for_student(
    p_quiz_id uuid
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
        qq.question_text,
        qq.question_type,
        qq.options,
        qq.points
    FROM public.quiz_questions qq
    WHERE qq.quiz_id = p_quiz_id
    ORDER BY qq.order_index ASC;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.get_quiz_questions_for_student(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_quiz_questions_for_student(uuid) TO authenticated;

-- Contract 2: Fetch questions for formal pre-tests or post-tests
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

    SELECT * INTO v_asmt FROM public.module_assessments WHERE id = p_assessment_id AND is_published = true;
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

REVOKE EXECUTE ON FUNCTION public.get_assessment_questions_for_student(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_assessment_questions_for_student(uuid) TO authenticated;

-- ----------------------------------------------------------------------------
-- 7. Server-Side Auto-Grading RPCs (Option A: Post-Test Auto-Graded Finality)
-- ----------------------------------------------------------------------------

-- Grade Formal Pre-Test or Post-Test
CREATE OR REPLACE FUNCTION public.submit_and_grade_assessment(
    p_assessment_id uuid,
    p_answers jsonb -- Array of objects: [{"question_id": "...", "answer": "..."}]
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

    -- Concurrency serialization lock per student + assessment
    PERFORM pg_advisory_xact_lock(hashtext(v_student_id::text || p_assessment_id::text));

    SELECT * INTO v_asmt FROM public.module_assessments WHERE id = p_assessment_id AND is_published = true;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Assessment not found or unpublished';
    END IF;

    -- Check prior attempt status
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

    -- Fetch and validate total items in assessment
    SELECT COUNT(*), COALESCE(SUM(points), 0)
    INTO v_total_questions, v_total_possible_score
    FROM public.quiz_questions
    WHERE assessment_id = p_assessment_id;

    IF v_total_questions = 0 OR v_total_possible_score <= 0 THEN
        RAISE EXCEPTION 'No questions configured for this assessment';
    END IF;

    -- Verify answer array length
    IF p_answers IS NULL OR jsonb_array_length(p_answers) <> v_total_questions THEN
        RAISE EXCEPTION 'Submitted answers count (%) does not match required total questions (%)', 
            COALESCE(jsonb_array_length(p_answers), 0), v_total_questions;
    END IF;

    -- Create tentative attempt row
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
        0, -- placeholder, updated below
        v_total_possible_score,
        'pending',
        'pending'
    )
    RETURNING id INTO v_attempt_id;

    -- Grade answers against secret answer keys
    FOR v_q IN 
        SELECT id, question_type, correct_answer, points
        FROM public.quiz_questions
        WHERE assessment_id = p_assessment_id
        ORDER BY order_index ASC
    LOOP
        -- Find submitted answer for this question
        SELECT item->>'answer' INTO v_student_answer
        FROM jsonb_array_elements(p_answers) AS item
        WHERE (item->>'question_id')::uuid = v_q.id;

        IF v_student_answer IS NULL THEN
            RAISE EXCEPTION 'Missing answer for question ID %', v_q.id;
        END IF;

        -- Evaluate correctness
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

        -- Record item audit trail
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

    -- Compute score percentage
    v_score_pct := ROUND((v_earned_score::numeric / v_total_possible_score::numeric) * 100, 2);
    v_is_passing := (v_score_pct >= v_asmt.passing_threshold);

    -- Apply Option A: Native Auto-Graded Finality
    IF v_asmt.assessment_type = 'post_test' THEN
        IF v_is_passing THEN
            v_verification_status := 'verified'; -- Auto-verified by system
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
    ELSE -- Pre-test (Option B: unlocks on any attempt)
        v_verification_status := 'verified';
        v_assessment_result := CASE WHEN v_is_passing THEN 'passed' ELSE 'incomplete' END;
        v_status := CASE WHEN v_is_passing THEN 'Passed' ELSE 'Incomplete' END;
        v_remaining_attempts := 0; -- Pre-test completed
    END IF;

    -- Update attempt record with definitive scores
    UPDATE public.module_assessment_attempts
    SET student_score = v_earned_score,
        total_items = v_total_possible_score,
        verification_status = v_verification_status,
        assessment_result = v_assessment_result
    WHERE id = v_attempt_id;

    -- Strict Aggregate-Only Return Contract
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

REVOKE EXECUTE ON FUNCTION public.submit_and_grade_assessment(uuid, jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_and_grade_assessment(uuid, jsonb) TO authenticated;

-- Grade Regular Practice Quiz
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

REVOKE EXECUTE ON FUNCTION public.submit_and_grade_regular_quiz(uuid, jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_and_grade_regular_quiz(uuid, jsonb) TO authenticated;

-- ----------------------------------------------------------------------------
-- 8. Presentation Signed URL Access Helper
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_presentation_signed_path(
    p_presentation_id uuid
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_user_id uuid := auth.uid();
    v_pres record;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT * INTO v_pres FROM public.presentations WHERE id = p_presentation_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Presentation not found';
    END IF;

    IF NOT public.is_current_user_teacher_or_admin() THEN
        IF NOT v_pres.is_published THEN
            RAISE EXCEPTION 'Presentation is unpublished';
        END IF;

        IF NOT public.can_student_access_module(v_user_id, v_pres.module_id)
           OR NOT public.is_module_content_unlocked(v_user_id, v_pres.module_id) THEN
            RAISE EXCEPTION 'Access locked by module progression';
        END IF;
    END IF;

    RETURN v_pres.file_path;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.get_presentation_signed_path(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_presentation_signed_path(uuid) TO authenticated;

-- ----------------------------------------------------------------------------
-- 9. Operation-Specific Row Level Security Policies
-- ----------------------------------------------------------------------------

-- quiz_questions
ALTER TABLE public.quiz_questions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS qq_select_teacher_admin ON public.quiz_questions;
CREATE POLICY qq_select_teacher_admin ON public.quiz_questions
    FOR SELECT USING (public.is_current_user_teacher_or_admin());

DROP POLICY IF EXISTS qq_insert_teacher_admin ON public.quiz_questions;
CREATE POLICY qq_insert_teacher_admin ON public.quiz_questions
    FOR INSERT WITH CHECK (public.is_current_user_teacher_or_admin());

DROP POLICY IF EXISTS qq_update_teacher_admin ON public.quiz_questions;
CREATE POLICY qq_update_teacher_admin ON public.quiz_questions
    FOR UPDATE 
    USING (public.is_current_user_teacher_or_admin())
    WITH CHECK (public.is_current_user_teacher_or_admin());

DROP POLICY IF EXISTS qq_delete_teacher_admin ON public.quiz_questions;
CREATE POLICY qq_delete_teacher_admin ON public.quiz_questions
    FOR DELETE USING (public.is_current_user_teacher_or_admin());

-- quiz_attempt_answers
ALTER TABLE public.quiz_attempt_answers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS qaa_select_teacher_admin ON public.quiz_attempt_answers;
CREATE POLICY qaa_select_teacher_admin ON public.quiz_attempt_answers
    FOR SELECT USING (public.is_current_user_teacher_or_admin());

DROP POLICY IF EXISTS qaa_insert_nobody ON public.quiz_attempt_answers;
CREATE POLICY qaa_insert_nobody ON public.quiz_attempt_answers
    FOR INSERT WITH CHECK (false);

DROP POLICY IF EXISTS qaa_update_nobody ON public.quiz_attempt_answers;
CREATE POLICY qaa_update_nobody ON public.quiz_attempt_answers
    FOR UPDATE USING (false);

DROP POLICY IF EXISTS qaa_delete_teacher_admin ON public.quiz_attempt_answers;
CREATE POLICY qaa_delete_teacher_admin ON public.quiz_attempt_answers
    FOR DELETE USING (public.is_current_user_teacher_or_admin());

-- presentations
ALTER TABLE public.presentations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS pres_select_teacher_admin ON public.presentations;
CREATE POLICY pres_select_teacher_admin ON public.presentations
    FOR SELECT USING (public.is_current_user_teacher_or_admin());

DROP POLICY IF EXISTS pres_select_student ON public.presentations;
CREATE POLICY pres_select_student ON public.presentations
    FOR SELECT USING (
        is_published = true 
        AND public.can_student_access_module(auth.uid(), module_id)
        AND public.is_module_content_unlocked(auth.uid(), module_id)
    );

DROP POLICY IF EXISTS pres_insert_teacher_admin ON public.presentations;
CREATE POLICY pres_insert_teacher_admin ON public.presentations
    FOR INSERT WITH CHECK (public.is_current_user_teacher_or_admin());

DROP POLICY IF EXISTS pres_update_teacher_admin ON public.presentations;
CREATE POLICY pres_update_teacher_admin ON public.presentations
    FOR UPDATE 
    USING (public.is_current_user_teacher_or_admin())
    WITH CHECK (public.is_current_user_teacher_or_admin());

DROP POLICY IF EXISTS pres_delete_teacher_admin ON public.presentations;
CREATE POLICY pres_delete_teacher_admin ON public.presentations
    FOR DELETE USING (public.is_current_user_teacher_or_admin());
