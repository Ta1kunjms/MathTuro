-- ============================================================
-- COMPREHENSIVE ADMIN ACCOUNT FIX
-- Run this in Supabase SQL Editor
-- ============================================================

-- ============================================================
-- PART 1: Check existing user in auth.users
-- ============================================================
SELECT 
    id, 
    email, 
    email_confirmed_at, 
    raw_user_meta_data, 
    created_at 
FROM auth.users 
WHERE email = 'admin@mathturo.com';

-- ============================================================
-- PART 2: Create admin record in public.users
-- ============================================================
-- Disable RLS temporarily
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;

-- Check if record exists
SELECT * FROM public.users WHERE email = 'admin@mathturo.com';

-- Create record if it doesn't exist
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

-- Verify the record was created
SELECT * FROM public.users WHERE role = 'admin';

-- Re-enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- PART 3: Verify all policies are correctly applied
-- ============================================================
SELECT * FROM pg_policies WHERE tablename = 'users';

-- ============================================================
-- PART 4: Check if user has the correct RLS permissions
-- ============================================================
-- Test if we can select admin user with admin role check
WITH test_user AS (
    SELECT '15c79e06-017f-48d5-acc0-a44f47d6d1d5'::uuid as id
)
SELECT * 
FROM public.users u
WHERE EXISTS (
    SELECT 1 FROM public.users 
    WHERE id = (SELECT id FROM test_user) 
    AND role = 'admin'
);

-- ============================================================
-- If you get an empty result in PART 1:
-- It means the user doesn't exist in auth.users.
-- You'll need to create the user through the Supabase Auth console.
-- ============================================================

-- ============================================================
-- If you need to reset the password:
-- 1. Go to Auth > Users
-- 2. Find the user admin@mathturo.com
-- 3. Click Edit
-- 4. Click "Send password reset email"
-- ============================================================
