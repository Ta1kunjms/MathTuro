-- ============================================================
-- FIX RLS POLICIES FOR VIDEOS AND QUIZZES
-- Run this in Supabase SQL Editor to fix INSERT issues
-- ============================================================

-- ============================================================
-- STEP 1: DROP EXISTING POLICIES
-- ============================================================

DROP POLICY IF EXISTS "videos_read_published" ON public.videos;
DROP POLICY IF EXISTS "teachers_manage_videos" ON public.videos;
DROP POLICY IF EXISTS "admin_manage_all_videos" ON public.videos;
DROP POLICY IF EXISTS "teachers_view_own_videos" ON public.videos;
DROP POLICY IF EXISTS "teachers_insert_videos" ON public.videos;
DROP POLICY IF EXISTS "teachers_update_videos" ON public.videos;
DROP POLICY IF EXISTS "teachers_delete_videos" ON public.videos;
DROP POLICY IF EXISTS "admin_select_videos" ON public.videos;
DROP POLICY IF EXISTS "admin_insert_videos" ON public.videos;
DROP POLICY IF EXISTS "admin_update_videos" ON public.videos;
DROP POLICY IF EXISTS "admin_delete_videos" ON public.videos;

DROP POLICY IF EXISTS "quizzes_read_published" ON public.quizzes;
DROP POLICY IF EXISTS "teachers_manage_quizzes" ON public.quizzes;
DROP POLICY IF EXISTS "admin_manage_all_quizzes" ON public.quizzes;
DROP POLICY IF EXISTS "teachers_view_own_quizzes" ON public.quizzes;
DROP POLICY IF EXISTS "teachers_insert_quizzes" ON public.quizzes;
DROP POLICY IF EXISTS "teachers_update_quizzes" ON public.quizzes;
DROP POLICY IF EXISTS "teachers_delete_quizzes" ON public.quizzes;
DROP POLICY IF EXISTS "admin_select_quizzes" ON public.quizzes;
DROP POLICY IF EXISTS "admin_insert_quizzes" ON public.quizzes;
DROP POLICY IF EXISTS "admin_update_quizzes" ON public.quizzes;
DROP POLICY IF EXISTS "admin_delete_quizzes" ON public.quizzes;

-- ============================================================
-- STEP 2: CREATE CORRECT RLS POLICIES FOR VIDEOS
-- ============================================================

-- Anyone can view videos from published modules
CREATE POLICY "videos_read_published" ON public.videos
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.modules WHERE id = module_id AND status = 'published')
    );

-- Teachers can view their own videos (even draft modules)
CREATE POLICY "teachers_view_own_videos" ON public.videos
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.modules WHERE id = module_id AND teacher_id = auth.uid())
    );

-- Teachers can INSERT videos for their own modules (WITH CHECK is required for INSERT)
CREATE POLICY "teachers_insert_videos" ON public.videos
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM public.modules WHERE id = module_id AND teacher_id = auth.uid())
    );

-- Teachers can update their own videos
CREATE POLICY "teachers_update_videos" ON public.videos
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM public.modules WHERE id = module_id AND teacher_id = auth.uid())
    );

-- Teachers can delete their own videos
CREATE POLICY "teachers_delete_videos" ON public.videos
    FOR DELETE USING (
        EXISTS (SELECT 1 FROM public.modules WHERE id = module_id AND teacher_id = auth.uid())
    );

-- Admins can do everything with videos
CREATE POLICY "admin_select_videos" ON public.videos
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "admin_insert_videos" ON public.videos
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "admin_update_videos" ON public.videos
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "admin_delete_videos" ON public.videos
    FOR DELETE USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- ============================================================
-- STEP 3: CREATE CORRECT RLS POLICIES FOR QUIZZES
-- ============================================================

-- Anyone can view quizzes from published modules
CREATE POLICY "quizzes_read_published" ON public.quizzes
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.modules WHERE id = module_id AND status = 'published')
    );

-- Teachers can view their own quizzes (even draft modules or no module)
CREATE POLICY "teachers_view_own_quizzes" ON public.quizzes
    FOR SELECT USING (
        teacher_id = auth.uid() OR
        EXISTS (SELECT 1 FROM public.modules WHERE id = module_id AND teacher_id = auth.uid())
    );

-- Teachers can INSERT quizzes for their own modules or without modules
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

-- Admins can do everything with quizzes
CREATE POLICY "admin_select_quizzes" ON public.quizzes
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "admin_insert_quizzes" ON public.quizzes
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "admin_update_quizzes" ON public.quizzes
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "admin_delete_quizzes" ON public.quizzes
    FOR DELETE USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- ============================================================
-- STEP 4: CREATE CORRECT RLS POLICIES FOR QUIZ SUBMISSIONS
-- ============================================================

DROP POLICY IF EXISTS "submissions_read_own" ON public.quiz_submissions;
DROP POLICY IF EXISTS "submissions_create_own" ON public.quiz_submissions;
DROP POLICY IF EXISTS "teachers_view_submissions" ON public.quiz_submissions;
DROP POLICY IF EXISTS "teachers_update_submissions" ON public.quiz_submissions;
DROP POLICY IF EXISTS "admin_manage_submissions" ON public.quiz_submissions;

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

-- ============================================================
-- DONE! Video, Quiz, and Submission management should now work for teachers
-- ============================================================
