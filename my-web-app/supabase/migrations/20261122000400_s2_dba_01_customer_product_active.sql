-- Reassert the active-only Customer/Product views consumed by the application.
-- No additional indexes are added: current list searches run in the app.
BEGIN;
SET LOCAL search_path = public, pg_temp;

DO $$
DECLARE
    missing_columns TEXT;
    existing_indexes TEXT;
BEGIN
    WITH required_columns(table_name, column_name, data_type) AS (
        VALUES
            ('customer', 'custno', 'character varying'),
            ('customer', 'custname', 'character varying'),
            ('customer', 'address', 'character varying'),
            ('customer', 'payterm', 'character varying'),
            ('customer', 'is_deleted', 'boolean'),
            ('customer', 'stamp', 'character varying'),
            ('product', 'prodcode', 'character varying'),
            ('product', 'description', 'character varying'),
            ('product', 'unit', 'character varying'),
            ('product', 'is_deleted', 'boolean'),
            ('product', 'stamp', 'character varying')
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
       AND actual.data_type = required.data_type
     WHERE actual.column_name IS NULL;

    IF missing_columns IS NOT NULL THEN
        RAISE EXCEPTION
            'S2-DBA-01 stopped: expected Customer/Product columns are missing or have unexpected types: %.',
            missing_columns;
    END IF;

    SELECT string_agg(
               format('%I: %s', index_class.relname, pg_get_indexdef(index_class.oid)),
               E'\n' ORDER BY table_class.relname, index_class.relname
           )
      INTO existing_indexes
      FROM pg_index AS index_row
      JOIN pg_class AS index_class ON index_class.oid = index_row.indexrelid
      JOIN pg_class AS table_class ON table_class.oid = index_row.indrelid
      JOIN pg_namespace AS table_namespace ON table_namespace.oid = table_class.relnamespace
     WHERE table_namespace.nspname = 'public'
       AND table_class.relname IN ('customer', 'product', 'sales', 'salesdetail', 'pricehist');

    RAISE NOTICE 'S2-DBA-01 indexes before migration (Customer/Product and related FK tables):% ',
        COALESCE(E'\n' || existing_indexes, ' none');
END;
$$;

CREATE OR REPLACE VIEW public.customer_active
WITH (security_invoker = true)
AS
SELECT *
  FROM public.customer
 WHERE NOT is_deleted;

CREATE OR REPLACE VIEW public.product_active
WITH (security_invoker = true)
AS
SELECT *
  FROM public.product
 WHERE NOT is_deleted;

GRANT SELECT ON public.customer_active, public.product_active TO authenticated;

DO $$
DECLARE
    resulting_indexes TEXT;
BEGIN
    SELECT string_agg(
               format('%I: %s', index_class.relname, pg_get_indexdef(index_class.oid)),
               E'\n' ORDER BY table_class.relname, index_class.relname
           )
      INTO resulting_indexes
      FROM pg_index AS index_row
      JOIN pg_class AS index_class ON index_class.oid = index_row.indexrelid
      JOIN pg_class AS table_class ON table_class.oid = index_row.indrelid
      JOIN pg_namespace AS table_namespace ON table_namespace.oid = table_class.relnamespace
     WHERE table_namespace.nspname = 'public'
       AND table_class.relname IN ('customer', 'product', 'sales', 'salesdetail', 'pricehist');

    RAISE NOTICE 'S2-DBA-01 indexes after migration (no indexes added):% ',
        COALESCE(E'\n' || resulting_indexes, ' none');
END;
$$;

COMMIT;
