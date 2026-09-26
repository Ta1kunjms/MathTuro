-- ==============================================================================
-- Migration: Phase 1 Remediation D1 - Restrict Teacher Student Access
-- Target: Supabase Staging (jlmdvcmdvkvdxpfkqivh)
-- Purpose: Restrict teacher access to approved, active students only
-- ==============================================================================

DROP POLICY IF EXISTS teachers_view_all_students ON public.users;

CREATE POLICY teachers_view_all_students ON public.users
  FOR SELECT
  USING (
    role = 'student'
    AND approval_status = 'approved'
    AND is_active = true
    AND public.is_current_user_teacher_or_admin()
  );
