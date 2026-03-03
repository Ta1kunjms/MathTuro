-- ============================================================
-- FIX: learning-materials upload blocked by RLS
-- Run this once in Supabase SQL Editor
-- ============================================================

BEGIN;

-- Ensure bucket exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('learning-materials', 'learning-materials', true)
ON CONFLICT (id) DO NOTHING;

-- Replace potentially broken/duplicate policies for learning-materials
DROP POLICY IF EXISTS "Anyone can view learning materials" ON storage.objects;
DROP POLICY IF EXISTS "Teachers can upload learning materials" ON storage.objects;
DROP POLICY IF EXISTS "Teachers can delete learning materials" ON storage.objects;
DROP POLICY IF EXISTS learning_materials_read ON storage.objects;
DROP POLICY IF EXISTS learning_materials_upload ON storage.objects;
DROP POLICY IF EXISTS learning_materials_update ON storage.objects;
DROP POLICY IF EXISTS learning_materials_delete ON storage.objects;

CREATE POLICY learning_materials_read
ON storage.objects
FOR SELECT
USING (bucket_id = 'learning-materials');

CREATE POLICY learning_materials_upload
ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = 'learning-materials'
  AND COALESCE(
    auth.jwt() -> 'user_metadata' ->> 'role',
    auth.jwt() -> 'app_metadata' ->> 'role'
  ) IN ('teacher', 'admin')
  AND (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY learning_materials_update
ON storage.objects
FOR UPDATE
USING (
  bucket_id = 'learning-materials'
  AND COALESCE(
    auth.jwt() -> 'user_metadata' ->> 'role',
    auth.jwt() -> 'app_metadata' ->> 'role'
  ) IN ('teacher', 'admin')
  AND (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
  bucket_id = 'learning-materials'
  AND COALESCE(
    auth.jwt() -> 'user_metadata' ->> 'role',
    auth.jwt() -> 'app_metadata' ->> 'role'
  ) IN ('teacher', 'admin')
  AND (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY learning_materials_delete
ON storage.objects
FOR DELETE
USING (
  bucket_id = 'learning-materials'
  AND COALESCE(
    auth.jwt() -> 'user_metadata' ->> 'role',
    auth.jwt() -> 'app_metadata' ->> 'role'
  ) IN ('teacher', 'admin')
  AND (storage.foldername(name))[1] = auth.uid()::text
);

NOTIFY pgrst, 'reload schema';

COMMIT;
