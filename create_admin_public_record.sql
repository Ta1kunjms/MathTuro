-- ============================================================
-- CREATE ADMIN RECORD IN PUBLIC.USERS TABLE
-- This script should be run in the Supabase SQL Editor
-- It will create the missing admin record in public.users table
-- ============================================================

-- Check if admin record already exists
SELECT 
    id, 
    email, 
    full_name, 
    role, 
    is_active,
    created_at
FROM public.users
WHERE email = 'admin@mathturo.com';

-- If no record exists, create it
INSERT INTO public.users (
    id,
    email,
    full_name,
    role,
    avatar_url,
    is_active,
    created_at,
    updated_at
) 
SELECT 
    '15c79e06-017f-48d5-acc0-a44f47d6d1d5',
    'admin@mathturo.com',
    'MathTuro Admin',
    'admin',
    NULL,
    true,
    '2026-02-23 00:51:28.91259+00',
    '2026-02-23 00:51:29.055923+00'
WHERE NOT EXISTS (
    SELECT 1 FROM public.users WHERE email = 'admin@mathturo.com'
);

-- Verify the record was created
SELECT 
    id, 
    email, 
    full_name, 
    role, 
    is_active,
    created_at
FROM public.users
WHERE role = 'admin';

-- ============================================================
-- Verify authentication works by checking if user exists in both tables
-- ============================================================

-- Check auth.users table
SELECT 
    id, 
    email, 
    created_at,
    confirmed_at,
    raw_user_meta_data
FROM auth.users
WHERE email = 'admin@mathturo.com';

-- Check public.users table
SELECT 
    id, 
    email, 
    full_name, 
    role, 
    is_active,
    created_at
FROM public.users
WHERE email = 'admin@mathturo.com';
