-- ============================================================
-- CREATE ADMIN ACCOUNT SCRIPT
-- Learning Management System
-- ============================================================
-- Run this script in the Supabase SQL Editor
-- This will create an admin user with all necessary permissions
-- ============================================================

-- ============================================================
-- IMPORTANT NOTES
-- ============================================================
-- 1. You need to have at least one admin account to manage the system
-- 2. Replace 'admin@example.com' and 'your-strong-password' with your own values
-- 3. Make sure to use a strong password (minimum 8 characters with mixed types)
-- 4. The user will be created with the 'admin' role in the public.users table

-- ============================================================
-- Step 1: Create the user in the auth.users table
-- ============================================================
-- This will create a new user account in the Supabase auth system

-- First, we'll use the supabase.auth.createUser() function to create the user
-- This function is only available in the SQL editor context

DO $$
DECLARE
  new_user_id UUID;
BEGIN
  -- Create the user in auth.users
  INSERT INTO auth.users (
    email,
    email_confirmed_at,
    encrypted_password,
    raw_user_meta_data,
    created_at,
    updated_at
  ) VALUES (
    'admin@example.com',
    NOW(),
    -- You can generate a proper bcrypt hash using online tools or libraries
    -- For testing purposes, you can use the default Supabase password hashing
    -- or use a tool like https://bcrypt-generator.com/
    -- Example: $2a$10$nTHYVs2a5s0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a
    '$2a$10$QvJQvJQvJQvJQvJQvJQvJQvJQvJQvJQvJQvJQvJQvJQvJQvJQvJQvJQvJQvJ',
    '{
      "full_name": "System Administrator",
      "role": "admin"
    }'::jsonb,
    NOW(),
    NOW()
  )
  RETURNING id INTO new_user_id;

  -- ============================================================
  -- Step 2: Create the user in the public.users table
  -- ============================================================
  -- This will create a corresponding user record in the public.users table
  -- with the 'admin' role

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
    new_user_id,
    'admin@example.com',
    'System Administrator',
    'admin',
    NULL,
    true,
    NOW(),
    NOW()
  );

  -- ============================================================
  -- Step 3: Verify the account creation
  -- ============================================================
  RAISE NOTICE 'Admin account created successfully!';
  RAISE NOTICE 'User ID: %', new_user_id;
  RAISE NOTICE 'Email: admin@example.com';
  RAISE NOTICE 'Role: admin';

EXCEPTION
  WHEN unique_violation THEN
    RAISE NOTICE 'Admin account with email admin@example.com already exists';
  WHEN OTHERS THEN
    RAISE NOTICE 'Error creating admin account: %', SQLERRM;
END $$;

-- ============================================================
-- ALTERNATIVE METHOD: USING SUPABASE AUTH API (RECOMMENDED)
-- ============================================================
-- If you prefer to use the Supabase Auth API, you can use this approach:
-- 
-- 1. Go to your Supabase project dashboard
-- 2. Navigate to "Authentication" > "Users"
-- 3. Click "Add user" button
-- 4. Fill in the details:
--    - Email: admin@example.com
--    - Password: your-strong-password
--    - Confirm password: your-strong-password
-- 5. Click "Create user"
-- 6. Then run the following SQL to update the role to 'admin':
-- 
-- UPDATE public.users 
-- SET role = 'admin', full_name = 'System Administrator'
-- WHERE email = 'admin@example.com';

-- ============================================================
-- VERIFICATION QUERY
-- ============================================================
-- Run this query to verify the admin account exists

SELECT 
  id, 
  email, 
  role, 
  full_name,
  is_active,
  created_at
FROM public.users
WHERE role = 'admin';

-- ============================================================
-- TROUBLESHOOTING
-- ============================================================
-- If you get a "permission denied" error, make sure you're using a
-- PostgreSQL role with sufficient permissions (e.g., postgres or service_role)