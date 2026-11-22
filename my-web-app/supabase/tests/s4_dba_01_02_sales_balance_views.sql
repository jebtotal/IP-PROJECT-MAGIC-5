-- Run after 20261122000800_s4_dba_01_02_sales_balance_views.sql.
-- Execute in a scratch/copy database as a database owner; all fixtures roll back.
BEGIN;
SET LOCAL search_path = public, pg_temp;

DO $$
DECLARE
    -- Reserved test keys (not in the 928-row source sample set)
    test_cust  VARCHAR(5)  := 'TC999';
    test_emp   VARCHAR(5)  := 'TE999';
    test_prod  VARCHAR(6)  := 'TP9991';
    test_prod2 VARCHAR(6)  := 'TP9992';
    -- Transaction numbers for each test case
    t_paid     VARCHAR(8)  := 'TS0001';
    t_partial  VARCHAR(8)  := 'TS0002';
    t_unpaid   VARCHAR(8)  := 'TS0003';
    t_overpaid VARCHAR(8)  := 'TS0004';
    t_nolines  VARCHAR(8)  := 'TS0005';
    t_deleted  VARCHAR(8)  := 'TS0006';
    -- Expected numeric results
    v_paid_total     NUMERIC(10,2) := 100.00;
    v_paid_paid      NUMERIC(10,2) := 100.00;
    v_partial_total  NUMERIC(10,2) := 200.00;
    v_partial_paid   NUMERIC(10,2) :=  50.00;
    v_unpaid_total   NUMERIC(10,2) := 150.00;
    v_overpaid_total NUMERIC(10,2) :=  80.00;
    v_overpaid_paid  NUMERIC(10,2) := 100.00;
BEGIN
    -- Pre-flight: confirm required objects exist
    IF to_regclass('public.sales') IS NULL
       OR to_regclass('public.salesdetail') IS NULL
       OR to_regclass('public.payment') IS NULL
       OR to_regclass('public.customer') IS NULL
       OR to_regclass('public.product') IS NULL
       OR to_regclass('public.pricehist') IS NULL
       OR to_regclass('public.employee') IS NULL
       OR to_regprocedure('public.price_as_of(VARCHAR, DATE)') IS NULL
       OR to_regclass('public.sales_active') IS NULL
       OR to_regclass('public.salesdetail_active') IS NULL
       OR to_regclass('public.payment_active') IS NULL
       OR to_regclass('public.customer_active') IS NULL THEN
        RAISE EXCEPTION
            'S4-DBA-01/02 test requires HOPE base tables, active views, and price_as_of. Apply migrations first.';
    END IF;

    IF to_regclass('public.v_sale_line_amounts') IS NULL
       OR to_regclass('public.v_sale_totals') IS NULL
       OR to_regclass('public.v_sale_payment_balance') IS NULL
       OR to_regclass('public.v_customer_payment_balance') IS NULL THEN
        RAISE EXCEPTION
            'S4-DBA-01/02 test requires the four new views. Apply the migration first.';
    END IF;
    -- Fixtures: employee, customer, products, price history
    INSERT INTO public.employee (empno, lastname, firstname, gender, birthdate, hiredate, sepdate)
    VALUES (test_emp, 'Tester', 'DBA', 'M', '1990-01-01', '2020-01-01', NULL)
    ON CONFLICT DO NOTHING;

    INSERT INTO public.customer (custno, custname, address, payterm)
    VALUES (test_cust, 'Test Customer Inc', '123 Test Lane', '30D')
    ON CONFLICT DO NOTHING;

    INSERT INTO public.product (prodcode, description, unit)
    VALUES (test_prod,  'Test Product One',  'pc'),
           (test_prod2, 'Test Product Two',  'ea')
    ON CONFLICT DO NOTHING;

    INSERT INTO public.pricehist (prodcode, effdate, unitprice)
    VALUES
        (test_prod,  '2020-01-01', 10.00),
        (test_prod2, '2020-01-01', 20.00)
    ON CONFLICT DO NOTHING;

    -- Sales
    -- TS0001: 2 lines x 10.00 = 100.00, paid 100.00  -> paid, balance 0
    INSERT INTO public.sales (transno, salesdate, custno, empno)
    VALUES (t_paid,  '2021-01-10', test_cust, test_emp)
    ON CONFLICT DO NOTHING;
    INSERT INTO public.salesdetail (transno, prodcode, quantity)
    VALUES (t_paid, test_prod, 10.00) ON CONFLICT DO NOTHING;

    -- TS0002: 1 line x 200.00 = 200.00, paid 50.00   -> partial, balance 150
    INSERT INTO public.sales (transno, salesdate, custno, empno)
    VALUES (t_partial, '2021-01-10', test_cust, test_emp)
    ON CONFLICT DO NOTHING;
    INSERT INTO public.salesdetail (transno, prodcode, quantity)
    VALUES (t_partial, test_prod2, 10.00) ON CONFLICT DO NOTHING;

    -- TS0003: 1 line x 150.00 = 150.00, no payments  -> unpaid, balance 150
    INSERT INTO public.sales (transno, salesdate, custno, empno)
    VALUES (t_unpaid,  '2021-01-10', test_cust, test_emp)
    ON CONFLICT DO NOTHING;
    INSERT INTO public.salesdetail (transno, prodcode, quantity)
    VALUES (t_unpaid, test_prod, 15.00) ON CONFLICT DO NOTHING;

    -- TS0004: 1 line x 80.00 = 80.00, paid 100.00    -> paid, balance -20 (overpayment)
    INSERT INTO public.sales (transno, salesdate, custno, empno)
    VALUES (t_overpaid, '2021-01-10', test_cust, test_emp)
    ON CONFLICT DO NOTHING;
    INSERT INTO public.salesdetail (transno, prodcode, quantity)
    VALUES (t_overpaid, test_prod, 8.00) ON CONFLICT DO NOTHING;

    -- TS0005: sale with no lines                    -> paid, total 0, balance 0
    INSERT INTO public.sales (transno, salesdate, custno, empno)
    VALUES (t_nolines, '2021-01-10', test_cust, test_emp)
    ON CONFLICT DO NOTHING;

    -- TS0006: soft-deleted sale                     -> excluded from all views
    INSERT INTO public.sales (transno, salesdate, custno, empno, is_deleted)
    VALUES (t_deleted, '2021-01-10', test_cust, test_emp, TRUE)
    ON CONFLICT DO NOTHING;

    -- Payments
    INSERT INTO public.payment (orno, paydate, amount, transno)
    VALUES ('TO9901', '2021-01-15', 100.00, t_paid)     ON CONFLICT DO NOTHING;
    INSERT INTO public.payment (orno, paydate, amount, transno)
    VALUES ('TO9902', '2021-01-15',  50.00, t_partial)  ON CONFLICT DO NOTHING;
    INSERT INTO public.payment (orno, paydate, amount, transno)
    VALUES ('TO9904', '2021-01-15', 100.00, t_overpaid) ON CONFLICT DO NOTHING;

    -- Soft-deleted payment on TS0002 -> must not reduce balance
    INSERT INTO public.payment (orno, paydate, amount, transno, is_deleted)
    VALUES ('TO9903', '2021-01-15', 9999.00, t_partial, TRUE) ON CONFLICT DO NOTHING;
    -- Assertions: v_sale_line_amounts
    DECLARE
        l_cnt   INTEGER;
        l_amt   NUMERIC(10,2);
    BEGIN
        SELECT count(*), SUM(line_amount)
          INTO l_cnt, l_amt
          FROM public.v_sale_line_amounts
         WHERE transno = t_paid;
        IF l_cnt <> 1 OR l_amt IS DISTINCT FROM 100.00::NUMERIC(10,2) THEN
            RAISE EXCEPTION 'S4-DBA-01 failed: v_sale_line_amounts for % expected 1 line at 100.00, got count %, sum %.', t_paid, l_cnt, l_amt;
        END IF;

        SELECT count(*) INTO l_cnt FROM public.v_sale_line_amounts WHERE transno = t_deleted;
        IF l_cnt <> 0 THEN
            RAISE EXCEPTION 'S4-DBA-01 failed: soft-deleted sale % appeared in line amounts.', t_deleted;
        END IF;

        RAISE NOTICE 'PASS: v_sale_line_amounts returns correct line amounts for % (10 x 10.00 = 100.00).', t_paid;
    END;

    -- Assertions: v_sale_totals
    DECLARE
        t_tot   NUMERIC(10,2);
    BEGIN
        SELECT total_amount INTO t_tot FROM public.v_sale_totals WHERE transno = t_paid;
        IF t_tot IS DISTINCT FROM 100.00::NUMERIC(10,2) THEN
            RAISE EXCEPTION 'S4-DBA-01 failed: v_sale_totals for % expected 100.00, got %.', t_paid, t_tot;
        END IF;

        SELECT total_amount INTO t_tot FROM public.v_sale_totals WHERE transno = t_partial;
        IF t_tot IS DISTINCT FROM 200.00::NUMERIC(10,2) THEN
            RAISE EXCEPTION 'S4-DBA-01 failed: v_sale_totals for % expected 200.00, got %.', t_partial, t_tot;
        END IF;

        SELECT total_amount INTO t_tot FROM public.v_sale_totals WHERE transno = t_nolines;
        IF t_tot IS DISTINCT FROM 0::NUMERIC(10,2) THEN
            RAISE EXCEPTION 'S4-DBA-01 failed: v_sale_totals for % (no lines) expected 0, got %.', t_nolines, t_tot;
        END IF;

        IF EXISTS (SELECT 1 FROM public.v_sale_totals WHERE transno = t_deleted) THEN
            RAISE EXCEPTION 'S4-DBA-01 failed: soft-deleted sale % appeared in totals.', t_deleted;
        END IF;

        RAISE NOTICE 'PASS: v_sale_totals returns correct totals (incl. no-lines sale at 0).';
    END;
    -- Assertions: v_sale_payment_balance (statuses + overpayment + no payments)
    DECLARE
        r_status  VARCHAR(10);
        r_balance NUMERIC(10,2);
        r_paid    NUMERIC(10,2);
        r_tot     NUMERIC(10,2);
    BEGIN
        -- TS0001: fully paid
        SELECT status, balance, total_paid INTO r_status, r_balance, r_paid
          FROM public.v_sale_payment_balance WHERE transno = t_paid;
        IF r_status IS DISTINCT FROM 'paid' OR r_balance IS DISTINCT FROM 0::NUMERIC(10,2)
           OR r_paid IS DISTINCT FROM 100.00::NUMERIC(10,2) THEN
            RAISE EXCEPTION 'S4-DBA-02 failed: % expected status=paid balance=0 paid=100, got status=% balance=% paid=%.', t_paid, r_status, r_balance, r_paid;
        END IF;

        -- TS0002: partial
        SELECT status, balance INTO r_status, r_balance
          FROM public.v_sale_payment_balance WHERE transno = t_partial;
        IF r_status IS DISTINCT FROM 'partial' OR r_balance IS DISTINCT FROM 150.00::NUMERIC(10,2) THEN
            RAISE EXCEPTION 'S4-DBA-02 failed: % expected status=partial balance=150, got status=% balance=%.', t_partial, r_status, r_balance;
        END IF;

        -- TS0003: unpaid (no payments)
        SELECT status, balance INTO r_status, r_balance
          FROM public.v_sale_payment_balance WHERE transno = t_unpaid;
        IF r_status IS DISTINCT FROM 'unpaid' OR r_balance IS DISTINCT FROM 150.00::NUMERIC(10,2) THEN
            RAISE EXCEPTION 'S4-DBA-02 failed: % expected status=unpaid balance=150, got status=% balance=%.', t_unpaid, r_status, r_balance;
        END IF;

        -- TS0004: overpaid
        SELECT status, balance INTO r_status, r_balance
          FROM public.v_sale_payment_balance WHERE transno = t_overpaid;
        IF r_status IS DISTINCT FROM 'paid' OR r_balance IS DISTINCT FROM -20.00::NUMERIC(10,2) THEN
            RAISE EXCEPTION 'S4-DBA-02 failed: % expected status=paid balance=-20 (overpayment), got status=% balance=%.', t_overpaid, r_status, r_balance;
        END IF;

        -- TS0005: no lines
        SELECT status, total_amount, balance INTO r_status, r_tot, r_balance
          FROM public.v_sale_payment_balance WHERE transno = t_nolines;
        IF r_status IS DISTINCT FROM 'paid' OR r_tot IS DISTINCT FROM 0::NUMERIC(10,2)
           OR r_balance IS DISTINCT FROM 0::NUMERIC(10,2) THEN
            RAISE EXCEPTION 'S4-DBA-02 failed: % (no lines) expected status=paid total=0 balance=0, got status=% total=% balance=%.', t_nolines, r_status, r_tot, r_balance;
        END IF;

        -- Soft-deleted sale excluded
        IF EXISTS (SELECT 1 FROM public.v_sale_payment_balance WHERE transno = t_deleted) THEN
            RAISE EXCEPTION 'S4-DBA-02 failed: soft-deleted sale % appeared in balance view.', t_deleted;
        END IF;

        -- Soft-deleted payment ignored: TS0002 should still be partial at balance 150
        SELECT balance INTO r_balance FROM public.v_sale_payment_balance WHERE transno = t_partial;
        IF r_balance IS DISTINCT FROM 150.00::NUMERIC(10,2) THEN
            RAISE EXCEPTION 'S4-DBA-02 failed: soft-deleted payment affected balance for %, got %.', t_partial, r_balance;
        END IF;

        RAISE NOTICE 'PASS: v_sale_payment_balance statuses correct (paid/partial/unpaid/paid-overpaid/paid-no-lines).';
    END;
    -- Assertions: v_customer_payment_balance
    DECLARE
        c_tot    NUMERIC(10,2);
        c_paid   NUMERIC(10,2);
        c_bal    NUMERIC(10,2);
        c_status VARCHAR(10);
    BEGIN
        SELECT total_amount, total_paid, balance, status
          INTO c_tot, c_paid, c_bal, c_status
          FROM public.v_customer_payment_balance
         WHERE custno = test_cust;
        -- Total: 100 + 200 + 150 + 80 + 0 = 530; Paid: 100 + 50 + 0 + 100 + 0 = 250; Balance: 280; Status: partial
        IF c_tot IS DISTINCT FROM 530.00::NUMERIC(10,2)
           OR c_paid IS DISTINCT FROM 250.00::NUMERIC(10,2)
           OR c_bal IS DISTINCT FROM 280.00::NUMERIC(10,2)
           OR c_status IS DISTINCT FROM 'partial' THEN
            RAISE EXCEPTION
                'S4-DBA-02 failed: customer % expected total=530 paid=250 balance=280 status=partial, got total=% paid=% balance=% status=%.',
                test_cust, c_tot, c_paid, c_bal, c_status;
        END IF;

        RAISE NOTICE 'PASS: v_customer_payment_balance roll-up correct (total=530 paid=250 balance=280 status=partial).';
    END;

    RAISE NOTICE 'PASS: All S4-DBA-01 and S4-DBA-02 assertions passed.';
END;
$$;

-- Display view results for inspection
SELECT 'v_sale_line_amounts' AS view_name, transno, prodcode, quantity, unitprice, line_amount
  FROM public.v_sale_line_amounts
 WHERE transno LIKE 'TS%'
 ORDER BY transno, prodcode;

SELECT 'v_sale_totals' AS view_name, transno, total_amount
  FROM public.v_sale_totals
 WHERE transno LIKE 'TS%'
 ORDER BY transno;

SELECT 'v_sale_payment_balance' AS view_name, transno, total_amount, total_paid, balance, status
  FROM public.v_sale_payment_balance
 WHERE transno LIKE 'TS%'
 ORDER BY transno;

SELECT 'v_customer_payment_balance' AS view_name, custno, custname, total_amount, total_paid, balance, status
  FROM public.v_customer_payment_balance
 WHERE custno = 'TC999';

SELECT 'S4-DBA-01/S4-DBA-02 fixtures are temporary and will be rolled back.' AS test_result;
ROLLBACK;