-- Read-only, paginated audit access for active Superadmins.
-- Supports both the source HOPE audit schema and the existing app audit schema.
BEGIN;
SET LOCAL search_path = public, pg_temp;

DO $$
DECLARE
    missing_columns TEXT;
BEGIN
    IF to_regclass('public.audit_log') IS NULL THEN
        RAISE EXCEPTION
            'S1-BLD-09 stopped: public.audit_log is required.';
    END IF;

    WITH required_columns(table_name, column_name) AS (
        VALUES
            ('profiles', 'id'),
            ('profiles', 'role'),
            ('profiles', 'status'),
            ('profiles', 'blocked'),
            ('profiles', 'email')
    )
    SELECT string_agg(
               required.table_name || '.' || required.column_name,
               ', ' ORDER BY required.table_name, required.column_name
           )
      INTO missing_columns
      FROM required_columns AS required
      LEFT JOIN information_schema.columns AS actual
        ON actual.table_schema = 'public'
       AND actual.table_name = required.table_name
       AND actual.column_name = required.column_name
     WHERE actual.column_name IS NULL;

    IF missing_columns IS NOT NULL THEN
        RAISE EXCEPTION
            'S1-BLD-09 stopped: required profile columns are missing: %.',
            missing_columns;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.hope_read_audit_log(
    p_search TEXT DEFAULT '',
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $$
DECLARE
    v_pattern TEXT;
    v_total BIGINT;
    v_rows JSONB;
BEGIN
    IF NOT EXISTS (
        SELECT 1
          FROM public.profiles AS profile
         WHERE profile.id = auth.uid()
           AND profile.role = 'superadmin'
           AND profile.status NOT IN ('blocked', 'rejected', 'pending')
           AND profile.blocked IS NOT TRUE
           AND COALESCE((to_jsonb(profile) ->> 'is_deleted')::BOOLEAN, FALSE) = FALSE
    ) THEN
        RAISE EXCEPTION 'Active Superadmin access is required.'
            USING ERRCODE = '42501';
    END IF;

    IF p_limit IS NULL OR p_limit < 1 OR p_limit > 100
       OR p_offset IS NULL OR p_offset < 0 OR p_offset > 1000000
       OR length(COALESCE(p_search, '')) > 200 THEN
        RAISE EXCEPTION 'Invalid audit-log pagination or search filters.'
            USING ERRCODE = '22023';
    END IF;

    v_pattern := '%' || btrim(COALESCE(p_search, '')) || '%';

    SELECT count(*)
      INTO v_total
      FROM public.audit_log AS entry
     WHERE btrim(COALESCE(p_search, '')) = ''
        OR concat_ws(
               ' ',
               to_jsonb(entry) ->> 'event_type',
               to_jsonb(entry) ->> 'table_name',
               to_jsonb(entry) ->> 'action',
               to_jsonb(entry) ->> 'record_key',
               to_jsonb(entry) ->> 'actor_id',
               to_jsonb(entry) ->> 'action_by',
               to_jsonb(entry) ->> 'old_values',
               to_jsonb(entry) ->> 'new_values'
           ) ILIKE v_pattern;

    SELECT COALESCE(
               jsonb_agg(page.audit_row ORDER BY page.row_number),
               '[]'::JSONB
           )
      INTO v_rows
      FROM (
          SELECT to_jsonb(entry) || jsonb_build_object(
                     'actor_email',
                     actor.email
                 ) AS audit_row,
                 row_number() OVER (
                     ORDER BY
                         COALESCE(
                             to_jsonb(entry) ->> 'created_at',
                             to_jsonb(entry) ->> 'action_at',
                             to_jsonb(entry) ->> 'timestamp',
                             to_jsonb(entry) ->> 'occurred_at'
                         ) DESC NULLS LAST,
                         COALESCE(
                             to_jsonb(entry) ->> 'audit_id',
                             to_jsonb(entry) ->> 'id',
                             to_jsonb(entry) ->> 'event_id'
                         ) DESC NULLS LAST
                 ) AS row_number
            FROM public.audit_log AS entry
            LEFT JOIN public.profiles AS actor
              ON actor.id::TEXT = (to_jsonb(entry) ->> 'actor_id')
           WHERE btrim(COALESCE(p_search, '')) = ''
              OR concat_ws(
                     ' ',
                     to_jsonb(entry) ->> 'event_type',
                     to_jsonb(entry) ->> 'table_name',
                     to_jsonb(entry) ->> 'action',
                     to_jsonb(entry) ->> 'record_key',
                     to_jsonb(entry) ->> 'actor_id',
                     to_jsonb(entry) ->> 'action_by',
                     to_jsonb(entry) ->> 'old_values',
                     to_jsonb(entry) ->> 'new_values'
                 ) ILIKE v_pattern
      ) AS page
     WHERE page.row_number > p_offset
       AND page.row_number <= p_offset + p_limit;

    RETURN jsonb_build_object(
        'rows', v_rows,
        'total', v_total
    );
END;
$$;

REVOKE ALL ON FUNCTION public.hope_read_audit_log(TEXT, INTEGER, INTEGER)
    FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.hope_read_audit_log(TEXT, INTEGER, INTEGER)
    TO authenticated;

COMMIT;
