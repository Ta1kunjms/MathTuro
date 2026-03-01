-- ============================================================
-- SIMPLE FIX ADMIN ACCOUNT SQL SCRIPT
-- ============================================================

-- Step 1: Disable RLS temporarily
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;

-- Step 2: Create admin account
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

-- Step 3: Re-enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Step 4: Verify
SELECT * FROM public.users WHERE role = 'admin';
