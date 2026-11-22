-- Run after all migrations in the Supabase SQL Editor as a database owner.
-- Test rows and audit rows are rolled back; identity sequences may advance.
BEGIN;
SET LOCAL search_path = public, pg_temp;

DO $$
DECLARE
    history_empno VARCHAR(5);
    no_history_empno VARCHAR(5);
    deleted_empno VARCHAR(5);
    dept_one VARCHAR(3);
    dept_two VARCHAR(3);
    current_job VARCHAR(4);
    future_job VARCHAR(4);
    attempt INTEGER;
    current_row RECORD;
BEGIN
    IF to_regclass('public.v_employee_current') IS NULL
       OR to_regclass('public.employee') IS NULL
       OR to_regclass('public.jobhistory') IS NULL
       OR to_regclass('public.job') IS NULL
       OR to_regclass('public.department') IS NULL THEN
        RAISE EXCEPTION
            'S3-DBA-01 test requires employee, jobhistory, job, department, and v_employee_current. Apply migrations first.';
    END IF;

    FOR attempt IN 1..50 LOOP
        history_empno := substr(md5(random()::TEXT || clock_timestamp()::TEXT), 1, 5);
        EXIT WHEN NOT EXISTS (
            SELECT 1 FROM public.employee WHERE empno = history_empno
        );
    END LOOP;
    IF EXISTS (SELECT 1 FROM public.employee WHERE empno = history_empno) THEN
        RAISE EXCEPTION 'S3-DBA-01 test could not allocate a temporary history employee.';
    END IF;

    FOR attempt IN 1..50 LOOP
        no_history_empno := substr(md5(random()::TEXT || clock_timestamp()::TEXT), 1, 5);
        EXIT WHEN no_history_empno <> history_empno
          AND NOT EXISTS (
              SELECT 1 FROM public.employee WHERE empno = no_history_empno
          );
    END LOOP;
    IF no_history_empno = history_empno
       OR EXISTS (SELECT 1 FROM public.employee WHERE empno = no_history_empno) THEN
        RAISE EXCEPTION 'S3-DBA-01 test could not allocate a no-history employee.';
    END IF;

    FOR attempt IN 1..50 LOOP
        deleted_empno := substr(md5(random()::TEXT || clock_timestamp()::TEXT), 1, 5);
        EXIT WHEN deleted_empno NOT IN (history_empno, no_history_empno)
          AND NOT EXISTS (
              SELECT 1 FROM public.employee WHERE empno = deleted_empno
          );
    END LOOP;
    IF deleted_empno IN (history_empno, no_history_empno)
       OR EXISTS (SELECT 1 FROM public.employee WHERE empno = deleted_empno) THEN
        RAISE EXCEPTION 'S3-DBA-01 test could not allocate a deleted employee.';
    END IF;

    FOR attempt IN 1..50 LOOP
        dept_one := upper(substr(md5(random()::TEXT || clock_timestamp()::TEXT), 1, 3));
        EXIT WHEN NOT EXISTS (
            SELECT 1 FROM public.department WHERE deptcode = dept_one
        );
    END LOOP;
    IF EXISTS (SELECT 1 FROM public.department WHERE deptcode = dept_one) THEN
        RAISE EXCEPTION 'S3-DBA-01 test could not allocate the first department.';
    END IF;

    FOR attempt IN 1..50 LOOP
        dept_two := upper(substr(md5(random()::TEXT || clock_timestamp()::TEXT), 1, 3));
        EXIT WHEN dept_two <> dept_one
          AND NOT EXISTS (
              SELECT 1 FROM public.department WHERE deptcode = dept_two
          );
    END LOOP;
    IF dept_two = dept_one
       OR EXISTS (SELECT 1 FROM public.department WHERE deptcode = dept_two) THEN
        RAISE EXCEPTION 'S3-DBA-01 test could not allocate the second department.';
    END IF;

    FOR attempt IN 1..50 LOOP
        current_job := upper(substr(md5(random()::TEXT || clock_timestamp()::TEXT), 1, 4));
        EXIT WHEN NOT EXISTS (SELECT 1 FROM public.job WHERE jobcode = current_job);
    END LOOP;
    IF EXISTS (SELECT 1 FROM public.job WHERE jobcode = current_job) THEN
        RAISE EXCEPTION 'S3-DBA-01 test could not allocate the current job.';
    END IF;

    FOR attempt IN 1..50 LOOP
        future_job := upper(substr(md5(random()::TEXT || clock_timestamp()::TEXT), 1, 4));
        EXIT WHEN future_job <> current_job
          AND NOT EXISTS (SELECT 1 FROM public.job WHERE jobcode = future_job);
    END LOOP;
    IF future_job = current_job
       OR EXISTS (SELECT 1 FROM public.job WHERE jobcode = future_job) THEN
        RAISE EXCEPTION 'S3-DBA-01 test could not allocate the future job.';
    END IF;

    INSERT INTO public.department (deptcode, deptname)
    VALUES (dept_one, 'S3 Test Dept A'), (dept_two, 'S3 Test Dept B');

    INSERT INTO public.job (jobcode, jobdesc)
    VALUES (current_job, 'S3 Current'), (future_job, 'S3 Future');

    INSERT INTO public.employee (empno, firstname, lastname)
    VALUES
        (history_empno, 'S3', 'History'),
        (no_history_empno, 'S3', 'NoHistory'),
        (deleted_empno, 'S3', 'Deleted');

    INSERT INTO public.jobhistory (empno, jobcode, effdate, salary, deptcode)
    VALUES
        (history_empno, current_job, CURRENT_DATE - 30, 50000, dept_one),
        (history_empno, current_job, CURRENT_DATE - 10, 55000, dept_two),
        (history_empno, future_job, CURRENT_DATE + 10, 70000, dept_one);

    UPDATE public.employee
       SET is_deleted = TRUE
     WHERE empno = deleted_empno;

    SELECT *
      INTO current_row
      FROM public.v_employee_current
     WHERE empno = history_empno;

    IF NOT FOUND
       OR current_row.jobcode IS DISTINCT FROM current_job
       OR current_row.deptcode IS DISTINCT FROM dept_two
       OR current_row.effdate IS DISTINCT FROM CURRENT_DATE - 10 THEN
        RAISE EXCEPTION
            'S3-DBA-01 test failed: expected current job %, department %, effective date %, got job %, department %, date %.',
            current_job, dept_two, CURRENT_DATE - 10,
            current_row.jobcode, current_row.deptcode, current_row.effdate;
    END IF;

    RAISE NOTICE
        'PASS: transfer is current; future promotion ignored (employee %, job %, department %, effective date %).',
        history_empno, current_row.jobcode, current_row.deptcode, current_row.effdate;

    SELECT *
      INTO current_row
      FROM public.v_employee_current
     WHERE empno = no_history_empno;

    IF NOT FOUND
       OR current_row.jobcode IS NOT NULL
       OR current_row.deptcode IS NOT NULL
       OR current_row.jobdesc IS NOT NULL
       OR current_row.deptname IS NOT NULL
       OR current_row.effdate IS NOT NULL THEN
        RAISE EXCEPTION
            'S3-DBA-01 test failed: employee with no history must remain with NULL job/department.';
    END IF;

    RAISE NOTICE
        'PASS: employee with no history remains visible with NULL job and department (employee %).',
        no_history_empno;

    IF EXISTS (
        SELECT 1
          FROM public.v_employee_current
         WHERE empno = deleted_empno
    ) THEN
        RAISE EXCEPTION
            'S3-DBA-01 test failed: soft-deleted employee % appears in the active view.',
            deleted_empno;
    END IF;

    RAISE NOTICE
        'PASS: soft-deleted employee is excluded from active view (employee %).',
        deleted_empno;
END;
$$;

SELECT
    'S3-DBA-01 test uses temporary rows; all rows are rolled back after assertions.' AS test_result;

ROLLBACK;
