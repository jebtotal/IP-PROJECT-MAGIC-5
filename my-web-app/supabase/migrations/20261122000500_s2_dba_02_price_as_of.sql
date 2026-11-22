-- Resolve a product's effective price as of a date.
BEGIN;
SET LOCAL search_path = public, pg_temp;

DO $$
DECLARE
    missing_columns TEXT;
    existing_indexes TEXT;
    has_product_date_index BOOLEAN;
BEGIN
    IF to_regclass('public.pricehist') IS NULL
       OR to_regclass('public.pricehist_active') IS NULL
       OR to_regclass('public.product_active') IS NULL THEN
        RAISE EXCEPTION
            'S2-DBA-02 stopped: pricehist, pricehist_active, and product_active are required. Apply the HOPE schema and app-access migrations first.';
    END IF;

    WITH required_columns(table_name, column_name, data_type) AS (
        VALUES
            ('pricehist', 'prodcode', 'character varying'),
            ('pricehist', 'effdate', 'date'),
            ('pricehist', 'unitprice', 'numeric'),
            ('pricehist', 'is_deleted', 'boolean'),
            ('product', 'prodcode', 'character varying'),
            ('product', 'description', 'character varying'),
            ('product', 'unit', 'character varying'),
            ('product', 'is_deleted', 'boolean')
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
            'S2-DBA-02 stopped: expected price-history/product columns are missing or have unexpected types: %.',
            missing_columns;
    END IF;

    SELECT string_agg(
               format('%I: %s', index_class.relname, pg_get_indexdef(index_class.oid)),
               E'\n' ORDER BY index_class.relname
           )
      INTO existing_indexes
      FROM pg_index AS index_row
      JOIN pg_class AS index_class ON index_class.oid = index_row.indexrelid
     WHERE index_row.indrelid = 'public.pricehist'::regclass;

    RAISE NOTICE 'S2-DBA-02 pricehist indexes before migration:% ',
        COALESCE(E'\n' || existing_indexes, ' none');

    SELECT EXISTS (
        SELECT 1
          FROM pg_index AS index_row
          JOIN pg_class AS index_class ON index_class.oid = index_row.indexrelid
          JOIN pg_am AS access_method ON access_method.oid = index_class.relam
         WHERE index_row.indrelid = 'public.pricehist'::regclass
           AND index_row.indisvalid
           AND index_row.indisready
           AND access_method.amname = 'btree'
           AND index_row.indnkeyatts >= 2
           AND index_row.indkey[0] = (
               SELECT attribute.attnum
                 FROM pg_attribute AS attribute
                WHERE attribute.attrelid = 'public.pricehist'::regclass
                  AND attribute.attname = 'prodcode'
           )
           AND index_row.indkey[1] = (
               SELECT attribute.attnum
                 FROM pg_attribute AS attribute
                WHERE attribute.attrelid = 'public.pricehist'::regclass
                  AND attribute.attname = 'effdate'
           )
    )
      INTO has_product_date_index;

    IF NOT has_product_date_index THEN
        IF to_regclass('public.pricehist_prodcode_effdate_idx') IS NOT NULL THEN
            RAISE EXCEPTION
                'S2-DBA-02 stopped: public.pricehist_prodcode_effdate_idx exists but is not a valid btree index beginning with (prodcode, effdate). Review the conflicting index before retrying.';
        END IF;

        CREATE INDEX pricehist_prodcode_effdate_idx
            ON public.pricehist (prodcode, effdate DESC);
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.price_as_of(
    p_prodcode VARCHAR,
    p_as_of_date DATE
)
RETURNS NUMERIC(10, 2)
LANGUAGE SQL
STABLE
SECURITY INVOKER
SET search_path = pg_catalog, public
AS $$
    SELECT history.unitprice
      FROM public.pricehist_active AS history
     WHERE history.prodcode = p_prodcode
       AND history.effdate <= p_as_of_date
     ORDER BY history.effdate DESC
     LIMIT 1
$$;

REVOKE ALL ON FUNCTION public.price_as_of(VARCHAR, DATE) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.price_as_of(VARCHAR, DATE) TO authenticated;

CREATE OR REPLACE VIEW public.v_product_current_price
WITH (security_invoker = true)
AS
SELECT
    product.prodcode,
    product.description,
    product.unit,
    public.price_as_of(product.prodcode, CURRENT_DATE) AS unitprice
FROM public.product_active AS product;

GRANT SELECT ON public.v_product_current_price TO authenticated;

DO $$
DECLARE
    resulting_indexes TEXT;
BEGIN
    SELECT string_agg(
               format('%I: %s', index_class.relname, pg_get_indexdef(index_class.oid)),
               E'\n' ORDER BY index_class.relname
           )
      INTO resulting_indexes
      FROM pg_index AS index_row
      JOIN pg_class AS index_class ON index_class.oid = index_row.indexrelid
     WHERE index_row.indrelid = 'public.pricehist'::regclass;

    RAISE NOTICE 'S2-DBA-02 pricehist indexes after migration:% ',
        COALESCE(E'\n' || resulting_indexes, ' none');
END;
$$;

COMMIT;
