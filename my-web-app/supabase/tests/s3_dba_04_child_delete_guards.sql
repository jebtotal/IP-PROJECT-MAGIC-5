-- Run only against a scratch/copy database as a database owner.
-- The test temporarily links one existing profile and rolls everything back.
BEGIN;
SET LOCAL search_path = public, pg_temp;

SELECT
    constraint_row.conname AS constraint_name,
    child.relname AS referencing_table,
    string_agg(child_column.attname, ', ' ORDER BY child_column.attnum) AS referencing_columns,
    parent.relname AS referenced_table,
    string_agg(parent_column.attname, ', ' ORDER BY parent_column.attnum) AS referenced_columns,
    CASE constraint_row.confdeltype
        WHEN 'a' THEN 'NO ACTION'
        WHEN 'r' THEN 'RESTRICT'
        WHEN 'c' THEN 'CASCADE'
        WHEN 'n' THEN 'SET NULL'
        WHEN 'd' THEN 'SET DEFAULT'
    END AS on_delete
FROM pg_constraint AS constraint_row
JOIN pg_class AS child ON child.oid = constraint_row.conrelid
JOIN pg_namespace AS child_namespace ON child_namespace.oid = child.relnamespace
JOIN pg_class AS parent ON parent.oid = constraint_row.confrelid
JOIN pg_namespace AS parent_namespace ON parent_namespace.oid = parent.relnamespace
JOIN LATERAL unnest(constraint_row.conkey) AS child_key(attnum) ON TRUE
JOIN pg_attribute AS child_column
  ON child_column.attrelid = child.oid
 AND child_column.attnum = child_key.attnum
JOIN LATERAL unnest(constraint_row.confkey) AS parent_key(attnum) ON TRUE
JOIN pg_attribute AS parent_column
  ON parent_column.attrelid = parent.oid
 AND parent_column.attnum = parent_key.attnum
WHERE constraint_row.contype = 'f'
  AND child_namespace.nspname = 'public'
  AND parent_namespace.nspname = 'public'
  AND parent.relname IN ('employee', 'department', 'job')
GROUP BY constraint_row.conname, child.relname, parent.relname, constraint_row.confdeltype
ORDER BY parent.relname, child.relname;

SELECT
    table_class.relname AS table_name,
    trigger_row.tgname AS trigger_name,
    pg_get_triggerdef(trigger_row.oid) AS trigger_definition
FROM pg_trigger AS trigger_row
JOIN pg_class AS table_class ON table_class.oid = trigger_row.tgrelid
JOIN pg_namespace AS table_namespace ON table_namespace.oid = table_class.relnamespace
WHERE NOT trigger_row.tgisinternal
  AND table_namespace.nspname = 'public'
  AND table_class.relname IN
      ('employee', 'department', 'job', 'jobhistory', 'sales', 'profiles')
ORDER BY table_class.relname, trigger_row.tgname;

DO $$
DECLARE
    employee_history VARCHAR(5);
    employee_sales VARCHAR(5);
    employee_profile VARCHAR(5);
    employee_archived VARCHAR(5);
    department_active VARCHAR(3);
    department_archived VARCHAR(3);
    job_active VARCHAR(4);
    job_archived VARCHAR(4);
    customer_test VARCHAR(5);
    sales_transaction VARCHAR(8);
    archived_sales_transaction VARCHAR(8);
    profile_id UUID;
    attempt INTEGER;
    error_message TEXT;
    rejected BOOLEAN;
    deleted_profiles INTEGER;
    employee_fk_action CHAR;
BEGIN
    IF to_regclass('public.employee') IS NULL
       OR to_regclass('public.department') IS NULL
       OR to_regclass('public.job') IS NULL
       OR to_regclass('public.jobhistory') IS NULL
       OR to_regclass('public.sales') IS NULL
       OR to_regclass('public.profiles') IS NULL THEN
        RAISE EXCEPTION
            'S3-DBA-04 test requires employee, department, job, jobhistory, sales, and profiles.';
    END IF;

    SELECT id
      INTO profile_id
      FROM public.profiles
     WHERE empno IS NULL
       AND role::TEXT IN ('admin', 'superadmin')
       AND status::TEXT = 'approved'
     ORDER BY id
     LIMIT 1;
    IF profile_id IS NULL THEN
        RAISE EXCEPTION
            'S3-DBA-04 test needs one approved admin/superadmin profile with NULL empno in the scratch database.';
    END IF;

    PERFORM set_config('request.jwt.claim.sub', profile_id::TEXT, TRUE);
    PERFORM set_config(
        'request.jwt.claims',
        jsonb_build_object('sub', profile_id::TEXT)::TEXT,
        TRUE
    );

    SELECT confdeltype
      INTO employee_fk_action
      FROM pg_constraint
     WHERE conrelid = 'public.profiles'::regclass
       AND conname = 'profiles_empno_fkey'
       AND confrelid = 'public.employee'::regclass;
    IF employee_fk_action IS DISTINCT FROM 'n' THEN
        RAISE EXCEPTION
            'S3-DBA-04 test expected profiles_empno_fkey ON DELETE SET NULL.';
    END IF;

    FOR attempt IN 1..50 LOOP
        employee_history := substr(md5(random()::TEXT || clock_timestamp()::TEXT), 1, 5);
        EXIT WHEN NOT EXISTS (SELECT 1 FROM public.employee WHERE empno = employee_history);
    END LOOP;
    FOR attempt IN 1..50 LOOP
        employee_sales := substr(md5(random()::TEXT || clock_timestamp()::TEXT), 1, 5);
        EXIT WHEN employee_sales <> employee_history
          AND NOT EXISTS (SELECT 1 FROM public.employee WHERE empno = employee_sales);
    END LOOP;
    FOR attempt IN 1..50 LOOP
        employee_profile := substr(md5(random()::TEXT || clock_timestamp()::TEXT), 1, 5);
        EXIT WHEN employee_profile NOT IN (employee_history, employee_sales)
          AND NOT EXISTS (SELECT 1 FROM public.employee WHERE empno = employee_profile);
    END LOOP;
    FOR attempt IN 1..50 LOOP
        employee_archived := substr(md5(random()::TEXT || clock_timestamp()::TEXT), 1, 5);
        EXIT WHEN employee_archived NOT IN (employee_history, employee_sales, employee_profile)
          AND NOT EXISTS (SELECT 1 FROM public.employee WHERE empno = employee_archived);
    END LOOP;
    FOR attempt IN 1..50 LOOP
        department_active := upper(substr(md5(random()::TEXT || clock_timestamp()::TEXT), 1, 3));
        EXIT WHEN NOT EXISTS (SELECT 1 FROM public.department WHERE deptcode = department_active);
    END LOOP;
    FOR attempt IN 1..50 LOOP
        department_archived := upper(substr(md5(random()::TEXT || clock_timestamp()::TEXT), 1, 3));
        EXIT WHEN department_archived <> department_active
          AND NOT EXISTS (SELECT 1 FROM public.department WHERE deptcode = department_archived);
    END LOOP;
    FOR attempt IN 1..50 LOOP
        job_active := upper(substr(md5(random()::TEXT || clock_timestamp()::TEXT), 1, 4));
        EXIT WHEN NOT EXISTS (SELECT 1 FROM public.job WHERE jobcode = job_active);
    END LOOP;
    FOR attempt IN 1..50 LOOP
        job_archived := upper(substr(md5(random()::TEXT || clock_timestamp()::TEXT), 1, 4));
        EXIT WHEN job_archived <> job_active
          AND NOT EXISTS (SELECT 1 FROM public.job WHERE jobcode = job_archived);
    END LOOP;
    FOR attempt IN 1..50 LOOP
        customer_test := substr(md5(random()::TEXT || clock_timestamp()::TEXT), 1, 5);
        EXIT WHEN NOT EXISTS (SELECT 1 FROM public.customer WHERE custno = customer_test);
    END LOOP;
    FOR attempt IN 1..50 LOOP
        sales_transaction := substr(md5(random()::TEXT || clock_timestamp()::TEXT), 1, 8);
        EXIT WHEN NOT EXISTS (SELECT 1 FROM public.sales WHERE transno = sales_transaction);
    END LOOP;
    FOR attempt IN 1..50 LOOP
        archived_sales_transaction := substr(md5(random()::TEXT || clock_timestamp()::TEXT), 1, 8);
        EXIT WHEN archived_sales_transaction <> sales_transaction
          AND NOT EXISTS (
              SELECT 1 FROM public.sales WHERE transno = archived_sales_transaction
          );
    END LOOP;

    IF EXISTS (SELECT 1 FROM public.employee WHERE empno IN
                    (employee_history, employee_sales, employee_profile, employee_archived))
       OR EXISTS (SELECT 1 FROM public.department WHERE deptcode IN
                    (department_active, department_archived))
       OR EXISTS (SELECT 1 FROM public.job WHERE jobcode IN
                    (job_active, job_archived))
       OR EXISTS (SELECT 1 FROM public.customer WHERE custno = customer_test)
       OR EXISTS (SELECT 1 FROM public.sales WHERE transno IN
                    (sales_transaction, archived_sales_transaction)) THEN
        RAISE EXCEPTION 'S3-DBA-04 test could not allocate unique fixture keys.';
    END IF;

    INSERT INTO public.department (deptcode, deptname)
    VALUES (department_active, 'S3 Active'), (department_archived, 'S3 Archived');
    INSERT INTO public.job (jobcode, jobdesc)
    VALUES (job_active, 'S3 Active'), (job_archived, 'S3 Archived');
    INSERT INTO public.employee (empno, firstname, lastname)
    VALUES
        (employee_history, 'S3', 'History'),
        (employee_sales, 'S3', 'Sales'),
        (employee_profile, 'S3', 'Profile'),
        (employee_archived, 'S3', 'Archived');
    INSERT INTO public.customer (custno, custname)
    VALUES (customer_test, 'S3 Child Guard');

    INSERT INTO public.jobhistory (empno, jobcode, effdate, salary, deptcode)
    VALUES (employee_history, job_active, CURRENT_DATE, 1000, department_active);

    rejected := FALSE;
    BEGIN
        UPDATE public.employee SET is_deleted = TRUE WHERE empno = employee_history;
    EXCEPTION WHEN raise_exception THEN
        GET STACKED DIAGNOSTICS error_message = MESSAGE_TEXT;
        rejected := position('active related record' IN error_message) > 0;
    END;
    IF NOT rejected THEN
        RAISE EXCEPTION 'S3-DBA-04 failed: active job history did not block employee soft-delete.';
    END IF;
    RAISE NOTICE 'PASS: active job history blocks employee soft-delete.';

    rejected := FALSE;
    BEGIN
        UPDATE public.department SET is_deleted = TRUE WHERE deptcode = department_active;
    EXCEPTION WHEN raise_exception THEN
        GET STACKED DIAGNOSTICS error_message = MESSAGE_TEXT;
        rejected := position('active related record' IN error_message) > 0;
    END;
    IF NOT rejected THEN
        RAISE EXCEPTION 'S3-DBA-04 failed: active job history did not block department soft-delete.';
    END IF;
    RAISE NOTICE 'PASS: department referenced by active job history cannot be soft-deleted.';

    rejected := FALSE;
    BEGIN
        UPDATE public.job SET is_deleted = TRUE WHERE jobcode = job_active;
    EXCEPTION WHEN raise_exception THEN
        GET STACKED DIAGNOSTICS error_message = MESSAGE_TEXT;
        rejected := position('active related record' IN error_message) > 0;
    END;
    IF NOT rejected THEN
        RAISE EXCEPTION 'S3-DBA-04 failed: active job history did not block job soft-delete.';
    END IF;
    RAISE NOTICE 'PASS: job referenced by active job history cannot be soft-deleted.';

    INSERT INTO public.sales (transno, salesdate, custno, empno)
    VALUES (
        sales_transaction,
        CURRENT_DATE,
        customer_test,
        employee_sales
    );

    rejected := FALSE;
    BEGIN
        UPDATE public.employee SET is_deleted = TRUE WHERE empno = employee_sales;
    EXCEPTION WHEN raise_exception THEN
        GET STACKED DIAGNOSTICS error_message = MESSAGE_TEXT;
        rejected := position('active related record' IN error_message) > 0;
    END;
    IF NOT rejected THEN
        RAISE EXCEPTION 'S3-DBA-04 failed: active sales did not block employee soft-delete.';
    END IF;
    RAISE NOTICE 'PASS: active sales blocks employee soft-delete.';

    UPDATE public.profiles SET empno = employee_profile WHERE id = profile_id;

    rejected := FALSE;
    BEGIN
        UPDATE public.employee SET is_deleted = TRUE WHERE empno = employee_profile;
    EXCEPTION WHEN raise_exception THEN
        GET STACKED DIAGNOSTICS error_message = MESSAGE_TEXT;
        rejected := position('linked user profile' IN error_message) > 0;
    END;
    IF NOT rejected THEN
        RAISE EXCEPTION 'S3-DBA-04 failed: linked profile did not block employee soft-delete.';
    END IF;
    RAISE NOTICE 'PASS: linked profile blocks employee soft-delete with an explicit unlink-first error.';

    INSERT INTO public.jobhistory (empno, jobcode, effdate, salary, deptcode, is_deleted)
    VALUES (employee_archived, job_archived, CURRENT_DATE, 1000, department_archived, TRUE);
    INSERT INTO public.sales (transno, salesdate, custno, empno)
    VALUES (archived_sales_transaction, CURRENT_DATE, customer_test, employee_archived);
    UPDATE public.sales
       SET is_deleted = TRUE
     WHERE transno = archived_sales_transaction;

    UPDATE public.employee SET is_deleted = TRUE WHERE empno = employee_archived;
    UPDATE public.department SET is_deleted = TRUE WHERE deptcode = department_archived;
    UPDATE public.job SET is_deleted = TRUE WHERE jobcode = job_archived;

    IF NOT EXISTS (SELECT 1 FROM public.employee WHERE empno = employee_archived AND is_deleted)
       OR NOT EXISTS (SELECT 1 FROM public.department WHERE deptcode = department_archived AND is_deleted)
       OR NOT EXISTS (SELECT 1 FROM public.job WHERE jobcode = job_archived AND is_deleted) THEN
        RAISE EXCEPTION
            'S3-DBA-04 failed: soft-deleted job-history child blocked employee, department, or job.';
    END IF;
    RAISE NOTICE 'PASS: soft-deleted job history and sales do not block employee, department, or job soft-delete.';

    UPDATE public.employee SET is_deleted = FALSE WHERE empno = employee_archived;
    UPDATE public.department SET is_deleted = FALSE WHERE deptcode = department_archived;
    UPDATE public.job SET is_deleted = FALSE WHERE jobcode = job_archived;
    UPDATE public.jobhistory
       SET is_deleted = FALSE
     WHERE empno = employee_archived
       AND jobcode = job_archived
       AND effdate = CURRENT_DATE;

    IF EXISTS (
        SELECT 1
          FROM public.employee AS e
          JOIN public.department AS d ON d.deptcode = department_archived
          JOIN public.job AS j ON j.jobcode = job_archived
          JOIN public.jobhistory AS h
            ON h.empno = e.empno
           AND h.jobcode = j.jobcode
           AND h.deptcode = d.deptcode
         WHERE e.empno = employee_archived
           AND (e.is_deleted OR d.is_deleted OR j.is_deleted OR h.is_deleted)
    ) THEN
        RAISE EXCEPTION
            'S3-DBA-04 failed: employee, department, job, or job-history restore did not complete.';
    END IF;
    RAISE NOTICE 'PASS: employee, department, job, and job-history soft-delete restores succeed.';

    SELECT count(*) INTO deleted_profiles
      FROM public.profiles
     WHERE id = profile_id
       AND empno = employee_profile;
    IF deleted_profiles <> 1 THEN
        RAISE EXCEPTION
            'S3-DBA-04 failed: test profile link was not retained after the rejected employee soft-delete.';
    END IF;
END;
$$;

SELECT
    'S3-DBA-04 test fixtures and temporary profile link are rolled back.' AS test_result;

ROLLBACK;
