-- Migration v12: Persistent student achievements
-- Purpose:
-- 1) Store earned achievements permanently.
-- 2) Keep earned date history and prevent losing previously earned badges.

CREATE TABLE IF NOT EXISTS public.student_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    achievement_id TEXT NOT NULL,
    earned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(student_id, achievement_id)
);

CREATE INDEX IF NOT EXISTS idx_student_achievements_student
    ON public.student_achievements(student_id);

CREATE INDEX IF NOT EXISTS idx_student_achievements_achievement
    ON public.student_achievements(achievement_id);

ALTER TABLE public.student_achievements ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS students_manage_own_achievements ON public.student_achievements;
CREATE POLICY students_manage_own_achievements
    ON public.student_achievements
    FOR ALL
    USING (auth.uid() = student_id)
    WITH CHECK (auth.uid() = student_id);

DROP POLICY IF EXISTS teachers_view_student_achievements ON public.student_achievements;
CREATE POLICY teachers_view_student_achievements
    ON public.student_achievements
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1
            FROM public.lesson_progress lp
            JOIN public.modules m ON m.id = lp.module_id
            WHERE lp.user_id = student_achievements.student_id
              AND m.teacher_id = auth.uid()
            LIMIT 1
        )
    );

DROP POLICY IF EXISTS admin_view_student_achievements ON public.student_achievements;
CREATE POLICY admin_view_student_achievements
    ON public.student_achievements
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1
            FROM public.users u
            WHERE u.id = auth.uid()
              AND u.role = 'admin'
        )
    );

DROP TRIGGER IF EXISTS trg_student_achievements_updated_at ON public.student_achievements;
CREATE TRIGGER trg_student_achievements_updated_at
    BEFORE UPDATE ON public.student_achievements
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

GRANT ALL ON public.student_achievements TO authenticated;
