-- ============================================================
-- FIX_DELETED_VIDEOS_SYNC.sql
-- Purpose:
-- 1) Delete ALL existing videos across 'videos', 'tutorial_videos', and 'video_views'
-- 2) Install a database trigger on 'videos' table so deleting a video automatically
--    deletes its mirrored record in 'tutorial_videos'
-- ============================================================

BEGIN;

-- 1) Delete all existing video records
DELETE FROM public.video_views;
DELETE FROM public.tutorial_videos;
DELETE FROM public.videos;

-- 2) Trigger function to auto-delete mirrored tutorial_videos on deletion from videos table
CREATE OR REPLACE FUNCTION public.fn_sync_video_deletion()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.video_url IS NOT NULL AND OLD.video_url <> '' THEN
        DELETE FROM public.tutorial_videos
        WHERE video_url = OLD.video_url;
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3) Attach trigger to public.videos table
DROP TRIGGER IF EXISTS trg_sync_video_deletion ON public.videos;

CREATE TRIGGER trg_sync_video_deletion
AFTER DELETE ON public.videos
FOR EACH ROW
EXECUTE FUNCTION public.fn_sync_video_deletion();

COMMIT;
