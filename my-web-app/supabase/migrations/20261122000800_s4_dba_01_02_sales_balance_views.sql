-- S4-DBA-01: Sales line amounts and transaction totals
-- S4-DBA-02: Payment balance per transaction and per customer
-- Views are read-only; no base tables are altered. Safe to re-run (CREATE OR REPLACE VIEW).
BEGIN;
SET LOCAL search_path = public, pg_temp;

-- ------------------------------------------------------------------
-- 1. Line amounts: quantity x unit price (as of sale date) per active line item
--    Uses public.price_as_of(prodcode, salesdate) for consistent effective pricing.
--    Excludes soft-deleted sales and soft-deleted line items.
-- ------------------------------------------------------------------
CREATE OR REPLACE VIEW public.v_sale_line_amounts
WITH (security_invoker = true)
AS
SELECT
    sd.transno,
    sd.prodcode,
    sd.quantity,
    public.price_as_of(sd.prodcode, s.salesdate) AS unitprice,
    (sd.quantity * public.price_as_of(sd.prodcode, s.salesdate))::NUMERIC(10,2) AS line_amount
FROM public.salesdetail_active AS sd
JOIN public.sales_active AS s
    ON s.transno = sd.transno;

-- ------------------------------------------------------------------
-- 2. Transaction totals: sum of line amounts per active sale.
--    Sales with no lines appear with total_amount = 0.
-- ------------------------------------------------------------------
CREATE OR REPLACE VIEW public.v_sale_totals
WITH (security_invoker = true)
AS
SELECT
    s.transno,
    COALESCE(SUM(la.line_amount), 0::NUMERIC(10,2))::NUMERIC(10,2) AS total_amount
FROM public.sales_active AS s
LEFT JOIN public.v_sale_line_amounts AS la
    ON la.transno = s.transno
GROUP BY s.transno;

-- ------------------------------------------------------------------
-- 3. Payment balance per transaction: total minus payments, with status.
--    Status: 'paid' when nothing owed or fully paid/overpaid,
--            'partial' when some paid but balance remains,
--            'unpaid' when no payments and balance remains.
--    Handles: no payments, overpayment, sales with no lines.
-- ------------------------------------------------------------------
CREATE OR REPLACE VIEW public.v_sale_payment_balance
WITH (security_invoker = true)
AS
SELECT
    t.transno,
    t.total_amount,
    COALESCE(p.total_paid, 0::NUMERIC(10,2))::NUMERIC(10,2) AS total_paid,
    (t.total_amount - COALESCE(p.total_paid, 0::NUMERIC(10,2)))::NUMERIC(10,2) AS balance,
    CASE
        WHEN t.total_amount = 0 THEN 'paid'
        WHEN (t.total_amount - COALESCE(p.total_paid, 0::NUMERIC(10,2))) <= 0 THEN 'paid'
        WHEN COALESCE(p.total_paid, 0::NUMERIC(10,2)) > 0 THEN 'partial'
        ELSE 'unpaid'
    END AS status
FROM public.v_sale_totals AS t
LEFT JOIN (
    SELECT transno, SUM(amount) AS total_paid
    FROM public.payment_active
    GROUP BY transno
) AS p
    ON p.transno = t.transno;

-- ------------------------------------------------------------------
-- 4. Customer roll-up: per-customer totals, payments, balance, status.
--    Aggregates all active sales for each active customer.
-- ------------------------------------------------------------------
CREATE OR REPLACE VIEW public.v_customer_payment_balance
WITH (security_invoker = true)
AS
SELECT
    c.custno,
    c.custname,
    COALESCE(SUM(tb.total_amount), 0::NUMERIC(10,2))::NUMERIC(10,2) AS total_amount,
    COALESCE(SUM(tb.total_paid), 0::NUMERIC(10,2))::NUMERIC(10,2) AS total_paid,
    (COALESCE(SUM(tb.total_amount), 0::NUMERIC(10,2)) - COALESCE(SUM(tb.total_paid), 0::NUMERIC(10,2)))::NUMERIC(10,2) AS balance,
    CASE
        WHEN COALESCE(SUM(tb.total_amount), 0::NUMERIC(10,2)) = 0 THEN 'paid'
        WHEN (COALESCE(SUM(tb.total_amount), 0::NUMERIC(10,2)) - COALESCE(SUM(tb.total_paid), 0::NUMERIC(10,2))) <= 0 THEN 'paid'
        WHEN COALESCE(SUM(tb.total_paid), 0::NUMERIC(10,2)) > 0 THEN 'partial'
        ELSE 'unpaid'
    END AS status
FROM public.customer_active AS c
LEFT JOIN public.sales_active AS s
    ON s.custno = c.custno
LEFT JOIN public.v_sale_payment_balance AS tb
    ON tb.transno = s.transno
GROUP BY c.custno, c.custname;

GRANT SELECT ON public.v_sale_line_amounts TO authenticated;
GRANT SELECT ON public.v_sale_totals TO authenticated;
GRANT SELECT ON public.v_sale_payment_balance TO authenticated;
GRANT SELECT ON public.v_customer_payment_balance TO authenticated;

COMMIT;
