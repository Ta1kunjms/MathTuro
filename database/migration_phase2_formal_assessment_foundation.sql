-- ============================================================================
-- Migration: Phase 2 — Formal Assessment Foundation & Progression Gating
-- Purpose:
--   1. Create module_assessments and module_assessment_attempts tables
--   2. Extend quizzes and quiz_submissions with attempt and override tracking
--   3. Implement SECURITY DEFINER RPCs for student submission, teacher verification,
--      and authorized teacher override (in-place terminal row update, no attempt 4,
--      no synthetic scores)
--   4. Implement progression gating helper functions (Option B for pre-test,
--      strict teacher-verified pass/override for post-test, modules.order_index ASC)
--   5. Enforce RLS policies (deny direct student writes, allow RPC access)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Create public.module_assessments
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.module_assessments (
    id                  uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
    module_id           uuid         NOT NULL REFERENCES public.modules(id) ON DELETE CASCADE,
    assessment_type     varchar(10)  NOT NULL CHECK (assessment_type IN ('pre_test', 'post_test')),
    title               varchar(200) NOT NULL,
    description         text,
    quiz_url            text,
    total_items         smallint     NOT NULL CHECK (total_items > 0),
    max_attempts        smallint     NOT NULL DEFAULT 3 CHECK (max_attempts BETWEEN 1 AND 3),
    passing_threshold   numeric(5,2) NOT NULL DEFAULT 75.00 CHECK (passing_threshold BETWEEN 0 AND 100),
    is_published        boolean      NOT NULL DEFAULT false,
    created_by          uuid         REFERENCES public.users(id) ON DELETE SET NULL,
    created_at          timestamptz  NOT NULL DEFAULT now(),
    updated_at          timestamptz  NOT NULL DEFAULT now(),
    CONSTRAINT uq_module_assessment_type UNIQUE (module_id, assessment_type)
);

CREATE INDEX IF NOT EXISTS idx_module_assessments_module_id
    ON public.module_assessments(module_id);
CREATE INDEX IF NOT EXISTS idx_module_assessments_type
    ON public.module_assessments(assessment_type);

-- ----------------------------------------------------------------------------
-- 2. Create public.module_assessment_attempts
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.module_assessment_attempts (
    id                  uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
    assessment_id       uuid         NOT NULL REFERENCES public.module_assessments(id) ON DELETE CASCADE,
    student_id          uuid         NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    attempt_number      smallint     NOT NULL CHECK (attempt_number BETWEEN 1 AND 3),
    student_score       smallint     NOT NULL CHECK (student_score >= 0),
    total_items         smallint     NOT NULL CHECK (total_items > 0),
    score_pct           numeric(5,2) GENERATED ALWAYS AS 
                            (ROUND((student_score::numeric / total_items::numeric) * 100, 2)) STORED,
    verification_status varchar(20)  NOT NULL DEFAULT 'pending'
                            CHECK (verification_status IN ('pending', 'verified', 'rejected')),
    verified_by         uuid         REFERENCES public.users(id),
    verified_at         timestamptz,
    verification_notes  text,
    assessment_result   varchar(10)  NOT NULL DEFAULT 'pending'
                            CHECK (assessment_result IN ('pending', 'passed', 'failed', 'incomplete')),
    is_teacher_override boolean      NOT NULL DEFAULT false,
    override_by         uuid         REFERENCES public.users(id),
    override_at         timestamptz,
    override_reason     text,
    submitted_at        timestamptz  NOT NULL DEFAULT now(),
    created_at          timestamptz  NOT NULL DEFAULT now(),
    CONSTRAINT uq_assessment_student_attempt UNIQUE (assessment_id, student_id, attempt_number),
    CONSTRAINT chk_student_score_lte_total CHECK (student_score <= total_items)
);

CREATE INDEX IF NOT EXISTS idx_maa_assessment_id
    ON public.module_assessment_attempts(assessment_id);
CREATE INDEX IF NOT EXISTS idx_maa_student_id
    ON public.module_assessment_attempts(student_id);
CREATE INDEX IF NOT EXISTS idx_maa_verification_status
    ON public.module_assessment_attempts(verification_status);
CREATE INDEX IF NOT EXISTS idx_maa_assessment_result
    ON public.module_assessment_attempts(assessment_result);

-- ----------------------------------------------------------------------------
-- 3. Extend public.quizzes
-- ----------------------------------------------------------------------------
ALTER TABLE public.quizzes
    ADD COLUMN IF NOT EXISTS quiz_type varchar(10) NOT NULL DEFAULT 'regular'
        CHECK (quiz_type = 'regular'),
    ADD COLUMN IF NOT EXISTS max_attempts smallint NOT NULL DEFAULT 3
        CHECK (max_attempts BETWEEN 1 AND 3),
    ADD COLUMN IF NOT EXISTS passing_threshold numeric(5,2) NOT NULL DEFAULT 75.00
        CHECK (passing_threshold BETWEEN 0 AND 100);

-- ----------------------------------------------------------------------------
-- 4. Extend public.quiz_submissions
-- ----------------------------------------------------------------------------
ALTER TABLE public.quiz_submissions
    ADD COLUMN IF NOT EXISTS attempt_number smallint NOT NULL DEFAULT 1
        CHECK (attempt_number BETWEEN 1 AND 3),
    ADD COLUMN IF NOT EXISTS assessment_result varchar(10)
        CHECK (assessment_result IS NULL OR assessment_result IN ('passed', 'failed', 'incomplete')),
    ADD COLUMN IF NOT EXISTS is_teacher_override boolean NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS override_by uuid REFERENCES public.users(id),
    ADD COLUMN IF NOT EXISTS override_at timestamptz,
    ADD COLUMN IF NOT EXISTS override_reason text;

-- ----------------------------------------------------------------------------
-- 5. Reporting View: public.v_module_assessment_student_summary
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.v_module_assessment_student_summary AS
WITH ranked_attempts AS (
    SELECT 
        maa.*,
        ROW_NUMBER() OVER (
            PARTITION BY maa.assessment_id, maa.student_id 
            ORDER BY maa.attempt_number DESC
        ) AS rn,
        COUNT(*) OVER (
            PARTITION BY maa.assessment_id, maa.student_id
        ) AS total_attempts
    FROM public.module_assessment_attempts maa
)
SELECT 
    ra.id AS latest_attempt_id,
    ra.assessment_id,
    ra.student_id,
    ra.total_attempts,
    ra.attempt_number AS final_attempt_number,
    ra.student_score AS final_numerical_score,
    ra.total_items AS final_total_items,
    ra.score_pct AS final_score_pct,
    ra.verification_status,
    ra.assessment_result AS raw_result,
    ra.is_teacher_override,
    ra.override_reason,
    ra.override_at,
    ra.override_by,
    CASE 
        WHEN ra.is_teacher_override = true THEN 'Passed via Override'
        WHEN ra.verification_status = 'pending' THEN 'Pending Verification'
        WHEN ra.assessment_result = 'passed' THEN 'Passed'
        WHEN ra.assessment_result = 'failed' THEN 'Failed'
        WHEN ra.assessment_result = 'incomplete' THEN 'Retake Allowed'
        ELSE 'Not Started'
    END AS effective_status
FROM ranked_attempts ra
WHERE ra.rn = 1;

-- ----------------------------------------------------------------------------
-- 6. RPC: submit_assessment_score (Student submits paper score)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.submit_assessment_score(
    p_assessment_id uuid,
    p_student_score smallint,
    p_total_items smallint
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_student_id uuid := auth.uid();
    v_asmt record;
    v_existing_count smallint;
    v_has_pending boolean;
    v_has_passed boolean;
    v_new_attempt_number smallint;
    v_attempt_id uuid;
BEGIN
    IF v_student_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Verify assessment exists and is published
    SELECT * INTO v_asmt
    FROM public.module_assessments
    WHERE id = p_assessment_id AND is_published = true;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Assessment not found or not published';
    END IF;

    -- Validate score bounds
    IF p_student_score < 0 OR p_total_items <= 0 OR p_student_score > p_total_items THEN
        RAISE EXCEPTION 'Invalid score or total items';
    END IF;

    -- Check student's prior attempts
    SELECT 
        COUNT(*),
        COALESCE(BOOL_OR(verification_status = 'pending'), false),
        COALESCE(BOOL_OR(assessment_result = 'passed' OR is_teacher_override = true), false)
    INTO v_existing_count, v_has_pending, v_has_passed
    FROM public.module_assessment_attempts
    WHERE assessment_id = p_assessment_id AND student_id = v_student_id;

    IF v_has_passed THEN
        RAISE EXCEPTION 'Assessment has already been passed';
    END IF;

    IF v_has_pending THEN
        RAISE EXCEPTION 'Previous attempt is still pending teacher verification';
    END IF;

    IF v_existing_count >= 3 THEN
        RAISE EXCEPTION 'Maximum attempts (3) already reached';
    END IF;

    v_new_attempt_number := v_existing_count + 1;

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
        p_student_score,
        p_total_items,
        'pending',
        'pending'
    )
    RETURNING id INTO v_attempt_id;

    RETURN jsonb_build_object(
        'success', true,
        'attempt_id', v_attempt_id,
        'attempt_number', v_new_attempt_number,
        'verification_status', 'pending'
    );
END;
$$;

-- ----------------------------------------------------------------------------
-- 7. RPC: verify_assessment_attempt (Teacher verifies paper score)
-- ----------------------------------------------------------------------------
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

    RETURN jsonb_build_object(
        'success', true,
        'attempt_id', p_attempt_id,
        'verification_status', 'verified',
        'assessment_result', v_result,
        'score_pct', v_score_pct
    );
END;
$$;

-- ----------------------------------------------------------------------------
-- 8. RPC: apply_assessment_override (Teacher overrides terminal 3rd failed attempt)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.apply_assessment_override(
    p_attempt_id uuid,
    p_reason text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_attempt record;
BEGIN
    IF NOT public.is_current_user_teacher_or_admin() THEN
        RAISE EXCEPTION 'Unauthorized: only teachers or admins may override assessments';
    END IF;

    IF p_reason IS NULL OR trim(p_reason) = '' THEN
        RAISE EXCEPTION 'An override reason is required';
    END IF;

    SELECT * INTO v_attempt
    FROM public.module_assessment_attempts
    WHERE id = p_attempt_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Attempt not found';
    END IF;

    -- Strict preconditions: Must be verified third-attempt failure
    IF v_attempt.attempt_number <> 3 THEN
        RAISE EXCEPTION 'Overrides can only be applied to terminal third attempts (current attempt: %)', v_attempt.attempt_number;
    END IF;

    IF v_attempt.verification_status <> 'verified' THEN
        RAISE EXCEPTION 'Attempt must be teacher-verified before an override can be applied';
    END IF;

    IF v_attempt.assessment_result <> 'failed' THEN
        RAISE EXCEPTION 'Only failed assessments can be overridden (current result: %)', v_attempt.assessment_result;
    END IF;

    IF v_attempt.is_teacher_override THEN
        RAISE EXCEPTION 'Assessment has already been overridden';
    END IF;

    -- Update row in-place. Scores remain unmodified. No attempt 4 created.
    UPDATE public.module_assessment_attempts
    SET is_teacher_override = true,
        override_by = auth.uid(),
        override_at = now(),
        override_reason = trim(p_reason)
    WHERE id = p_attempt_id;

    RETURN jsonb_build_object(
        'success', true,
        'attempt_id', p_attempt_id,
        'attempt_number', 3,
        'effective_status', 'Passed via Override',
        'student_score', v_attempt.student_score,
        'total_items', v_attempt.total_items
    );
END;
$$;

-- ----------------------------------------------------------------------------
-- 9. RPC: submit_regular_quiz_score (Student submits regular quiz score)
-- ----------------------------------------------------------------------------
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

    RETURN jsonb_build_object(
        'success', true,
        'submission_id', v_submission_id,
        'attempt_number', v_new_attempt,
        'assessment_result', v_result,
        'score_pct', v_pct
    );
END;
$$;

-- ----------------------------------------------------------------------------
-- 10. RPC: apply_quiz_override (Teacher overrides terminal 3rd failed quiz)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.apply_quiz_override(
    p_submission_id uuid,
    p_reason text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_sub record;
BEGIN
    IF NOT public.is_current_user_teacher_or_admin() THEN
        RAISE EXCEPTION 'Unauthorized: only teachers or admins may override quiz scores';
    END IF;

    IF p_reason IS NULL OR trim(p_reason) = '' THEN
        RAISE EXCEPTION 'An override reason is required';
    END IF;

    SELECT * INTO v_sub
    FROM public.quiz_submissions
    WHERE id = p_submission_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Submission not found';
    END IF;

    IF v_sub.attempt_number <> 3 THEN
        RAISE EXCEPTION 'Overrides can only be applied to terminal third attempts (current attempt: %)', v_sub.attempt_number;
    END IF;

    IF v_sub.assessment_result <> 'failed' THEN
        RAISE EXCEPTION 'Only failed quizzes can be overridden';
    END IF;

    IF v_sub.is_teacher_override THEN
        RAISE EXCEPTION 'Quiz submission has already been overridden';
    END IF;

    UPDATE public.quiz_submissions
    SET is_teacher_override = true,
        override_by = auth.uid(),
        override_at = now(),
        override_reason = trim(p_reason)
    WHERE id = p_submission_id;

    RETURN jsonb_build_object(
        'success', true,
        'submission_id', p_submission_id,
        'attempt_number', 3,
        'effective_status', 'Passed via Override'
    );
END;
$$;

-- ----------------------------------------------------------------------------
-- 11. Helper: is_module_content_unlocked (Option B: pre-test attempted once)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_module_content_unlocked(
    p_student_id uuid,
    p_module_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_pre_test_id uuid;
BEGIN
    -- Check if this module has a pre-test defined
    SELECT id INTO v_pre_test_id
    FROM public.module_assessments
    WHERE module_id = p_module_id AND assessment_type = 'pre_test';

    -- If no pre-test exists for this module, content is accessible
    IF v_pre_test_id IS NULL THEN
        RETURN true;
    END IF;

    -- Option B: Any attempt by the student unlocks module content immediately
    RETURN EXISTS (
        SELECT 1
        FROM public.module_assessment_attempts
        WHERE assessment_id = v_pre_test_id
          AND student_id = p_student_id
    );
END;
$$;

-- ----------------------------------------------------------------------------
-- 12. Helper: has_student_passed_post_test (Strict verified pass or override)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.has_student_passed_post_test(
    p_student_id uuid,
    p_module_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_post_test_id uuid;
BEGIN
    SELECT id INTO v_post_test_id
    FROM public.module_assessments
    WHERE module_id = p_module_id AND assessment_type = 'post_test';

    -- If no post-test exists for this module, progression is not blocked
    IF v_post_test_id IS NULL THEN
        RETURN true;
    END IF;

    -- Strict progression: Must be verified AND (passed OR overridden)
    RETURN EXISTS (
        SELECT 1
        FROM public.module_assessment_attempts
        WHERE assessment_id = v_post_test_id
          AND student_id = p_student_id
          AND verification_status = 'verified'
          AND (assessment_result = 'passed' OR is_teacher_override = true)
    );
END;
$$;

-- ----------------------------------------------------------------------------
-- 13. Helper: can_student_access_module (Sequencing via modules.order_index ASC)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.can_student_access_module(
    p_student_id uuid,
    p_module_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_target_order integer;
    v_preceding_module_id uuid;
BEGIN
    SELECT order_index INTO v_target_order
    FROM public.modules
    WHERE id = p_module_id;

    IF v_target_order IS NULL THEN
        RETURN true;
    END IF;

    -- Find immediately preceding published module based on order_index ASC
    SELECT id INTO v_preceding_module_id
    FROM public.modules
    WHERE status = 'published'
      AND order_index < v_target_order
    ORDER BY order_index DESC
    LIMIT 1;

    -- If no preceding module exists, this is the first module -> accessible
    IF v_preceding_module_id IS NULL THEN
        RETURN true;
    END IF;

    -- Preceding module's post-test must be passed (verified) or overridden
    RETURN public.has_student_passed_post_test(p_student_id, v_preceding_module_id);
END;
$$;

-- ----------------------------------------------------------------------------
-- 14. Row Level Security Configuration
-- ----------------------------------------------------------------------------
ALTER TABLE public.module_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.module_assessment_attempts ENABLE ROW LEVEL SECURITY;

-- module_assessments policies
DROP POLICY IF EXISTS ma_teachers_manage ON public.module_assessments;
CREATE POLICY ma_teachers_manage ON public.module_assessments
    FOR ALL
    USING (public.is_current_user_teacher_or_admin())
    WITH CHECK (public.is_current_user_teacher_or_admin());

DROP POLICY IF EXISTS ma_students_read ON public.module_assessments;
CREATE POLICY ma_students_read ON public.module_assessments
    FOR SELECT
    USING (
        is_published = true
        AND EXISTS (
            SELECT 1 FROM public.users
            WHERE id = auth.uid()
              AND role = 'student'
              AND approval_status = 'approved'
              AND is_active = true
        )
    );

-- module_assessment_attempts policies
DROP POLICY IF EXISTS maa_student_read_own ON public.module_assessment_attempts;
CREATE POLICY maa_student_read_own ON public.module_assessment_attempts
    FOR SELECT
    USING (student_id = auth.uid());

DROP POLICY IF EXISTS maa_teachers_read ON public.module_assessment_attempts;
CREATE POLICY maa_teachers_read ON public.module_assessment_attempts
    FOR SELECT
    USING (public.is_current_user_teacher_or_admin());

-- Revoke direct student write on quiz_submissions (routing writes to RPC)
DROP POLICY IF EXISTS submissions_create_own ON public.quiz_submissions;
DROP POLICY IF EXISTS submissions_update_own ON public.quiz_submissions;

-- Maintain teacher review update on quiz_submissions
DROP POLICY IF EXISTS submissions_teacher_update ON public.quiz_submissions;
CREATE POLICY submissions_teacher_update ON public.quiz_submissions
    FOR UPDATE
    USING (public.is_current_user_teacher_or_admin())
    WITH CHECK (public.is_current_user_teacher_or_admin());
