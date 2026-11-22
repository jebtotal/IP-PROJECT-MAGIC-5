-- Run after all migrations in the Supabase SQL Editor as a database owner.
-- All fixture rows are rolled back after assertions.
BEGIN;
SET LOCAL search_path = public, pg_temp;

DO $$
DECLARE
    test_empno VARCHAR(5);
    first_jobcode VARCHAR(4);
    second_jobcode VARCHAR(4);
    attempt INTEGER;
    duplicate_rejected BOOLEAN := FALSE;
    restore_rejected BOOLEAN := FALSE;
    null_date_rejected BOOLEAN := FALSE;
    negative_salary_rejected BOOLEAN := FALSE;
BEGIN
    IF to_regprocedure('public.enforce_jobhistory_unique_active_effdate()') IS NULL
       OR to_regclass('public.jobhistory') IS NULL THEN
        RAISE EXCEPTION
            'S3-DBA-02 test requires jobhistory and its uniqueness trigger. Apply migrations first.';
    END IF;

    FOR attempt IN 1..50 LOOP
        test_empno := substr(md5(random()::TEXT || clock_timestamp()::TEXT), 1, 5);
        EXIT WHEN NOT EXISTS (
            SELECT 1 FROM public.employee WHERE empno = test_empno
        );
    END LOOP;
    IF EXISTS (SELECT 1 FROM public.employee WHERE empno = test_empno) THEN
        RAISE EXCEPTION 'S3-DBA-02 test could not allocate a temporary employee.';
    END IF;

    FOR attempt IN 1..50 LOOP
        first_jobcode := upper(substr(md5(random()::TEXT || clock_timestamp()::TEXT), 1, 4));
        EXIT WHEN NOT EXISTS (
            SELECT 1 FROM public.job WHERE jobcode = first_jobcode
        );
    END LOOP;
    IF EXISTS (SELECT 1 FROM public.job WHERE jobcode = first_jobcode) THEN
        RAISE EXCEPTION 'S3-DBA-02 test could not allocate the first temporary job.';
    END IF;

    FOR attempt IN 1..50 LOOP
        second_jobcode := upper(substr(md5(random()::TEXT || clock_timestamp()::TEXT), 1, 4));
        EXIT WHEN second_jobcode <> first_jobcode
          AND NOT EXISTS (
              SELECT 1 FROM public.job WHERE jobcode = second_jobcode
          );
    END LOOP;
    IF second_jobcode = first_jobcode
       OR EXISTS (SELECT 1 FROM public.job WHERE jobcode = second_jobcode) THEN
        RAISE EXCEPTION 'S3-DBA-02 test could not allocate the second temporary job.';
    END IF;

    INSERT INTO public.employee (empno, firstname, lastname)
    VALUES (test_empno, 'S3', 'UniqueDate');
    INSERT INTO public.job (jobcode, jobdesc)
    VALUES (first_jobcode, 'S3 Test 1'), (second_jobcode, 'S3 Test 2');

    INSERT INTO public.jobhistory (empno, jobcode, effdate, salary)
    VALUES (test_empno, first_jobcode, DATE '2020-01-01', 1000);
    RAISE NOTICE
        'PASS: valid active job-history row inserted for employee %.',
        test_empno;

    BEGIN
        INSERT INTO public.jobhistory (empno, jobcode, effdate, salary)
        VALUES (test_empno, second_jobcode, DATE '2020-01-01', 1200);
    EXCEPTION
        WHEN unique_violation THEN
            duplicate_rejected := TRUE;
            RAISE NOTICE
                'PASS: duplicate active employee/effective-date insert rejected: %',
                SQLERRM;
    END;

    IF NOT duplicate_rejected THEN
        RAISE EXCEPTION
            'S3-DBA-02 test failed: duplicate active employee/effective-date insert was accepted.';
    END IF;

    BEGIN
        INSERT INTO public.jobhistory (empno, jobcode, effdate, salary)
        VALUES (test_empno, second_jobcode, DATE '2020-01-02', -1);
    EXCEPTION
        WHEN check_violation THEN
            negative_salary_rejected := TRUE;
            RAISE NOTICE 'PASS: negative salary insert rejected: %', SQLERRM;
    END;

    IF NOT negative_salary_rejected THEN
        RAISE EXCEPTION
            'S3-DBA-02 test failed: negative salary insert was accepted.';
    END IF;

    BEGIN
        INSERT INTO public.jobhistory (empno, jobcode, effdate, salary)
        VALUES (test_empno, second_jobcode, NULL, 1200);
    EXCEPTION
        WHEN not_null_violation OR check_violation THEN
            null_date_rejected := TRUE;
            RAISE NOTICE 'PASS: NULL effective-date insert rejected: %', SQLERRM;
    END;

    IF NOT null_date_rejected THEN
        RAISE EXCEPTION
            'S3-DBA-02 test failed: NULL effective date insert was accepted.';
    END IF;

    INSERT INTO public.jobhistory (empno, jobcode, effdate, salary, is_deleted)
    VALUES (test_empno, second_jobcode, DATE '2020-01-01', 1200, TRUE);

    BEGIN
        UPDATE public.jobhistory
           SET is_deleted = FALSE
         WHERE empno = test_empno
           AND jobcode = second_jobcode
           AND effdate = DATE '2020-01-01';
    EXCEPTION
        WHEN unique_violation THEN
            restore_rejected := TRUE;
            RAISE NOTICE
                'PASS: restoring a conflicting soft-deleted row was rejected: %',
                SQLERRM;
    END;

    IF NOT restore_rejected THEN
        RAISE EXCEPTION
            'S3-DBA-02 test failed: conflicting soft-deleted row was restored.';
    END IF;
END;
$$;

SELECT
    'S3-DBA-02 test uses temporary rows; all rows are rolled back after assertions.' AS test_result;

ROLLBACK;
