-- Add permission-checked Sales header options and sequence-backed creation.
BEGIN;
SET LOCAL search_path = public, pg_temp;

DO $$
DECLARE
    missing_columns TEXT;
BEGIN
    IF to_regprocedure('public.hope_can_access(text,text,text)') IS NULL THEN
        RAISE EXCEPTION
            'S4-BLD-01 stopped: public.hope_can_access(text,text,text) is required.';
    END IF;

    WITH required_columns(table_name, column_name) AS (
        VALUES
            ('sales', 'transno'),
            ('sales', 'salesdate'),
            ('sales', 'custno'),
            ('sales', 'empno'),
            ('customer', 'custno'),
            ('customer', 'custname'),
            ('customer', 'is_deleted'),
            ('employee', 'empno'),
            ('employee', 'firstname'),
            ('employee', 'lastname'),
            ('employee', 'hiredate'),
            ('employee', 'sepdate'),
            ('employee', 'is_deleted')
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
            'S4-BLD-01 stopped: required Sales/customer/employee columns are missing: %.',
            missing_columns;
    END IF;
END;
$$;

CREATE SEQUENCE IF NOT EXISTS public.hope_sales_transno_seq
    AS BIGINT
    MINVALUE 1
    NO CYCLE;

DO $$
DECLARE
    v_max_existing BIGINT;
    v_last_value BIGINT;
    v_is_called BOOLEAN;
BEGIN
    SELECT COALESCE(MAX(substring(transno FROM 3)::BIGINT), 0)
      INTO v_max_existing
      FROM public.sales
     WHERE transno ~ '^TR[0-9]{6}$';

    SELECT last_value, is_called
      INTO v_last_value, v_is_called
      FROM public.hope_sales_transno_seq;

    IF v_max_existing > v_last_value
       OR (v_max_existing = v_last_value AND v_max_existing > 0 AND NOT v_is_called) THEN
        PERFORM setval(
            'public.hope_sales_transno_seq',
            v_max_existing,
            TRUE
        );
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
        )
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.hope_create_sale(
    p_salesdate DATE,
    p_custno TEXT,
    p_empno TEXT
)
RETURNS TEXT
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $$
DECLARE
    v_number BIGINT;
    v_transno TEXT;
BEGIN
    IF NOT public.hope_can_access('sales', 'sales', 'create') THEN
        RAISE EXCEPTION 'Sales Add permission is required.'
            USING ERRCODE = '42501';
    END IF;

    IF p_salesdate IS NULL
       OR p_custno IS NULL
       OR btrim(p_custno) = ''
       OR p_empno IS NULL
       OR btrim(p_empno) = ''
       OR NOT EXISTS (
           SELECT 1
             FROM public.customer AS c
            WHERE c.custno = btrim(p_custno)
              AND NOT c.is_deleted
       )
       OR NOT EXISTS (
           SELECT 1
             FROM public.employee AS e
            WHERE e.empno = btrim(p_empno)
              AND NOT e.is_deleted
              AND (e.hiredate IS NULL OR e.hiredate <= p_salesdate)
              AND (e.sepdate IS NULL OR e.sepdate >= p_salesdate)
       ) THEN
        RAISE EXCEPTION 'Choose an active customer and salesperson.'
            USING ERRCODE = '22023';
    END IF;

    LOOP
        v_number := nextval('public.hope_sales_transno_seq');
        IF v_number > 999999 THEN
            RAISE EXCEPTION 'Sales transaction number sequence exhausted.'
                USING ERRCODE = 'P0001';
        END IF;

        v_transno := 'TR' || lpad(v_number::TEXT, 6, '0');
        INSERT INTO public.sales (transno, salesdate, custno, empno)
        VALUES (v_transno, p_salesdate, btrim(p_custno), btrim(p_empno))
        ON CONFLICT (transno) DO NOTHING;

        IF FOUND THEN
            RETURN v_transno;
        END IF;
    END LOOP;
END;
$$;

REVOKE ALL ON FUNCTION public.hope_sales_form_options() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.hope_create_sale(DATE, TEXT, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON SEQUENCE public.hope_sales_transno_seq FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.hope_sales_form_options() TO authenticated;
GRANT EXECUTE ON FUNCTION public.hope_create_sale(DATE, TEXT, TEXT) TO authenticated;

COMMIT;
