-- Replace source-HOPE audit triggers with the application audit-log contract.
-- The source trigger writes table_name/action/record_key/action_by, which are
-- not columns in the existing application's audit_log.
BEGIN;
SET LOCAL search_path = public, pg_temp;

DO $$
DECLARE
    missing_columns TEXT;
    r RECORD;
BEGIN
    IF to_regclass('public.audit_log') IS NULL
       OR to_regprocedure('public.hope_audit_record_change()') IS NULL THEN
        RAISE EXCEPTION
            'S1-DBA-10 stopped: public.audit_log and public.hope_audit_record_change() are required. Apply 20261109000000_hope_app_access.sql first.';
    END IF;

    WITH required_columns(table_name, column_name) AS (
        VALUES
            ('audit_log', 'actor_id'),
            ('audit_log', 'event_type'),
            ('audit_log', 'old_values'),
            ('audit_log', 'new_values'),
            ('employee', 'is_deleted'),
            ('employee', 'stamp'),
            ('department', 'is_deleted'),
            ('department', 'stamp'),
            ('job', 'is_deleted'),
            ('job', 'stamp'),
            ('jobhistory', 'is_deleted'),
            ('jobhistory', 'stamp'),
            ('customer', 'is_deleted'),
            ('customer', 'stamp'),
            ('sales', 'is_deleted'),
            ('sales', 'stamp'),
            ('salesdetail', 'is_deleted'),
            ('salesdetail', 'stamp'),
            ('payment', 'is_deleted'),
            ('payment', 'stamp'),
            ('product', 'is_deleted'),
            ('product', 'stamp'),
            ('pricehist', 'is_deleted'),
            ('pricehist', 'stamp')
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
            'S1-DBA-10 stopped: required audit or HOPE columns are missing: %.',
            missing_columns;
    END IF;

    FOR r IN
        SELECT table_name
          FROM (VALUES
              ('employee'),
              ('department'),
              ('job'),
              ('jobhistory'),
              ('customer'),
              ('sales'),
              ('salesdetail'),
              ('payment'),
              ('product'),
              ('pricehist')
          ) AS tables(table_name)
    LOOP
        EXECUTE format(
            'DROP TRIGGER IF EXISTS %I ON public.%I',
            r.table_name || '_aiu_audit',
            r.table_name
        );
        EXECUTE format(
            'DROP TRIGGER IF EXISTS hope_20_audit_change ON public.%I',
            r.table_name
        );
        EXECUTE format(
            'CREATE TRIGGER hope_20_audit_change AFTER INSERT OR UPDATE ON public.%I FOR EACH ROW EXECUTE FUNCTION public.hope_audit_record_change()',
            r.table_name
        );
    END LOOP;
END;
$$;

COMMIT;
