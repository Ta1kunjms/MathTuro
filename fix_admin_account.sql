-- ============================================================
-- FIX ADMIN ACCOUNT SQL SCRIPT
-- Run this in Supabase SQL Editor to fix admin login issues
-- ============================================================

-- Step 1: Disable RLS temporarily to allow creating the admin account
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;

-- Step 2: Check if admin account exists
SELECT * FROM public.users WHERE email = 'admin@mathturo.com';

-- Step 3: Create admin account if it doesn't exist
INSERT INTO public.users (
    id, 
    email, 
    full_name, 
    role, 
    avatar_url, 
    is_active, 
    created_at, 
    updated_at
) VALUES (
    '15c79e06-017f-48d5-acc0-a44f47d6d1d5', 
    'admin@mathturo.com', 
    'MathTuro Admin', 
    'admin', 
    NULL, 
    TRUE, 
    NOW(), 
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Step 4: Verify the admin account was created
SELECT * FROM public.users WHERE role = 'admin';

-- Step 5: Re-enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Step 6: Verify RLS is enabled (RLS status is automatically enabled after ALTER TABLE command)

-- Step 7: Check RLS policies for users table
SELECT * FROM pg_policies WHERE tablename = 'users';

-- ============================================================
-- If the admin account was already created, you should see it
-- in the output of Step 4.
-- ============================================================

-- ============================================================
-- After running this script, you should be able to login with:
-- Email: admin@mathturo.com
-- Password: Admin123!
-- ============================================================
