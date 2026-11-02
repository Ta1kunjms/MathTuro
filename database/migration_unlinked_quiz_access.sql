-- ============================================================================
-- Migration: Allow students to take published quizzes not linked to a module
-- Project: MathTuro LMS (Production: ynkzcybctsstpqxdoweq)
-- Date: 2026-11-02
--
-- Problem: can_student_access_quiz returned false whenever quizzes.module_id
-- IS NULL, so a published stand-alone quiz could never be opened by students
-- (student/take-quiz.html showed "Access Locked").
--
-- Fix: a published quiz with no module is open to students. Quizzes linked to
-- a module keep the existing progression gating unchanged.
--
-- Requires separate approval (gating change). Safe to re-run.
-- ============================================================================

BEGIN;

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

    IF NOT FOUND OR NOT COALESCE(v_is_published, false) THEN
        RETURN false;
    END IF;

    -- Stand-alone quiz: no module progression to enforce.
    IF v_module_id IS NULL THEN
        RETURN true;
    END IF;

    RETURN public.can_student_access_module(p_student_id, v_module_id)
       AND public.is_module_content_unlocked(p_student_id, v_module_id);
END;
$$;

REVOKE EXECUTE ON FUNCTION public.can_student_access_quiz(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.can_student_access_quiz(uuid, uuid) TO authenticated;

COMMIT;
