-- ============================================================
-- SUPABASE COMPLETE DATABASE SETUP
-- Learning Management System
-- ============================================================
-- Run this entire script in the Supabase SQL Editor
-- This will create all tables, policies, triggers, and storage buckets
-- ============================================================

-- ============================================================
-- SECTION 1: EXTENSIONS
-- ============================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- SECTION 2: TABLES
-- ============================================================

-- Table: users
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'student' CHECK (role IN ('student', 'teacher', 'admin')),
    avatar_url TEXT,
    is_active BOOLEAN DEFAULT true,
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);

-- Table: modules
CREATE TABLE IF NOT EXISTS public.modules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    cover_image_url TEXT,
    teacher_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
    order_index INTEGER DEFAULT 0,
    total_lessons INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_modules_teacher ON public.modules(teacher_id);
CREATE INDEX IF NOT EXISTS idx_modules_status ON public.modules(status);

-- Table: lessons
CREATE TABLE IF NOT EXISTS public.lessons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    module_id UUID NOT NULL REFERENCES public.modules(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    content TEXT,
    video_url TEXT,
    materials_url TEXT,
    order_index INTEGER DEFAULT 0,
    duration_minutes INTEGER DEFAULT 0,
    has_quiz BOOLEAN DEFAULT false,
    quiz_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_lessons_module ON public.lessons(module_id);

-- Table: lesson_progress
CREATE TABLE IF NOT EXISTS public.lesson_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    lesson_id UUID NOT NULL REFERENCES public.lessons(id) ON DELETE CASCADE,
    module_id UUID NOT NULL REFERENCES public.modules(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'not_started' CHECK (status IN ('not_started', 'in_progress', 'completed')),
    progress_percent INTEGER DEFAULT 0 CHECK (progress_percent >= 0 AND progress_percent <= 100),
    time_spent_minutes INTEGER DEFAULT 0,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, lesson_id)
);

CREATE INDEX IF NOT EXISTS idx_progress_user ON public.lesson_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_progress_lesson ON public.lesson_progress(lesson_id);
CREATE INDEX IF NOT EXISTS idx_progress_module ON public.lesson_progress(module_id);

-- Table: quiz_submissions
CREATE TABLE IF NOT EXISTS public.quiz_submissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    lesson_id UUID NOT NULL REFERENCES public.lessons(id) ON DELETE CASCADE,
    module_id UUID NOT NULL REFERENCES public.modules(id) ON DELETE CASCADE,
    screenshot_url TEXT,
    score INTEGER CHECK (score >= 0 AND score <= 100),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'approved', 'rejected')),
    teacher_feedback TEXT,
    reviewed_by UUID REFERENCES public.users(id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_submissions_user ON public.quiz_submissions(user_id);
CREATE INDEX IF NOT EXISTS idx_submissions_lesson ON public.quiz_submissions(lesson_id);
CREATE INDEX IF NOT EXISTS idx_submissions_status ON public.quiz_submissions(status);

-- Table: notifications
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) DEFAULT 'info' CHECK (type IN ('info', 'success', 'warning', 'error', 'quiz_reviewed', 'new_module', 'announcement')),
    is_read BOOLEAN DEFAULT false,
    link TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON public.notifications(is_read);

-- Table: activity_log
CREATE TABLE IF NOT EXISTS public.activity_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50),
    entity_id UUID,
    details JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_activity_user ON public.activity_log(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_action ON public.activity_log(action);
CREATE INDEX IF NOT EXISTS idx_activity_created ON public.activity_log(created_at DESC);

-- ============================================================
-- SECTION 3: ENABLE ROW LEVEL SECURITY
-- ============================================================
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lesson_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_log ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- SECTION 4: RLS POLICIES
-- ============================================================

-- Users Table Policies
CREATE POLICY "users_read_own" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "users_update_own" ON public.users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "admin_read_all_users" ON public.users
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "admin_update_all_users" ON public.users
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "admin_delete_users" ON public.users
    FOR DELETE USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- Allow users to insert their own record (matches their auth.uid)
CREATE POLICY "users_insert_own" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "teachers_read_students" ON public.users
    FOR SELECT USING (
        role = 'student' AND EXISTS (
            SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('teacher', 'admin')
        )
    );

-- Modules Table Policies
CREATE POLICY "modules_read_published" ON public.modules
    FOR SELECT USING (status = 'published');

CREATE POLICY "teachers_read_own_modules" ON public.modules
    FOR SELECT USING (teacher_id = auth.uid());

CREATE POLICY "teachers_create_modules" ON public.modules
    FOR INSERT WITH CHECK (
        teacher_id = auth.uid() AND
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('teacher', 'admin'))
    );

CREATE POLICY "teachers_update_own_modules" ON public.modules
    FOR UPDATE USING (teacher_id = auth.uid());

CREATE POLICY "teachers_delete_own_modules" ON public.modules
    FOR DELETE USING (teacher_id = auth.uid());

CREATE POLICY "admin_manage_modules" ON public.modules
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- Lessons Table Policies
CREATE POLICY "lessons_read_published" ON public.lessons
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.modules WHERE id = module_id AND status = 'published')
    );

CREATE POLICY "teachers_read_own_lessons" ON public.lessons
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.modules WHERE id = module_id AND teacher_id = auth.uid())
    );

CREATE POLICY "teachers_create_lessons" ON public.lessons
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM public.modules WHERE id = module_id AND teacher_id = auth.uid())
    );

CREATE POLICY "teachers_update_own_lessons" ON public.lessons
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM public.modules WHERE id = module_id AND teacher_id = auth.uid())
    );

CREATE POLICY "teachers_delete_own_lessons" ON public.lessons
    FOR DELETE USING (
        EXISTS (SELECT 1 FROM public.modules WHERE id = module_id AND teacher_id = auth.uid())
    );

CREATE POLICY "admin_manage_lessons" ON public.lessons
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- Lesson Progress Table Policies
CREATE POLICY "progress_read_own" ON public.lesson_progress
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "progress_create_own" ON public.lesson_progress
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "progress_update_own" ON public.lesson_progress
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "teachers_view_progress" ON public.lesson_progress
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.modules WHERE id = module_id AND teacher_id = auth.uid())
    );

CREATE POLICY "admin_view_all_progress" ON public.lesson_progress
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- Quiz Submissions Table Policies
CREATE POLICY "submissions_read_own" ON public.quiz_submissions
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "submissions_create_own" ON public.quiz_submissions
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "teachers_view_submissions" ON public.quiz_submissions
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.modules WHERE id = module_id AND teacher_id = auth.uid())
    );

CREATE POLICY "teachers_update_submissions" ON public.quiz_submissions
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM public.modules WHERE id = module_id AND teacher_id = auth.uid())
    );

CREATE POLICY "admin_manage_submissions" ON public.quiz_submissions
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- Notifications Table Policies
CREATE POLICY "notifications_read_own" ON public.notifications
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "notifications_update_own" ON public.notifications
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "notifications_delete_own" ON public.notifications
    FOR DELETE USING (user_id = auth.uid());

CREATE POLICY "system_create_notifications" ON public.notifications
    FOR INSERT WITH CHECK (
        user_id = auth.uid() OR
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('teacher', 'admin'))
    );

-- Activity Log Table Policies
CREATE POLICY "activity_read_own" ON public.activity_log
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "activity_insert" ON public.activity_log
    FOR INSERT WITH CHECK (true);

CREATE POLICY "admin_view_all_activity" ON public.activity_log
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- ============================================================
-- SECTION 5: TRIGGERS & FUNCTIONS
-- ============================================================

-- Function: Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_modules_updated_at
    BEFORE UPDATE ON public.modules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_lessons_updated_at
    BEFORE UPDATE ON public.lessons
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_progress_updated_at
    BEFORE UPDATE ON public.lesson_progress
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_submissions_updated_at
    BEFORE UPDATE ON public.quiz_submissions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function: Update module lesson count
CREATE OR REPLACE FUNCTION update_module_lesson_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.modules 
        SET total_lessons = (SELECT COUNT(*) FROM public.lessons WHERE module_id = NEW.module_id)
        WHERE id = NEW.module_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.modules 
        SET total_lessons = (SELECT COUNT(*) FROM public.lessons WHERE module_id = OLD.module_id)
        WHERE id = OLD.module_id;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_lesson_count
    AFTER INSERT OR DELETE ON public.lessons
    FOR EACH ROW EXECUTE FUNCTION update_module_lesson_count();

-- Function: Create notification on quiz review
CREATE OR REPLACE FUNCTION notify_quiz_reviewed()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status IN ('approved', 'rejected') AND OLD.status = 'pending' THEN
        INSERT INTO public.notifications (user_id, title, message, type, link)
        VALUES (
            NEW.user_id,
            'Quiz Reviewed',
            CASE 
                WHEN NEW.status = 'approved' THEN 'Your quiz submission has been approved! Score: ' || COALESCE(NEW.score::text, 'N/A')
                ELSE 'Your quiz submission has been reviewed. Please check the feedback.'
            END,
            'quiz_reviewed',
            '/lesson-view.html?lessonId=' || NEW.lesson_id
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_quiz_reviewed
    AFTER UPDATE ON public.quiz_submissions
    FOR EACH ROW EXECUTE FUNCTION notify_quiz_reviewed();

-- Function: Handle new user registration
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email, full_name, role, created_at, updated_at)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
        COALESCE(NEW.raw_user_meta_data->>'role', 'student'),
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- SECTION 6: STORAGE BUCKETS
-- ============================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'quiz-screenshots',
    'quiz-screenshots',
    true,
    5242880,
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
) ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'learning-materials',
    'learning-materials',
    true,
    52428800,
    ARRAY['application/pdf', 'image/jpeg', 'image/png', 'video/mp4', 'video/webm']
) ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'avatars',
    'avatars',
    true,
    2097152,
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
) ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- SECTION 7: STORAGE POLICIES
-- ============================================================

CREATE POLICY "quiz_screenshots_upload" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'quiz-screenshots' AND auth.uid() IS NOT NULL);

CREATE POLICY "quiz_screenshots_read" ON storage.objects
    FOR SELECT USING (bucket_id = 'quiz-screenshots');

CREATE POLICY "quiz_screenshots_delete" ON storage.objects
    FOR DELETE USING (bucket_id = 'quiz-screenshots' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "learning_materials_upload" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'learning-materials' AND
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('teacher', 'admin'))
    );

CREATE POLICY "learning_materials_read" ON storage.objects
    FOR SELECT USING (bucket_id = 'learning-materials');

CREATE POLICY "learning_materials_delete" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'learning-materials' AND
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('teacher', 'admin'))
    );

CREATE POLICY "avatars_upload" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'avatars' AND auth.uid() IS NOT NULL AND auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "avatars_read" ON storage.objects
    FOR SELECT USING (bucket_id = 'avatars');

CREATE POLICY "avatars_update" ON storage.objects
    FOR UPDATE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "avatars_delete" ON storage.objects
    FOR DELETE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- ============================================================
-- SECTION 8: GRANTS
-- ============================================================
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- ============================================================
-- SETUP COMPLETE!
-- ============================================================
-- After running this script:
-- 1. Create your first admin user through the admin-login.html page
-- 2. Manually update that user's role to 'admin' in the users table:
--    UPDATE public.users SET role = 'admin' WHERE email = 'your-admin-email@example.com';
-- 3. Start creating teacher and student accounts through the register page
-- ============================================================
