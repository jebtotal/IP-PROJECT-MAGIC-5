-- Run only against a scratch/copy database as a database owner.
-- Two existing NULL-linked profiles are used temporarily; changes are rolled back.
BEGIN;
SET LOCAL search_path = public, pg_temp;

DO $$
DECLARE
    first_profile_id UUID;
    second_profile_id UUID;
    first_auth_user_id UUID;
    second_auth_user_id UUID;
    first_empno VARCHAR(5);
    missing_empno VARCHAR(5);
    attempt INTEGER;
    duplicate_rejected BOOLEAN := FALSE;
    invalid_rejected BOOLEAN := FALSE;
    first_profile_before JSONB;
    delete_action CHAR;
BEGIN
    IF NOT EXISTS (
        SELECT 1
          FROM information_schema.columns
         WHERE table_schema = 'public'
           AND table_name = 'profiles'
           AND column_name = 'empno'
    ) THEN
        RAISE EXCEPTION
            'S3-DBA-03 test requires profiles.empno. Apply migrations first.';
    END IF;

    SELECT id INTO first_profile_id
      FROM public.profiles
     WHERE empno IS NULL
     ORDER BY id
     LIMIT 1;

    SELECT id INTO second_profile_id
      FROM public.profiles
     WHERE empno IS NULL
       AND id <> first_profile_id
     ORDER BY id
     LIMIT 1;

    IF first_profile_id IS NULL OR second_profile_id IS NULL THEN
        RAISE EXCEPTION
            'S3-DBA-03 test needs two existing profiles with NULL empno in the scratch database.';
    END IF;

    SELECT id INTO first_auth_user_id
      FROM auth.users
     WHERE id = first_profile_id;

    SELECT id INTO second_auth_user_id
      FROM auth.users
     WHERE id = second_profile_id;

    IF first_auth_user_id IS DISTINCT FROM first_profile_id
       OR second_auth_user_id IS DISTINCT FROM second_profile_id THEN
        RAISE EXCEPTION
            'S3-DBA-03 test found a profile without its corresponding Auth user.';
    END IF;

    SELECT to_jsonb(p) - 'empno'
      INTO first_profile_before
      FROM public.profiles AS p
     WHERE p.id = first_profile_id;

    FOR attempt IN 1..50 LOOP
        first_empno := substr(md5(random()::TEXT || clock_timestamp()::TEXT), 1, 5);
        EXIT WHEN NOT EXISTS (
            SELECT 1 FROM public.employee WHERE empno = first_empno
        );
    END LOOP;

    IF EXISTS (SELECT 1 FROM public.employee WHERE empno = first_empno) THEN
        RAISE EXCEPTION
            'S3-DBA-03 test could not allocate a temporary employee number.';
    END IF;

    INSERT INTO public.employee (empno, firstname, lastname)
    VALUES (first_empno, 'S3', 'ProfileLink');

    UPDATE public.profiles
       SET empno = first_empno
     WHERE id = first_profile_id;

    IF NOT EXISTS (
        SELECT 1
          FROM public.profiles AS p
          JOIN auth.users AS u ON u.id = p.id
         WHERE p.id = first_profile_id
           AND p.empno = first_empno
           AND (to_jsonb(p) - 'empno') = first_profile_before
    ) THEN
        RAISE EXCEPTION
            'S3-DBA-03 test failed: valid link changed profile identity or authentication linkage.';
    END IF;

    RAISE NOTICE
        'PASS: valid employee link stored; profile/Auth user ID and other profile fields remain unchanged.';

    FOR attempt IN 1..50 LOOP
        missing_empno := substr(md5(random()::TEXT || clock_timestamp()::TEXT), 1, 5);
        EXIT WHEN NOT EXISTS (
            SELECT 1 FROM public.employee WHERE empno = missing_empno
        );
    END LOOP;
    IF EXISTS (SELECT 1 FROM public.employee WHERE empno = missing_empno) THEN
        RAISE EXCEPTION
            'S3-DBA-03 test could not allocate a missing employee number.';
    END IF;

    BEGIN
        UPDATE public.profiles
           SET empno = missing_empno
         WHERE id = second_profile_id;
    EXCEPTION
        WHEN foreign_key_violation THEN
            invalid_rejected := TRUE;
            RAISE NOTICE 'PASS: invalid employee number rejected by foreign key.';
    END;

    IF NOT invalid_rejected THEN
        RAISE EXCEPTION
            'S3-DBA-03 test failed: invalid employee number was accepted.';
    END IF;

    BEGIN
        UPDATE public.profiles
           SET empno = first_empno
         WHERE id = second_profile_id;
    EXCEPTION
        WHEN unique_violation THEN
            duplicate_rejected := TRUE;
            RAISE NOTICE 'PASS: duplicate user-to-employee link rejected.';
    END;

    IF NOT duplicate_rejected THEN
        RAISE EXCEPTION
            'S3-DBA-03 test failed: duplicate employee link was accepted.';
    END IF;

    SELECT c.confdeltype
      INTO delete_action
      FROM pg_constraint AS c
     WHERE c.conrelid = 'public.profiles'::regclass
       AND c.conname = 'profiles_empno_fkey'
       AND c.confrelid = 'public.employee'::regclass;

    IF delete_action IS DISTINCT FROM 'n' OR NOT EXISTS (
        SELECT 1
          FROM public.profiles AS p
          JOIN auth.users AS u ON u.id = p.id
         WHERE p.id = first_profile_id
           AND p.empno = first_empno
           AND (to_jsonb(p) - 'empno') = first_profile_before
    ) THEN
        RAISE EXCEPTION
            'S3-DBA-03 test failed: ON DELETE SET NULL or the profile/Auth link is incorrect.';
    END IF;

    RAISE NOTICE
        'PASS: employee FK uses ON DELETE SET NULL; the linked profile and Auth user remain unchanged.';
END;
$$;

SELECT
    'S3-DBA-03 test used existing scratch profiles temporarily; all changes are rolled back.' AS test_result;

ROLLBACK;
