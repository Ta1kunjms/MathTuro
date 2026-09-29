-- ============================================================================
-- Migration: Phase 4 — Admin Analytics Refinements & User Management Auditing
-- Purpose:
--   1. Add archive (soft-delete) columns to public.users, distinct from the
--      existing approval-workflow is_active flag
--   2. Add admin_archive_user / admin_unarchive_user SECURITY DEFINER RPCs
--   3. Close the destructive admin_delete_user path by revoking EXECUTE from
--      authenticated (function is NOT dropped in this migration)
-- Notes:
--   - This migration is purely additive. No existing rows or columns are
--     dropped or destructively altered. Analytics label/query changes and the
--     archived-login block live in application code (admin/analytics.html,
--     admin/users.html, shared/js/auth.js), not in this file.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Archive columns on public.users
-- ----------------------------------------------------------------------------
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS is_archived boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS archived_at timestamptz,
  ADD COLUMN IF NOT EXISTS archived_by uuid REFERENCES public.users(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_users_is_archived ON public.users(is_archived);

-- ----------------------------------------------------------------------------
-- 2. admin_archive_user — replaces admin_delete_user in the live UI path
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_archive_user(target_user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    requester_id uuid := auth.uid();
    requester_role text;
BEGIN
    IF requester_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT role INTO requester_role FROM public.users WHERE id = requester_id;
    IF requester_role IS DISTINCT FROM 'admin' THEN
        RAISE EXCEPTION 'Only admins can archive users';
    END IF;

    IF target_user_id = requester_id THEN
        RAISE EXCEPTION 'You cannot archive your own account';
    END IF;

    UPDATE public.users
    SET is_archived = true,
        archived_at = now(),
        archived_by = requester_id
    WHERE id = target_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User not found';
    END IF;

    RETURN true;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_archive_user(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_archive_user(uuid) TO authenticated;

-- ----------------------------------------------------------------------------
-- 3. admin_unarchive_user — restores a previously archived user
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_unarchive_user(target_user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    requester_id uuid := auth.uid();
    requester_role text;
BEGIN
    IF requester_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT role INTO requester_role FROM public.users WHERE id = requester_id;
    IF requester_role IS DISTINCT FROM 'admin' THEN
        RAISE EXCEPTION 'Only admins can restore users';
    END IF;

    UPDATE public.users
    SET is_archived = false,
        archived_at = NULL,
        archived_by = NULL
    WHERE id = target_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User not found';
    END IF;

    RETURN true;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_unarchive_user(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_unarchive_user(uuid) TO authenticated;

-- ----------------------------------------------------------------------------
-- 4. Close the destructive delete path (function retained, not dropped)
-- ----------------------------------------------------------------------------
REVOKE EXECUTE ON FUNCTION public.admin_delete_user(uuid) FROM authenticated;

-- Ensure PostgREST sees the new/changed RPCs immediately
NOTIFY pgrst, 'reload schema';

-- ============================================================================
-- ROLLBACK (manual — run only if this migration must be reverted)
-- ============================================================================
-- GRANT EXECUTE ON FUNCTION public.admin_delete_user(uuid) TO authenticated;
-- DROP FUNCTION IF EXISTS public.admin_archive_user(uuid);
-- DROP FUNCTION IF EXISTS public.admin_unarchive_user(uuid);
-- ALTER TABLE public.users DROP COLUMN IF EXISTS is_archived;
-- ALTER TABLE public.users DROP COLUMN IF EXISTS archived_at;
-- ALTER TABLE public.users DROP COLUMN IF EXISTS archived_by;
-- NOTIFY pgrst, 'reload schema';
