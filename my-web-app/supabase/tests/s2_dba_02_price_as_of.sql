-- Run after 20261122000500_s2_dba_02_price_as_of.sql.
-- Execute in a scratch/copy database as a database owner; all fixtures roll back.
BEGIN;
SET LOCAL search_path = public, pg_temp;

DO $$
DECLARE
    test_product VARCHAR(6);
    earlier_price NUMERIC(10, 2);
    today_price NUMERIC(10, 2);
    future_price NUMERIC(10, 2);
    absent_price NUMERIC(10, 2);
    current_view_price NUMERIC(10, 2);
    current_view_count INTEGER;
    attempt INTEGER;
    current_day DATE := CURRENT_DATE;
BEGIN
    IF to_regprocedure('public.price_as_of(character varying, date)') IS NULL
       OR to_regclass('public.v_product_current_price') IS NULL THEN
        RAISE EXCEPTION
            'S2-DBA-02 test requires public.price_as_of(VARCHAR, DATE) and public.v_product_current_price. Apply the migration first.';
    END IF;

    FOR attempt IN 1..50 LOOP
        test_product := 'T' || substr(md5(random()::TEXT || clock_timestamp()::TEXT), 1, 5);
        EXIT WHEN NOT EXISTS (
            SELECT 1 FROM public.product WHERE prodcode = test_product
        );
    END LOOP;
    IF EXISTS (SELECT 1 FROM public.product WHERE prodcode = test_product) THEN
        RAISE EXCEPTION 'S2-DBA-02 test could not allocate a temporary product code.';
    END IF;

    INSERT INTO public.product (prodcode, description, unit)
    VALUES (test_product, 'S2 Price Test', 'pc');

    INSERT INTO public.pricehist (prodcode, effdate, unitprice)
    VALUES
        (test_product, current_day - 10, 10.00),
        (test_product, current_day - 2, 12.50),
        (test_product, current_day + 10, 99.00);

    absent_price := public.price_as_of(test_product, current_day - 11);
    earlier_price := public.price_as_of(test_product, current_day - 5);
    today_price := public.price_as_of(test_product, current_day);
    future_price := public.price_as_of(test_product, current_day + 20);

    IF absent_price IS NOT NULL THEN
        RAISE EXCEPTION
            'S2-DBA-02 failed: no eligible price must return NULL, got %.',
            absent_price;
    END IF;
    IF earlier_price IS DISTINCT FROM 10.00::NUMERIC(10, 2) THEN
        RAISE EXCEPTION
            'S2-DBA-02 failed: expected earlier effective price 10.00, got %.',
            earlier_price;
    END IF;
    IF today_price IS DISTINCT FROM 12.50::NUMERIC(10, 2) THEN
        RAISE EXCEPTION
            'S2-DBA-02 failed: future price must be ignored and latest eligible price should be 12.50, got %.',
            today_price;
    END IF;
    IF future_price IS DISTINCT FROM 99.00::NUMERIC(10, 2) THEN
        RAISE EXCEPTION
            'S2-DBA-02 failed: the future price should apply on its effective date, got %.',
            future_price;
    END IF;

    SELECT unitprice
      INTO current_view_price
      FROM public.v_product_current_price
     WHERE prodcode = test_product;
    GET DIAGNOSTICS current_view_count = ROW_COUNT;
    IF current_view_count <> 1
       OR current_view_price IS DISTINCT FROM 12.50::NUMERIC(10, 2) THEN
        RAISE EXCEPTION
            'S2-DBA-02 failed: current-price view expected one row at 12.50, got count %, price %.',
            current_view_count,
            current_view_price;
    END IF;

    BEGIN
        INSERT INTO public.pricehist (prodcode, effdate, unitprice)
        VALUES (test_product, current_day - 2, 13.00);
        RAISE EXCEPTION
            'S2-DBA-02 failed: duplicate product/effective-date price was accepted.';
    EXCEPTION
        WHEN unique_violation THEN
            RAISE NOTICE
                'PASS: duplicate price for product % on % was rejected by the existing (effdate, prodcode) primary key.',
                test_product,
                current_day - 2;
    END;

    RAISE NOTICE
        'PASS: no eligible price returned NULL; as of %, 10.00 applied; as of today %, future 99.00 was ignored; and as of %, future 99.00 applied.',
        current_day - 11,
        today_price,
        current_day + 20;
    RAISE NOTICE
        'PASS: v_product_current_price returned % for temporary product %.',
        current_view_price,
        test_product;
END;
$$;

SELECT
    index_class.relname AS index_name,
    pg_get_indexdef(index_class.oid) AS index_definition
FROM pg_index AS index_row
JOIN pg_class AS index_class ON index_class.oid = index_row.indexrelid
WHERE index_row.indrelid = 'public.pricehist'::regclass
ORDER BY index_class.relname;

SELECT
    'S2-DBA-02 fixtures are temporary and will be rolled back.' AS test_result;

ROLLBACK;
