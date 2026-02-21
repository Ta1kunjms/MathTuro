-- Fix quiz_submissions table - ensure all required columns exist and are correct
ALTER TABLE public.quiz_submissions 
ADD COLUMN IF NOT EXISTS quiz_id UUID REFERENCES public.quizzes(id) ON DELETE CASCADE;

ALTER TABLE public.quiz_submissions 
ADD COLUMN IF NOT EXISTS student_score INTEGER DEFAULT 0;

ALTER TABLE public.quiz_submissions 
ADD COLUMN IF NOT EXISTS total_items INTEGER DEFAULT 0;

ALTER TABLE public.quiz_submissions 
ADD COLUMN IF NOT EXISTS teacher_comment TEXT;

-- Make lesson_id and module_id nullable (quizzes can exist independently)
ALTER TABLE public.quiz_submissions 
ALTER COLUMN lesson_id DROP NOT NULL;

ALTER TABLE public.quiz_submissions 
ALTER COLUMN module_id DROP NOT NULL;

-- Fix RLS policies for quiz_submissions
DROP POLICY IF EXISTS "submissions_read_own" ON public.quiz_submissions;
DROP POLICY IF EXISTS "submissions_create_own" ON public.quiz_submissions;
DROP POLICY IF EXISTS "teachers_view_submissions" ON public.quiz_submissions;
DROP POLICY IF EXISTS "teachers_update_submissions" ON public.quiz_submissions;
DROP POLICY IF EXISTS "admin_manage_submissions" ON public.quiz_submissions;

-- Create correct RLS policies for quiz_submissions
CREATE POLICY "submissions_read_own" ON public.quiz_submissions
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "submissions_create_own" ON public.quiz_submissions
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "teachers_view_submissions" ON public.quiz_submissions
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.modules WHERE id = module_id AND teacher_id = auth.uid()) OR
        EXISTS (SELECT 1 FROM public.quizzes WHERE id = quiz_id AND teacher_id = auth.uid())
    );

CREATE POLICY "teachers_update_submissions" ON public.quiz_submissions
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM public.modules WHERE id = module_id AND teacher_id = auth.uid()) OR
        EXISTS (SELECT 1 FROM public.quizzes WHERE id = quiz_id AND teacher_id = auth.uid())
    );

CREATE POLICY "admin_manage_submissions" ON public.quiz_submissions
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- Create or update index for better query performance
CREATE INDEX IF NOT EXISTS idx_submissions_quiz ON public.quiz_submissions(quiz_id);

-- Update any existing submissions that might have the old 'score' column instead of 'student_score'
-- Note: This will only work if you actually have a 'score' column
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'quiz_submissions' AND column_name = 'score' AND table_schema = 'public'
    ) THEN
        -- Copy data from old 'score' column to new 'student_score' column
        UPDATE public.quiz_submissions 
        SET student_score = score 
        WHERE student_score IS NULL;
        
        -- Optional: Drop the old 'score' column (uncomment if you want to remove it permanently)
        -- ALTER TABLE public.quiz_submissions DROP COLUMN IF EXISTS score;
    END IF;
END $$;

-- Verify the changes
SELECT 'quiz_submissions table updated successfully' as status;

-- Show the updated table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'quiz_submissions' 
AND table_schema = 'public'
ORDER BY column_name;