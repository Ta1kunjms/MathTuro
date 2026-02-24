-- ============================================
-- MathTuro LMS - Add Grade and Section to Users
-- Version: 6.0
-- Purpose: Add grade level and section fields to users table
-- ============================================

-- Add grade level column to users table
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS grade_level VARCHAR(50);

-- Add section column to users table
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS section VARCHAR(50);

-- Create indexes for faster querying
CREATE INDEX IF NOT EXISTS idx_users_grade_level ON public.users(grade_level) 
WHERE role = 'student';

CREATE INDEX IF NOT EXISTS idx_users_section ON public.users(section) 
WHERE role = 'student';

CREATE INDEX IF NOT EXISTS idx_users_grade_section ON public.users(grade_level, section) 
WHERE role = 'student';

-- ============================================
-- SAMPLE DATA FOR TESTING
-- ============================================
-- Update existing student users with sample grade levels and sections
UPDATE public.users 
SET grade_level = CASE 
    WHEN id % 3 = 0 THEN 'Grade 7'
    WHEN id % 3 = 1 THEN 'Grade 8'
    ELSE 'Grade 9'
END,
section = CASE 
    WHEN id % 4 = 0 THEN 'Section A'
    WHEN id % 4 = 1 THEN 'Section B'
    WHEN id % 4 = 2 THEN 'Section C'
    ELSE 'Section D'
END
WHERE role = 'student' 
AND grade_level IS NULL;

-- Verify the changes
SELECT role, grade_level, section, COUNT(*) 
FROM public.users 
GROUP BY role, grade_level, section 
ORDER BY role, grade_level, section;
