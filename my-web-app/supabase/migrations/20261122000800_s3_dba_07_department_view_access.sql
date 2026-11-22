-- Employee, department, and job reads use the Human Resources module-view right.
BEGIN;
SET LOCAL search_path = public, pg_temp;

DO $$
BEGIN
    IF to_regclass('public.employee') IS NULL
       OR to_regclass('public.department') IS NULL
       OR to_regclass('public.job') IS NULL
       OR to_regprocedure('public.hope_can_access(text,text,text)') IS NULL THEN
        RAISE EXCEPTION
            'S3-DBA-07 stopped: public.employee, public.department, public.job, and public.hope_can_access(text,text,text) are required.';
    END IF;
END;
$$;

DROP POLICY IF EXISTS hope_select_by_permission ON public.department;
CREATE POLICY hope_select_by_permission
    ON public.department
    FOR SELECT
    TO authenticated
    USING (public.hope_can_access('hr', 'hr', 'view'));

DROP POLICY IF EXISTS hope_select_by_permission ON public.job;
CREATE POLICY hope_select_by_permission
    ON public.job
    FOR SELECT
    TO authenticated
    USING (public.hope_can_access('hr', 'hr', 'view'));

DROP POLICY IF EXISTS hope_select_by_permission ON public.employee;
CREATE POLICY hope_select_by_permission
    ON public.employee
    FOR SELECT
    TO authenticated
    USING (public.hope_can_access('hr', 'hr', 'view'));

COMMIT;
