-- Expose Sales balance summaries and permission-checked sale soft delete/restore.
BEGIN;
SET LOCAL search_path = public, pg_temp;

DO $$
DECLARE
    missing_columns TEXT;
BEGIN
    IF to_regprocedure('public.hope_can_access(text,text,text)') IS NULL
       OR to_regclass('public.v_sale_payment_balance') IS NULL
       OR to_regclass('public.v_customer_payment_balance') IS NULL THEN
        RAISE EXCEPTION
            'S4-BLD-05 stopped: apply HOPE app access and the Sales balance views first.';
    END IF;

    WITH required_columns(table_name, column_name) AS (
        VALUES
            ('sales', 'transno'),
            ('sales', 'is_deleted'),
            ('sales', 'stamp'),
            ('profiles', 'id'),
            ('profiles', 'role')
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
            'S4-BLD-05 stopped: required Sales/profile columns are missing: %.',
            missing_columns;
    END IF;
END;
$$;

-- A sale is an archival parent: retain its line items and payments so restore
-- can reactivate the complete transaction without changing its ledger history.
DROP TRIGGER IF EXISTS sales_bu_check ON public.sales;

CREATE OR REPLACE FUNCTION public.hope_sales_balance_data()
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
        'transactions',
        COALESCE(
            (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'transactionNo', balance.transno,
                        'totalAmount', balance.total_amount,
                        'totalPaid', balance.total_paid,
                        'balance', balance.balance,
                        'status', balance.status
                    )
                    ORDER BY balance.transno
                )
                  FROM public.v_sale_payment_balance AS balance
            ),
            '[]'::JSONB
        ),
        'customers',
        COALESCE(
            (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'customerNo', balance.custno,
                        'customerName', balance.custname,
                        'totalAmount', balance.total_amount,
                        'totalPaid', balance.total_paid,
                        'balance', balance.balance,
                        'status', balance.status
                    )
                    ORDER BY balance.custname, balance.custno
                )
                  FROM public.v_customer_payment_balance AS balance
            ),
            '[]'::JSONB
        )
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.hope_set_sale_deleted(
    p_transno TEXT,
    p_is_deleted BOOLEAN
)
RETURNS BOOLEAN
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $$
BEGIN
    IF NOT public.hope_can_access('sales', 'sales', 'delete') THEN
        RAISE EXCEPTION 'Sales Delete permission is required.'
            USING ERRCODE = '42501';
    END IF;

    IF p_transno IS NULL OR btrim(p_transno) = '' OR p_is_deleted IS NULL THEN
        RAISE EXCEPTION 'A transaction number and target status are required.'
            USING ERRCODE = '22023';
    END IF;

    IF NOT p_is_deleted AND NOT EXISTS (
        SELECT 1
          FROM public.profiles AS profile
         WHERE profile.id = auth.uid()
           AND profile.role IN ('admin', 'superadmin')
    ) THEN
        RAISE EXCEPTION 'Only administrators can restore inactive sales.'
            USING ERRCODE = '42501';
    END IF;

    UPDATE public.sales
       SET is_deleted = p_is_deleted
     WHERE transno = btrim(p_transno)
       AND is_deleted IS DISTINCT FROM p_is_deleted;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Sale not found or already has the requested status.'
            USING ERRCODE = 'P0002';
    END IF;

    RETURN TRUE;
END;
$$;

REVOKE ALL ON FUNCTION public.hope_sales_balance_data() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.hope_set_sale_deleted(TEXT, BOOLEAN) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.hope_sales_balance_data() TO authenticated;
GRANT EXECUTE ON FUNCTION public.hope_set_sale_deleted(TEXT, BOOLEAN) TO authenticated;

COMMIT;
