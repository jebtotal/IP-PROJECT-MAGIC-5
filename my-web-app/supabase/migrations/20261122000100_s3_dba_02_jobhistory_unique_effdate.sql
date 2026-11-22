-- Enforce one active job-history row per employee and effective date.
-- Existing rows are preserved; the unique index is deferred if active
-- duplicates need a DBA-reviewed resolution.
BEGIN;
SET LOCAL search_path = public, pg_temp;

DO $$
DECLARE
    missing_columns TEXT;
    duplicate_groups TEXT;
    active_duplicate_count BIGINT;
BEGIN
    WITH required_columns(column_name) AS (
        VALUES ('empno'), ('jobcode'), ('effdate'), ('salary'), ('is_deleted')
    )
    SELECT string_agg(r.column_name, ', ' ORDER BY r.column_name)
      INTO missing_columns
      FROM required_columns AS r
      LEFT JOIN information_schema.columns AS c
        ON c.table_schema = 'public'
       AND c.table_name = 'jobhistory'
       AND c.column_name = r.column_name
     WHERE c.column_name IS NULL;

    IF missing_columns IS NOT NULL THEN
        RAISE EXCEPTION
            'S3-DBA-02 stopped: public.jobhistory is missing required columns: %',
            missing_columns;
    END IF;

    SELECT count(*)
      INTO active_duplicate_count
      FROM (
          SELECT empno, effdate
            FROM public.jobhistory
           WHERE NOT is_deleted
           GROUP BY empno, effdate
          HAVING count(*) > 1
      ) AS duplicate_pairs;

    SELECT string_agg(
               format(
                   '%s on %s (rows=%s, active=%s, jobcodes=%s)',
                   empno,
                   effdate,
                   total_rows,
                   active_rows,
                   jobcodes
               ),
               '; ' ORDER BY empno, effdate
           )
      INTO duplicate_groups
      FROM (
          SELECT empno,
                 effdate,
                 count(*) AS total_rows,
                 count(*) FILTER (WHERE NOT is_deleted) AS active_rows,
                 string_agg(jobcode, ',' ORDER BY jobcode) AS jobcodes
            FROM public.jobhistory
           GROUP BY empno, effdate
          HAVING count(*) > 1
      ) AS duplicates;

    IF duplicate_groups IS NOT NULL THEN
        RAISE NOTICE 'S3-DBA-02 existing duplicate pairs: %', duplicate_groups;
    ELSE
        RAISE NOTICE 'S3-DBA-02 existing duplicate pairs: none.';
    END IF;

    IF active_duplicate_count = 0 THEN
        IF EXISTS (
            SELECT 1
              FROM pg_class AS c
              JOIN pg_namespace AS n ON n.oid = c.relnamespace
             WHERE n.nspname = 'public'
               AND c.relname = 'jobhistory_empno_effdate_active_uidx'
               AND c.relkind <> 'i'
        ) THEN
            RAISE EXCEPTION
                'S3-DBA-02 stopped: public.jobhistory_empno_effdate_active_uidx exists but is not an index.';
        END IF;

        CREATE UNIQUE INDEX IF NOT EXISTS jobhistory_empno_effdate_active_uidx
            ON public.jobhistory (empno, effdate)
            WHERE NOT is_deleted;
        RAISE NOTICE
            'S3-DBA-02 partial unique index enforces one active row per employee/effective date.';
    ELSE
        RAISE NOTICE
            'S3-DBA-02 skipped the partial unique index because % active duplicate pair(s) need DBA review. Resolve approved rows and rerun this migration.',
            active_duplicate_count;
    END IF;
END;
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
         WHERE conrelid = 'public.jobhistory'::regclass
           AND conname = 'jobhistory_effdate_not_null_ck'
    ) THEN
        ALTER TABLE public.jobhistory
            ADD CONSTRAINT jobhistory_effdate_not_null_ck
            CHECK (effdate IS NOT NULL) NOT VALID;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
         WHERE conrelid = 'public.jobhistory'::regclass
           AND conname = 'jobhistory_salary_nonnegative_ck'
    ) THEN
        ALTER TABLE public.jobhistory
            ADD CONSTRAINT jobhistory_salary_nonnegative_ck
            CHECK (salary >= 0) NOT VALID;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.enforce_jobhistory_unique_active_effdate()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = pg_catalog, public
AS $$
DECLARE
    old_empno VARCHAR(5);
    old_jobcode VARCHAR(4);
    old_effdate DATE;
BEGIN
    IF NEW.is_deleted THEN
        RETURN NEW;
    END IF;

    IF NEW.effdate IS NULL THEN
        RAISE EXCEPTION 'Job history effective date cannot be NULL.'
            USING ERRCODE = '23502';
    END IF;

    IF TG_OP = 'UPDATE' THEN
        IF NOT OLD.is_deleted
           AND OLD.empno IS NOT DISTINCT FROM NEW.empno
           AND OLD.effdate IS NOT DISTINCT FROM NEW.effdate THEN
            RETURN NEW;
        END IF;

        old_empno := OLD.empno;
        old_jobcode := OLD.jobcode;
        old_effdate := OLD.effdate;
    END IF;

    PERFORM pg_advisory_xact_lock(
        hashtext(NEW.empno),
        NEW.effdate - DATE '2000-01-01'
    );

    IF EXISTS (
        SELECT 1
          FROM public.jobhistory AS existing
         WHERE existing.empno = NEW.empno
           AND existing.effdate = NEW.effdate
           AND NOT existing.is_deleted
           AND (
               old_empno IS NULL
               OR (existing.empno, existing.jobcode, existing.effdate)
                  IS DISTINCT FROM
                  (old_empno, old_jobcode, old_effdate)
           )
    ) THEN
        RAISE EXCEPTION
            'An active job-history row already exists for employee % on effective date %.',
            NEW.empno,
            NEW.effdate
            USING ERRCODE = '23505',
                  CONSTRAINT = 'jobhistory_empno_effdate_active_uidx';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS jobhistory_biu_unique_active_effdate ON public.jobhistory;
CREATE TRIGGER jobhistory_biu_unique_active_effdate
    BEFORE INSERT OR UPDATE
    ON public.jobhistory
    FOR EACH ROW
    EXECUTE FUNCTION public.enforce_jobhistory_unique_active_effdate();

COMMIT;
