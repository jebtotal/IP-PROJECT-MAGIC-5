-- Add per-report permission-checked data for the Reports workspace.
BEGIN;
SET LOCAL search_path = public, pg_temp;

DO $$
DECLARE
    missing_columns TEXT;
    mismatched_rights TEXT;
BEGIN
    IF to_regprocedure('public.hope_can_access(text,text,text)') IS NULL
       OR to_regprocedure('public.price_as_of(character varying,date)') IS NULL
       OR to_regclass('public.v_employee_current') IS NULL
       OR to_regclass('public.v_sale_totals') IS NULL THEN
        RAISE EXCEPTION
            'S4-BLD-04 stopped: apply HOPE app access, employee-current, price-as-of, and Sales balance migrations first.';
    END IF;

    WITH required_columns(table_name, column_name) AS (
        VALUES
            ('product', 'prodcode'),
            ('product', 'description'),
            ('product', 'unit'),
            ('product', 'is_deleted'),
            ('employee', 'empno'),
            ('employee', 'firstname'),
            ('employee', 'lastname'),
            ('employee', 'hiredate'),
            ('employee', 'sepdate'),
            ('employee', 'is_deleted'),
            ('jobhistory', 'empno'),
            ('jobhistory', 'jobcode'),
            ('jobhistory', 'deptcode'),
            ('jobhistory', 'effdate'),
            ('jobhistory', 'salary'),
            ('jobhistory', 'is_deleted'),
            ('job', 'jobcode'),
            ('job', 'jobdesc'),
            ('job', 'is_deleted'),
            ('department', 'deptcode'),
            ('department', 'deptname'),
            ('department', 'is_deleted'),
            ('customer', 'custno'),
            ('customer', 'custname'),
            ('customer', 'is_deleted'),
            ('sales', 'transno'),
            ('sales', 'salesdate'),
            ('sales', 'custno'),
            ('sales', 'empno'),
            ('sales', 'is_deleted'),
            ('salesdetail', 'transno'),
            ('salesdetail', 'prodcode'),
            ('salesdetail', 'quantity'),
            ('salesdetail', 'is_deleted')
    )
    SELECT string_agg(
               required.table_name || '.' || required.column_name,
               ', ' ORDER BY required.table_name, required.column_name
           )
      INTO missing_columns
      FROM required_columns AS required
      LEFT JOIN information_schema.columns AS actual
        ON actual.table_schema = 'public'
       AND actual.table_name = required.table_name
       AND actual.column_name = required.column_name
     WHERE actual.column_name IS NULL;

    IF missing_columns IS NOT NULL THEN
        RAISE EXCEPTION
            'S4-BLD-04 stopped: required report columns are missing: %.',
            missing_columns;
    END IF;

    IF to_regclass('public.right_catalog') IS NULL THEN
        RAISE EXCEPTION 'S4-BLD-04 stopped: public.right_catalog is required.';
    END IF;
END;
$$;

INSERT INTO public.right_catalog (right_code, module_code, resource_code, action)
VALUES
    ('reports.productsMaster.view', 'reports', 'products_master', 'view'),
    ('reports.activeEmployees.view', 'reports', 'active_employees', 'view'),
    ('reports.allEmployees.view', 'reports', 'all_employees', 'view'),
    ('reports.employeeJobHistory.view', 'reports', 'employee_job_history', 'view'),
    ('reports.topCustomers.view', 'reports', 'top_customers', 'view'),
    ('reports.topProducts.view', 'reports', 'top_products', 'view'),
    ('reports.topSales.view', 'reports', 'top_sales', 'view')
ON CONFLICT (right_code) DO NOTHING;

DO $$
DECLARE
    mismatched_rights TEXT;
BEGIN
    SELECT string_agg(expected.right_code, ', ' ORDER BY expected.right_code)
      INTO mismatched_rights
      FROM (
          VALUES
              ('reports.productsMaster.view', 'reports', 'products_master', 'view'),
              ('reports.activeEmployees.view', 'reports', 'active_employees', 'view'),
              ('reports.allEmployees.view', 'reports', 'all_employees', 'view'),
              ('reports.employeeJobHistory.view', 'reports', 'employee_job_history', 'view'),
              ('reports.topCustomers.view', 'reports', 'top_customers', 'view'),
              ('reports.topProducts.view', 'reports', 'top_products', 'view'),
              ('reports.topSales.view', 'reports', 'top_sales', 'view')
      ) AS expected(right_code, module_code, resource_code, action)
      LEFT JOIN public.right_catalog AS actual
        ON actual.right_code = expected.right_code
       AND actual.module_code = expected.module_code
       AND actual.resource_code = expected.resource_code
       AND actual.action = expected.action
     WHERE actual.right_code IS NULL;

    IF mismatched_rights IS NOT NULL THEN
        RAISE EXCEPTION
            'S4-BLD-04 stopped: report rights catalogue conflicts with: %.',
            mismatched_rights;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.hope_run_report(
    p_report TEXT,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL,
    p_top_n INTEGER DEFAULT 10,
    p_empno TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public, auth
AS $$
DECLARE
    v_resource TEXT;
    v_rows JSONB;
    v_employee_options JSONB := '[]'::JSONB;
    v_business_date DATE := (now() AT TIME ZONE 'Asia/Manila')::DATE;
BEGIN
    v_resource := CASE p_report
        WHEN 'products_master' THEN 'products_master'
        WHEN 'active_employees' THEN 'active_employees'
        WHEN 'all_employees' THEN 'all_employees'
        WHEN 'employee_job_history' THEN 'employee_job_history'
        WHEN 'top_customers' THEN 'top_customers'
        WHEN 'top_products' THEN 'top_products'
        WHEN 'top_sales' THEN 'top_sales'
        ELSE NULL
    END;

    IF v_resource IS NULL THEN
        RAISE EXCEPTION 'Unknown report.'
            USING ERRCODE = '22023';
    END IF;

    IF NOT public.hope_can_access('reports', 'reports', 'view')
       OR NOT public.hope_can_access('reports', v_resource, 'view') THEN
        RAISE EXCEPTION 'Reports View and the report-specific right are required.'
            USING ERRCODE = '42501';
    END IF;

    IF p_report IN ('top_customers', 'top_products', 'top_sales')
       AND (
           p_start_date IS NULL
           OR p_end_date IS NULL
           OR p_end_date < p_start_date
           OR p_top_n IS NULL
           OR p_top_n < 1
           OR p_top_n > 100
       ) THEN
        RAISE EXCEPTION 'A valid date range and Top N from 1 to 100 are required.'
            USING ERRCODE = '22023';
    END IF;

    IF p_report = 'products_master' THEN
        SELECT COALESCE(
                   jsonb_agg(
                       jsonb_build_object(
                           'productCode', p.prodcode,
                           'description', p.description,
                           'unit', p.unit,
                           'unitPrice', public.price_as_of(p.prodcode, v_business_date)
                       )
                       ORDER BY p.prodcode
                   ),
                   '[]'::JSONB
               )
          INTO v_rows
          FROM public.product AS p
         WHERE NOT p.is_deleted;

    ELSIF p_report IN ('active_employees', 'all_employees') THEN
        SELECT COALESCE(
                   jsonb_agg(
                       jsonb_build_object(
                           'employeeNo', employee_view.empno,
                           'fullName', COALESCE(
                               NULLIF(concat_ws(' ', NULLIF(btrim(employee_view.firstname), ''),
                                                NULLIF(btrim(employee_view.lastname), '')), ''),
                               employee_view.empno
                           ),
                           'gender', employee_view.gender,
                           'hireDate', employee_view.hiredate,
                           'separationDate', employee.sepdate,
                           'job', employee_view.jobdesc,
                           'department', employee_view.deptname,
                           'status', CASE
                               WHEN employee.sepdate IS NULL OR employee.sepdate >= v_business_date
                                   THEN 'Active'
                               ELSE 'Separated'
                           END
                       )
                       ORDER BY employee_view.lastname NULLS LAST,
                                employee_view.firstname NULLS LAST,
                                employee_view.empno
                   ),
                   '[]'::JSONB
               )
          INTO v_rows
          FROM public.v_employee_current AS employee_view
          JOIN public.employee AS employee ON employee.empno = employee_view.empno
         WHERE p_report = 'all_employees'
            OR employee.sepdate IS NULL
            OR employee.sepdate >= v_business_date;

    ELSIF p_report = 'employee_job_history' THEN
        SELECT COALESCE(
                   jsonb_agg(
                       jsonb_build_object(
                           'employeeNo', e.empno,
                           'fullName', COALESCE(
                               NULLIF(concat_ws(' ', NULLIF(btrim(e.firstname), ''),
                                                NULLIF(btrim(e.lastname), '')), ''),
                               e.empno
                           )
                       )
                       ORDER BY e.lastname NULLS LAST, e.firstname NULLS LAST, e.empno
                   ),
                   '[]'::JSONB
               )
          INTO v_employee_options
          FROM public.employee AS e
         WHERE NOT e.is_deleted;

        IF p_empno IS NULL OR btrim(p_empno) = '' THEN
            v_rows := '[]'::JSONB;
        ELSE
            IF NOT EXISTS (
                SELECT 1 FROM public.employee AS e
                 WHERE e.empno = btrim(p_empno)
                   AND NOT e.is_deleted
            ) THEN
                RAISE EXCEPTION 'Active employee not found.'
                    USING ERRCODE = 'P0002';
            END IF;

            SELECT COALESCE(
                       jsonb_agg(
                           jsonb_build_object(
                               'employeeNo', history.empno,
                               'effectiveDate', history.effdate,
                               'jobCode', history.jobcode,
                               'job', j.jobdesc,
                               'departmentCode', history.deptcode,
                               'department', d.deptname,
                               'salary', history.salary
                           )
                           ORDER BY history.effdate DESC, history.jobcode DESC
                       ),
                       '[]'::JSONB
                   )
              INTO v_rows
              FROM public.jobhistory AS history
              LEFT JOIN public.job AS j
                ON j.jobcode = history.jobcode AND NOT j.is_deleted
              LEFT JOIN public.department AS d
                ON d.deptcode = history.deptcode AND NOT d.is_deleted
             WHERE history.empno = btrim(p_empno)
               AND NOT history.is_deleted;
        END IF;

    ELSIF p_report = 'top_customers' THEN
        SELECT COALESCE(
                   jsonb_agg(to_jsonb(r) ORDER BY r.total_amount DESC, r.customer_no),
                   '[]'::JSONB
               )
          INTO v_rows
          FROM (
              SELECT c.custno AS customer_no,
                     c.custname AS customer_name,
                     COUNT(s.transno)::BIGINT AS transaction_count,
                     SUM(t.total_amount)::NUMERIC(12,2) AS total_amount
                FROM public.sales_active AS s
                JOIN public.customer_active AS c ON c.custno = s.custno
                JOIN public.v_sale_totals AS t ON t.transno = s.transno
               WHERE s.salesdate BETWEEN p_start_date AND p_end_date
               GROUP BY c.custno, c.custname
               ORDER BY total_amount DESC, c.custno
               LIMIT p_top_n
          ) AS r;

    ELSIF p_report = 'top_products' THEN
        SELECT COALESCE(
                   jsonb_agg(to_jsonb(r) ORDER BY r.revenue DESC, r.product_code),
                   '[]'::JSONB
               )
          INTO v_rows
          FROM (
              SELECT p.prodcode AS product_code,
                     p.description,
                     p.unit,
                     SUM(sd.quantity)::NUMERIC(12,2) AS quantity_sold,
                     SUM(sd.quantity * public.price_as_of(p.prodcode, s.salesdate))
                         ::NUMERIC(12,2) AS revenue
                FROM public.sales_active AS s
                JOIN public.salesdetail_active AS sd ON sd.transno = s.transno
                JOIN public.product_active AS p ON p.prodcode = sd.prodcode
               WHERE s.salesdate BETWEEN p_start_date AND p_end_date
               GROUP BY p.prodcode, p.description, p.unit
               ORDER BY revenue DESC, p.prodcode
               LIMIT p_top_n
          ) AS r;

    ELSIF p_report = 'top_sales' THEN
        SELECT COALESCE(
                   jsonb_agg(to_jsonb(r) ORDER BY r.total_amount DESC, r.transaction_no),
                   '[]'::JSONB
               )
          INTO v_rows
          FROM (
              SELECT s.transno AS transaction_no,
                     s.salesdate AS sale_date,
                     c.custname AS customer_name,
                     COALESCE(
                         NULLIF(concat_ws(' ', NULLIF(btrim(e.firstname), ''),
                                          NULLIF(btrim(e.lastname), '')), ''),
                         e.empno
                     ) AS salesperson,
                     t.total_amount
                FROM public.sales_active AS s
                LEFT JOIN public.customer_active AS c ON c.custno = s.custno
                LEFT JOIN public.employee AS e ON e.empno = s.empno
                JOIN public.v_sale_totals AS t ON t.transno = s.transno
               WHERE s.salesdate BETWEEN p_start_date AND p_end_date
               ORDER BY t.total_amount DESC, s.transno
               LIMIT p_top_n
          ) AS r;
    END IF;

    RETURN jsonb_build_object(
        'rows', COALESCE(v_rows, '[]'::JSONB),
        'employeeOptions', v_employee_options
    );
END;
$$;

REVOKE ALL ON FUNCTION public.hope_run_report(TEXT, DATE, DATE, INTEGER, TEXT)
    FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.hope_run_report(TEXT, DATE, DATE, INTEGER, TEXT)
    TO authenticated;

COMMIT;
