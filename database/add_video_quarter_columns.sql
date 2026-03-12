-- Add quarter support for tutorial video filtering across portals

ALTER TABLE public.videos
ADD COLUMN IF NOT EXISTS quarter VARCHAR(10)
CHECK (quarter IN ('1', '2', '3', '4'));

ALTER TABLE public.tutorial_videos
ADD COLUMN IF NOT EXISTS quarter VARCHAR(10)
CHECK (quarter IN ('1', '2', '3', '4'));

CREATE INDEX IF NOT EXISTS idx_videos_quarter
ON public.videos(quarter);

CREATE INDEX IF NOT EXISTS idx_tutorial_videos_quarter
ON public.tutorial_videos(quarter);

-- Optional rollback
-- DROP INDEX IF EXISTS idx_videos_quarter;
-- DROP INDEX IF EXISTS idx_tutorial_videos_quarter;
-- ALTER TABLE public.videos DROP COLUMN IF EXISTS quarter;
-- ALTER TABLE public.tutorial_videos DROP COLUMN IF EXISTS quarter;