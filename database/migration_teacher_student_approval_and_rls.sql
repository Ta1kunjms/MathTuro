-- ==============================================================================
-- Migration: Teacher Student Approval & RLS Alignment
-- Purpose:
--   1. Allow teachers to view pending students and approve/reject their registrations
--   2. Update approve_student_account, reject_student_account, bulk_approve_student_accounts
--      to allow active teachers as well as admins
--   3. Ensure anon has EXECUTE on helper functions for public registration
--   4. Allow postgres superuser in prevent_protected_user_changes
-- ==============================================================================

-- 1. Helper function execution grants for anon
GRANT EXECUTE ON FUNCTION public.is_current_user_admin() TO anon;
GRANT EXECUTE ON FUNCTION public.is_current_user_teacher_or_admin() TO anon;

-- 2. Update teachers_view_all_students policy so teachers can view pending students
DROP POLICY IF EXISTS teachers_view_all_students ON public.users;
CREATE POLICY teachers_view_all_students ON public.users
  FOR SELECT
  USING (
    role = 'student'
    AND public.is_current_user_teacher_or_admin()
  );

-- 3. Update approve_student_account to permit teachers
CREATE OR REPLACE FUNCTION public.approve_student_account(target_user_id uuid)
RETURNS public.users
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  approved_user public.users;
BEGIN
  IF NOT public.is_current_user_teacher_or_admin() THEN
    RAISE EXCEPTION 'Only active teachers and administrators may approve student accounts';
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
  VALUES (auth.uid(), 'approve_account', 'user', target_user_id, jsonb_build_object('role', 'student', 'approved_by_role', CASE WHEN public.is_current_user_admin() THEN 'admin' ELSE 'teacher' END));

  RETURN approved_user;
END;
$$;

-- 4. Update reject_student_account to permit teachers
CREATE OR REPLACE FUNCTION public.reject_student_account(target_user_id uuid, reason text)
RETURNS public.users
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  rejected_user public.users;
BEGIN
  IF NOT public.is_current_user_teacher_or_admin() THEN
    RAISE EXCEPTION 'Only active teachers and administrators may reject student accounts';
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
  VALUES (auth.uid(), 'reject_account', 'user', target_user_id, jsonb_build_object('role', 'student', 'reason', trim(reason), 'rejected_by_role', CASE WHEN public.is_current_user_admin() THEN 'admin' ELSE 'teacher' END));

  RETURN rejected_user;
END;
$$;

-- 5. Update bulk_approve_student_accounts to permit teachers
CREATE OR REPLACE FUNCTION public.bulk_approve_student_accounts(target_user_ids uuid[])
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE affected_count integer;
BEGIN
  IF NOT public.is_current_user_teacher_or_admin() THEN
    RAISE EXCEPTION 'Only active teachers and administrators may approve student accounts';
  END IF;

  UPDATE public.users
  SET approval_status = 'approved',
      is_active = true,
      approved_at = now(),
      approved_by = auth.uid(),
      rejection_reason = NULL,
      updated_at = now()
  WHERE id = ANY(target_user_ids)
    AND role = 'student'
    AND approval_status = 'pending';

  GET DIAGNOSTICS affected_count = ROW_COUNT;

  INSERT INTO public.activity_log (user_id, action, entity_type, details)
  VALUES (auth.uid(), 'bulk_approve_accounts', 'user', jsonb_build_object('count', affected_count, 'approved_by_role', CASE WHEN public.is_current_user_admin() THEN 'admin' ELSE 'teacher' END));

  RETURN affected_count;
END;
$$;

GRANT EXECUTE ON FUNCTION public.approve_student_account(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.reject_student_account(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.bulk_approve_student_accounts(uuid[]) TO authenticated;

-- 6. Update prevent_protected_user_changes to permit teachers to approve students & allow postgres superuser
CREATE OR REPLACE FUNCTION public.prevent_protected_user_changes()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Allow postgres superuser (SQL Editor) and admin
  IF current_user = 'postgres' OR public.is_current_user_admin() THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' THEN
    -- If an active teacher is updating a student's approval status
    IF public.is_current_user_teacher_or_admin() AND OLD.role = 'student' AND NEW.role = 'student' THEN
      -- Teachers may only change approval_status, is_active, approved_at, approved_by, rejection_reason
      IF NEW.email IS DISTINCT FROM OLD.email
         OR NEW.lrn IS DISTINCT FROM OLD.lrn
         OR NEW.school_year IS DISTINCT FROM OLD.school_year
         OR NEW.gender IS DISTINCT FROM OLD.gender
         OR NEW.first_name IS DISTINCT FROM OLD.first_name
         OR NEW.last_name IS DISTINCT FROM OLD.last_name
         OR NEW.full_name IS DISTINCT FROM OLD.full_name
         OR NEW.grade_level_id IS DISTINCT FROM OLD.grade_level_id
         OR NEW.section_id IS DISTINCT FROM OLD.section_id
         OR NEW.grade_level_text IS DISTINCT FROM OLD.grade_level_text
         OR NEW.section_text IS DISTINCT FROM OLD.section_text THEN
        RAISE EXCEPTION 'Teachers may only update student approval status, not demographic fields';
      END IF;
      RETURN NEW;
    END IF;

    -- For all other users/fields, block modification of protected fields
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

