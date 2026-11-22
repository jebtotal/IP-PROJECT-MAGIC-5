-- Link an optional employee record to the existing Supabase profile.
-- Existing profiles are not backfilled.
BEGIN;
SET LOCAL search_path = public, pg_temp;

DO $$
DECLARE
    employee_empno_attnum SMALLINT;
    profiles_id_attnum SMALLINT;
BEGIN
    IF to_regclass('public.profiles') IS NULL
       OR to_regclass('public.employee') IS NULL THEN
        RAISE EXCEPTION
            'S3-DBA-03 stopped: public.profiles and public.employee must both exist.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM information_schema.columns
         WHERE table_schema = 'public'
           AND table_name = 'profiles'
           AND column_name = 'id'
           AND data_type = 'uuid'
           AND is_nullable = 'NO'
    ) THEN
        RAISE EXCEPTION
            'S3-DBA-03 stopped: public.profiles.id must be a non-null UUID.';
    END IF;

    SELECT a.attnum
      INTO profiles_id_attnum
      FROM pg_attribute AS a
     WHERE a.attrelid = 'public.profiles'::regclass
       AND a.attname = 'id'
       AND NOT a.attisdropped;

    IF NOT EXISTS (
        SELECT 1
          FROM pg_constraint AS c
         WHERE c.conrelid = 'public.profiles'::regclass
           AND c.contype = 'p'
           AND c.conkey = ARRAY[profiles_id_attnum]::SMALLINT[]
    ) THEN
        RAISE EXCEPTION
            'S3-DBA-03 stopped: public.profiles.id must remain the primary key.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM information_schema.columns
         WHERE table_schema = 'public'
           AND table_name = 'employee'
           AND column_name = 'empno'
           AND data_type = 'character varying'
           AND character_maximum_length = 5
           AND is_nullable = 'NO'
    ) THEN
        RAISE EXCEPTION
            'S3-DBA-03 stopped: public.employee.empno must be VARCHAR(5) NOT NULL.';
    END IF;

    SELECT a.attnum
      INTO employee_empno_attnum
      FROM pg_attribute AS a
     WHERE a.attrelid = 'public.employee'::regclass
       AND a.attname = 'empno'
       AND NOT a.attisdropped;

    IF NOT EXISTS (
        SELECT 1
          FROM pg_constraint AS c
         WHERE c.conrelid = 'public.employee'::regclass
           AND c.contype = 'p'
           AND c.conkey = ARRAY[employee_empno_attnum]::SMALLINT[]
    ) THEN
        RAISE EXCEPTION
            'S3-DBA-03 stopped: public.employee.empno must remain the primary key.';
    END IF;
END;
$$;

ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS empno VARCHAR(5);

DO $$
DECLARE
    invalid_empnos TEXT;
    duplicate_empnos TEXT;
BEGIN
    IF NOT EXISTS (
        SELECT 1
          FROM information_schema.columns
         WHERE table_schema = 'public'
           AND table_name = 'profiles'
           AND column_name = 'empno'
           AND data_type = 'character varying'
           AND character_maximum_length = 5
           AND is_nullable = 'YES'
    ) THEN
        RAISE EXCEPTION
            'S3-DBA-03 stopped: public.profiles.empno must be nullable VARCHAR(5).';
    END IF;

    SELECT string_agg(p.id::TEXT || '=' || p.empno, ', ' ORDER BY p.id)
      INTO invalid_empnos
      FROM public.profiles AS p
      LEFT JOIN public.employee AS e ON e.empno = p.empno
     WHERE p.empno IS NOT NULL
       AND e.empno IS NULL;

    IF invalid_empnos IS NOT NULL THEN
        RAISE EXCEPTION
            'S3-DBA-03 stopped: existing profiles.empno values do not reference employees: %. Review links; no rows were changed.',
            invalid_empnos;
    END IF;

    SELECT string_agg(p.empno || ' (profiles=' || p.profile_ids || ')', ', ' ORDER BY p.empno)
      INTO duplicate_empnos
      FROM (
          SELECT empno,
                 string_agg(id::TEXT, ',' ORDER BY id) AS profile_ids
            FROM public.profiles
           WHERE empno IS NOT NULL
           GROUP BY empno
          HAVING count(*) > 1
      ) AS p;

    IF duplicate_empnos IS NOT NULL THEN
        RAISE EXCEPTION
            'S3-DBA-03 stopped: employee links are already duplicated: %. Review links; no rows were changed.',
            duplicate_empnos;
    END IF;
END;
$$;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
          FROM pg_constraint
         WHERE conrelid = 'public.profiles'::regclass
           AND conname = 'profiles_empno_fkey'
           AND (
               contype <> 'f'
               OR confrelid <> 'public.employee'::regclass
               OR confdeltype <> 'n'
               OR conkey <> ARRAY[
                   (SELECT attnum FROM pg_attribute
                     WHERE attrelid = 'public.profiles'::regclass
                       AND attname = 'empno'
                       AND NOT attisdropped)
               ]::SMALLINT[]
               OR confkey <> ARRAY[
                   (SELECT attnum FROM pg_attribute
                     WHERE attrelid = 'public.employee'::regclass
                       AND attname = 'empno'
                       AND NOT attisdropped)
               ]::SMALLINT[]
           )
    ) THEN
        RAISE EXCEPTION
            'S3-DBA-03 stopped: profiles_empno_fkey exists with a different definition.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM pg_constraint
         WHERE conrelid = 'public.profiles'::regclass
           AND conname = 'profiles_empno_fkey'
    ) THEN
        ALTER TABLE public.profiles
            ADD CONSTRAINT profiles_empno_fkey
            FOREIGN KEY (empno)
            REFERENCES public.employee (empno)
            ON DELETE SET NULL
            NOT VALID;
    END IF;

    ALTER TABLE public.profiles
        VALIDATE CONSTRAINT profiles_empno_fkey;
END;
$$;

DO $$
DECLARE
    empno_attnum SMALLINT;
    index_is_compatible BOOLEAN;
BEGIN
    SELECT a.attnum
      INTO empno_attnum
      FROM pg_attribute AS a
     WHERE a.attrelid = 'public.profiles'::regclass
       AND a.attname = 'empno'
       AND NOT a.attisdropped;

    IF EXISTS (
        SELECT 1
          FROM pg_class AS c
          JOIN pg_namespace AS n ON n.oid = c.relnamespace
         WHERE n.nspname = 'public'
           AND c.relname = 'profiles_empno_unique_idx'
           AND c.relkind <> 'i'
    ) THEN
        RAISE EXCEPTION
            'S3-DBA-03 stopped: public.profiles_empno_unique_idx exists but is not an index.';
    END IF;

    SELECT (
        i.indisunique
        AND i.indnatts = 1
        AND i.indnkeyatts = 1
        AND i.indpred IS NULL
        AND i.indkey[0] = empno_attnum
    )
      INTO index_is_compatible
      FROM pg_index AS i
      JOIN pg_class AS index_class ON index_class.oid = i.indexrelid
      JOIN pg_namespace AS index_namespace ON index_namespace.oid = index_class.relnamespace
     WHERE index_namespace.nspname = 'public'
       AND index_class.relname = 'profiles_empno_unique_idx';

    IF index_is_compatible IS FALSE THEN
        RAISE EXCEPTION
            'S3-DBA-03 stopped: public.profiles_empno_unique_idx exists with an incompatible definition.';
    END IF;
END;
$$;

CREATE UNIQUE INDEX IF NOT EXISTS profiles_empno_unique_idx
    ON public.profiles (empno);

COMMIT;
