-- Fix: allow admins to view/manage teacher lesson plan files
-- Run this in Supabase SQL Editor.

ALTER TABLE public.lesson_plan_files ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can view all lesson plan files" ON public.lesson_plan_files;
CREATE POLICY "Admins can view all lesson plan files"
ON public.lesson_plan_files FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.users u
    WHERE u.id = auth.uid()
      AND u.role = 'admin'
  )
);

DROP POLICY IF EXISTS "Admins can update all lesson plan files" ON public.lesson_plan_files;
CREATE POLICY "Admins can update all lesson plan files"
ON public.lesson_plan_files FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.users u
    WHERE u.id = auth.uid()
      AND u.role = 'admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.users u
    WHERE u.id = auth.uid()
      AND u.role = 'admin'
  )
);

DROP POLICY IF EXISTS "Admins can delete all lesson plan files" ON public.lesson_plan_files;
CREATE POLICY "Admins can delete all lesson plan files"
ON public.lesson_plan_files FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.users u
    WHERE u.id = auth.uid()
      AND u.role = 'admin'
  )
);
