-- Backfill users.grade/section fields from auth.users metadata
-- Run once in Supabase SQL Editor.

DO $$
DECLARE
    has_grade_level_id boolean;
    has_section_id boolean;
    has_grade_level_text boolean;
    has_section_text boolean;
    has_grade_level_legacy boolean;
    has_section_legacy boolean;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'grade_level_id'
    ) INTO has_grade_level_id;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'section_id'
    ) INTO has_section_id;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'grade_level_text'
    ) INTO has_grade_level_text;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'section_text'
    ) INTO has_section_text;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'grade_level'
    ) INTO has_grade_level_legacy;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'section'
    ) INTO has_section_legacy;

    IF has_grade_level_id THEN
        EXECUTE $sql$
            UPDATE public.users u
            SET grade_level_id = NULLIF((a.raw_user_meta_data->>'grade_level_id'), '')::uuid
            FROM auth.users a
            WHERE a.id = u.id
              AND u.grade_level_id IS NULL
              AND NULLIF((a.raw_user_meta_data->>'grade_level_id'), '') IS NOT NULL
        $sql$;
    END IF;

    IF has_section_id THEN
        EXECUTE $sql$
            UPDATE public.users u
            SET section_id = NULLIF((a.raw_user_meta_data->>'section_id'), '')::uuid
            FROM auth.users a
            WHERE a.id = u.id
              AND u.section_id IS NULL
              AND NULLIF((a.raw_user_meta_data->>'section_id'), '') IS NOT NULL
        $sql$;
    END IF;

    IF has_grade_level_text THEN
        EXECUTE $sql$
            UPDATE public.users u
            SET grade_level_text = COALESCE(
                NULLIF(a.raw_user_meta_data->>'grade_level_text', ''),
                NULLIF(a.raw_user_meta_data->>'grade_level', '')
            )
            FROM auth.users a
            WHERE a.id = u.id
              AND (u.grade_level_text IS NULL OR btrim(u.grade_level_text) = '')
              AND COALESCE(
                NULLIF(a.raw_user_meta_data->>'grade_level_text', ''),
                NULLIF(a.raw_user_meta_data->>'grade_level', '')
              ) IS NOT NULL
        $sql$;
    END IF;

    IF has_section_text THEN
        EXECUTE $sql$
            UPDATE public.users u
            SET section_text = COALESCE(
                NULLIF(a.raw_user_meta_data->>'section_text', ''),
                NULLIF(a.raw_user_meta_data->>'section', '')
            )
            FROM auth.users a
            WHERE a.id = u.id
              AND (u.section_text IS NULL OR btrim(u.section_text) = '')
              AND COALESCE(
                NULLIF(a.raw_user_meta_data->>'section_text', ''),
                NULLIF(a.raw_user_meta_data->>'section', '')
              ) IS NOT NULL
        $sql$;
    END IF;

    IF has_grade_level_legacy THEN
        EXECUTE $sql$
            UPDATE public.users u
            SET grade_level = COALESCE(
                NULLIF(a.raw_user_meta_data->>'grade_level', ''),
                NULLIF(a.raw_user_meta_data->>'grade_level_text', '')
            )
            FROM auth.users a
            WHERE a.id = u.id
              AND (u.grade_level IS NULL OR btrim(u.grade_level) = '')
              AND COALESCE(
                NULLIF(a.raw_user_meta_data->>'grade_level', ''),
                NULLIF(a.raw_user_meta_data->>'grade_level_text', '')
              ) IS NOT NULL
        $sql$;
    END IF;

    IF has_section_legacy THEN
        EXECUTE $sql$
            UPDATE public.users u
            SET section = COALESCE(
                NULLIF(a.raw_user_meta_data->>'section', ''),
                NULLIF(a.raw_user_meta_data->>'section_text', '')
            )
            FROM auth.users a
            WHERE a.id = u.id
              AND (u.section IS NULL OR btrim(u.section) = '')
              AND COALESCE(
                NULLIF(a.raw_user_meta_data->>'section', ''),
                NULLIF(a.raw_user_meta_data->>'section_text', '')
              ) IS NOT NULL
        $sql$;
    END IF;
END
$$;

-- Quick verification
SELECT
    u.id,
    u.email,
    u.role,
    COALESCE(
        to_jsonb(u)->>'grade_level_text',
        to_jsonb(u)->>'grade_level',
        'N/A'
    ) AS grade_level_display,
    COALESCE(
        to_jsonb(u)->>'section_text',
        to_jsonb(u)->>'section',
        'N/A'
    ) AS section_display
FROM public.users u
ORDER BY u.created_at DESC
LIMIT 20;
