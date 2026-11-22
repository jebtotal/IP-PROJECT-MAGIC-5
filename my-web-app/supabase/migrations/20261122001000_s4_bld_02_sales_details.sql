-- Add permission-checked Sales Detail read and line-item mutations.
BEGIN;
SET LOCAL search_path = public, pg_temp;

DO $$
DECLARE
    missing_columns TEXT;
BEGIN
    IF to_regprocedure('public.hope_can_access(text,text,text)') IS NULL
       OR to_regprocedure('public.price_as_of(character varying,date)') IS NULL THEN
        RAISE EXCEPTION
            'S4-BLD-02 stopped: apply HOPE app access and the price_as_of migration first.';
    END IF;

    WITH required_columns(table_name, column_name) AS (
        VALUES
            ('sales', 'transno'),
            ('sales', 'salesdate'),
            ('sales', 'is_deleted'),
            ('salesdetail', 'transno'),
            ('salesdetail', 'prodcode'),
            ('salesdetail', 'quantity'),
            ('salesdetail', 'is_deleted'),
            ('product', 'prodcode'),
            ('product', 'description'),
            ('product', 'unit'),
            ('product', 'is_deleted')
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
            'S4-BLD-02 stopped: required Sales Detail columns are missing: %.',
            missing_columns;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.hope_sales_form_options()
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $$
BEGIN
    IF NOT public.hope_can_access('sales', 'sales', 'view') THEN
        RAISE EXCEPTION 'Sales View permission is required.'
            USING ERRCODE = '42501';
    END IF;

    RETURN jsonb_build_object(
        'customers',
        COALESCE(
            (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'customerNo', c.custno,
                        'customerName', c.custname
                    )
                    ORDER BY c.custno
                )
                  FROM public.customer AS c
                 WHERE NOT c.is_deleted
            ),
            '[]'::JSONB
        ),
        'salespeople',
        COALESCE(
            (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'employeeNo', e.empno,
                        'fullName',
                        COALESCE(
                            NULLIF(
                                concat_ws(
                                    ' ',
                                    NULLIF(btrim(e.firstname), ''),
                                    NULLIF(btrim(e.lastname), '')
                                ),
                                ''
                            ),
                            e.empno
                        )
                    )
                    ORDER BY e.lastname NULLS LAST, e.firstname NULLS LAST, e.empno
                )
                  FROM public.employee AS e
                 WHERE NOT e.is_deleted
                   AND (
                       e.sepdate IS NULL
                       OR e.sepdate >= (now() AT TIME ZONE 'Asia/Manila')::DATE
                   )
            ),
            '[]'::JSONB
        ),
        'saleDetailActions',
        jsonb_build_object(
            'view', public.hope_can_access('sales', 'sale_details', 'view'),
            'add', public.hope_can_access('sales', 'sale_details', 'create'),
            'edit', public.hope_can_access('sales', 'sale_details', 'edit'),
            'delete', public.hope_can_access('sales', 'sale_details', 'delete')
        )
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.hope_sales_details_data(p_transno TEXT)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $$
DECLARE
    v_salesdate DATE;
    v_details JSONB;
    v_products JSONB;
BEGIN
    IF NOT public.hope_can_access('sales', 'sales', 'view')
       OR NOT public.hope_can_access('sales', 'sale_details', 'view') THEN
        RAISE EXCEPTION 'Sales and Sales Detail View permissions are required.'
            USING ERRCODE = '42501';
    END IF;

    SELECT s.salesdate
      INTO v_salesdate
      FROM public.sales AS s
     WHERE s.transno = p_transno
       AND NOT s.is_deleted;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Active sale not found.'
            USING ERRCODE = 'P0002';
    END IF;
    IF v_salesdate IS NULL THEN
        RAISE EXCEPTION 'Sale date is required to calculate product prices.'
            USING ERRCODE = '22023';
    END IF;

    SELECT COALESCE(
               jsonb_agg(
                   jsonb_build_object(
                       'productCode', sd.prodcode,
                       'description', p.description,
                       'unit', p.unit,
                       'quantity', sd.quantity,
                       'unitPrice', public.price_as_of(sd.prodcode, v_salesdate),
                       'lineAmount',
                       (
                           sd.quantity * public.price_as_of(sd.prodcode, v_salesdate)
                       )::NUMERIC(10,2)
                   )
                   ORDER BY sd.prodcode
               ),
               '[]'::JSONB
           )
      INTO v_details
      FROM public.salesdetail AS sd
      LEFT JOIN public.product AS p ON p.prodcode = sd.prodcode
     WHERE sd.transno = p_transno
       AND NOT sd.is_deleted;

    SELECT COALESCE(
               jsonb_agg(
                   jsonb_build_object(
                       'productCode', p.prodcode,
                       'description', p.description,
                       'unit', p.unit,
                       'unitPrice', public.price_as_of(p.prodcode, v_salesdate)
                   )
                   ORDER BY p.description NULLS LAST, p.prodcode
               ),
               '[]'::JSONB
           )
      INTO v_products
      FROM public.product AS p
     WHERE NOT p.is_deleted
       AND public.price_as_of(p.prodcode, v_salesdate) IS NOT NULL;

    RETURN jsonb_build_object(
        'transactionNo', p_transno,
        'salesDate', v_salesdate,
        'details', v_details,
        'products', v_products,
        'actions', jsonb_build_object(
            'view', TRUE,
            'add', public.hope_can_access('sales', 'sale_details', 'create'),
            'edit', public.hope_can_access('sales', 'sale_details', 'edit'),
            'delete', public.hope_can_access('sales', 'sale_details', 'delete')
        )
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.hope_add_sale_detail(
    p_transno TEXT,
    p_product_code TEXT,
    p_quantity NUMERIC
)
RETURNS BOOLEAN
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $$
DECLARE
    v_salesdate DATE;
BEGIN
    IF NOT public.hope_can_access('sales', 'sales', 'view')
       OR NOT public.hope_can_access('sales', 'sale_details', 'create') THEN
        RAISE EXCEPTION 'Sales Detail Add permission is required.'
            USING ERRCODE = '42501';
    END IF;

    SELECT s.salesdate
      INTO v_salesdate
      FROM public.sales AS s
     WHERE s.transno = p_transno
       AND NOT s.is_deleted;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Active sale not found.'
            USING ERRCODE = 'P0002';
    END IF;

    IF p_quantity IS NULL
       OR p_quantity <= 0
       OR p_quantity >= 100000000
       OR p_quantity <> round(p_quantity, 2)
       OR p_product_code IS NULL OR btrim(p_product_code) = ''
       OR length(btrim(p_product_code)) > 6 THEN
        RAISE EXCEPTION 'Enter a valid product and a positive quantity with at most two decimal places.'
            USING ERRCODE = '22023';
    END IF;
    IF v_salesdate IS NULL THEN
        RAISE EXCEPTION 'Sale date is required to calculate product prices.'
            USING ERRCODE = '22023';
    END IF;
    IF NOT EXISTS (
        SELECT 1
          FROM public.product AS p
         WHERE p.prodcode = btrim(p_product_code)
           AND NOT p.is_deleted
    ) THEN
        RAISE EXCEPTION 'Choose an active product.'
            USING ERRCODE = '22023';
    END IF;
    IF public.price_as_of(btrim(p_product_code)::VARCHAR(6), v_salesdate) IS NULL THEN
        RAISE EXCEPTION 'No active price is available on the sale date.'
            USING ERRCODE = '22023';
    END IF;

    INSERT INTO public.salesdetail (transno, prodcode, quantity)
    VALUES (p_transno, btrim(p_product_code), p_quantity);
    RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION public.hope_edit_sale_detail(
    p_transno TEXT,
    p_old_product_code TEXT,
    p_product_code TEXT,
    p_quantity NUMERIC
)
RETURNS BOOLEAN
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $$
DECLARE
    v_salesdate DATE;
BEGIN
    IF NOT public.hope_can_access('sales', 'sales', 'view')
       OR NOT public.hope_can_access('sales', 'sale_details', 'edit') THEN
        RAISE EXCEPTION 'Sales Detail Edit permission is required.'
            USING ERRCODE = '42501';
    END IF;

    SELECT s.salesdate
      INTO v_salesdate
      FROM public.sales AS s
     WHERE s.transno = p_transno
       AND NOT s.is_deleted;

    IF NOT FOUND OR NOT EXISTS (
        SELECT 1
          FROM public.salesdetail AS sd
         WHERE sd.transno = p_transno
           AND sd.prodcode = p_old_product_code
           AND NOT sd.is_deleted
    ) THEN
        RAISE EXCEPTION 'Active sale line not found.'
            USING ERRCODE = 'P0002';
    END IF;

    IF p_quantity IS NULL
       OR p_quantity <= 0
       OR p_quantity >= 100000000
       OR p_quantity <> round(p_quantity, 2)
       OR p_product_code IS NULL OR btrim(p_product_code) = ''
       OR length(btrim(p_product_code)) > 6 THEN
        RAISE EXCEPTION 'Enter a valid product and a positive quantity with at most two decimal places.'
            USING ERRCODE = '22023';
    END IF;
    IF v_salesdate IS NULL THEN
        RAISE EXCEPTION 'Sale date is required to calculate product prices.'
            USING ERRCODE = '22023';
    END IF;
    IF NOT EXISTS (
        SELECT 1
          FROM public.product AS p
         WHERE p.prodcode = btrim(p_product_code)
           AND NOT p.is_deleted
    ) THEN
        RAISE EXCEPTION 'Choose an active product.'
            USING ERRCODE = '22023';
    END IF;
    IF public.price_as_of(btrim(p_product_code)::VARCHAR(6), v_salesdate) IS NULL THEN
        RAISE EXCEPTION 'No active price is available on the sale date.'
            USING ERRCODE = '22023';
    END IF;

    UPDATE public.salesdetail
       SET prodcode = btrim(p_product_code),
           quantity = p_quantity
     WHERE transno = p_transno
       AND prodcode = p_old_product_code
       AND NOT is_deleted;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Active sale line not found.'
            USING ERRCODE = 'P0002';
    END IF;
    RETURN TRUE;
END;
$$;

CREATE OR REPLACE FUNCTION public.hope_delete_sale_detail(
    p_transno TEXT,
    p_product_code TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $$
BEGIN
    IF NOT public.hope_can_access('sales', 'sales', 'view')
       OR NOT public.hope_can_access('sales', 'sale_details', 'delete') THEN
        RAISE EXCEPTION 'Sales Detail Delete permission is required.'
            USING ERRCODE = '42501';
    END IF;

    UPDATE public.salesdetail
       SET is_deleted = TRUE
     WHERE transno = p_transno
       AND prodcode = p_product_code
       AND NOT is_deleted
       AND EXISTS (
           SELECT 1
             FROM public.sales AS s
            WHERE s.transno = p_transno
              AND NOT s.is_deleted
       );

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Active sale line not found.'
            USING ERRCODE = 'P0002';
    END IF;
    RETURN TRUE;
END;
$$;

REVOKE ALL ON FUNCTION public.hope_sales_form_options() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.hope_sales_details_data(TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.hope_add_sale_detail(TEXT, TEXT, NUMERIC) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.hope_edit_sale_detail(TEXT, TEXT, TEXT, NUMERIC) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.hope_delete_sale_detail(TEXT, TEXT) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.hope_sales_form_options() TO authenticated;
GRANT EXECUTE ON FUNCTION public.hope_sales_details_data(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.hope_add_sale_detail(TEXT, TEXT, NUMERIC) TO authenticated;
GRANT EXECUTE ON FUNCTION public.hope_edit_sale_detail(TEXT, TEXT, TEXT, NUMERIC) TO authenticated;
GRANT EXECUTE ON FUNCTION public.hope_delete_sale_detail(TEXT, TEXT) TO authenticated;

COMMIT;
