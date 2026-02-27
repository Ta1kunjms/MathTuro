-- ============================================================
-- FIX QUIZ SUBMISSIONS UPDATE POLICY AND TRIGGER
-- Run this in Supabase SQL Editor to fix the issue where updated
-- rejected submissions don't move back to pending status
-- ============================================================

-- Step 1: Create RLS policy for students to update their own submissions
-- This policy allows students to update their own quiz submissions
DROP POLICY IF EXISTS "submissions_update_own" ON public.quiz_submissions;

CREATE POLICY "submissions_update_own" ON public.quiz_submissions
    FOR UPDATE USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- Step 2: Create a trigger function to automatically set status to pending
-- when a rejected submission is updated
CREATE OR REPLACE FUNCTION public.handle_submission_update()
RETURNS TRIGGER AS $$
BEGIN
    -- If the submission was rejected and is being updated by the student
    -- (or anyone), set status back to pending
    IF OLD.status = 'rejected' THEN
        NEW.status = 'pending';
        NEW.teacher_comment = NULL;
        NEW.teacher_feedback = NULL;
        NEW.reviewed_at = NULL;
        NEW.reviewed_by = NULL;
    END IF;
    
    -- Always update the updated_at timestamp
    NEW.updated_at = NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 3: Create the trigger
DROP TRIGGER IF EXISTS on_submission_update ON public.quiz_submissions;

CREATE TRIGGER on_submission_update
    BEFORE UPDATE ON public.quiz_submissions
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_submission_update();

-- Verify the changes
SELECT 'Quiz submissions update policy and trigger created successfully' as status;
