-- Synthetic Customer, Product, and Price History demo fixtures.
-- Apply after the S2-DBA-01/02/03 migrations; safe to rerun.
BEGIN;
SET LOCAL search_path = public, pg_temp;

DO $$
DECLARE
    missing_relations TEXT;
    admin_id UUID;
BEGIN
    SELECT string_agg(required.relation_name, ', ' ORDER BY required.relation_name)
      INTO missing_relations
      FROM (VALUES
          ('public.customer'),
          ('public.product'),
          ('public.sales'),
          ('public.salesdetail'),
          ('public.pricehist'),
          ('public.customer_active'),
          ('public.product_active'),
          ('public.pricehist_active'),
          ('public.v_product_current_price')
      ) AS required(relation_name)
     WHERE to_regclass(required.relation_name) IS NULL;

    IF missing_relations IS NOT NULL
       OR to_regprocedure('public.price_as_of(character varying, date)') IS NULL THEN
        RAISE EXCEPTION
            'S2-DBA-05 seed stopped: apply the Customer/Product schema and S2-DBA-01/02 views first. Missing relations: %; price_as_of present: %.',
            COALESCE(missing_relations, 'none'),
            to_regprocedure('public.price_as_of(character varying, date)') IS NOT NULL;
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM pg_constraint
         WHERE conrelid = 'public.customer'::regclass
           AND conname = 'pay_ck'
           AND contype = 'c'
           AND convalidated
    ) OR NOT EXISTS (
        SELECT 1
          FROM pg_constraint
         WHERE conrelid = 'public.product'::regclass
           AND conname = 'unit_ck'
           AND contype = 'c'
           AND convalidated
    ) THEN
        RAISE EXCEPTION
            'S2-DBA-05 seed stopped: apply the validated S2-DBA-03 pay_ck and unit_ck constraints first.';
    END IF;

    SELECT id
      INTO admin_id
      FROM public.profiles
     WHERE role::TEXT IN ('admin', 'superadmin')
       AND status::TEXT = 'approved'
     ORDER BY id
     LIMIT 1;

    IF admin_id IS NULL THEN
        RAISE EXCEPTION
            'S2-DBA-05 seed needs an approved admin/superadmin profile to soft-delete its demo Customer and Product.';
    END IF;

    PERFORM set_config('request.jwt.claim.sub', admin_id::TEXT, TRUE);
    PERFORM set_config(
        'request.jwt.claims',
        jsonb_build_object('sub', admin_id::TEXT)::TEXT,
        TRUE
    );
END;
$$;

INSERT INTO public.customer (custno, custname, address, payterm)
VALUES
    ('ZC501', 'Demo Buyer Alpha', '101 Example Ave, Demo City', 'COD'),
    ('ZC502', 'Demo Buyer Bravo', '202 Sample Road, Test Town', '30D'),
    ('ZC503', 'Demo Buyer Charlie', '303 Fiction St, Sample Bay', '45D'),
    ('ZC504', 'Demo Buyer Deleted', '404 Placeholder Blvd, Demo City', 'COD')
ON CONFLICT (custno) DO NOTHING;

INSERT INTO public.product (prodcode, description, unit)
VALUES
    ('ZP5001', 'Demo Widget Alpha', 'pc'),
    ('ZP5002', 'Demo Cable Bravo', 'mtr'),
    ('ZP5003', 'Demo Parts Charlie', 'ea'),
    ('ZP5004', 'Demo Kit Deleted', 'pkg')
ON CONFLICT (prodcode) DO NOTHING;

INSERT INTO public.pricehist (effdate, prodcode, unitprice)
VALUES
    (DATE '2022-01-01', 'ZP5001', 10.00),
    (DATE '2024-01-01', 'ZP5001', 12.00),
    (DATE '2026-01-01', 'ZP5001', 13.75),
    (DATE '2099-01-01', 'ZP5001', 99.99),
    (DATE '2022-01-01', 'ZP5002', 20.00),
    (DATE '2024-01-01', 'ZP5002', 22.00),
    (DATE '2026-01-01', 'ZP5002', 24.50),
    (DATE '2099-01-01', 'ZP5002', 120.00),
    (DATE '2022-01-01', 'ZP5003', 30.00),
    (DATE '2024-01-01', 'ZP5003', 33.00),
    (DATE '2026-01-01', 'ZP5003', 36.00),
    (DATE '2099-01-01', 'ZP5003', 150.00),
    (DATE '2022-01-01', 'ZP5004', 40.00),
    (DATE '2024-01-01', 'ZP5004', 44.00),
    (DATE '2026-01-01', 'ZP5004', 48.00),
    (DATE '2099-01-01', 'ZP5004', 200.00)
ON CONFLICT (effdate, prodcode) DO NOTHING;

DO $$
DECLARE
    mismatch_count INTEGER;
BEGIN
    IF (SELECT count(*) FROM public.customer
         WHERE custno IN ('ZC501', 'ZC502', 'ZC503', 'ZC504')) <> 4 THEN
        RAISE EXCEPTION
            'S2-DBA-05 seed rolled back: reserved demo customer keys ZC501-ZC504 are incomplete.';
    END IF;

    SELECT count(*)
      INTO mismatch_count
      FROM (VALUES
          ('ZC501', 'Demo Buyer Alpha', '101 Example Ave, Demo City', 'COD'),
          ('ZC502', 'Demo Buyer Bravo', '202 Sample Road, Test Town', '30D'),
          ('ZC503', 'Demo Buyer Charlie', '303 Fiction St, Sample Bay', '45D'),
          ('ZC504', 'Demo Buyer Deleted', '404 Placeholder Blvd, Demo City', 'COD')
      ) AS expected(custno, custname, address, payterm)
      LEFT JOIN public.customer AS actual USING (custno)
     WHERE actual.custno IS NULL
        OR (actual.custname, actual.address, actual.payterm)
           IS DISTINCT FROM
           (expected.custname, expected.address, expected.payterm);

    IF mismatch_count > 0 THEN
        RAISE EXCEPTION
            'S2-DBA-05 seed rolled back: one or more reserved demo customer keys conflict with existing values.';
    END IF;

    IF (SELECT count(*) FROM public.product
         WHERE prodcode IN ('ZP5001', 'ZP5002', 'ZP5003', 'ZP5004')) <> 4 THEN
        RAISE EXCEPTION
            'S2-DBA-05 seed rolled back: reserved demo product keys ZP5001-ZP5004 are incomplete.';
    END IF;

    SELECT count(*)
      INTO mismatch_count
      FROM (VALUES
          ('ZP5001', 'Demo Widget Alpha', 'pc'),
          ('ZP5002', 'Demo Cable Bravo', 'mtr'),
          ('ZP5003', 'Demo Parts Charlie', 'ea'),
          ('ZP5004', 'Demo Kit Deleted', 'pkg')
      ) AS expected(prodcode, description, unit)
      LEFT JOIN public.product AS actual USING (prodcode)
     WHERE actual.prodcode IS NULL
        OR (actual.description, actual.unit)
           IS DISTINCT FROM
           (expected.description, expected.unit);

    IF mismatch_count > 0 THEN
        RAISE EXCEPTION
            'S2-DBA-05 seed rolled back: one or more reserved demo product keys conflict with existing values.';
    END IF;

    IF (SELECT count(*) FROM public.pricehist
         WHERE prodcode IN ('ZP5001', 'ZP5002', 'ZP5003', 'ZP5004')) <> 16 THEN
        RAISE EXCEPTION
            'S2-DBA-05 seed rolled back: expected exactly 16 demo price rows (four effective dates for each reserved demo product).';
    END IF;

    SELECT count(*)
      INTO mismatch_count
      FROM (VALUES
          ('ZP5001', DATE '2022-01-01', 10.00::NUMERIC),
          ('ZP5001', DATE '2024-01-01', 12.00::NUMERIC),
          ('ZP5001', DATE '2026-01-01', 13.75::NUMERIC),
          ('ZP5001', DATE '2099-01-01', 99.99::NUMERIC),
          ('ZP5002', DATE '2022-01-01', 20.00::NUMERIC),
          ('ZP5002', DATE '2024-01-01', 22.00::NUMERIC),
          ('ZP5002', DATE '2026-01-01', 24.50::NUMERIC),
          ('ZP5002', DATE '2099-01-01', 120.00::NUMERIC),
          ('ZP5003', DATE '2022-01-01', 30.00::NUMERIC),
          ('ZP5003', DATE '2024-01-01', 33.00::NUMERIC),
          ('ZP5003', DATE '2026-01-01', 36.00::NUMERIC),
          ('ZP5003', DATE '2099-01-01', 150.00::NUMERIC),
          ('ZP5004', DATE '2022-01-01', 40.00::NUMERIC),
          ('ZP5004', DATE '2024-01-01', 44.00::NUMERIC),
          ('ZP5004', DATE '2026-01-01', 48.00::NUMERIC),
          ('ZP5004', DATE '2099-01-01', 200.00::NUMERIC)
      ) AS expected(prodcode, effdate, unitprice)
      LEFT JOIN public.pricehist AS actual
        ON actual.prodcode = expected.prodcode
       AND actual.effdate = expected.effdate
     WHERE actual.prodcode IS NULL
        OR actual.unitprice IS DISTINCT FROM expected.unitprice;

    IF mismatch_count > 0 THEN
        RAISE EXCEPTION
            'S2-DBA-05 seed rolled back: one or more reserved demo price-history keys conflict with existing values.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM public.sales WHERE custno = 'ZC504' AND NOT is_deleted
    ) THEN
        RAISE EXCEPTION
            'S2-DBA-05 seed rolled back: demo customer ZC504 has active sales and cannot be soft-deleted.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM public.salesdetail
         WHERE prodcode = 'ZP5004' AND NOT is_deleted
    ) THEN
        RAISE EXCEPTION
            'S2-DBA-05 seed rolled back: demo product ZP5004 has active sales details and cannot be soft-deleted.';
    END IF;

    UPDATE public.customer
       SET is_deleted = CASE WHEN custno = 'ZC504' THEN TRUE ELSE FALSE END
     WHERE custno IN ('ZC501', 'ZC502', 'ZC503', 'ZC504')
       AND is_deleted IS DISTINCT FROM (custno = 'ZC504');

    UPDATE public.pricehist
       SET is_deleted = (prodcode = 'ZP5004')
     WHERE prodcode IN ('ZP5001', 'ZP5002', 'ZP5003', 'ZP5004')
       AND is_deleted IS DISTINCT FROM (prodcode = 'ZP5004');

    UPDATE public.product
       SET is_deleted = (prodcode = 'ZP5004')
     WHERE prodcode IN ('ZP5001', 'ZP5002', 'ZP5003', 'ZP5004')
       AND is_deleted IS DISTINCT FROM (prodcode = 'ZP5004');

    IF (SELECT count(*) FROM public.customer_active
         WHERE custno IN ('ZC501', 'ZC502', 'ZC503', 'ZC504')) <> 3
       OR (SELECT count(*) FROM public.product_active
            WHERE prodcode IN ('ZP5001', 'ZP5002', 'ZP5003', 'ZP5004')) <> 3
       OR (SELECT count(*) FROM public.pricehist_active
            WHERE prodcode IN ('ZP5001', 'ZP5002', 'ZP5003')) <> 12
       OR EXISTS (
           SELECT 1 FROM public.pricehist_active WHERE prodcode = 'ZP5004'
       ) THEN
        RAISE EXCEPTION
            'S2-DBA-05 seed rolled back: active views do not show the expected active demo rows.';
    END IF;

    IF public.price_as_of('ZP5001', CURRENT_DATE) IS DISTINCT FROM 13.75::NUMERIC(10, 2)
       OR public.price_as_of('ZP5001', DATE '2099-01-01') IS DISTINCT FROM 99.99::NUMERIC(10, 2) THEN
        RAISE EXCEPTION
            'S2-DBA-05 seed rolled back: price_as_of did not return the expected current and future prices for ZP5001.';
    END IF;

    RAISE NOTICE
        'S2-DBA-05 seed complete: 4 demo customers, 4 demo products, 16 price rows; 3 customers, 3 products, and 12 price rows active.';
END;
$$;

COMMIT;
