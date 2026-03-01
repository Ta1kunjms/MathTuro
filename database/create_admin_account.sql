-- ============================================================
-- CREATE BUILT-IN ADMIN ACCOUNT FOR MATHTURO SYSTEM
-- ============================================================

-- Run this script in Supabase SQL Editor
-- This creates the built-in admin account with full system privileges

-- ============================================================
-- IMPORTANT: First create the auth user through Supabase Dashboard!
-- ============================================================
-- 1. Go to Authentication > Users > Add User
-- 2. Email: admin@mathturo.com
-- 3. Password: (create a strong password - remember this for login)
-- 4. THEN run this SQL script

-- ============================================================
-- STEP 1: VERIFY AUTH USER EXISTS
-- ============================================================

-- Check if admin user exists in auth.users
SELECT id, email, created_at 
FROM auth.users 
WHERE email = 'admin@mathturo.com';

-- If you get "No rows returned", you need to create the user first!

-- ============================================================
-- STEP 2: CREATE ADMIN USER PROFILE
-- ============================================================

-- Create admin user profile in public.users table
INSERT INTO public.users (
    id, 
    email, 
    full_name, 
    role, 
    is_active, 
    created_at, 
    updated_at
)
SELECT 
    id,
    'admin@mathturo.com',
    'System Admin',
    'admin',
    true,
    NOW(),
    NOW()
FROM auth.users 
WHERE email = 'admin@mathturo.com'
ON CONFLICT (id) DO UPDATE 
SET 
    full_name = EXCLUDED.full_name,
    role = EXCLUDED.role,
    is_active = EXCLUDED.is_active,
    updated_at = EXCLUDED.updated_at;

-- ============================================================
-- STEP 3: VERIFY ADMIN ACCOUNT
-- ============================================================

-- Check that admin user was created successfully
SELECT 
    u.id, 
    u.email, 
    u.full_name, 
    u.role,
    u.is_active,
    u.created_at,
    a.raw_user_meta_data
FROM public.users u
LEFT JOIN auth.users a ON u.id = a.id
WHERE u.role = 'admin';

-- ============================================================
-- STEP 4: CREATE ACCESS POLICY FOR ADMIN QUERIES
-- ============================================================

-- Ensure admin policy for public.users table is in place
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'users' AND policyname = 'admin_manage_all_users'
    ) THEN
        CREATE POLICY "admin_manage_all_users" ON public.users
            FOR ALL USING (
                EXISTS (
                    SELECT 1 FROM public.users 
                    WHERE id = auth.uid() AND role = 'admin'
                )
            );
        RAISE NOTICE 'Created admin_manage_all_users policy';
    ELSE
        RAISE NOTICE 'admin_manage_all_users policy already exists';
    END IF;
END $$;

-- ============================================================
-- SUCCESS MESSAGE
-- ============================================================

RAISE NOTICE 'Admin account profile created successfully!';
RAISE NOTICE 'Admin login credentials:';
RAISE NOTICE 'Email: admin@mathturo.com';
RAISE NOTICE 'Password: (the one you set in Supabase Auth)';