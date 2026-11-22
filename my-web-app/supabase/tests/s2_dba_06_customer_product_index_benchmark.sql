-- Scratch-only benchmark for the Customer/Product list queries.
-- All generated rows and candidate indexes are temporary and rolled back.
BEGIN;
SET LOCAL search_path = pg_temp, public;

DO $$
BEGIN
    IF to_regclass('public.customer_active') IS NULL
       OR to_regclass('public.product_active') IS NULL
       OR to_regclass('public.customer') IS NULL
       OR to_regclass('public.product') IS NULL THEN
        RAISE EXCEPTION
            'S2-DBA-06 benchmark stopped: apply the Customer/Product schema and active-view migrations first.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM pg_index AS index_row
          JOIN pg_class AS index_class ON index_class.oid = index_row.indexrelid
          JOIN pg_am AS access_method ON access_method.oid = index_class.relam
         WHERE index_row.indrelid = 'public.customer'::REGCLASS
           AND index_row.indisvalid
           AND index_row.indisready
           AND access_method.amname = 'btree'
           AND index_row.indnkeyatts = 1
           AND index_row.indkey[0] = (
               SELECT attribute.attnum
                 FROM pg_attribute AS attribute
                WHERE attribute.attrelid = 'public.customer'::REGCLASS
                  AND attribute.attname = 'custno'
           )
           AND pg_get_expr(index_row.indpred, index_row.indrelid) = 'is_deleted'
    ) OR NOT EXISTS (
        SELECT 1
          FROM pg_index AS index_row
          JOIN pg_class AS index_class ON index_class.oid = index_row.indexrelid
          JOIN pg_am AS access_method ON access_method.oid = index_class.relam
         WHERE index_row.indrelid = 'public.product'::REGCLASS
           AND index_row.indisvalid
           AND index_row.indisready
           AND access_method.amname = 'btree'
           AND index_row.indnkeyatts = 1
           AND index_row.indkey[0] = (
               SELECT attribute.attnum
                 FROM pg_attribute AS attribute
                WHERE attribute.attrelid = 'public.product'::REGCLASS
                  AND attribute.attname = 'prodcode'
           )
           AND pg_get_expr(index_row.indpred, index_row.indrelid) = 'is_deleted'
    ) THEN
        RAISE EXCEPTION
            'S2-DBA-06 benchmark stopped: apply the S2-DBA-06 migration first.';
    END IF;
END;
$$;

CREATE TEMP TABLE benchmark_customer (LIKE public.customer INCLUDING DEFAULTS);
CREATE TEMP TABLE benchmark_product (LIKE public.product INCLUDING DEFAULTS);
ALTER TABLE pg_temp.benchmark_customer ADD PRIMARY KEY (custno);
ALTER TABLE pg_temp.benchmark_product ADD PRIMARY KEY (prodcode);

INSERT INTO pg_temp.benchmark_customer
    (custno, custname, address, payterm, is_deleted, stamp)
SELECT custno, custname, address, payterm, is_deleted, stamp
  FROM public.customer;

INSERT INTO pg_temp.benchmark_product
    (prodcode, description, unit, is_deleted, stamp)
SELECT prodcode, description, unit, is_deleted, stamp
  FROM public.product;

INSERT INTO pg_temp.benchmark_customer
    (custno, custname, address, payterm, is_deleted, stamp)
SELECT 'T' || lpad(number::TEXT, 4, '0'),
       'Demo Customer ' || number,
       number || ' Example Ave, Test City',
       (ARRAY['COD', '30D', '45D'])[1 + (number % 3)],
       number % 100 = 0,
       'ADD synthetic benchmark'
  FROM generate_series(0, 4999) AS number;

INSERT INTO pg_temp.benchmark_product
    (prodcode, description, unit, is_deleted, stamp)
SELECT 'T' || lpad(number::TEXT, 5, '0'),
       'Demo Product ' || number,
       (ARRAY['pc', 'ea', 'mtr', 'pkg', 'ltr'])[1 + (number % 5)],
       number % 100 = 0,
       'ADD synthetic benchmark'
  FROM generate_series(0, 4999) AS number;

CREATE TEMP VIEW benchmark_customer_active AS
SELECT * FROM pg_temp.benchmark_customer WHERE NOT is_deleted;

CREATE TEMP VIEW benchmark_product_active AS
SELECT * FROM pg_temp.benchmark_product WHERE NOT is_deleted;

ANALYZE pg_temp.benchmark_customer;
ANALYZE pg_temp.benchmark_product;

SELECT 'Rows in disposable benchmark tables' AS section, entity, total_rows, inactive_rows
FROM (
    SELECT 'Customer' AS entity,
           count(*) AS total_rows,
           count(*) FILTER (WHERE is_deleted) AS inactive_rows
      FROM pg_temp.benchmark_customer
    UNION ALL
    SELECT 'Product',
           count(*),
           count(*) FILTER (WHERE is_deleted)
      FROM pg_temp.benchmark_product
) AS counts
ORDER BY entity;

SELECT 'BEFORE: active Customer list fetch' AS benchmark;
EXPLAIN (ANALYZE, BUFFERS, TIMING ON, SUMMARY ON)
SELECT custno, custname, address, payterm
  FROM pg_temp.benchmark_customer_active;

SELECT 'BEFORE: active Product list fetch' AS benchmark;
EXPLAIN (ANALYZE, BUFFERS, TIMING ON, SUMMARY ON)
SELECT prodcode, description, unit
  FROM pg_temp.benchmark_product_active;

SELECT 'BEFORE: inactive Customer admin filter' AS benchmark;
EXPLAIN (ANALYZE, BUFFERS, TIMING ON, SUMMARY ON)
SELECT custno, custname, address, payterm, is_deleted, stamp
  FROM pg_temp.benchmark_customer
 WHERE is_deleted = TRUE;

SELECT 'BEFORE: inactive Product admin filter' AS benchmark;
EXPLAIN (ANALYZE, BUFFERS, TIMING ON, SUMMARY ON)
SELECT prodcode, description, unit, is_deleted, stamp
  FROM pg_temp.benchmark_product
 WHERE is_deleted = TRUE;

CREATE INDEX benchmark_customer_inactive_idx
    ON pg_temp.benchmark_customer (custno)
    WHERE is_deleted;

CREATE INDEX benchmark_product_inactive_idx
    ON pg_temp.benchmark_product (prodcode)
    WHERE is_deleted;

ANALYZE pg_temp.benchmark_customer;
ANALYZE pg_temp.benchmark_product;

SELECT 'AFTER: active Customer list fetch' AS benchmark;
EXPLAIN (ANALYZE, BUFFERS, TIMING ON, SUMMARY ON)
SELECT custno, custname, address, payterm
  FROM pg_temp.benchmark_customer_active;

SELECT 'AFTER: active Product list fetch' AS benchmark;
EXPLAIN (ANALYZE, BUFFERS, TIMING ON, SUMMARY ON)
SELECT prodcode, description, unit
  FROM pg_temp.benchmark_product_active;

SELECT 'AFTER: inactive Customer admin filter' AS benchmark;
EXPLAIN (ANALYZE, BUFFERS, TIMING ON, SUMMARY ON)
SELECT custno, custname, address, payterm, is_deleted, stamp
  FROM pg_temp.benchmark_customer
 WHERE is_deleted = TRUE;

SELECT 'AFTER: inactive Product admin filter' AS benchmark;
EXPLAIN (ANALYZE, BUFFERS, TIMING ON, SUMMARY ON)
SELECT prodcode, description, unit, is_deleted, stamp
  FROM pg_temp.benchmark_product
 WHERE is_deleted = TRUE;

ROLLBACK;
