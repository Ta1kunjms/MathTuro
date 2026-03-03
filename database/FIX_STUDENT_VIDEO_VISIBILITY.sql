-- FIX_STUDENT_VIDEO_VISIBILITY.sql
-- Purpose: Ensure students can see published teacher videos on tutorial pages.
-- Run this in Supabase SQL Editor.

BEGIN;

ALTER TABLE public.videos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "students_view_scoped_videos" ON public.videos;
DROP POLICY IF EXISTS "anyone_view_published_videos" ON public.videos;

CREATE POLICY "anyone_view_published_videos"
ON public.videos
FOR SELECT
USING (is_published = true);

COMMIT;
