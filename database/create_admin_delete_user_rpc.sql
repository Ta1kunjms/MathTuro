-- Admin RPC: delete user from both public.users and auth.users
-- Run this once in Supabase SQL Editor.

BEGIN;

DROP FUNCTION IF EXISTS public.admin_delete_user(uuid);

CREATE OR REPLACE FUNCTION public.admin_delete_user(target_user_id uuid)
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

    SELECT role INTO requester_role
    FROM public.users
    WHERE id = requester_id;

    IF requester_role IS DISTINCT FROM 'admin' THEN
        RAISE EXCEPTION 'Only admins can delete users';
    END IF;

    IF target_user_id = requester_id THEN
        RAISE EXCEPTION 'You cannot delete your own account';
    END IF;

    -- Delete app profile first (safe even if already missing)
    DELETE FROM public.users
    WHERE id = target_user_id;

    -- Delete Supabase Auth account
    DELETE FROM auth.users
    WHERE id = target_user_id;

    RETURN true;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_delete_user(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_delete_user(uuid) TO authenticated;

-- Ensure PostgREST sees the new RPC immediately
NOTIFY pgrst, 'reload schema';

COMMIT;
