-- ============================================================
-- MIGRATION V4: SEPARATE VIDEOS & QUIZZES FROM MODULES
-- MathTuro LMS - Standalone Video & Quiz System
-- ============================================================

-- ============================================================
-- SECTION 1: UPDATE VIDEOS TABLE
-- Make videos standalone with categories
-- ============================================================

-- Remove module_id requirement, add new fields
ALTER TABLE public.videos DROP CONSTRAINT IF EXISTS videos_module_id_fkey;
ALTER TABLE public.videos ALTER COLUMN module_id DROP NOT NULL;

-- Add new columns for standalone videos
ALTER TABLE public.videos ADD COLUMN IF NOT EXISTS category VARCHAR(100);
ALTER TABLE public.videos ADD COLUMN IF NOT EXISTS subject VARCHAR(100);
ALTER TABLE public.videos ADD COLUMN IF NOT EXISTS grade_level VARCHAR(50);
ALTER TABLE public.videos ADD COLUMN IF NOT EXISTS is_published BOOLEAN DEFAULT false;
ALTER TABLE public.videos ADD COLUMN IF NOT EXISTS teacher_id UUID REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE public.videos ADD COLUMN IF NOT EXISTS view_count INTEGER DEFAULT 0;

-- Create index for teacher
CREATE INDEX IF NOT EXISTS idx_videos_teacher ON public.videos(teacher_id);
CREATE INDEX IF NOT EXISTS idx_videos_category ON public.videos(category);
CREATE INDEX IF NOT EXISTS idx_videos_published ON public.videos(is_published);

-- ============================================================
-- SECTION 2: UPDATE QUIZZES TABLE
-- Make quizzes standalone, optionally linked to videos
-- ============================================================

-- Remove module_id requirement
ALTER TABLE public.quizzes DROP CONSTRAINT IF EXISTS quizzes_module_id_fkey;
ALTER TABLE public.quizzes ALTER COLUMN module_id DROP NOT NULL;

-- Add new columns for standalone quizzes
ALTER TABLE public.quizzes ADD COLUMN IF NOT EXISTS category VARCHAR(100);
ALTER TABLE public.quizzes ADD COLUMN IF NOT EXISTS subject VARCHAR(100);
ALTER TABLE public.quizzes ADD COLUMN IF NOT EXISTS grade_level VARCHAR(50);
ALTER TABLE public.quizzes ADD COLUMN IF NOT EXISTS is_published BOOLEAN DEFAULT false;
ALTER TABLE public.quizzes ADD COLUMN IF NOT EXISTS teacher_id UUID REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE public.quizzes ADD COLUMN IF NOT EXISTS video_id UUID REFERENCES public.videos(id) ON DELETE SET NULL;
ALTER TABLE public.quizzes ADD COLUMN IF NOT EXISTS time_limit_minutes INTEGER DEFAULT 0;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_quizzes_teacher ON public.quizzes(teacher_id);
CREATE INDEX IF NOT EXISTS idx_quizzes_video ON public.quizzes(video_id);
CREATE INDEX IF NOT EXISTS idx_quizzes_published ON public.quizzes(is_published);

-- ============================================================
-- SECTION 3: VIDEO PROGRESS TRACKING
-- Track student video watching progress
-- ============================================================

CREATE TABLE IF NOT EXISTS public.video_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    video_id UUID NOT NULL REFERENCES public.videos(id) ON DELETE CASCADE,
    watch_time_seconds INTEGER DEFAULT 0,
    completed BOOLEAN DEFAULT false,
    last_watched_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(student_id, video_id)
);

CREATE INDEX IF NOT EXISTS idx_video_progress_student ON public.video_progress(student_id);
CREATE INDEX IF NOT EXISTS idx_video_progress_video ON public.video_progress(video_id);

-- ============================================================
-- SECTION 4: VIDEO FAVORITES/LIKES
-- Students can save favorite videos
-- ============================================================

CREATE TABLE IF NOT EXISTS public.video_favorites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    video_id UUID NOT NULL REFERENCES public.videos(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(student_id, video_id)
);

CREATE INDEX IF NOT EXISTS idx_video_favorites_student ON public.video_favorites(student_id);

-- ============================================================
-- SECTION 5: ENABLE RLS
-- ============================================================

ALTER TABLE public.video_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.video_favorites ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- SECTION 6: UPDATE RLS POLICIES FOR VIDEOS
-- ============================================================

-- Drop old policies
DROP POLICY IF EXISTS "videos_read_published" ON public.videos;
DROP POLICY IF EXISTS "teachers_view_own_videos" ON public.videos;
DROP POLICY IF EXISTS "teachers_insert_videos" ON public.videos;
DROP POLICY IF EXISTS "teachers_update_videos" ON public.videos;
DROP POLICY IF EXISTS "teachers_delete_videos" ON public.videos;
DROP POLICY IF EXISTS "admin_select_videos" ON public.videos;
DROP POLICY IF EXISTS "admin_insert_videos" ON public.videos;
DROP POLICY IF EXISTS "admin_update_videos" ON public.videos;
DROP POLICY IF EXISTS "admin_delete_videos" ON public.videos;

-- New policies for standalone videos
CREATE POLICY "anyone_view_published_videos" ON public.videos
    FOR SELECT USING (is_published = true);

CREATE POLICY "teachers_view_own_videos" ON public.videos
    FOR SELECT USING (teacher_id = auth.uid());

CREATE POLICY "teachers_insert_videos" ON public.videos
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('teacher', 'admin'))
    );

CREATE POLICY "teachers_update_own_videos" ON public.videos
    FOR UPDATE USING (teacher_id = auth.uid());

CREATE POLICY "teachers_delete_own_videos" ON public.videos
    FOR DELETE USING (teacher_id = auth.uid());

CREATE POLICY "admin_all_videos" ON public.videos
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- ============================================================
-- SECTION 7: UPDATE RLS POLICIES FOR QUIZZES
-- ============================================================

-- Drop old policies
DROP POLICY IF EXISTS "quizzes_read_published" ON public.quizzes;
DROP POLICY IF EXISTS "teachers_view_own_quizzes" ON public.quizzes;
DROP POLICY IF EXISTS "teachers_insert_quizzes" ON public.quizzes;
DROP POLICY IF EXISTS "teachers_update_quizzes" ON public.quizzes;
DROP POLICY IF EXISTS "teachers_delete_quizzes" ON public.quizzes;
DROP POLICY IF EXISTS "admin_select_quizzes" ON public.quizzes;
DROP POLICY IF EXISTS "admin_insert_quizzes" ON public.quizzes;
DROP POLICY IF EXISTS "admin_update_quizzes" ON public.quizzes;
DROP POLICY IF EXISTS "admin_delete_quizzes" ON public.quizzes;

-- New policies for standalone quizzes
CREATE POLICY "anyone_view_published_quizzes" ON public.quizzes
    FOR SELECT USING (is_published = true);

CREATE POLICY "teachers_view_own_quizzes" ON public.quizzes
    FOR SELECT USING (teacher_id = auth.uid());

CREATE POLICY "teachers_insert_quizzes" ON public.quizzes
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('teacher', 'admin'))
    );

CREATE POLICY "teachers_update_own_quizzes" ON public.quizzes
    FOR UPDATE USING (teacher_id = auth.uid());

CREATE POLICY "teachers_delete_own_quizzes" ON public.quizzes
    FOR DELETE USING (teacher_id = auth.uid());

CREATE POLICY "admin_all_quizzes" ON public.quizzes
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- ============================================================
-- SECTION 8: RLS POLICIES FOR VIDEO PROGRESS
-- ============================================================

CREATE POLICY "students_manage_own_progress" ON public.video_progress
    FOR ALL USING (student_id = auth.uid());

CREATE POLICY "teachers_view_progress" ON public.video_progress
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('teacher', 'admin'))
    );

-- ============================================================
-- SECTION 9: RLS POLICIES FOR VIDEO FAVORITES
-- ============================================================

CREATE POLICY "students_manage_own_favorites" ON public.video_favorites
    FOR ALL USING (student_id = auth.uid());

-- ============================================================
-- DONE!
-- ============================================================
