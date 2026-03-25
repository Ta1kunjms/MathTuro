-- Migration v11: Student module open/progress tracking
-- Purpose:
-- 1) Persist module-open activity for each student.
-- 2) Support functional module-level progress and streak updates from module opens.

CREATE TABLE IF NOT EXISTS public.student_module_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    module_id UUID NOT NULL REFERENCES public.modules(id) ON DELETE CASCADE,
    content_viewed BOOLEAN NOT NULL DEFAULT FALSE,
    first_opened_at TIMESTAMPTZ,
    last_opened_at TIMESTAMPTZ,
    open_count INTEGER NOT NULL DEFAULT 0,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(student_id, module_id)
);

CREATE INDEX IF NOT EXISTS idx_student_module_progress_student
    ON public.student_module_progress(student_id);

CREATE INDEX IF NOT EXISTS idx_student_module_progress_module
    ON public.student_module_progress(module_id);

CREATE INDEX IF NOT EXISTS idx_student_module_progress_last_opened
    ON public.student_module_progress(last_opened_at DESC);

ALTER TABLE public.student_module_progress ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS students_manage_own_module_progress ON public.student_module_progress;
CREATE POLICY students_manage_own_module_progress
    ON public.student_module_progress
    FOR ALL
    USING (auth.uid() = student_id)
    WITH CHECK (auth.uid() = student_id);

DROP POLICY IF EXISTS teachers_view_module_progress ON public.student_module_progress;
CREATE POLICY teachers_view_module_progress
    ON public.student_module_progress
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1
            FROM public.modules m
            WHERE m.id = student_module_progress.module_id
              AND m.teacher_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS admin_view_module_progress ON public.student_module_progress;
CREATE POLICY admin_view_module_progress
    ON public.student_module_progress
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1
            FROM public.users u
            WHERE u.id = auth.uid()
              AND u.role = 'admin'
        )
    );

DROP TRIGGER IF EXISTS trg_student_module_progress_updated_at ON public.student_module_progress;
CREATE TRIGGER trg_student_module_progress_updated_at
    BEFORE UPDATE ON public.student_module_progress
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

GRANT ALL ON public.student_module_progress TO authenticated;
