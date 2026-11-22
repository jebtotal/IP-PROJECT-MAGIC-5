-- Index the selective inactive-row filters used by administrator list tabs.
BEGIN;
SET LOCAL search_path = public, pg_temp;

DO $$
DECLARE
    target_table TEXT;
    target_column TEXT;
    target_index TEXT;
    target_relation REGCLASS;
    target_attnum SMALLINT;
    has_equivalent_index BOOLEAN;
    existing_indexes TEXT;
BEGIN
    IF to_regclass('public.customer') IS NULL
       OR to_regclass('public.product') IS NULL THEN
        RAISE EXCEPTION
            'S2-DBA-06 stopped: public.customer and public.product must exist before adding list indexes.';
    END IF;

    WITH required_columns(table_name, column_name, data_type) AS (
        VALUES
            ('customer', 'custno', 'character varying'),
            ('customer', 'is_deleted', 'boolean'),
            ('product', 'prodcode', 'character varying'),
            ('product', 'is_deleted', 'boolean')
    )
    SELECT string_agg(
               required.table_name || '.' || required.column_name,
               ', ' ORDER BY required.table_name, required.column_name
           )
      INTO existing_indexes
      FROM required_columns AS required
      LEFT JOIN information_schema.columns AS actual
        ON actual.table_schema = 'public'
       AND actual.table_name = required.table_name
       AND actual.column_name = required.column_name
       AND actual.data_type = required.data_type
     WHERE actual.column_name IS NULL;

    IF existing_indexes IS NOT NULL THEN
        RAISE EXCEPTION
            'S2-DBA-06 stopped: required Customer/Product columns are missing or have unexpected types: %.',
            existing_indexes;
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
       AND table_class.relname IN ('customer', 'product');

    RAISE NOTICE 'S2-DBA-06 Customer/Product indexes before migration:% ',
        COALESCE(E'\n' || existing_indexes, ' none');

    FOR target_table, target_column, target_index IN
        SELECT 'customer', 'custno', 'customer_inactive_list_idx'
        UNION ALL
        SELECT 'product', 'prodcode', 'product_inactive_list_idx'
    LOOP
        target_relation := format('public.%I', target_table)::REGCLASS;

        SELECT attribute.attnum
          INTO target_attnum
          FROM pg_attribute AS attribute
         WHERE attribute.attrelid = target_relation
           AND attribute.attname = target_column
           AND NOT attribute.attisdropped;

        IF target_attnum IS NULL THEN
            RAISE EXCEPTION
                'S2-DBA-06 stopped: expected column %.% is missing.',
                target_table,
                target_column;
        END IF;

        SELECT EXISTS (
            SELECT 1
              FROM pg_index AS index_row
              JOIN pg_class AS index_class ON index_class.oid = index_row.indexrelid
              JOIN pg_am AS access_method ON access_method.oid = index_class.relam
             WHERE index_row.indrelid = target_relation
               AND index_row.indisvalid
               AND index_row.indisready
               AND access_method.amname = 'btree'
               AND index_row.indnkeyatts = 1
               AND index_row.indkey[0] = target_attnum
               AND pg_get_expr(index_row.indpred, index_row.indrelid) = 'is_deleted'
        )
          INTO has_equivalent_index;

        IF NOT has_equivalent_index THEN
            IF to_regclass(format('public.%I', target_index)) IS NOT NULL THEN
                RAISE EXCEPTION
                    'S2-DBA-06 stopped: index name % already exists but is not a valid btree index on %.% WHERE is_deleted. Review the conflicting index before retrying.',
                    target_index,
                    target_table,
                    target_column;
            END IF;

            EXECUTE format(
                'CREATE INDEX %I ON %s (%I) WHERE is_deleted',
                target_index,
                target_relation,
                target_column
            );
        END IF;
    END LOOP;

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
       AND table_class.relname IN ('customer', 'product');

    RAISE NOTICE 'S2-DBA-06 Customer/Product indexes after migration:% ',
        COALESCE(E'\n' || existing_indexes, ' none');
END;
$$;

COMMIT;
