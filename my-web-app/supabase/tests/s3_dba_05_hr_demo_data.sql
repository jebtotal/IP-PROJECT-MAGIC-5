-- Run after applying supabase/seeds/s3_dba_05_hr_demo_data.sql.
-- Read-only assertions and reports for the synthetic HR demo fixtures.
BEGIN;
SET LOCAL search_path = public, pg_temp;

DO $$
DECLARE
    current_row RECORD;
BEGIN
    IF to_regclass('public.v_employee_current') IS NULL THEN
        RAISE EXCEPTION 'S3-DBA-05 test requires public.v_employee_current.';
    END IF;

    IF (SELECT count(*) FROM public.department
         WHERE deptcode IN ('ZDM', 'ZDT', 'ZDS')) <> 3
       OR (SELECT count(*) FROM public.job
            WHERE jobcode IN ('ZJ01', 'ZJ02', 'ZJ03')) <> 3
       OR (SELECT count(*) FROM public.employee
            WHERE empno IN ('Z5001', 'Z5002', 'Z5003', 'Z5004')) <> 4
       OR (SELECT count(*) FROM public.jobhistory
            WHERE empno IN ('Z5001', 'Z5002')) <> 5 THEN
        RAISE EXCEPTION
            'S3-DBA-05 failed: expected exactly 3 departments, 3 jobs, 4 employees, and 5 history rows.';
    END IF;

    IF EXISTS (
        SELECT empno, effdate
          FROM public.jobhistory
         WHERE empno IN ('Z5001', 'Z5002')
           AND NOT is_deleted
         GROUP BY empno, effdate
        HAVING count(*) > 1
    ) THEN
        RAISE EXCEPTION
            'S3-DBA-05 failed: duplicate active employee/effective-date history found.';
    END IF;

    IF (SELECT count(DISTINCT salary)
          FROM public.jobhistory
         WHERE empno IN ('Z5001', 'Z5002')) <> 5 THEN
        RAISE EXCEPTION
            'S3-DBA-05 failed: expected five distinct synthetic salary placeholders.';
    END IF;

    SELECT *
      INTO current_row
      FROM public.v_employee_current
     WHERE empno = 'Z5001';
    IF NOT FOUND
       OR current_row.jobcode IS DISTINCT FROM 'ZJ02'
       OR current_row.deptcode IS DISTINCT FROM 'ZDT'
       OR current_row.effdate IS DISTINCT FROM DATE '2023-01-01'
       OR NOT EXISTS (
           SELECT 1
             FROM public.jobhistory
            WHERE empno = 'Z5001'
              AND jobcode = 'ZJ01'
              AND effdate = DATE '2020-01-01'
              AND NOT is_deleted
       )
       OR NOT EXISTS (
           SELECT 1
             FROM public.jobhistory
            WHERE empno = 'Z5001'
              AND jobcode = 'ZJ02'
              AND effdate = DATE '2021-01-01'
              AND deptcode = 'ZDM'
              AND NOT is_deleted
       )
       OR NOT EXISTS (
           SELECT 1
             FROM public.jobhistory
            WHERE empno = 'Z5001'
              AND jobcode = 'ZJ02'
              AND effdate = DATE '2023-01-01'
              AND deptcode = 'ZDT'
              AND NOT is_deleted
       )
       OR NOT EXISTS (
           SELECT 1 FROM public.jobhistory
            WHERE empno = 'Z5001'
              AND jobcode = 'ZJ03'
              AND effdate = DATE '2099-01-01'
              AND NOT is_deleted
       ) THEN
        RAISE EXCEPTION
            'S3-DBA-05 failed: promotion/transfer should be current and the 2099 job change future-dated.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM public.employee AS e
          JOIN public.v_employee_current AS current_employee USING (empno)
         WHERE e.empno = 'Z5002'
           AND e.sepdate = DATE '2023-12-31'
           AND current_employee.jobcode = 'ZJ01'
    ) THEN
        RAISE EXCEPTION
            'S3-DBA-05 failed: separated demo employee or its current-view row is missing.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM public.v_employee_current
         WHERE empno = 'Z5003'
           AND jobcode IS NULL
           AND deptcode IS NULL
           AND effdate IS NULL
    ) THEN
        RAISE EXCEPTION
            'S3-DBA-05 failed: employee with no job history must remain visible with NULL job/department.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM public.employee
         WHERE empno = 'Z5004'
           AND is_deleted
    ) OR EXISTS (
        SELECT 1
          FROM public.v_employee_current
         WHERE empno = 'Z5004'
    ) THEN
        RAISE EXCEPTION
            'S3-DBA-05 failed: soft-deleted demo employee must be absent from the current view.';
    END IF;

    RAISE NOTICE 'PASS: promotion from ZJ01 to ZJ02 and transfer from ZDM to ZDT are recorded; future ZJ03 change is not current.';
    RAISE NOTICE 'PASS: separated employee is retained in the current view (the view filters soft-delete, not sepdate).';
    RAISE NOTICE 'PASS: no-history employee remains visible with NULL job and department.';
    RAISE NOTICE 'PASS: soft-deleted employee is excluded from the current view.';
    RAISE NOTICE 'PASS: five distinct synthetic salary placeholders and unique active effective dates.';
END;
$$;

SELECT 'department' AS table_name, count(*) AS demo_row_count
  FROM public.department WHERE deptcode IN ('ZDM', 'ZDT', 'ZDS')
UNION ALL
SELECT 'job', count(*)
  FROM public.job WHERE jobcode IN ('ZJ01', 'ZJ02', 'ZJ03')
UNION ALL
SELECT 'employee', count(*)
  FROM public.employee WHERE empno IN ('Z5001', 'Z5002', 'Z5003', 'Z5004')
UNION ALL
SELECT 'jobhistory', count(*)
  FROM public.jobhistory WHERE empno IN ('Z5001', 'Z5002')
ORDER BY table_name;

SELECT
    CASE e.empno
        WHEN 'Z5001' THEN 'promotion_transfer_future_change'
        WHEN 'Z5002' THEN 'separated_employee'
        WHEN 'Z5003' THEN 'no_job_history'
        WHEN 'Z5004' THEN 'soft_deleted_employee'
    END AS scenario,
    e.empno,
    current_employee.empno IS NOT NULL AS visible_in_current_view,
    current_employee.jobcode,
    current_employee.deptcode,
    current_employee.effdate,
    e.sepdate,
    e.is_deleted
FROM public.employee AS e
LEFT JOIN public.v_employee_current AS current_employee USING (empno)
WHERE e.empno IN ('Z5001', 'Z5002', 'Z5003', 'Z5004')
ORDER BY e.empno;

ROLLBACK;
