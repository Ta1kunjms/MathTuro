-- ============================================================
-- MIGRATION: ADD GRADE LEVEL TO MODULES
-- MathTuro LMS - Module Grade Level Support
-- ============================================================

-- Add grade_level column to modules table
ALTER TABLE public.modules ADD COLUMN IF NOT EXISTS grade_level VARCHAR(50);

-- Create index for faster querying
CREATE INDEX IF NOT EXISTS idx_modules_grade_level ON public.modules(grade_level);

-- Update existing modules with sample grade levels (for testing purposes)
UPDATE public.modules 
SET grade_level = CASE 
    WHEN id::text LIKE '%1%' THEN 'Grade 7'
    WHEN id::text LIKE '%2%' THEN 'Grade 8'
    WHEN id::text LIKE '%3%' THEN 'Grade 9'
    WHEN id::text LIKE '%4%' THEN 'Grade 10'
    ELSE 'Grade 7' -- Default to Grade 7 if no match
END
WHERE grade_level IS NULL;

-- Verify the changes
SELECT 'Modules with grade levels:', COUNT(*) FROM public.modules WHERE grade_level IS NOT NULL;
SELECT grade_level, COUNT(*) FROM public.modules GROUP BY grade_level ORDER BY grade_level;
