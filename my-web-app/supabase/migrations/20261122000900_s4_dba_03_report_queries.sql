-- S4-DBA-03: Sprint 4 report queries
-- Seven reports: product master list, active employees, all employees, employee job history,
--                top customers, top products, top sales.
-- Reports 1-4 are views (no parameters). Reports 5-7 are table functions (date range + Top N).
-- Reuses views from S2-DBA-01/02, S3-DBA-01, and S4-DBA-01/02 instead of rewriting their logic.
-- Safe to re-run (CREATE OR REPLACE). Forward-only; no base tables are altered.
BEGIN;
SET LOCAL search_path = public, pg_temp;

-- ------------------------------------------------------------------
-- Pre-flight: confirm required upstream objects exist
-- ------------------------------------------------------------------
DO $$
BEGIN
    IF to_regclass('public.product_active') IS NULL
       OR to_regclass('public.v_product_current_price') IS NULL
       OR to_regclass('public.v_employee_current') IS NULL
       OR to_regclass('public.employee') IS NULL
       OR to_regclass('public.jobhistory') IS NULL
       OR to_regclass('public.job') IS NULL
       OR to_regclass('public.department') IS NULL
       OR to_regclass('public.sales_active') IS NULL
       OR to_regclass('public.salesdetail_active') IS NULL
       OR to_regclass('public.customer_active') IS NULL
       OR to_regclass('public.v_sale_totals') IS NULL
       OR to_regclass('public.v_sale_line_amounts') IS NULL
       OR to_regprocedure('public.price_as_of(VARCHAR, DATE)') IS NULL THEN
        RAISE EXCEPTION
            'S4-DBA-03 stopped: required upstream views/functions from S2-DBA-01/02, S3-DBA-01, or S4-DBA-01/02 are missing. Apply those migrations first.';
    END IF;
END;
$$;

-- ------------------------------------------------------------------
-- Report 1: Product Master List (view)
-- Active products with current price. Reuses v_product_current_price (S2-DBA-02).
-- ------------------------------------------------------------------
CREATE OR REPLACE VIEW public.v_report_product_master
WITH (security_invoker = true)
AS
SELECT
    p.prodcode,
    p.description,
    p.unit,
    vcp.unitprice AS current_price
FROM public.product_active AS p
JOIN public.v_product_current_price AS vcp
    ON vcp.prodcode = p.prodcode
ORDER BY p.prodcode;

-- ------------------------------------------------------------------
-- Report 2: Active Employees (view)
-- Active employees with current job and department. Reuses v_employee_current (S3-DBA-01).
-- ------------------------------------------------------------------
CREATE OR REPLACE VIEW public.v_report_active_employees
WITH (security_invoker = true)
AS
SELECT
    empno,
    firstname,
    lastname,
    gender,
    hiredate,
    jobcode,
    jobdesc,
    deptcode,
    deptname,
    effdate
FROM public.v_employee_current
ORDER BY empno;

-- ------------------------------------------------------------------
-- Report 3: All Employees (view)
-- All employees including separated and soft-deleted, with a status column.
-- Status: 'Active' / 'Separated' / 'Soft-Deleted'.
-- ------------------------------------------------------------------
CREATE OR REPLACE VIEW public.v_report_all_employees
WITH (security_invoker = true)
AS
SELECT
    e.empno,
    e.firstname,
    e.lastname,
    e.gender,
    e.hiredate,
    e.sepdate,
    CASE
        WHEN e.is_deleted THEN 'Soft-Deleted'
        WHEN e.sepdate IS NOT NULL THEN 'Separated'
        ELSE 'Active'
    END AS status
FROM public.employee AS e
ORDER BY e.empno;

-- ------------------------------------------------------------------
-- Report 4: Employee Job History (view)
-- Full timeline per employee: every job-history row with job and department.
-- Includes soft-deleted history rows (flagged via history_is_deleted).
-- ------------------------------------------------------------------
CREATE OR REPLACE VIEW public.v_report_employee_job_history
WITH (security_invoker = true)
AS
SELECT
    e.empno,
    e.firstname,
    e.lastname,
    h.jobcode,
    j.jobdesc,
    h.deptcode,
    d.deptname,
    h.effdate,
    h.salary,
    h.is_deleted AS history_is_deleted,
    e.is_deleted AS employee_is_deleted
FROM public.employee AS e
JOIN public.jobhistory AS h
    ON h.empno = e.empno
LEFT JOIN public.job AS j
    ON j.jobcode = h.jobcode
   AND NOT j.is_deleted
LEFT JOIN public.department AS d
    ON d.deptcode = h.deptcode
   AND NOT d.is_deleted
ORDER BY e.empno, h.effdate ASC, h.jobcode ASC;

GRANT SELECT ON public.v_report_product_master TO authenticated;
GRANT SELECT ON public.v_report_active_employees TO authenticated;
GRANT SELECT ON public.v_report_all_employees TO authenticated;
GRANT SELECT ON public.v_report_employee_job_history TO authenticated;

-- ------------------------------------------------------------------
-- Report 5: Top Customers (function)
-- Top N customers by total sales in a date range. Reuses v_sale_totals (S4-DBA-01/02)
-- and sales_active / customer_active. Excludes soft-deleted sales.
-- Tie-break: total_sales DESC, custno ASC (deterministic).
-- ------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.report_top_customers(
    p_date_start DATE,
    p_date_end DATE,
    p_top_n INTEGER
)
RETURNS TABLE (
    custno       VARCHAR(5),
    custname     VARCHAR(20),
    total_sales  NUMERIC(10,2),
    sale_count   INTEGER
)
LANGUAGE SQL
STABLE
SECURITY INVOKER
SET search_path = pg_catalog, public
AS $$
SELECT
    c.custno,
    c.custname,
    agg.total_sales,
    agg.sale_count
FROM public.customer_active AS c
JOIN (
    SELECT
        s.custno,
        SUM(vt.total_amount) AS total_sales,
        COUNT(*) AS sale_count
    FROM public.sales_active AS s
    JOIN public.v_sale_totals AS vt
        ON vt.transno = s.transno
    WHERE s.salesdate BETWEEN p_date_start AND p_date_end
    GROUP BY s.custno
) AS agg
    ON agg.custno = c.custno
ORDER BY agg.total_sales DESC, c.custno ASC
LIMIT p_top_n;
$$;

-- ------------------------------------------------------------------
-- Report 6: Top Products (function)
-- Top N products by quantity and amount in a date range. Reuses v_sale_line_amounts (S4-DBA-01/02)
-- and sales_active / product_active. Excludes soft-deleted sales and lines.
-- Tie-break: total_amount DESC, total_quantity DESC, prodcode ASC (deterministic).
-- ------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.report_top_products(
    p_date_start DATE,
    p_date_end DATE,
    p_top_n INTEGER
)
RETURNS TABLE (
    prodcode       VARCHAR(6),
    description    VARCHAR(30),
    unit           VARCHAR(3),
    total_quantity NUMERIC(10,2),
    total_amount   NUMERIC(10,2)
)
LANGUAGE SQL
STABLE
SECURITY INVOKER
SET search_path = pg_catalog, public
AS $$
SELECT
    p.prodcode,
    p.description,
    p.unit,
    agg.total_quantity,
    agg.total_amount
FROM public.product_active AS p
JOIN (
    SELECT
        sd.prodcode,
        SUM(sd.quantity) AS total_quantity,
        SUM(vsla.line_amount) AS total_amount
    FROM public.salesdetail_active AS sd
    JOIN public.sales_active AS s
        ON s.transno = sd.transno
       AND s.salesdate BETWEEN p_date_start AND p_date_end
    JOIN public.v_sale_line_amounts AS vsla
        ON vsla.transno = sd.transno
       AND vsla.prodcode = sd.prodcode
    GROUP BY sd.prodcode
) AS agg
    ON agg.prodcode = p.prodcode
ORDER BY agg.total_amount DESC, agg.total_quantity DESC, p.prodcode ASC
LIMIT p_top_n;
$$;

-- ------------------------------------------------------------------
-- Report 7: Top Sales (function)
-- Top N largest transactions in a date range. Reuses v_sale_totals (S4-DBA-01/02)
-- and sales_active / customer_active. Excludes soft-deleted sales.
-- Tie-break: total_amount DESC, transno ASC (deterministic).
-- ------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.report_top_sales(
    p_date_start DATE,
    p_date_end DATE,
    p_top_n INTEGER
)
RETURNS TABLE (
    transno       VARCHAR(8),
    salesdate     DATE,
    custno        VARCHAR(5),
    custname      VARCHAR(20),
    total_amount  NUMERIC(10,2)
)
LANGUAGE SQL
STABLE
SECURITY INVOKER
SET search_path = pg_catalog, public
AS $$
SELECT
    s.transno,
    s.salesdate,
    s.custno,
    c.custname,
    vt.total_amount
FROM public.sales_active AS s
JOIN public.v_sale_totals AS vt
    ON vt.transno = s.transno
JOIN public.customer_active AS c
    ON c.custno = s.custno
WHERE s.salesdate BETWEEN p_date_start AND p_date_end
ORDER BY vt.total_amount DESC, s.transno ASC
LIMIT p_top_n;
$$;

GRANT SELECT ON public.report_top_customers TO authenticated;
GRANT SELECT ON public.report_top_products TO authenticated;
GRANT SELECT ON public.report_top_sales TO authenticated;

COMMIT;