-- Run only against a scratch/copy database as a database owner.
-- Fixtures, audit rows, and all soft-delete transitions roll back.
BEGIN;
SET LOCAL search_path = public, pg_temp;

SELECT
    constraint_row.conname AS constraint_name,
    child.relname AS referencing_table,
    child_column.attname AS referencing_column,
    parent.relname AS referenced_table,
    parent_column.attname AS referenced_column,
    CASE constraint_row.confdeltype
        WHEN 'a' THEN 'NO ACTION'
        WHEN 'r' THEN 'RESTRICT'
        WHEN 'c' THEN 'CASCADE'
        WHEN 'n' THEN 'SET NULL'
        WHEN 'd' THEN 'SET DEFAULT'
    END AS on_delete
FROM pg_constraint AS constraint_row
JOIN pg_class AS child ON child.oid = constraint_row.conrelid
JOIN pg_namespace AS child_namespace ON child_namespace.oid = child.relnamespace
JOIN pg_class AS parent ON parent.oid = constraint_row.confrelid
JOIN pg_namespace AS parent_namespace ON parent_namespace.oid = parent.relnamespace
JOIN pg_attribute AS child_column
  ON child_column.attrelid = child.oid
 AND child_column.attnum = constraint_row.conkey[1]
JOIN pg_attribute AS parent_column
  ON parent_column.attrelid = parent.oid
 AND parent_column.attnum = constraint_row.confkey[1]
WHERE constraint_row.contype = 'f'
  AND child_namespace.nspname = 'public'
  AND parent_namespace.nspname = 'public'
  AND parent.relname IN ('customer', 'product')
ORDER BY parent.relname, child.relname, constraint_row.conname;

SELECT
    table_class.relname AS table_name,
    trigger_row.tgname AS trigger_name,
    pg_get_triggerdef(trigger_row.oid) AS trigger_definition
FROM pg_trigger AS trigger_row
JOIN pg_class AS table_class ON table_class.oid = trigger_row.tgrelid
JOIN pg_namespace AS table_namespace ON table_namespace.oid = table_class.relnamespace
WHERE NOT trigger_row.tgisinternal
  AND table_namespace.nspname = 'public'
  AND table_class.relname IN ('customer', 'product', 'sales', 'salesdetail', 'pricehist')
ORDER BY table_class.relname, trigger_row.tgname;

DO $$
DECLARE
    customer_blocked VARCHAR(5);
    customer_free VARCHAR(5);
    product_detail_blocked VARCHAR(6);
    product_price_blocked VARCHAR(6);
    product_archived VARCHAR(6);
    product_free VARCHAR(6);
    sales_key VARCHAR(8);
    profile_id UUID;
    attempt INTEGER;
    error_message TEXT;
    rejected BOOLEAN;
    actual_fk_count INTEGER;
    expected_fk_count INTEGER;
BEGIN
    IF to_regclass('public.customer') IS NULL
       OR to_regclass('public.product') IS NULL
       OR to_regclass('public.sales') IS NULL
       OR to_regclass('public.salesdetail') IS NULL
       OR to_regclass('public.pricehist') IS NULL
       OR to_regprocedure('public.trg_check_children()') IS NULL THEN
        RAISE EXCEPTION
            'S2-DBA-04 test requires customer, product, sales, salesdetail, pricehist, and public.trg_check_children(). Apply the HOPE schema migrations first.';
    END IF;

    SELECT count(*)
      INTO actual_fk_count
      FROM pg_constraint AS constraint_row
      JOIN pg_class AS child ON child.oid = constraint_row.conrelid
      JOIN pg_namespace AS child_namespace ON child_namespace.oid = child.relnamespace
      JOIN pg_class AS parent ON parent.oid = constraint_row.confrelid
      JOIN pg_namespace AS parent_namespace ON parent_namespace.oid = parent.relnamespace
     WHERE constraint_row.contype = 'f'
       AND child_namespace.nspname = 'public'
       AND parent_namespace.nspname = 'public'
       AND parent.relname IN ('customer', 'product');

    SELECT count(*)
      INTO expected_fk_count
      FROM pg_constraint AS constraint_row
      JOIN pg_class AS child ON child.oid = constraint_row.conrelid
      JOIN pg_namespace AS child_namespace ON child_namespace.oid = child.relnamespace
      JOIN pg_class AS parent ON parent.oid = constraint_row.confrelid
      JOIN pg_namespace AS parent_namespace ON parent_namespace.oid = parent.relnamespace
     WHERE constraint_row.contype = 'f'
       AND child_namespace.nspname = 'public'
       AND parent_namespace.nspname = 'public'
       AND (
           (child.relname = 'sales' AND parent.relname = 'customer'
             AND constraint_row.conkey = ARRAY[
                 (SELECT attnum FROM pg_attribute
                   WHERE attrelid = child.oid AND attname = 'custno')
             ]::SMALLINT[]
             AND constraint_row.confkey = ARRAY[
                 (SELECT attnum FROM pg_attribute
                   WHERE attrelid = parent.oid AND attname = 'custno')
             ]::SMALLINT[])
           OR
           (child.relname = 'salesdetail' AND parent.relname = 'product'
             AND constraint_row.conkey = ARRAY[
                 (SELECT attnum FROM pg_attribute
                   WHERE attrelid = child.oid AND attname = 'prodcode')
             ]::SMALLINT[]
             AND constraint_row.confkey = ARRAY[
                 (SELECT attnum FROM pg_attribute
                   WHERE attrelid = parent.oid AND attname = 'prodcode')
             ]::SMALLINT[])
           OR
           (child.relname = 'pricehist' AND parent.relname = 'product'
             AND constraint_row.conkey = ARRAY[
                 (SELECT attnum FROM pg_attribute
                   WHERE attrelid = child.oid AND attname = 'prodcode')
             ]::SMALLINT[]
             AND constraint_row.confkey = ARRAY[
                 (SELECT attnum FROM pg_attribute
                   WHERE attrelid = parent.oid AND attname = 'prodcode')
             ]::SMALLINT[])
       )
       AND constraint_row.confdeltype = 'a';

    IF actual_fk_count <> 3 OR expected_fk_count <> 3 THEN
        RAISE EXCEPTION
            'S2-DBA-04 failed: expected exactly three NO ACTION FKs: sales.custno -> customer.custno, salesdetail.prodcode -> product.prodcode, and pricehist.prodcode -> product.prodcode; found % total and % matching constraints.',
            actual_fk_count,
            expected_fk_count;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM (VALUES ('customer'), ('product')) AS expected(table_name)
         WHERE NOT EXISTS (
             SELECT 1
               FROM pg_trigger AS trigger_row
               JOIN pg_class AS table_class ON table_class.oid = trigger_row.tgrelid
               JOIN pg_namespace AS table_namespace ON table_namespace.oid = table_class.relnamespace
              WHERE table_namespace.nspname = 'public'
                AND table_class.relname = expected.table_name
                AND trigger_row.tgname = expected.table_name || '_bu_check'
                AND NOT trigger_row.tgisinternal
                AND trigger_row.tgfoid = 'public.trg_check_children()'::regprocedure
         )
       ) THEN
        RAISE EXCEPTION
            'S2-DBA-04 failed: customer_bu_check/product_bu_check must call public.trg_check_children().';
    END IF;

    IF EXISTS (
        SELECT 1
          FROM (VALUES ('customer'), ('product')) AS expected(table_name)
         WHERE NOT EXISTS (
             SELECT 1
               FROM pg_trigger AS trigger_row
               JOIN pg_class AS table_class ON table_class.oid = trigger_row.tgrelid
               JOIN pg_namespace AS table_namespace ON table_namespace.oid = table_class.relnamespace
              WHERE table_namespace.nspname = 'public'
                AND table_class.relname = expected.table_name
                AND trigger_row.tgname = expected.table_name || '_bd_block'
                AND NOT trigger_row.tgisinternal
         )
       ) THEN
        RAISE EXCEPTION
            'S2-DBA-04 failed: direct hard-delete blockers are missing on customer or product.';
    END IF;

    IF EXISTS (
        SELECT 1
          FROM (VALUES ('customer'), ('product')) AS expected(table_name)
         WHERE NOT EXISTS (
             SELECT 1
               FROM pg_trigger AS trigger_row
               JOIN pg_class AS table_class ON table_class.oid = trigger_row.tgrelid
               JOIN pg_namespace AS table_namespace ON table_namespace.oid = table_class.relnamespace
              WHERE table_namespace.nspname = 'public'
                AND table_class.relname = expected.table_name
                AND trigger_row.tgname = expected.table_name || '_bd_block'
                AND NOT trigger_row.tgisinternal
                AND trigger_row.tgfoid = 'public.trg_block_hard_delete()'::regprocedure
         )
       ) THEN
        RAISE EXCEPTION
            'S2-DBA-04 failed: customer_bd_block/product_bd_block must call public.trg_block_hard_delete().';
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
            'S2-DBA-04 test needs an approved admin/superadmin profile in the scratch database to exercise delete and restore permissions.';
    END IF;

    PERFORM set_config('request.jwt.claim.sub', profile_id::TEXT, TRUE);
    PERFORM set_config(
        'request.jwt.claims',
        jsonb_build_object('sub', profile_id::TEXT)::TEXT,
        TRUE
    );

    FOR attempt IN 1..50 LOOP
        customer_blocked := 'C' || substr(md5(random()::TEXT || clock_timestamp()::TEXT), 1, 4);
        EXIT WHEN NOT EXISTS (SELECT 1 FROM public.customer WHERE custno = customer_blocked);
    END LOOP;
    FOR attempt IN 1..50 LOOP
        customer_free := 'C' || substr(md5(random()::TEXT || clock_timestamp()::TEXT), 1, 4);
        EXIT WHEN customer_free <> customer_blocked
          AND NOT EXISTS (SELECT 1 FROM public.customer WHERE custno = customer_free);
    END LOOP;
    FOR attempt IN 1..50 LOOP
        product_detail_blocked := 'D' || substr(md5(random()::TEXT || clock_timestamp()::TEXT), 1, 5);
        EXIT WHEN NOT EXISTS (SELECT 1 FROM public.product WHERE prodcode = product_detail_blocked);
    END LOOP;
    FOR attempt IN 1..50 LOOP
        product_price_blocked := 'H' || substr(md5(random()::TEXT || clock_timestamp()::TEXT), 1, 5);
        EXIT WHEN NOT EXISTS (SELECT 1 FROM public.product WHERE prodcode = product_price_blocked);
    END LOOP;
    FOR attempt IN 1..50 LOOP
        product_archived := 'A' || substr(md5(random()::TEXT || clock_timestamp()::TEXT), 1, 5);
        EXIT WHEN NOT EXISTS (SELECT 1 FROM public.product WHERE prodcode = product_archived);
    END LOOP;
    FOR attempt IN 1..50 LOOP
        product_free := 'F' || substr(md5(random()::TEXT || clock_timestamp()::TEXT), 1, 5);
        EXIT WHEN NOT EXISTS (SELECT 1 FROM public.product WHERE prodcode = product_free);
    END LOOP;
    FOR attempt IN 1..50 LOOP
        sales_key := 'S' || substr(md5(random()::TEXT || clock_timestamp()::TEXT), 1, 7);
        EXIT WHEN NOT EXISTS (SELECT 1 FROM public.sales WHERE transno = sales_key);
    END LOOP;

    IF EXISTS (
        SELECT 1 FROM public.customer
         WHERE custno IN (customer_blocked, customer_free)
    ) OR EXISTS (
        SELECT 1 FROM public.product
         WHERE prodcode IN (
             product_detail_blocked,
             product_price_blocked,
             product_archived,
             product_free
         )
    ) OR EXISTS (
        SELECT 1 FROM public.sales WHERE transno = sales_key
    ) THEN
        RAISE EXCEPTION 'S2-DBA-04 test could not allocate unique fixture keys.';
    END IF;

    INSERT INTO public.customer (custno, custname, payterm)
    VALUES
        (customer_blocked, 'S2 Active Child', 'COD'),
        (customer_free, 'S2 No Child', 'COD');
    INSERT INTO public.product (prodcode, description, unit)
    VALUES
        (product_detail_blocked, 'S2 Active Detail', 'pc'),
        (product_price_blocked, 'S2 Active Price', 'ea'),
        (product_archived, 'S2 Archived Child', 'pc'),
        (product_free, 'S2 No Child', 'ea');
    INSERT INTO public.sales (transno, salesdate, custno)
    VALUES (sales_key, CURRENT_DATE, customer_blocked);
    INSERT INTO public.salesdetail (transno, prodcode, quantity)
    VALUES
        (sales_key, product_detail_blocked, 1),
        (sales_key, product_archived, 1);
    INSERT INTO public.pricehist (effdate, prodcode, unitprice)
    VALUES
        (CURRENT_DATE, product_price_blocked, 10.00),
        (CURRENT_DATE, product_archived, 20.00);

    rejected := FALSE;
    BEGIN
        UPDATE public.customer SET is_deleted = TRUE
         WHERE custno = customer_blocked;
    EXCEPTION WHEN raise_exception THEN
        GET STACKED DIAGNOSTICS error_message = MESSAGE_TEXT;
        rejected := position('active related record' IN error_message) > 0;
    END;
    IF NOT rejected THEN
        RAISE EXCEPTION
            'S2-DBA-04 failed: active sales did not block customer soft-delete.';
    END IF;
    RAISE NOTICE 'PASS: customer with an active sales child cannot be soft-deleted.';

    rejected := FALSE;
    BEGIN
        UPDATE public.product SET is_deleted = TRUE
         WHERE prodcode = product_detail_blocked;
    EXCEPTION WHEN raise_exception THEN
        GET STACKED DIAGNOSTICS error_message = MESSAGE_TEXT;
        rejected := position('active related record' IN error_message) > 0;
    END;
    IF NOT rejected THEN
        RAISE EXCEPTION
            'S2-DBA-04 failed: active salesdetail did not block product soft-delete.';
    END IF;
    RAISE NOTICE 'PASS: product with an active salesdetail child cannot be soft-deleted.';

    rejected := FALSE;
    BEGIN
        UPDATE public.product SET is_deleted = TRUE
         WHERE prodcode = product_price_blocked;
    EXCEPTION WHEN raise_exception THEN
        GET STACKED DIAGNOSTICS error_message = MESSAGE_TEXT;
        rejected := position('active related record' IN error_message) > 0;
    END;
    IF NOT rejected THEN
        RAISE EXCEPTION
            'S2-DBA-04 failed: active pricehist did not block product soft-delete.';
    END IF;
    RAISE NOTICE 'PASS: product with an active pricehist child cannot be soft-deleted.';

    UPDATE public.salesdetail SET is_deleted = TRUE
     WHERE transno = sales_key AND prodcode = product_detail_blocked;
    UPDATE public.pricehist SET is_deleted = TRUE
     WHERE prodcode = product_price_blocked;
    UPDATE public.salesdetail SET is_deleted = TRUE
     WHERE transno = sales_key AND prodcode = product_archived;
    UPDATE public.pricehist SET is_deleted = TRUE
     WHERE prodcode = product_archived;
    UPDATE public.sales SET is_deleted = TRUE
     WHERE transno = sales_key;

    UPDATE public.customer SET is_deleted = TRUE
     WHERE custno = customer_blocked;
    IF NOT EXISTS (
        SELECT 1 FROM public.customer
         WHERE custno = customer_blocked AND is_deleted
    ) THEN
        RAISE EXCEPTION
            'S2-DBA-04 failed: archived sales did not permit soft-deleting the customer it references.';
    END IF;
    RAISE NOTICE 'PASS: soft-deleted sales do not block customer soft-delete.';

    UPDATE public.customer SET is_deleted = FALSE
     WHERE custno = customer_blocked;
    IF NOT EXISTS (
        SELECT 1 FROM public.customer
         WHERE custno = customer_blocked AND NOT is_deleted
    ) THEN
        RAISE EXCEPTION 'S2-DBA-04 failed: customer restore did not succeed.';
    END IF;
    RAISE NOTICE 'PASS: customer with archived sales can be restored.';

    UPDATE public.product SET is_deleted = TRUE
     WHERE prodcode = product_archived;
    IF NOT EXISTS (
        SELECT 1 FROM public.product
         WHERE prodcode = product_archived AND is_deleted
    ) THEN
        RAISE EXCEPTION
            'S2-DBA-04 failed: soft-deleted salesdetail/pricehist children did not permit product soft-delete.';
    END IF;
    RAISE NOTICE 'PASS: soft-deleted salesdetail and pricehist do not block product soft-delete.';

    UPDATE public.product SET is_deleted = FALSE
     WHERE prodcode = product_archived;
    IF NOT EXISTS (
        SELECT 1 FROM public.product
         WHERE prodcode = product_archived AND NOT is_deleted
    ) THEN
        RAISE EXCEPTION 'S2-DBA-04 failed: product restore did not succeed.';
    END IF;
    RAISE NOTICE 'PASS: product with archived salesdetail/pricehist can be restored.';

    UPDATE public.customer SET is_deleted = TRUE
     WHERE custno = customer_free;
    UPDATE public.product SET is_deleted = TRUE
     WHERE prodcode = product_free;
    IF NOT EXISTS (
        SELECT 1 FROM public.customer
         WHERE custno = customer_free AND is_deleted
    ) OR NOT EXISTS (
        SELECT 1 FROM public.product
         WHERE prodcode = product_free AND is_deleted
    ) THEN
        RAISE EXCEPTION
            'S2-DBA-04 failed: parent rows with no children could not be soft-deleted.';
    END IF;
    RAISE NOTICE 'PASS: customer and product with no children can be soft-deleted.';

    UPDATE public.customer SET is_deleted = FALSE
     WHERE custno = customer_free;
    UPDATE public.product SET is_deleted = FALSE
     WHERE prodcode = product_free;
    IF NOT EXISTS (
        SELECT 1 FROM public.customer
         WHERE custno = customer_free AND NOT is_deleted
    ) OR NOT EXISTS (
        SELECT 1 FROM public.product
         WHERE prodcode = product_free AND NOT is_deleted
    ) THEN
        RAISE EXCEPTION
            'S2-DBA-04 failed: customer or product without children could not be restored.';
    END IF;
    RAISE NOTICE 'PASS: customer and product with no children can be restored.';

    rejected := FALSE;
    BEGIN
        DELETE FROM public.customer WHERE custno = customer_free;
    EXCEPTION WHEN raise_exception THEN
        GET STACKED DIAGNOSTICS error_message = MESSAGE_TEXT;
        rejected := position('Hard delete/truncate not allowed' IN error_message) > 0;
    END;
    IF NOT rejected OR NOT EXISTS (
        SELECT 1 FROM public.customer WHERE custno = customer_free
    ) THEN
        RAISE EXCEPTION
            'S2-DBA-04 failed: direct hard DELETE of customer was not blocked.';
    END IF;

    rejected := FALSE;
    BEGIN
        DELETE FROM public.product WHERE prodcode = product_free;
    EXCEPTION WHEN raise_exception THEN
        GET STACKED DIAGNOSTICS error_message = MESSAGE_TEXT;
        rejected := position('Hard delete/truncate not allowed' IN error_message) > 0;
    END;
    IF NOT rejected OR NOT EXISTS (
        SELECT 1 FROM public.product WHERE prodcode = product_free
    ) THEN
        RAISE EXCEPTION
            'S2-DBA-04 failed: direct hard DELETE of product was not blocked.';
    END IF;
    RAISE NOTICE 'PASS: direct hard DELETE of customer and product is blocked.';
END;
$$;

SELECT
    'S2-DBA-04 fixtures, audit rows, and soft-delete changes are temporary and will be rolled back.' AS test_result;

ROLLBACK;
