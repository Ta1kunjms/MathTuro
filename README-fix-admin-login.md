# Fix Admin Login Issue

## Problem
The admin login is failing because of "infinite recursion detected in policy for relation 'users'" error in Supabase. This happens when the RLS policy tries to query the users table to check if the user is an admin, which triggers the same policy again.

## Solution

### Step 1: Fix the RLS Policy on Users Table
Run this SQL script in your Supabase SQL Editor to fix the recursive policy:

```sql
-- ============================================================
-- FIX RLS POLICY FOR USERS TABLE - RESOLVE INFINITE RECURSION
-- ============================================================

-- The current admin_manage_all_users policy causes infinite recursion
-- because it queries the users table to check the user's role, which 
-- triggers the same policy again.

-- ============================================================
-- STEP 1: DROP EXISTING POLICY
-- ============================================================

DROP POLICY IF EXISTS "admin_manage_all_users" ON public.users;

-- ============================================================
-- STEP 2: CREATE FIXED RLS POLICIES FOR USERS TABLE
-- ============================================================

-- Policy 1: Allow users to read their own profile
CREATE POLICY "users_read_own_profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

-- Policy 2: Allow authenticated users to create their own profile
CREATE POLICY "users_insert_own_profile" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Policy 3: Allow users to update their own profile
CREATE POLICY "users_update_own_profile" ON public.users
    FOR UPDATE USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Policy 4: Allow admins to manage all users (FIXED - NO RECURSION)
-- This policy checks the role directly from the JWT metadata instead
-- of querying the database, which prevents recursion
CREATE POLICY "admin_manage_all_users" ON public.users
    FOR ALL USING (
        (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
    );

-- ============================================================
-- STEP 3: ENABLE RLS ON USERS TABLE
-- ============================================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- STEP 4: UPDATE ADMIN USER METADATA
-- ============================================================

-- For existing admin user, update the auth metadata to include role claim
UPDATE auth.users 
SET raw_user_meta_data = raw_user_meta_data || '{"role": "admin"}'::jsonb
WHERE email = 'admin@mathturo.com';

-- ============================================================
-- SUCCESS MESSAGE
-- ============================================================

RAISE NOTICE 'Users table RLS policies fixed successfully!';
RAISE NOTICE 'Admin user metadata updated to include role claim.';
RAISE NOTICE 'Login should now work without recursion errors.';
```

### Step 2: Verify the Auth User Exists
Ensure you have created the admin user in Supabase Auth:
1. Go to Authentication > Users > Add User
2. Email: `admin@mathturo.com`
3. Password: (strong password of your choice)
4. Click "Add User"

### Step 3: Create the Admin Profile in Public.Users Table
Run this SQL to create the admin profile record:

```sql
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
```

### Step 4: Test the Login
Now try to login with:
- Email: `admin@mathturo.com`
- Password: (the one you set)

### Step 5: Verify the Fix
After logging in, you should see the admin dashboard. The login should succeed without any recursion errors.

## If You Still Experience Issues

### Check Browser Console for Errors
- Open browser developer tools (F12)
- Go to Console tab
- Check for any error messages

### Verify Database Setup
1. Check that auth.user exists for `admin@mathturo.com`
2. Check that public.users has a record for the admin user
3. Verify the role column is set to 'admin'
4. Check raw_user_meta_data in auth.users has role: 'admin'

### Clear Browser Cache
- Clear browser cache and localStorage
- Try incognito mode

## Important Notes

The fix ensures that:
1. The RLS policy no longer queries the users table to check admin status
2. Admin role is verified directly from the JWT token's metadata
3. This prevents the infinite recursion issue
4. The login will work even if there's a problem with the database query

Always keep your admin credentials secure and change them regularly!
