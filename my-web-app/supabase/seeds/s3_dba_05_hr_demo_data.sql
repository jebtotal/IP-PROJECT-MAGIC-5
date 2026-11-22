-- Synthetic HR-only demo fixtures. Apply after the ordered schema migrations.
-- Re-running preserves these rows and does not overwrite unrelated records.
BEGIN;
SET LOCAL search_path = public, pg_temp;

DO $$
DECLARE
    missing_relations TEXT;
    admin_id UUID;
BEGIN
    SELECT string_agg(required.relation_name, ', ' ORDER BY required.relation_name)
      INTO missing_relations
      FROM (VALUES
          ('public.department'),
          ('public.job'),
          ('public.employee'),
          ('public.jobhistory'),
          ('public.profiles'),
          ('public.v_employee_current')
      ) AS required(relation_name)
     WHERE to_regclass(required.relation_name) IS NULL;

    IF missing_relations IS NOT NULL THEN
        RAISE EXCEPTION
            'S3-DBA-05 seed stopped: apply the HR schema migrations first; missing: %.',
            missing_relations;
    END IF;

    SELECT id
      INTO admin_id
      FROM public.profiles
     WHERE role::TEXT IN ('admin', 'superadmin')
       AND status::TEXT = 'approved'
     ORDER BY id
     LIMIT 1;

    IF admin_id IS NULL THEN
        RAISE EXCEPTION
            'S3-DBA-05 seed needs an approved admin/superadmin profile to soft-delete its demo employee.';
    END IF;

    PERFORM set_config('request.jwt.claim.sub', admin_id::TEXT, TRUE);
    PERFORM set_config(
        'request.jwt.claims',
        jsonb_build_object('sub', admin_id::TEXT)::TEXT,
        TRUE
    );
END;
$$;

INSERT INTO public.department (deptcode, deptname)
VALUES
    ('ZDM', 'Demo Marketing'),
    ('ZDT', 'Demo Technology'),
    ('ZDS', 'Demo Support')
ON CONFLICT (deptcode) DO NOTHING;

INSERT INTO public.job (jobcode, jobdesc)
VALUES
    ('ZJ01', 'Demo Associate'),
    ('ZJ02', 'Demo Specialist'),
    ('ZJ03', 'Demo Lead')
ON CONFLICT (jobcode) DO NOTHING;

INSERT INTO public.employee
    (empno, firstname, lastname, gender, birthdate, hiredate, sepdate)
VALUES
    ('Z5001', 'Demo', 'Promoter', NULL, NULL, DATE '2020-01-01', NULL),
    ('Z5002', 'Demo', 'Separated', NULL, NULL, DATE '2021-01-01', DATE '2023-12-31'),
    ('Z5003', 'Demo', 'NoHistory', NULL, NULL, DATE '2022-01-01', NULL),
    ('Z5004', 'Demo', 'Archived', NULL, NULL, DATE '2020-01-01', NULL)
ON CONFLICT (empno) DO NOTHING;

INSERT INTO public.jobhistory (empno, jobcode, effdate, salary, deptcode)
VALUES
    ('Z5001', 'ZJ01', DATE '2020-01-01', 1111.11, 'ZDM'),
    ('Z5001', 'ZJ02', DATE '2021-01-01', 2222.22, 'ZDM'),
    ('Z5001', 'ZJ02', DATE '2023-01-01', 3333.33, 'ZDT'),
    ('Z5001', 'ZJ03', DATE '2099-01-01', 4444.44, 'ZDS'),
    ('Z5002', 'ZJ01', DATE '2021-01-01', 5555.55, 'ZDS')
ON CONFLICT (empno, jobcode, effdate) DO NOTHING;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
          FROM (VALUES
              ('ZDM', 'Demo Marketing'),
              ('ZDT', 'Demo Technology'),
              ('ZDS', 'Demo Support')
          ) AS expected(deptcode, deptname)
          LEFT JOIN public.department AS actual USING (deptcode)
         WHERE actual.deptcode IS NULL
            OR actual.deptname IS DISTINCT FROM expected.deptname
    ) OR (SELECT count(*) FROM public.department
           WHERE deptcode IN ('ZDM', 'ZDT', 'ZDS')) <> 3 THEN
        RAISE EXCEPTION
            'S3-DBA-05 seed rolled back: reserved department keys ZDM/ZDT/ZDS conflict with existing rows.';
    END IF;

    IF EXISTS (
        SELECT 1
          FROM (VALUES
              ('ZJ01', 'Demo Associate'),
              ('ZJ02', 'Demo Specialist'),
              ('ZJ03', 'Demo Lead')
          ) AS expected(jobcode, jobdesc)
          LEFT JOIN public.job AS actual USING (jobcode)
         WHERE actual.jobcode IS NULL
            OR actual.jobdesc IS DISTINCT FROM expected.jobdesc
    ) OR (SELECT count(*) FROM public.job
           WHERE jobcode IN ('ZJ01', 'ZJ02', 'ZJ03')) <> 3 THEN
        RAISE EXCEPTION
            'S3-DBA-05 seed rolled back: reserved job keys ZJ01-ZJ03 conflict with existing rows.';
    END IF;

    IF EXISTS (
        SELECT 1
          FROM (VALUES
              ('Z5001', 'Demo', 'Promoter', DATE '2020-01-01', NULL::DATE),
              ('Z5002', 'Demo', 'Separated', DATE '2021-01-01', DATE '2023-12-31'),
              ('Z5003', 'Demo', 'NoHistory', DATE '2022-01-01', NULL::DATE),
              ('Z5004', 'Demo', 'Archived', DATE '2020-01-01', NULL::DATE)
          ) AS expected(empno, firstname, lastname, hiredate, sepdate)
          LEFT JOIN public.employee AS actual USING (empno)
         WHERE actual.empno IS NULL
            OR (actual.firstname, actual.lastname, actual.hiredate, actual.sepdate,
                actual.gender, actual.birthdate)
               IS DISTINCT FROM
               (expected.firstname, expected.lastname, expected.hiredate, expected.sepdate,
                NULL::CHAR(1), NULL::DATE)
            OR (expected.empno <> 'Z5004' AND actual.is_deleted)
    ) OR (SELECT count(*) FROM public.employee
           WHERE empno IN ('Z5001', 'Z5002', 'Z5003', 'Z5004')) <> 4 THEN
        RAISE EXCEPTION
            'S3-DBA-05 seed rolled back: reserved employee keys Z5001-Z5004 conflict with existing rows.';
    END IF;

    IF EXISTS (
        SELECT 1
          FROM (VALUES
              ('Z5001', 'ZJ01', DATE '2020-01-01', 1111.11::NUMERIC, 'ZDM'),
              ('Z5001', 'ZJ02', DATE '2021-01-01', 2222.22::NUMERIC, 'ZDM'),
              ('Z5001', 'ZJ02', DATE '2023-01-01', 3333.33::NUMERIC, 'ZDT'),
              ('Z5001', 'ZJ03', DATE '2099-01-01', 4444.44::NUMERIC, 'ZDS'),
              ('Z5002', 'ZJ01', DATE '2021-01-01', 5555.55::NUMERIC, 'ZDS')
          ) AS expected(empno, jobcode, effdate, salary, deptcode)
         WHERE NOT EXISTS (
             SELECT 1
               FROM public.jobhistory AS actual
              WHERE (actual.empno, actual.jobcode, actual.effdate, actual.salary, actual.deptcode)
                    IS NOT DISTINCT FROM
                    (expected.empno, expected.jobcode, expected.effdate, expected.salary, expected.deptcode)
                AND NOT actual.is_deleted
         )
    ) OR (SELECT count(*) FROM public.jobhistory
           WHERE empno IN ('Z5001', 'Z5002')) <> 5
       OR EXISTS (
           SELECT 1 FROM public.jobhistory
            WHERE empno IN ('Z5003', 'Z5004')
       ) THEN
        RAISE EXCEPTION
            'S3-DBA-05 seed rolled back: reserved demo job-history keys conflict with existing rows.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM public.profiles WHERE empno = 'Z5004'
    ) THEN
        RAISE EXCEPTION
            'S3-DBA-05 seed rolled back: reserved soft-delete employee Z5004 is linked to a profile.';
    END IF;

    UPDATE public.employee
       SET is_deleted = TRUE
     WHERE empno = 'Z5004'
       AND NOT is_deleted;

    IF NOT EXISTS (
        SELECT 1
          FROM public.employee
         WHERE empno = 'Z5004'
           AND is_deleted
    ) THEN
        RAISE EXCEPTION
            'S3-DBA-05 seed rolled back: demo soft-delete did not complete.';
    END IF;
END;
$$;

COMMIT;
