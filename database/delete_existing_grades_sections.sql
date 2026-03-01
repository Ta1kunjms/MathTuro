-- ============================================
-- MathTuro LMS - Delete Existing Grades and Sections
-- Version: 1.0
-- Purpose: Delete existing grade levels and sections from the database
-- ============================================

-- CAUTION: This will delete all existing grade levels and sections
-- This is irreversible, so make sure you have backups if needed

-- First, check if there are any existing grade levels
SELECT 'Current grade levels:', COUNT(*) FROM public.grade_levels;
SELECT 'Current sections:', COUNT(*) FROM public.sections;

-- Delete all sections first (due to foreign key constraints)
DELETE FROM public.sections;

-- Delete all grade levels
DELETE FROM public.grade_levels;

-- Verify deletion
SELECT 'Grade levels after deletion:', COUNT(*) FROM public.grade_levels;
SELECT 'Sections after deletion:', COUNT(*) FROM public.sections;

-- Optional: Reset auto-increment counters (if using serial primary keys)
-- Note: Supabase uses UUIDs by default, so this may not be necessary
-- If you're using serial/auto-increment, you would use:
-- ALTER SEQUENCE grade_levels_id_seq RESTART WITH 1;
-- ALTER SEQUENCE sections_id_seq RESTART WITH 1;

-- Optional: Also remove any user associations to grade levels and sections
-- This will set grade_level_id and section_id to NULL for all users
UPDATE public.users 
SET grade_level_id = NULL, 
    section_id = NULL;

-- Verify user table updates
SELECT 'Users with grade level:', COUNT(*) FROM public.users WHERE grade_level_id IS NOT NULL;
SELECT 'Users with section:', COUNT(*) FROM public.users WHERE section_id IS NOT NULL;

-- Optional: Create new default grade levels and sections (uncomment if needed)
/*
INSERT INTO public.grade_levels (name, description, is_active) VALUES
    ('Grade 7', 'First year of junior high school', true),
    ('Grade 8', 'Second year of junior high school', true),
    ('Grade 9', 'Third year of junior high school', true),
    ('Grade 10', 'Fourth year of junior high school', true);

INSERT INTO public.sections (name, grade_level_id, description, is_active) VALUES
    ('Section A', (SELECT id FROM public.grade_levels WHERE name = 'Grade 7'), 'Section A - Grade 7', true),
    ('Section B', (SELECT id FROM public.grade_levels WHERE name = 'Grade 7'), 'Section B - Grade 7', true),
    ('Section C', (SELECT id FROM public.grade_levels WHERE name = 'Grade 7'), 'Section C - Grade 7', true),
    ('Section A', (SELECT id FROM public.grade_levels WHERE name = 'Grade 8'), 'Section A - Grade 8', true),
    ('Section B', (SELECT id FROM public.grade_levels WHERE name = 'Grade 8'), 'Section B - Grade 8', true),
    ('Section C', (SELECT id FROM public.grade_levels WHERE name = 'Grade 8'), 'Section C - Grade 8', true),
    ('Section A', (SELECT id FROM public.grade_levels WHERE name = 'Grade 9'), 'Section A - Grade 9', true),
    ('Section B', (SELECT id FROM public.grade_levels WHERE name = 'Grade 9'), 'Section B - Grade 9', true),
    ('Section C', (SELECT id FROM public.grade_levels WHERE name = 'Grade 9'), 'Section C - Grade 9', true),
    ('Section A', (SELECT id FROM public.grade_levels WHERE name = 'Grade 10'), 'Section A - Grade 10', true),
    ('Section B', (SELECT id FROM public.grade_levels WHERE name = 'Grade 10'), 'Section B - Grade 10', true),
    ('Section C', (SELECT id FROM public.grade_levels WHERE name = 'Grade 10'), 'Section C - Grade 10', true);

-- Verify new data
SELECT 'New grade levels:', COUNT(*) FROM public.grade_levels;
SELECT 'New sections:', COUNT(*) FROM public.sections;
*/
