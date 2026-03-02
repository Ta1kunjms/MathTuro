-- Sync existing Supabase Auth users into public.users
-- Run in Supabase SQL Editor when auth users exist but public.users is missing rows.

BEGIN;

-- Ensure new auth users automatically get a profile row.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.users (id, email, full_name, role, created_at, updated_at)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE(NULLIF(NEW.raw_user_meta_data->>'role', ''), 'student'),
        COALESCE(NEW.created_at, NOW()),
        NOW()
    )
    ON CONFLICT (id) DO NOTHING;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Backfill missing rows in public.users from existing auth.users.
INSERT INTO public.users (id, email, full_name, role, created_at, updated_at)
SELECT
    au.id,
    au.email,
    COALESCE(au.raw_user_meta_data->>'full_name', split_part(au.email, '@', 1)) AS full_name,
    COALESCE(NULLIF(au.raw_user_meta_data->>'role', ''), 'student') AS role,
    COALESCE(au.created_at, NOW()) AS created_at,
    NOW() AS updated_at
FROM auth.users au
LEFT JOIN public.users pu ON pu.id = au.id
WHERE pu.id IS NULL;

COMMIT;

-- Verification
SELECT
    (SELECT COUNT(*) FROM auth.users) AS auth_user_count,
    (SELECT COUNT(*) FROM public.users) AS public_user_count;
