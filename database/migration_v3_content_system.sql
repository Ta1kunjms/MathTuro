-- ============================================================
-- MIGRATION V3: COMPREHENSIVE CONTENT SYSTEM
-- MathTuro LMS - Module, Video, Quiz System
-- ============================================================
-- Run this script in Supabase SQL Editor
-- ============================================================

-- ============================================================
-- SECTION 1: UPDATE MODULES TABLE
-- Add content_type for PDF or images
-- ============================================================

ALTER TABLE public.modules ADD COLUMN IF NOT EXISTS content_type VARCHAR(20) DEFAULT 'pdf' CHECK (content_type IN ('pdf', 'images'));
ALTER TABLE public.modules ADD COLUMN IF NOT EXISTS pdf_url TEXT;
ALTER TABLE public.modules ADD COLUMN IF NOT EXISTS image_urls TEXT[]; -- Array of image URLs

-- ============================================================
-- SECTION 2: CREATE VIDEOS TABLE
-- Teachers can add videos with title, description, and URL
-- ============================================================

CREATE TABLE IF NOT EXISTS public.videos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    module_id UUID NOT NULL REFERENCES public.modules(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    video_url TEXT NOT NULL, -- YouTube, Vimeo, or other video URLs
    thumbnail_url TEXT, -- Auto-generated or custom thumbnail
    order_index INTEGER DEFAULT 0,
    duration_minutes INTEGER DEFAULT 0,
    created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_videos_module ON public.videos(module_id);
CREATE INDEX IF NOT EXISTS idx_videos_order ON public.videos(order_index);

-- ============================================================
-- SECTION 3: CREATE QUIZZES TABLE
-- External quiz links that students take and submit scores for
-- ============================================================

CREATE TABLE IF NOT EXISTS public.quizzes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    module_id UUID NOT NULL REFERENCES public.modules(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    quiz_url TEXT NOT NULL, -- External quiz URL (Google Forms, Quizizz, etc.)
    total_items INTEGER NOT NULL DEFAULT 10, -- Total possible score
    passing_score INTEGER DEFAULT 0, -- Minimum passing score (optional)
    order_index INTEGER DEFAULT 0,
    is_required BOOLEAN DEFAULT true,
    deadline TIMESTAMP WITH TIME ZONE, -- Optional deadline
    created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_quizzes_module ON public.quizzes(module_id);

-- ============================================================
-- SECTION 4: UPDATE QUIZ_SUBMISSIONS TABLE
-- Now linked to quizzes table, includes score details
-- ============================================================

ALTER TABLE public.quiz_submissions ADD COLUMN IF NOT EXISTS quiz_id UUID REFERENCES public.quizzes(id) ON DELETE CASCADE;
ALTER TABLE public.quiz_submissions ADD COLUMN IF NOT EXISTS total_items INTEGER DEFAULT 0;
ALTER TABLE public.quiz_submissions ADD COLUMN IF NOT EXISTS student_score INTEGER DEFAULT 0;
ALTER TABLE public.quiz_submissions ADD COLUMN IF NOT EXISTS teacher_comment TEXT;

-- Drop old score column constraint if exists and update
-- ALTER TABLE public.quiz_submissions DROP CONSTRAINT IF EXISTS quiz_submissions_score_check;
-- ALTER TABLE public.quiz_submissions ALTER COLUMN score TYPE INTEGER;

-- ============================================================
-- SECTION 5: ENABLE ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE public.videos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quizzes ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- SECTION 6: RLS POLICIES FOR VIDEOS
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

-- Teachers can insert videos for their own modules
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
-- SECTION 7: RLS POLICIES FOR QUIZZES
-- ============================================================

-- Anyone can view quizzes from published modules
CREATE POLICY "quizzes_read_published" ON public.quizzes
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.modules WHERE id = module_id AND status = 'published')
    );

-- Teachers can view their own quizzes (even draft modules)
CREATE POLICY "teachers_view_own_quizzes" ON public.quizzes
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.modules WHERE id = module_id AND teacher_id = auth.uid())
    );

-- Teachers can insert quizzes for their own modules
CREATE POLICY "teachers_insert_quizzes" ON public.quizzes
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM public.modules WHERE id = module_id AND teacher_id = auth.uid())
    );

-- Teachers can update their own quizzes
CREATE POLICY "teachers_update_quizzes" ON public.quizzes
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM public.modules WHERE id = module_id AND teacher_id = auth.uid())
    );

-- Teachers can delete their own quizzes
CREATE POLICY "teachers_delete_quizzes" ON public.quizzes
    FOR DELETE USING (
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
-- SECTION 8: STORAGE BUCKETS FOR FILES
-- ============================================================

-- Buckets already created in Supabase dashboard:
-- - learning-materials (for PDFs, images, videos)
-- - quiz-screenshots (for quiz screenshots)
-- - avatars (for profile images)

-- Storage policies for learning-materials (PDFs, images, videos)
CREATE POLICY "Anyone can view learning materials"
ON storage.objects FOR SELECT
USING (bucket_id = 'learning-materials');

CREATE POLICY "Teachers can upload learning materials"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'learning-materials' AND
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('teacher', 'admin'))
);

CREATE POLICY "Teachers can delete learning materials"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'learning-materials' AND
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('teacher', 'admin'))
);

-- Storage policies for quiz screenshots
CREATE POLICY "Students can view own screenshots"
ON storage.objects FOR SELECT
USING (
    bucket_id = 'quiz-screenshots' AND
    (auth.uid()::text = (storage.foldername(name))[1] OR
     EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('teacher', 'admin')))
);

CREATE POLICY "Students can upload screenshots"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'quiz-screenshots' AND
    auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Teachers can view all screenshots"
ON storage.objects FOR SELECT
USING (
    bucket_id = 'quiz-screenshots' AND
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('teacher', 'admin'))
);

-- ============================================================
-- SECTION 9: HELPER FUNCTIONS
-- ============================================================

-- Drop existing function if exists (to handle parameter name changes)
DROP FUNCTION IF EXISTS get_video_thumbnail(text);

-- Function to get video thumbnail from URL (YouTube, Vimeo)
CREATE OR REPLACE FUNCTION get_video_thumbnail(video_url TEXT)
RETURNS TEXT AS $$
DECLARE
    video_id TEXT;
BEGIN
    -- YouTube
    IF video_url LIKE '%youtube.com%' OR video_url LIKE '%youtu.be%' THEN
        -- Extract video ID
        IF video_url LIKE '%youtu.be%' THEN
            video_id := substring(video_url from 'youtu\.be/([a-zA-Z0-9_-]+)');
        ELSE
            video_id := substring(video_url from 'v=([a-zA-Z0-9_-]+)');
        END IF;
        
        IF video_id IS NOT NULL THEN
            RETURN 'https://img.youtube.com/vi/' || video_id || '/maxresdefault.jpg';
        END IF;
    END IF;
    
    -- Default thumbnail
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-generate thumbnail for videos
CREATE OR REPLACE FUNCTION set_video_thumbnail()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.thumbnail_url IS NULL THEN
        NEW.thumbnail_url := get_video_thumbnail(NEW.video_url);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS video_thumbnail_trigger ON public.videos;
CREATE TRIGGER video_thumbnail_trigger
    BEFORE INSERT OR UPDATE ON public.videos
    FOR EACH ROW
    EXECUTE FUNCTION set_video_thumbnail();

-- ============================================================
-- SECTION 10: UPDATE TIMESTAMP TRIGGERS
-- ============================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_videos_updated_at ON public.videos;
CREATE TRIGGER update_videos_updated_at
    BEFORE UPDATE ON public.videos
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_quizzes_updated_at ON public.quizzes;
CREATE TRIGGER update_quizzes_updated_at
    BEFORE UPDATE ON public.quizzes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- VERIFICATION: Check all tables exist
-- ============================================================
SELECT 'Migration V3 Complete!' as status;
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;
