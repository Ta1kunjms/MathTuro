-- ============================================
-- MathTuro LMS - Test Grade Levels
-- Version: 1.0
-- Purpose: Create test grade levels for sections page functionality
-- ============================================

-- Create test grade levels (if not already exists)
INSERT INTO public.grade_levels (name, description, is_active, created_by) 
VALUES 
    ('Grade 7', 'First year of junior high school', true, NULL),
    ('Grade 8', 'Second year of junior high school', true, NULL),
    ('Grade 9', 'Third year of junior high school', true, NULL),
    ('Grade 10', 'Fourth year of junior high school', true, NULL)
ON CONFLICT (name) DO NOTHING;

-- Verify grade levels were created
SELECT id, name, description, is_active 
FROM public.grade_levels 
WHERE is_active = true 
ORDER BY name;