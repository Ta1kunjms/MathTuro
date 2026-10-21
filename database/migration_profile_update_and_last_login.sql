-- Migration: Safe Profile & Login State Update
-- Description: Ensures authenticated users can update their own last_login and safe profile fields,
-- and provides an atomic RPC for recording logins with activity logging.

DO $$
BEGIN
  -- 1. Ensure users_update_own_profile RLS policy exists
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'users' 
      AND schemaname = 'public' 
      AND policyname = 'users_update_own_profile'
  ) THEN
    CREATE POLICY users_update_own_profile ON public.users
      FOR UPDATE
      USING (auth.uid() = id)
      WITH CHECK (auth.uid() = id);
  END IF;
END $$;

-- 2. Provide atomic record_user_login RPC
CREATE OR REPLACE FUNCTION public.record_user_login()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid;
BEGIN
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Update last_login timestamp on users table
  UPDATE public.users
  SET last_login = now(),
      updated_at = now()
  WHERE id = v_uid;

  -- Record login in activity_log if table exists
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'activity_log'
  ) THEN
    INSERT INTO public.activity_log (user_id, action, details, created_at)
    VALUES (v_uid, 'login', 'User logged in successfully', now());
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.record_user_login() TO authenticated;
