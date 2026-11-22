-- Run after 20261122000400_s2_dba_01_customer_product_active.sql.
-- Use only a scratch/copy database as an approved admin/superadmin.
BEGIN;
SET LOCAL search_path = public, pg_temp;

DO $$
DECLARE
    customer_test VARCHAR(5);
    product_test VARCHAR(6);
    profile_id UUID;
    attempt INTEGER;
BEGIN
    IF to_regclass('public.customer_active') IS NULL
       OR to_regclass('public.product_active') IS NULL THEN
        RAISE EXCEPTION
            'S2-DBA-01 test requires customer_active and product_active views. Apply the migration first.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM pg_class
         WHERE oid = 'public.customer_active'::regclass
           AND reloptions @> ARRAY['security_invoker=true']
    ) OR NOT EXISTS (
        SELECT 1
          FROM pg_class
         WHERE oid = 'public.product_active'::regclass
           AND reloptions @> ARRAY['security_invoker=true']
    ) THEN
        RAISE EXCEPTION
            'S2-DBA-01 failed: both active views must use security_invoker=true.';
    END IF;

    IF NOT has_table_privilege('authenticated', 'public.customer_active', 'SELECT')
       OR NOT has_table_privilege('authenticated', 'public.product_active', 'SELECT') THEN
        RAISE EXCEPTION
            'S2-DBA-01 failed: authenticated must have SELECT on both active views.';
    END IF;

    SELECT id
      INTO profile_id
      FROM public.profiles
     WHERE role::TEXT IN ('admin', 'superadmin')
       AND status::TEXT = 'approved'
     ORDER BY id
     LIMIT 1;
    IF profile_id IS NULL THEN
        RAISE EXCEPTION
            'S2-DBA-01 test needs an approved admin/superadmin profile in the scratch database.';
    END IF;

    PERFORM set_config('request.jwt.claim.sub', profile_id::TEXT, TRUE);
    PERFORM set_config(
        'request.jwt.claims',
        jsonb_build_object('sub', profile_id::TEXT)::TEXT,
        TRUE
    );

    FOR attempt IN 1..50 LOOP
        customer_test := 'C' || substr(md5(random()::TEXT || clock_timestamp()::TEXT), 1, 4);
        EXIT WHEN NOT EXISTS (
            SELECT 1 FROM public.customer WHERE custno = customer_test
        );
    END LOOP;
    IF EXISTS (SELECT 1 FROM public.customer WHERE custno = customer_test) THEN
        RAISE EXCEPTION 'S2-DBA-01 test could not allocate a customer key.';
    END IF;

    FOR attempt IN 1..50 LOOP
        product_test := 'P' || substr(md5(random()::TEXT || clock_timestamp()::TEXT), 1, 5);
        EXIT WHEN NOT EXISTS (
            SELECT 1 FROM public.product WHERE prodcode = product_test
        );
    END LOOP;
    IF EXISTS (SELECT 1 FROM public.product WHERE prodcode = product_test) THEN
        RAISE EXCEPTION 'S2-DBA-01 test could not allocate a product key.';
    END IF;

    INSERT INTO public.customer (custno, custname, address, payterm)
    VALUES (customer_test, 'S2 Demo Customer', 'Scratch fixture only', 'COD');
    INSERT INTO public.product (prodcode, description, unit)
    VALUES (product_test, 'S2 Demo Product', 'pc');

    IF NOT EXISTS (
        SELECT 1 FROM public.customer_active WHERE custno = customer_test
    ) OR NOT EXISTS (
        SELECT 1 FROM public.product_active WHERE prodcode = product_test
    ) THEN
        RAISE EXCEPTION
            'S2-DBA-01 failed: an active test record is missing from its active view.';
    END IF;

    UPDATE public.customer SET is_deleted = TRUE WHERE custno = customer_test;
    UPDATE public.product SET is_deleted = TRUE WHERE prodcode = product_test;

    IF EXISTS (
        SELECT 1 FROM public.customer_active WHERE custno = customer_test
    ) OR EXISTS (
        SELECT 1 FROM public.product_active WHERE prodcode = product_test
    ) THEN
        RAISE EXCEPTION
            'S2-DBA-01 failed: a soft-deleted record remains visible in an active view.';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM public.customer
         WHERE custno = customer_test AND is_deleted
    ) OR NOT EXISTS (
        SELECT 1 FROM public.product
         WHERE prodcode = product_test AND is_deleted
    ) THEN
        RAISE EXCEPTION
            'S2-DBA-01 failed: soft-deleted test rows should remain in their base tables.';
    END IF;

    RAISE NOTICE
        'PASS: customer % and product % disappeared from active views but remain soft-deleted in their base tables.',
        customer_test,
        product_test;
END;
$$;

SELECT
    table_class.relname AS table_name,
    index_class.relname AS index_name,
    pg_get_indexdef(index_class.oid) AS index_definition
FROM pg_index AS index_row
JOIN pg_class AS index_class ON index_class.oid = index_row.indexrelid
JOIN pg_class AS table_class ON table_class.oid = index_row.indrelid
JOIN pg_namespace AS table_namespace ON table_namespace.oid = table_class.relnamespace
WHERE table_namespace.nspname = 'public'
  AND table_class.relname IN ('customer', 'product', 'sales', 'salesdetail', 'pricehist')
ORDER BY table_class.relname, index_class.relname;

SELECT
    'S2-DBA-01 test rows are temporary and will be rolled back.' AS test_result;

ROLLBACK;
