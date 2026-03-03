-- ============================================================
-- MATHTURO MASTER DB RESTORE (ONE FILE)
-- Copy-paste this entire script into Supabase SQL Editor, then Run.
-- ============================================================

BEGIN;

-- ============================================================
-- 0) HARD RESET PUBLIC SCHEMA
-- ============================================================
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;

GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON SCHEMA public TO postgres, service_role;

-- ============================================================
-- 1) EXTENSIONS
-- ============================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================
-- 2) BASE TABLES
-- ============================================================

CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'student' CHECK (role IN ('student', 'teacher', 'admin')),
    avatar_url TEXT,
    is_active BOOLEAN DEFAULT true,
    last_login TIMESTAMPTZ,
    grade_level_text VARCHAR(100),
    section_text VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_users_role ON public.users(role);
CREATE INDEX idx_users_email ON public.users(email);
CREATE INDEX idx_users_grade_level_text ON public.users(grade_level_text) WHERE grade_level_text IS NOT NULL;
CREATE INDEX idx_users_section_text ON public.users(section_text) WHERE section_text IS NOT NULL;

CREATE TABLE public.modules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    cover_image_url TEXT,
    content_type VARCHAR(20) DEFAULT 'pdf' CHECK (content_type IN ('pdf', 'images')),
    pdf_url TEXT,
    image_urls TEXT[],
    teacher_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
    order_index INTEGER DEFAULT 0,
    total_lessons INTEGER DEFAULT 0,
    grade_level VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_modules_teacher ON public.modules(teacher_id);
CREATE INDEX idx_modules_status ON public.modules(status);
CREATE INDEX idx_modules_grade_level ON public.modules(grade_level);

CREATE TABLE public.lessons (
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
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_lessons_module ON public.lessons(module_id);

CREATE TABLE public.videos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    module_id UUID REFERENCES public.modules(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    video_url TEXT NOT NULL,
    thumbnail_url TEXT,
    order_index INTEGER DEFAULT 0,
    duration_minutes INTEGER DEFAULT 0,
    created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    category VARCHAR(100),
    subject VARCHAR(100),
    grade_level VARCHAR(50),
    is_published BOOLEAN DEFAULT false,
    teacher_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    view_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_videos_module ON public.videos(module_id);
CREATE INDEX idx_videos_order ON public.videos(order_index);
CREATE INDEX idx_videos_teacher ON public.videos(teacher_id);
CREATE INDEX idx_videos_category ON public.videos(category);
CREATE INDEX idx_videos_published ON public.videos(is_published);

CREATE TABLE public.quizzes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    module_id UUID REFERENCES public.modules(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    quiz_url TEXT NOT NULL,
    total_items INTEGER NOT NULL DEFAULT 10,
    passing_score INTEGER DEFAULT 0,
    order_index INTEGER DEFAULT 0,
    is_required BOOLEAN DEFAULT true,
    deadline TIMESTAMPTZ,
    created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    category VARCHAR(100),
    subject VARCHAR(100),
    grade_level VARCHAR(50),
    is_published BOOLEAN DEFAULT false,
    teacher_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    video_id UUID REFERENCES public.videos(id) ON DELETE SET NULL,
    time_limit_minutes INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_quizzes_module ON public.quizzes(module_id);
CREATE INDEX idx_quizzes_teacher ON public.quizzes(teacher_id);
CREATE INDEX idx_quizzes_video ON public.quizzes(video_id);
CREATE INDEX idx_quizzes_category ON public.quizzes(category);
CREATE INDEX idx_quizzes_grade_level ON public.quizzes(grade_level);
CREATE INDEX idx_quizzes_published ON public.quizzes(is_published);

CREATE TABLE public.lesson_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    lesson_id UUID NOT NULL REFERENCES public.lessons(id) ON DELETE CASCADE,
    module_id UUID NOT NULL REFERENCES public.modules(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'not_started' CHECK (status IN ('not_started', 'in_progress', 'completed')),
    progress_percent INTEGER DEFAULT 0 CHECK (progress_percent >= 0 AND progress_percent <= 100),
    time_spent_minutes INTEGER DEFAULT 0,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, lesson_id)
);

CREATE INDEX idx_progress_user ON public.lesson_progress(user_id);
CREATE INDEX idx_progress_lesson ON public.lesson_progress(lesson_id);
CREATE INDEX idx_progress_module ON public.lesson_progress(module_id);

CREATE TABLE public.quiz_submissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    lesson_id UUID REFERENCES public.lessons(id) ON DELETE CASCADE,
    module_id UUID REFERENCES public.modules(id) ON DELETE CASCADE,
    quiz_id UUID REFERENCES public.quizzes(id) ON DELETE CASCADE,
    screenshot_url TEXT,
    student_score INTEGER DEFAULT 0,
    total_items INTEGER DEFAULT 0,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'approved', 'rejected')),
    teacher_feedback TEXT,
    teacher_comment TEXT,
    reviewed_by UUID REFERENCES public.users(id),
    reviewed_at TIMESTAMPTZ,
    submitted_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_submissions_user ON public.quiz_submissions(user_id);
CREATE INDEX idx_submissions_lesson ON public.quiz_submissions(lesson_id);
CREATE INDEX idx_submissions_quiz ON public.quiz_submissions(quiz_id);
CREATE INDEX idx_submissions_status ON public.quiz_submissions(status);

CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) DEFAULT 'info' CHECK (type IN ('info', 'success', 'warning', 'error', 'quiz_reviewed', 'new_module', 'announcement')),
    is_read BOOLEAN DEFAULT false,
    link TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON public.notifications(user_id);
CREATE INDEX idx_notifications_read ON public.notifications(is_read);

CREATE TABLE public.activity_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50),
    entity_id UUID,
    details JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_activity_user ON public.activity_log(user_id);
CREATE INDEX idx_activity_action ON public.activity_log(action);
CREATE INDEX idx_activity_created ON public.activity_log(created_at DESC);

-- ============================================================
-- 3) GRADE / SECTION TABLES (V6+)
-- ============================================================

CREATE TABLE public.grade_levels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.sections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) NOT NULL,
    grade_level_id UUID NOT NULL REFERENCES public.grade_levels(id) ON DELETE CASCADE,
    teacher_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(name, grade_level_id)
);

CREATE INDEX idx_grade_levels_active ON public.grade_levels(is_active);
CREATE INDEX idx_sections_grade ON public.sections(grade_level_id);
CREATE INDEX idx_sections_teacher ON public.sections(teacher_id);
CREATE INDEX idx_sections_active ON public.sections(is_active);

ALTER TABLE public.users
ADD COLUMN grade_level_id UUID REFERENCES public.grade_levels(id) ON DELETE SET NULL,
ADD COLUMN section_id UUID REFERENCES public.sections(id) ON DELETE SET NULL;

CREATE INDEX idx_users_grade_level_id ON public.users(grade_level_id) WHERE role = 'student';
CREATE INDEX idx_users_section_id ON public.users(section_id) WHERE role = 'student';

ALTER TABLE public.modules
ADD COLUMN grade_level_id UUID REFERENCES public.grade_levels(id) ON DELETE SET NULL,
ADD COLUMN section_id UUID REFERENCES public.sections(id) ON DELETE SET NULL;

ALTER TABLE public.videos
ADD COLUMN grade_level_id UUID REFERENCES public.grade_levels(id) ON DELETE SET NULL,
ADD COLUMN section_id UUID REFERENCES public.sections(id) ON DELETE SET NULL;

ALTER TABLE public.quizzes
ADD COLUMN grade_level_id UUID REFERENCES public.grade_levels(id) ON DELETE SET NULL,
ADD COLUMN section_id UUID REFERENCES public.sections(id) ON DELETE SET NULL;

CREATE INDEX idx_modules_grade_level_id ON public.modules(grade_level_id);
CREATE INDEX idx_modules_section_id ON public.modules(section_id);
CREATE INDEX idx_videos_grade_level_id ON public.videos(grade_level_id);
CREATE INDEX idx_videos_section_id ON public.videos(section_id);
CREATE INDEX idx_quizzes_grade_level_id ON public.quizzes(grade_level_id);
CREATE INDEX idx_quizzes_section_id ON public.quizzes(section_id);

-- ============================================================
-- 4) ADDITIONAL TABLES (V2/V4/V5/V7)
-- ============================================================

CREATE TABLE public.lesson_plan_files (
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

CREATE INDEX idx_lesson_plan_files_user ON public.lesson_plan_files(user_id);
CREATE INDEX idx_lesson_plan_files_module ON public.lesson_plan_files(module_name);
CREATE INDEX idx_lesson_plan_files_uploaded ON public.lesson_plan_files(uploaded_at DESC);

CREATE TABLE public.settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_name VARCHAR(100) NOT NULL DEFAULT 'MathTuro',
    language VARCHAR(10) NOT NULL DEFAULT 'en',
    min_password_length INTEGER NOT NULL DEFAULT 8,
    require_special_chars BOOLEAN NOT NULL DEFAULT true,
    smtp_host VARCHAR(255) DEFAULT 'smtp.gmail.com',
    smtp_port INTEGER DEFAULT 587,
    smtp_username VARCHAR(255),
    smtp_password TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO public.settings (system_name, language, min_password_length, require_special_chars, smtp_host, smtp_port)
VALUES ('MathTuro', 'en', 8, true, 'smtp.gmail.com', 587);

CREATE TABLE public.video_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    video_id UUID NOT NULL REFERENCES public.videos(id) ON DELETE CASCADE,
    watch_time_seconds INTEGER DEFAULT 0,
    completed BOOLEAN DEFAULT false,
    last_watched_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(student_id, video_id)
);

CREATE TABLE public.video_favorites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    video_id UUID NOT NULL REFERENCES public.videos(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(student_id, video_id)
);

CREATE INDEX idx_video_progress_student ON public.video_progress(student_id);
CREATE INDEX idx_video_progress_video ON public.video_progress(video_id);
CREATE INDEX idx_video_favorites_student ON public.video_favorites(student_id);

CREATE TABLE public.tutorial_videos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100) NOT NULL DEFAULT 'general',
    video_url TEXT NOT NULL,
    thumbnail_url TEXT,
    duration VARCHAR(20),
    is_featured BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    "order" INTEGER DEFAULT 0,
    created_by UUID REFERENCES public.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.video_views (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    video_id UUID REFERENCES public.tutorial_videos(id) ON DELETE CASCADE,
    student_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    viewed_at TIMESTAMPTZ DEFAULT NOW(),
    watch_duration INTEGER DEFAULT 0,
    completed BOOLEAN DEFAULT FALSE
);

CREATE TABLE public.student_streaks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES public.users(id) ON DELETE CASCADE UNIQUE,
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    last_activity_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.student_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    lesson_id UUID REFERENCES public.lessons(id) ON DELETE SET NULL,
    content TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(student_id, lesson_id)
);

CREATE INDEX idx_tutorial_videos_category ON public.tutorial_videos(category);
CREATE INDEX idx_tutorial_videos_featured ON public.tutorial_videos(is_featured) WHERE is_featured = TRUE;
CREATE INDEX idx_tutorial_videos_active ON public.tutorial_videos(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_video_views_video ON public.video_views(video_id);
CREATE INDEX idx_video_views_student ON public.video_views(student_id);
CREATE INDEX idx_video_views_date ON public.video_views(viewed_at);
CREATE INDEX idx_student_streaks_student ON public.student_streaks(student_id);
CREATE INDEX idx_student_notes_student ON public.student_notes(student_id);
CREATE INDEX idx_student_notes_lesson ON public.student_notes(lesson_id);

-- ============================================================
-- 5) TRIGGERS / FUNCTIONS
-- ============================================================

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER trg_modules_updated_at BEFORE UPDATE ON public.modules FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER trg_lessons_updated_at BEFORE UPDATE ON public.lessons FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER trg_videos_updated_at BEFORE UPDATE ON public.videos FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER trg_quizzes_updated_at BEFORE UPDATE ON public.quizzes FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER trg_quiz_submissions_updated_at BEFORE UPDATE ON public.quiz_submissions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER trg_grade_levels_updated_at BEFORE UPDATE ON public.grade_levels FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER trg_sections_updated_at BEFORE UPDATE ON public.sections FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER trg_settings_updated_at BEFORE UPDATE ON public.settings FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER trg_tutorial_videos_updated_at BEFORE UPDATE ON public.tutorial_videos FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER trg_student_streaks_updated_at BEFORE UPDATE ON public.student_streaks FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER trg_student_notes_updated_at BEFORE UPDATE ON public.student_notes FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE OR REPLACE FUNCTION public.handle_submission_update()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status = 'rejected' THEN
        NEW.status = 'pending';
        NEW.teacher_comment = NULL;
        NEW.teacher_feedback = NULL;
        NEW.reviewed_at = NULL;
        NEW.reviewed_by = NULL;
    END IF;
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_submission_update
    BEFORE UPDATE ON public.quiz_submissions
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_submission_update();

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.users (id, email, full_name, role, created_at, updated_at)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE(NULLIF(NEW.raw_user_meta_data->>'role', ''), 'student'),
        COALESCE(NEW.created_at, NOW()),
        NOW()
    )
    ON CONFLICT (id) DO NOTHING;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Backfill existing auth users to public.users
INSERT INTO public.users (id, email, full_name, role, created_at, updated_at)
SELECT
    au.id,
    au.email,
    COALESCE(au.raw_user_meta_data->>'full_name', split_part(au.email, '@', 1)) AS full_name,
    COALESCE(NULLIF(au.raw_user_meta_data->>'role', ''), 'student') AS role,
    COALESCE(au.created_at, NOW()) AS created_at,
    NOW() AS updated_at
FROM auth.users au
LEFT JOIN public.users pu ON pu.id = au.id
WHERE pu.id IS NULL;

-- ============================================================
-- 6) RLS ENABLE
-- ============================================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.videos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lesson_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.grade_levels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lesson_plan_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.video_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.video_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tutorial_videos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.video_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_notes ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 7) RLS POLICIES
-- ============================================================

-- USERS (recursion-safe admin policy)
CREATE POLICY users_read_own_profile ON public.users FOR SELECT USING (auth.uid() = id);
CREATE POLICY users_insert_own_profile ON public.users FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY users_update_own_profile ON public.users FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
CREATE POLICY admin_manage_all_users ON public.users FOR ALL USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');
CREATE POLICY teachers_view_all_students ON public.users
FOR SELECT USING (
    role = 'student'
    AND COALESCE(
        auth.jwt() -> 'user_metadata' ->> 'role',
        auth.jwt() -> 'app_metadata' ->> 'role'
    ) IN ('teacher', 'admin')
);

-- MODULES
CREATE POLICY modules_read_published ON public.modules FOR SELECT USING (status = 'published');
CREATE POLICY teachers_read_own_modules ON public.modules FOR SELECT USING (teacher_id = auth.uid());
CREATE POLICY teachers_create_modules ON public.modules FOR INSERT WITH CHECK (teacher_id = auth.uid());
CREATE POLICY teachers_update_own_modules ON public.modules FOR UPDATE USING (teacher_id = auth.uid());
CREATE POLICY teachers_delete_own_modules ON public.modules FOR DELETE USING (teacher_id = auth.uid());
CREATE POLICY admin_manage_modules ON public.modules FOR ALL USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

-- LESSONS
CREATE POLICY lessons_read_published ON public.lessons
FOR SELECT USING (EXISTS (SELECT 1 FROM public.modules m WHERE m.id = module_id AND m.status = 'published'));
CREATE POLICY teachers_manage_own_lessons ON public.lessons
FOR ALL USING (EXISTS (SELECT 1 FROM public.modules m WHERE m.id = module_id AND m.teacher_id = auth.uid()));
CREATE POLICY admin_manage_lessons ON public.lessons
FOR ALL USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

-- VIDEOS
CREATE POLICY anyone_view_published_videos ON public.videos FOR SELECT USING (is_published = true);
CREATE POLICY teachers_view_own_videos ON public.videos FOR SELECT USING (teacher_id = auth.uid());
CREATE POLICY teachers_insert_videos ON public.videos FOR INSERT WITH CHECK (teacher_id = auth.uid());
CREATE POLICY teachers_update_own_videos ON public.videos FOR UPDATE USING (teacher_id = auth.uid());
CREATE POLICY teachers_delete_own_videos ON public.videos FOR DELETE USING (teacher_id = auth.uid());
CREATE POLICY admin_all_videos ON public.videos FOR ALL USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

-- QUIZZES
CREATE POLICY anyone_view_published_quizzes ON public.quizzes FOR SELECT USING (is_published = true);
CREATE POLICY teachers_view_own_quizzes ON public.quizzes
FOR SELECT USING (teacher_id = auth.uid() OR EXISTS (SELECT 1 FROM public.modules m WHERE m.id = module_id AND m.teacher_id = auth.uid()));
CREATE POLICY teachers_insert_quizzes ON public.quizzes
FOR INSERT WITH CHECK (teacher_id = auth.uid() OR EXISTS (SELECT 1 FROM public.modules m WHERE m.id = module_id AND m.teacher_id = auth.uid()));
CREATE POLICY teachers_update_own_quizzes ON public.quizzes
FOR UPDATE USING (teacher_id = auth.uid() OR EXISTS (SELECT 1 FROM public.modules m WHERE m.id = module_id AND m.teacher_id = auth.uid()));
CREATE POLICY teachers_delete_own_quizzes ON public.quizzes
FOR DELETE USING (teacher_id = auth.uid() OR EXISTS (SELECT 1 FROM public.modules m WHERE m.id = module_id AND m.teacher_id = auth.uid()));
CREATE POLICY admin_all_quizzes ON public.quizzes FOR ALL USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

-- QUIZ SUBMISSIONS
CREATE POLICY submissions_read_own ON public.quiz_submissions FOR SELECT USING (user_id = auth.uid());
CREATE POLICY submissions_create_own ON public.quiz_submissions FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY submissions_update_own ON public.quiz_submissions FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY teachers_view_submissions ON public.quiz_submissions
FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.modules m WHERE m.id = module_id AND m.teacher_id = auth.uid())
    OR EXISTS (SELECT 1 FROM public.quizzes q WHERE q.id = quiz_id AND q.teacher_id = auth.uid())
);
CREATE POLICY teachers_update_submissions ON public.quiz_submissions
FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.modules m WHERE m.id = module_id AND m.teacher_id = auth.uid())
    OR EXISTS (SELECT 1 FROM public.quizzes q WHERE q.id = quiz_id AND q.teacher_id = auth.uid())
);
CREATE POLICY admin_manage_submissions ON public.quiz_submissions
FOR ALL USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

-- LESSON PROGRESS
CREATE POLICY students_manage_own_lesson_progress ON public.lesson_progress FOR ALL USING (user_id = auth.uid());
CREATE POLICY teachers_view_lesson_progress ON public.lesson_progress
FOR SELECT USING (EXISTS (SELECT 1 FROM public.modules m WHERE m.id = module_id AND m.teacher_id = auth.uid()));
CREATE POLICY admin_manage_lesson_progress ON public.lesson_progress
FOR ALL USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

-- NOTIFICATIONS
CREATE POLICY users_manage_own_notifications ON public.notifications FOR ALL USING (user_id = auth.uid());
CREATE POLICY admin_manage_notifications ON public.notifications FOR ALL USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

-- ACTIVITY LOG
CREATE POLICY users_read_own_activity_log ON public.activity_log FOR SELECT USING (user_id = auth.uid());
CREATE POLICY admin_manage_activity_log ON public.activity_log FOR ALL USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

-- GRADE LEVELS / SECTIONS
CREATE POLICY admin_manage_grade_levels ON public.grade_levels FOR ALL USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY everyone_view_active_grade_levels ON public.grade_levels FOR SELECT USING (is_active = true);
CREATE POLICY admin_manage_sections ON public.sections FOR ALL USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));
DROP POLICY IF EXISTS admin_manage_sections ON public.sections;
CREATE POLICY admin_manage_sections ON public.sections
FOR ALL USING (
    COALESCE(
        auth.jwt() -> 'user_metadata' ->> 'role',
        auth.jwt() -> 'app_metadata' ->> 'role'
    ) = 'admin'
)
WITH CHECK (
    COALESCE(
        auth.jwt() -> 'user_metadata' ->> 'role',
        auth.jwt() -> 'app_metadata' ->> 'role'
    ) = 'admin'
);
CREATE POLICY teachers_view_own_sections ON public.sections FOR SELECT USING (teacher_id = auth.uid());
CREATE POLICY everyone_view_active_sections ON public.sections FOR SELECT USING (is_active = true);

-- LESSON PLAN FILES
CREATE POLICY teachers_view_own_lesson_plan_files ON public.lesson_plan_files FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY teachers_insert_own_lesson_plan_files ON public.lesson_plan_files FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY teachers_update_own_lesson_plan_files ON public.lesson_plan_files FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY teachers_delete_own_lesson_plan_files ON public.lesson_plan_files FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY admin_view_all_lesson_plan_files ON public.lesson_plan_files FOR SELECT USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

-- SETTINGS
CREATE POLICY admin_view_settings ON public.settings FOR SELECT USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY admin_update_settings ON public.settings FOR UPDATE USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY admin_insert_settings ON public.settings FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

-- V2 TABLES
CREATE POLICY anyone_view_active_tutorial_videos ON public.tutorial_videos FOR SELECT USING (is_active = TRUE);
CREATE POLICY teachers_manage_tutorial_videos ON public.tutorial_videos FOR ALL USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('teacher', 'admin')));
CREATE POLICY students_manage_own_video_views ON public.video_views FOR ALL USING (auth.uid() = student_id);
CREATE POLICY students_manage_own_streaks ON public.student_streaks FOR ALL USING (auth.uid() = student_id);
CREATE POLICY students_manage_own_notes ON public.student_notes FOR ALL USING (auth.uid() = student_id);
CREATE POLICY students_manage_own_video_progress ON public.video_progress FOR ALL USING (student_id = auth.uid());
CREATE POLICY students_manage_own_video_favorites ON public.video_favorites FOR ALL USING (student_id = auth.uid());

-- ============================================================
-- 8) OPTIONAL SEED DATA
-- ============================================================
INSERT INTO public.grade_levels (name, description)
VALUES
    ('Grade 7', 'First year of junior high school'),
    ('Grade 8', 'Second year of junior high school'),
    ('Grade 9', 'Third year of junior high school'),
    ('Grade 10', 'Fourth year of junior high school')
ON CONFLICT (name) DO NOTHING;

-- ============================================================
-- 9) ACCESS GRANTS
-- ============================================================
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;

COMMIT;

-- ============================================================
-- 10) ADMIN DELETE USER RPC (required by admin/users.html)
-- ============================================================

BEGIN;

DROP FUNCTION IF EXISTS public.admin_delete_user(uuid);

CREATE OR REPLACE FUNCTION public.admin_delete_user(target_user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    requester_id uuid := auth.uid();
    requester_role text;
BEGIN
    IF requester_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT role INTO requester_role
    FROM public.users
    WHERE id = requester_id;

    IF requester_role IS DISTINCT FROM 'admin' THEN
        RAISE EXCEPTION 'Only admins can delete users';
    END IF;

    IF target_user_id = requester_id THEN
        RAISE EXCEPTION 'You cannot delete your own account';
    END IF;

    DELETE FROM public.users
    WHERE id = target_user_id;

    DELETE FROM auth.users
    WHERE id = target_user_id;

    RETURN true;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_delete_user(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_delete_user(uuid) TO authenticated;
NOTIFY pgrst, 'reload schema';

COMMIT;

-- ============================================================
-- 11) ADMIN FIX (RUN AFTER YOU CREATE AUTH USER)
-- ============================================================
-- If needed, run this AFTER creating admin@mathturo.com in Auth > Users:
--
-- INSERT INTO public.users (id, email, full_name, role, is_active, created_at, updated_at)
-- SELECT id, 'admin@mathturo.com', 'System Admin', 'admin', true, NOW(), NOW()
-- FROM auth.users
-- WHERE email = 'admin@mathturo.com'
-- ON CONFLICT (id) DO UPDATE
-- SET full_name = EXCLUDED.full_name,
--     role = EXCLUDED.role,
--     is_active = EXCLUDED.is_active,
--     updated_at = EXCLUDED.updated_at;

-- ============================================================
-- 12) QUICK VERIFY
-- ============================================================
-- SELECT COUNT(*) AS users_count FROM public.users;
-- SELECT COUNT(*) AS modules_count FROM public.modules;
-- SELECT COUNT(*) AS videos_count FROM public.videos;
-- SELECT COUNT(*) AS quizzes_count FROM public.quizzes;
-- SELECT COUNT(*) AS submissions_count FROM public.quiz_submissions;
