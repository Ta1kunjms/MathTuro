-- ============================================================
-- Migration: v7 - Registration grade/section text fields
-- Purpose:
-- - Support registration flows where users can manually enter grade/section text
-- - Keep compatibility with existing grade_level_id and section_id references
-- ============================================================

ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS grade_level_text VARCHAR(100),
ADD COLUMN IF NOT EXISTS section_text VARCHAR(100);

CREATE INDEX IF NOT EXISTS idx_users_grade_level_text
ON public.users(grade_level_text)
WHERE grade_level_text IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_users_section_text
ON public.users(section_text)
WHERE section_text IS NOT NULL;
