-- S3-DBA-01: expose each active employee's current effective job and department.
BEGIN;
SET LOCAL search_path = public, pg_temp;

CREATE OR REPLACE VIEW public.v_employee_current
WITH (security_invoker = true)
AS
SELECT
    e.empno,
    e.firstname,
    e.lastname,
    e.gender,
    e.hiredate,
    current_history.jobcode,
    j.jobdesc,
    current_history.deptcode,
    d.deptname,
    current_history.effdate
FROM public.employee AS e
LEFT JOIN LATERAL (
    SELECT
        h.jobcode,
        h.deptcode,
        h.effdate
    FROM public.jobhistory AS h
    WHERE h.empno = e.empno
      AND h.effdate <= CURRENT_DATE
      AND NOT h.is_deleted
    ORDER BY h.effdate DESC, h.jobcode DESC
    LIMIT 1
) AS current_history ON TRUE
LEFT JOIN public.job AS j
    ON j.jobcode = current_history.jobcode
   AND NOT j.is_deleted
LEFT JOIN public.department AS d
    ON d.deptcode = current_history.deptcode
   AND NOT d.is_deleted
WHERE NOT e.is_deleted;

GRANT SELECT ON public.v_employee_current TO authenticated;

COMMIT;
