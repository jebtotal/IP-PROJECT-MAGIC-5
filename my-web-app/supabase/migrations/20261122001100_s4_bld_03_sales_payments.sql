-- Add permission-checked payment recording and transaction payment history.
BEGIN;
SET LOCAL search_path = public, pg_temp;

DO $$
DECLARE
    missing_columns TEXT;
BEGIN
    IF to_regprocedure('public.hope_can_access(text,text,text)') IS NULL
       OR to_regclass('public.v_sale_payment_balance') IS NULL THEN
        RAISE EXCEPTION
            'S4-BLD-03 stopped: apply HOPE app access and the Sales balance views first.';
    END IF;

    WITH required_columns(table_name, column_name) AS (
        VALUES
            ('sales', 'transno'),
            ('sales', 'salesdate'),
            ('sales', 'is_deleted'),
            ('payment', 'orno'),
            ('payment', 'paydate'),
            ('payment', 'amount'),
            ('payment', 'transno'),
            ('payment', 'is_deleted'),
            ('payment', 'stamp')
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
            'S4-BLD-03 stopped: required Sales/payment columns are missing: %.',
            missing_columns;
    END IF;
END;
$$;

CREATE SEQUENCE IF NOT EXISTS public.hope_payment_orno_seq
    AS BIGINT
    MINVALUE 1
    NO CYCLE;

DO $$
DECLARE
    v_max_existing BIGINT;
    v_last_value BIGINT;
    v_is_called BOOLEAN;
BEGIN
    SELECT COALESCE(MAX(substring(orno FROM 3)::BIGINT), 0)
      INTO v_max_existing
      FROM public.payment
     WHERE orno ~ '^OR[0-9]{6}$';

    SELECT last_value, is_called
      INTO v_last_value, v_is_called
      FROM public.hope_payment_orno_seq;

    IF v_max_existing > v_last_value
       OR (v_max_existing = v_last_value AND v_max_existing > 0 AND NOT v_is_called) THEN
        PERFORM setval(
            'public.hope_payment_orno_seq',
            v_max_existing,
            TRUE
        );
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.hope_sales_payments_data(p_transno TEXT)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $$
DECLARE
    v_balance JSONB;
    v_payments JSONB;
BEGIN
    IF NOT public.hope_can_access('sales', 'sales', 'view') THEN
        RAISE EXCEPTION 'Sales View permission is required.'
            USING ERRCODE = '42501';
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM public.sales AS s
         WHERE s.transno = p_transno
           AND NOT s.is_deleted
    ) THEN
        RAISE EXCEPTION 'Active sale not found.'
            USING ERRCODE = 'P0002';
    END IF;

    SELECT to_jsonb(b)
      INTO v_balance
      FROM public.v_sale_payment_balance AS b
     WHERE b.transno = p_transno;

    IF v_balance IS NULL THEN
        RAISE EXCEPTION 'Sale balance could not be calculated.'
            USING ERRCODE = 'P0001';
    END IF;

    SELECT COALESCE(
               jsonb_agg(
                   jsonb_build_object(
                       'receiptNo', p.orno,
                       'paymentDate', p.paydate,
                       'amount', p.amount
                   )
                   ORDER BY p.paydate DESC NULLS LAST, p.orno DESC
               ),
               '[]'::JSONB
           )
      INTO v_payments
      FROM public.payment AS p
     WHERE p.transno = p_transno
       AND NOT p.is_deleted;

    RETURN jsonb_build_object(
        'transactionNo', p_transno,
        'totalAmount', v_balance -> 'total_amount',
        'totalPaid', v_balance -> 'total_paid',
        'balance', v_balance -> 'balance',
        'status', v_balance -> 'status',
        'payments', v_payments,
        'actions', jsonb_build_object(
            'add', public.hope_can_access('sales', 'sales', 'create')
        )
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.hope_create_sale_payment(
    p_transno TEXT,
    p_paydate DATE,
    p_amount NUMERIC
)
RETURNS TEXT
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $$
DECLARE
    v_receipt_number BIGINT;
    v_orno TEXT;
BEGIN
    IF NOT public.hope_can_access('sales', 'sales', 'view')
       OR NOT public.hope_can_access('sales', 'sales', 'create') THEN
        RAISE EXCEPTION 'Sales View and Add permissions are required.'
            USING ERRCODE = '42501';
    END IF;

    IF p_paydate IS NULL
       OR p_amount IS NULL
       OR p_amount <= 0
       OR p_amount >= 100000000
       OR p_amount <> round(p_amount, 2) THEN
        RAISE EXCEPTION 'Payment date and a positive amount with at most two decimal places are required.'
            USING ERRCODE = '22023';
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM public.sales AS s
         WHERE s.transno = p_transno
           AND NOT s.is_deleted
    ) THEN
        RAISE EXCEPTION 'Active sale not found.'
            USING ERRCODE = 'P0002';
    END IF;

    LOOP
        v_receipt_number := nextval('public.hope_payment_orno_seq');
        IF v_receipt_number > 999999 THEN
            RAISE EXCEPTION 'Payment receipt number sequence exhausted.'
                USING ERRCODE = 'P0001';
        END IF;

        v_orno := 'OR' || lpad(v_receipt_number::TEXT, 6, '0');
        INSERT INTO public.payment (orno, paydate, amount, transno)
        VALUES (v_orno, p_paydate, p_amount, p_transno)
        ON CONFLICT (orno) DO NOTHING;

        IF FOUND THEN
            RETURN v_orno;
        END IF;
    END LOOP;
END;
$$;

REVOKE ALL ON FUNCTION public.hope_sales_payments_data(TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.hope_create_sale_payment(TEXT, DATE, NUMERIC) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON SEQUENCE public.hope_payment_orno_seq FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.hope_sales_payments_data(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.hope_create_sale_payment(TEXT, DATE, NUMERIC) TO authenticated;

COMMIT;
