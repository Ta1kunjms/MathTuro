-- Phase 1: accounts and security foundation
-- Apply only after reviewing the confirmed live schema and taking a backup.
-- This migration does not create Auth users. Full admin account creation remains
-- a server-side Edge Function responsibility.

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS first_name varchar(100),
  ADD COLUMN IF NOT EXISTS last_name varchar(100),
  ADD COLUMN IF NOT EXISTS lrn varchar(12),
  ADD COLUMN IF NOT EXISTS school_year varchar(13),
  ADD COLUMN IF NOT EXISTS gender varchar(10),
  ADD COLUMN IF NOT EXISTS approval_status varchar(20),
  ADD COLUMN IF NOT EXISTS approved_at timestamptz,
  ADD COLUMN IF NOT EXISTS approved_by uuid,
  ADD COLUMN IF NOT EXISTS rejection_reason text;

UPDATE public.users
SET first_name = COALESCE(NULLIF(first_name, ''), split_part(trim(full_name), ' ', 1)),
    last_name = COALESCE(NULLIF(last_name, ''), NULLIF(regexp_replace(trim(full_name), '^\S+\s*', ''), '')),
    approval_status = COALESCE(approval_status, CASE WHEN is_active THEN 'approved' ELSE 'pending' END),
    updated_at = now()
WHERE first_name IS NULL
   OR last_name IS NULL
   OR approval_status IS NULL;

ALTER TABLE public.users
  ALTER COLUMN approval_status SET DEFAULT 'pending';

ALTER TABLE public.users
  DROP CONSTRAINT IF EXISTS users_gender_check,
  ADD CONSTRAINT users_gender_check
    CHECK (gender IS NULL OR gender IN ('Male', 'Female')),
  DROP CONSTRAINT IF EXISTS users_school_year_check,
  ADD CONSTRAINT users_school_year_check
    CHECK (school_year IS NULL OR school_year ~ '^S\.Y\. 20[0-9]{2}-20[0-9]{2}$'),
  DROP CONSTRAINT IF EXISTS users_approval_status_check,
  ADD CONSTRAINT users_approval_status_check
    CHECK (approval_status IN ('pending', 'approved', 'rejected'));

CREATE UNIQUE INDEX IF NOT EXISTS users_lrn_unique_student_idx
  ON public.users (lrn)
  WHERE role = 'student' AND lrn IS NOT NULL;

CREATE INDEX IF NOT EXISTS users_approval_status_idx
  ON public.users (approval_status, role, created_at DESC);

CREATE OR REPLACE FUNCTION public.is_current_user_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.users
    WHERE id = auth.uid()
      AND role = 'admin'
      AND is_active = true
      AND approval_status = 'approved'
  );
$$;

REVOKE ALL ON FUNCTION public.is_current_user_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_current_user_admin() TO authenticated;

CREATE OR REPLACE FUNCTION public.is_current_user_teacher_or_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.users
    WHERE id = auth.uid()
      AND role IN ('teacher', 'admin')
      AND is_active = true
      AND approval_status = 'approved'
  );
$$;

REVOKE ALL ON FUNCTION public.is_current_user_teacher_or_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_current_user_teacher_or_admin() TO authenticated;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  metadata_first_name text := NULLIF(NEW.raw_user_meta_data ->> 'first_name', '');
  metadata_last_name text := NULLIF(NEW.raw_user_meta_data ->> 'last_name', '');
  metadata_full_name text := NULLIF(NEW.raw_user_meta_data ->> 'full_name', '');
  metadata_lrn text := NULLIF(NEW.raw_user_meta_data ->> 'lrn', '');
  metadata_school_year text := NULLIF(NEW.raw_user_meta_data ->> 'school_year', '');
  metadata_gender text := NULLIF(NEW.raw_user_meta_data ->> 'gender', '');
BEGIN
  IF metadata_lrn IS NULL OR metadata_lrn !~ '^\d{12}$' THEN
    RAISE EXCEPTION 'A valid 12-digit LRN is required';
  END IF;
  IF metadata_school_year IS NULL OR metadata_school_year !~ '^S\.Y\. 20[0-9]{2}-20[0-9]{2}$' THEN
    RAISE EXCEPTION 'A valid school year is required';
  END IF;
  IF metadata_gender IS NULL OR metadata_gender NOT IN ('Male', 'Female') THEN
    RAISE EXCEPTION 'A valid gender is required';
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
    COALESCE(metadata_full_name, concat_ws(' ', metadata_first_name, metadata_last_name), split_part(NEW.email, '@', 1)),
    metadata_first_name,
    metadata_last_name,
    'student',
    false,
    'pending',
    CASE WHEN NEW.raw_user_meta_data ->> 'grade_level_id' ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
      THEN (NEW.raw_user_meta_data ->> 'grade_level_id')::uuid END,
    CASE WHEN NEW.raw_user_meta_data ->> 'section_id' ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
      THEN (NEW.raw_user_meta_data ->> 'section_id')::uuid END,
    NULLIF(NEW.raw_user_meta_data ->> 'grade_level_text', ''),
    NULLIF(NEW.raw_user_meta_data ->> 'section_text', ''),
    metadata_lrn,
    metadata_school_year,
    metadata_gender,
    COALESCE(NEW.created_at, now()),
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

CREATE OR REPLACE FUNCTION public.prevent_protected_user_changes()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND NOT public.is_current_user_admin() THEN
    IF NEW.role IS DISTINCT FROM OLD.role
       OR NEW.is_active IS DISTINCT FROM OLD.is_active
       OR NEW.approval_status IS DISTINCT FROM OLD.approval_status
       OR NEW.lrn IS DISTINCT FROM OLD.lrn
       OR NEW.school_year IS DISTINCT FROM OLD.school_year
       OR NEW.email IS DISTINCT FROM OLD.email
      OR NEW.full_name IS DISTINCT FROM OLD.full_name
       OR NEW.first_name IS DISTINCT FROM OLD.first_name
       OR NEW.last_name IS DISTINCT FROM OLD.last_name
       OR NEW.grade_level_id IS DISTINCT FROM OLD.grade_level_id
       OR NEW.section_id IS DISTINCT FROM OLD.section_id
      OR NEW.grade_level_text IS DISTINCT FROM OLD.grade_level_text
      OR NEW.section_text IS DISTINCT FROM OLD.section_text
       OR NEW.gender IS DISTINCT FROM OLD.gender THEN
      RAISE EXCEPTION 'Protected account fields may only be changed by an administrator';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS protect_user_profile_fields ON public.users;
CREATE TRIGGER protect_user_profile_fields
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.prevent_protected_user_changes();

DROP POLICY IF EXISTS admin_manage_all_users ON public.users;
DROP POLICY IF EXISTS users_read_own_profile ON public.users;
DROP POLICY IF EXISTS users_insert_own_profile ON public.users;
DROP POLICY IF EXISTS users_update_own_profile ON public.users;
DROP POLICY IF EXISTS teachers_view_all_students ON public.users;

CREATE POLICY users_read_own_profile ON public.users
  FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY users_insert_own_profile ON public.users
  FOR INSERT
  WITH CHECK (
    auth.uid() = id
    AND role = 'student'
    AND approval_status = 'pending'
    AND is_active = false
  );

CREATE POLICY users_update_own_profile ON public.users
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY teachers_view_all_students ON public.users
  FOR SELECT
  USING (role = 'student' AND public.is_current_user_teacher_or_admin());

CREATE POLICY admin_manage_all_users ON public.users
  FOR ALL
  USING (public.is_current_user_admin())
  WITH CHECK (public.is_current_user_admin());

DROP POLICY IF EXISTS admin_manage_sections ON public.sections;
CREATE POLICY admin_manage_sections ON public.sections
  FOR ALL
  USING (public.is_current_user_admin())
  WITH CHECK (public.is_current_user_admin());

DROP POLICY IF EXISTS admin_manage_grade_levels ON public.grade_levels;
CREATE POLICY admin_manage_grade_levels ON public.grade_levels
  FOR ALL
  USING (public.is_current_user_admin())
  WITH CHECK (public.is_current_user_admin());

CREATE OR REPLACE FUNCTION public.approve_student_account(target_user_id uuid)
RETURNS public.users
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  approved_user public.users;
BEGIN
  IF NOT public.is_current_user_admin() THEN
    RAISE EXCEPTION 'Only active administrators may approve accounts';
  END IF;

  UPDATE public.users
  SET approval_status = 'approved',
      is_active = true,
      approved_at = now(),
      approved_by = auth.uid(),
      rejection_reason = NULL,
      updated_at = now()
  WHERE id = target_user_id
    AND role = 'student'
    AND approval_status = 'pending'
  RETURNING * INTO approved_user;

  IF approved_user.id IS NULL THEN
    RAISE EXCEPTION 'Pending student account not found';
  END IF;

  INSERT INTO public.activity_log (user_id, action, entity_type, entity_id, details)
  VALUES (auth.uid(), 'approve_account', 'user', target_user_id, jsonb_build_object('role', 'student'));

  RETURN approved_user;
END;
$$;

CREATE OR REPLACE FUNCTION public.reject_student_account(target_user_id uuid, reason text)
RETURNS public.users
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  rejected_user public.users;
BEGIN
  IF NOT public.is_current_user_admin() THEN
    RAISE EXCEPTION 'Only active administrators may reject accounts';
  END IF;
  IF NULLIF(trim(reason), '') IS NULL THEN
    RAISE EXCEPTION 'A rejection reason is required';
  END IF;

  UPDATE public.users
  SET approval_status = 'rejected',
      is_active = false,
      rejection_reason = trim(reason),
      updated_at = now()
  WHERE id = target_user_id
    AND role = 'student'
    AND approval_status = 'pending'
  RETURNING * INTO rejected_user;

  IF rejected_user.id IS NULL THEN
    RAISE EXCEPTION 'Pending student account not found';
  END IF;

  INSERT INTO public.activity_log (user_id, action, entity_type, entity_id, details)
  VALUES (auth.uid(), 'reject_account', 'user', target_user_id, jsonb_build_object('role', 'student', 'reason', trim(reason)));

  RETURN rejected_user;
END;
$$;

CREATE OR REPLACE FUNCTION public.bulk_approve_student_accounts(target_user_ids uuid[])
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE affected_count integer;
BEGIN
  IF NOT public.is_current_user_admin() THEN
    RAISE EXCEPTION 'Only active administrators may approve accounts';
  END IF;

  UPDATE public.users
  SET approval_status = 'approved', is_active = true,
      approved_at = now(), approved_by = auth.uid(),
      rejection_reason = NULL, updated_at = now()
  WHERE id = ANY(target_user_ids)
    AND role = 'student'
    AND approval_status = 'pending';
  GET DIAGNOSTICS affected_count = ROW_COUNT;

  INSERT INTO public.activity_log (user_id, action, entity_type, details)
  VALUES (auth.uid(), 'bulk_approve_accounts', 'user', jsonb_build_object('count', affected_count));

  RETURN affected_count;
END;
$$;

CREATE OR REPLACE FUNCTION public.bulk_reject_student_accounts(target_user_ids uuid[], reason text)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE affected_count integer;
BEGIN
  IF NOT public.is_current_user_admin() THEN
    RAISE EXCEPTION 'Only active administrators may reject accounts';
  END IF;
  IF NULLIF(trim(reason), '') IS NULL THEN
    RAISE EXCEPTION 'A rejection reason is required';
  END IF;

  UPDATE public.users
  SET approval_status = 'rejected', is_active = false,
      rejection_reason = trim(reason), updated_at = now()
  WHERE id = ANY(target_user_ids)
    AND role = 'student'
    AND approval_status = 'pending';
  GET DIAGNOSTICS affected_count = ROW_COUNT;

  INSERT INTO public.activity_log (user_id, action, entity_type, details)
  VALUES (auth.uid(), 'bulk_reject_accounts', 'user', jsonb_build_object('count', affected_count, 'reason', trim(reason)));

  RETURN affected_count;
END;
$$;

-- This links an already-created Auth user to an approved profile. Creating the
-- Auth user itself must happen in a trusted Edge Function using the service role.
CREATE OR REPLACE FUNCTION public.provision_user_profile(
  target_user_id uuid,
  target_email text,
  target_first_name text,
  target_last_name text,
  target_role text,
  target_lrn text DEFAULT NULL,
  target_school_year text DEFAULT NULL,
  target_gender text DEFAULT NULL,
  target_grade_level_id uuid DEFAULT NULL,
  target_section_id uuid DEFAULT NULL
)
RETURNS public.users
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE provisioned_user public.users;
BEGIN
  IF NOT public.is_current_user_admin() THEN
    RAISE EXCEPTION 'Only active administrators may provision accounts';
  END IF;
  IF target_role NOT IN ('student', 'teacher') THEN
    RAISE EXCEPTION 'Only student and teacher accounts may be provisioned';
  END IF;

  INSERT INTO public.users (
    id, email, first_name, last_name, full_name, role, lrn,
    school_year, gender, grade_level_id, section_id,
    approval_status, is_active, approved_at, approved_by, updated_at
  )
  VALUES (
    target_user_id, target_email, target_first_name, target_last_name,
    concat_ws(' ', target_first_name, target_last_name), target_role, target_lrn,
    target_school_year, target_gender, target_grade_level_id, target_section_id,
    'approved', true, now(), auth.uid(), now()
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    full_name = EXCLUDED.full_name,
    role = EXCLUDED.role,
    lrn = EXCLUDED.lrn,
    school_year = EXCLUDED.school_year,
    gender = EXCLUDED.gender,
    grade_level_id = EXCLUDED.grade_level_id,
    section_id = EXCLUDED.section_id,
    approval_status = 'approved',
    is_active = true,
    approved_at = now(),
    approved_by = auth.uid(),
    updated_at = now()
  RETURNING * INTO provisioned_user;

  RETURN provisioned_user;
END;
$$;

GRANT EXECUTE ON FUNCTION public.approve_student_account(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.reject_student_account(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.bulk_approve_student_accounts(uuid[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.bulk_reject_student_accounts(uuid[], text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.provision_user_profile(uuid, text, text, text, text, text, text, text, uuid, uuid) TO authenticated;
