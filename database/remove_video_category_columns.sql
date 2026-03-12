-- Remove tutorial video category support across the system

ALTER TABLE public.videos
DROP COLUMN IF EXISTS category;

ALTER TABLE public.tutorial_videos
DROP COLUMN IF EXISTS category;

DROP INDEX IF EXISTS idx_tutorial_videos_category;