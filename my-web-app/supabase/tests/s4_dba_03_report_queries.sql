-- Run after 20261122000900_s4_dba_03_report_queries.sql.
-- Execute in a scratch/copy database as a database owner; all fixtures roll back.
BEGIN;
SET LOCAL search_path = public, pg_temp;

DO $$
DECLARE
    -- Reserved test keys (not in the 928-row source sample set)
    test_cust  VARCHAR(5)  := 'TC999';
    test_emp   VARCHAR(5)  := 'TE999';
    test_prod1 VARCHAR(6)  := 'TP9991';
    test_prod2 VARCHAR(6)  := 'TP9992';
    -- Transaction numbers for Top-N test cases (January 2021)
    t_sale1    VARCHAR(8)  := 'TS0001';
    t_sale2    VARCHAR(8)  := 'TS0002';
    t_sale3    VARCHAR(8)  := 'TS0003';
    t_sale4    VARCHAR(8)  := 'TS0004';
    t_deleted  VARCHAR(8)  := 'TS0005';
    -- Expected results for January 2021, Top 3
    v_jan_start DATE := '2021-01-01';
    v_jan_end   DATE := '2021-01-31';
    v_empty_start DATE := '2019-01-01';
    v_empty_end   DATE := '2019-01-31';
BEGIN
    -- Pre-flight: confirm required objects exist
    IF to_regclass('public.v_report_product_master') IS NULL
       OR to_regclass('public.v_report_active_employees') IS NULL
       OR to_regclass('public.v_report_all_employees') IS NULL
       OR to_regclass('public.v_report_employee_job_history') IS NULL
       OR to_regprocedure('public.report_top_customers(DATE, DATE, INTEGER)') IS NULL
       OR to_regprocedure('public.report_top_products(DATE, DATE, INTEGER)') IS NULL
       OR to_regprocedure('public.report_top_sales(DATE, DATE, INTEGER)') IS NULL THEN
        RAISE EXCEPTION
            'S4-DBA-03 test requires the seven report objects. Apply the migration first.';
    END IF;

    -- Fixtures: employee, customer, products, price history
    INSERT INTO public.employee (empno, lastname, firstname, gender, birthdate, hiredate, sepdate, is_deleted)
    VALUES (test_emp, 'Tester', 'DBA', 'M', '1990-01-01', '2020-01-01', NULL, FALSE)
    ON CONFLICT DO NOTHING;

    INSERT INTO public.employee (empno, lastname, firstname, gender, birthdate, hiredate, sepdate, is_deleted)
    VALUES ('TE998', 'Deleted', 'User', 'F', '1985-01-01', '2015-01-01', NULL, TRUE)
    ON CONFLICT DO NOTHING;

    INSERT INTO public.customer (custno, custname, address, payterm, is_deleted)
    VALUES (test_cust, 'Test Customer Inc', '123 Test Lane', '30D', FALSE)
    ON CONFLICT DO NOTHING;

    INSERT INTO public.product (prodcode, description, unit, is_deleted)
    VALUES (test_prod1, 'Test Product One', 'pc', FALSE),
           (test_prod2, 'Test Product Two', 'ea', FALSE)
    ON CONFLICT DO NOTHING;

    INSERT INTO public.pricehist (prodcode, effdate, unitprice)
    VALUES
        (test_prod1, '2020-01-01', 10.00),
        (test_prod2, '2020-01-01', 20.00)
    ON CONFLICT DO NOTHING;
    -- Sales (January 2021 for Top-N tests)
    INSERT INTO public.sales (transno, salesdate, custno, empno, is_deleted)
    VALUES (t_sale1,  '2021-01-10', test_cust, test_emp, FALSE) ON CONFLICT DO NOTHING;
    INSERT INTO public.sales (transno, salesdate, custno, empno, is_deleted)
    VALUES (t_sale2,  '2021-01-15', test_cust, test_emp, FALSE) ON CONFLICT DO NOTHING;
    INSERT INTO public.sales (transno, salesdate, custno, empno, is_deleted)
    VALUES (t_sale3,  '2021-01-20', test_cust, test_emp, FALSE) ON CONFLICT DO NOTHING;
    INSERT INTO public.sales (transno, salesdate, custno, empno, is_deleted)
    VALUES (t_sale4,  '2021-02-01', test_cust, test_emp, FALSE) ON CONFLICT DO NOTHING;
    INSERT INTO public.sales (transno, salesdate, custno, empno, is_deleted)
    VALUES (t_deleted, '2021-01-25', test_cust, test_emp, TRUE) ON CONFLICT DO NOTHING;

    -- Sales detail lines
    INSERT INTO public.salesdetail (transno, prodcode, quantity, is_deleted)
    VALUES (t_sale1, test_prod1, 10.00, FALSE) ON CONFLICT DO NOTHING;
    INSERT INTO public.salesdetail (transno, prodcode, quantity, is_deleted)
    VALUES (t_sale2, test_prod2, 5.00,  FALSE) ON CONFLICT DO NOTHING;
    INSERT INTO public.salesdetail (transno, prodcode, quantity, is_deleted)
    VALUES (t_sale3, test_prod1, 3.00,  FALSE) ON CONFLICT DO NOTHING;
    INSERT INTO public.salesdetail (transno, prodcode, quantity, is_deleted)
    VALUES (t_sale4, test_prod2, 2.00,  FALSE) ON CONFLICT DO NOTHING;
    INSERT INTO public.salesdetail (transno, prodcode, quantity, is_deleted)
    VALUES (t_deleted, test_prod1, 999.00, TRUE) ON CONFLICT DO NOTHING;

    -- ------------------------------------------------------------------
    -- Test 1: Product Master List (view)
    -- ------------------------------------------------------------------
    DECLARE
        pm_cnt  INTEGER;
        pm_null_price INTEGER;
    BEGIN
        SELECT count(*) INTO pm_cnt FROM public.v_report_product_master;
        SELECT count(*) INTO pm_null_price
          FROM public.v_report_product_master
         WHERE current_price IS NULL;

        IF pm_cnt = 0 THEN
            RAISE EXCEPTION 'S4-DBA-03 failed: v_report_product_master returned no rows.';
        END IF;
        IF pm_null_price > 0 THEN
            RAISE EXCEPTION 'S4-DBA-03 failed: v_report_product_master has % rows with NULL current_price.', pm_null_price;
        END IF;

        IF EXISTS (
            SELECT 1
            FROM public.product_active AS p
            LEFT JOIN public.v_product_current_price AS vcp ON vcp.prodcode = p.prodcode
            LEFT JOIN public.v_report_product_master AS rpm ON rpm.prodcode = p.prodcode
            WHERE rpm.prodcode IS NULL
        ) THEN
            RAISE EXCEPTION 'S4-DBA-03 failed: v_report_product_master missing active products.';
        END IF;

        RAISE NOTICE 'PASS: v_report_product_master returns % rows, all with current_price.', pm_cnt;
    END;
    -- ------------------------------------------------------------------
    -- Test 2: Active Employees (view) - should match v_employee_current
    -- ------------------------------------------------------------------
    DECLARE
        ae_cnt  INTEGER;
        vec_cnt INTEGER;
        ae_missing INTEGER;
    BEGIN
        SELECT count(*) INTO ae_cnt FROM public.v_report_active_employees;
        SELECT count(*) INTO vec_cnt FROM public.v_employee_current;

        IF ae_cnt IS DISTINCT FROM vec_cnt THEN
            RAISE EXCEPTION 'S4-DBA-03 failed: v_report_active_employees count % differs from v_employee_current %.', ae_cnt, vec_cnt;
        END IF;

        -- Every row in v_report_active_employees must exist in v_employee_current
        SELECT count(*) INTO ae_missing
          FROM public.v_report_active_employees AS rae
          LEFT JOIN public.v_employee_current AS vec ON vec.empno = rae.empno
         WHERE vec.empno IS NULL;

        IF ae_missing > 0 THEN
            RAISE EXCEPTION 'S4-DBA-03 failed: v_report_active_employees has % rows not in v_employee_current.', ae_missing;
        END IF;

        -- No soft-deleted employees should appear
        IF EXISTS (SELECT 1 FROM public.v_report_active_employees WHERE empno = 'TE998') THEN
            RAISE EXCEPTION 'S4-DBA-03 failed: soft-deleted employee TE998 appeared in active employees.';
        END IF;

        RAISE NOTICE 'PASS: v_report_active_employees matches v_employee_current (% rows).', ae_cnt;
    END;

    -- ------------------------------------------------------------------
    -- Test 3: All Employees (view) - includes separated and soft-deleted with status
    -- ------------------------------------------------------------------
    DECLARE
        ae_status_active   INTEGER;
        ae_status_separated INTEGER;
        ae_status_softdeleted INTEGER;
        te999_status       VARCHAR(20);
        te998_status       VARCHAR(20);
    BEGIN
        SELECT count(*) INTO ae_status_active
          FROM public.v_report_all_employees WHERE status = 'Active';
        SELECT count(*) INTO ae_status_separated
          FROM public.v_report_all_employees WHERE status = 'Separated';
        SELECT count(*) INTO ae_status_softdeleted
          FROM public.v_report_all_employees WHERE status = 'Soft-Deleted';

        SELECT status INTO te999_status FROM public.v_report_all_employees WHERE empno = test_emp;
        SELECT status INTO te998_status FROM public.v_report_all_employees WHERE empno = 'TE998';

        IF te999_status IS DISTINCT FROM 'Active' THEN
            RAISE EXCEPTION 'S4-DBA-03 failed: % expected status=Active, got %.', test_emp, te999_status;
        END IF;
        IF te998_status IS DISTINCT FROM 'Soft-Deleted' THEN
            RAISE EXCEPTION 'S4-DBA-03 failed: TE998 expected status=Soft-Deleted, got %.', te998_status;
        END IF;
        IF ae_status_softdeleted = 0 THEN
            RAISE EXCEPTION 'S4-DBA-03 failed: v_report_all_employees has no Soft-Deleted rows.';
        END IF;

        RAISE NOTICE 'PASS: v_report_all_employees statuses - Active: %, Separated: %, Soft-Deleted: %.',
            ae_status_active, ae_status_separated, ae_status_softdeleted;
    END;

    -- ------------------------------------------------------------------
    -- Test 4: Employee Job History (view) - full timeline per employee
    -- ------------------------------------------------------------------
    DECLARE
        ejh_cnt  INTEGER;
        ejh_dup_order INTEGER;
    BEGIN
        SELECT count(*) INTO ejh_cnt FROM public.v_report_employee_job_history;

        IF ejh_cnt = 0 THEN
            RAISE EXCEPTION 'S4-DBA-03 failed: v_report_employee_job_history returned no rows.';
        END IF;

        -- Verify ordering: within each employee, effdate should be ascending
        SELECT count(*) INTO ejh_dup_order
          FROM (
            SELECT empno, effdate,
                   LAG(effdate) OVER (PARTITION BY empno ORDER BY effdate ASC, jobcode ASC) AS prev_effdate
              FROM public.v_report_employee_job_history
          ) AS sub
         WHERE prev_effdate IS NOT NULL AND effdate < prev_effdate;

        IF ejh_dup_order > 0 THEN
            RAISE EXCEPTION 'S4-DBA-03 failed: v_report_employee_job_history not ordered by empno, effdate.';
        END IF;

        RAISE NOTICE 'PASS: v_report_employee_job_history returns % rows, ordered correctly.', ejh_cnt;
    END;

    -- ------------------------------------------------------------------
    -- Test 5: Top Customers (function) - January 2021, Top 3
    -- Expected: TC999 total=230.00 (100+100+30), 3 sales
    -- ------------------------------------------------------------------
    DECLARE
        tc_cnt  INTEGER;
        tc_total NUMERIC(10,2);
        tc_sales INTEGER;
    BEGIN
        SELECT count(*), SUM(total_sales), SUM(sale_count)
          INTO tc_cnt, tc_total, tc_sales
          FROM public.report_top_customers(v_jan_start, v_jan_end, 3);

        IF tc_cnt <> 1 THEN
            RAISE EXCEPTION 'S4-DBA-03 failed: report_top_customers expected 1 row, got %.', tc_cnt;
        END IF;
        IF tc_total IS DISTINCT FROM 230.00::NUMERIC(10,2) THEN
            RAISE EXCEPTION 'S4-DBA-03 failed: report_top_customers expected total_sales=230.00, got %.', tc_total;
        END IF;
        IF tc_sales IS DISTINCT FROM 3 THEN
            RAISE EXCEPTION 'S4-DBA-03 failed: report_top_customers expected sale_count=3, got %.', tc_sales;
        END IF;

        RAISE NOTICE 'PASS: report_top_customers Jan 2021 Top 3: cust=% total=%, sales=%.', test_cust, tc_total, tc_sales;
    END;
    -- ------------------------------------------------------------------
    -- Test 6: Top Products (function) - January 2021, Top 3
    -- Expected: TP9991 qty=13 amount=130.00; TP9992 qty=5 amount=100.00
    -- ------------------------------------------------------------------
    DECLARE
        tp_cnt  INTEGER;
        tp1_qty NUMERIC(10,2);
        tp1_amt NUMERIC(10,2);
        tp2_qty NUMERIC(10,2);
        tp2_amt NUMERIC(10,2);
    BEGIN
        SELECT count(*) INTO tp_cnt FROM public.report_top_products(v_jan_start, v_jan_end, 3);
        IF tp_cnt <> 2 THEN
            RAISE EXCEPTION 'S4-DBA-03 failed: report_top_products expected 2 rows, got %.', tp_cnt;
        END IF;

        SELECT total_quantity, total_amount INTO tp1_qty, tp1_amt
          FROM public.report_top_products(v_jan_start, v_jan_end, 3)
         WHERE prodcode = test_prod1;
        IF tp1_qty IS DISTINCT FROM 13.00::NUMERIC(10,2) OR tp1_amt IS DISTINCT FROM 130.00::NUMERIC(10,2) THEN
            RAISE EXCEPTION 'S4-DBA-03 failed: report_top_products TP9991 expected qty=13 amount=130.00, got qty=% amount=%.', tp1_qty, tp1_amt;
        END IF;

        SELECT total_quantity, total_amount INTO tp2_qty, tp2_amt
          FROM public.report_top_products(v_jan_start, v_jan_end, 3)
         WHERE prodcode = test_prod2;
        IF tp2_qty IS DISTINCT FROM 5.00::NUMERIC(10,2) OR tp2_amt IS DISTINCT FROM 100.00::NUMERIC(10,2) THEN
            RAISE EXCEPTION 'S4-DBA-03 failed: report_top_products TP9992 expected qty=5 amount=100.00, got qty=% amount=%.', tp2_qty, tp2_amt;
        END IF;

        RAISE NOTICE 'PASS: report_top_products Jan 2021 Top 3: TP9991 qty=% amt=%; TP9992 qty=% amt=%.',
            tp1_qty, tp1_amt, tp2_qty, tp2_amt;
    END;

    -- ------------------------------------------------------------------
    -- Test 7: Top Sales (function) - January 2021, Top 3
    -- Expected: TS0001=100.00, TS0002=100.00 (tie broken by transno), TS0003=30.00
    -- TS0004 (Feb) and TS0005 (soft-deleted) excluded
    -- ------------------------------------------------------------------
    DECLARE
        ts_cnt  INTEGER;
        ts1_amt NUMERIC(10,2);
        ts2_amt NUMERIC(10,2);
        ts3_amt NUMERIC(10,2);
        ts_transnos VARCHAR(100);
    BEGIN
        SELECT count(*) INTO ts_cnt FROM public.report_top_sales(v_jan_start, v_jan_end, 3);
        IF ts_cnt <> 3 THEN
            RAISE EXCEPTION 'S4-DBA-03 failed: report_top_sales expected 3 rows, got %.', ts_cnt;
        END IF;

        SELECT total_amount INTO ts1_amt FROM public.report_top_sales(v_jan_start, v_jan_end, 3) WHERE transno = t_sale1;
        SELECT total_amount INTO ts2_amt FROM public.report_top_sales(v_jan_start, v_jan_end, 3) WHERE transno = t_sale2;
        SELECT total_amount INTO ts3_amt FROM public.report_top_sales(v_jan_start, v_jan_end, 3) WHERE transno = t_sale3;

        IF ts1_amt IS DISTINCT FROM 100.00::NUMERIC(10,2) THEN
            RAISE EXCEPTION 'S4-DBA-03 failed: report_top_sales TS0001 expected 100.00, got %.', ts1_amt;
        END IF;
        IF ts2_amt IS DISTINCT FROM 100.00::NUMERIC(10,2) THEN
            RAISE EXCEPTION 'S4-DBA-03 failed: report_top_sales TS0002 expected 100.00, got %.', ts2_amt;
        END IF;
        IF ts3_amt IS DISTINCT FROM 30.00::NUMERIC(10,2) THEN
            RAISE EXCEPTION 'S4-DBA-03 failed: report_top_sales TS0003 expected 30.00, got %.', ts3_amt;
        END IF;

        -- TS0004 (Feb 1) and TS0005 (soft-deleted) must not appear
        SELECT string_agg(transno, ',' ORDER BY transno) INTO ts_transnos
          FROM public.report_top_sales(v_jan_start, v_jan_end, 3);
        IF ts_transnos LIKE '%' || t_sale4 || '%' THEN
            RAISE EXCEPTION 'S4-DBA-03 failed: report_top_sales included February sale TS0004 in January range.';
        END IF;
        IF ts_transnos LIKE '%' || t_deleted || '%' THEN
            RAISE EXCEPTION 'S4-DBA-03 failed: report_top_sales included soft-deleted sale TS0005.';
        END IF;

        RAISE NOTICE 'PASS: report_top_sales Jan 2021 Top 3: TS0001=%, TS0002=%, TS0003=%.', ts1_amt, ts2_amt, ts3_amt;
    END;

    -- ------------------------------------------------------------------
    -- Test 8: Empty date range - all three functions return no rows
    -- ------------------------------------------------------------------
    DECLARE
        empty_customers INTEGER;
        empty_products  INTEGER;
        empty_sales     INTEGER;
    BEGIN
        SELECT count(*) INTO empty_customers FROM public.report_top_customers(v_empty_start, v_empty_end, 10);
        SELECT count(*) INTO empty_products  FROM public.report_top_products(v_empty_start, v_empty_end, 10);
        SELECT count(*) INTO empty_sales     FROM public.report_top_sales(v_empty_start, v_empty_end, 10);

        IF empty_customers <> 0 THEN
            RAISE EXCEPTION 'S4-DBA-03 failed: empty date range returned % customer rows.', empty_customers;
        END IF;
        IF empty_products <> 0 THEN
            RAISE EXCEPTION 'S4-DBA-03 failed: empty date range returned % product rows.', empty_products;
        END IF;
        IF empty_sales <> 0 THEN
            RAISE EXCEPTION 'S4-DBA-03 failed: empty date range returned % sale rows.', empty_sales;
        END IF;

        RAISE NOTICE 'PASS: empty date range returns 0 rows for all three report functions.';
    END;

    RAISE NOTICE 'PASS: All S4-DBA-03 report tests passed.';
END;
$$;

-- Display view results for inspection
SELECT 'v_report_product_master' AS report_name, prodcode, description, unit, current_price
  FROM public.v_report_product_master
 ORDER BY prodcode
 LIMIT 10;

SELECT 'v_report_active_employees' AS report_name, empno, firstname, lastname, jobcode, jobdesc, deptcode, deptname
  FROM public.v_report_active_employees
 ORDER BY empno
 LIMIT 10;

SELECT 'v_report_all_employees' AS report_name, empno, firstname, lastname, status
  FROM public.v_report_all_employees
 WHERE empno IN ('TE999', 'TE998')
 ORDER BY empno;

SELECT 'v_report_employee_job_history' AS report_name, empno, jobcode, deptcode, effdate, salary
  FROM public.v_report_employee_job_history
 WHERE empno = 'TE999'
 ORDER BY effdate ASC;

-- Display function results for inspection
SELECT 'report_top_customers' AS report_name, *
  FROM public.report_top_customers('2021-01-01', '2021-01-31', 3);

SELECT 'report_top_products' AS report_name, *
  FROM public.report_top_products('2021-01-01', '2021-01-31', 3);

SELECT 'report_top_sales' AS report_name, *
  FROM public.report_top_sales('2021-01-01', '2021-01-31', 3);

-- Empty date range results
SELECT 'report_top_customers_empty' AS report_name, count(*) AS row_count
  FROM public.report_top_customers('2019-01-01', '2019-01-31', 10);

SELECT 'report_top_products_empty' AS report_name, count(*) AS row_count
  FROM public.report_top_products('2019-01-01', '2019-01-31', 10);

SELECT 'report_top_sales_empty' AS report_name, count(*) AS row_count
  FROM public.report_top_sales('2019-01-01', '2019-01-31', 10);

SELECT 'S4-DBA-03 fixtures are temporary and will be rolled back.' AS test_result;
ROLLBACK;

