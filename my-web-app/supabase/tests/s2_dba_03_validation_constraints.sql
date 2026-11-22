-- Run after 20261122000600_s2_dba_03_validation_constraints.sql.
-- Execute in a scratch/copy database as a database owner; all fixtures roll back.
BEGIN;
SET LOCAL search_path = public, pg_temp;

DO $$
DECLARE
    customer_key VARCHAR(5);
    product_key VARCHAR(6);
    allowed_value TEXT;
    invalid_value TEXT;
    attempt INTEGER;
    rejected_constraint TEXT;
    customer_allowed TEXT[] := ARRAY['COD', '30D', '45D'];
    product_allowed TEXT[] := ARRAY['pc', 'ea', 'mtr', 'pkg', 'ltr'];
    customer_invalid TEXT[] := ARRAY['NET', '60D'];
    product_invalid TEXT[] := ARRAY['box', 'kg'];
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
         WHERE conrelid = 'public.customer'::regclass
           AND conname = 'pay_ck'
           AND contype = 'c'
           AND convalidated
    ) OR NOT EXISTS (
        SELECT 1 FROM pg_constraint
         WHERE conrelid = 'public.product'::regclass
           AND conname = 'unit_ck'
           AND contype = 'c'
           AND convalidated
    ) THEN
        RAISE EXCEPTION
            'S2-DBA-03 test requires validated pay_ck and unit_ck constraints. Apply the migration first.';
    END IF;

    FOREACH allowed_value IN ARRAY customer_allowed LOOP
        FOR attempt IN 1..50 LOOP
            customer_key := 'T' || substr(md5(random()::TEXT || clock_timestamp()::TEXT), 1, 4);
            EXIT WHEN NOT EXISTS (
                SELECT 1 FROM public.customer WHERE custno = customer_key
            );
        END LOOP;
        IF EXISTS (SELECT 1 FROM public.customer WHERE custno = customer_key) THEN
            RAISE EXCEPTION 'S2-DBA-03 test could not allocate a customer test key.';
        END IF;

        INSERT INTO public.customer (custno, custname, address, payterm)
        VALUES (customer_key, 'S2 Check Test', 'Scratch fixture only', allowed_value);
    END LOOP;

    FOREACH allowed_value IN ARRAY product_allowed LOOP
        FOR attempt IN 1..50 LOOP
            product_key := 'T' || substr(md5(random()::TEXT || clock_timestamp()::TEXT), 1, 5);
            EXIT WHEN NOT EXISTS (
                SELECT 1 FROM public.product WHERE prodcode = product_key
            );
        END LOOP;
        IF EXISTS (SELECT 1 FROM public.product WHERE prodcode = product_key) THEN
            RAISE EXCEPTION 'S2-DBA-03 test could not allocate a product test key.';
        END IF;

        INSERT INTO public.product (prodcode, description, unit)
        VALUES (product_key, 'S2 Check Test', allowed_value);
    END LOOP;

    RAISE NOTICE 'PASS: all allowed payterm values inserted: COD, 30D, 45D.';
    RAISE NOTICE 'PASS: all allowed product unit values inserted: pc, ea, mtr, pkg, ltr.';

    FOREACH invalid_value IN ARRAY customer_invalid LOOP
        FOR attempt IN 1..50 LOOP
            customer_key := 'T' || substr(md5(random()::TEXT || clock_timestamp()::TEXT), 1, 4);
            EXIT WHEN NOT EXISTS (
                SELECT 1 FROM public.customer WHERE custno = customer_key
            );
        END LOOP;
        IF EXISTS (SELECT 1 FROM public.customer WHERE custno = customer_key) THEN
            RAISE EXCEPTION 'S2-DBA-03 test could not allocate a customer test key.';
        END IF;

        BEGIN
            INSERT INTO public.customer (custno, custname, address, payterm)
            VALUES (customer_key, 'S2 Invalid Test', 'Scratch fixture only', invalid_value);
            RAISE EXCEPTION
                'S2-DBA-03 failed: invalid payterm % was accepted.',
                invalid_value;
        EXCEPTION
            WHEN check_violation THEN
                GET STACKED DIAGNOSTICS rejected_constraint = CONSTRAINT_NAME;
                IF rejected_constraint <> 'pay_ck' THEN
                    RAISE EXCEPTION
                        'S2-DBA-03 failed: invalid payterm % was rejected by unexpected constraint %.',
                        invalid_value,
                        rejected_constraint;
                END IF;
                RAISE NOTICE 'PASS: invalid payterm % rejected by pay_ck.', invalid_value;
        END;
    END LOOP;

    FOREACH invalid_value IN ARRAY product_invalid LOOP
        FOR attempt IN 1..50 LOOP
            product_key := 'T' || substr(md5(random()::TEXT || clock_timestamp()::TEXT), 1, 5);
            EXIT WHEN NOT EXISTS (
                SELECT 1 FROM public.product WHERE prodcode = product_key
            );
        END LOOP;
        IF EXISTS (SELECT 1 FROM public.product WHERE prodcode = product_key) THEN
            RAISE EXCEPTION 'S2-DBA-03 test could not allocate a product test key.';
        END IF;

        BEGIN
            INSERT INTO public.product (prodcode, description, unit)
            VALUES (product_key, 'S2 Invalid Test', invalid_value);
            RAISE EXCEPTION
                'S2-DBA-03 failed: invalid product unit % was accepted.',
                invalid_value;
        EXCEPTION
            WHEN check_violation THEN
                GET STACKED DIAGNOSTICS rejected_constraint = CONSTRAINT_NAME;
                IF rejected_constraint <> 'unit_ck' THEN
                    RAISE EXCEPTION
                        'S2-DBA-03 failed: invalid product unit % was rejected by unexpected constraint %.',
                        invalid_value,
                        rejected_constraint;
                END IF;
                RAISE NOTICE 'PASS: invalid product unit % rejected by unit_ck.', invalid_value;
        END;
    END LOOP;
END;
$$;

SELECT
    'S2-DBA-03 test fixtures are temporary and will be rolled back.' AS test_result;

ROLLBACK;
