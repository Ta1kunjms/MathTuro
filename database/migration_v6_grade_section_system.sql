-- ============================================
-- MathTuro LMS - Grade and Section Management System
-- Version: 6.1
-- Purpose: Create admin-managed grade levels and sections with teacher assignments
-- ============================================

-- 1. Create grade_levels table (admin-managed)
CREATE TABLE IF NOT EXISTS public.grade_levels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_grade_levels_active ON public.grade_levels(is_active);

-- 2. Create sections table (admin-managed)
CREATE TABLE IF NOT EXISTS public.sections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) NOT NULL,
    grade_level_id UUID NOT NULL REFERENCES public.grade_levels(id) ON DELETE CASCADE,
    teacher_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(name, grade_level_id)
);

CREATE INDEX IF NOT EXISTS idx_sections_grade ON public.sections(grade_level_id);
CREATE INDEX IF NOT EXISTS idx_sections_teacher ON public.sections(teacher_id);
CREATE INDEX IF NOT EXISTS idx_sections_active ON public.sections(is_active);

-- 3. Modify users table to reference grade levels and sections
ALTER TABLE public.users 
DROP COLUMN IF EXISTS grade_level,
DROP COLUMN IF EXISTS section;

ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS grade_level_id UUID REFERENCES public.grade_levels(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS section_id UUID REFERENCES public.sections(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_users_grade_level ON public.users(grade_level_id)
WHERE role = 'student';

CREATE INDEX IF NOT EXISTS idx_users_section ON public.users(section_id)
WHERE role = 'student';

-- 4. RLS Policies for Grade Levels
ALTER TABLE public.grade_levels ENABLE ROW LEVEL SECURITY;

CREATE POLICY "admin_manage_grade_levels" ON public.grade_levels
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "everyone_view_active_grade_levels" ON public.grade_levels
    FOR SELECT USING (is_active = true);

-- 5. RLS Policies for Sections
ALTER TABLE public.sections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "admin_manage_sections" ON public.sections
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "teachers_view_own_sections" ON public.sections
    FOR SELECT USING (
        teacher_id = auth.uid()
    );

CREATE POLICY "everyone_view_active_sections" ON public.sections
    FOR SELECT USING (is_active = true);

-- 6. Triggers for updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_grade_levels_updated_at
    BEFORE UPDATE ON public.grade_levels
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sections_updated_at
    BEFORE UPDATE ON public.sections
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 7. Sample Data for Testing
INSERT INTO public.grade_levels (name, description) VALUES
    ('Grade 7', 'First year of junior high school'),
    ('Grade 8', 'Second year of junior high school'),
    ('Grade 9', 'Third year of junior high school'),
    ('Grade 10', 'Fourth year of junior high school')
ON CONFLICT (name) DO NOTHING;

INSERT INTO public.sections (name, grade_level_id, description) VALUES
    ('Section A', (SELECT id FROM public.grade_levels WHERE name = 'Grade 7'), 'Section A - Grade 7'),
    ('Section B', (SELECT id FROM public.grade_levels WHERE name = 'Grade 7'), 'Section B - Grade 7'),
    ('Section C', (SELECT id FROM public.grade_levels WHERE name = 'Grade 7'), 'Section C - Grade 7'),
    ('Section A', (SELECT id FROM public.grade_levels WHERE name = 'Grade 8'), 'Section A - Grade 8'),
    ('Section B', (SELECT id FROM public.grade_levels WHERE name = 'Grade 8'), 'Section B - Grade 8'),
    ('Section C', (SELECT id FROM public.grade_levels WHERE name = 'Grade 8'), 'Section C - Grade 8'),
    ('Section A', (SELECT id FROM public.grade_levels WHERE name = 'Grade 9'), 'Section A - Grade 9'),
    ('Section B', (SELECT id FROM public.grade_levels WHERE name = 'Grade 9'), 'Section B - Grade 9'),
    ('Section C', (SELECT id FROM public.grade_levels WHERE name = 'Grade 9'), 'Section C - Grade 9'),
    ('Section A', (SELECT id FROM public.grade_levels WHERE name = 'Grade 10'), 'Section A - Grade 10'),
    ('Section B', (SELECT id FROM public.grade_levels WHERE name = 'Grade 10'), 'Section B - Grade 10'),
    ('Section C', (SELECT id FROM public.grade_levels WHERE name = 'Grade 10'), 'Section C - Grade 10')
ON CONFLICT DO NOTHING;

-- Verify the setup
SELECT 'Grade Levels created:', COUNT(*) FROM public.grade_levels;
SELECT 'Sections created:', COUNT(*) FROM public.sections;
SELECT 'Users table modified:', EXISTS (SELECT 1 FROM information_schema.columns 
WHERE table_name = 'users' AND column_name = 'grade_level_id'),
EXISTS (SELECT 1 FROM information_schema.columns 
WHERE table_name = 'users' AND column_name = 'section_id');
