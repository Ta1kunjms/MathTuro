-- Migration V5: Lesson Plan Files Table
-- Copy and paste this entire script into your Supabase SQL Editor and click Run.

-- ============================================================
-- STEP 1: Create the table if it does not exist yet
-- ============================================================
CREATE TABLE IF NOT EXISTS public.lesson_plan_files (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    file_name TEXT NOT NULL,
    file_path TEXT NOT NULL,
    file_url TEXT NOT NULL,
    file_type TEXT,
    file_size BIGINT,
    description TEXT DEFAULT '',
    tags TEXT[] DEFAULT '{}',
    module_name TEXT,
    lesson_name TEXT,
    period_type TEXT,
    period_value TEXT,
    uploaded_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- STEP 2: Add missing columns if the table already exists
--         (safe to run even if columns already exist)
-- ============================================================
ALTER TABLE public.lesson_plan_files
    ADD COLUMN IF NOT EXISTS module_name TEXT,
    ADD COLUMN IF NOT EXISTS lesson_name TEXT,
    ADD COLUMN IF NOT EXISTS period_type TEXT,
    ADD COLUMN IF NOT EXISTS period_value TEXT,
    ADD COLUMN IF NOT EXISTS description TEXT DEFAULT '',
    ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';

-- ============================================================
-- STEP 3: Drop old foreign-key columns if they exist
--         (only runs if the old columns are present)
-- ============================================================
ALTER TABLE public.lesson_plan_files
    DROP COLUMN IF EXISTS module_id,
    DROP COLUMN IF EXISTS lesson_id;

-- ============================================================
-- STEP 4: Indexes
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_lesson_plan_files_user     ON public.lesson_plan_files(user_id);
CREATE INDEX IF NOT EXISTS idx_lesson_plan_files_module   ON public.lesson_plan_files(module_name);
CREATE INDEX IF NOT EXISTS idx_lesson_plan_files_uploaded ON public.lesson_plan_files(uploaded_at DESC);

-- ============================================================
-- STEP 5: Enable Row Level Security
-- ============================================================
ALTER TABLE public.lesson_plan_files ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- STEP 6: RLS Policies (drop first to avoid duplicate errors)
-- ============================================================
DROP POLICY IF EXISTS "Teachers can view their own lesson plan files"   ON public.lesson_plan_files;
DROP POLICY IF EXISTS "Teachers can insert their own lesson plan files" ON public.lesson_plan_files;
DROP POLICY IF EXISTS "Teachers can update their own lesson plan files" ON public.lesson_plan_files;
DROP POLICY IF EXISTS "Teachers can delete their own lesson plan files" ON public.lesson_plan_files;

CREATE POLICY "Teachers can view their own lesson plan files"
    ON public.lesson_plan_files FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Teachers can insert their own lesson plan files"
    ON public.lesson_plan_files FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Teachers can update their own lesson plan files"
    ON public.lesson_plan_files FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Teachers can delete their own lesson plan files"
    ON public.lesson_plan_files FOR DELETE
    USING (auth.uid() = user_id);
