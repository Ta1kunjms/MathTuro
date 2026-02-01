-- ============================================
-- MathTuro LMS - Additional Tables Migration
-- Version: 2.0
-- Purpose: Add tutorial videos, streaks, notes, and views tables
-- ============================================

-- ============================================
-- TUTORIAL VIDEOS TABLE
-- Stores tutorial video content for students
-- ============================================
CREATE TABLE IF NOT EXISTS tutorial_videos (
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
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for category filtering
CREATE INDEX IF NOT EXISTS idx_tutorial_videos_category ON tutorial_videos(category);
CREATE INDEX IF NOT EXISTS idx_tutorial_videos_featured ON tutorial_videos(is_featured) WHERE is_featured = TRUE;
CREATE INDEX IF NOT EXISTS idx_tutorial_videos_active ON tutorial_videos(is_active) WHERE is_active = TRUE;

-- ============================================
-- VIDEO VIEWS TABLE
-- Tracks student video watch history
-- ============================================
CREATE TABLE IF NOT EXISTS video_views (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    video_id UUID REFERENCES tutorial_videos(id) ON DELETE CASCADE,
    student_id UUID REFERENCES users(id) ON DELETE CASCADE,
    viewed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    watch_duration INTEGER DEFAULT 0, -- in seconds
    completed BOOLEAN DEFAULT FALSE
);

-- Create indexes for analytics
CREATE INDEX IF NOT EXISTS idx_video_views_video ON video_views(video_id);
CREATE INDEX IF NOT EXISTS idx_video_views_student ON video_views(student_id);
CREATE INDEX IF NOT EXISTS idx_video_views_date ON video_views(viewed_at);

-- ============================================
-- STUDENT STREAKS TABLE
-- Tracks daily learning streaks
-- ============================================
CREATE TABLE IF NOT EXISTS student_streaks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE,
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    last_activity_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for student lookup
CREATE INDEX IF NOT EXISTS idx_student_streaks_student ON student_streaks(student_id);

-- ============================================
-- STUDENT NOTES TABLE
-- Stores personal notes for students
-- ============================================
CREATE TABLE IF NOT EXISTS student_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES users(id) ON DELETE CASCADE,
    lesson_id UUID REFERENCES lessons(id) ON DELETE SET NULL,
    content TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(student_id, lesson_id)
);

-- Create indexes for note retrieval
CREATE INDEX IF NOT EXISTS idx_student_notes_student ON student_notes(student_id);
CREATE INDEX IF NOT EXISTS idx_student_notes_lesson ON student_notes(lesson_id);

-- ============================================
-- SAMPLE TUTORIAL VIDEOS
-- Insert some default tutorial videos
-- ============================================
INSERT INTO tutorial_videos (title, description, category, video_url, duration, is_featured, "order") VALUES
('Getting Started with MathTuro', 'Learn how to navigate the MathTuro learning platform, access modules, and track your progress.', 'getting-started', 'https://www.youtube.com/embed/dQw4w9WgXcQ', '5:30', TRUE, 1),
('How to Take Quizzes', 'A complete guide on taking quizzes, submitting answers, and understanding your scores.', 'getting-started', 'https://www.youtube.com/embed/dQw4w9WgXcQ', '3:45', TRUE, 2),
('Introduction to Algebra', 'Master the basics of algebraic expressions, equations, and problem-solving techniques.', 'algebra', 'https://www.youtube.com/embed/dQw4w9WgXcQ', '12:20', FALSE, 3),
('Solving Linear Equations', 'Step-by-step guide to solving linear equations with one and two variables.', 'algebra', 'https://www.youtube.com/embed/dQw4w9WgXcQ', '8:15', FALSE, 4),
('Basic Geometry Concepts', 'Learn about points, lines, angles, and basic geometric shapes.', 'geometry', 'https://www.youtube.com/embed/dQw4w9WgXcQ', '10:00', FALSE, 5),
('Area and Perimeter', 'Calculate area and perimeter of common shapes including rectangles, triangles, and circles.', 'geometry', 'https://www.youtube.com/embed/dQw4w9WgXcQ', '7:30', FALSE, 6),
('Introduction to Limits', 'Understanding the concept of limits in calculus with visual examples.', 'calculus', 'https://www.youtube.com/embed/dQw4w9WgXcQ', '15:45', FALSE, 7),
('Derivatives Explained', 'Learn how to find derivatives and understand their real-world applications.', 'calculus', 'https://www.youtube.com/embed/dQw4w9WgXcQ', '18:20', FALSE, 8),
('Mean, Median, and Mode', 'Understanding measures of central tendency in statistics.', 'statistics', 'https://www.youtube.com/embed/dQw4w9WgXcQ', '6:45', FALSE, 9),
('Effective Study Techniques', 'Proven study strategies to improve your learning and retention.', 'tips', 'https://www.youtube.com/embed/dQw4w9WgXcQ', '9:00', TRUE, 10),
('Time Management for Students', 'Learn to balance studies, activities, and rest for optimal performance.', 'tips', 'https://www.youtube.com/embed/dQw4w9WgXcQ', '7:15', FALSE, 11),
('Overcoming Math Anxiety', 'Practical tips to build confidence and reduce stress when studying math.', 'tips', 'https://www.youtube.com/embed/dQw4w9WgXcQ', '8:30', FALSE, 12)
ON CONFLICT DO NOTHING;

-- ============================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================

-- Enable RLS on new tables
ALTER TABLE tutorial_videos ENABLE ROW LEVEL SECURITY;
ALTER TABLE video_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_notes ENABLE ROW LEVEL SECURITY;

-- Tutorial Videos policies (viewable by all, editable by teachers/admins)
CREATE POLICY "Anyone can view active tutorial videos"
    ON tutorial_videos FOR SELECT
    USING (is_active = TRUE);

CREATE POLICY "Teachers and admins can manage tutorial videos"
    ON tutorial_videos FOR ALL
    USING (
        auth.uid() IN (
            SELECT id FROM users WHERE role IN ('teacher', 'admin')
        )
    );

-- Video Views policies
CREATE POLICY "Students can view their own video views"
    ON video_views FOR SELECT
    USING (auth.uid() = student_id);

CREATE POLICY "Students can insert their video views"
    ON video_views FOR INSERT
    WITH CHECK (auth.uid() = student_id);

-- Student Streaks policies
CREATE POLICY "Students can view their own streaks"
    ON student_streaks FOR SELECT
    USING (auth.uid() = student_id);

CREATE POLICY "Students can manage their own streaks"
    ON student_streaks FOR ALL
    USING (auth.uid() = student_id);

-- Student Notes policies
CREATE POLICY "Students can manage their own notes"
    ON student_notes FOR ALL
    USING (auth.uid() = student_id);

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Function to update streak on lesson completion
CREATE OR REPLACE FUNCTION update_streak_on_activity()
RETURNS TRIGGER AS $$
DECLARE
    v_student_id UUID;
    v_today DATE;
    v_last_activity DATE;
    v_current_streak INTEGER;
BEGIN
    v_student_id := NEW.student_id;
    v_today := CURRENT_DATE;
    
    -- Get existing streak
    SELECT last_activity_date, current_streak 
    INTO v_last_activity, v_current_streak
    FROM student_streaks 
    WHERE student_id = v_student_id;
    
    IF FOUND THEN
        IF v_last_activity = v_today - 1 THEN
            -- Consecutive day, increment streak
            UPDATE student_streaks 
            SET current_streak = current_streak + 1,
                longest_streak = GREATEST(longest_streak, current_streak + 1),
                last_activity_date = v_today,
                updated_at = NOW()
            WHERE student_id = v_student_id;
        ELSIF v_last_activity <> v_today THEN
            -- Not consecutive, reset streak
            UPDATE student_streaks 
            SET current_streak = 1,
                last_activity_date = v_today,
                updated_at = NOW()
            WHERE student_id = v_student_id;
        END IF;
    ELSE
        -- First activity, create streak record
        INSERT INTO student_streaks (student_id, current_streak, longest_streak, last_activity_date)
        VALUES (v_student_id, 1, 1, v_today);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for streak updates on lesson completion
DROP TRIGGER IF EXISTS trigger_update_streak ON lesson_progress;
CREATE TRIGGER trigger_update_streak
    AFTER INSERT OR UPDATE ON lesson_progress
    FOR EACH ROW
    WHEN (NEW.completed = TRUE)
    EXECUTE FUNCTION update_streak_on_activity();

-- ============================================
-- GRANT PERMISSIONS
-- ============================================
GRANT ALL ON tutorial_videos TO authenticated;
GRANT ALL ON video_views TO authenticated;
GRANT ALL ON student_streaks TO authenticated;
GRANT ALL ON student_notes TO authenticated;
