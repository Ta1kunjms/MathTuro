-- ============================================================
-- MathTuro Migration: School Year Format & Registration Hardening
-- Date: 2026-10-22
-- Target: Production (ynkzcybctsstpqxdoweq)
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- 1. Modules Compatibility Column
-- Ensures module queries selecting is_published don't fail (e.g. manage-quizzes.html)
-- ------------------------------------------------------------
ALTER TABLE public.modules 
  ADD COLUMN IF NOT EXISTS is_published BOOLEAN DEFAULT true;

UPDATE public.modules 
SET is_published = (status = 'published' OR status = 'active' OR is_published IS TRUE)
WHERE is_published IS NULL;

-- ------------------------------------------------------------
-- 2. Update School Year Check Constraint
-- Allows 20XX-20XX (e.g., 2026-2027) while maintaining backward-compatibility
-- with legacy records formatted as 'S.Y. 20XX-20XX'.
-- ------------------------------------------------------------
ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_school_year_check;
ALTER TABLE public.users ADD CONSTRAINT users_school_year_check
  CHECK (school_year IS NULL OR school_year ~ '^(S\.Y\. )?20[0-9]{2}-20[0-9]{2}$');

-- ------------------------------------------------------------
-- 3. Resilient handle_new_user() Trigger Function
-- Gracefully inserts user profile without aborting auth signup transaction
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_first_name text := NULLIF(NEW.raw_user_meta_data ->> 'first_name', '');
  v_last_name text := NULLIF(NEW.raw_user_meta_data ->> 'last_name', '');
  v_full_name text := NULLIF(NEW.raw_user_meta_data ->> 'full_name', '');
  v_role text := COALESCE(NULLIF(NEW.raw_user_meta_data ->> 'role', ''), 'student');
  v_lrn text := NULLIF(NEW.raw_user_meta_data ->> 'lrn', '');
  v_school_year text := NULLIF(NEW.raw_user_meta_data ->> 'school_year', '');
  v_gender text := NULLIF(NEW.raw_user_meta_data ->> 'gender', '');
  v_grade_level_id uuid := NULL;
  v_section_id uuid := NULL;
BEGIN
  -- Validate and verify UUID foreign keys exist before setting
  IF (NEW.raw_user_meta_data ->> 'grade_level_id') ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' THEN
    SELECT id INTO v_grade_level_id FROM public.grade_levels WHERE id = (NEW.raw_user_meta_data ->> 'grade_level_id')::uuid;
  END IF;

  IF (NEW.raw_user_meta_data ->> 'section_id') ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' THEN
    SELECT id INTO v_section_id FROM public.sections WHERE id = (NEW.raw_user_meta_data ->> 'section_id')::uuid;
  END IF;

  INSERT INTO public.users (
    id, email, full_name, first_name, last_name, role,
    is_active, approval_status, grade_level_id, section_id,
    grade_level_text, section_text, lrn, school_year, gender,
    created_at, updated_at
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(v_full_name, concat_ws(' ', v_first_name, v_last_name), split_part(NEW.email, '@', 1)),
    v_first_name,
    v_last_name,
    v_role,
    CASE WHEN v_role = 'student' THEN false ELSE true END,
    CASE WHEN v_role = 'student' THEN 'pending' ELSE 'approved' END,
    v_grade_level_id,
    v_section_id,
    NULLIF(NEW.raw_user_meta_data ->> 'grade_level_text', ''),
    NULLIF(NEW.raw_user_meta_data ->> 'section_text', ''),
    v_lrn,
    v_school_year,
    v_gender,
    COALESCE(NEW.created_at, now()),
    now()
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    full_name = COALESCE(EXCLUDED.full_name, public.users.full_name),
    updated_at = now();

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Fallback: insert minimal profile row so Auth never 500s
  INSERT INTO public.users (id, email, full_name, role, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(split_part(NEW.email, '@', 1), 'User'),
    v_role,
    now(),
    now()
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

COMMIT;

-- ------------------------------------------------------------
-- 4. Storage Bucket & Policies (Outside transaction if required)
-- ------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public)
VALUES ('learning-materials', 'learning-materials', true)
ON CONFLICT (id) DO UPDATE SET public = true;

DROP POLICY IF EXISTS "learning_materials_upload" ON storage.objects;
CREATE POLICY "learning_materials_upload"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'learning-materials'
);

DROP POLICY IF EXISTS "learning_materials_public_read" ON storage.objects;
CREATE POLICY "learning_materials_public_read"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'learning-materials');
