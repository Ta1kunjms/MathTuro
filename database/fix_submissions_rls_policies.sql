-- ============================================================
-- FIX RLS POLICIES FOR QUIZ SUBMISSIONS
-- Run this in Supabase SQL Editor to fix submissions button
-- ============================================================

-- Drop existing policies to ensure we create fresh ones
DROP POLICY IF EXISTS "teachers_view_submissions" ON public.quiz_submissions;
DROP POLICY IF EXISTS "teachers_update_submissions" ON public.quiz_submissions;

-- Create updated policies that handle both module_id and quiz_id
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

-- Also ensure quizzes table policies handle teacher_id directly
DROP POLICY IF EXISTS "teachers_view_own_quizzes" ON public.quizzes;
DROP POLICY IF EXISTS "teachers_insert_quizzes" ON public.quizzes;
DROP POLICY IF EXISTS "teachers_update_quizzes" ON public.quizzes;
DROP POLICY IF EXISTS "teachers_delete_quizzes" ON public.quizzes;

-- Create updated quiz policies that check teacher_id directly
CREATE POLICY "teachers_view_own_quizzes" ON public.quizzes
    FOR SELECT USING (
        teacher_id = auth.uid() OR
        EXISTS (SELECT 1 FROM public.modules WHERE id = module_id AND teacher_id = auth.uid())
    );

CREATE POLICY "teachers_insert_quizzes" ON public.quizzes
    FOR INSERT WITH CHECK (
        teacher_id = auth.uid() OR
        EXISTS (SELECT 1 FROM public.modules WHERE id = module_id AND teacher_id = auth.uid())
    );

CREATE POLICY "teachers_update_quizzes" ON public.quizzes
    FOR UPDATE USING (
        teacher_id = auth.uid() OR
        EXISTS (SELECT 1 FROM public.modules WHERE id = module_id AND teacher_id = auth.uid())
    );

CREATE POLICY "teachers_delete_quizzes" ON public.quizzes
    FOR DELETE USING (
        teacher_id = auth.uid() OR
        EXISTS (SELECT 1 FROM public.modules WHERE id = module_id AND teacher_id = auth.uid())
    );

-- Verify the changes
SELECT 'Quiz submission policies updated successfully' as status;