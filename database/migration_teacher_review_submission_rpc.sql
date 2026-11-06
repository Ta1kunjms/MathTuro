-- ============================================================================
-- Migration: Teacher review of quiz submissions through an RPC
-- Project: MathTuro LMS (Production: ynkzcybctsstpqxdoweq)
-- Date: 2026-11-06
--
-- Problem: authenticated has no UPDATE privilege on public.quiz_submissions, so
-- Approve/Reject failed with "permission denied".
--
-- Fix: a SECURITY DEFINER function limited to active teachers/admins. UPDATE is
-- deliberately NOT granted to authenticated: the students_update_own_submission
-- policy exists, so a grant would let students approve or edit their own scores.
--
-- Only pending submissions can be reviewed. The on_submission_update trigger
-- forces a rejected row back to pending, so reviewing one would silently undo.
--
-- Safe to re-run. Run in the Supabase SQL Editor as one script.
-- ============================================================================

BEGIN;

CREATE OR REPLACE FUNCTION public.review_quiz_submission(
    p_submission_id uuid,
    p_status text,
    p_comment text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_comment text := NULLIF(btrim(COALESCE(p_comment, '')), '');
    v_current_status text;
BEGIN
    IF auth.uid() IS NULL OR NOT public.is_current_user_teacher_or_admin() THEN
        RAISE EXCEPTION 'Only active teachers and administrators may review submissions' USING ERRCODE = '42501';
    END IF;

    IF p_status NOT IN ('approved', 'rejected') THEN
        RAISE EXCEPTION 'Status must be approved or rejected';
    END IF;

    IF p_status = 'rejected' AND v_comment IS NULL THEN
        RAISE EXCEPTION 'Please provide a comment explaining the rejection';
    END IF;

    SELECT s.status INTO v_current_status
    FROM public.quiz_submissions s
    WHERE s.id = p_submission_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Submission not found';
    END IF;

    IF v_current_status <> 'pending' THEN
        RAISE EXCEPTION 'This submission was already reviewed (%)', v_current_status;
    END IF;

    UPDATE public.quiz_submissions
    SET status = p_status,
        teacher_comment = v_comment,
        reviewed_at = now(),
        reviewed_by = auth.uid()
    WHERE id = p_submission_id;

    RETURN jsonb_build_object('id', p_submission_id, 'status', p_status);
END;
$$;

REVOKE ALL ON FUNCTION public.review_quiz_submission(uuid, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.review_quiz_submission(uuid, text, text) TO authenticated;

COMMIT;
