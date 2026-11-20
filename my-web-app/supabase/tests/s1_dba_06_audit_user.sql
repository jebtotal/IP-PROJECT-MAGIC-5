-- Run after all migrations in the Supabase SQL Editor as a database owner.
-- Test rows and audit rows are rolled back; the audit identity sequence may advance.
BEGIN;
SET LOCAL search_path = public, pg_temp;

DO $$
DECLARE
    test_user_id UUID := '00000000-0000-0000-0000-000000000006';
    expected_user TEXT;
    dept_code VARCHAR(3);
    attempt INTEGER;
    action_name TEXT;
    audit_count INTEGER;
    test_case INTEGER;
BEGIN
    IF to_regclass('public.department') IS NULL
       OR to_regclass('public.audit_log') IS NULL
       OR to_regprocedure('public.audit_user()') IS NULL THEN
        RAISE EXCEPTION
            'S1-DBA-06 test requires department, audit_log, and audit_user(). Apply migrations first.';
    END IF;

    FOR test_case IN 1..2 LOOP
        IF test_case = 1 THEN
            PERFORM set_config('request.jwt.claim.sub', test_user_id::TEXT, TRUE);
            PERFORM set_config(
                'request.jwt.claims',
                jsonb_build_object('sub', test_user_id::TEXT)::TEXT,
                TRUE
            );
            PERFORM set_config('app.username', '', TRUE);
            expected_user := test_user_id::TEXT;
        ELSE
            PERFORM set_config('request.jwt.claim.sub', '', TRUE);
            PERFORM set_config('request.jwt.claims', '{}', TRUE);
            PERFORM set_config('app.username', '', TRUE);
            expected_user := 'system';
        END IF;

        IF public.audit_user() IS DISTINCT FROM expected_user THEN
            RAISE EXCEPTION
                'S1-DBA-06 test failed: expected audit_user() %, got %.',
                expected_user, public.audit_user();
        END IF;

        FOR attempt IN 1..50 LOOP
            dept_code := upper(substr(
                md5(clock_timestamp()::TEXT || random()::TEXT ||
                    pg_backend_pid()::TEXT || test_case::TEXT || attempt::TEXT),
                1,
                3
            ));
            EXIT WHEN NOT EXISTS (
                SELECT 1 FROM public.department WHERE deptcode = dept_code
            ) AND NOT EXISTS (
                SELECT 1
                  FROM public.audit_log
                 WHERE table_name = 'department'
                   AND record_key = dept_code
            );
        END LOOP;

        IF EXISTS (
            SELECT 1 FROM public.department WHERE deptcode = dept_code
        ) OR EXISTS (
            SELECT 1
              FROM public.audit_log
             WHERE table_name = 'department'
               AND record_key = dept_code
        ) THEN
            RAISE EXCEPTION 'S1-DBA-06 test could not allocate a temporary department code.';
        END IF;

        INSERT INTO public.department (deptcode, deptname)
        VALUES (dept_code, 'Audit Test');

        UPDATE public.department
           SET deptname = 'Audit Test Edit'
         WHERE deptcode = dept_code;

        -- The audit migration blocks hard DELETE; use its documented soft delete.
        UPDATE public.department
           SET is_deleted = TRUE
         WHERE deptcode = dept_code;

        FOREACH action_name IN ARRAY ARRAY['ADD', 'EDIT', 'DELETE'] LOOP
            IF NOT EXISTS (
                SELECT 1
                  FROM public.audit_log
                 WHERE table_name = 'department'
                   AND record_key = dept_code
                   AND action = action_name
                   AND action_by = expected_user
            ) THEN
                RAISE EXCEPTION
                    'S1-DBA-06 test failed: missing % audit row for department % by %.',
                    action_name, dept_code, expected_user;
            END IF;
        END LOOP;

        SELECT count(*)
          INTO audit_count
          FROM public.audit_log
         WHERE table_name = 'department'
           AND record_key = dept_code
           AND action_by = expected_user;

        IF audit_count <> 3 THEN
            RAISE EXCEPTION
                'S1-DBA-06 test failed: expected 3 audit rows for department %, got %.',
                dept_code, audit_count;
        END IF;

        RAISE NOTICE
            'PASS: ADD, EDIT, DELETE audit rows record action_by=%',
            expected_user;
    END LOOP;
END;
$$;

ROLLBACK;
