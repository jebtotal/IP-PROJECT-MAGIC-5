-- Run after applying s2_dba_05_customer_product_demo_data.sql twice.
-- Read-only verification; does not modify demo or application data.
BEGIN;
SET LOCAL search_path = public, pg_temp;

DO $$
DECLARE
    customer_rows INTEGER;
    active_customer_rows INTEGER;
    deleted_customer_rows INTEGER;
    product_rows INTEGER;
    active_product_rows INTEGER;
    deleted_product_rows INTEGER;
    price_rows INTEGER;
    active_price_rows INTEGER;
    mismatch_count INTEGER;
BEGIN
    SELECT count(*) INTO customer_rows
      FROM public.customer
     WHERE custno IN ('ZC501', 'ZC502', 'ZC503', 'ZC504');
    SELECT count(*) INTO active_customer_rows
      FROM public.customer_active
     WHERE custno IN ('ZC501', 'ZC502', 'ZC503', 'ZC504');
    SELECT count(*) INTO deleted_customer_rows
      FROM public.customer
     WHERE custno IN ('ZC501', 'ZC502', 'ZC503', 'ZC504')
       AND is_deleted;

    SELECT count(*) INTO product_rows
      FROM public.product
     WHERE prodcode IN ('ZP5001', 'ZP5002', 'ZP5003', 'ZP5004');
    SELECT count(*) INTO active_product_rows
      FROM public.product_active
     WHERE prodcode IN ('ZP5001', 'ZP5002', 'ZP5003', 'ZP5004');
    SELECT count(*) INTO deleted_product_rows
      FROM public.product
     WHERE prodcode IN ('ZP5001', 'ZP5002', 'ZP5003', 'ZP5004')
       AND is_deleted;

    SELECT count(*) INTO price_rows
      FROM public.pricehist
     WHERE prodcode IN ('ZP5001', 'ZP5002', 'ZP5003', 'ZP5004');
    SELECT count(*) INTO active_price_rows
      FROM public.pricehist_active
     WHERE prodcode IN ('ZP5001', 'ZP5002', 'ZP5003', 'ZP5004');

    IF customer_rows <> 4 OR active_customer_rows <> 3 OR deleted_customer_rows <> 1
       OR product_rows <> 4 OR active_product_rows <> 3 OR deleted_product_rows <> 1
       OR price_rows <> 16 OR active_price_rows <> 12 THEN
        RAISE EXCEPTION
            'S2-DBA-05 verification failed: expected Customer base/active/deleted 4/3/1, Product 4/3/1, and Price History base/active 16/12; got Customer %/%/%, Product %/%/%, Price History %/%.',
            customer_rows, active_customer_rows, deleted_customer_rows,
            product_rows, active_product_rows, deleted_product_rows,
            price_rows, active_price_rows;
    END IF;

    IF (SELECT count(*) FROM public.v_product_current_price
         WHERE prodcode IN ('ZP5001', 'ZP5002', 'ZP5003', 'ZP5004')) <> 3
       OR (SELECT count(*) FROM public.v_product_current_price
            WHERE prodcode = 'ZP5004') <> 0 THEN
        RAISE EXCEPTION
            'S2-DBA-05 verification failed: current-price view must include three active demo products and omit soft-deleted ZP5004.';
    END IF;

    IF EXISTS (
        SELECT 1
          FROM (VALUES
              ('ZP5001', 13.75::NUMERIC(10, 2)),
              ('ZP5002', 24.50::NUMERIC(10, 2)),
              ('ZP5003', 36.00::NUMERIC(10, 2))
          ) AS expected(prodcode, unitprice)
          LEFT JOIN public.v_product_current_price AS actual USING (prodcode)
         WHERE actual.prodcode IS NULL
            OR actual.unitprice IS DISTINCT FROM expected.unitprice
    ) THEN
        RAISE EXCEPTION
            'S2-DBA-05 verification failed: the current-price view does not return all expected prices for active demo products.';
    END IF;

    IF EXISTS (
        SELECT 1
          FROM (VALUES ('ZC501'), ('ZC502'), ('ZC503')) AS expected(custno)
         WHERE NOT EXISTS (
             SELECT 1 FROM public.customer_active AS active
              WHERE active.custno = expected.custno
         )
    ) OR EXISTS (
        SELECT 1 FROM public.customer_active WHERE custno = 'ZC504'
    ) OR NOT EXISTS (
        SELECT 1 FROM public.customer
         WHERE custno = 'ZC504' AND is_deleted
    ) THEN
        RAISE EXCEPTION
            'S2-DBA-05 verification failed: customer_active must show ZC501-ZC503 and omit soft-deleted ZC504, which remains in customer.';
    END IF;

    IF EXISTS (
        SELECT 1
          FROM (VALUES ('ZP5001'), ('ZP5002'), ('ZP5003')) AS expected(prodcode)
         WHERE NOT EXISTS (
             SELECT 1 FROM public.product_active AS active
              WHERE active.prodcode = expected.prodcode
         )
    ) OR EXISTS (
        SELECT 1 FROM public.product_active WHERE prodcode = 'ZP5004'
    ) OR NOT EXISTS (
        SELECT 1 FROM public.product
         WHERE prodcode = 'ZP5004' AND is_deleted
    ) THEN
        RAISE EXCEPTION
            'S2-DBA-05 verification failed: product_active must show ZP5001-ZP5003 and omit soft-deleted ZP5004, which remains in product.';
    END IF;

    SELECT count(*)
      INTO mismatch_count
      FROM (VALUES
          ('ZC501', 'COD'),
          ('ZC502', '30D'),
          ('ZC503', '45D'),
          ('ZC504', 'COD')
      ) AS expected(custno, payterm)
      LEFT JOIN public.customer AS actual USING (custno)
     WHERE actual.custno IS NULL
        OR actual.payterm IS DISTINCT FROM expected.payterm;

    IF mismatch_count > 0 THEN
        RAISE EXCEPTION
            'S2-DBA-05 verification failed: the demo customers do not preserve the expected varied payterms.';
    END IF;

    SELECT count(*)
      INTO mismatch_count
      FROM (VALUES
          ('ZP5001', 'pc'),
          ('ZP5002', 'mtr'),
          ('ZP5003', 'ea'),
          ('ZP5004', 'pkg')
      ) AS expected(prodcode, unit)
      LEFT JOIN public.product AS actual USING (prodcode)
     WHERE actual.prodcode IS NULL
        OR actual.unit IS DISTINCT FROM expected.unit;

    IF mismatch_count > 0 THEN
        RAISE EXCEPTION
            'S2-DBA-05 verification failed: the demo products do not preserve the expected varied units.';
    END IF;

    IF public.price_as_of('ZP5001', CURRENT_DATE) IS DISTINCT FROM 13.75::NUMERIC(10, 2)
       OR public.price_as_of('ZP5001', DATE '2099-01-01') IS DISTINCT FROM 99.99::NUMERIC(10, 2)
       OR public.price_as_of('ZP5004', CURRENT_DATE) IS NOT NULL THEN
        RAISE EXCEPTION
            'S2-DBA-05 verification failed: current/future/deleted-product price-as-of results are incorrect.';
    END IF;

    IF EXISTS (
        SELECT 1
          FROM (VALUES ('ZP5001'), ('ZP5002'), ('ZP5003'), ('ZP5004')) AS expected(prodcode)
         WHERE (SELECT count(*) FROM public.pricehist AS history
                 WHERE history.prodcode = expected.prodcode) <> 4
    ) THEN
        RAISE EXCEPTION
            'S2-DBA-05 verification failed: every demo product must retain exactly four effective-dated prices after the seed is rerun.';
    END IF;

    RAISE NOTICE
        'PASS: rerun-safe counts are Customer 4 base/3 active/1 soft-deleted; Product 4 base/3 active/1 soft-deleted; Price History 16 base/12 active.';
    RAISE NOTICE
        'PASS: each demo product has four price rows; future prices remain dated 2099-01-01; soft-deleted product ZP5004 is absent from active/current-price views.';
    RAISE NOTICE
        'PASS: price_as_of(ZP5001, CURRENT_DATE) = 13.75; price_as_of(ZP5001, 2099-01-01) = 99.99; price_as_of(ZP5004, CURRENT_DATE) = NULL.';
END;
$$;

SELECT 'Customer demo counts' AS section, status, row_count
FROM (
    SELECT 'base' AS status, count(*)::INTEGER AS row_count
      FROM public.customer
     WHERE custno IN ('ZC501', 'ZC502', 'ZC503', 'ZC504')
    UNION ALL
    SELECT 'active view', count(*)::INTEGER
      FROM public.customer_active
     WHERE custno IN ('ZC501', 'ZC502', 'ZC503', 'ZC504')
    UNION ALL
    SELECT 'soft-deleted', count(*)::INTEGER
      FROM public.customer
     WHERE custno IN ('ZC501', 'ZC502', 'ZC503', 'ZC504')
       AND is_deleted
) AS counts
UNION ALL
SELECT 'Product demo counts', status, row_count
FROM (
    SELECT 'base' AS status, count(*)::INTEGER AS row_count
      FROM public.product
     WHERE prodcode IN ('ZP5001', 'ZP5002', 'ZP5003', 'ZP5004')
    UNION ALL
    SELECT 'active view', count(*)::INTEGER
      FROM public.product_active
     WHERE prodcode IN ('ZP5001', 'ZP5002', 'ZP5003', 'ZP5004')
    UNION ALL
    SELECT 'soft-deleted', count(*)::INTEGER
      FROM public.product
     WHERE prodcode IN ('ZP5001', 'ZP5002', 'ZP5003', 'ZP5004')
       AND is_deleted
) AS counts
UNION ALL
SELECT 'Price History demo counts', status, row_count
FROM (
    SELECT 'base' AS status, count(*)::INTEGER AS row_count
      FROM public.pricehist
     WHERE prodcode IN ('ZP5001', 'ZP5002', 'ZP5003', 'ZP5004')
    UNION ALL
    SELECT 'active view', count(*)::INTEGER
      FROM public.pricehist_active
     WHERE prodcode IN ('ZP5001', 'ZP5002', 'ZP5003', 'ZP5004')
) AS counts
ORDER BY section, status;

SELECT
    product.prodcode,
    product.description,
    product.unit,
    current_price.unitprice AS current_unitprice,
    public.price_as_of(product.prodcode, CURRENT_DATE) AS price_as_of_today,
    public.price_as_of(product.prodcode, DATE '2099-01-01') AS price_as_of_future_date
FROM public.product_active AS product
LEFT JOIN public.v_product_current_price AS current_price USING (prodcode)
WHERE product.prodcode IN ('ZP5001', 'ZP5002', 'ZP5003')
ORDER BY product.prodcode;

SELECT
    customer.custno,
    customer.custname,
    customer.payterm,
    customer.is_deleted,
    (active.custno IS NOT NULL) AS visible_in_customer_active
FROM public.customer AS customer
LEFT JOIN public.customer_active AS active USING (custno)
WHERE customer.custno IN ('ZC501', 'ZC502', 'ZC503', 'ZC504')
ORDER BY customer.custno;

SELECT
    product.prodcode,
    product.description,
    product.unit,
    product.is_deleted,
    (active.prodcode IS NOT NULL) AS visible_in_product_active,
    count(history.effdate) AS retained_price_rows,
    count(history.effdate) FILTER (WHERE NOT history.is_deleted) AS active_price_rows
FROM public.product AS product
LEFT JOIN public.product_active AS active USING (prodcode)
LEFT JOIN public.pricehist AS history USING (prodcode)
WHERE product.prodcode IN ('ZP5001', 'ZP5002', 'ZP5003', 'ZP5004')
GROUP BY product.prodcode, product.description, product.unit, product.is_deleted, active.prodcode
ORDER BY product.prodcode;

SELECT
    product.prodcode,
    product.is_deleted AS remains_in_base_table,
    history.effdate,
    history.unitprice,
    history.is_deleted AS price_row_is_deleted
FROM public.product AS product
JOIN public.pricehist AS history USING (prodcode)
WHERE product.prodcode = 'ZP5004'
ORDER BY history.effdate;

ROLLBACK;
