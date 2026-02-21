-- Check quizzes table RLS policies
SELECT * FROM pg_policies WHERE tablename = 'quizzes' AND schemaname = 'public';

-- Create or update quizzes table policies if needed
DROP POLICY IF EXISTS "teachers_view_own_quizzes" ON public.quizzes;
DROP POLICY IF EXISTS "teachers_insert_quizzes" ON public.quizzes;
DROP POLICY IF EXISTS "teachers_update_quizzes" ON public.quizzes;
DROP POLICY IF EXISTS "teachers_delete_quizzes" ON public.quizzes;

-- Teachers can view their own quizzes
CREATE POLICY "teachers_view_own_quizzes" ON public.quizzes
    FOR SELECT USING (
        teacher_id = auth.uid() OR
        EXISTS (SELECT 1 FROM public.modules WHERE id = module_id AND teacher_id = auth.uid())
    );

-- Teachers can insert quizzes for their own modules or without modules
CREATE POLICY "teachers_insert_quizzes" ON public.quizzes
    FOR INSERT WITH CHECK (
        teacher_id = auth.uid() OR
        EXISTS (SELECT 1 FROM public.modules WHERE id = module_id AND teacher_id = auth.uid())
    );

-- Teachers can update their own quizzes
CREATE POLICY "teachers_update_quizzes" ON public.quizzes
    FOR UPDATE USING (
        teacher_id = auth.uid() OR
        EXISTS (SELECT 1 FROM public.modules WHERE id = module_id AND teacher_id = auth.uid())
    );

-- Teachers can delete their own quizzes
CREATE POLICY "teachers_delete_quizzes" ON public.quizzes
    FOR DELETE USING (
        teacher_id = auth.uid() OR
        EXISTS (SELECT 1 FROM public.modules WHERE id = module_id AND teacher_id = auth.uid())
    );

-- Verify the policies are created
SELECT * FROM pg_policies WHERE tablename = 'quizzes' AND schemaname = 'public';