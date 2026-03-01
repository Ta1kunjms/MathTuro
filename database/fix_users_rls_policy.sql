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
-- This policy has a special check that avoids querying the users table
-- by using a different mechanism to verify admin status
CREATE POLICY "admin_manage_all_users" ON public.users
    FOR ALL USING (
        -- Check if user has admin claim in auth metadata (more efficient)
        (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
    );

-- ============================================================
-- STEP 3: ENABLE RLS ON USERS TABLE (IF NOT ALREADY ENABLED)
-- ============================================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- STEP 4: UPDATE USER METADATA TO INCLUDE ROLE CLAIM
-- ============================================================

-- For existing admin user, update the auth metadata to include role
UPDATE auth.users 
SET raw_user_meta_data = raw_user_meta_data || '{"role": "admin"}'::jsonb
WHERE email = 'admin@mathturo.com';

-- ============================================================
-- SUCCESS MESSAGE
-- ============================================================

RAISE NOTICE 'Users table RLS policies fixed successfully!';
RAISE NOTICE 'Admin user metadata updated to include role claim.';
RAISE NOTICE 'Login should now work without recursion errors.';
