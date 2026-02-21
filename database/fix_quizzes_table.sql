-- Fix Quizzes Table - Add missing columns and indexes
-- This script is safe to run multiple times

-- Add missing description column
ALTER TABLE public.quizzes ADD COLUMN IF NOT EXISTS description TEXT;

-- Add any other missing columns from the current schema
ALTER TABLE public.quizzes ADD COLUMN IF NOT EXISTS category VARCHAR(100);
ALTER TABLE public.quizzes ADD COLUMN IF NOT EXISTS subject VARCHAR(100);
ALTER TABLE public.quizzes ADD COLUMN IF NOT EXISTS grade_level VARCHAR(50);
ALTER TABLE public.quizzes ADD COLUMN IF NOT EXISTS is_published BOOLEAN DEFAULT false;
ALTER TABLE public.quizzes ADD COLUMN IF NOT EXISTS teacher_id UUID REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE public.quizzes ADD COLUMN IF NOT EXISTS video_id UUID REFERENCES public.videos(id) ON DELETE SET NULL;
ALTER TABLE public.quizzes ADD COLUMN IF NOT EXISTS time_limit_minutes INTEGER DEFAULT 0;
ALTER TABLE public.quizzes ADD COLUMN IF NOT EXISTS is_required BOOLEAN DEFAULT true;
ALTER TABLE public.quizzes ADD COLUMN IF NOT EXISTS deadline TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.quizzes ADD COLUMN IF NOT EXISTS order_index INTEGER DEFAULT 0;
ALTER TABLE public.quizzes ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES public.users(id) ON DELETE SET NULL;

-- Ensure module_id is nullable (from migration_v4)
ALTER TABLE public.quizzes ALTER COLUMN module_id DROP NOT NULL;

-- Create missing indexes
CREATE INDEX IF NOT EXISTS idx_quizzes_teacher ON public.quizzes(teacher_id);
CREATE INDEX IF NOT EXISTS idx_quizzes_video ON public.quizzes(video_id);
CREATE INDEX IF NOT EXISTS idx_quizzes_category ON public.quizzes(category);
CREATE INDEX IF NOT EXISTS idx_quizzes_grade_level ON public.quizzes(grade_level);
CREATE INDEX IF NOT EXISTS idx_quizzes_published ON public.quizzes(is_published);

-- Ensure RLS is enabled
ALTER TABLE public.quizzes ENABLE ROW LEVEL SECURITY;

-- Update quiz_submissions table (if needed)
ALTER TABLE public.quiz_submissions ADD COLUMN IF NOT EXISTS quiz_id UUID REFERENCES public.quizzes(id) ON DELETE CASCADE;
ALTER TABLE public.quiz_submissions ADD COLUMN IF NOT EXISTS total_items INTEGER DEFAULT 0;
ALTER TABLE public.quiz_submissions ADD COLUMN IF NOT EXISTS student_score INTEGER DEFAULT 0;
ALTER TABLE public.quiz_submissions ADD COLUMN IF NOT EXISTS teacher_comment TEXT;
ALTER TABLE public.quiz_submissions ALTER COLUMN lesson_id DROP NOT NULL;
ALTER TABLE public.quiz_submissions ALTER COLUMN module_id DROP NOT NULL;
CREATE INDEX IF NOT EXISTS idx_submissions_quiz ON public.quiz_submissions(quiz_id);

-- Create trigger to update updated_at timestamp (if missing)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Check if trigger exists before creating it
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger
        WHERE tgname = 'update_quizzes_updated_at'
        AND NOT tgisinternal
    ) THEN
        CREATE TRIGGER update_quizzes_updated_at
            BEFORE UPDATE ON public.quizzes
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

-- Verify the changes
SELECT 'Quizzes table updated successfully' as status;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'quizzes' 
AND table_schema = 'public'
ORDER BY column_name;
