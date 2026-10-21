-- ============================================================================
-- Migration: Phase 5 Remediation — Gate Legacy Self-Reported Quiz Score RPC
-- Project: MathTuro LMS (Staging: jlmdvcmdvkvdxpfkqivh)
--
-- Problem: submit_regular_quiz_score (still used by student/quizzes.html,
-- student/module-view.html, student/assets/js/student.js) had no progression
-- check and accepted any client-chosen p_total/p_score (up to 32767). The
-- score is awarded as EXP, so a student could pass a locked quiz and inflate
-- the leaderboard.
--
-- Fix: keep the existing logic as *_core (not callable by clients) and expose
-- a gated wrapper under the original name that requires module access,
-- rejects natively graded quizzes, and pins p_total to quizzes.total_items.
--
-- Run AFTER migration_phase5_exp_gamification_and_leaderboard.sql. If phase 5
-- is re-run later it replaces the wrapper with the ungated function, so run
-- this file again afterwards.
-- ============================================================================

DO $$
BEGIN
    IF to_regprocedure('public.submit_regular_quiz_score_core(uuid, smallint, smallint)') IS NULL THEN
        ALTER FUNCTION public.submit_regular_quiz_score(uuid, smallint, smallint)
            RENAME TO submit_regular_quiz_score_core;
    END IF;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.submit_regular_quiz_score_core(uuid, smallint, smallint) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.submit_regular_quiz_score(
    p_quiz_id uuid,
    p_score smallint,
    p_total smallint
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_total integer;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    IF NOT public.can_student_access_quiz(auth.uid(), p_quiz_id) THEN
        RAISE EXCEPTION 'Quiz access locked by module progression or unpublished';
    END IF;

    -- Natively authored quizzes must go through server-side grading
    IF EXISTS (SELECT 1 FROM public.quiz_questions qq WHERE qq.quiz_id = p_quiz_id) THEN
        RAISE EXCEPTION 'This quiz is graded automatically; submit answers instead of a score';
    END IF;

    SELECT q.total_items INTO v_total FROM public.quizzes q WHERE q.id = p_quiz_id;
    IF p_total IS DISTINCT FROM v_total THEN
        RAISE EXCEPTION 'Total items must match the quiz (%)', v_total;
    END IF;

    RETURN public.submit_regular_quiz_score_core(p_quiz_id, p_score, p_total);
END;
$$;

REVOKE EXECUTE ON FUNCTION public.submit_regular_quiz_score(uuid, smallint, smallint) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.submit_regular_quiz_score(uuid, smallint, smallint) TO authenticated;
