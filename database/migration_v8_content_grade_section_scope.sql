-- ============================================================
-- MIGRATION V8: CONTENT GRADE/SECTION SCOPE
-- Purpose: Allow modules, videos, and quizzes to target grade levels and sections
-- Notes:
-- - grade_level remains as text for backward compatibility
-- - grade_level_id and section_id provide canonical references
-- - NULL section_id means content is available to all sections in the selected grade
-- ============================================================

ALTER TABLE public.modules
ADD COLUMN IF NOT EXISTS grade_level_id UUID REFERENCES public.grade_levels(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS section_id UUID REFERENCES public.sections(id) ON DELETE SET NULL;

ALTER TABLE public.videos
ADD COLUMN IF NOT EXISTS grade_level_id UUID REFERENCES public.grade_levels(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS section_id UUID REFERENCES public.sections(id) ON DELETE SET NULL;

ALTER TABLE public.quizzes
ADD COLUMN IF NOT EXISTS grade_level_id UUID REFERENCES public.grade_levels(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS section_id UUID REFERENCES public.sections(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_modules_grade_level_id ON public.modules(grade_level_id);
CREATE INDEX IF NOT EXISTS idx_modules_section_id ON public.modules(section_id);

CREATE INDEX IF NOT EXISTS idx_videos_grade_level_id ON public.videos(grade_level_id);
CREATE INDEX IF NOT EXISTS idx_videos_section_id ON public.videos(section_id);

CREATE INDEX IF NOT EXISTS idx_quizzes_grade_level_id ON public.quizzes(grade_level_id);
CREATE INDEX IF NOT EXISTS idx_quizzes_section_id ON public.quizzes(section_id);
