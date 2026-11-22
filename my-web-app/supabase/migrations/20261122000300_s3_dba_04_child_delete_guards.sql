-- Extend soft-delete child checks to include profile links to employees.
-- Active children block soft deletion; archived children do not.
BEGIN;
SET LOCAL search_path = public, pg_temp;

DO $$
DECLARE
    missing_columns TEXT;
BEGIN
    WITH required_columns(table_name, column_name) AS (
        VALUES
            ('employee', 'empno'),
            ('employee', 'is_deleted'),
            ('department', 'deptcode'),
            ('department', 'is_deleted'),
            ('job', 'jobcode'),
            ('job', 'is_deleted'),
            ('jobhistory', 'empno'),
            ('jobhistory', 'deptcode'),
            ('jobhistory', 'jobcode'),
            ('jobhistory', 'is_deleted'),
            ('sales', 'empno'),
            ('sales', 'is_deleted'),
            ('profiles', 'empno')
    )
    SELECT string_agg(r.table_name || '.' || r.column_name, ', ' ORDER BY r.table_name, r.column_name)
      INTO missing_columns
      FROM required_columns AS r
      LEFT JOIN information_schema.columns AS c
        ON c.table_schema = 'public'
       AND c.table_name = r.table_name
       AND c.column_name = r.column_name
     WHERE c.column_name IS NULL;

    IF missing_columns IS NOT NULL THEN
        RAISE EXCEPTION
            'S3-DBA-04 stopped: required child-check columns are missing: %',
            missing_columns;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.trg_check_children()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = pg_catalog, public
AS $$
DECLARE
    related_count BIGINT := 0;
    linked_profile_count BIGINT := 0;
BEGIN
    IF NOT (NEW.is_deleted AND NOT OLD.is_deleted) THEN
        RETURN NEW;
    END IF;

    CASE TG_TABLE_NAME
        WHEN 'employee' THEN
            SELECT count(*)
              INTO related_count
              FROM public.jobhistory
             WHERE empno = OLD.empno
               AND NOT is_deleted;

            SELECT related_count + count(*)
              INTO related_count
              FROM public.sales
             WHERE empno = OLD.empno
               AND NOT is_deleted;

            SELECT count(*)
              INTO linked_profile_count
              FROM public.profiles
             WHERE empno = OLD.empno;

            IF linked_profile_count > 0 THEN
                RAISE EXCEPTION
                    'Cannot delete employee %: % linked user profile(s) must be unlinked first.',
                    OLD.empno,
                    linked_profile_count;
            END IF;
        WHEN 'department' THEN
            SELECT count(*)
              INTO related_count
              FROM public.jobhistory
             WHERE deptcode = OLD.deptcode
               AND NOT is_deleted;
        WHEN 'job' THEN
            SELECT count(*)
              INTO related_count
              FROM public.jobhistory
             WHERE jobcode = OLD.jobcode
               AND NOT is_deleted;
        WHEN 'customer' THEN
            SELECT count(*)
              INTO related_count
              FROM public.sales
             WHERE custno = OLD.custno
               AND NOT is_deleted;
        WHEN 'sales' THEN
            SELECT count(*)
              INTO related_count
              FROM (
                  SELECT 1
                    FROM public.salesdetail
                   WHERE transno = OLD.transno
                     AND NOT is_deleted
                  UNION ALL
                  SELECT 1
                    FROM public.payment
                   WHERE transno = OLD.transno
                     AND NOT is_deleted
              ) AS active_children;
        WHEN 'product' THEN
            SELECT count(*)
              INTO related_count
              FROM (
                  SELECT 1
                    FROM public.salesdetail
                   WHERE prodcode = OLD.prodcode
                     AND NOT is_deleted
                  UNION ALL
                  SELECT 1
                    FROM public.pricehist
                   WHERE prodcode = OLD.prodcode
                     AND NOT is_deleted
              ) AS active_children;
        ELSE
            RETURN NEW;
    END CASE;

    IF related_count > 0 THEN
        RAISE EXCEPTION
            'Cannot delete % row: % active related record(s) still exist.',
            TG_TABLE_NAME,
            related_count;
    END IF;

    RETURN NEW;
END;
$$;

DO $$
DECLARE
    parent_table TEXT;
    trigger_name TEXT;
    trigger_function OID;
BEGIN
    FOREACH parent_table IN ARRAY ARRAY['employee', 'department', 'job']
    LOOP
        trigger_name := parent_table || '_bu_check';

        SELECT t.tgfoid
          INTO trigger_function
          FROM pg_trigger AS t
          JOIN pg_class AS c ON c.oid = t.tgrelid
          JOIN pg_namespace AS n ON n.oid = c.relnamespace
         WHERE n.nspname = 'public'
           AND c.relname = parent_table
           AND t.tgname = trigger_name
           AND NOT t.tgisinternal;

        IF trigger_function IS NULL THEN
            EXECUTE format(
                'CREATE TRIGGER %I BEFORE UPDATE ON public.%I FOR EACH ROW EXECUTE FUNCTION public.trg_check_children()',
                trigger_name,
                parent_table
            );
        ELSIF trigger_function <> 'public.trg_check_children()'::regprocedure::OID THEN
            RAISE EXCEPTION
                'S3-DBA-04 stopped: trigger public.% on public.% uses a different function.',
                trigger_name,
                parent_table;
        END IF;
    END LOOP;
END;
$$;

COMMIT;
